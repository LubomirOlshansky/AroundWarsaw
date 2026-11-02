#!/usr/bin/env python3
"""Paint Warsaw's bike pictograms (P-23) on the cycle paths.

    python3 -I tools/bike_marks.py [game/map/centrum.json] [--dry]   (rewrites the map in place)

Idea #9 from F's city-life list (docs/design/city-life-satire.md, 2026-11-02): the cycle paths
should read as Warsaw's real network, red asphalt with its markings. Every path already draws red
(map_builder.gd `_build_paths`), its crossings as red strips with the white squares of P-11
(`_build_crossings`). What the paths lacked is the white bike that Warsaw paints just past every
crossing, facing the riders coming off it, and now and then along a long stretch.

This adds `symbols` of kind `bike` (the painted cycle lanes' symbol, drawn by `_build_symbols`)
marked `"on": "path"`, so a second run first removes its own and gives the same result:

- a path end within END_NEAR of a cycle crossing gets one AT_END metres in, facing into the path;
- a stretch longer than EVERY gets one every EVERY metres, at least GAP from any other;
- not on a path under MIN_W wide (the bike is 1.3 m across), not on a footbridge or a bridge
  path without its deck index, not where the point lies on a road's carriageway (a path drawn
  across a road with no crossing mapped).

bake_osm.py calls `apply(out)` after car_free; this file is also a command line tool for a map
that is already baked (the cloud has no OpenStreetMap download). Standard library only,
deterministic. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

END_NEAR = 3.0
AT_END = 4.5
EVERY = 110.0
GAP = 35.0
MIN_W = 1.6
MIN_LEN = 14.0
CELL = 32.0


def _pts(p):
    q = p["p"]
    return [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]


def _cum(pts):
    out = [0.0]
    for a, b in zip(pts, pts[1:]):
        out.append(out[-1] + math.dist(a, b))
    return out


def _at(pts, cum, s):
    """The point s metres along the polyline and the unit direction of its segment there."""
    for i in range(len(pts) - 1):
        if cum[i + 1] >= s or i == len(pts) - 2:
            seg = cum[i + 1] - cum[i]
            t = 0.0 if seg < 1e-6 else max(0.0, min(1.0, (s - cum[i]) / seg))
            a, b = pts[i], pts[i + 1]
            d = math.dist(a, b)
            if d < 1e-6:
                return None
            return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t), ((b[0] - a[0]) / d, (b[1] - a[1]) / d)
    return None


def _seg_dist(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ll = dx * dx + dz * dz
    t = 0.0 if ll < 1e-9 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / ll))
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dz)


class _Grid:
    """Segments by CELL-metre cell, each with a payload (a half width, or None)."""

    def __init__(self):
        self.cells = {}

    def add_line(self, pts, payload, pad):
        for a, b in zip(pts, pts[1:]):
            x0, x1 = sorted((a[0], b[0]))
            z0, z1 = sorted((a[1], b[1]))
            for i in range(int(math.floor((x0 - pad) / CELL)), int(math.floor((x1 + pad) / CELL)) + 1):
                for j in range(int(math.floor((z0 - pad) / CELL)), int(math.floor((z1 + pad) / CELL)) + 1):
                    self.cells.setdefault((i, j), []).append((a, b, payload))

    def near(self, p):
        return self.cells.get((int(math.floor(p[0] / CELL)), int(math.floor(p[1] / CELL))), [])


def _on_road(roads, p):
    for a, b, half in roads.near(p):
        if _seg_dist(p, a, b) < half:
            return True
    return False


def _eligible(p):
    return (p.get("k") == "cycle" and float(p.get("w", 2.0)) >= MIN_W and len(p["p"]) >= 4
            and not (p.get("_br") and "dk" not in p))


def apply(data):
    """Replaces the map's path pictograms; returns a one-line summary."""
    syms = data.setdefault("symbols", [])
    before = sum(1 for m in syms if m.get("on") == "path")
    syms[:] = [m for m in syms if m.get("on") != "path"]

    roads = _Grid()
    for r in data.get("roads", []):
        if r.get("k") in ("service", "living_street", "track", "pedestrian"):
            continue
        roads.add_line(_pts(r), float(r.get("w", 6.0)) * 0.5 + 0.3, float(r.get("w", 6.0)))
    crossings = _Grid()
    for p in data.get("paths", []):
        if p.get("k") == "cyclecross":
            crossings.add_line(_pts(p), None, END_NEAR)

    def near_crossing(e):
        return any(_seg_dist(e, a, b) < END_NEAR for a, b, _ in crossings.near(e))

    placed = []
    taken = _Grid()
    skipped_road = 0

    def put(pt, d, dk):
        nonlocal skipped_road
        if _on_road(roads, pt):
            skipped_road += 1
            return False
        if any(math.dist(pt, a) < GAP for a, _, _ in taken.near(pt)):
            return False
        m = {"k": "bike", "x": round(pt[0], 2), "z": round(pt[1], 2), "d": [round(d[0], 3), round(d[1], 3)], "on": "path"}
        if dk is not None:
            m["dk"] = dk
        placed.append(m)
        taken.add_line([pt, pt], None, 0.0)
        return True

    ends = 0
    for p in data.get("paths", []):
        if not _eligible(p):
            continue
        pts = _pts(p)
        cum = _cum(pts)
        length = cum[-1]
        if length < MIN_LEN:
            continue
        dk = p.get("dk")
        # The ends first: past a crossing, facing the riders coming off it.
        for s, sign, e in ((AT_END, 1.0, pts[0]), (length - AT_END, -1.0, pts[-1])):
            if near_crossing(e):
                hit = _at(pts, cum, s)
                if hit and put(hit[0], (hit[1][0] * sign, hit[1][1] * sign), dk):
                    ends += 1
        # Then the long stretches.
        n = int(length // EVERY)
        for k in range(n):
            s = length * (k + 1) / (n + 1)
            hit = _at(pts, cum, s)
            if hit:
                put(hit[0], hit[1], dk)
    syms.extend(placed)
    return (f"{len(placed)} bike pictograms on the cycle paths ({ends} past a crossing; "
            f"{skipped_road} points on a carriageway left; {before} replaced)")


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    print("bike_marks: " + apply(data))
    if "--dry" in argv:
        return 0
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"), ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
