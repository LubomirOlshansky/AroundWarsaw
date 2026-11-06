"""road_design.py: build an area's roads from a design spec, from zero, instead of repairing OSM ribbons.

A street is one reference line (its `axis`, corners filleted with arcs) with a cross-section that
changes along it (`sections`); a junction is a shape of its own, made from its arms' kerbs and
corner arcs (kerb returns). The generator is the only writer of the area it designs: the old road
layers there (ribbons, carriage areas, kerbs, islands, medians, lines, arrows, zebras) are removed
and the new ones written in the same layers, so the renderer and both city paths are unchanged.
Research and the model: docs/design/road-design-system.md. Workflow: the `road-design` skill.

Usage:
  python3 -I tools/road_design.py AREA                 apply docs/roads/AREA.json to game/map/centrum.json
  python3 -I tools/road_design.py AREA --check         build it and run the checks; writes nothing
  python3 -I tools/road_design.py AREA --from BASE.json --out OUT.json   apply to BASE, write OUT
  python3 -I tools/road_design.py AREA --needs OSM.json                  the OSM evidence per street
  python3 -I tools/road_design.py --check-all          check every applied area (verify step `design`)

The map remembers what was applied (`road_design`: {area: version}); applying twice is refused
(take the map from before, e.g. `git show origin/main:game/map/centrum.json > base.json`, and use
--from). bake_osm.py runs `apply_all(out)` after road_smooth, so a re-bake keeps every area.

Spec (docs/roads/AREA.json), map metres, +x east, +z south; offsets are to the right of the axis
(the right as seen on the map from above when facing along it), negative to the left:
  {"area": "palace", "version": 1,
   "streets": [{"id": "marsz", "name": "Marszałkowska", "k": "secondary",
                "axis": [[x, z], ...], "fillet": 40,
                "sections": [{"s": 0, "taper": 25,
                              "cw": [{"l": -16.4, "r": -3.6, "lanes": [{"d": -1, "t": "T"}, {"d": -1, "k": "bus"}]},
                                     {"l": 3.6, "r": 16.4, "lanes": [...]}],
                              "med": ["tram"]}, ...],
                "crossings": [{"s": 120, "w": 4.0, "bs": 116, "bw": 2.2}],
                "openings": [{"s": 150, "side": 1, "w": 8, "r": 5}],
                "gaps": [{"s0": 140, "s1": 160}],
                "start": "j1", "end": "cut"}],
   "junctions": [{"id": "j1", "r": 9, "arms": {"marsz": {"x": 3.5}, ...}}]}
  lanes: d +1 along the axis, -1 against; k lane (default), bus, bike; t turn arrows (L T R LT TR U);
  w width (else an equal share of what is left). med: tram, grass, island (one per gap between
  carriageways; "none" for a painted gap). crossings: mid-block zebras (bs: a cycle crossing beside
  it). openings: a side road or driveway leaving one side (kerb break, two kerb returns). gaps: the
  median broken where a side street or U-turn crosses (paved; the lanes' paint runs on).
"""
import json
import math
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MAP = os.path.join(ROOT, "game", "map", "centrum.json")
SPECS = os.path.join(ROOT, "docs", "roads")

STEP = 1.0            # m between the axis' samples
TAPER = 25.0          # m: a kerb that moves between two sections does so over this (smoothstep)
CROSS_W = 4.0         # m: a zebra's width (P-10, 4 m in the centre)
CROSS_GAP = 1.0       # m between a crossing's near edge and the junction mouth
STOP_GAP = 1.2        # m between the stop line and the crossing (P-12)
SOLID = 20.0          # m of solid lane line before a stop line (P-2)
ARROWS = (6.0, 30.0)  # m before the stop line where the turn arrows go
BUS_EVERY = 60.0      # m between BUS words in a bus lane
BIKE_EVERY = 40.0     # m between bike symbols in a cycle lane
KERB_RETURN = 9.0     # m: default corner radius
FOOT_PAD = 2.5        # m round the designed asphalt where the old road layers are removed
MIN_MOUTH = 1.0       # m: an arm's carriageway starts at least this far from the corners' tangents
NOSE = 1.2            # m: a median's rounded end stops this far behind a crossing
HATCH = 3.0           # m between a painted gap's bars
CHUNK = 8.0           # m: carriageway polygons in pieces this long (they drape on the terrain)


# --- small geometry -------------------------------------------------------------------------

def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, k):
    return (a[0] * k, a[1] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def norm(a):
    n = math.hypot(a[0], a[1])
    return (a[0] / n, a[1] / n) if n > 1e-9 else (0.0, 0.0)


def right_of(d):
    """The right-hand normal (the map's right, x east and z south, seen from above)."""
    return (-d[1], d[0])


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def smoothstep(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def flat(pts, nd=2):
    out = []
    for p in pts:
        out += [round(p[0], nd), round(p[1], nd)]
    return out


def pts_of(f):
    return [(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]


def plen(pts):
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def ring_area(p):
    return 0.5 * sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))


def inside(x, z, poly):
    hit = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi:
            hit = not hit
        j = i
    return hit


def seg_hit(a, b, c, d):
    """Where segments ab and cd cross (t along ab), or None."""
    r = sub(b, a)
    s = sub(d, c)
    den = cross(r, s)
    if abs(den) < 1e-12:
        return None
    t = cross(sub(c, a), s) / den
    u = cross(sub(c, a), r) / den
    if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
        return t
    return None


def line_hit(p, d, q, e):
    """Where the lines p + u d and q + v e meet: (u, v), or None if parallel."""
    den = cross(d, e)
    if abs(den) < 1e-9:
        return None
    w = sub(q, p)
    return cross(w, e) / den, cross(w, d) / den


def fillet(pts, radius):
    """The polyline with each corner replaced by a circular arc (radius capped by the legs)."""
    if len(pts) < 3 or radius <= 0:
        return list(pts)
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[i], pts[i + 1]
        d1 = norm(sub(a, b))
        d2 = norm(sub(c, b))
        turn = math.acos(max(-1.0, min(1.0, dot(d1, d2))))   # the angle at the corner
        if turn > math.radians(178):
            out.append(b)
            continue
        half = turn / 2.0
        r = radius
        t = r / math.tan(half)
        cap = 0.45 * min(math.dist(a, b), math.dist(b, c))
        if t > cap:
            t = cap
            r = t * math.tan(half)
        p1 = add(b, mul(d1, t))
        p2 = add(b, mul(d2, t))
        centre = add(b, mul(norm(add(d1, d2)), r / math.sin(half)))
        a1 = math.atan2(p1[1] - centre[1], p1[0] - centre[0])
        a2 = math.atan2(p2[1] - centre[1], p2[0] - centre[0])
        sweep = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
        n = max(2, int(abs(sweep) * r / 1.5))
        for k in range(n + 1):
            ang = a1 + sweep * k / n
            out.append((centre[0] + r * math.cos(ang), centre[1] + r * math.sin(ang)))
    out.append(pts[-1])
    return out


def resample(pts, step):
    out = [pts[0]]
    carry = 0.0
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = math.dist(a, b)
        t = step - carry
        while t <= L:
            out.append(lerp(a, b, t / L))
            t += step
        carry = L - (t - step)
    if math.dist(out[-1], pts[-1]) > step * 0.3:
        out.append(pts[-1])
    else:
        out[-1] = pts[-1]
    return out


def arc(centre, r, a1, a2, step=1.0):
    sweep = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
    n = max(2, int(abs(sweep) * r / step))
    return [(centre[0] + r * math.cos(a1 + sweep * k / n), centre[1] + r * math.sin(a1 + sweep * k / n))
            for k in range(n + 1)]


# --- a street ---------------------------------------------------------------------------------

class Street:
    """One street: a filleted, resampled axis and its cross-section as functions of s."""

    def __init__(self, spec):
        self.spec = spec
        self.id = spec["id"]
        self.k = spec.get("k", "secondary")
        axis = [tuple(p) for p in spec["axis"]]
        self.pts = resample(fillet(axis, spec.get("fillet", 40.0)), STEP)
        self.cum = [0.0]
        for i in range(1, len(self.pts)):
            self.cum.append(self.cum[-1] + math.dist(self.pts[i - 1], self.pts[i]))
        self.L = self.cum[-1]
        self.tan = []
        for i in range(len(self.pts)):
            a = self.pts[max(0, i - 1)]
            b = self.pts[min(len(self.pts) - 1, i + 1)]
            self.tan.append(norm(sub(b, a)))
        self.sections = sorted(spec["sections"], key=lambda s: s["s"])
        n = len(self.sections[0]["cw"])
        for sec in self.sections:
            if len(sec["cw"]) != n:
                raise SystemExit("road_design: %s: every section needs %d carriageways" % (self.id, n))
        self.ncw = n
        self.meds = self.sections[0].get("med", ["none"] * (n - 1))
        self.s0 = 0.0          # the mouths (set by the junctions)
        self.s1 = self.L

    def at(self, s):
        """(point, tangent) on the axis s metres along."""
        s = min(max(s, 0.0), self.L)
        i = min(int(s / STEP), len(self.pts) - 2)
        while i > 0 and self.cum[i] > s:
            i -= 1
        while i < len(self.pts) - 2 and self.cum[i + 1] < s:
            i += 1
        seg = self.cum[i + 1] - self.cum[i]
        t = (s - self.cum[i]) / seg if seg > 0 else 0.0
        p = lerp(self.pts[i], self.pts[i + 1], t)
        d = norm(lerp(self.tan[i], self.tan[i + 1], t))
        if s <= 0.0:
            # the axis carries on straight past its ends (for the corner fits)
            pass
        return p, d

    def ext(self, s):
        """(point, tangent) also beyond the ends, straight on."""
        if s < 0.0:
            p, d = self.at(0.0)
            return add(p, mul(d, s)), d
        if s > self.L:
            p, d = self.at(self.L)
            return add(p, mul(d, s - self.L)), d
        return self.at(s)

    def section_at(self, s):
        """(previous section, this section, blend 0..1) for the kerbs' smooth taper."""
        cur = self.sections[0]
        prev = cur
        for sec in self.sections:
            if sec["s"] <= s + 1e-6:
                prev, cur = cur, sec
        # blend: the change between prev and cur ramps over [cur.s - taper, cur.s]
        idx = self.sections.index(cur)
        nxt = self.sections[idx + 1] if idx + 1 < len(self.sections) else None
        if nxt is not None:
            taper = nxt.get("taper", TAPER)
            if s > nxt["s"] - taper:
                return cur, nxt, smoothstep((s - (nxt["s"] - taper)) / taper)
        return cur, cur, 1.0

    def edges(self, s):
        """[(l, r)] of every carriageway at s, tapered."""
        a, b, t = self.section_at(s)
        out = []
        for i in range(self.ncw):
            ca, cb = a["cw"][i], b["cw"][i]
            out.append((ca["l"] + (cb["l"] - ca["l"]) * t, ca["r"] + (cb["r"] - ca["r"]) * t))
        return out

    def bounds(self, sec, s):
        """Each carriageway's lanes and lane boundaries for section `sec` at s: [(lanes, [x0..xn])].
        The widths come from the section's own kerbs (its nominal l and r); where the kerbs are
        tapering at s, only the outer lanes take up the change, so the lane lines stay put."""
        out = []
        for i, (l, r) in enumerate(self.edges(s)):
            cw = sec["cw"][i]
            L, R = float(cw["l"]), float(cw["r"])
            lanes = cw["lanes"]
            fixed = sum(float(x.get("w", 0.0)) for x in lanes)
            free = [x for x in lanes if "w" not in x]
            share = (R - L - fixed) / len(free) if free else 0.0
            k = (R - L) / fixed if (not free and fixed > 0) else 1.0
            xs = [L]
            for x in lanes:
                xs.append(xs[-1] + (float(x["w"]) * k if "w" in x else share))
            xs[0], xs[-1] = l, r
            out.append((lanes, xs))
        return out

    def lanes(self, s):
        """The lanes of each carriageway at s: [(lane spec, left offset, right offset)] per carriageway.
        The paint follows the section that holds s (lanes change by paint, at the section's start).
        Over the taper before the next section, every lane line that carries on into it (one within
        2 m of a line there) slides across to meet it, so no line jogs at the section change."""
        idx = 0
        for k, x in enumerate(self.sections):
            if x["s"] <= s + 1e-6:
                idx = k
        sec = self.sections[idx]
        rows = self.bounds(sec, s)
        nxt = self.sections[idx + 1] if idx + 1 < len(self.sections) else None
        if nxt is not None:
            taper = float(nxt.get("taper", TAPER))
            if s > nxt["s"] - taper:
                t = smoothstep((s - (nxt["s"] - taper)) / taper)
                ahead = self.bounds(nxt, nxt["s"])
                here = self.bounds(nxt, s)
                for i, (lanes, xs) in enumerate(rows):
                    at_end = self.bounds(sec, nxt["s"])[i][1]
                    target = ahead[i][1][1:-1]
                    used = set()
                    for b in range(1, len(xs) - 1):
                        best = None
                        for c, y in enumerate(target):
                            if c in used:
                                continue
                            dd = abs(y - at_end[b])
                            if dd <= 2.0 and (best is None or dd < best[0]):
                                best = (dd, c)
                        if best is not None:
                            used.add(best[1])
                            goal = here[i][1][best[1] + 1]
                            xs[b] = xs[b] + (goal - xs[b]) * t
        out = []
        for lanes, xs in rows:
            out.append([(x, xs[n], xs[n + 1]) for n, x in enumerate(lanes)])
        return out

    def point(self, s, off):
        p, d = self.ext(s)
        return add(p, mul(right_of(d), off))

    def line(self, s0, s1, off_fn, step=STEP):
        """A polyline from s0 to s1 at the offset off_fn(s)."""
        if s1 < s0:
            return list(reversed(self.line(s1, s0, off_fn, step)))
        n = max(1, int(math.ceil((s1 - s0) / step)))
        return [self.point(s0 + (s1 - s0) * k / n, off_fn(s0 + (s1 - s0) * k / n)) for k in range(n + 1)]

    def outer(self, s, side):
        """The outer kerb's offset at s: side -1 the leftmost, +1 the rightmost."""
        e = self.edges(s)
        return e[0][0] if side < 0 else e[-1][1]


# --- the design -------------------------------------------------------------------------------

class Design:
    def __init__(self, spec, roads=None):
        self.spec = spec
        self.roads = roads      # the map's road ribbons: side roads found on them get openings
        self.area = spec["area"]
        self.streets = {s["id"]: Street(s) for s in spec["streets"]}
        self.out = {k: [] for k in ("carriage", "kerbs", "islands", "medians", "markings", "symbols",
                                    "zebras", "cyclecross", "tram_xings")}
        self.footprint = []     # polygons of designed asphalt and medians
        self.mouths = []        # side-road mouths: old kerbs and lines go, the side road stays
        self.crossings = {}     # street id -> [(s0, s1)] where kerbs and lines break
        self.stops = {}         # street id -> [(s of the stop line, direction of the lanes it stops)]
        self.notes = []

    # junctions -----------------------------------------------------------------------------

    def arms(self, j):
        """The arms of a junction: (street, end, s at the end, direction leaving the junction)."""
        out = []
        for sid in j["arms"]:
            st = self.streets[sid]
            if st.spec.get("start") == j["id"]:
                p, d = st.at(0.0)
                out.append({"st": st, "end": 0, "p": p, "dir": d, "cfg": j["arms"][sid]})
            if st.spec.get("end") == j["id"]:
                p, d = st.at(st.L)
                out.append({"st": st, "end": 1, "p": p, "dir": mul(d, -1.0), "cfg": j["arms"][sid]})
        for a in out:
            a["ang"] = math.atan2(a["dir"][1], a["dir"][0])
        out.sort(key=lambda a: a["ang"])
        return out

    @staticmethod
    def arm_s(a, dist):
        """The street's s that lies `dist` metres out from the junction along the arm."""
        return dist if a["end"] == 0 else a["st"].L - dist

    @staticmethod
    def arm_kerb(a, side, dist):
        """A point of the arm's outer kerb `dist` out: side +1 the kerb towards the next arm
        (counter-clockwise in atan2 terms, the arm direction turned +90 degrees), -1 the other."""
        st = a["st"]
        s = Design.arm_s(a, dist)
        street_side = side if a["end"] == 0 else -side
        return st.point(s, st.outer(min(max(s, 0.0), st.L), street_side))

    def build_junction(self, j):
        arms = self.arms(j)
        R = float(j.get("r", KERB_RETURN))
        n = len(arms)
        corners = []
        for i in range(n):
            a, b = arms[i], arms[(i + 1) % n]
            gap = (b["ang"] - a["ang"]) % (2 * math.pi) if n > 1 else 2 * math.pi
            r = float(j.get("radii", {}).get("%s/%s" % (a["st"].id, b["st"].id), R))
            pa = self.arm_kerb(a, +1, 0.0)
            pb = self.arm_kerb(b, -1, 0.0)
            if gap >= math.radians(170):
                # nearly straight on (or the outside of a bend): the kerb runs straight across
                corners.append({"a": a, "b": b, "ta": 0.0, "tb": 0.0, "arc": []})
                continue
            hit = line_hit(pa, a["dir"], pb, b["dir"])
            if hit is None:
                corners.append({"a": a, "b": b, "ta": 0.0, "tb": 0.0, "arc": []})
                continue
            corner = add(pa, mul(a["dir"], hit[0]))
            phi = gap
            t = r / math.tan(phi / 2.0)
            ta = hit[0] + t       # distance out along a's kerb (from the arm's end point)
            tb = hit[1] + t
            p1 = add(corner, mul(a["dir"], t))
            p2 = add(corner, mul(b["dir"], t))
            centre = add(corner, mul(norm(add(a["dir"], b["dir"])), r / math.sin(phi / 2.0)))
            a1 = math.atan2(p1[1] - centre[1], p1[0] - centre[0])
            a2 = math.atan2(p2[1] - centre[1], p2[0] - centre[0])
            corners.append({"a": a, "b": b, "ta": ta, "tb": tb, "arc": arc(centre, r, a1, a2)})
        # each arm's mouth: past both of its corners' tangents
        for i, a in enumerate(arms):
            right = corners[i]["ta"]                  # this arm is corner i's `a`
            left = corners[(i - 1) % n]["tb"]         # and corner i-1's `b`
            a["mouth"] = max(right, left, 0.0) + MIN_MOUTH
            a["mouth"] = max(a["mouth"], float(a["cfg"].get("mouth", 0.0)))
            cfg = a["cfg"]
            spans = []          # (near, far) metres out: the zebra and the cycle crossing
            a["zebra"] = None
            a["cycle"] = None
            if cfg.get("cross", True):
                w = float(cfg.get("w", CROSS_W))
                x = float(cfg.get("x", a["mouth"] + CROSS_GAP + w / 2.0))
                a["zebra"] = (x, w)
                spans.append((x - w / 2.0, x + w / 2.0))
                if "bx" in cfg:
                    bw = float(cfg.get("bw", 2.2))
                    a["cycle"] = (float(cfg["bx"]), bw)
                    spans.append((float(cfg["bx"]) - bw / 2.0, float(cfg["bx"]) + bw / 2.0))
            a["near"] = min([sp[0] for sp in spans] + [a["mouth"]]) if spans else a["mouth"]
            a["near"] = max(a["near"], a["mouth"]) if not spans else min(sp[0] for sp in spans)
            a["throat"] = max([sp[1] for sp in spans] + [a["mouth"]])
            st = a["st"]
            if a["end"] == 0:
                st.s0 = a["mouth"]
                st.t0 = a["throat"]
            else:
                st.s1 = st.L - a["mouth"]
                st.t1 = st.L - a["throat"]
        # the junction's asphalt: round the arms' mouths and the corner arcs
        ring = []
        for i, a in enumerate(arms):
            ring.append(self.arm_kerb(a, -1, a["mouth"]))
            ring.append(self.arm_kerb(a, +1, a["mouth"]))
            c = corners[i]
            ring += [self.arm_kerb(a, +1, d) for d in self._down(a["mouth"], c["ta"])]
            ring += c["arc"]
            ring += [self.arm_kerb(c["b"], -1, d) for d in self._up(c["tb"], c["b"]["mouth"])]
        ring = dedupe(ring)
        self.out["carriage"].append({"k": j.get("k", "secondary"), "p": flat(ring)})
        self.footprint.append(ring)
        # corner kerbs: from one arm's nearest crossing round the arc into the next arm's
        for i, c in enumerate(corners):
            a, b = c["a"], c["b"]
            run = [self.arm_kerb(a, +1, d) for d in self._down(a["throat"], c["ta"])]
            run += c["arc"]
            run += [self.arm_kerb(b, -1, d) for d in self._up(c["tb"], b["throat"])]
            run = dedupe(run)
            if len(run) >= 2:
                # the pavement on the line's right: run from b's kerb round the arc to a's
                self.out["kerbs"].append({"p": flat(list(reversed(run)))})
        for a in arms:
            self.arm_details(j, a)
        return arms

    @staticmethod
    def _down(d0, d1, step=1.0):
        if d0 <= d1:
            return []
        n = max(1, int(math.ceil((d0 - d1) / step)))
        return [d0 - (d0 - d1) * k / n for k in range(n + 1)]

    @staticmethod
    def _up(d0, d1, step=1.0):
        if d1 <= d0:
            return []
        n = max(1, int(math.ceil((d1 - d0) / step)))
        return [d0 + (d1 - d0) * k / n for k in range(n + 1)]

    def arm_details(self, j, a):
        """The throat (full-width asphalt from the mouth to past the crossings), the crossings,
        the stop line of the lanes coming in."""
        st = a["st"]
        sm = self.arm_s(a, a["mouth"])
        sth = self.arm_s(a, a["throat"])
        lo, hi = min(sm, sth), max(sm, sth)
        if hi - lo > 0.05:
            ring = st.line(lo, hi, lambda s: st.outer(s, -1)) + st.line(hi, lo, lambda s: st.outer(s, +1))
            self.out["carriage"].append({"k": st.k, "p": flat(ring)})
            self.footprint.append(ring)
        if a["zebra"]:
            x, w = a["zebra"]
            self.zebra(st, self.arm_s(a, x), w)
        if a["cycle"]:
            x, w = a["cycle"]
            self.cycle_crossing(st, self.arm_s(a, x), w)
        if a["zebra"] or a["cycle"]:
            # the lanes heading into the junction stop STOP_GAP behind the farthest crossing
            d_in = -1 if a["end"] == 0 else 1
            s_stop = self.arm_s(a, a["throat"] + STOP_GAP)
            self.stops.setdefault(st.id, []).append((s_stop, d_in))
            for row in st.lanes(s_stop):
                run = [x for x in row if int(x[0].get("d", 1)) == d_in and x[0].get("k", "lane") in ("lane", "bus")]
                if run:
                    l = min(x[1] for x in run)
                    r = max(x[2] for x in run)
                    self.out["markings"].append({"k": "stop", "p": flat([st.point(s_stop, l + 0.15), st.point(s_stop, r - 0.15)])})

    def zebra(self, st, s, w):
        """A zebra (P-10) across every carriageway at s, w wide; over a tram bed a pale walkway."""
        self.crossings.setdefault(st.id, []).append((s - w / 2.0, s + w / 2.0))
        edges = st.edges(s)
        for (l, r) in edges:
            self.out["zebras"].append({"p": flat([st.point(s, l + 0.3), st.point(s, r - 0.3)]), "w": w})
        for i in range(len(edges) - 1):
            if st.meds[i] == "tram":
                self.out["tram_xings"].append({"k": "walk", "w": w, "p": flat([st.point(s, edges[i][1]), st.point(s, edges[i + 1][0])])})

    def cycle_crossing(self, st, s, w):
        """A cycle crossing (P-11) across the whole street at s."""
        self.crossings.setdefault(st.id, []).append((s - w / 2.0, s + w / 2.0))
        edges = st.edges(s)
        self.out["cyclecross"].append({"p": flat([st.point(s, edges[0][0]), st.point(s, edges[-1][1])])})

    # streets -------------------------------------------------------------------------------

    def build_street(self, st):
        for sx in st.spec.get("crossings", []):
            self.zebra(st, sx["s"], float(sx.get("w", CROSS_W)))
            if "bs" in sx:
                self.cycle_crossing(st, sx["bs"], float(sx.get("bw", 2.2)))
        t0 = getattr(st, "t0", st.s0)
        t1 = getattr(st, "t1", st.s1)
        if t1 - t0 < 1.0:
            return
        # carriageways in chunks, each between its own kerbs
        for i in range(st.ncw):
            for (u0, u1) in chunks(t0, t1):
                ring = st.line(u0, u1, lambda s, i=i: st.edges(s)[i][0]) + st.line(u1, u0, lambda s, i=i: st.edges(s)[i][1])
                self.out["carriage"].append({"k": st.k, "p": flat(ring)})
                self.footprint.append(ring)
        # medians between carriageways
        gaps = [(float(g["s0"]), float(g["s1"])) for g in st.spec.get("gaps", [])]
        for i, kind in enumerate(st.meds):
            if kind == "none":
                continue
            ml = lambda s, i=i: st.edges(s)[i][1]
            mr = lambda s, i=i: st.edges(s)[i + 1][0]
            if kind == "tram":
                m0, m1 = t0, t1
                strip = []
                for s in frange(m0, m1, 2.0):
                    strip += list(st.point(s, ml(s))) + list(st.point(s, mr(s)))
                self.out["medians"].append({"k": "paving", "s": [round(v, 2) for v in strip]})
                for (u0, u1) in self.kerb_runs(st, m0, m1):
                    self.out["kerbs"].append({"p": flat(st.line(u0, u1, ml))})   # the bed on its right
                    self.out["kerbs"].append({"p": flat(st.line(u1, u0, mr))})
                self.footprint.append(st.line(m0, m1, ml) + st.line(m1, m0, mr))
            else:
                # a raised median (grass or paving) with rounded noses short of the crossings,
                # broken where a side street crosses (gaps), the break paved as carriageway
                for (g0, g1) in gaps:
                    ring = st.line(g0, g1, ml) + st.line(g1, g0, mr)
                    self.out["carriage"].append({"k": st.k, "p": flat(ring)})
                    self.footprint.append(ring)
                for (u0, u1) in self.runs_minus(t0, t1, self.crossings.get(st.id, []) + gaps):
                    m0, m1 = u0 + NOSE, u1 - NOSE
                    if m1 - m0 < 2.0:
                        continue
                    ring = nose_round(st.line(m0, m1, ml), st.line(m1, m0, mr))
                    if kind == "grass":
                        strip = []
                        for s in frange(m0, m1, 2.0):
                            strip += list(st.point(s, ml(s))) + list(st.point(s, mr(s)))
                        self.out["medians"].append({"k": "grass", "s": [round(v, 2) for v in strip]})
                    self.out["islands"].append({"p": flat(ring)})
                    self.footprint.append(ring)
        # outer kerbs, continuous past the crossings (the renderer lowers them under each zebra,
        # map_builder _lowered_kerb, and lays the tactile pads on them); open at side roads
        breaks = []
        for op in self.openings_of(st):
            breaks.append(self.opening(st, op))
        for side in (-1, +1):
            own = [b for b in breaks if not (isinstance(b, tuple) and len(b) == 3 and b[2] != side)]
            for (u0, u1) in self.runs_minus(t0, t1, [(b[0], b[1]) for b in own]):
                if side < 0:
                    self.out["kerbs"].append({"p": flat(st.line(u1, u0, lambda s: st.outer(s, -1)))})
                else:
                    self.out["kerbs"].append({"p": flat(st.line(u0, u1, lambda s: st.outer(s, +1)))})
        self.paint(st, t0, t1)

    def opening(self, st, op):
        """A side road or driveway leaving the street: the kerb opens, two small kerb returns
        lead into it and a patch of asphalt fills its mouth. Returns the kerb break (s0, s1, side)."""
        side = int(op["side"])
        s = float(op["s"])
        w = float(op.get("w", 6.0))
        r = float(op.get("r", 4.0))
        depth = float(op.get("depth", r + 1.5))
        p, d = st.at(s)
        nrm = mul(right_of(d), side)               # pointing out of the street, into the side road
        off = st.outer(s, side)
        edge = add(p, mul(right_of(d), off))
        # the side road's own direction out of the street (an angled road gets an angled mouth),
        # kept within 65 degrees of square so the corners stay buildable
        v = norm(tuple(op["dir"])) if op.get("dir") else nrm
        if dot(v, nrm) < 0.42:
            along = 1.0 if dot(v, d) > 0 else -1.0
            v = norm(add(mul(nrm, 0.42), mul(d, along * 0.907)))
        nv = right_of(v)
        if dot(nv, d) < 0:
            nv = mul(nv, -1.0)
        kerbs = []
        span = []
        for sgn in (-1, +1):
            # where this edge of the side road meets the street's kerb line
            q = mul(nv, sgn * w / 2.0)
            det = d[0] * (-v[1]) - d[1] * (-v[0])
            u = (q[0] * (-v[1]) - q[1] * (-v[0])) / det if abs(det) > 1e-6 else sgn * w / 2.0
            I = add(edge, mul(d, u))
            u1 = mul(d, float(sgn))                # along the kerb, away from the mouth
            phi = math.acos(max(-1.0, min(1.0, dot(u1, v))))
            T = r / math.tan(phi / 2.0)
            A = add(I, mul(u1, T))
            B = add(I, mul(v, T))
            c = add(I, mul(norm(add(u1, v)), r / math.sin(phi / 2.0)))
            a1 = math.atan2(A[1] - c[1], A[0] - c[0])
            a2 = math.atan2(B[1] - c[1], B[0] - c[0])
            pts = arc(c, r, a1, a2, 0.7) + [add(B, mul(v, 0.5))]
            kerbs.append(pts)
            span.append(u + sgn * T)
        ring = kerbs[0] + list(reversed(kerbs[1]))
        self.out["carriage"].append({"k": op.get("k", "service"), "p": flat(ring)})
        links = op.get("links", [])
        if op.get("merged"):
            links = [([add(edge, mul(v, 1.0)), add(edge, mul(v, 9.0))], w)]
        for pts, lw in links:
            band = strip(pts, lw / 2.0)
            if band:
                self.out["carriage"].append({"k": op.get("k", "service"), "p": flat(band)})
                self.mouths.append(band)
        self.mouths.append(ring)
        # kerb returns: the pavement on the line's right
        for sgn, pts in zip((-1, +1), kerbs):
            run = pts if (sgn * side) < 0 else list(reversed(pts))
            self.out["kerbs"].append({"p": flat(run)})
        return (s + min(span), s + max(span), side)

    def runs_minus(self, s0, s1, holes):
        runs = [(s0, s1)]
        for (c0, c1) in sorted(holes):
            nxt = []
            for (u0, u1) in runs:
                if c1 <= u0 or c0 >= u1:
                    nxt.append((u0, u1))
                    continue
                if c0 - u0 > 0.5:
                    nxt.append((u0, c0))
                if u1 - c1 > 0.5:
                    nxt.append((c1, u1))
            runs = nxt
        return runs

    def kerb_runs(self, st, s0, s1):
        """[s0, s1] minus the crossings (lowered kerbs)."""
        return self.runs_minus(s0, s1, self.crossings.get(st.id, []))

    def paint(self, st, s0, s1):
        """Lane lines (lane boundaries), bus, cycle and parking lanes, hatched gaps, arrows, words."""
        stops = self.stops.get(st.id, [])
        runs = {}
        s = s0
        while s <= s1 + 1e-6:
            for ci, row in enumerate(st.lanes(s)):
                for li in range(len(row) - 1):
                    a, b = row[li][0], row[li + 1][0]
                    kind = boundary_kind(a, b)
                    if kind is None:
                        continue
                    d = int(a.get("d", 1))
                    for (ss, din) in stops:
                        if kind == "lane" and din == d and int(b.get("d", 1)) == d and 0.0 <= (ss - s) * din <= SOLID:
                            kind = "solid"
                    if self.in_crossing(st, s) or self.past_stop(st, s, d, int(b.get("d", 1))):
                        kind = None
                    key = (ci, li, id(a), id(b))
                    runs.setdefault(key, []).append(None if kind is None else (kind, st.point(s, row[li][2])))
                for (x, l, r) in row:
                    if x.get("k") == "bike":
                        item = None if self.in_crossing(st, s) else ("cyclefill", st.point(s, (l + r) / 2.0), r - l)
                        runs.setdefault(("fill", ci, id(x)), []).append(item)
            s += STEP
        for key, seq in runs.items():
            cur = []
            last = None
            for item in seq + [None]:
                k = item[0] if item else None
                if item is None or (last is not None and k != last):
                    if len(cur) >= 2:
                        m = {"k": last, "p": flat([c[1] for c in cur])}
                        if last == "cyclefill":
                            m["w"] = round(cur[0][2] - 0.1, 2)
                        self.out["markings"].append(m)
                    cur = [] if item is None else ([cur[-1], item] if cur and k != "cyclefill" and last is not None else [item])
                    last = k
                    continue
                cur.append(item)
                last = k
        self.hatch(st, s0, s1)
        # arrows before every stop line
        for (ss, din) in stops:
            for back in ARROWS:
                sa = ss - din * back
                if not (s0 + 3 < sa < s1 - 3) or self.in_crossing(st, sa):
                    continue
                for row in st.lanes(sa):
                    for (x, l, r) in row:
                        if int(x.get("d", 1)) != din or x.get("k", "lane") != "lane" or not x.get("t"):
                            continue
                        p, d = st.at(sa)
                        c = add(p, mul(right_of(d), (l + r) / 2.0))
                        dd = mul(d, din)
                        self.out["symbols"].append({"k": "arrow", "x": round(c[0], 2), "z": round(c[1], 2),
                                                    "d": [round(dd[0], 3), round(dd[1], 3)], "t": x["t"]})
        # BUS words and bike symbols
        for kind, every in (("bus", BUS_EVERY), ("bike", BIKE_EVERY)):
            s = s0 + every / 2.0
            while s < s1 - 8:
                if not self.in_crossing(st, s) and not any(abs(s - ss) < 8 for (ss, _) in stops):
                    for row in st.lanes(s):
                        for (x, l, r) in row:
                            if x.get("k", "lane") == kind:
                                p, d = st.at(s)
                                c = add(p, mul(right_of(d), (l + r) / 2.0))
                                dd = mul(d, int(x.get("d", 1)))
                                self.out["symbols"].append({"k": kind, "x": round(c[0], 2), "z": round(c[1], 2),
                                                            "d": [round(dd[0], 3), round(dd[1], 3)]})
                s += every

    def hatch(self, st, s0, s1):
        """Painted gaps (P-21): diagonal bars every HATCH metres between the gap's edges."""
        s = s0 + 1.0
        while s < s1 - 1.0:
            if not self.in_crossing(st, s):
                for row in st.lanes(s):
                    for (x, l, r) in row:
                        if x.get("k") == "gap" and r - l > 0.8:
                            a = st.point(s, l + 0.2)
                            b = st.point(min(s + (r - l) * 0.8, s1), r - 0.2)
                            self.out["markings"].append({"k": "stripe", "p": flat([a, b])})
            s += HATCH

    def in_crossing(self, st, s):
        return any(c0 - 0.3 <= s <= c1 + 0.3 for (c0, c1) in self.crossings.get(st.id, []))

    def past_stop(self, st, s, d, d2):
        """Between a stop line and its junction (the crossing and the throat): no lane lines."""
        for (ss, din) in self.stops.get(st.id, []):
            if (d == din or d2 == din) and (s - ss) * din > 0:
                return True
        return False

    def openings_of(self, st):
        """The street's side-road openings: found on the map's own roads where one crosses the
        street's outer kerb (when the map is given), plus any the spec marks "keep"; else the spec's."""
        if self.roads is None:
            return st.spec.get("openings", [])
        if not hasattr(st, "auto_open"):
            st.auto_open = self.find_openings(st) + [o for o in st.spec.get("openings", []) if o.get("keep")]
        return st.auto_open

    def find_openings(self, st):
        names = {x.spec.get("name") for x in self.streets.values()}
        t0 = getattr(st, "t0", st.s0)
        t1 = getattr(st, "t1", st.s1)
        xs = [p[0] for p in st.pts]
        zs = [p[1] for p in st.pts]
        box = (min(xs) - 40, min(zs) - 40, max(xs) + 40, max(zs) + 40)
        hits = []
        for r in self.roads:
            if r.get("bridge") or r.get("name") in names or r.get("k") in SIDE_SKIP:
                continue
            p = pts_of(r["p"])
            if not any(box[0] < x < box[2] and box[1] < z < box[3] for x, z in p):
                continue
            prev = None
            for q in dense(p, 1.0):
                s, off = project(st, q)
                if s is None or not (t0 + 4.0 < s < t1 - 4.0):
                    prev = None
                    continue
                side = 1 if off > 0 else -1
                out = side * (off - st.outer(s, side))      # > 0: beyond the kerb, on the pavement
                if prev is not None and prev[2] == side and (prev[1] > 0) != (out > 0) and abs(off) < 60:
                    hits.append((side, (s + prev[0]) / 2.0, float(r.get("w", 4.0)), r.get("k", "service"), r, q))
                prev = (s, out, side)
        # one opening per side road mouth; the road must run on at least 3 m past the kerb
        found = []
        for side, s, w, k, r, at in sorted(hits, key=lambda h: (h[0], h[1])):
            ok = False
            for q in pts_of(r["p"]):
                ss, off = project(st, q)
                if ss is not None and abs(ss - s) < 40 and side * (off - st.outer(ss, side)) > 3.0:
                    ok = True
                    break
            if not ok:
                continue
            # the side road's own line from the kerb out (8 m): paved, so a road meeting the street at
            # an angle still reaches the mouth
            out_pts = []
            for q in dense(pts_of(r["p"]), 0.5):
                ss, off = project(st, q)
                if ss is not None and math.dist(q, at) < 9.0 and side * (off - st.outer(ss, side)) > -1.0:
                    out_pts.append(q)
            links = [(out_pts, w)] if len(out_pts) >= 2 else []
            far = max(out_pts, key=lambda q: math.dist(q, at)) if out_pts else None
            vdir = norm(sub(far, at)) if far is not None and math.dist(far, at) > 1.0 else None
            if found and found[-1]["side"] == side and abs(found[-1]["s"] - s) < (found[-1]["w"] + w) / 2.0 + 4.0:
                f = found[-1]                       # two ribbons of one mouth (in and out): one wider mouth
                f.setdefault("sum_w", f["w"] - 0.8)
                lo, hi = min(f["s"] - f["w"] / 2.0, s - w / 2.0), max(f["s"] + f["w"] / 2.0, s + w / 2.0)
                f["s"], f["w"] = (lo + hi) / 2.0, hi - lo
                # a Y of two one-way ribbons: one mouth as wide as both roads (not the gap between them),
                # paved straight out along the mean direction to where the ribbons join
                f["links"] = []
                f["merged"] = True
                f["sum_w"] = f.get("sum_w", f["w"] - 0.8) + w
                f["w"] = min(hi - lo, f["sum_w"] + 0.8)
                if vdir and f.get("dir"):
                    f["dir"] = list(norm(add(tuple(f["dir"]), vdir)))
                continue
            found.append({"s": s, "side": side, "w": max(3.5, w + 0.8),
                          "r": 3.0 if k in ("service", "living_street", "track", "pedestrian") else 5.0, "auto": True,
                          "links": links, "dir": list(vdir) if vdir else None})
        return found

    def build(self):
        for j in self.spec.get("junctions", []):
            self.build_junction(j)
        for st in self.streets.values():
            self.build_street(st)
        return self


def strip(pts, half):
    """A polygon `half` either side of a polyline."""
    if len(pts) < 2:
        return None
    left, right = [], []
    for i, p in enumerate(pts):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        d = norm(sub(b, a))
        n = right_of(d)
        left.append(add(p, mul(n, -half)))
        right.append(add(p, mul(n, half)))
    return left + list(reversed(right))


SIDE_SKIP = ("footway", "path", "cycleway", "steps", "pedestrian", "platform", "corridor")


def boundary_kind(a, b):
    ka, kb = a.get("k", "lane"), b.get("k", "lane")
    da, db = int(a.get("d", 1)), int(b.get("d", 1))
    if "gap" in (ka, kb):
        return "solid"
    if "park" in (ka, kb):
        return "edge"
    if "bike" in (ka, kb):
        return "cycle"
    if "bus" in (ka, kb):
        return "bus"
    if da != db:
        return "centre"
    return "lane"


def frange(a, b, step):
    n = max(1, int(math.ceil((b - a) / step)))
    return [a + (b - a) * k / n for k in range(n + 1)]


def chunks(a, b):
    n = max(1, int(math.ceil((b - a) / CHUNK)))
    return [(a + (b - a) * k / n, a + (b - a) * (k + 1) / n) for k in range(n)]


def dedupe(ring, eps=0.05):
    out = []
    for p in ring:
        if not out or math.dist(out[-1], p) > eps:
            out.append(p)
    if len(out) > 2 and math.dist(out[0], out[-1]) <= eps:
        out.pop()
    return out


NOSE_R = 0.8          # m: corner radius of a median's square end (as kerbed in Warsaw)


def nose_round(left, right, rc=NOSE_R):
    """A median outline (left edge forward, right edge back) with square ends, their two corners
    rounded by `rc` (Warsaw's medians end square across the lane, not in a half circle)."""
    def corner(a, P, b):
        # quadratic curve from a to b with P as the control: a rounded corner at P
        return [add(add(mul(a, (1 - t) ** 2), mul(P, 2 * (1 - t) * t)), mul(b, t * t))
                for t in (k / 6.0 for k in range(7))]

    def toward(P, Q, d):
        L = math.dist(P, Q)
        return lerp(P, Q, min(0.45, d / L)) if L > 0 else P

    w0 = math.dist(left[-1], right[0])
    w1 = math.dist(right[-1], left[0])
    r0 = max(0.05, min(rc, w0 / 2.0 - 0.05))
    r1 = max(0.05, min(rc, w1 / 2.0 - 0.05))
    body_l, body_r = left[1:-1], right[1:-1]
    out = []
    # start corner (left[0]), coming from right[-1]
    out += corner(toward(left[0], right[-1], r1), left[0], toward(left[0], left[1], r1))
    out += body_l
    out += corner(toward(left[-1], left[-2], r0), left[-1], toward(left[-1], right[0], r0))
    out += corner(toward(right[0], left[-1], r0), right[0], toward(right[0], right[1], r0))
    out += body_r
    out += corner(toward(right[-1], right[-2], r1), right[-1], toward(right[-1], left[0], r1))
    return out


# --- applying to the map ----------------------------------------------------------------------

class Footprint:
    """Point-in-footprint tests on a grid of the designed polygons, padded."""

    def __init__(self, polys, pad):
        self.polys = []
        self.grid = {}
        self.pad = pad
        for k, p in enumerate(polys):
            xs = [q[0] for q in p]
            zs = [q[1] for q in p]
            box = (min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad)
            self.polys.append((p, box))
            for gx in range(int(box[0] // 20), int(box[2] // 20) + 1):
                for gz in range(int(box[1] // 20), int(box[3] // 20) + 1):
                    self.grid.setdefault((gx, gz), []).append(k)

    def has(self, x, z):
        for k in self.grid.get((int(x // 20), int(z // 20)), []):
            p, box = self.polys[k]
            if not (box[0] <= x <= box[2] and box[1] <= z <= box[3]):
                continue
            if inside(x, z, p):
                return True
            if self.pad > 0 and near_ring(x, z, p, self.pad):
                return True
        return False


def near_ring(x, z, ring, r):
    for i in range(len(ring)):
        a, b = ring[i], ring[(i + 1) % len(ring)]
        ab = sub(b, a)
        L2 = dot(ab, ab)
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, dot(sub((x, z), a), ab) / L2))
        q = add(a, mul(ab, t))
        if math.dist(q, (x, z)) <= r:
            return True
    return False


def dense(pts, step=1.0):
    out = [pts[0]]
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        out += [lerp(a, b, k / n) for k in range(1, n + 1)]
    return out


def clip_line(pts, fp):
    """The parts of a polyline outside the footprint (sampled every metre)."""
    d = dense(pts)
    keep = [not fp.has(x, z) for (x, z) in d]
    runs, cur = [], []
    for p, k in zip(d, keep):
        if k:
            cur.append(p)
        elif cur:
            runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    return [simplify_run(r) for r in runs if len(r) >= 2 and plen(r) > 0.6]


def simplify_run(pts, tol=0.03):
    if len(pts) < 3:
        return pts
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[i], pts[i + 1]
        if abs(cross(sub(b, a), norm(sub(c, a)))) > tol:
            out.append(b)
    out.append(pts[-1])
    return out


def hide_ranges(road, fp):
    """The metres along a road's centreline that lie in the footprint (merged with its old ones)."""
    pts = pts_of(road["p"])
    cum = [0.0]
    for i in range(1, len(pts)):
        cum.append(cum[-1] + math.dist(pts[i - 1], pts[i]))
    spans = []
    start = None
    s = 0.0
    total = cum[-1]
    while s <= total + 1e-6:
        i = 0
        while i < len(cum) - 2 and cum[i + 1] < s:
            i += 1
        seg = cum[i + 1] - cum[i] if len(cum) > 1 else 0
        p = lerp(pts[i], pts[i + 1], (s - cum[i]) / seg) if seg > 0 else pts[i]
        hit = fp.has(p[0], p[1])
        if hit and start is None:
            start = max(0.0, s - 0.5)
        if not hit and start is not None:
            spans.append([round(start, 2), round(min(total, s - 0.5), 2)])
            start = None
        s += 1.0
    if start is not None:
        spans.append([round(start, 2), round(total, 2)])
    old = [list(h) for h in road.get("hide", [])]
    allh = sorted(old + spans)
    merged = []
    for h in allh:
        if merged and h[0] <= merged[-1][1] + 0.01:
            merged[-1][1] = max(merged[-1][1], h[1])
        else:
            merged.append(h)
    return merged


VERSION = 1


def apply_design(out, d):
    """Removes the old road layers in the design's footprint and writes the design's own."""
    fp = Footprint(d.footprint + d.mouths, FOOT_PAD)
    fp_tight = Footprint(d.footprint, 0.3)
    stats = {}

    def drop(layer, test):
        before = len(out.get(layer, []))
        out[layer] = [f for f in out.get(layer, []) if not test(f)]
        stats[layer] = before - len(out[layer])

    def centre_in(f, key="p"):
        p = pts_of(f[key])
        cx = sum(q[0] for q in p) / len(p)
        cz = sum(q[1] for q in p) / len(p)
        return fp.has(cx, cz)

    def mostly_in(f, key="p", share=0.5):
        p = dense(pts_of(f[key]), 2.0)
        n = sum(1 for q in p if fp_tight.has(*q))
        return n >= share * len(p)

    # roads: hide where they run in the footprint (the graph and everything else keep them)
    hidden = 0
    for r in out["roads"]:
        if r.get("dk") is not None or r.get("bridge"):
            continue
        h = hide_ranges(r, fp_tight)
        if h != r.get("hide", []):
            r["hide"] = h
            hidden += 1
    stats["roads hidden"] = hidden
    drop("carriage", lambda f: f.get("dk") is None and mostly_in(f))
    drop("asphalt_fills", lambda f: centre_in(f))
    drop("islands", lambda f: f.get("dk") is None and centre_in(f))
    drop("tram_noses", lambda f: centre_in(f))
    drop("tram_xings", lambda f: centre_in(f))
    drop("medians", lambda f: f.get("dk") is None and centre_in(f, "s"))
    drop("symbols", lambda f: f.get("dk") is None and fp.has(f["x"], f["z"]))
    # the old medians' grass and planter walls (the design draws its own medians)
    drop("areas", lambda f: f.get("k") in ("grass", "park") and mostly_in(f, share=0.6))
    drop("paths", lambda f: f["k"] in ("zebra", "cyclecross") and f.get("dk") is None
         and any(fp_tight.has(*q) for q in dense(pts_of(f["p"]), 1.0)))
    # footways and cycle tracks: clipped where they cross the new asphalt (the zebras and the
    # cycle crossings carry them over it)
    paths = []
    cut = 0
    for f in out.get("paths", []):
        if f["k"] not in ("foot", "cycle") or f.get("dk") is not None:
            paths.append(f)
            continue
        p = pts_of(f["p"])
        if not any(fp_tight.has(*q) for q in dense(p, 1.0)):
            paths.append(f)
            continue
        cut += 1
        for run in clip_line(p, fp_tight):
            g = dict(f)
            g["p"] = flat(run)
            paths.append(g)
    out["paths"] = paths
    stats["paths clipped"] = cut
    # kerbs and painted lines: clipped to outside the footprint
    walls = []
    cut = 0
    for f in out.get("lines", []):
        p = pts_of(f["p"])
        if f.get("k") not in ("wall", "fence", "hedge") or not any(fp_tight.has(*q) for q in dense(p, 1.0)):
            walls.append(f)
            continue
        cut += 1
        for run in clip_line(p, fp_tight):
            g = dict(f)
            g["p"] = flat(run)
            walls.append(g)
    out["lines"] = walls
    stats["walls clipped"] = cut
    for layer in ("kerbs", "markings"):
        keep = []
        cut = 0
        for f in out.get(layer, []):
            if f.get("dk") is not None:
                keep.append(f)
                continue
            p = pts_of(f["p"])
            if not any(fp.has(*q) for q in dense(p, 2.0)):
                keep.append(f)
                continue
            cut += 1
            for run in clip_line(p, fp):
                g = dict(f)
                g["p"] = flat(run)
                keep.append(g)
        out[layer] = keep
        stats[layer + " clipped"] = cut
    # the design's own
    o = d.out
    out["carriage"] += o["carriage"]
    out["kerbs"] += o["kerbs"]
    out["islands"] += o["islands"]
    out["medians"] += o["medians"]
    out["markings"] += o["markings"]
    out["symbols"] += o["symbols"]
    out["paths"] += [{"k": "zebra", "p": z["p"], "w": z.get("w", CROSS_W)} for z in o["zebras"]]
    out["paths"] += [{"k": "cyclecross", "p": z["p"]} for z in o["cyclecross"]]
    out.setdefault("tram_xings", [])
    out["tram_xings"] += o["tram_xings"]
    stats["traffic edges on the designed lanes"] = retarget_graph(out, d)
    out.setdefault("road_design", {})[d.area] = d.spec.get("version", VERSION)
    return stats


BLEND = 12.0          # m: at a street's free end the traffic lanes blend back to the old ones


def drive_lanes(st, s, d):
    """(centre offset, count, mean width) of the lanes driven in direction d at s (lane and bus)."""
    xs = []
    for row in st.lanes(s):
        for (x, l, r) in row:
            if int(x.get("d", 1)) == d and x.get("k", "lane") in ("lane", "bus"):
                xs.append((l, r))
    if not xs:
        return None
    lo = min(l for l, r in xs)
    hi = max(r for l, r in xs)
    return ((lo + hi) / 2.0, len(xs), sum(r - l for l, r in xs) / len(xs))


def retarget_graph(out, d):
    """Moves the traffic graph's edges on the designed streets onto the designed lanes: the edge's
    line follows the middle of its direction's lanes, with their count and width (the graph's
    junctions and links stay as they were). Returns how many edges moved."""
    g = out.get("graph")
    if not g:
        return 0
    moved = 0
    for e in g["edges"]:
        if e.get("br"):
            continue
        for st in d.streets.values():
            if e.get("name") != st.spec.get("name"):
                continue
            p = dense(pts_of(e["p"]), 2.0)
            proj = []
            for q in p:
                ss, off = project(st, q)
                ok = ss is not None and 0.0 <= ss <= st.L and math.dist(q, st.point(ss, off)) < 0.6 and abs(off) < 30
                proj.append((ss, off) if ok else None)
            on = [x for x in proj if x is not None]
            if len(on) < max(3, len(p) // 2):
                continue
            dirn = 1 if on[-1][0] > on[0][0] else -1
            mid = drive_lanes(st, on[len(on) // 2][0], dirn)
            if mid is None:
                continue
            # the edge must already run on its direction's side (a two-way street's lanes share a line)
            if abs(on[len(on) // 2][1] - mid[0]) > 9.0:
                continue
            free0 = st.spec.get("start") is None
            free1 = st.spec.get("end") is None
            new = []
            for q, x in zip(p, proj):
                if x is None:
                    new.append(q)
                    continue
                ss = x[0]
                lane = drive_lanes(st, ss, dirn)
                if lane is None:
                    new.append(q)
                    continue
                w = 1.0
                if free0:
                    w = min(w, ss / BLEND)
                if free1:
                    w = min(w, (st.L - ss) / BLEND)
                w = max(0.0, min(1.0, w))
                new.append(lerp(q, st.point(ss, lane[0]), w))
            old_len = plen(pts_of(e["p"]))
            new_len = plen(new)
            e["s1"] = round(max(float(e["s0"]) + 0.1, new_len - (old_len - float(e["s1"]))), 2)
            e["p"] = flat(new)
            e["n"] = mid[1]
            e["lw"] = round(mid[2], 2)
            e["o"] = round(-(mid[1] - 1) / 2.0 * mid[2], 2)
            moved += 1
            break
    return moved


def load_spec(area):
    with open(os.path.join(SPECS, area + ".json"), encoding="utf-8") as f:
        return json.load(f)


def apply_all(out):
    """bake_osm.py: every area in docs/roads/ (a fresh bake has none applied)."""
    done = []
    if not os.path.isdir(SPECS):
        return "no areas"
    for name in sorted(os.listdir(SPECS)):
        if not name.endswith(".json"):
            continue
        area = name[:-5]
        if area in out.get("road_design", {}):
            continue
        d = Design(load_spec(area), out["roads"]).build()
        apply_design(out, d)
        problems = check(d)
        done.append("%s (%d problems)" % (area, len(problems)))
    return "designed " + (", ".join(done) if done else "nothing new")


# --- checks -----------------------------------------------------------------------------------

def check(d):
    """The design's own rules: polygons simple, kerbs never cross each other, every lane line
    inside asphalt, every zebra end on a kerb or a median edge."""
    problems = []
    for c in d.out["carriage"]:
        p = pts_of(c["p"])
        if self_crossing(p):
            problems.append("carriage polygon crosses itself near (%.0f, %.0f)" % p[0])
    asphalt = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 0.25)
    for m in d.out["markings"]:
        if m["k"] in ("lane", "solid", "centre", "bus", "stop", "cycle"):
            for q in dense(pts_of(m["p"]), 2.0):
                if not asphalt.has(*q):
                    problems.append("%s line off the asphalt at (%.1f, %.1f)" % (m["k"], q[0], q[1]))
                    break
    kerbs = [pts_of(k["p"]) for k in d.out["kerbs"]]
    for i in range(len(kerbs)):
        for j in range(i + 1, len(kerbs)):
            x = polylines_cross(kerbs[i], kerbs[j])
            if x:
                problems.append("kerbs cross at (%.1f, %.1f)" % x)
    return problems


def self_crossing(p):
    n = len(p)
    if n < 4:
        return False
    for i in range(n):
        a, b = p[i], p[(i + 1) % n]
        for k in range(i + 2, n):
            if (k + 1) % n == i:
                continue
            c, e = p[k], p[(k + 1) % n]
            if seg_hit(a, b, c, e) is not None:
                return True
    return False


def polylines_cross(a, b):
    ba = (min(q[0] for q in a), min(q[1] for q in a), max(q[0] for q in a), max(q[1] for q in a))
    bb = (min(q[0] for q in b), min(q[1] for q in b), max(q[0] for q in b), max(q[1] for q in b))
    if ba[2] < bb[0] or bb[2] < ba[0] or ba[3] < bb[1] or bb[3] < ba[1]:
        return None
    for i in range(len(a) - 1):
        for k in range(len(b) - 1):
            t = seg_hit(a[i], a[i + 1], b[k], b[k + 1])
            if t is not None and 0.02 < t < 0.98:
                return lerp(a[i], a[i + 1], t)
    return None


# --- evidence ---------------------------------------------------------------------------------

LAT0, LON0 = 52.2340, 21.0240
ML = 110574.0
MO = 111320.0 * math.cos(math.radians(LAT0))


def needs(area, osm_path):
    """The OSM tags of every way of the area's streets, ordered along their axes."""
    spec = load_spec(area)
    with open(osm_path, encoding="utf-8") as f:
        els = json.load(f)["elements"]
    nodes = {e["id"]: e for e in els if e["type"] == "node"}

    def xz(n):
        return ((n["lon"] - LON0) * MO, (LAT0 - n["lat"]) * ML)
    for sspec in spec["streets"]:
        st = Street(sspec)
        rows = []
        for e in els:
            t = e.get("tags", {})
            if e["type"] != "way" or "highway" not in t:
                continue
            pts = [xz(nodes[n]) for n in e["nodes"] if n in nodes]
            if len(pts) < 2:
                continue
            mid = pts[len(pts) // 2]
            s, off = project(st, mid)
            if s is None or abs(off) > 30 or not (-10 <= s <= st.L + 10):
                continue
            if t["highway"] in ("footway", "path", "steps", "pedestrian") and t.get("footway") != "crossing":
                continue
            keys = {k: v for k, v in t.items() if k.startswith(("lanes", "turn", "placement", "oneway", "cycleway",
                                                                  "bus", "psv", "width", "crossing", "footway"))}
            rows.append((s, off, e["id"], t.get("highway"), t.get("name", ""), keys))
        print("== %s (%s), %.0f m" % (st.id, sspec.get("name", ""), st.L))
        for s, off, wid, hw, name, keys in sorted(rows):
            print("  s %6.1f off %+6.1f  way %s %s %s %s" % (s, off, wid, hw, name, keys))
        for e in els:
            if e["type"] == "node" and e.get("tags", {}).get("highway") in ("crossing", "traffic_signals"):
                s, off = project(st, xz(e))
                if s is not None and abs(off) < 25 and -5 <= s <= st.L + 5:
                    print("  s %6.1f off %+6.1f  node %s %s" % (s, off, e["id"], e["tags"]))


def project(st, p):
    best = None
    for i in range(len(st.pts) - 1):
        a, b = st.pts[i], st.pts[i + 1]
        ab = sub(b, a)
        L2 = dot(ab, ab)
        if L2 == 0:
            continue
        t = max(0.0, min(1.0, dot(sub(p, a), ab) / L2))
        q = add(a, mul(ab, t))
        dd = math.dist(q, p)
        if best is None or dd < best[0]:
            off = cross(norm(ab), sub(p, a))
            best = (dd, st.cum[i] + t * math.sqrt(L2), off)
    return (best[1], best[2]) if best else (None, None)


def main(argv):
    if "--check-all" in argv:
        with open(MAP, encoding="utf-8") as f:
            out = json.load(f)
        bad = 0
        for area in sorted(out.get("road_design", {})):
            d = Design(load_spec(area)).build()
            probs = check(d)
            bad += len(probs)
            for p in probs[:20]:
                print("  %s: %s" % (area, p))
        print("road_design: %s, %d problems" % (", ".join(sorted(out.get("road_design", {}))) or "no areas", bad))
        return 1 if bad else 0
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 2
    area = args[0]
    if "--needs" in argv:
        needs(area, argv[argv.index("--needs") + 1])
        return 0
    d = Design(load_spec(area)).build()
    probs = check(d)
    for p in probs[:40]:
        print("  " + p)
    print("road_design: %s: %d carriage, %d kerbs, %d lines, %d arrows/words, %d zebras, %d problems" % (
        area, len(d.out["carriage"]), len(d.out["kerbs"]), len(d.out["markings"]), len(d.out["symbols"]),
        len(d.out["zebras"]), len(probs)))
    if "--check" in argv:
        return 1 if probs else 0
    src = argv[argv.index("--from") + 1] if "--from" in argv else MAP
    dst = argv[argv.index("--out") + 1] if "--out" in argv else MAP
    with open(src, encoding="utf-8") as f:
        out = json.load(f)
    if area in out.get("road_design", {}):
        raise SystemExit("road_design: %s is already applied to %s; use --from with the map from before" % (area, src))
    # built again on the map: the side roads' mouths come from the map's own roads
    d = Design(load_spec(area), out["roads"]).build()
    for st in d.streets.values():
        for o in getattr(st, "auto_open", []):
            print("  opening %s s %.0f %s w %.1f" % (st.id, o["s"], "right" if o["side"] > 0 else "left", o["w"]))
    stats = apply_design(out, d)
    print("road_design: removed " + ", ".join("%s %d" % kv for kv in stats.items()))
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
