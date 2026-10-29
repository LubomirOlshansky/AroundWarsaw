"""The streets at grade over the whole map (map review B, 2026-10-29): classes of defect that the
road and deck rules (tools/check_roads.py C1-C10) don't see, read from game/map/centrum.json.

Usage: python3 -I tools/check_streets.py [--map=DIR] [--list]

  S1 poles on the asphalt: a street lamp or signal pole at grade standing on a carriageway
     (a carriageway area or a drawn road strip), not on a traffic island or a median.
  S2 zebras off the asphalt: a zebra crossing with 0.75 m or more of its stripes where there is
     no carriageway (the pavement, a tram bed, a median, an island), a cycle path excepted.
  S3 medians inside a junction: a median strip (grass or tram bed, with its kerb) laid in the
     middle of a junction where a dual carriageway crosses another (beside a one-way road's
     piece of up to 30 m between two halves of one crossing street), per 3 m cross-section.
  S4 grass medians on tram tracks: a raised grass median a tram track runs along or over.

Prints each finding with its --at= (with --list), then `check_streets counts: S1 n, ...` and
`check_streets: OK` (exit 0) or `check_streets: FAIL ...` (exit 1). S1, S2 and S4 fail; S3 is
reported only (it also counts real median noses at a junction's edge).
Today's map (map review B): before the fixes S1 58, S2 457, S3 20, S4 78; after S1 0, S2 0,
S3 18, S4 0.
"""
import json
import math
import os
import sys
from collections import defaultdict

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
HATCH = ("emergency", "prohibited")
MINOR = ("service", "living_street")


def pairs(f):
    return list(zip(f[0::2], f[1::2]))


def pip(x, z, pts):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, zi = pts[i]
        xj, zj = pts[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            inside = not inside
        j = i
    return inside


def segd(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = dx * dx + dz * dz
    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
    return math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)


def offset(pts, off):
    """The polyline `off` metres to its right (+x east, +z south: right of (dx, dz) is (-dz, dx)),
    mitred like tools/bake_roads.py offset_line."""
    out = []
    n = len(pts)
    for i in range(n):
        ds = []
        segs = ([(pts[i - 1], pts[i])] if i > 0 else []) + ([(pts[i], pts[i + 1])] if i < n - 1 else [])
        for a, b in segs:
            ln = math.dist(a, b)
            if ln > 1e-6:
                ds.append(((b[0] - a[0]) / ln, (b[1] - a[1]) / ln))
        if not ds:
            out.append(pts[i])
            continue
        r0, r1 = (-ds[0][1], ds[0][0]), (-ds[-1][1], ds[-1][0])
        mx, mz = r0[0] + r1[0], r0[1] + r1[1]
        ln = math.hypot(mx, mz)
        mx, mz = r1 if ln < 1e-6 else (mx / ln, mz / ln)
        sc = 1.0 / max(mx * r1[0] + mz * r1[1], 0.5)
        out.append((pts[i][0] + mx * off * sc, pts[i][1] + mz * off * sc))
    return out


def sample(pts, step):
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.dist(a, b) / step))
        for k in range(n):
            t = (k + 0.5) / n
            yield a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t


class Grid:
    def __init__(self, cell=16.0):
        self.cell, self.g = cell, defaultdict(list)

    def add(self, item, x0, z0, x1, z1):
        c = self.cell
        for i in range(int(math.floor(x0 / c)), int(math.floor(x1 / c)) + 1):
            for j in range(int(math.floor(z0 / c)), int(math.floor(z1 / c)) + 1):
                self.g[(i, j)].append(item)

    def at(self, x, z):
        return self.g.get((int(math.floor(x / self.cell)), int(math.floor(z / self.cell))), [])


class Polys:
    def __init__(self, polys):
        self.p, self.grid, self.box = polys, Grid(), []
        for i, q in enumerate(polys):
            b = (min(a[0] for a in q), min(a[1] for a in q), max(a[0] for a in q), max(a[1] for a in q))
            self.box.append(b)
            self.grid.add(i, *b)

    def hit(self, x, z):
        for i in self.grid.at(x, z):
            b = self.box[i]
            if b[0] <= x <= b[2] and b[1] <= z <= b[3] and pip(x, z, self.p[i]):
                return i
        return -1


class Caps:
    def __init__(self):
        self.grid = Grid()

    def add(self, a, b, half, tag):
        self.grid.add((a, b, half, tag), min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                      max(a[0], b[0]) + half, max(a[1], b[1]) + half)

    def hit(self, x, z, pad=0.0):
        for a, b, half, tag in self.grid.at(x, z):
            if segd(x, z, a, b) <= half + pad:
                return tag
        return None


def visible(r):
    """The road's centreline outside its hidden ranges (as map_builder._visible_runs)."""
    pts, hide = pairs(r["p"]), r.get("hide", [])
    runs, cur, s = [], [], 0.0
    for a, b in zip(pts, pts[1:]):
        ln = math.dist(a, b)
        cuts = sorted({0.0, ln, *[c - s for h in hide for c in h if 0 < c - s < ln]})
        for c0, c1 in zip(cuts, cuts[1:]):
            mid = s + (c0 + c1) / 2
            p0 = (a[0] + (b[0] - a[0]) * c0 / ln, a[1] + (b[1] - a[1]) * c0 / ln) if ln else a
            p1 = (a[0] + (b[0] - a[0]) * c1 / ln, a[1] + (b[1] - a[1]) * c1 / ln) if ln else b
            if any(h0 <= mid <= h1 for h0, h1 in hide):
                if len(cur) >= 2:
                    runs.append(cur)
                cur = []
            else:
                if not cur:
                    cur = [p0]
                cur.append(p1)
        s += ln
    if len(cur) >= 2:
        runs.append(cur)
    return runs


def main():
    folder = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--map=")), os.path.join(ROOT, "game", "map"))
    show = "--list" in sys.argv
    d = json.load(open(os.path.join(folder, "centrum.json"), encoding="utf-8"))
    ground = lambda item: item.get("dk", -1) < 0  # noqa: E731  (at grade; decks are check_roads')

    carr = Polys([pairs(c["p"]) for c in d["carriage"] if ground(c) and c["k"] not in HATCH])
    hatch = Polys([pairs(c["p"]) for c in d["carriage"] if ground(c) and c["k"] in HATCH])
    strips = Caps()
    for r in d["roads"]:
        if not ground(r):
            continue
        for run in visible(r):
            run = offset(run, r.get("c", 0.0))
            for a, b in zip(run, run[1:]):
                strips.add(a, b, r["w"] * 0.5, 1)
    islands = Polys([pairs(a["p"]) for a in d.get("islands", []) if ground(a)])
    med_quads = []
    for m in d.get("medians", []):
        if not ground(m):
            continue
        s4 = m["s"]
        for i in range(0, len(s4) - 7, 4):
            med_quads.append(([(s4[i], s4[i + 1]), (s4[i + 2], s4[i + 3]), (s4[i + 6], s4[i + 7]), (s4[i + 4], s4[i + 5])], m["k"]))
    meds = Polys([q for q, _ in med_quads])
    cycle = Caps()
    for p in d["paths"]:
        if p["k"] == "cycle" and ground(p):
            for a, b in zip(pairs(p["p"]), pairs(p["p"])[1:]):
                cycle.add(a, b, p["w"] * 0.5, 1)
    trams = Caps()
    for t in d["trams"]:
        if ground(t):
            for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                trams.add(a, b, 0.9, 1)

    def asphalt(x, z):
        return (carr.hit(x, z) >= 0 or strips.hit(x, z) is not None) and hatch.hit(x, z) < 0

    def raised(x, z):
        return islands.hit(x, z) >= 0 or meds.hit(x, z) >= 0

    found = defaultdict(list)

    # S1: poles on the asphalt.
    for key, stride in (("lamps", 2), ("signals", 3)):
        v = d.get(key, [])
        for k in range(0, len(v) - stride + 1, stride):
            x, z = v[k], v[k + 1]
            if not raised(x, z) and asphalt(x, z):
                found["S1"].append((x, z, key[:-1]))

    # S2: zebras off the asphalt.
    for p in d["paths"]:
        if p["k"] != "zebra" or not ground(p):
            continue
        bad = [(x, z) for x, z in sample(pairs(p["p"]), 0.25)
               if not (asphalt(x, z) and islands.hit(x, z) < 0) and cycle.hit(x, z) is None]
        if len(bad) >= 3:
            found["S2"].append((bad[0][0], bad[0][1], f"{len(bad) * 0.25:.1f} m"))

    # S3: medians inside a junction. An in-junction piece is a one-way road's segment (up to
    # 40 m) between two vertices where one-way halves of one other street cross it at an angle
    # (a dual carriageway crossing another), up to 30 m; a median cross-section whose middle lies
    # within 8 m beside the piece (between its ends) lies in the junction.
    road_at = defaultdict(list)
    roads = [r for r in d["roads"] if ground(r) and r["k"] not in MINOR]
    for r in roads:
        for j, p in enumerate(pairs(r["p"])):
            road_at[(round(p[0], 2), round(p[1], 2))].append((r, j))

    def unit(a, b):
        ln = math.dist(a, b)
        return None if ln < 1e-6 else ((b[0] - a[0]) / ln, (b[1] - a[1]) / ln)

    def crossing_names(r, j):
        q = pairs(r["p"])
        mine = [u for u in (unit(q[j], q[k]) for k in (j - 1, j + 1) if 0 <= k < len(q)) if u]
        out = set()
        for o, k in road_at[(round(q[j][0], 2), round(q[j][1], 2))]:
            if o is r or not o["oneway"] or not o["name"] or o["name"] == r["name"]:
                continue
            qo = pairs(o["p"])
            for u in (unit(qo[k], qo[m]) for m in (k - 1, k + 1) if 0 <= m < len(qo)):
                if u and all(abs(u[0] * v[0] + u[1] * v[1]) < 0.87 for v in mine):
                    out.add(o["name"])
        return out

    pieces = Caps()
    for r in roads:
        if not r["oneway"]:
            continue
        q = pairs(r["p"])
        for j in range(len(q) - 1):
            if math.dist(q[j], q[j + 1]) <= 30.0 and crossing_names(r, j) & crossing_names(r, j + 1):
                pieces.add(q[j], q[j + 1], 8.0, 1)
    for q, kind in med_quads:
        mx, mz = sum(a[0] for a in q) / 4, sum(a[1] for a in q) / 4
        for a, b, half, _ in pieces.grid.at(mx, mz):
            dx, dz = b[0] - a[0], b[1] - a[1]
            u = ((mx - a[0]) * dx + (mz - a[1]) * dz) / (dx * dx + dz * dz)
            if 0.0 < u < 1.0 and segd(mx, mz, a, b) <= half:
                found["S3"].append((mx, mz, kind))
                break

    # S4: grass medians on tram tracks.
    for q, kind in med_quads:
        if kind != "grass":
            continue
        for f in (0.2, 0.5, 0.8):
            x = q[0][0] + (q[1][0] - q[0][0]) * f
            z = q[0][1] + (q[1][1] - q[0][1]) * f
            if trams.hit(x, z) is not None:
                found["S4"].append((x, z, "grass"))
                break

    rules = ("S1", "S2", "S3", "S4")
    for r in rules:
        if show:
            for x, z, what in found[r]:
                print(f"{r} --at={x:.0f},{z:.0f} {what}")
    print("check_streets counts: " + ", ".join(f"{r} {len(found[r])}" for r in rules))
    # S3 is reported, not failed: a real median nose at a junction's edge (Świętokrzyska by
    # Emilii Plater and Mariańska) looks the same to it; the junction boxes themselves are
    # bake_roads._junction_boxes' (3 on today's map, judged in the shots).
    bad = [r for r in rules if found[r] and r != "S3"]
    if bad:
        print("check_streets: FAIL " + ", ".join(f"{r} {len(found[r])}" for r in bad) + " (--list prints them)")
        return 1
    print("check_streets: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
