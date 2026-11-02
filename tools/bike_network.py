#!/usr/bin/env python3
"""Warsaw's on-street cycle network from OpenStreetMap's tags: contraflow, sharrows and bus lanes
open to bikes.

    python3 -I tools/bike_network.py --osm data/work/demo/osm_demo.json [game/map/centrum.json] [--dry]

Idea #9 (F, 2026-11-02; docs/design/city-life-satire.md). tools/compare_cycleways.py measured
the map against OpenStreetMap (2026-11-02): the separate cycle paths and the crossings were all
drawn, the painted lanes 85 %, but the network's biggest part in the centre was invisible: 33 km of
one-way streets that bikes may ride both ways (`oneway:bicycle=no`, `cycleway*=opposite*`), which
Warsaw marks with a white bike and arrow facing the riders at each end, plus bus lanes open to
bikes (`share_busway`) and sharrows (`shared_lane`). This adds, on the baked map:

- `symbols` of kind `bike` marked `"on": "contra"` near the contraflow side's kerb (the car's left),
  facing against the one-way, CONTRA_IN metres into each street and every CONTRA_EVERY on long ones;
- `bike` symbols `"on": "busway"` in the bus lane (BUS_IN from the right kerb) every BUS_EVERY,
  and `"on": "sharrow"` in the lane's middle every SHARROW_EVERY, facing the traffic;

The painted lanes (`cycleway[:side]=lane`) are bake_roads.py's: measured from the kerb they are
all drawn where the road is wide enough (compare_cycleways.py measures from the centreline).

Every piece needs the drawn road under it: the map's road of the same name nearest the point
(its width `w` and side offset `c`), the point on its asphalt, not within KEEP_CLEAR of a zebra or
cycle crossing, and not inside another street's carriageway (a junction). A second run first
removes what an earlier run added, so it is idempotent. Without --osm (the cloud has no download)
it changes nothing. bake_osm.py calls `apply(out, els)` after bike_marks. Standard library only.
Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

CONTRA_IN = 7.0
CONTRA_EVERY = 90.0
CONTRA_INSET = 0.95
BUS_IN = 1.6
BUS_EVERY = 70.0
SHARROW_EVERY = 45.0
NEAR = 4.0
KEEP_CLEAR = 3.0
MATCH = 6.0
CELL = 32.0
OFF_ROAD = ("footway", "path", "cycleway", "pedestrian", "steps", "service", "track")
MINE = {"contra", "busway", "sharrow"}


def _seg_proj(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ll = dx * dx + dz * dz
    t = 0.0 if ll < 1e-9 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / ll))
    q = (a[0] + t * dx, a[1] + t * dz)
    return math.hypot(p[0] - q[0], p[1] - q[1]), q


def _unit(a, b):
    d = math.dist(a, b)
    return None if d < 1e-6 else ((b[0] - a[0]) / d, (b[1] - a[1]) / d)


def _pts(q):
    return [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]


class _Grid:
    def __init__(self):
        self.cells = {}

    def add(self, pts, payload, pad):
        for a, b in zip(pts, pts[1:]):
            for i in range(int(math.floor((min(a[0], b[0]) - pad) / CELL)), int(math.floor((max(a[0], b[0]) + pad) / CELL)) + 1):
                for j in range(int(math.floor((min(a[1], b[1]) - pad) / CELL)), int(math.floor((max(a[1], b[1]) + pad) / CELL)) + 1):
                    self.cells.setdefault((i, j), []).append((a, b, payload))

    def near(self, p):
        return self.cells.get((int(math.floor(p[0] / CELL)), int(math.floor(p[1] / CELL))), [])


def _oneway(t):
    ow = t.get("oneway", "")
    if ow in ("yes", "true", "1"):
        return 1
    if ow in ("-1", "reverse"):
        return -1
    if ow != "no" and t.get("junction") in ("roundabout", "circular"):
        return 1
    return 0


def _vals(t):
    return {k: t.get(k, "") for k in ("cycleway", "cycleway:both", "cycleway:left", "cycleway:right")}


class _Map:
    """The baked map's roads, crossings and cycle pieces, for lookups by point."""

    def __init__(self, data):
        self.roads = _Grid()
        for r in data.get("roads", []):
            if r.get("k") in ("service", "track") or r.get("dk", -1) not in (-1, None):
                continue
            pts = _pts(r["p"])
            self.roads.add(pts, r, float(r["w"]) + MATCH)
        self.clear = _Grid()
        for p in data.get("paths", []):
            if p["k"] in ("zebra", "cyclecross"):
                self.clear.add(_pts(p["p"]), None, KEEP_CLEAR)
        self.cycle = _Grid()
        for p in data.get("paths", []):
            if p["k"] in ("cycle", "cyclecross"):
                self.cycle.add(_pts(p["p"]), None, NEAR)
        for m in data.get("markings", []):
            if m["k"] in ("cycle", "cyclefill"):
                self.cycle.add(_pts(m["p"]), None, NEAR)

    def frame(self, p, name, d):
        """The drawn road of this name at p: (centre point, right unit vector of d, half width,
        the road) with the right vector turned to the OSM way's direction d; None if no match."""
        best = None
        for a, b, r in self.roads.near(p):
            if name and r.get("name", "") != name:
                continue
            dist, q = _seg_proj(p, a, b)
            if dist < MATCH and (best is None or dist < best[0]):
                best = (dist, q, a, b, r)
        if best is None:
            return None
        _, q, a, b, r = best
        dr = _unit(a, b)
        if dr is None:
            return None
        right_r = (-dr[1], dr[0])
        c = float(r.get("c", 0.0))
        centre = (q[0] + right_r[0] * c, q[1] + right_r[1] * c)
        sign = 1.0 if dr[0] * d[0] + dr[1] * d[1] >= 0 else -1.0
        return centre, (right_r[0] * sign, right_r[1] * sign), float(r["w"]) * 0.5, r

    def ok(self, p, road):
        """On this road's asphalt, clear of crossings and of other streets' carriageways."""
        for a, b, _ in self.clear.near(p):
            if _seg_proj(p, a, b)[0] < KEEP_CLEAR:
                return False
        on = False
        for a, b, r in self.roads.near(p):
            dist = _seg_proj(p, a, b)[0]
            half = float(r["w"]) * 0.5 + abs(float(r.get("c", 0.0)))
            if r is road or (road.get("name") and r.get("name") == road.get("name")):
                on = on or dist < half
            elif dist < float(r["w"]) * 0.5 - 0.3 and r.get("k") not in ("service", "living_street"):
                return False
        return on

    def drawn(self, p):
        return any(_seg_proj(p, a, b)[0] < NEAR for a, b, _ in self.cycle.near(p))


def _walk(pts):
    cum = [0.0]
    for a, b in zip(pts, pts[1:]):
        cum.append(cum[-1] + math.dist(a, b))
    return cum


def _at(pts, cum, s):
    for i in range(len(pts) - 1):
        if cum[i + 1] >= s or i == len(pts) - 2:
            d = _unit(pts[i], pts[i + 1])
            if d is None:
                return None
            t = max(0.0, min(cum[i + 1] - cum[i], s - cum[i]))
            return (pts[i][0] + d[0] * t, pts[i][1] + d[1] * t), d
    return None


def apply(data, els=None):
    """Adds the on-street network from the OSM elements; returns a one-line summary."""
    syms = data.setdefault("symbols", [])
    marks = data.setdefault("markings", [])
    if els is None:
        return "no OpenStreetMap export given: unchanged"
    syms[:] = [m for m in syms if m.get("on") not in MINE]
    marks[:] = [m for m in marks if m.get("on") not in MINE]
    mp = _Map(data)
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    import bake_osm
    x0, z0, x1, z1 = data["bounds"]
    outside = data.get("outside", [])

    def inside(p):
        return x0 <= p[0] <= x1 and z0 <= p[1] <= z1 and not any(o[0] <= p[0] <= o[2] and o[1] <= p[1] <= o[3] for o in outside)

    count = {"contra": 0, "busway": 0, "sharrow": 0}
    taken = _Grid()

    def sym(kind, p, d):
        if not inside(p) or any(math.dist(p, a) < 6.0 for a, _, _ in taken.near(p)):
            return False
        syms.append({"k": "bike", "x": round(p[0], 2), "z": round(p[1], 2), "d": [round(d[0], 3), round(d[1], 3)], "on": kind})
        taken.add([p, p], None, 0.0)
        count[kind] += 1
        return True

    def place(pts, cum, s, name, side, inset, facing, kind):
        """A bike `inset` m in from the kerb on `side` (+1 right, -1 left of the way, 0 the
        middle), facing along the way (+1) or against it (-1)."""
        hit = _at(pts, cum, s)
        if hit is None:
            return False
        p, d = hit
        fr = mp.frame(p, name, d)
        if fr is None:
            return False
        centre, right, half, road = fr
        off = 0.0 if side == 0 else side * (half - inset)
        if side != 0 and half - inset < 0.8:
            return False
        q = (centre[0] + right[0] * off, centre[1] + right[1] * off)
        if not mp.ok(q, road):
            return False
        return sym(kind, q, (d[0] * facing, d[1] * facing))

    for e in els:
        if e["type"] != "way":
            continue
        t = e.get("tags", {})
        hw = t.get("highway", "")
        if not hw or hw in OFF_ROAD or t.get("tunnel") not in (None, "no"):
            continue
        if t.get("bridge") not in (None, "no") or t.get("layer", "0") not in ("0", ""):
            continue
        pts = [bake_osm.project(*nodes[n]) for n in e.get("nodes", []) if n in nodes]
        if len(pts) < 2:
            continue
        cum = _walk(pts)
        length = cum[-1]
        if length < 8.0:
            continue
        name = t.get("name", "")
        ow = _oneway(t)
        v = _vals(t)
        allv = set(v.values())
        # Contraflow: the riders against the one-way keep to their right, the car's left.
        if ow != 0 and (t.get("oneway:bicycle") == "no" or any(x.startswith("opposite") for x in allv)) and "lane" not in allv:
            side = -ow
            stops = [min(CONTRA_IN, length * 0.5), max(length - CONTRA_IN, length * 0.5)]
            n = int(length // CONTRA_EVERY)
            stops += [length * (k + 1) / (n + 1) for k in range(n)]
            for s in stops:
                place(pts, cum, s, name, side, CONTRA_INSET, -ow, "contra")
        # Bus lanes open to bikes.
        for key, side in (("cycleway:right", 1), ("cycleway:left", -1), ("cycleway:both", 0), ("cycleway", 0)):
            if v[key] != "share_busway":
                continue
            sides = [side] if side else ([1] if ow >= 0 else [-1]) + ([-1] if ow == 0 else [])
            for sd in sides:
                s = 20.0
                while s < length - 8.0:
                    facing = 1 if sd > 0 else -1
                    place(pts, cum, s, name, sd, BUS_IN, facing, "busway")
                    s += BUS_EVERY
        # Sharrows in the middle of the lane.
        if "shared_lane" in allv:
            sides = [0] if ow != 0 else [1, -1]
            for sd in sides:
                s = 10.0
                while s < length - 6.0:
                    hit = _at(pts, cum, s)
                    if hit:
                        fr = mp.frame(hit[0], name, hit[1])
                        if fr:
                            inset = fr[2] * 0.5 if sd else 0.0
                            place(pts, cum, s, name, sd, inset, (ow or 1) if sd == 0 else sd, "sharrow")
                    s += SHARROW_EVERY
    return f"{count['contra']} contraflow bikes, {count['busway']} in bus lanes, {count['sharrow']} sharrows"


def main(argv):
    osm = None
    rest = []
    for a in argv:
        if a.startswith("--osm="):
            osm = a.split("=", 1)[1]
        elif not a.startswith("--"):
            rest.append(a)
    if "--osm" in argv:
        i = argv.index("--osm")
        osm = argv[i + 1]
        rest = [a for a in rest if a != osm]
    path = rest[0] if rest else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    els = json.load(open(osm, encoding="utf-8"))["elements"] if osm else None
    print("bike_network: " + apply(data, els))
    if "--dry" in argv or els is None:
        return 0
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"), ensure_ascii=False)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
