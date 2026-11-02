"""Checks game/data/monuments.json against the map and the OSM cache (step `monuments`): the file is
the one tools/bake_monuments.py writes from today's docs/inventory/osm_candidates.json (`src`), every
kind is known, the count is inside the budget, no free-standing piece stands on a road, in a building
or in water, every plaque is on a building's wall, and nothing stands where a hand-built monument or
another thread's monument is (bake_monuments.SKIP).

    python3 -I tools/check_monuments.py
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_monuments as B  # noqa: E402
import bake_street_pois as P  # noqa: E402


def main():
    doc = json.load(open(B.OUT))
    data = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json")))
    problems = []
    if doc["src"] != B.src_hash(B.points(B.OSM)):
        problems.append("stale: re-run tools/bake_monuments.py")
    items = doc["items"]
    if not 0 < len(items) <= B.MAX_ITEMS:
        problems.append("%d items" % len(items))
    lod2 = B.load_lod2()   # None in CI's quick job: the plaques' walls are then not checked
    solids = P.Solids(data, lod2)
    baker = B.Baker(data, lod2)
    for kind, x, z, yaw, col, name in items:
        if kind not in B.KINDS:
            problems.append("unknown kind %s" % kind)
            continue
        if B.skipped(name, x, z) or any(part == "" and math.hypot(x - sx, z - sz) < r for part, sx, sz, r in B.SKIP):
            problems.append("%s %s at %.0f, %.0f stands on a hand-built or owned monument" % (kind, name, x, z))
        if kind == "plaque":
            if lod2 is None:
                continue
            near = min((P.seg_dist(x, z, a, b) for pts, x0, x1, z0, z1 in baker.buildings
                        if x0 - 1 < x < x1 + 1 and z0 - 1 < z < z1 + 1
                        for a, b in zip(pts, pts[1:] + pts[:1])), default=99.0)
            if near > 0.3:
                problems.append("plaque %s at %.0f, %.0f is off its wall" % (name, x, z))
            continue
        what = solids.blocked(x, z, B.RADIUS[kind] * 0.5, skip=("tree", "bench", "pole", "bin", "bike rack", "column"))
        if what in ("carriageway", "building", "water", "tram track", "rail"):
            problems.append("%s %s at %.0f, %.0f is on %s" % (kind, name, x, z, what))
    counts = {}
    for it in items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    for k in ("statue", "bust", "stone", "stele", "plaque", "allegory"):
        if k not in counts:
            problems.append("no %s" % k)
    if problems:
        print("\n".join(problems[:20]))
        print("check_monuments: FAIL (%d)" % len(problems))
        sys.exit(1)
    print("check_monuments: OK %d items %s" % (len(items), json.dumps(counts, sort_keys=True)))


main()
