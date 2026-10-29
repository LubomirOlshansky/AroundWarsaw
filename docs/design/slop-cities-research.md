# Slop New York and Slop Cities: what we can use (2026-10-29)

The user found mrdoob's **Slop New York** (github.com/mrdoob/slop-newyork) and zz85's **Slop
Cities** list (github.com/zz85/slop-cities) and asked how to use them. Read from their GitHub
pages and file lists; no code was copied.

## What they are

- **Slop New York** (MIT, 147 commits, ~440 stars): Manhattan in the browser with three.js,
  WebGPURenderer and TSL; walk, drive, cycle or fly a helicopter. Data: NYC Open Data building
  footprints and heights and street trees, the MTA's subway entrances, OpenStreetMap. Its `js/`
  shows the systems: traffic, cars, buses, vehicle physics and lights, pedestrians with routes,
  a helicopter, building footprints, collision and details (fire escapes), street details and
  props, road paint, subway entrances, trees from the city's database, landmarks, lighting,
  post-processing, scene culling, gamepad and touch controls, and a five-file audio system
  (sources, events, synthesis, **acoustics**). The README invites forks for games and films.
- **Slop Cities**: a curated list (and world map) of 44 city sims "in the spirit of" Slop New
  York plus 15 New York remixes and other games, on five continents. **Warsaw already has three:**
  *Tiny Warsaw* (tinywarsaw.app: low-poly central Warsaw, browse, ride and fly, the Palace of
  Culture), *Isometric Warsaw* (see `isometric-warsaw-comparison.md`) and *Szczęśliwe Bielany*
  (Bielany along M1, golden autumn, source only). Nocna Warszawa isn't on it.

## How we can use them

### 1. Get listed (the cheapest win)
The list takes entries through `cities.yml` and `CONTRIBUTING.md` (a pull request). Our repo is
public and MIT, so a "Source" entry works today; a **Play** link needs a web build (below).
Our hook against the three Warsaw entries: the only one that is a *game* at street level, with
gentle police, Podwózka, the radio and the Moja Warszawa humour. → Prepare the entry text and a
screenshot; opening the PR posts publicly from the user's GitHub account, so it needs the user's
yes first.

### 2. A web build (for the list, the site, sharing)
Every entry is playable in a browser in one click; that is how they spread (Reddit, X). Godot's
web export runs only the **Compatibility** renderer (WebGL 2), not our Mobile renderer, and the
map is 47 MB (today) to ~130 MB (the demo box). → A later loop: a web preset with the
Compatibility renderer, a smaller "web" map (the centre only, ~1 km² around the Palace and
Marszałkowska), the look checked against the art bible, hosted on GitHub Pages. Worth it before
a public announcement; not before 3d–3f land.

### 3. Ideas worth taking (in our own GDScript; nothing ported line by line)
Ranked by fit with the Moja Warszawa vision and the phone budget:

1. **Other ways to move**: on foot (the Old Town walking zone, the river steps, the notebook's
   places: Spacer mode becomes literal), a city bike (Rowerilo, vision.md), a dumped e-scooter
   (Leżak: ride one instead of collecting it). Slop NY has walk / car / bike / helicopter; the
   electric-unicycle remix shows how much a silly vehicle adds. → Loop MW-4/MW-6.
2. **City sound with acoustics**: their audio splits sources, events, synthesis and acoustics
   (street canyons echo, open squares don't). Ours has sfx loops and the radio. → A reverb/echo
   send that follows the space around the car (narrow Old Town lanes, the W-Z tunnel, the open
   Plac Defilad, the river), plus tram bells and the metro chime. Loop 3i / MW-5.
3. **A real bus or tram route on a timetable** (London Loop drives a double-decker on its real
   route): a Warsaw **night bus** (the N-lines meet at Centralna) as a side job, which also fits
   the night scene. Needs ZTM's GTFS (a download to approve; see the Isometric Warsaw notes).
4. **Building details by type**: their fire escapes are New York's signature. Warsaw's are the
   kamienica cornices and balconies, the prefab blocks' grids, shop-front neons, Soviet-era
   pavilions. → Facade details by OSM type and age in `map_builder` (loop 3f-2).
5. **Pedestrians with routes** (theirs walk real pavements): ours already walk; give them
   destinations (metro entrances, stops, the river steps at sunset, the club queues). MW-3/MW-4.
6. **Subway entrances from open data**: they used the MTA dataset; ours come from OSM
   (`railway=subway_entrance`), planned in MW-2.
7. **Phone tricks**: *Slop New York Mini* runs Midtown at 60 fps on an iPhone with a `?phone`
   mode; the *Low-end GPU* fork shows a weak-GPU path. We already have tiers, the governor and
   sector streaming; their lesson matches ours.
8. **Gamepad support**: a Bluetooth controller on the iPhone and the Mac is cheap in Godot (the
   Input map) and suits a driving game. Loop 3j.
9. **Taxi fares against the clock** (a remix) = our Podwózka; **LLM residents** (one batched LLM
   call for eight NPCs' plans) is out: it needs a network and a server, and the game collects
   nothing and stays offline.

### What not to take
- Their code as is: it is three.js/JavaScript, ours is Godot; and MIT would need its notice kept
  wherever code is ported. We port ideas, not code.
- The "cops with paddles" chase: our police stay gentle (police.md).
- Paid billboard takeovers ("Make it anywhere"): no ads, no payments.

## Next steps (proposals)
1. A Slop Cities entry (text and screenshot ready; the PR only on the user's yes).
2. Loop "web build" after 3f: the Compatibility renderer, a small web map, GitHub Pages.
3. Fold ideas 1–6 into vision.md's MW loops when they're briefed.
