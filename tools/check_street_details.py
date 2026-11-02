"""Checks game/data/street_details.json (tools/bake_street_details.py, docs/design/street-details.md).

    python3 -I tools/check_street_details.py

Fails (exit 1) when the file is stale against game/map/centrum.json (`src`), or an item: has a
kind the bake doesn't know, lies in the first scene's rectangle or round the Palm or the Rotunda,
is blocked (carriageway, kerb, track, building, platform, lamp, tree, bench, bin, shelter, parked
car... bake_street_pois.Solids; the stop kit may stand on its shelter's platform), or breaks the
budget (900 in all, 70 a 512 m sector); or when two kiosks/stalls stand nearer than 250 m. Prints
`check_street_details: OK` and the counts. Standard library only.
"""
import collections
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_details as B  # noqa: E402


def main():
    with open(os.path.join(ROOT, "game", "map", "centrum.json"), encoding="utf-8") as f:
        data = json.load(f)
    with open(B.OUT, encoding="utf-8") as f:
        doc = json.load(f)
    bad = []
    if doc.get("src") != B.src_hash(data):
        bad.append("street_details.json is stale against centrum.json: re-run tools/bake_street_details.py")
    items = doc["items"]
    if len(items) > B.MAX_ITEMS:
        bad.append("%d items, over %d" % (len(items), B.MAX_ITEMS))
    pl = B.Placer(data)
    sectors = collections.Counter()
    for kind, x, z, yaw, colour in items:
        if kind not in B.KINDS:
            bad.append("unknown kind %s" % kind)
            continue
        sectors[(int(x // B.SECTOR), int(z // B.SECTOR))] += 1
        if pl.excluded(x, z):
            bad.append("%s at %.1f,%.1f is in an excluded area" % (kind, x, z))
        skip = ("shelter", "platform", "island") if kind in ("post", "ticket") else ()
        if colour == B.ON_PLATFORM:
            skip = B.PLATFORM_SKIP
        why = pl.solids.blocked(x, z, (B.PLATFORM_R if colour == B.ON_PLATFORM else B.RADIUS[kind]) - 0.05, skip=skip)
        # a prop is checked against the others by the bake (the items list); here against the map
        if why:
            bad.append("%s at %.1f,%.1f is blocked by %s" % (kind, x, z, why))
    for key, n in sectors.items():
        if n > B.MAX_SECTOR:
            bad.append("sector %s holds %d items, over %d" % (key, n, B.MAX_SECTOR))
    for kind in ("kiosk", "stall"):
        pts = [(i[1], i[2]) for i in items if i[0] == kind]
        for a in range(len(pts)):
            for b in range(a + 1, len(pts)):
                if math.hypot(pts[a][0] - pts[b][0], pts[a][1] - pts[b][1]) < B.SPACING[kind] - 0.5:
                    bad.append("two %ss %.0f m apart at %s" % (kind, math.hypot(pts[a][0] - pts[b][0], pts[a][1] - pts[b][1]), pts[a]))
    counts = collections.Counter(i[0] for i in items)
    print("check_street_details counts: %d items (%s)" % (len(items), ", ".join("%s %d" % kv for kv in sorted(counts.items()))))
    for b in bad[:30]:
        print("  WRONG: " + b)
    if bad:
        print("check_street_details: FAIL (%d problems)" % len(bad))
        sys.exit(1)
    print("check_street_details: OK")


if __name__ == "__main__":
    main()
