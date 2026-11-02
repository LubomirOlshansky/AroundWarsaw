"""Checks game/data/park_details.json against the map (step `parkdetails`): the file is the one
tools/bake_park_details.py writes from today's centrum.json (`src`), every kind is known, the
count is inside the budget and no solid piece stands on a road, in a building or in water.

    python3 -I tools/check_park_details.py
"""
import json
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_park_details as B  # noqa: E402
import bake_street_pois as P  # noqa: E402

SOLID = ("statue", "fountain", "carousel", "playground", "gazebo", "sundial")


def main():
    doc = json.load(open(B.OUT))
    data = json.load(open(os.path.join(ROOT, "game", "map", "centrum.json")))
    problems = []
    if doc["src"] != B.src_hash(data):
        problems.append("stale: re-run tools/bake_park_details.py")
    items = doc["items"]
    if not 0 < len(items) <= B.MAX_ITEMS:
        problems.append("%d items" % len(items))
    solids = P.Solids(data)
    for kind, x, z, yaw, col in items:
        if kind not in B.KINDS:
            problems.append("unknown kind %s" % kind)
        elif kind in SOLID:
            what = solids.blocked(x, z, B.RADIUS[kind] * 0.5, skip=("tree", "bench", "pole", "bin"))
            if what in ("carriageway", "building", "water", "tram track", "rail"):
                problems.append("%s at %.0f, %.0f is on %s" % (kind, x, z, what))
    counts = {}
    for it in items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    for k in ("statue", "fountain", "carousel", "playground", "gazebo", "duck", "seated", "picnic"):
        if k not in counts:
            problems.append("no %s" % k)
    if problems:
        print("\n".join(problems[:20]))
        print("check_park_details: FAIL (%d)" % len(problems))
        sys.exit(1)
    print("check_park_details: OK %d items %s" % (len(items), json.dumps(counts, sort_keys=True)))


main()
