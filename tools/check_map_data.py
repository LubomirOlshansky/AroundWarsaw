#!/usr/bin/env python3
"""Check the baked map data and the prebuilt city without opening Godot.

    python3 -I tools/check_map_data.py [--trees3d=N] [--pois=N]

Checks game/map/centrum.json against the counts the last full bake produced (a re-bake
that changes them must say so and update EXPECTED below in the same change), that the
lane graph and the Palm are present. Loop 3c: the same counts over the sectors
(tools/bake_sectors.py: index.json and sectors/<i>_<j>.json; a point thing near a border is in
both sectors' files, so each sector counts the ones standing in its own square), every
sector's file and prebuilt scene there, and
warns when the sector files are older than the bake (run tools/bake_sectors.py) or the
prebuilt sectors (sectors/s_<i>_<j>.scn, index.res, proxies.scn) older than anything they
are built from (the exported game loads them, so stale ones mean the phone shows yesterday's
city: rebuild WITH a renderer, see README "Sectors and streaming").

Prints one line per check: OK / WARN / FAIL. Exits 1 if any check fails.
Reads only; writes nothing.
"""
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map")

# The counts after the last full bake (loop 1, 2026-10-28): trees3d holds 6 values per
# tree (12,554 trees), pois are hospitals, beaches, parks, kebab stands, addresses, etc.
# Loop 3b-2: trees3d_crown, one crown scale per scanned tree (12,554: 75 by the roads, up to
# 100 in the parks; bake_osm.py crown_scales).
EXPECTED = {"trees3d": 75324, "pois": 1020, "trees3d_crown": 12554}

# What tools/bake_sectors.py reads to split the map, and what tools/bake_city.gd reads to build
# the prebuilt sectors: the baked map files and the scripts map_builder.gd runs (its preloads).
# Shaders are referenced by path, so they need no rebuild.
SPLIT_INPUTS = ["game/map/centrum.json", "game/map/lod2.bin", "game/map/lod2.json", "tools/bake_sectors.py"]
CITY_INPUTS = [
    "game/map/index.json", "game/map/lod2.bin", "game/map/terrain.json",
    "game/map/ao.bin", "game/map/lights.bin", "game/map/water.bin",
    "game/scripts/map_builder.gd", "game/scripts/chunked_surface.gd",
    "game/scripts/neon_signs.gd", "game/scripts/landmarks.gd", "game/scripts/sector_proxies.gd",
    "game/scripts/models.gd",
]


def main() -> int:
    expected = dict(EXPECTED)
    for arg in sys.argv[1:]:
        key, _, value = arg.lstrip("-").partition("=")
        if key in expected and value.isdigit():
            expected[key] = int(value)
        else:
            print(f"unknown argument {arg!r}; use --trees3d=N, --pois=N or --trees3d_crown=N")
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

    sectors(data, expected, report)
    print("map data: " + ("OK" if failures == 0 else f"{failures} FAILED"))
    return 0 if failures == 0 else 1


def newest(paths):
    """The newest of these repo paths (and the file), or (0, None)."""
    best = (0.0, None)
    for p in paths:
        full = os.path.join(ROOT, p)
        if os.path.exists(full) and os.path.getmtime(full) > best[0]:
            best = (os.path.getmtime(full), p)
    return best


def sectors(data, expected, report):
    """Loop 3c: the sector split and the prebuilt sectors."""
    index_path = os.path.join(MAP, "index.json")
    try:
        with open(index_path, encoding="utf-8") as f:
            index = json.load(f)
    except (OSError, ValueError) as e:
        report("FAIL", "index.json", f"can't read {index_path}: {e} (run python3 -I tools/bake_sectors.py)")
        return
    keys = [tuple(k) for k in index.get("sectors", {}).get("keys", [])]
    if not keys:
        report("FAIL", "index.json", "no sector grid (run python3 -I tools/bake_sectors.py)")
        return
    size = float(index["sectors"].get("size", 512.0))
    trees, crowns = 0, 0
    files, missing = 0, []
    for k in keys:
        path = os.path.join(MAP, "sectors", "%d_%d.json" % k)
        try:
            with open(path, encoding="utf-8") as f:
                s = json.load(f)
        except (OSError, ValueError):
            missing.append("%d_%d.json" % k)
            continue
        files += 1
        real = s.get("trees3d", [])
        crown = s.get("trees3d_crown", [])
        for i in range(0, len(real) - 5, 6):
            if (math.floor(real[i] / size), math.floor(real[i + 1] / size)) == k:
                trees += 1
                crowns += 1 if i // 6 < len(crown) else 0
    if missing:
        report("FAIL", "sectors", "%d sector files missing: %s (run tools/bake_sectors.py)" % (len(missing), ", ".join(missing[:4])))
    report("OK" if trees * 6 == expected["trees3d"] else "FAIL", "sectors trees3d",
           f"{trees * 6} values over {files} sectors (expected {expected['trees3d']})")
    report("OK" if crowns == expected["trees3d_crown"] else "FAIL", "sectors trees3d_crown",
           f"{crowns} over the sectors (expected {expected['trees3d_crown']})")
    pois = len(index.get("pois", []))
    report("OK" if pois == expected["pois"] else "FAIL", "index pois", f"{pois} (expected {expected['pois']})")
    report("OK" if index.get("graph", {}).get("edges") and index.get("palm") else "FAIL", "index graph, palm",
           "present" if index.get("graph", {}).get("edges") and index.get("palm") else "missing")
    split_t, split_by = newest(SPLIT_INPUTS)
    oldest = min((os.path.getmtime(os.path.join(MAP, "sectors", "%d_%d.json" % k)) for k in keys
                  if os.path.exists(os.path.join(MAP, "sectors", "%d_%d.json" % k))), default=0.0)
    if oldest < split_t or os.path.getmtime(index_path) < split_t:
        report("WARN", "sector files", f"older than {split_by}: run python3 -I tools/bake_sectors.py")
    else:
        report("OK", "sector files", "newer than centrum.json and lod2.*")
    scenes = [os.path.join(MAP, "sectors", "s_%d_%d.scn" % k) for k in keys]
    scenes += [os.path.join(MAP, "index.res"), os.path.join(MAP, "proxies.scn")]
    absent = [os.path.relpath(p, MAP) for p in scenes if not os.path.exists(p)]
    if absent:
        report("FAIL", "prebuilt sectors", "missing: %s: the exported game has no city there" % ", ".join(absent[:4]))
        return
    built = min(os.path.getmtime(p) for p in scenes)
    city_t, city_by = newest(CITY_INPUTS + ["game/map/sectors/%d_%d.json" % k for k in keys])
    if city_t > built:
        report("WARN", "prebuilt sectors", f"older than {city_by}: rebuild them with a renderer "
               "(godot --path game --resolution 320x180 --script res://tools/bake_city.gd, never --headless)")
    else:
        report("OK", "prebuilt sectors", f"{len(keys)} sector scenes, index.res and proxies.scn newer than every input")


if __name__ == "__main__":
    sys.exit(main())
