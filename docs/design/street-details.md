# Street details along the main line

BACKLOG audit item "street furniture only at the start": the kiosk, flower stall, cafés,
planters and ad column exist only in `first_scene.gd` ITEMS (Marszałkowska by the museum). The
map data already has the generic props everywhere (centrum.json `benches` 11553, `bins` 4683,
`bikes` 5040, `columns` 927, `shelters` 1176, `lamps`). What is missing is the *character* layer
along the streets the main line (docs/design/main-line.md) sends the player down. This page is
the spec; built 2026-11-01 (the bake, `street_details.gd`, the two checks). Not yet seen in a render.

## 1. The route (game metres, x east, z south; from centrum.json, origin 52.234 N 21.024 E)

Points the main line sends the player to, in order:

| # | Place | (x, z) | Source |
| --- | --- | --- | --- |
| 0 | Spawn, Marszałkowska by the Rotunda | (-912, 279) | centrum.json `spawn` |
| 1 | stand: kebab at Marszałkowska × Świętokrzyska | (-1060, -230) | jobs.gd FIRST_STAND |
| 2 | order: Aleje Jerozolimskie 33 | (-694, 452) | first order's door (address poi) |
| 3 | race: the Palm, Rondo de Gaulle'a | (-214, 239) | rivals.gd FIRST_FINISH, `palm` |
| 4 | trap 1, Aleje Jerozolimskie eastbound | (142, 139) | police_traps.json id 1 |
| 5 | tape: the boulevards (Karowa to Most Świętokrzyski) | (160, -1057) | places.json `bulwary`, Wybrzeże Kościuszkowskie |
| 6 | powisle: district label | (380, -480) | districts.json |
| 7 | garage: Mirek's, Praga | (1321, -1948) | garage.gd SPOT |
| 8 | final start: Rondo Daszyńskiego | (-2647, 410) | trzy_mosty.gd START_HINT |
| 9 | bridges: Śląsko-Dąbrowski, Świętokrzyski, Poniatowski | (-138, -1689), (689, -864), (1176, -219) | trzy_mosty.gd |
| 10 | finish: PGE Narodowy | (1496, -601) | `pois` stadium |

The rescue (nearest hospital) and the ladder's rivals (cruising anywhere, finishes from
rivals.gd FINISHES: PKiN, Dmowskiego, the Palm, Pl. Trzech Krzyży, Kopernik, Rondo ONZ, Powiśle
station) have no fixed path; the corridors below already pass most of those finishes.

**Corridors** (shortest road paths between the points, from the roads graph; waypoints every
~250 m). The bake takes a road segment when its `name` is in the corridor and it lies within
40 m of the corridor polyline:

| Id | Streets | Waypoints | Character |
| --- | --- | --- | --- |
| C1 | Marszałkowska, Świętokrzyska (Jasna to Marszałkowska) | (-1091,-256) (-977,53) (-952,172) (-872,411) | avenue |
| C2 | Aleje Jerozolimskie, Rondo de Gaulle'a | (-872,411) (-711,426) (-433,330) (-195,253) (-44,197) (150,131) (300,80) | avenue |
| C3 | Nowy Świat (the Palm to Świętokrzyska), Świętokrzyska east of it | (-195,253) (-300,0) (-430,-330) (-242,-285) | café street |
| C4 | Tamka, Topiel, Browarna, Karowa, Dobra | (-242,-285) (38,-323) (81,-497) (-95,-717) (-215,-958) (-221,-1201) | café street |
| C5 | Wybrzeże Kościuszkowskie (Karowa to Most Poniatowskiego) | (-25,-1225) (162,-1057) (404,-478) (566,-22) | riverside |
| C6 | Prosta, Rondo ONZ, Świętokrzyska (west) | (-2644,412) (-2149,242) (-1671,75) (-1181,-94) | avenue |
| C7 | Aleja „Solidarności” and Targowa east of the river, Ząbkowska | (73,-1835) (900,-1800) (1321,-1948) | avenue (Praga) |
| C8 | Aleja Poniatowskiego, Rondo Waszyngtona, Aleja Zieleniecka (to the stadium) | (1417,-292) (1722,-391) (1611,-372) (1496,-601) | avenue |

Never on bridges (`bridge` true), Wybrzeże Szczecińskie (riverbank, no pavement life) or
Nowy Zjazd. **Excluded areas:** main.gd FIRST_SCENE `Rect2(-1080, -160, 200, 420)` grown by
30 m (first_scene.gd owns it); 40 m round the Palm and the Rotunda (jobs.gd FIRST_PAST); 6 m
round every centrum.json `landmarks` outline (the landmark models' plazas stay as designed).

## 2. Design: a Python bake to a committed table (recommended)

`tools/bake_street_details.py` reads only `game/map/centrum.json` (committed, so the cloud
container can run it; no lod2, terrain or OSM) and writes `game/data/street_details.json`
(~30 KB, committed): `{"_about", "src": <sha1 of the keys it read>, "kinds": [...],
"items": [[kind, x, z, yaw, colour], ...]}`, 0.1 m and 0.01 rad. Hand tables like ITEMS do not
scale past one street; the bake reruns after every centrum.json re-bake. Deterministic: SHA1
hashes of positions, as bake_street_pois.py SEED.

**Clearance:** import and reuse `bake_street_pois.Solids` (carriageway, kerbs and ramps,
crossings, tram tracks, buildings, platforms, islands, steps, walls, metro stairs, lamps,
signals, benches, bins, bike racks, columns, shelters, parked cars, trees) with the prop's own
radius; add the `pois` kebab, scooter, scooter_zone and subway_entrance discs (2 m). **On the
pavement:** for each corridor segment and side, probe out from the road's edge (`w`/2 + 1.5 m) in
0.5 m steps up to 8 m; take the first point clear for the kind's radius that is outside every
carriage/median polygon and 1.0 m off any building (the LoD2 path's walls can stand a little
proud of OSM footprints). **Facing:** front (-z) to the nearest point of the road centre line.

**Density:** one cluster per 70-110 m of pavement side (hashed), each kind spaced from its own
kind: kiosk and stall 250 m, column 150 m (also from the map's `columns`), cafés only on café
streets. Clusters by character:
- avenue: at a junction corner (15-40 m from a graph node of degree 3+): a kiosk or a flower
  stall, plus two planters; mid-block: a planter pair or a bollard row;
- café street: two or three café sets in a row (3.5 m apart, parallel to the kerb), a planter at
  each end; one flower stall a street;
- riverside (C5, on the boulevard side only): an ice-cream cart every 400 m, planters, a café pair by the bars.
**Tram and bus stops:** each map `shelter` within 40 m of a corridor gets a stop post and, for
tram stops (shelter on or within 3 m of a `platforms` polygon), a ticket machine. Both stand
inside the shelter's own 2.6 m cleared disc (at its end, along its yaw), so they never add a new
obstruction to a platform; no other kind goes on a platform.

**Budget:** at most 900 items in all, 85 per 512 m sector (100 with the stop kits); ~250 triangles average, 25 k per
sector. Runtime `game/scripts/street_details.gd`, built per sector on load on both city paths
like storefronts.gd `_build_props` (not baked into sector scenes, so `bake_city.gd` is untouched):
one MeshInstance3D a sector in the actors' material (`Models.material()`), **one draw call a
loaded sector in view, +0 in the shadow pass** (cast_shadow OFF for the whole mesh; tall props
carry a flat dark contact pad 2 cm over the paving in their own mesh instead of a sun shadow, so
nothing under 1 m casts and the shadow pass gains no call). Ceiling: +3 draw calls at the spawn
view, +4 zoomed out and from the helicopter; bench before and after on the Mac.

## 3. Props (props.gd, one SurfaceTool, actors' material, ~20 boxes each)

Existing: `add_kiosk`, `add_flower_stall`, `add_cafe_set`, `add_planter`, `add_ad_column`.
New:
- `add_bollards(st, xf, n)`: a row of n (3-5) 0.9 m black posts, 1.5 m apart. ~60 tris.
- `add_stop_post(st, xf)`: the stop pole with a round yellow-green plate and a timetable box. ~70.
- `add_ticket_machine(st, xf)`: a 1.7 m grey-yellow box, lit screen (LIT_SIGN), BILETY in pixel
  letters. ~120.
- `add_ice_cream_cart(st, xf, awning)`: a white cart on two wheels, striped awning, LODY board. ~200.
- `add_contact_pad(st, xf, half)`: the dark quad under kiosk, stall, cafés, cart, column.

**Solid** (BoxShape3D per item, a StaticBody per sector, like first_scene.gd SOLID): kiosk,
flower stall, ice-cream cart. **Drive-through** (as the map's benches, bins, columns since
2026-10-30): café sets, planters, bollards, ad column, stop post, ticket machine.

**Text and brands:** only generic Polish words, each with its English in the code's doc comment
and on any card: PRASA (press), KWIATY (flowers), LODY (ice cream), BILETY (tickets). No real
chain or brand (no Ruch, no ZTM logo); a fascia name, if ever wanted, comes from
docs/design/parodies.md. Poster colours from the first scene's palette.

## 4. Checks and definition of done (full: geometry and per-frame)

`game/tools/check_street_details.gd` prints `street_details: OK` and exits 0/1; joins
`tools/verify.sh` as step `streetdetails` in the same change. It loads the JSON and centrum.json
and fails when: `src` does not match the map data (re-run the bake); an item lies in the
excluded areas, a carriage polygon, a platform (stop kit excepted, inside its shelter's disc),
within its radius of a lamp, tree, bench, bin, shelter or parked car, or more than 8 m from a
corridor road's edge; counts break the budget; a kiosk or stall is nearer than 250 m to another;
a sector's built mesh exceeds 25 k triangles or one surface. On the Mac (lod2 present) it also
fails on an item inside a LoD2 footprint; in the cloud it prints that step as skipped.
Plus: `tools/verify.sh`, `tools/shots.sh --set=core` on both paths (with `--prebuilt`), shots
at Nowy Świat, Tamka, the boulevards and Targowa (`--at=` x,z from section 1), the bench and the
four probe views before and after, `--ios`.

**Only the phone can show:** whether the props read at the iPhone's scale and camera size 80
(too small, or clutter), the frame on the TEST · BENCH card with the extra sector meshes, the
contact pads against the real sun shadows of the first scene's kiosk (which keeps its shadow),
and the lit screens and hatches at night.

**Bookkeeping:** BACKLOG item closed; CHANGELOG line "Kiosks, flower stalls, café tables and tram
stop details along the main line's streets, not only at the start"; the bake's flags in the
archive's flags table if any.
