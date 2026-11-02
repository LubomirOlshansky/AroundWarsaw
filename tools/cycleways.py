#!/usr/bin/env python3
"""Tidy the cycle paths (`k == "cycle"`, on the ground): close the small gaps between their ends,
join the ways OpenStreetMap split into pieces, take out the spikes and the jitter, and round the
sharp corners, so the paths draw smoothly and the riders (city_life.gd joins paths at their ends)
ride on from one to the next instead of turning back at a 1-8 m gap.

    python3 -I tools/cycleways.py [game/map/centrum.json] [--dry]

bake_osm.py calls tidy() on its paths after the clip (a re-bake gives the same result); this CLI
applies it to a baked centrum.json in place (a second run changes next to nothing). Footbridge
and deck ways (`_br`, `_ly`, `dk`) are left alone: their heights are solved from their points.

Steps (constants below, all in metres):
  1. snap   an end within SNAP_END of another cycle path's end moves to the middle of the two; an end
            within SNAP_LINE of another path's line (a T) moves onto it (the line gets the point).
  2. join   two ways meeting at one point, nobody else there, similar width: one polyline.
  3. tidy   points closer than MIN_STEP merge; a spike (a turn over SPIKE_DEG on legs under
            SPIKE_LEG) goes; a corner turning more than CORNER_DEG is cut with two points
            CORNER_CUT from it (at most a third of each leg), the ends stay put.
"""
import json
import math
import os
import sys

SNAP_END = 3.0
SNAP_LINE = 2.5
MIN_STEP = 0.4
SPIKE_DEG = 150.0
SPIKE_LEG = 3.0
CORNER_DEG = 25.0
CORNER_CUT = 2.0
CORNER_MIN_LEG = 3.7   # shorter legs are a cut corner already (and keep the pass idempotent)
JOIN_W = 0.6
CELL = 16.0


def _pts(p):
    q = p["p"]
    return [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]


def _flat(pts):
    return [round(v, 1) for pt in pts for v in pt]


def _eligible(p):
    return p.get("k") == "cycle" and not p.get("_br") and not (p.get("_ly") or 0) and "dk" not in p and len(p["p"]) >= 4


def _turn(a, b, c):
    """The turning angle at b in degrees (0 straight on, 180 back on itself), and the two legs."""
    ux, uz, vx, vz = b[0] - a[0], b[1] - a[1], c[0] - b[0], c[1] - b[1]
    lu, lv = math.hypot(ux, uz), math.hypot(vx, vz)
    if lu < 1e-6 or lv < 1e-6:
        return 0.0, lu, lv
    cs = max(-1.0, min(1.0, (ux * vx + uz * vz) / (lu * lv)))
    return math.degrees(math.acos(cs)), lu, lv


def _nearest_on(pt, ways, skip):
    """(distance, way index, segment, point) of the closest cycle line to `pt`, not way `skip`."""
    best = None
    for i, w in enumerate(ways):
        if i == skip:
            continue
        for s in range(len(w) - 1):
            a, b = w[s], w[s + 1]
            dx, dz = b[0] - a[0], b[1] - a[1]
            ll = dx * dx + dz * dz
            t = 0.0 if ll < 1e-9 else max(0.0, min(1.0, ((pt[0] - a[0]) * dx + (pt[1] - a[1]) * dz) / ll))
            q = (a[0] + dx * t, a[1] + dz * t)
            d = math.hypot(pt[0] - q[0], pt[1] - q[1])
            if best is None or d < best[0]:
                best = (d, i, s, q)
    return best


class _Grid:
    def __init__(self, ways):
        self.cells = {}
        for i, w in enumerate(ways):
            for pt in w:
                self.cells.setdefault((int(pt[0] // CELL), int(pt[1] // CELL)), set()).add(i)

    def near(self, pt):
        cx, cz = int(pt[0] // CELL), int(pt[1] // CELL)
        out = set()
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                out |= self.cells.get((cx + dx, cz + dz), set())
        return out


def _snap(ways, stats):
    grid = _Grid(ways)
    ends = {}   # (way, 0|1) -> point
    for i, w in enumerate(ways):
        ends[(i, 0)] = w[0]
        ends[(i, 1)] = w[-1]
    moved = {}
    for (i, e), pt in sorted(ends.items()):
        best = None
        for j in grid.near(pt):
            if j == i:
                continue
            for f in (0, 1):
                q = ends[(j, f)]
                d = math.hypot(pt[0] - q[0], pt[1] - q[1])
                if 0.05 < d <= SNAP_END and (best is None or d < best[0]):
                    best = (d, j, f, q)
        if best:
            d, j, f, q = best
            # the middle of the two ends (each moves by half), unless the other already moved
            tgt = moved.get((j, f)) or ((pt[0] + q[0]) / 2.0, (pt[1] + q[1]) / 2.0)
            moved[(i, e)] = tgt
            moved[(j, f)] = tgt
            stats["gaps"] += 1
    for (i, e), tgt in moved.items():
        ways[i][0 if e == 0 else -1] = (round(tgt[0], 1), round(tgt[1], 1))
    # a free end just off another path's line: onto it, and the line gets the point
    grid = _Grid(ways)
    ends_now = {pt for w in ways for pt in (w[0], w[-1])}
    for i, w in enumerate(ways):
        for e in (0, 1):
            pt = w[0] if e == 0 else w[-1]
            others = sum(1 for j in grid.near(pt) if j != i and (ways[j][0] == pt or ways[j][-1] == pt))
            if others:
                continue
            cand = [ways[j] for j in sorted(grid.near(pt)) if j != i]
            idx = [j for j in sorted(grid.near(pt)) if j != i]
            best = _nearest_on(pt, cand, -1)
            if not best or best[0] > SNAP_LINE or best[0] < 0.05:
                continue
            d, ci, s, q = best
            q = (round(q[0], 1), round(q[1], 1))
            tgt = ways[idx[ci]]
            if math.hypot(q[0] - tgt[s][0], q[1] - tgt[s][1]) > 0.05 and math.hypot(q[0] - tgt[s + 1][0], q[1] - tgt[s + 1][1]) > 0.05:
                tgt.insert(s + 1, q)
            w[0 if e == 0 else -1] = q
            stats["tees"] += 1
    return ways


def _join(ways, widths, stats):
    changed = True
    while changed:
        changed = False
        at = {}
        for i, w in enumerate(ways):
            if w is None:
                continue
            for e, pt in ((0, w[0]), (1, w[-1])):
                at.setdefault(pt, []).append((i, e))
        for pt, lst in at.items():
            if len(lst) != 2 or lst[0][0] == lst[1][0]:
                continue
            (i, ei), (j, ej) = lst
            if abs(widths[i] - widths[j]) > JOIN_W:
                continue
            a = ways[i] if ei == 1 else ways[i][::-1]       # ends at pt
            b = ways[j] if ej == 0 else ways[j][::-1]       # starts at pt
            ways[i] = a + b[1:]
            widths[i] = max(widths[i], widths[j])
            ways[j] = None
            stats["joined"] += 1
            changed = True
            break
    return ways


def _tidy_line(pts, stats):
    out = [pts[0]]
    for pt in pts[1:]:
        if math.hypot(pt[0] - out[-1][0], pt[1] - out[-1][1]) < MIN_STEP:
            if pt is pts[-1] and len(out) > 1:
                out[-1] = pt   # the end stays where it is
            continue
        out.append(pt)
    if len(out) < 2:
        out = [pts[0], pts[-1]]
    # spikes
    i = 1
    while i < len(out) - 1:
        ang, lu, lv = _turn(out[i - 1], out[i], out[i + 1])
        if ang > SPIKE_DEG and min(lu, lv) < SPIKE_LEG:
            del out[i]
            stats["spikes"] += 1
            i = max(1, i - 1)
        else:
            i += 1
    # corners
    res = [out[0]]
    for i in range(1, len(out) - 1):
        a, b, c = out[i - 1], out[i], out[i + 1]
        ang, lu, lv = _turn(a, b, c)
        if CORNER_DEG < ang <= SPIKE_DEG and min(lu, lv) >= CORNER_MIN_LEG:
            cu = min(CORNER_CUT, lu / 3.0)
            cv = min(CORNER_CUT, lv / 3.0)
            res.append((b[0] + (a[0] - b[0]) * cu / lu, b[1] + (a[1] - b[1]) * cu / lu))
            res.append((b[0] + (c[0] - b[0]) * cv / lv, b[1] + (c[1] - b[1]) * cv / lv))
            stats["corners"] += 1
        else:
            res.append(b)
    res.append(out[-1])
    return res


def tidy(paths):
    """Tidy the eligible cycle paths of `paths` (a list of baked path dicts); returns (paths, stats)."""
    stats = {"gaps": 0, "tees": 0, "joined": 0, "spikes": 0, "corners": 0}
    idx = [i for i, p in enumerate(paths) if _eligible(p)]
    ways = [_pts(paths[i]) for i in idx]
    widths = [float(paths[i].get("w", 2.0)) for i in idx]
    for _ in range(6):
        before = stats["gaps"] + stats["tees"]
        ways = _snap(ways, stats)
        if stats["gaps"] + stats["tees"] == before:
            break
    ways = _join(ways, widths, stats)
    keep = [i for i in range(len(idx)) if ways[i] is not None]
    new = {}
    for k in keep:
        line = _tidy_line(ways[k], stats)
        new[idx[k]] = {"p": _flat(line), "w": round(widths[k], 1), "k": "cycle"} if len(line) >= 2 else None
    gone = set(idx) - set(new)
    out = []
    for i, p in enumerate(paths):
        if i in gone:
            continue
        if i in new and new[i]:
            q = dict(p)
            q["p"], q["w"] = new[i]["p"], new[i]["w"]
            out.append(q)
        else:
            out.append(p)
    return out, stats


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    dry = "--dry" in argv
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    src = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(src) as f:
        data = json.load(f)
    before = [p for p in data["paths"] if p.get("k") == "cycle"]
    data["paths"], stats = tidy(data["paths"])
    after = [p for p in data["paths"] if p.get("k") == "cycle"]
    print(f"cycleways: {len(before)} -> {len(after)} ways; {stats['gaps']} gaps closed, {stats['tees']} ends put on a line, "
          f"{stats['joined']} ways joined, {stats['spikes']} spikes cut, {stats['corners']} corners rounded")
    if not dry:
        with open(src, "w") as f:
            json.dump(data, f, separators=(",", ":"), ensure_ascii=False)


if __name__ == "__main__":
    main(sys.argv[1:])
