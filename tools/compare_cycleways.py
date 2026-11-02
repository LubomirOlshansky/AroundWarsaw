#!/usr/bin/env python3
"""Compare the map's cycle network with OpenStreetMap's: what Warsaw has that we don't draw.

    python3 -I tools/compare_cycleways.py [data/work/demo/osm_demo.json] [game/map/centrum.json] [--list]

Idea #9 (F, 2026-11-02; docs/design/city-life-satire.md). Reads the raw Overpass export the bake
reads (bake_osm.py OSM_SRC) and the baked map, and sorts every cycle-relevant way of the export
inside the map into a class:

  track     highway=cycleway (a separate red path), or path/bridleway with bicycle=designated
  shared    footway with bicycle=designated (a ciąg pieszo-rowerowy: we draw it as footway)
  lane      a road with cycleway[:side]=lane (painted lane)
  busway    a road with cycleway[:side]=share_busway (bus lane open to bikes)
  sharrow   a road with cycleway[:side]=shared_lane (sharrows), or bicycle_road=yes
  contra    a one-way road with cycleway[:side]=opposite* or oneway:bicycle=no (contraflow)
  crossing  cycleway=crossing (a P-11 crossing)

then samples each way every STEP metres and counts a sample as drawn when the map has a cycle
path, cycle crossing or painted cycle lane within NEAR metres (NEAR_LANE for a painted lane,
which lies at the kerb), and a contraflow, bus-lane or sharrow way as drawn when tools/bike_network.py
painted a bike of its kind on it. Prints metres in the box and the
share drawn per class, and with --list the longest undrawn stretches with their street names
(the "missing links" to fix in the bake, by data). Reads only. Standard library.
"""
import collections
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402  (the projection and the box)

STEP = 5.0
NEAR = 4.0
# A painted lane lies at the kerb, up to half a wide street from the way's centreline.
NEAR_LANE = 9.0
# Contraflow, bus lanes open to bikes and sharrows are marked by bikes painted on the street
# (tools/bike_network.py): a way counts as drawn when one of its kind lies this near its line.
SIGNED = {"contra": "contra", "busway": "busway", "sharrow": "sharrow"}
SIGN_NEAR = 8.0
CELL = 25.0


def classify(t):
    hw = t.get("highway", "")
    if not hw:
        return None
    if t.get("cycleway") == "crossing" or (hw in ("footway", "path", "cycleway") and t.get("footway") == "crossing"
                                           and t.get("bicycle") in ("designated", "yes")):
        return "crossing" if t.get("cycleway") == "crossing" or t.get("bicycle") == "designated" else None
    if hw == "cycleway" or (hw in ("path", "bridleway") and t.get("bicycle") == "designated"):
        return "track"
    if hw == "footway" and t.get("bicycle") == "designated":
        return "shared"
    vals = {t.get(k, "") for k in ("cycleway", "cycleway:both", "cycleway:left", "cycleway:right")}
    if "lane" in vals:
        return "lane"
    if "share_busway" in vals:
        return "busway"
    if any(v.startswith("opposite") for v in vals) or t.get("oneway:bicycle") == "no":
        return "contra"
    if "shared_lane" in vals or t.get("bicycle_road") == "yes":
        return "sharrow"
    if "track" in vals:
        return "track_tag"
    return None


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    src = args[0] if args else bake_osm.OSM_SRC
    dst = args[1] if len(args) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    els = json.load(open(src, encoding="utf-8"))["elements"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    data = json.load(open(dst, encoding="utf-8"))
    x0, z0, x1, z1 = data["bounds"]
    outside = data.get("outside", [])

    grid = collections.defaultdict(list)

    def add(q):
        pts = [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]
        for a, b in zip(pts, pts[1:]):
            for i in range(int(min(a[0], b[0]) // CELL) - 1, int(max(a[0], b[0]) // CELL) + 2):
                for j in range(int(min(a[1], b[1]) // CELL) - 1, int(max(a[1], b[1]) // CELL) + 2):
                    grid[(i, j)].append((a, b))
    for p in data["paths"]:
        if p["k"] in ("cycle", "cyclecross"):
            add(p["p"])
    for m in data.get("markings", []):
        if m["k"] in ("cycle", "cyclefill"):
            add(m["p"])

    signs = collections.defaultdict(list)
    for m in data.get("symbols", []):
        if m.get("on") in SIGNED.values():
            signs[m["on"]].append((m["x"], m["z"]))

    def marked(kind, pts):
        for sx, sz in signs[kind]:
            for a, b in zip(pts, pts[1:]):
                if min(a[0], b[0]) - SIGN_NEAR <= sx <= max(a[0], b[0]) + SIGN_NEAR and \
                        min(a[1], b[1]) - SIGN_NEAR <= sz <= max(a[1], b[1]) + SIGN_NEAR:
                    dx, dz = b[0] - a[0], b[1] - a[1]
                    ll = dx * dx + dz * dz
                    t = 0.0 if ll < 1e-9 else max(0.0, min(1.0, ((sx - a[0]) * dx + (sz - a[1]) * dz) / ll))
                    if math.hypot(sx - a[0] - t * dx, sz - a[1] - t * dz) < SIGN_NEAR:
                        return True
        return False

    def drawn(x, z, near=NEAR):
        for a, b in grid.get((int(x // CELL), int(z // CELL)), []):
            dx, dz = b[0] - a[0], b[1] - a[1]
            ll = dx * dx + dz * dz
            t = 0.0 if ll < 1e-9 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ll))
            if math.hypot(x - a[0] - t * dx, z - a[1] - t * dz) < near:
                return True
        return False

    def inside(x, z):
        return x0 <= x <= x1 and z0 <= z <= z1 and not any(o[0] <= x <= o[2] and o[1] <= z <= o[3] for o in outside)

    total = collections.Counter()
    have = collections.Counter()
    gaps = []
    for e in els:
        if e["type"] != "way":
            continue
        t = e.get("tags", {})
        if t.get("tunnel") not in (None, "no") or t.get("layer", "0").lstrip("-").isdigit() and int(t.get("layer", "0")) < 0:
            continue
        c = classify(t)
        if not c:
            continue
        pts = [bake_osm.project(*nodes[n]) for n in e.get("nodes", []) if n in nodes]
        signed = c in SIGNED and marked(SIGNED[c], pts)
        near = NEAR_LANE if c == "lane" else NEAR
        run = 0.0
        for a, b in zip(pts, pts[1:]):
            seg = math.dist(a, b)
            n = max(1, int(seg // STEP))
            for k in range(n):
                x = a[0] + (b[0] - a[0]) * (k + 0.5) / n
                z = a[1] + (b[1] - a[1]) * (k + 0.5) / n
                if not inside(x, z):
                    continue
                total[c] += seg / n
                if signed or drawn(x, z, near):
                    have[c] += seg / n
                    if run > 20:
                        gaps.append((run, c, t.get("name", ""), e["id"], round(x), round(z)))
                    run = 0.0
                else:
                    run += seg / n
        if run > 20:
            gaps.append((run, c, t.get("name", ""), e["id"], round(pts[-1][0]), round(pts[-1][1])))
    print(f"{'class':<10}{'in map (m)':>12}{'drawn (m)':>12}{'share':>8}")
    for c in sorted(total, key=lambda k: -total[k]):
        print(f"{c:<10}{total[c]:>12.0f}{have[c]:>12.0f}{have[c] / total[c]:>8.0%}")
    if "--list" in argv:
        gaps.sort(reverse=True)
        print("\nlongest undrawn stretches (m, class, name, way, end x z):")
        for g in gaps[:80]:
            print(f"{g[0]:7.0f}  {g[1]:<9}{g[2][:32]:<33}{g[3]:>12}  {g[4]} {g[5]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
