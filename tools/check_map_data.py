#!/usr/bin/env python3
"""Check the baked map data and the prebuilt city without opening Godot.

    python3 -I tools/check_map_data.py [--trees3d=N] [--pois=N] [--fresh]

Checks game/map/centrum.json against the counts the last full bake produced (a re-bake
that changes them must say so and update EXPECTED below in the same change), that the
lane graph and the Palm are present. Loop 3c: the same counts over the sectors
(tools/bake_sectors.py: index.json and sectors/<i>_<j>.json; a point thing near a border is in
both sectors' files, so each sector counts the ones standing in its own square), every
sector's file and prebuilt scene there.

Loop 3d-1: the split and the prebuilt sectors (index.json, sectors/*, index.res, proxies.scn,
shared/) are derived and not committed: when they are missing this says "missing: run
tools/setup_map.sh" (a WARN, not a FAIL). Freshness is by content: bake_sectors.py writes
sectors/split.stamp (the SHA-256 of what it read) and bake_city.gd writes sectors/city.stamp
(the split's digest and the SHA-256 of the maps and scripts it builds from); a stamp that
doesn't match today's files is a WARN (stale: re-run, see README "Sectors and streaming").

--fresh: only the derived files, quietly: exit 0 when the split and the prebuilt sectors are
there and match their inputs, 3 when either is missing or stale (tools/setup_map.sh
--if-needed and tools/verify.sh use it).

Prints one line per check: OK / WARN / FAIL. Exits 1 if any check fails.
Reads only; writes nothing.
"""
import hashlib
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

# Loop 3d-1: what tools/bake_sectors.py reads to split the map (map-dir files, and the script
# itself; the same names as its SPLIT_INPUTS), and what tools/bake_city.gd builds the prebuilt
# sectors from besides the split (res:// paths: its CITY_INPUTS; the split itself is covered by
# split.stamp's digest). Shaders are referenced by path, so they need no rebuild.
SPLIT_INPUTS = ["centrum.json", "lod2.bin", "lod2.json"]
CITY_INPUTS = ["map/lod2.bin", "map/terrain.json", "map/ao.bin", "map/lights.bin", "map/water.bin",
               "scripts/map_builder.gd", "scripts/chunked_surface.gd", "scripts/neon_signs.gd",
               "scripts/landmarks.gd", "scripts/sector_proxies.gd", "scripts/models.gd",
               "scripts/pixel_font.gd", "tools/bake_city.gd"]
SETUP = "run tools/setup_map.sh"


def main() -> int:
    expected = dict(EXPECTED)
    if "--fresh" in sys.argv[1:]:
        state = freshness()
        print("derived map files: %s" % state[1])
        return 0 if state[0] == "OK" else 3
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


def sha256_file(path):
    """The file's SHA-256 (hex), or "" when it isn't there."""
    if not os.path.exists(path):
        return ""
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def split_state():
    """("OK" | "MISSING" | "STALE", detail, split digest) for index.json and sectors/*.json."""
    index_path = os.path.join(MAP, "index.json")
    if not os.path.exists(index_path):
        return "MISSING", "missing: no game/map/index.json (the sector split): " + SETUP, ""
    stamp = read_json(os.path.join(MAP, "sectors", "split.stamp"))
    if not isinstance(stamp, dict):
        return "STALE", "no sectors/split.stamp (split before loop 3d-1): run python3 -I tools/bake_sectors.py", ""
    now = {f: sha256_file(os.path.join(MAP, f)) for f in SPLIT_INPUTS}
    now["bake_sectors.py"] = sha256_file(os.path.join(ROOT, "tools", "bake_sectors.py"))
    changed = [f for f, h in sorted(now.items()) if stamp.get("inputs", {}).get(f) != h]
    if changed:
        return "STALE", "made from another %s: run python3 -I tools/bake_sectors.py" % ", ".join(changed), ""
    return "OK", "made from today's %s" % ", ".join(sorted(now)), stamp.get("digest", "")


def city_state(keys, split_digest):
    """("OK" | "MISSING" | "STALE", detail) for the prebuilt sectors, index.res, proxies.scn."""
    scenes = [os.path.join(MAP, "sectors", "s_%d_%d.scn" % k) for k in keys]
    scenes += [os.path.join(MAP, "index.res"), os.path.join(MAP, "proxies.scn"), os.path.join(MAP, "shared")]
    absent = [os.path.relpath(p, MAP) for p in scenes if not os.path.exists(p)]
    if absent:
        return "MISSING", "missing: %s%s: %s" % (", ".join(absent[:4]), " and %d more" % (len(absent) - 4) if len(absent) > 4 else "", SETUP)
    rebuild = ("rebuild them with a renderer (godot --path game --resolution 320x180 --script "
               "res://tools/bake_city.gd, never --headless)")
    stamp = read_json(os.path.join(MAP, "sectors", "city.stamp"))
    if not isinstance(stamp, dict):
        return "STALE", "no sectors/city.stamp (built before loop 3d-1): " + rebuild
    changed = [p for p in CITY_INPUTS if stamp.get("inputs", {}).get(p) != sha256_file(os.path.join(ROOT, "game", p))]
    if split_digest and stamp.get("split") != split_digest:
        changed.insert(0, "the sector split")
    if changed:
        return "STALE", "built from another %s: %s" % (", ".join(changed[:4]), rebuild)
    return "OK", "%d sector scenes, index.res and proxies.scn built from today's split, maps and scripts" % len(keys)


def freshness():
    """--fresh: the split, then the prebuilt sectors."""
    state, detail, digest = split_state()
    if state != "OK":
        return state, detail
    index = read_json(os.path.join(MAP, "index.json")) or {}
    keys = [tuple(k) for k in index.get("sectors", {}).get("keys", [])]
    missing = [k for k in keys if not os.path.exists(os.path.join(MAP, "sectors", "%d_%d.json" % k))]
    if not keys or missing:
        return "MISSING", "sector files missing: " + SETUP
    state, detail = city_state(keys, digest)
    return state, ("split OK; " if state == "OK" else "") + detail


def sectors(data, expected, report):
    """Loop 3c: the sector split and the prebuilt sectors (loop 3d-1: derived, maybe missing)."""
    state, detail, digest = split_state()
    if state == "MISSING":
        report("WARN", "sector split", detail)
        return
    index_path = os.path.join(MAP, "index.json")
    index = read_json(index_path)
    if not isinstance(index, dict):
        report("FAIL", "index.json", f"can't read {index_path} (run python3 -I tools/bake_sectors.py)")
        return
    keys = [tuple(k) for k in index.get("sectors", {}).get("keys", [])]
    if not keys:
        report("FAIL", "index.json", "no sector grid (run python3 -I tools/bake_sectors.py)")
        return
    size = float(index["sectors"].get("size", 512.0))
    trees, crowns = 0, 0
    files, missing = 0, []
    for k in keys:
        s = read_json(os.path.join(MAP, "sectors", "%d_%d.json" % k))
        if not isinstance(s, dict):
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
        report("WARN", "sectors", "missing: %d sector files (%s): %s" % (len(missing), ", ".join(missing[:4]), SETUP))
        return
    report("OK" if trees * 6 == expected["trees3d"] else "FAIL", "sectors trees3d",
           f"{trees * 6} values over {files} sectors (expected {expected['trees3d']})")
    report("OK" if crowns == expected["trees3d_crown"] else "FAIL", "sectors trees3d_crown",
           f"{crowns} over the sectors (expected {expected['trees3d_crown']})")
    pois = len(index.get("pois", []))
    report("OK" if pois == expected["pois"] else "FAIL", "index pois", f"{pois} (expected {expected['pois']})")
    report("OK" if index.get("graph", {}).get("edges") and index.get("palm") else "FAIL", "index graph, palm",
           "present" if index.get("graph", {}).get("edges") and index.get("palm") else "missing")
    report("OK" if state == "OK" else "WARN", "sector files", detail)
    state, detail = city_state(keys, digest)
    report("OK" if state == "OK" else "WARN", "prebuilt sectors", detail)


if __name__ == "__main__":
    sys.exit(main())
