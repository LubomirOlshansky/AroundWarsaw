"""Loop 3d-1: the terrain on its own, before every other bake (docs/DEMO.md 3.3).

    python3 -I tools/bake_terrain.py [data/work/demo/terrain_10m.json] [game/map]

Reads the 10 m elevation grid in local map metres (tools/prepare_demo.py cuts the demo fetch's
grid to the box; EVRF2007 heights) and writes game/map/terrain.json: the same grid with heights
relative to BASE_HEIGHT (100 m above sea level is y = 0 in the game). Until loop 3c
bake_gugik.py wrote it, but bake_osm.py reads it for the decks and bake_gugik.py reads
centrum.json, which made a circle once the box grew; now the order is bake_terrain, bake_osm,
bake_gugik (docs/DEVELOPMENT.md "Map data").
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402

BASE_HEIGHT = 100.0  # bake_gugik.BASE_HEIGHT (kept here so this step needs no CityGML parser)


def main(src, out_dir):
    d = json.load(open(src))
    origin = d.get("origin")
    if origin and (abs(origin[0] - bake_osm.LAT0) > 1e-9 or abs(origin[1] - bake_osm.LON0) > 1e-9):
        raise SystemExit("bake_terrain: the grid's origin %s is not bake_osm.ORIGIN %s" % (origin, bake_osm.ORIGIN))
    t = {"x0": d["x0"], "z0": d["z0"], "step": d["step"], "nx": d["nx"], "nz": d["nz"],
         "h": [round(v - BASE_HEIGHT, 2) for v in d["h"]]}
    if len(t["h"]) != t["nx"] * t["nz"]:
        raise SystemExit("bake_terrain: %d heights for %d x %d" % (len(t["h"]), t["nx"], t["nz"]))
    with open(os.path.join(out_dir, "terrain.json"), "w") as f:
        json.dump(t, f, separators=(",", ":"))
    print("terrain: %d x %d points every %.0f m from (%.1f, %.1f), heights %.1f to %.1f m (relative to %.0f m)" % (
        t["nx"], t["nz"], t["step"], t["x0"], t["z0"], min(t["h"]), max(t["h"]), BASE_HEIGHT))


if __name__ == "__main__":
    root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(bake_osm.WORK, "terrain_10m.json"),
         sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "game", "map"))
