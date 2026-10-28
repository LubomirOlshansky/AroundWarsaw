#!/usr/bin/env python3
"""Check the baked map data and the prebuilt city without opening Godot.

    python3 -I tools/check_map_data.py [--trees3d=N] [--pois=N]

Checks game/map/centrum.json against the counts the last full bake produced (a re-bake
that changes them must say so and update EXPECTED below in the same change), that the
lane graph and the Palm are present, and warns when game/map/city.scn is older than
anything it is built from (the exported game loads city.scn, so a stale one means the
phone shows yesterday's city: rebuild it WITH a renderer, see README "Layout").

Prints one line per check: OK / WARN / FAIL. Exits 1 if any check fails.
Reads only; writes nothing.
"""
import json
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map")

# The counts after the last full bake (loop 1, 2026-10-28): trees3d holds 6 values per
# tree (12,554 trees), pois are hospitals, beaches, parks, kebab stands, addresses, etc.
EXPECTED = {"trees3d": 75324, "pois": 1020}

# What tools/bake_city.gd reads to build city.scn: the baked map files and the scripts
# map_builder.gd runs (its preloads). Shaders are referenced by path, so they need no rebuild.
CITY_INPUTS = [
    "game/map/centrum.json", "game/map/lod2.bin", "game/map/lod2.json", "game/map/terrain.json",
    "game/map/ao.bin", "game/map/lights.bin", "game/map/water.bin",
    "game/scripts/map_builder.gd", "game/scripts/chunked_surface.gd",
    "game/scripts/neon_signs.gd", "game/scripts/landmarks.gd",
]


def main() -> int:
    expected = dict(EXPECTED)
    for arg in sys.argv[1:]:
        key, _, value = arg.lstrip("-").partition("=")
        if key in expected and value.isdigit():
            expected[key] = int(value)
        else:
            print(f"unknown argument {arg!r}; use --trees3d=N or --pois=N")
            return 2
    failures = 0

    def report(status: str, name: str, detail: str) -> None:
        nonlocal failures
        if status == "FAIL":
            failures += 1
        print(f"{status:<4} {name}: {detail}")

    path = os.path.join(MAP, "centrum.json")
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError) as e:
        report("FAIL", "centrum.json", f"can't read {path}: {e}")
        return 1

    for key, want in expected.items():
        got = len(data.get(key, []))
        report("OK" if got == want else "FAIL", key, f"{got} values (expected {want})")

    graph = data.get("graph")
    if isinstance(graph, dict) and graph.get("edges"):
        report("OK", "graph", "present: %d nodes in the connected part, %d directed edges, "
               "%d signal controllers, %d portals" % (len(graph.get("scc", [])), len(graph["edges"]),
                                                      len(graph.get("ctrl", [])), len(graph.get("portals", []))))
    else:
        report("FAIL", "graph", "missing or empty (the lane graph: traffic, races and jobs need it)")

    palm = data.get("palm")
    if palm:
        report("OK", "palm", f"present at {palm[0]}, {palm[1]}")
    else:
        report("FAIL", "palm", "missing (bake_osm.py writes it from GUGIK_NOT_TREES)")

    scn = os.path.join(MAP, "city.scn")
    if not os.path.exists(scn):
        report("FAIL", "city.scn", "missing: the exported game has no city")
    else:
        built = os.path.getmtime(scn)
        newer = [p for p in CITY_INPUTS
                 if os.path.exists(os.path.join(ROOT, p)) and os.path.getmtime(os.path.join(ROOT, p)) > built]
        if newer:
            report("WARN", "city.scn", "older than " + ", ".join(newer) + ": rebuild it with a renderer "
                   "(godot --path game --resolution 320x180 --script res://tools/bake_city.gd, never --headless)")
        else:
            report("OK", "city.scn", "newer than every input")

    print("map data: " + ("OK" if failures == 0 else f"{failures} FAILED"))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
