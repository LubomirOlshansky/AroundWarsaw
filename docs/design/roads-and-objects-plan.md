# Smoother roads, better road objects, then buildings: research and the plan for the next days

**Status (2026-11-04):** research, two new cloud tools (`tools/street_features.py`, `tools/street_objects.py`) and a day-by-day
plan. No game code changed. Builds on docs/design/road-objects.md (PR #429: the object census, the
verdicts, collision v2, the `road-objects-sweep` skill and the `road-auditor` agent), the Tiny Warsaw
area list (PR #433, docs/design/tinywarsaw-area-plan.md) and docs/CITY_INVENTORY.md. The plan's
items are also in `docs/plan/city-plan.json`, which the dev console (tools/console.py, PR #431) reads.

F (2026-11-04): "the first priority is make roads and objects better; with the objects analytics I
think we can improve the roads, make it look smoother and natural, with Panoramax and Mapillary.
First make the research for how to improve roads, which additional sources we can use, and plan how
we approach improving the city for the next few days: roads, objects, buildings." The delivery,
racing and steering half of the same message has its own thread.

Contents:
1. [How the roads are drawn today, measured](#1-how-the-roads-are-drawn-today-measured)
2. [What makes a road look smooth and natural](#2-what-makes-a-road-look-smooth-and-natural)
3. [What the street-level detections add (Mapillary, measured)](#3-what-the-street-level-detections-add-mapillary-measured);
   [3a. Log everything, add only what earns its place](#3a-log-everything-add-only-what-earns-its-place-f-2026-11-04)
4. [Every data source worth using](#4-every-data-source-worth-using)
5. [The plan, day by day](#5-the-plan-day-by-day)
6. [Gates, numbers and what F checks](#6-gates-numbers-and-what-f-checks)
7. [Sources](#7-sources)

---

## 1. How the roads are drawn today, measured

From `game/map/centrum.json` on main (2026-11-04) and the code that draws it:

- **Every road is a ribbon of quads along its OSM centreline** (`map_builder.gd` `_build_roads` →
  `_strip`), one flat colour (`road` / `road_minor`), with **a round disc at every vertex that bends
  more than ~7°** to fill the gap on the outside of the bend. The ground shader adds grain, light
  wear and repair patches, rain and the night sheen (`ground.gdshader`).
- **Only where OSM maps the carriageway as an area (`area:highway`) is the shape exact** (761
  areas). The road's own ribbon hides under it ("hide" ranges). That covers **38 of 461 km** of road:
  main roads 21 %, residential 4 %, service ways 2 %, living streets 0 %.
- **Junctions are where the ribbons overlap.** Of 2,639 places where two or more non-service roads
  share a node, **377 (14 %) lie inside a mapped carriageway area**; the other 86 % are crossing
  ribbons plus discs: square ends, no kerb return radius, a circle bulging out on the corner.
- **Kinks**: OSM centrelines are polylines. Main roads have 217 vertices bending 20-45° and 13 over
  45°; the minor network 2,489 at 20-45° and 1,019 over 45°. Each is a disc patch and a visible
  angle in the edge line and the kerb.
- **Width is one number per way** (`width`, else lane counts, else the class default), so a street
  does not widen into a bus bay, a turn lane or a junction flare unless an area says so.
- **Kerbs** (411 km) and **markings** (edge, lane, zebra stripes, stop lines, arrows, bus, cycle;
  14,422 lines and 3,291 symbols) follow the same centrelines and areas, so they inherit the kinks.
- **Surface** is asphalt everywhere except the hand-made granite setts of Krakowskie Przedmieście
  (`kp_setts_at`, a box test in the shader) and paved pedestrian areas. OSM's `surface=sett`,
  `paving_stones` and `concrete` on ways are not read.

So "smoother and more natural" is mostly three things: **the bends** (polyline kinks drawn as
discs), **the junctions** (overlapping rectangles instead of a junction shape with kerb returns),
and **the uniform width and surface** (one width and one asphalt per way). The objects on and
beside the road are the fourth (road-objects.md).

## 2. What makes a road look smooth and natural

Ranked by what the player sees per hour of work. Every item keeps both city paths (runtime build and
prebuilt sectors) and is a bake change unless it says shader.

| # | Change | What it fixes | How | Cost |
| --- | --- | --- | --- | --- |
| **RS1** | **Junction shapes with kerb returns** | 86 % of junctions are overlapping ribbons | the osm2streets method: trim each road's ribbon back to where its edges stop overlapping the others', join the trimmed corners into one junction polygon, round each corner between two adjacent roads with an arc (kerb return radius 8 m main / 5 m residential / 3 m service), and draw the kerb along the arc. Junctions already inside an area are left alone. Lane graph connectors already curve (`graph.connector`), so the drawn corner and the driven corner come together | bake_roads.py, new pass after `build_region`; a check that every junction polygon covers its lanes' connectors; Mac re-bake |
| **RS2** | **Fillet the kinks** | discs and angled edges on 3,700 vertices | replace each vertex bending more than 8° with a circular arc (radius from the class: 60 m primary, 30 m secondary/tertiary, 12 m residential, 6 m service; capped by half the shorter neighbouring segment), resampled every 2 m. The ribbon, edge lines, lane lines, kerbs and the lane graph read the same smoothed line (GAMEPLAY_PLAN 2.3 asks for the graph fillets anyway). Junction nodes and deck ends are pinned | bake_roads.py `smooth_centreline()` next to `simplify`; Mac re-bake |
| **RS3** | **Width that varies along the street** | bus bays, turn pockets, flares at junctions | (a) OSM: `width:carriageway`, `lanes` changes between consecutive ways, `parking:*` and `turn:lanes` per segment already exist and are read per way; taper between ways over 20 m instead of a step; (b) measured: on the Mac, sample the GUGiK orthophoto across the road every 10 m and find the asphalt edges (dark band between two kerb lines), giving a width profile per way; used only where it disagrees with the tags by more than 1 m, and listed for a look | bake_roads.py taper (cloud); `tools/road_widths.py` on the Mac (new) |
| **RS4** | **Surfaces from the tags** | everything is the same asphalt | read `surface` (sett, paving_stones, concrete, cobblestone, asphalt) and `smoothness` on drivable ways; pass a surface id in the road's vertex data; the ground shader draws setts and paving the way `kp_setts_at` does now, but by id instead of a box. Praga's cobbled side streets, the Old Town, Nowy Świat's setts, concrete slabs on service ways | bake + shader; no new material or draw call |
| **RS5** | **Tram beds and medians that read** | median fences and tram beds as grey slabs (road-objects O1) | tram track on grass or setts between kerbs (OSM `embedded`, `railway:track_bed`), median kerbs from RS1's polygons | bake + shader |
| **RS6** | **Crossings and kerb drops** | zebras painted but the kerb runs through them | OSM `highway=crossing` / `footway=crossing` nodes and `kerb=lowered/flush`: cut the kerb 3 m at each crossing, a lighter flush slab in the pavement; the zebra aligned to the crossing way, not the road's normal | bake |
| **RS7** | **Asphalt that has a history** | perfect uniform asphalt | in the ground shader, no new draw call: lane-wheel tracks a shade darker, longitudinal repair seams on main roads, utility trench patches near junctions, manhole and drain lids (procedural rings at points from the bake; Mapillary sees 39 manholes and drains along Marszałkowska alone), fresher black asphalt on streets OSM or the city marks as recently rebuilt | shader + a points list; bench (fragment cost) |
| **RS8** | **Road profile along the street** | the car bobbing on the 10 m terrain grid | smooth each road's height along its centreline (the same relaxation as the decks' `_solve`, 20 m window), and drape the pavement to the road edge so kerbs keep 12-15 cm | bake_roads.py; Mac re-bake |
| RS9 | Lines and arrows from evidence | markings guessed from tags | where Mapillary detects arrows or a zebra within 25 m of a junction and the game has none (section 3), list it for an ortho look on the Mac; add it by hand only after the look | evidence list, then small edits |

**Order**: RS2 and RS1 first (one thread: they share the centrelines and the re-bake), then RS4 and
RS6 (cheap, visible), RS3 (needs the Mac), RS7 (shader, bench), RS8 with the next deck change.

**Prototype first, on three pilot junctions:** Marszałkowska × Świętokrzyska (the first ten
minutes), Krucza × Hoża (a residential cross), Nowy Świat × Świętokrzyska (sett street meets a main
road). Before and after shots by day and night, `--prebuilt` too, and `check_lane_drive` numbers on
the same streets: the shape must never cut into a lane's corridor.

**osm2streets** (A/B Street's library, Apache 2.0) already does RS1 and much of RS3 from OSM
tags, and ships as `osm2streets-js` (WebAssembly) on npm. The recommendation is to **use it as the
reference, not the bake**: run it on the Mac on the pilot junctions' OSM extract and compare its
junction polygons with ours; port the method into bake_roads.py (standard library, the project's
rule) so the bake stays one Python chain. If the port is far off after a day, propose adding it as a
bake-time tool to F (a free download, but a second language in the bake).

## 3. What the street-level detections add (Mapillary, measured)

Mapillary detects objects in every street-level photo and triangulates them into "map features"
(a point and a class such as `object--street-light`, `marking--discrete--crosswalk-zebra`,
`regulatory--no-entry--g1`). The API answers from the cloud with F's token (MAPILLARY_TOKEN).
`tools/street_features.py` (new) fetches them for the map, a box or one street, merges duplicate
detections and the game's own zebra stripes into objects, and matches them against the game's
layers. In the 350 × 330 m block around Marszałkowska × Świętokrzyska alone there are 1,220
features: 136 traffic-sign fronts, 128 street-light detections, 121 shop signs, 42 zebras, 35
pedestrian lights, 29 utility poles, 27 bins, 14 junction boxes, 10 manholes, 8 temporary barriers.

**Marszałkowska (25 m either side of the street, match within 12 m):**

| Class | Mapillary | Game (in covered cells) | Matched | Mapillary only | Game only |
| --- | --- | --- | --- | --- | --- |
| Street lights | 450 | 123 | 101 | 349 | 22 |
| Traffic lights (vehicles) | 313 | 67 | 63 | 250 | 4 |
| Zebra crossings | 128 | 81 | 23 | 105 | 58 |
| Lane arrows | 161 | 83 | 38 | 123 | 45 |
| Bins / benches / bike racks | 49 / 30 / 25 | 68 / 22 / 45 | 9 / 4 / 10 | | 59 / 18 / 35 |
| Traffic signs | 1,221 | none (no layer) | | | |
| Utility poles / junction boxes / CCTV / hydrants | 197 / 50 / 14 / 3 | none | | | |
| Cones and temporary barriers | 38 | none (only edge roadworks) | | | |

**Whole map** (110,153 features, 10,660 covered 30 m cells; a fresh fetch takes about 20 minutes,
then 4 s from the cache):

| Class | Mapillary | Game (in covered cells) | Matched | Mapillary only | Game only |
| --- | --- | --- | --- | --- | --- |
| Street lights | 13,957 | 3,694 | 2,436 | 11,521 | 1,295 |
| Traffic lights (vehicles) | 3,583 | 1,062 | 887 | 2,696 | 176 |
| Zebra crossings | 2,354 | 529 | 116 | 2,238 | 413 |
| Stop lines | 540 | 548 | 184 | 356 | 364 |
| Lane arrows | 2,198 | 872 | 378 | 1,820 | 494 |
| Bins / benches / bike racks | 1,175 / 547 / 219 | 1,070 / 1,194 / 1,033 | 151 / 181 / 75 | | 920 / 1,022 / 959 |
| Traffic signs | 31,622 | none | | | |
| Shop signs and ads | 11,952 | none | | | |
| Utility poles / manholes / junction boxes / CCTV / hydrants | 4,402 / 1,005 / 944 / 248 / 59 | none | | | |
| Cones and temporary barriers | 1,389 | none (edge roadworks only) | | | |

Across the map, 83 % of the game's vehicle signals and 66 % of its lamps have a detection within
12 m. The game's 2,436 matched lamps against ~14,000 merged detections suggest the real streets
carry two to three times the lamps the game draws, even allowing for duplicates. Bins, benches and
racks barely match either way: they are small and the cameras face the road, so those classes say
little.

What it says, and how to use it:

1. **Positions are approximate.** Matching the same street at 4, 8, 15 and 25 m gives very
   different answers (zebras: 5, 11, 30, 44 matched): a marking or a sign is placed from the camera
   track, often 10-20 m off, and one lamp is often two or three detections. So Mapillary is
   **evidence per stretch and per junction** ("this junction has signals and two zebras", "this
   block has 12 lamps a side"), never coordinates to copy. Exact places come from OSM nodes and the
   orthophoto.
2. **Lamps and signals** are where the game is closest: almost every game lamp and signal near
   Marszałkowska has a detection near it (few "game only"); Mapillary sees more because it also sees
   the lamps of side streets, both sides of wide streets and duplicates. Density per 100 m, not
   count, is the comparison to make per street.
3. **What the game lacks entirely**: traffic signs (the largest class by far), utility and
   catenary poles beside the road, junction boxes, CCTV, hydrants, manholes, temporary roadworks.
   **They are logged, not added** (section 3a): at our camera and without hand-made graphics,
   tens of thousands of small signs and poles would clutter the city and read as noise.
4. **The sign types check the lane graph**: a `regulatory--no-entry` or `one-way` detection at a
   street's end that disagrees with the game's `oneway` is a lane-graph bug to look at
   (GAMEPLAY_PLAN 1.2).
5. **Licence**: Mapillary data is CC BY-SA 4.0. Used as evidence for decisions it needs nothing;
   anything placed in the game because of it gets a line in the attribution list (`attribution`
   in centrum.json, shown in the credits).

The JSON (`--json=build/street_features.json`) is a layer for the dev console's map: every
detection by class, green where the game has it, red where only one side does.

## 3a. Log everything, add only what earns its place (F, 2026-11-04)

F: "plan it carefully, so the roads are not overloaded with objects and nothing is added that the
map doesn't need. Map them and write it down, but decide wisely: if a street is for pedestrians,
why would it have cones or barriers? Temporary or stale? Signs would overload the city and are too
tiny without graphics. Traffic lights maybe only in the most valuable places. Lamps: check how
they look, the real number may not look good. Each street should have its own mapping of all its
objects, and we choose carefully what goes into the game for the gameplay balance."

So the street-level data does two separate jobs:

1. **The log** (`tools/street_objects.py` → `docs/inventory/street_objects.md`, generated, and
   `build/street_objects.json` for the console): for every named street, every class the cameras
   saw and every class the game draws, as objects per 100 m, real against game. Cones and barriers
   count only detections seen since 2025-05 (375 of the 1,138 on our streets; the rest may be long
   gone) and separately those inside pedestrian zones. It is the record F asked for, regenerated
   whenever the detections or the map change; nothing in it is placed by itself.
2. **The budget**: what each class may become in the game. Default "log only"; a class enters the
   game only when it helps reading the street or the gameplay, passes a look test at the game's
   camera by day and night, and passes the bench.

| Class | In the game? | Why |
| --- | --- | --- |
| Lamps | already in the game; **density by a look test**, not the real count | the cameras see about 3 lamps for every one the game draws (10,599 against 3,612 on named streets); at night lamps are the city's look, but the real density may read as clutter by day. Two streets (Marszałkowska; Hoża, which has none in the game today), current against real density, night and day shots, bench, F picks. Krakowskie Przedmieście already matches (87 seen, 84 drawn) |
| Traffic lights | already in the game (traffic stops at them); **no new ones** | A/B for F: all visible poles as now, or poles only at main-road junctions and the places that matter (first ten minutes, race routes), the rest kept as invisible stop lines |
| Zebras, stop lines, arrows | in the game from OSM | the detections and the orthophoto only correct them |
| Traffic signs | **log only** | too small to read at our zoom without real graphics; 26,000 on our streets would clutter. If any: a handful of gameplay signs (STREFA ZAMIESZKANIA at living-street mouths, a speed sign at a police trap, no entry where the main line turns), each one decided by F |
| Utility and catenary poles, junction boxes, CCTV, hydrants | **log only** | noise at our camera; they cost draw calls and give nothing to play |
| Manholes and drains | log only; maybe painted marks in the asphalt shader (RS7, no geometry) | |
| Cones and temporary barriers | **log only** by default | only if seen recently, on a carriageway and never in a pedestrian zone, and then as a roadworks event (edge_roadworks style, coming and going), never as fixed props |
| Bins, benches, bike racks | in the game as they are | the cameras face the road and barely see them; no change from this data |

**The metric per street** (in the log, and the gate for any object PR): objects per 100 m by class,
and for the driving balance the road-objects census's solid metres within 3 m of a lane per 100 m.
A street's budget is "no more solid roadside objects than now unless its sweep asks for them", and
every visual addition shows its shots and bench in the PR.

## 4. Every data source worth using

| Source | What it gives the roads and objects | Where it runs | Licence | Use |
| --- | --- | --- | --- | --- |
| **OSM tags we don't read yet** | `surface`, `smoothness`, `width:carriageway`, `kerb` and `crossing` on nodes, `traffic_sign`, `highway=stop/give_way`, `barrier=bollard`, `traffic_calming`, `railway:track_bed`, `parking:*:orientation` | Mac (OSM and Overpass are blocked from the cloud) | ODbL (already credited) | RS4, RS6, signs, bollards, speed bumps |
| **Mapillary map features** | detections by class (above); `traffic_signs` as their own layer | cloud, `tools/street_features.py` | CC BY-SA 4.0 | presence per street/junction, missing classes, lane-graph checks |
| **Mapillary and Panoramax photos** | the street as it is, any direction | cloud, `tools/street_photos.py` (#429) | CC BY-SA 4.0 / etalab-2.0 | the road-auditor's CHECK evidence, object and sign looks; never traced or shipped |
| **GUGiK orthophoto** (HighResolution WMS; the newest Warsaw flight in PZGiK) | asphalt edges, kerb lines, markings, zebras, tram beds, parked rows, medians | Mac (`tools/fetch_gugik.py`, `overlay_ortho.py`) | free (PZGiK, open since 2020) | RS3 width profile, RS9 markings, road-objects S4 |
| **GUGiK LiDAR** (ALS point cloud and NMPT) | kerb steps, medians and islands as height, bridge decks, the road's real profile | Mac (download per sheet) | free (PZGiK) | RS8 profile; islands and medians where OSM has none |
| **GUGiK BDOT10k** | road lines with class and attributes (surface material, width and lane count where surveyed), road-area classes | Mac (free download per county) | free (PZGiK) | a second opinion on width and surface where OSM has no tag |
| **Warsaw's city geoportal** (mapa.um.warszawa.pl: base map 1:500 with kerbs, road edges, lamps) | the most exact kerb lines there are | Mac, view only | check the terms before any use beyond looking | a reference for the pilot junctions' RS1 look, not a data input until the licence is clear |
| **Overture Maps transportation** | OSM-derived road segments and connectors, with surface and width rules, as Parquet on S3 | **cloud** (the S3 host answers) | ODbL (from OSM) | lets a cloud thread read up-to-date OSM-like road data when the Mac is busy; prototypes only |
| **osm2streets** | junction polygons and lane geometry from OSM tags | Mac or cloud (npm `osm2streets-js`, WebAssembly) | Apache 2.0 | the reference for RS1 and RS3 |
| Not used | Google Street View (licence forbids deriving data); Bing Streetside only to corroborate | | | |

## 5. The plan, day by day

F's limits reset on 2026-11-05. The cloud credits ($196 at the time of writing) expire
2026-11-05 08:59 CET, so the first block runs **tonight** in the cloud. One item per thread and
PR, merge slots from the coordinator, model by the project's routing (Opus for geometry, feel and
acceptance; Sonnet for content and kits; Haiku for counts). "Mac" items wait for F's yes in a
thread. The same list, with status, is `docs/plan/city-plan.json` (dev console, "Plan" tab).

### Day 0, tonight (cloud credits, nothing needs the Mac)

| Id | Item | Model | Needs |
| --- | --- | --- | --- |
| D0.1 | This research and plan (this PR) | Opus | — |
| D0.2 | Collision v2 behind `--collide=v2` and Classic's wall follow (road-objects §7 #1) | Opus | #429 merged |
| D0.3 | Census `--classify` (road-objects S2 rules B1-B15) into `game/data/road_objects.json`, cloud only | Opus | #429 merged |
| D0.4 | RS2 + RS1 prototype on the three pilot junctions, cloud shots (lavapipe) before/after | Opus | the map pack |
| D0.5 | Whole-map Mapillary census cached; console layer from `--json` | Sonnet | console #431 |

### Day 1, 2026-11-05: smooth roads and the first street sweep

| Id | Item | Model | Needs |
| --- | --- | --- | --- |
| D1.1 | RS2 kink fillets + RS1 junction shapes city-wide (after D0.4's look), with a check that junction polygons cover their connectors; Mac re-bake, both city paths | Opus | Mac re-bake |
| D1.2 | First road-objects sweep: Marszałkowska + Świętokrzyska + Jerozolimskie (road-objects §7 #3), with `street_features.py` evidence | Opus (road-auditor) | Mac ortho crops |
| D1.3 | `check_lane_drive` contact log, `--street=`, sloppy driver (road-objects RO2) | Opus | — |
| D1.4 | osm2streets comparison on the pilot junctions | Sonnet | Mac (OSM extract) |
| D1.5 | F: phone check of collision v2 presets and the smoothed roads | F | device run yes |

### Day 2, 2026-11-06: surfaces, crossings, the lamp look test

| Id | Item | Model | Needs |
| --- | --- | --- | --- |
| D2.1 | RS4 surfaces from tags (setts, paving, concrete) and RS6 crossings with kerb drops | Opus | Mac re-bake |
| D2.2 | Lamp density look test (Marszałkowska, Hoża: current against real, night and day, bench) and the traffic-light poles A/B; F picks (section 3a) | Opus | F's look |
| D2.3 | Stairwell balustrades and metro canopies city-wide (road-objects B5, B6) | Sonnet (object-modeler) | — |
| D2.4 | Second sweep: Nowy Świat + Krakowskie Przedmieście + Królewska | Opus | Mac ortho |

### Day 3, 2026-11-07: soft objects, narrow streets, the asphalt's history

| Id | Item | Model | Needs |
| --- | --- | --- | --- |
| D3.1 | Soft colliders (fences, hedges, parked-car corners) with the Marszałkowska median-fence A/B (road-objects §4.4) | Opus | phone bench |
| D3.2 | Narrow streets: drive hull, parked cars B7, kerbs (road-objects §5) | Opus | Mac re-bake |
| D3.3 | RS7 asphalt history (wheel tracks, seams, patches, manholes) in the ground shader; bench | Opus | phone bench |
| D3.4 | RS3 width profiles from the orthophoto (`tools/road_widths.py`), tapers between ways | Opus | Mac |
| D3.5 | Street-objects log refreshed and cross-checked with OSM nodes on the Mac; one-way and no-entry detections checked against the lane graph (no signs added) | Sonnet | Mac (OSM nodes) |

### Days 4-5, 2026-11-08/09: buildings (Tiny Warsaw list P1-P4, CITY_INVENTORY Part 3)

| Id | Item | Model | Needs |
| --- | --- | --- | --- |
| D4.1 | P1: the 31 ranked ✗ rows, palaces on Senatorska and Aleje Ujazdowskie first (Blanka, Prymasowski, Branickich, Jabłonowskich, Pod Karczochem, Pod Gigantami) | Sonnet (object-modeler), Opus accepts | Mac photo gather |
| D4.2 | P3: Rondo ONZ and Rondo Daszyńskiego towers by photo (the Daszyńskiego gather already started) | Sonnet, Opus accepts | Mac photos |
| D4.3 | P4 kits: hospital pavilions (Dzieciątka Jezus), industrial brick (Norblin, Browary), government stone (Sejm), MDM socrealism | Sonnet | street photos (cloud) |
| D4.4 | P5 address blocks folded into street passes (Żurawia-Chmielna, Foksal), colours from street photos | Sonnet | cloud |
| D4.5 | Third and fourth road-objects sweeps by the census order (Jana Pawła II, Solidarności, Prosta, Okopowa) | Opus | Mac ortho |
| D5.x | Eastern Wall photo pass, modernism lane next items, P6 infrastructure tier names | per lane | Mac photos |

After day 5 the loop goes on street by street (F, 2026-11-01): the census order for roads and
objects, CITY_INVENTORY order for buildings, one street group per thread.

## 6. Gates, numbers and what F checks

- **Every road look PR**: shots by day and night at the three pilot junctions and its own streets,
  `--prebuilt` too; `check_lane_drive` before/after (contacts per km, speed kept, unsticks: never
  worse); `python3 -I tools/check_map_data.py` with new counts recorded on purpose; bench before
  and after (RS4, RS7, signs: the draw-call gate).
- **Every object PR**: the road-objects sweep table (verdict counts, CHECK list).
- **Street features**: `street_features.py --street=NAME` before and after a sweep: game-only and
  Mapillary-only counts per class should shrink where the sweep added or removed objects.
- **What only the phone shows**: the feel of collision v2 and soft fences, the asphalt detail at
  phone size, signs' readability, bench on iPhone 11.
- F's checks live in QUESTIONS (A/B and look calls), the dev console's Plan and Approvals tabs,
  and each PR.

## 7. Sources

- [osm2streets on GitHub](https://github.com/a-b-street/osm2streets) and the talks
  [osm2streets: Street networks with detailed geometry (SotM 2022)](https://pretalx.com/sotm2022/talk/9NHQQM/),
  [slides](https://dabreegster.github.io/talks/sotm_2022/slides.html): junction polygons and lane
  geometry from OSM tags.
- [Reconstructing a high-detailed lane-level road network model from OpenStreetMap (SotM 2026)](https://pretalx.com/sotm2026-osm-science/talk/KUEYVB/)
  and [an MSc thesis at TU Delft on the same problem](https://3d.bk.tudelft.nl/ken/files/24_chengzhi.pdf).
- Mapillary: [types of map data](https://help.mapillary.com/hc/en-us/articles/360003021152-Types-of-map-data),
  [map data through the API](https://blog.mapillary.com/update/2020/08/28/map-data-mapillary-api.html),
  [42 point classes as map features](https://blog.mapillary.com/update/2019/01/23/updating-maps-with-cameras-42-new-point-features.html).
- GUGiK: [BDOT10k](https://www.geoportal.gov.pl/en/data/topographic-objects-database-bdot10k/),
  [the BDOT10k user guide](https://www.blog.ongeo.pl/vademecum-uzytkownika-bdot10k),
  [orthophoto](https://www.geoportal.gov.pl/en/dane/ortofotomapa),
  [new photogrammetric data in PZGiK](https://www.geoportal.gov.pl/aktualnosci/nowe-dane-fotogrametryczne-w-pzgik-19/).
- docs/design/road-objects.md section 9 for street-level imagery licences and the arcade references.
