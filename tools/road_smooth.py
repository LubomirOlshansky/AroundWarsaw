"""Smooth roads (F, 2026-11-05: "make the roads smooth, like it was hand designed"): the width
steps where two OpenStreetMap ways of one carriageway meet, tapered; the lane lines stitched
across those joins; small kinks in the lines rounded.

    python3 -I tools/road_smooth.py [MAP.json] [--dry] [--report]
        rewrites the map in place (idempotent: a map already smoothed is left alone);
        --dry measures and changes nothing; --report prints the steps and jogs left.
    python3 -I tools/road_smooth.py --check [MAP.json]
        exit 1 unless the map is smoothed and its edge steps and line jogs are at most
        CHECK_STEPS and CHECK_JOGS (verify.sh step `smooth`; a ratchet: lower them, never raise).

Why. The bake draws every OpenStreetMap way as its own ribbon (`roads[].w` wide, `c` off its
centreline) and paints its lane lines on its own (bake_roads.bake_lane_lines). Where the lane
count or the width changes at a join, the ribbon edge jumps sideways, the wider way's round end
cap bulges past the narrower one (the dark blob by the kerb), the kerb and the edge line, walked
round that outline, jog with it, and every lane line ends and starts again up to 1.6 m aside.
852 joins of the demo box stepped their edge by more than 0.3 m (588 by more than 1 m). A real
street opens or closes a lane with a taper: the edge drifts over 20-30 m, the lines with it.

What, on the finished map data (bake_osm.py calls `apply(out)` after car_free and the other
post-passes; this file also runs on a baked map, as the cloud has no OpenStreetMap download):

1. Chains: two drivable ways (not service or living streets) meet end to end at one point,
   carry on within CHAIN_COS, on the same deck level, with the same name and one-way flag.
2. Taper: at every join whose edge steps by STEP_MIN..STEP_MAX m, both ways get per-vertex
   widths and centre offsets (`wv`, `cv`, one per point of `p`; vertices are added every
   TAPER_STEP m on the taper without moving the line, so `hide` distances stay true). On each
   side the wider way keeps its edge to the node and the narrower one flares out to it along one
   smoothstep over L = TAPER_BASE + TAPER_PER_M * step (TAPER_MIN..TAPER_MAX m, at most half
   the way): where the wider way's round end cap bulged, a lane now opens or closes. The kerbs
   and lines of the wider way stay true. map_builder.gd draws `wv`/`cv` roads as one mitred
   band, so both ends are as wide at the node and no cap bulges.
3. Kerbs and edge lines: their points by a tapered join that lie on the old stepped edge (or the
   wider way's round cap, between the two edges) are moved onto the tapered edge, keeping their
   inset (resampled every metre first); not on a side where another road leaves the node (the
   kerb turns into it there). No flare on such a side either: the wider way's corner meets the
   other road's mouth there (a flare showed as a dark flag over a driveway, F's crop by PKiN).
   Where a side's kerb runs smoothly past the taper (left alone above), the asphalt edge follows
   that kerb instead of its smoothstep (fit_kerbs), so no wedge of road pokes past the kerb.
4. Lines: a lane, centre, edge or cycle line that ends where another of its kind starts within
   STITCH_GAP m ahead, at most STITCH_SIDE m aside and parallel, is joined to it with the same
   kind of S-curve (one polyline, no gap, no jump).
5. Kinks: a lane, centre or cycle line's corner turning ROUND_MIN..ROUND_MAX degrees is rounded
   into a short arc (cut at most ROUND_CUT m each side); ribbons keep their round joins.

The lane graph, the carriageway areas, the junction boxes and the decks are not touched.
Deterministic, standard library only. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys
from collections import defaultdict

VERSION = 2
# --check (2026-11-05, the demo box after the first pass): 727 edge steps -> 15 (joins without room
# for a taper), 969 line jogs -> 16. Lower these when a change leaves fewer; never raise them.
CHECK_STEPS = 10
CHECK_JOGS = 16
MINOR = {"service", "living_street"}
CHAIN_COS = 0.85        # ways carry on: their directions at the join within ~32 degrees
STEP_MIN = 0.3          # m: a smaller edge step is invisible
STEP_MAX = 6.0          # m: a bigger one is a different road shape (a slip, a bay), not a lane
TAPER_BASE = 20.0
TAPER_PER_M = 3.0
TAPER_MIN = 20.0
TAPER_MAX = 30.0
TAPER_STEP = 2.5        # m between the taper's vertices
JOG_MIN = 0.15          # m off its own chord: a line that jogs or bulges by the node
JOG_REACH = 1.5         # m past the node where the old jog's points still go onto the edge
SMOOTH_PASSES = 6       # light averaging of a moved line's points by the node
EDGE_BAND = 0.7         # m: a kerb point this close to the old edge (or between the two) follows
LINE_KINDS = ("lane", "centre", "edge", "cycle", "cyclefill", "bus")
STITCH_GAP = 3.0        # m: a line starting this far ahead (or 1 m behind) carries the one ending
STITCH_BACK = 1.0
STITCH_SIDE = 3.6       # m aside at most (a lane)
STITCH_COS = 0.96       # parallel within ~16 degrees
ROUND_KINDS = ("lane", "centre", "cycle", "cyclefill", "bus")
ROUND_MIN = 3.0
ROUND_MAX = 35.0
ROUND_CUT = 4.0
ROUND_SEG = 3.0         # degrees per arc piece
RAIL_GAP_MIN = 0.3      # m: a strip of ground narrower than this between asphalt and ballast is invisible
RAIL_GAP_MAX = 3.0      # m: a wider one is a real verge, a stop or a separator, kept
RAIL_COVER = 0.6        # share of the way's visible vertices that must find the bed
RAIL_JUMP = 0.3         # m per metre along: how fast the gap may change (a straight bed)
CHAIN_FILL_MAX = 150.0  # m: a longer way narrower than its neighbours may really be narrower
KERB_GAP = 10.0         # m: a kerb break along a tram bed this short is joined across
KERB_SIDE = 0.3


def pts_of(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def flat_of(pts, nd=2):
    out = []
    for x, z in pts:
        out += [round(x, nd), round(z, nd)]
    return out


def unit(a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dz)
    return None if ln < 1e-6 else (dx / ln, dz / ln)


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def taper_len(step):
    return min(max(TAPER_BASE + TAPER_PER_M * step, TAPER_MIN), TAPER_MAX)


def length(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def resample_between(pts, s0, s1, step):
    """`pts` with extra vertices at s0, s0 + step, ... and s1 (distances along it; none moved)."""
    marks = []
    u = s0
    while u < s1 - 1e-6:
        marks.append(u)
        u += step
    marks.append(s1)
    out = [pts[0]]
    s = 0.0
    for a, b in zip(pts, pts[1:]):
        ln = math.dist(a, b)
        for u in marks:
            if s + 0.3 < u < s + ln - 0.3:
                t = (u - s) / ln
                out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
        out.append(b)
        s += ln
    return out


def cumulative(pts):
    cum = [0.0]
    for a, b in zip(pts, pts[1:]):
        cum.append(cum[-1] + math.dist(a, b))
    return cum


class Grid:
    def __init__(self, cell=16.0):
        self.cell = cell
        self.g = defaultdict(list)

    def add(self, item, x, z):
        self.g[(int(math.floor(x / self.cell)), int(math.floor(z / self.cell)))].append(item)

    def near(self, x, z, r):
        c = self.cell
        for i in range(int(math.floor((x - r) / c)), int(math.floor((x + r) / c)) + 1):
            for j in range(int(math.floor((z - r) / c)), int(math.floor((z + r) / c)) + 1):
                yield from self.g.get((i, j), ())


# --- 1. chains -----------------------------------------------------------------------------

def _end(r, i, last):
    """An end of road r seen from its node: (node, away direction, left, right) in the away frame
    (left/right: the drawn edges' offsets from the centreline, + to the right of `away`)."""
    p = r["p"]
    c = float(r.get("c", 0.0))
    hw = float(r["w"]) * 0.5
    if "wv" in r:   # a way fit_rail_beds widened: its own end
        k = len(r["wv"]) - 1 if last else 0
        c, hw = float(r["cv"][k]), float(r["wv"][k]) * 0.5
    if not last:
        node = (p[0], p[1])
        away = unit(node, (p[2], p[3]))
        return node, away, c - hw, c + hw
    node = (p[-2], p[-1])
    away = unit(node, (p[-4], p[-3]))
    return node, away, -(c + hw), -(c - hw)


def find_joins(roads):
    """[(ia, last_a, ib, last_b, node, away_a, (la, ra), (lb', rb') in a's away frame)] for every
    join of two ways of one chain whose edge steps STEP_MIN..STEP_MAX m."""
    ends = defaultdict(list)
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, lft, rgt = _end(r, i, last)
            if away is None:
                continue
            ends[(round(node[0], 1), round(node[1], 1))].append((i, last, node, away, lft, rgt))
    joins = []
    used = set()
    for key in sorted(ends):
        lst = ends[key]
        cands = []
        for x in range(len(lst)):
            for y in range(x + 1, len(lst)):
                ia, la_, na, aa, l1, r1 = lst[x]
                ib, lb_, nb, ab, l2, r2 = lst[y]
                if ia == ib:
                    continue
                A, B = roads[ia], roads[ib]
                if (A.get("name") or "") != (B.get("name") or "") or bool(A.get("oneway")) != bool(B.get("oneway")):
                    continue
                if not A.get("name") and A["k"] != B["k"]:
                    continue
                if int(A.get("dk", -1)) != int(B.get("dk", -1)):
                    continue
                cos = aa[0] * ab[0] + aa[1] * ab[1]
                if cos > -CHAIN_COS:
                    continue
                cands.append((cos, x, y))
        cands.sort()
        for cos, x, y in cands:
            if x in used_local(used, key) or y in used_local(used, key):
                continue
            ia, la_, na, aa, l1, r1 = lst[x]
            ib, lb_, nb, ab, l2, r2 = lst[y]
            # b's edges in a's away frame: b faces the other way, so its right is a's left.
            ob = (-r2, -l2)
            step = max(abs(l1 - ob[0]), abs(r1 - ob[1]))
            used.add((key, x))
            used.add((key, y))
            if STEP_MIN < step <= STEP_MAX:
                joins.append((ia, la_, ib, lb_, (na[0], na[1]), aa, (l1, r1), ob, step))
    return joins


def major_sides(roads, node, ia, ib, aa):
    """The sides (0 left, 1 right, in a's away frame) where a street (not a service road or a
    living street) other than ia and ib leaves `node`."""
    n = (-aa[1], aa[0])
    key = (round(node[0], 1), round(node[1], 1))
    out = set()
    for i in _NODE_ROADS.get(key, ()):
        if i in (ia, ib) or roads[i]["k"] in MINOR:
            continue
        p = roads[i]["p"]
        m = len(p) // 2
        for k in range(m):
            if (round(p[2 * k], 1), round(p[2 * k + 1], 1)) != key:
                continue
            for nb in ((k - 1,) if k == m - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                d = unit((p[2 * k], p[2 * k + 1]), (p[2 * nb], p[2 * nb + 1]))
                if d is not None:
                    out.add(1 if d[0] * n[0] + d[1] * n[1] > 0 else 0)
    return out


_NODE_ROADS = {}


def index_nodes(roads):
    """Which roads pass through each node (rounded to 0.1 m), for major_sides."""
    _NODE_ROADS.clear()
    for i, r in enumerate(roads):
        p = r["p"]
        for k in range(0, len(p) - 1, 2):
            _NODE_ROADS.setdefault((round(p[k], 1), round(p[k + 1], 1)), set()).add(i)


def branch_sides(roads, joins):
    """For each join, the sides (0 left, 1 right, in a's away frame) where another road leaves
    its node: the kerb there turns into that road (a corner return), so it is not moved."""
    at = defaultdict(list)
    for i, r in enumerate(roads):
        p = r["p"]
        n = len(p) // 2
        for k in range(n):
            key = (round(p[2 * k], 1), round(p[2 * k + 1], 1))
            for nb in ((k - 1,) if k == n - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                at[key].append((i, (p[2 * nb], p[2 * nb + 1])))
    out = []
    for ia, la_, ib, lb_, node, aa, ea, eb, step in joins:
        sides = set()
        n = (-aa[1], aa[0])
        for i, q in at[(round(node[0], 1), round(node[1], 1))]:
            if i in (ia, ib):
                continue
            d = unit(node, q)
            if d is None:
                continue
            sides.add(1 if d[0] * n[0] + d[1] * n[1] > 0 else 0)
        out.append(sides)
    return out


def used_local(used, key):
    return {x for k, x in used if k == key}


# --- 2. taper ------------------------------------------------------------------------------

def side_spans(ea, eb, L, la, lb):
    """Per side (left, right): where the edge moves, (metres on a, metres on b). The wider way
    keeps its edge to the node and the narrower one flares out to meet it (the wider way's round
    cap was drawn there; its kerb and lines are left as they are). At most half a way's length."""
    out = []
    for side in (0, 1):
        a_out = ea[side] < eb[side] if side == 0 else ea[side] > eb[side]
        if a_out:
            out.append((0.0, min(L, lb * 0.5)))
        else:
            out.append((min(L, la * 0.5), 0.0))
    return out


def taper_roads(roads, joins, ends):
    """Per-vertex `wv`/`cv` on both ways of every join. Returns the tapers for the kerbs:
    [(node, away_a, spans, (la, ra), (lb, rb), branch sides)] (b's edges in a's away frame;
    spans from side_spans); `ends` gets (ia, last_a, ib, last_b) per taper."""
    specs = defaultdict(list)   # road -> [(last, own spans, own(l, r), other(l, r))]
    out = []
    ends.clear()
    lens = {}
    blocked = branch_sides(roads, joins)
    for (ia, la_, ib, lb_, node, aa, ea, eb, step), sides in zip(joins, blocked):
        for i in (ia, ib):
            if i not in lens:
                lens[i] = length(pts_of(roads[i]["p"]))
        spans = side_spans(ea, eb, taper_len(step), lens[ia], lens[ib])
        if any(abs(ea[k] - eb[k]) > STEP_MIN and sum(spans[k]) < 4.0 for k in (0, 1)):
            continue   # no room for a taper: leave the join as it is
        # Loop 2: no flare on a side where a street leaves the node (its corner kerb turns into
        # that street). Loop 4 (F's crop of the PKiN driveway corner): a driveway or service road
        # there is drawn under the street (map_builder MINOR_ROAD_BIAS), so the flare runs on over
        # its mouth and the corner is smooth instead of a rounded notch.
        majors = major_sides(roads, node, ia, ib, aa)
        spans = [(0.0, 0.0) if k in majors else spans[k] for k in (0, 1)]
        specs[ia].append((la_, spans, ea, eb))
        # b in its own away frame: mirrored, so its left is a's right.
        mirrored = [(spans[1][1], spans[1][0]), (spans[0][1], spans[0][0])]
        specs[ib].append((lb_, mirrored, (-eb[1], -eb[0]), (-ea[1], -ea[0])))
        out.append((node, aa, spans, ea, eb, sides))
        ends.append((ia, la_, ib, lb_))
    for i, lst in specs.items():
        r = roads[i]
        pts = pts_of(r["p"])
        total = lens[i]
        # the way's own edges before the taper (fit_rail_beds may have set them per vertex)
        if "wv" in r:
            base_s = cumulative(pts)
            base = [(float(c) - float(w) * 0.5, float(c) + float(w) * 0.5) for w, c in zip(r["wv"], r["cv"])]
        else:
            base_s, base = None, None
        for last, spans, _, _ in lst:
            h = max(spans[0][0], spans[1][0])
            if h <= 0.0:
                continue
            if last:
                pts = resample_between(pts, total - h, total, TAPER_STEP)
            else:
                pts = resample_between(pts, 0.0, h, TAPER_STEP)
        cum = cumulative(pts)
        total = cum[-1]
        c0 = float(r.get("c", 0.0))
        hw = float(r["w"]) * 0.5
        wv, cv = [], []
        for s in cum:
            lft, rgt = c0 - hw, c0 + hw
            if base is not None:
                lft, rgt = _interp_edges(base_s, base, s)
            for last, spans, own, other in lst:
                u = total - s if last else s
                d = [0.0, 0.0]
                for k in (0, 1):
                    h, ho = spans[k]
                    if u < h:
                        d[k] = (other[k] - own[k]) * smooth((h - u) / (h + ho))
                    elif h <= 0.0 and u <= 0.0:
                        d[k] = 0.0
                if last:   # the away frame is mirrored: its left is the road's right
                    lft -= d[1]
                    rgt -= d[0]
                else:
                    lft += d[0]
                    rgt += d[1]
            wv.append(round(rgt - lft, 3))
            cv.append(round((rgt + lft) * 0.5, 3))
        r["p"] = flat_of(pts)
        r["wv"] = wv
        r["cv"] = cv
    return out


def _interp_edges(cum, edges, s):
    """The (left, right) edges at s m along, from per-vertex ones at the distances `cum`."""
    if s <= cum[0]:
        return edges[0]
    for k in range(1, len(cum)):
        if s <= cum[k]:
            f = (s - cum[k - 1]) / max(cum[k] - cum[k - 1], 1e-9)
            a, b = edges[k - 1], edges[k]
            return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
    return edges[-1]


def taper_edge(t, side, x):
    """Tapered edge offset (in a's away frame) at x m from the node (x > 0 on a, < 0 on b)."""
    node, aa, spans, ea, eb, _ = t
    ha, hb = spans[side]
    if ha + hb <= 0.0:
        return ea[side] if x > 0 else eb[side]
    # one smoothstep from a's edge (x = ha) to b's edge (x = -hb)
    f = smooth((ha - x) / (ha + hb))
    return ea[side] + (eb[side] - ea[side]) * f


# --- 3. kerbs and edge lines ---------------------------------------------------------------

def snap_lines(lines, tapers, get, put):
    """Moves the points of `lines` that lie on a taper's old stepped edge onto the new one."""
    grid = Grid(32.0)
    for k, t in enumerate(tapers):
        grid.add(k, t[0][0], t[0][1])
    moved = 0
    for li, line in enumerate(lines):
        pts = get(line)
        if len(pts) < 2:
            continue
        hits = set()
        for x, z in pts[:: max(1, len(pts) // 64)] + [pts[-1]]:
            for k in grid.near(x, z, 48.0):
                hits.add(k)
        if not hits:
            continue
        changed = False
        for k in sorted(hits):
            t = tapers[k]
            node, aa, spans, ea, eb, sides = t
            n = (-aa[1], aa[0])  # + is right of the direction, as bake_roads.offset_line and map_builder
            reach = max(max(sp) for sp in spans) + 1.5
            # resample near the node
            dense = []
            for a, b in zip(pts, pts[1:]):
                dense.append(a)
                if seg_dist(node, a, b) < reach + 30.0:
                    ln = math.dist(a, b)
                    m = int(ln)
                    for q in range(1, m):
                        dense.append((a[0] + (b[0] - a[0]) * q / m, a[1] + (b[1] - a[1]) * q / m))
            dense.append(pts[-1])
            # The line's own inset from the edge it follows (an edge line is painted ~0.3 m in
            # from the kerb), from its points on the old straight edges, kept on the new one.
            local = []
            for x, z in dense:
                dx, dz = x - node[0], z - node[1]
                ax = dx * aa[0] + dz * aa[1]
                if abs(ax) <= reach:
                    local.append((ax, dx * n[0] + dz * n[1]))
            inset = {}
            for side in (0, 1):
                # Only a line that really runs along this side's edge on the way that flares
                # (a kerb at a junction's corner or an island near it does not), at one inset.
                ha, hb = spans[side]
                if ha + hb <= 0.0 or abs(ea[side] - eb[side]) <= STEP_MIN:
                    continue
                # Its inset from the edge just past each end of the taper, where it is left as
                # it was; across the taper it follows the new edge, its inset blended between.
                xa = max(ha, JOG_REACH) + 0.5
                xb = -max(hb, JOG_REACH) - 0.5

                def at(x0, edge):
                    best = None
                    for ax, y in local:
                        if abs(ax - x0) <= 1.5 and abs(y - edge) <= EDGE_BAND:
                            if best is None or abs(ax - x0) < best[0]:
                                best = (abs(ax - x0), y - edge)
                    return None if best is None else best[1]
                ma, mb = at(xa, ea[side]), at(xb, eb[side])
                if ma is None or mb is None:
                    continue
                # A line that already runs smoothly across (the bake walked many a kerb at a
                # long slant) is left alone: only one that jogs or bulges by the node moves.
                ya, yb = ea[side] + ma, eb[side] + mb
                lo = min(ea[side], eb[side]) - EDGE_BAND
                hi = max(ea[side], eb[side]) + EDGE_BAND
                if not any(lo <= y <= hi and abs(y - (yb + (ya - yb) * (ax - xb) / (xa - xb))) > JOG_MIN
                           for ax, y in local if xb < ax < xa):
                    continue
                inset[side] = (ma, mb)
            new = []
            for q, (x, z) in enumerate(dense):
                dx, dz = x - node[0], z - node[1]
                ax = dx * aa[0] + dz * aa[1]
                y = dx * n[0] + dz * n[1]
                done = False
                for side in (0, 1):
                    if side in sides or side not in inset:
                        continue
                    ha, hb = spans[side]
                    # past the taper the edge is where it was; the step's own jog, just past
                    # the node on the wider way, goes onto that way's edge
                    if ax > max(ha, JOG_REACH) + 0.5 or ax < -max(hb, JOG_REACH) - 0.5:
                        continue
                    lo = min(ea[side], eb[side]) - EDGE_BAND
                    hi = max(ea[side], eb[side]) + EDGE_BAND
                    if lo <= y <= hi:
                        xa, xb = max(ha, JOG_REACH) + 0.5, -max(hb, JOG_REACH) - 0.5
                        f = (xa - ax) / (xa - xb)
                        ny = taper_edge(t, side, ax) + inset[side][0] + (inset[side][1] - inset[side][0]) * f
                        new.append((node[0] + aa[0] * ax + n[0] * ny, node[1] + aa[1] * ax + n[1] * ny))
                        done = True
                        moved += 1
                        changed = True
                        break
                if not done:
                    new.append((x, z))
            if moved_here(new, dense):
                # Even out what is left where the moved points meet the unmoved ones (a kerb
                # the bake drew at a slant, an inset that differs a little on the two ways).
                for _ in range(SMOOTH_PASSES):
                    out = [new[0]]
                    for q in range(1, len(new) - 1):
                        x, z = new[q]
                        if math.dist((x, z), node) <= reach + 4.0:
                            a, b = new[q - 1], new[q + 1]
                            x = 0.5 * x + 0.25 * (a[0] + b[0])
                            z = 0.5 * z + 0.25 * (a[1] + b[1])
                        out.append((x, z))
                    out.append(new[-1])
                    new = out
            pts = new
        if changed:
            put(line, simplify(pts, 0.03))
    return moved


def _poly_hit(pts, x, z):
    c = False
    n = len(pts)
    for i in range(n):
        ax, az = pts[i]
        bx, bz = pts[(i + 1) % n]
        if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
            c = not c
    return c


def fit_rail_beds(out):
    """Loop 3 (F's red lines by Złota; Mapillary 2026-08-30: the asphalt runs right up to the tram
    bed): a street drawn narrower than it is leaves a strip of bare ground (RAIL_GAP_MIN..MAX m)
    between its edge and a tram bed's ballast. That side's edge goes out onto the ballast, vertex
    by vertex (`wv`/`cv`), so the kerb runs straight along the tracks and the next way's taper has
    less to make up. Only where the bed is found along most of the way (RAIL_COVER) and the gap
    changes gently (RAIL_JUMP per sample); not over a platform, an island or a tree in the strip.
    Kerb and edge-line points on the old edge move out with it. Returns (ways, sides)."""
    beds = [pts_of(su["p"]) for su in out.get("surfaces", []) if su.get("k") == "ballast"]
    keep = [pts_of(q["p"]) for q in out.get("platforms", []) + out.get("islands", [])]
    grid = Grid(64.0)
    for k, poly in enumerate(beds):
        xs = [x for x, _ in poly]
        zs = [z for _, z in poly]
        for gx in range(int(math.floor(min(xs) / 64.0)), int(math.floor(max(xs) / 64.0)) + 1):
            for gz in range(int(math.floor(min(zs) / 64.0)), int(math.floor(max(zs) / 64.0)) + 1):
                grid.g[(gx, gz)].append(k)
    kgrid = Grid(32.0)
    for k, poly in enumerate(keep):
        xs = [x for x, _ in poly]
        zs = [z for _, z in poly]
        for gx in range(int(math.floor(min(xs) / 32.0)), int(math.floor(max(xs) / 32.0)) + 1):
            for gz in range(int(math.floor(min(zs) / 32.0)), int(math.floor(max(zs) / 32.0)) + 1):
                kgrid.g[(gx, gz)].append(k)
    tgrid = Grid(16.0)
    for key, n in (("trees", 4), ("trees3d", 6)):
        t = out.get(key, [])
        for q in range(0, len(t) - n + 1, n):
            tgrid.add((t[q], t[q + 1]), t[q], t[q + 1])

    def gap_at(x, z, nrm, sgn, edge):
        ex, ez = x + nrm[0] * edge, z + nrm[1] * edge
        dx, dz = nrm[0] * sgn, nrm[1] * sgn
        best = None
        for k in set(grid.near(ex, ez, 1.0)):
            poly = beds[k]
            for q in range(len(poly)):
                a, b = poly[q], poly[(q + 1) % len(poly)]
                sx, sz = b[0] - a[0], b[1] - a[1]
                den = dx * sz - dz * sx
                if abs(den) < 1e-9:
                    continue
                t = ((a[0] - ex) * sz - (a[1] - ez) * sx) / den
                v = ((a[0] - ex) * dz - (a[1] - ez) * dx) / den
                if 0.0 <= v <= 1.0 and -0.2 <= t <= RAIL_GAP_MAX + 0.5 and (best is None or t < best):
                    best = t
        if best is None or not (RAIL_GAP_MIN <= best <= RAIL_GAP_MAX):
            return None
        for f in (0.25, 0.5, 0.75):
            mx, mz = ex + dx * best * f, ez + dz * best * f
            if any(_poly_hit(beds[k], mx, mz) for k in set(grid.near(mx, mz, 1.0))):
                return None   # the edge already meets the ballast (a bend of the bed's outline)
            if any(_poly_hit(keep[k], mx, mz) for k in set(kgrid.near(mx, mz, 1.0))):
                return None
        mx, mz = ex + dx * best * 0.5, ez + dz * best * 0.5
        if any(math.dist(t, (mx, mz)) < best * 0.5 + 0.8 for t in tgrid.near(mx, mz, 4.0)):
            return None
        return best

    moved = []   # (road points, sign, old edge, gap per vertex)
    ways, sides = 0, 0
    for r in out["roads"]:
        if r["k"] in MINOR or int(r.get("dk", -1)) >= 0 or "wv" in r or len(r["p"]) < 4:
            continue
        pts = pts_of(r["p"])
        total = length(pts)
        if total < 15.0:
            continue
        hide = r.get("hide", [])
        cum = cumulative(pts)
        c0, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
        lft = [c0 - hw] * len(pts)
        rgt = [c0 + hw] * len(pts)
        samples = []   # (distance along, point, direction)
        for v in range(len(pts)):
            if any(h0 <= cum[v] <= h1 for h0, h1 in hide):
                continue
            a = pts[max(v - 1, 0)]
            b = pts[min(v + 1, len(pts) - 1)]
            u = unit(a, b)
            if u is not None:
                samples.append((v, pts[v], u))
        if len(samples) < 4:
            continue
        changed = False
        for sgn in (-1.0, 1.0):   # left, right (+ is right of travel)
            edge = c0 + sgn * hw
            got = {}
            for v, (x, z), u in samples:
                g = gap_at(x, z, (-u[1], u[0]), sgn, edge)
                if g is not None:
                    got[v] = g
            if len(got) < RAIL_COVER * len(samples) or len(got) < 3:
                continue
            # every vertex: its own gap, else the nearest found one along the way
            keys = sorted(got)
            gv = []
            for v in range(len(pts)):
                if v in got:
                    gv.append(got[v])
                else:
                    near = min(keys, key=lambda q: abs(cum[q] - cum[v]))
                    gv.append(got[near] if abs(cum[near] - cum[v]) <= 6.0 else 0.0)
            if any(abs(gv[v + 1] - gv[v]) > RAIL_JUMP * max(1.0, cum[v + 1] - cum[v]) for v in range(len(pts) - 1)):
                continue   # the bed's outline turns away (a stop, a loop): not one straight kerb
            for v in range(len(pts)):
                if sgn < 0:
                    lft[v] -= gv[v]
                else:
                    rgt[v] += gv[v]
            moved.append((pts, sgn, [edge] * len(pts), gv))
            sides += 1
            changed = True
        if changed:
            ways += 1
            r["wv"] = [round(b - a, 3) for a, b in zip(lft, rgt)]
            r["cv"] = [round((a + b) * 0.5, 3) for a, b in zip(lft, rgt)]
    move_with_edges(out, moved)
    return ways, sides


def move_with_edges(out, moved):
    """Kerbs, edge lines and tram-bed median strips standing on a road edge that moved out move
    with it. `moved`: [(road points, side sign, old edge offset per vertex, metres out per vertex)]."""
    if not moved:
        return
    lgrid = Grid(32.0)
    for k, (pts, _, _, _) in enumerate(moved):
        for x, z in pts:
            lgrid.add(k, x, z)
    lines = [(line, "p") for line in out.get("kerbs", [])] + \
        [(m, "p") for m in out.get("markings", []) if m["k"] == "edge"] + \
        [(m, "s") for m in out.get("medians", []) if m.get("k") != "grass"]
    for line, key in lines:
        lp = pts_of(line[key])
        new = []
        hit = False
        for x, z in lp:
            nx_, nz_ = x, z
            for k in set(lgrid.near(x, z, 40.0)):
                pts, sgn, edges, gv = moved[k]
                best = None
                for q, (a, b) in enumerate(zip(pts, pts[1:])):
                    u = unit(a, b)
                    if u is None:
                        continue
                    ln = math.dist(a, b)
                    al = (x - a[0]) * u[0] + (z - a[1]) * u[1]
                    if -0.5 <= al <= ln + 0.5:
                        f = min(max(al / ln, 0.0), 1.0)
                        edge = edges[q] + (edges[q + 1] - edges[q]) * f
                        off = (x - a[0]) * -u[1] + (z - a[1]) * u[0]
                        if abs(off - edge) <= 0.6 and (best is None or abs(off - edge) < best[0]):
                            best = (abs(off - edge), u, gv[q] + (gv[q + 1] - gv[q]) * f)
                if best is not None and best[2] > 0.0:
                    _, u, g = best
                    nx_, nz_ = x - u[1] * sgn * g, z + u[0] * sgn * g
                    hit = True
                    break
            new.append((nx_, nz_))
        if hit:
            line[key] = flat_of(new)


def _edges_of(r):
    """Per-vertex (left, right) edge offsets of a road."""
    n = len(r["p"]) // 2
    if "wv" in r:
        return [(float(c) - float(w) * 0.5, float(c) + float(w) * 0.5) for w, c in zip(r["wv"], r["cv"])]
    c, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
    return [(c - hw, c + hw)] * n


def fit_chain_widths(out):
    """Loop 5 (F's satellite shots, 2026-11-05: a street's kerbs run straight while its lanes
    come and go by paint): a way of a street drawn narrower on a side than the ways of the same
    street at BOTH its ends (its width came from its own lane count) takes that side's edge from
    them, blended along it, so the kerb runs on instead of stepping in and out again. Not under a
    carriageway area, at most CHAIN_FILL_MAX m long. Its lane lines stay; kerbs, edge lines and
    tram-bed strips on the old edge move out. Returns (ways, sides)."""
    roads = out["roads"]
    ends = defaultdict(list)
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, _, _ = _end(r, i, last)
            if away is not None:
                ends[(round(node[0], 1), round(node[1], 1))].append((i, last, away))

    def partner(i, last):
        """The other way's edges at i's end, in i's own frame (left, right), or None."""
        r = roads[i]
        node, away, _, _ = _end(r, i, last)
        best = None
        for j, lj, aw in ends[(round(node[0], 1), round(node[1], 1))]:
            if j == i:
                continue
            q = roads[j]
            if (q.get("name") or "") != (r.get("name") or "") or bool(q.get("oneway")) != bool(r.get("oneway")):
                continue
            if int(q.get("dk", -1)) != int(r.get("dk", -1)) or away[0] * aw[0] + away[1] * aw[1] > -CHAIN_COS:
                continue
            # q's drawn edges at its end, in its own frame, then in i's
            ql, qr = _edges_of(q)[-1 if lj else 0]
            # i and q run the same way when one leaves the node and the other arrives at it
            same = last != lj
            el, er = (ql, qr) if same else (-qr, -ql)
            if best is None:
                best = (el, er)
        return best
    moved = []
    ways, sides = 0, 0
    for i, r in enumerate(roads):
        if r["k"] in MINOR or r.get("hide") or int(r.get("dk", -1)) >= 0 or len(r["p"]) < 4:
            continue
        pts = pts_of(r["p"])
        cum = cumulative(pts)
        total = cum[-1]
        if total > CHAIN_FILL_MAX or total < 1.0:
            continue
        a, b = partner(i, False), partner(i, True)
        if a is None or b is None:
            continue
        edges = _edges_of(r)
        new = [list(e) for e in edges]
        changed = False
        for side, sgn in ((0, -1.0), (1, 1.0)):
            ea, eb = a[side], b[side]
            own0, own1 = edges[0][side], edges[-1][side]
            # wider than this way at both ends, on this side, by a visible step but not a bay
            out0 = ea - own0 if side == 1 else own0 - ea
            out1 = eb - own1 if side == 1 else own1 - eb
            if not (STEP_MIN < out0 <= STEP_MAX and STEP_MIN < out1 <= STEP_MAX):
                continue
            gv = []
            for v, s_ in enumerate(cum):
                t = ea + (eb - ea) * (s_ / total)
                old = edges[v][side]
                g = (t - old) if side == 1 else (old - t)
                g = max(g, 0.0)
                new[v][side] = old + (g if side == 1 else -g)
                gv.append(g)
            moved.append((pts, sgn, [e[side] for e in edges], gv))
            sides += 1
            changed = True
        if changed:
            ways += 1
            r["wv"] = [round(e[1] - e[0], 3) for e in new]
            r["cv"] = [round((e[0] + e[1]) * 0.5, 3) for e in new]
    move_with_edges(out, moved)
    return ways, sides


def bridge_rail_kerbs(out, kerbs, reach=0.6):
    """Loop 3: a kerb along a tram bed that breaks off for a few metres by a way join (the bake
    walked the old step round it) is joined across, straight: two kerb ends at most KERB_GAP m
    apart, in line (KERB_SIDE m aside, parallel), the gap along a ballast outline and crossed by
    no zebra or path (`reach`: how near the outline; an edge line is painted 0.3 m inside the
    kerb). Works on any list of lines (kerbs, edge lines); deletes the joined ones from it.
    Returns how many."""
    beds = [pts_of(su["p"]) for su in out.get("surfaces", []) if su.get("k") == "ballast"]
    bgrid = Grid(16.0)
    for k, poly in enumerate(beds):
        for q in range(len(poly)):
            a, b = poly[q], poly[(q + 1) % len(poly)]
            n = max(1, int(math.dist(a, b) / 8.0))
            for t in range(n + 1):
                bgrid.add((k, q), a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n)

    def on_bed(x, z):
        for k, q in set(bgrid.near(x, z, 10.0)):
            poly = beds[k]
            if seg_dist((x, z), poly[q], poly[(q + 1) % len(poly)]) <= reach:
                return True
        return False
    paths = [pts_of(pp["p"]) for pp in out.get("paths", [])]
    pgrid = Grid(32.0)
    for k, pts in enumerate(paths):
        for x, z in pts:
            pgrid.add(k, x, z)
    def find():
        ends = []
        grid = Grid(16.0)
        for i, kb in enumerate(kerbs):
            pts = pts_of(kb["p"])
            if len(pts) < 2 or int(kb.get("dk", -1)) >= 0:
                continue
            for last in (False, True):
                p = pts[-1] if last else pts[0]
                d = unit(pts[-2], pts[-1]) if last else unit(pts[1], pts[0])
                if d is None:
                    continue
                ends.append((i, last, p, d))
                grid.add(len(ends) - 1, p[0], p[1])
        found = []
        for e, (i, last, p, d) in enumerate(ends):
            for f in grid.near(p[0], p[1], KERB_GAP):
                if f <= e:
                    continue
                j, lj, q, dq = ends[f]
                if j == i or -(dq[0] * d[0] + dq[1] * d[1]) < 0.99:
                    continue
                dx, dz = q[0] - p[0], q[1] - p[1]
                along = dx * d[0] + dz * d[1]
                side = dx * -d[1] + dz * d[0]
                if not (0.5 <= along <= KERB_GAP) or abs(side) > KERB_SIDE:
                    continue
                if not all(on_bed(p[0] + dx * t, p[1] + dz * t) for t in (0.25, 0.5, 0.75)):
                    continue
                crossed = False
                for k in set(pgrid.near((p[0] + q[0]) * 0.5, (p[1] + q[1]) * 0.5, 40.0)):
                    if any(_segs_cross(p, q, a, b) for a, b in zip(paths[k], paths[k][1:])):
                        crossed = True
                        break
                if not crossed:
                    found.append((along, i, last, j, lj))
        return found
    done = 0
    while True:
        found = find()
        if not found:
            break
        _, i, last, j, lj = min(found)
        a = pts_of(kerbs[i]["p"])
        b = pts_of(kerbs[j]["p"])
        if not last:
            a = a[::-1]   # a now ends at the gap
        if lj:
            b = b[::-1]   # b now starts at it
        kerbs[i]["p"] = flat_of(a + b)
        del kerbs[j]
        done += 1
        if done > 5000:
            break
    return done


def _segs_cross(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (orient(a, b, c) > 0) != (orient(a, b, d) > 0) and (orient(c, d, a) > 0) != (orient(c, d, b) > 0)


def fit_kerbs(roads, tapers, ends, kerbs):
    """Loop 2 (F's crop on Marszałkowska by Złota): where a side's kerb runs smoothly past a
    taper (the bake walked it at a long slant, so snap_lines left it), the asphalt follows that
    kerb instead of its own smoothstep, so no wedge of road pokes past the kerb into the ballast
    or the pavement. The kerb's inset at the taper's two ends is kept (the edge meets the
    untouched road there exactly). Returns the sides fitted."""
    grid = Grid(32.0)
    segs = []
    for k in kerbs:
        pts = pts_of(k["p"])
        for a, b in zip(pts, pts[1:]):
            segs.append((a, b))
            grid.add(len(segs) - 1, (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
    fitted = 0
    for t, (ia, la_, ib, lb_) in zip(tapers, ends):
        node, aa, spans, ea, eb, sides = t
        n = (-aa[1], aa[0])
        reach = max(max(sp) for sp in spans) + 4.0

        def loc(p):
            dx, dz = p[0] - node[0], p[1] - node[1]
            return dx * aa[0] + dz * aa[1], dx * n[0] + dz * n[1]
        local = []
        for q in set(grid.near(node[0], node[1], reach + 20.0)):
            a, b = loc(segs[q][0]), loc(segs[q][1])
            if min(a[0], b[0]) <= reach and max(a[0], b[0]) >= -reach and abs(a[0] - b[0]) > 1e-6:
                local.append((a, b))
        for side in (0, 1):
            ha, hb = spans[side]
            if side in sides or ha + hb <= 0.0 or abs(ea[side] - eb[side]) <= STEP_MIN:
                continue
            lo = min(ea[side], eb[side]) - EDGE_BAND
            hi = max(ea[side], eb[side]) + EDGE_BAND

            def kerb(x):
                want = taper_edge(t, side, x)
                best = None
                for a, b in local:
                    if (a[0] - x) * (b[0] - x) > 0.0:
                        continue
                    y = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
                    if lo <= y <= hi and (best is None or abs(y - want) < abs(best - want)):
                        best = y
                return best
            xs = [ha - (ha + hb) * q / max(1, int(ha + hb)) for q in range(max(1, int(ha + hb)) + 1)]
            ks = [kerb(x) for x in xs]
            if any(k is None for k in ks):
                continue
            ka, kb = ks[0] - ea[side], ks[-1] - eb[side]

            def edge(x):
                f = (ha - x) / (ha + hb)
                return kerb(x) - (ka + (kb - ka) * f)
            if max(abs(edge(x) - taper_edge(t, side, x)) for x in xs) <= 0.1:
                continue
            # Each way's vertices on the taper, their edge on this side (a's frame -> the road's).
            for i, last, mirror in ((ia, la_, False), (ib, lb_, True)):
                r = roads[i]
                if "wv" not in r:
                    continue
                pts = pts_of(r["p"])
                flip = mirror != last   # the road's own right is a's frame left
                j = (1 - side) if flip else side
                sign = -1.0 if flip else 1.0
                for v, p in enumerate(pts):
                    ax, y0 = loc(p)
                    if not (-hb - 1e-6 <= ax <= ha + 1e-6) or math.dist(p, node) > reach:
                        continue
                    if (ax > 1e-6 and mirror) or (ax < -1e-6 and not mirror):
                        continue
                    k = kerb(ax)
                    if k is None:
                        continue
                    e = sign * (edge(ax) - y0)
                    c, hw = float(r["cv"][v]), float(r["wv"][v]) * 0.5
                    lft, rgt = c - hw, c + hw
                    if j == 0:
                        lft = e
                    else:
                        rgt = e
                    r["wv"][v] = round(rgt - lft, 3)
                    r["cv"][v] = round((rgt + lft) * 0.5, 3)
            fitted += 1
    return fitted


def moved_here(new, dense):
    return any(a != b for a, b in zip(new, dense))


def simplify(pts, tol):
    if len(pts) < 3:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        i, j = stack.pop()
        a, b = pts[i], pts[j]
        best, bi = -1.0, -1
        for k in range(i + 1, j):
            d = seg_dist(pts[k], a, b)
            if d > best:
                best, bi = d, k
        if best > tol:
            keep[bi] = True
            stack += [(i, bi), (bi, j)]
    return [p for p, k in zip(pts, keep) if k]


def seg_dist(p, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    l2 = abx * abx + abz * abz
    t = 0.0 if l2 < 1e-12 else min(max(((p[0] - a[0]) * abx + (p[1] - a[1]) * abz) / l2, 0.0), 1.0)
    return math.hypot(p[0] - a[0] - abx * t, p[1] - a[1] - abz * t)


# --- 4. stitch -----------------------------------------------------------------------------

def _line_end(m, last):
    pts = pts_of(m["p"])
    if last:
        return pts[-1], unit(pts[-2], pts[-1])
    return pts[0], unit(pts[1], pts[0])


def jogs(marks):
    """[(i, last_i, j, last_j, along, side)]: line ends with a start of their kind just ahead."""
    grid = Grid(16.0)
    ends = []
    for i, m in enumerate(marks):
        if m["k"] not in LINE_KINDS or len(m["p"]) < 4:
            continue
        for last in (False, True):
            p, d = _line_end(m, last)
            if d is None:
                continue
            ends.append((i, last, p, d))
            grid.add(len(ends) - 1, p[0], p[1])
    found = []
    for e, (i, last, p, d) in enumerate(ends):
        if not last:
            continue  # pair each outgoing end (a line's last point) with an incoming one
        best = None
        for f in grid.near(p[0], p[1], STITCH_GAP + STITCH_SIDE):
            j, lj, q, dq = ends[f]
            if j == i or marks[j]["k"] != marks[i]["k"] or marks[j].get("dk", -1) != marks[i].get("dk", -1):
                continue
            # q's outward direction points back at p: its line carries on along d
            if -(dq[0] * d[0] + dq[1] * d[1]) < STITCH_COS:
                continue
            dx, dz = q[0] - p[0], q[1] - p[1]
            along = dx * d[0] + dz * d[1]
            side = dx * -d[1] + dz * d[0]
            if not (-STITCH_BACK <= along <= STITCH_GAP) or abs(side) > STITCH_SIDE:
                continue
            if marks[j]["k"] in ("cyclefill",) and abs(float(marks[j].get("w", 0)) - float(marks[i].get("w", 0))) > 0.3:
                continue
            key = (abs(side), abs(along))
            if best is None or key < best[0]:
                best = (key, j, lj, along, side)
        if best is not None:
            found.append((i, last, best[1], best[2], best[3], best[4]))
    return found


def stitch(marks):
    """Joins every line with the one carrying it on; returns how many joins."""
    pairs = jogs(marks)
    # one partner per end, the smallest jump first
    pairs.sort(key=lambda x: (abs(x[5]), abs(x[4])))
    taken = set()
    nxt = {}
    for i, li, j, lj, along, side in pairs:
        if (i, li) in taken or (j, lj) in taken:
            continue
        taken.add((i, li))
        taken.add((j, lj))
        nxt[i] = (j, lj)
    has_prev = {j for j, _ in nxt.values()}
    dead = set()
    joined = 0
    for i in sorted(nxt):
        if i in has_prev or i in dead:
            continue
        chain = pts_of(marks[i]["p"])
        cur = i
        seen = {i}
        while cur in nxt:
            j, lj = nxt[cur]
            if j in seen:
                break
            seen.add(j)
            q = pts_of(marks[j]["p"])
            if lj:   # its incoming end is its last point: walk it backwards
                q = q[::-1]
            chain = blend(chain, q)
            dead.add(j)
            joined += 1
            cur = j
        marks[i]["p"] = flat_of(chain)
    # lines in a loop (every one has a predecessor) stay as they are
    for j in sorted(dead, reverse=True):
        del marks[j]
    return joined


def blend(a, b):
    """a then b, with one S-curve between them (a's end to b's start), shifting both."""
    pe = a[-1]
    d = unit(a[-2], a[-1]) or (1.0, 0.0)
    n = (-d[1], d[0])
    q = b[0]
    side = (q[0] - pe[0]) * n[0] + (q[1] - pe[1]) * n[1]
    L = taper_len(abs(side))
    la, lb = length(a), length(b)
    ha = min(L * 0.5, la * 0.5)
    hb = min(L * 0.5, lb * 0.5)
    if abs(side) < 0.05 or ha + hb < 1.0:
        return a + b[1:] if math.dist(pe, q) < 0.05 else a + b
    A = resample_between(a, la - ha, la, 1.0)
    B = resample_between(b, 0.0, hb, 1.0)
    ca, cb = cumulative(A), cumulative(B)
    out = []
    for p, s in zip(A, ca):
        u = la - s
        if u < ha:
            f = smooth((ha - u) / (ha + hb))
            p = (p[0] + n[0] * side * f, p[1] + n[1] * side * f)
        out.append(p)
    for k, (p, s) in enumerate(zip(B, cb)):
        if s < hb:
            f = smooth((ha + s) / (ha + hb))
            p = (p[0] - n[0] * side * (1.0 - f), p[1] - n[1] * side * (1.0 - f))
        if k == 0 and math.dist(p, out[-1]) < 0.3:
            continue
        out.append(p)
    return simplify(out, 0.02)


# --- 5. kinks ------------------------------------------------------------------------------

def turn_deg(a, b, c):
    u, v = unit(a, b), unit(b, c)
    if u is None or v is None:
        return 0.0
    return abs(math.degrees(math.atan2(u[0] * v[1] - u[1] * v[0], u[0] * v[0] + u[1] * v[1])))


def round_line(pts):
    if len(pts) < 3:
        return pts, 0
    out = [pts[0]]
    n = 0
    for k in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[k], pts[k + 1]
        ang = turn_deg(a, b, c)
        if not (ROUND_MIN <= ang <= ROUND_MAX):
            out.append(b)
            continue
        cut = min(ROUND_CUT, math.dist(a, b) * 0.45, math.dist(b, c) * 0.45)
        if cut < 0.3:
            out.append(b)
            continue
        u, v = unit(b, a), unit(b, c)
        p0 = (b[0] + u[0] * cut, b[1] + u[1] * cut)
        p1 = (b[0] + v[0] * cut, b[1] + v[1] * cut)
        m = max(2, int(math.ceil(ang / ROUND_SEG)))
        for q in range(m + 1):
            t = q / m
            x = (1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * b[0] + t * t * p1[0]
            z = (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * b[1] + t * t * p1[1]
            out.append((x, z))
        n += 1
    out.append(pts[-1])
    return out, n


# --- measuring -----------------------------------------------------------------------------

def drawn_edges(r, last):
    """The drawn edges at a road's end in its away frame (with `wv`/`cv` if it has them)."""
    p = r["p"]
    if "wv" in r:
        k = len(r["wv"]) - 1 if last else 0
        c, hw = float(r["cv"][k]), float(r["wv"][k]) * 0.5
    else:
        c, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
    if last:
        return -(c + hw), -(c - hw)
    return c - hw, c + hw


def edge_steps(roads, near=None, every=None):
    """Joins of one chain whose drawn edge still steps more than STEP_MIN m: [(node, step)]
    (not on a side where another road leaves the node: its mouth meets the step there; `every`:
    the whole road list to find those roads in, when `roads` is a part of it)."""
    ends = defaultdict(list)
    legs = defaultdict(list)   # node -> [(road, direction away)] of every road through it
    for r in (roads if every is None else every):
        p = r["p"]
        m = len(p) // 2
        for k in range(m):
            key = (round(p[2 * k], 1), round(p[2 * k + 1], 1))
            for nb in ((k - 1,) if k == m - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                d = unit((p[2 * k], p[2 * k + 1]), (p[2 * nb], p[2 * nb + 1]))
                if d is not None:
                    legs[key].append((id(r), d))
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, _, _ = _end(r, i, last)
            if away is None or (near is not None and not near(node)):
                continue
            ends[(round(node[0], 1), round(node[1], 1))].append((i, last, node, away))
    out = []
    for key, lst in ends.items():
        best = None
        for x in range(len(lst)):
            for y in range(x + 1, len(lst)):
                ia, la_, na, aa = lst[x]
                ib, lb_, nb, ab = lst[y]
                A, B = roads[ia], roads[ib]
                if ia == ib or (A.get("name") or "") != (B.get("name") or "") or bool(A.get("oneway")) != bool(B.get("oneway")):
                    continue
                if int(A.get("dk", -1)) != int(B.get("dk", -1)) or aa[0] * ab[0] + aa[1] * ab[1] > -CHAIN_COS:
                    continue
                l1, r1 = drawn_edges(A, la_)
                l2, r2 = drawn_edges(B, lb_)
                nrm = (-aa[1], aa[0])
                side = {1 if d[0] * nrm[0] + d[1] * nrm[1] > 0 else 0 for j, d in legs[key] if j not in (id(A), id(B))}
                if max(abs(l1 + r2), abs(r1 + l2)) > STEP_MAX:
                    continue   # a different road shape (a bay, a slip), as find_joins
                step = max([abs(l1 + r2)] * (0 not in side) + [abs(r1 + l2)] * (1 not in side) + [0.0])
                if best is None or step < best[1]:
                    best = (na, step)
        if best is not None and STEP_MIN < best[1] <= STEP_MAX:
            out.append(best)
    return out


def measure(d):
    return {"steps": len(edge_steps(d["roads"])),
            "jogs": len([j for j in jogs(d["markings"]) if abs(j[5]) > STEP_MIN])}


def apply(out):
    """Smooths the finished map data in place; returns a one-line summary."""
    if int(out.get("road_smooth", 0)) >= VERSION:
        return "already smoothed"
    if out.get("road_smooth"):
        raise SystemExit("road_smooth: the map was smoothed by an older version; take the unsmoothed "
                         "map (the other side's centrum.json, or a re-bake) and run this again")
    before = measure(out)
    beds, bed_sides = fit_rail_beds(out)
    chain_ways, chain_sides = fit_chain_widths(out)
    joins = find_joins(out["roads"])
    index_nodes(out["roads"])
    ends = []
    tapers = taper_roads(out["roads"], joins, ends)
    km = snap_lines(out.get("kerbs", []), tapers, lambda k: pts_of(k["p"]), lambda k, p: k.__setitem__("p", flat_of(p)))
    fit = fit_kerbs(out["roads"], tapers, ends, out.get("kerbs", []))
    bridged = bridge_rail_kerbs(out, out.get("kerbs", []))
    edge_idx = [k for k, m in enumerate(out["markings"]) if m["k"] == "edge"]
    edge_lines = [out["markings"][k] for k in edge_idx]
    before_n = len(edge_lines)
    bridged += bridge_rail_kerbs(out, edge_lines, reach=1.0)
    if len(edge_lines) != before_n:   # drop the edge lines that were joined onto others
        alive = {id(m) for m in edge_lines}
        out["markings"] = [m for k, m in enumerate(out["markings"]) if m["k"] != "edge" or id(m) in alive]
    edges = [m for m in out.get("markings", []) if m["k"] in ("edge",)]
    em = snap_lines(edges, tapers, lambda m: pts_of(m["p"]), lambda m, p: m.__setitem__("p", flat_of(p)))
    joined = stitch(out["markings"])
    rounded = 0
    for m in out["markings"]:
        if m["k"] in ROUND_KINDS:
            p, n = round_line(pts_of(m["p"]))
            if n:
                m["p"] = flat_of(p)
                rounded += n
    after = measure(out)
    out["road_smooth"] = VERSION
    return (f"{beds} ways ({bed_sides} sides) widened onto the tram bed, {chain_ways} ways ({chain_sides} sides) "
            f"widened to their street's kerbs, {len(tapers)} joins tapered, {km} kerb and {em} edge-line points moved, {fit} edges fitted to "
            f"their kerbs, {bridged} kerb breaks by a tram bed closed, {joined} lines "
            f"stitched, {rounded} line kinks rounded; edge steps {before['steps']} -> {after['steps']}, "
            f"line jogs {before['jogs']} -> {after['jogs']}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    path = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    if "--check" in sys.argv:
        m = measure(d)
        ok = bool(d.get("road_smooth")) and m["steps"] <= CHECK_STEPS and m["jogs"] <= CHECK_JOGS
        why = "" if d.get("road_smooth") else " (the map was never smoothed: run tools/road_smooth.py)"
        print(f"road_smooth: {'OK' if ok else 'FAIL'}: edge steps {m['steps']} (max {CHECK_STEPS}), "
              f"line jogs {m['jogs']} (max {CHECK_JOGS}){why}")
        return 0 if ok else 1
    if "--report" in sys.argv or "--dry" in sys.argv:
        m = measure(d)
        print(f"road_smooth: {path}: edge steps {m['steps']}, line jogs {m['jogs']}, "
              f"smoothed {'yes' if d.get('road_smooth') else 'no'}")
        if "--dry" in sys.argv:
            return 0
    if "--dry" not in sys.argv:
        print("road_smooth: " + apply(d))
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(d, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
