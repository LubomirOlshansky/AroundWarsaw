---
name: bake-map
description: Runs or changes Nocna Warszawa's map-data bake chain (OpenStreetMap and GUGiK raw data in data/raw, the Python bakes in tools/ into game/map/centrum.json, ao.bin, lights.bin, water.bin, then the prebuilt city.scn) and checks its invariants. Use before editing any tools/bake_*.py, map_builder.gd, lane_graph.gd or anything under game/map/; for roads, bridge decks, ramps, the lane graph, trees, POIs; and before any download of map data.
---

# The map-data bake chain

README.md "Map data" holds the exact commands; this is the order, the rules and the checks.
If they disagree, README wins: fix this file.

## Rules

- **No download without the user's yes.** List each one first: source URL, size, time, and
  which bakes re-run. The raw data (`data/raw/`, ~5 GB) is gitignored and never committed.
  The public Overpass server is often busy (HTTP 502/504): retry with a back-off.
- Python tools run with `python3 -I` and use the standard library; the orthophoto overlays need
  Pillow (they run without `-I`). Don't install anything without asking.
- Never hand-edit generated files (`centrum.json`, `*.bin`, `city.scn`). Change the bake, and
  keep exclusions as small, commented lists in the bake (like `GUGIK_NOT_TREES`).
- Licences travel with the data: OpenStreetMap is ODbL (the baked files are derived databases
  under ODbL), GUGiK trees are CC BY 4.0. A new source needs a line in CREDITS.md and the
  in-game credit; ask the user before adding one.

## Order (re-run everything below the step you changed)

1. Trees (optional): `tools/bake_trees_gugik.py` → `data/raw/gugik/trees_area.json`.
2. OpenStreetMap: `tools/bake_osm.py` (imports `tools/bake_roads.py`: carriageways, kerbs,
   medians, markings, bridge decks; writes `graph`, the lane graph, and `pois`) →
   `game/map/centrum.json`. It reads `game/map/terrain.json` for the decks.
3. GUGiK buildings and terrain: `tools/fetch_gugik.py` (downloads: ask), `tools/bake_gugik.py`
   → `lod2.bin`, `lod2.json`, `terrain.json`.
4. `tools/bake_ao.py game/map` → `ao.bin` (after 2 and 3).
5. `tools/bake_lights.py game/map` → `lights.bin` (after 2 and 3).
6. `tools/bake_water.py game/map` → `water.bin` (after 2).
7. The prebuilt city, **with a renderer** (`--headless` drops MultiMesh and texture data):
   `godot --path game --resolution 320x180 --script res://tools/bake_city.gd`
   (also needed after any change to `map_builder.gd`, `chunked_surface.gd`, `landmarks.gd`,
   `neon_signs.gd`; `tools/export_ios.sh` does it too).

## Invariants after a re-bake

```zsh
python3 -I tools/check_map_data.py      # trees3d 75324 values, pois 1020, graph, palm, city.scn fresh
godot --path game --resolution 320x180 --script res://tools/count_vertices.gd   # vertex budget
```

If the counts change on purpose (the map grows, a POI kind is added), update `EXPECTED` in
`tools/check_map_data.py` and the numbers in README "Map data" in the same change, and say
in the report what changed and why.

## Checks for roads, decks and the lane graph

- Over the aerial photo: `python3 tools/overlay_ortho.py OUT.png X Z HALF` (road areas red,
  kerbs cyan, lane centres magenta); `tools/overlay_landmarks.py` for landmark footprints.
  Write outputs to `shots/`. Coordinates are map metres, +x east, +z south, origin at the
  map's centre.
- In the game, on both city paths: `tools/shots.sh --set=... -- --at=X,Z --heading=DEG`, or
  `cd game && godot --path . --resolution 2532x1170 --fixed-fps 60 -- --nosave --free --at=X,Z
  --shots=240 --out=$PWD/../shots/NAME` (add `--prebuilt`).
- Heights: `map_builder.gd` `ground_height`, `drive_height` (the surface the car is on: a
  deck 5 m overhead is not the road) and `deck_height`. A road, lane or tram line passing
  through solid geometry, or a height jump where a ramp meets the ground, is a bake or
  deck-solver defect: find the class of defect and fix it for the whole map, with a check
  that counts it over the whole map before and after (not just the spot the user saw).
- Then `tools/verify.sh` (the traffic, race and job runs use the lane graph).

## Report

Which steps ran (with their printed counts), the invariants before → after, the vertex count
before → after, overlay and in-game shots (both paths) you looked at, and every download
made or proposed (source, size, time).
