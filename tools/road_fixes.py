"""Main's real road bugs (F, 2026-11-07: "main as base, small fixes"), fixed once for the whole map
on the finished map data, after tools/road_smooth.py. Nothing is redesigned: main's medians, islands,
arrows, cycle paths and lanes stay; only paint that is in the wrong place moves or goes.

    python3 -I tools/road_fixes.py [MAP.json] [--dry]
        fixes the map in place (idempotent: a map already fixed is left alone); --dry measures only.
    python3 -I tools/road_fixes.py --check [MAP.json]
        exit 1 unless the map is fixed and what is left is at most the CHECK_* ratchets (verify.sh
        step `fixes`; lower them when a change leaves fewer, never raise them).

The bugs (seen on the GUGiK photo against main at Marszałkowska x Królewska, Świętokrzyska x
Mazowiecka and x Jasna, docs/BACKLOG.md "Main's real bugs"), and what this does about each:

1. Lane lines through the junction (the photo: lines end at the stop line or the zebra, the box is
   bare). bake_roads cuts a street's lines only where another street's ribbon crosses them, so the
   strip between a junction's zebra (or stop line) and the junction kept its lane lines, and lines
   stitched or moved by road_smooth ran on into the box. Cut here: every lane, centre, solid and bus
   line, running along the street, between a zebra or stop line and the junction it guards (the
   "mouth": out to the last junction node of that crossing within MOUTH_REACH), and on another main
   street's ribbon crossing it (the box). A roundabout's own ring keeps its lines.
2. Turn arrows past the zebra (painted in the mouth, even on the stripes): an arrow there pointing
   into the junction goes back behind the zebra and the stop line in front of it (ARROW_BACK), or,
   where its lane already has an arrow there or there is no asphalt, is dropped.
3. Zebras that cover one carriageway of a dual one (the photo: kerb to median, then median to kerb):
   where a zebra ends at a median, island or tram bed at most PARTNER_GAP wide and the same street's
   other carriageway on its line has no zebra, that carriageway gets its piece, kerb to median. Ends
   still short of the kerb run on to it (as road_smooth.extend_zebras, with the same tests), and
   zebras under 1 m long (dots left by the asphalt clip, drawn as nothing) go.
4. Cycle crossings that are short red bars over part of the road (the photo: one band across the
   street beside the zebra): a cycle crossing beside a zebra runs on along its line over the asphalt
   as far as that zebra reaches, and a free end left in the middle of the asphalt runs on to the kerb.

The dark patches in junction boxes (bug 5 in BACKLOG) are not in the game: every ribbon, area and
fill is one opaque colour at one height. They came from the flat comparison pictures, which draw the
ribbons half transparent over the photo, so two overlapping ribbons look darker there.

Deterministic, standard library only. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import road_smooth as RS  # noqa: E402  (the asphalt tests, the tram beds, the polyline helpers)

VERSION = 1
# --check ratchets (2026-11-07, the whole map after the first pass). Lower them, never raise them.
CHECK_MOUTH_M = 5      # m of lane, centre, solid or bus line left in a junction's mouth
CHECK_BOX_M = 0        # m of such lines left on another main street's ribbon
CHECK_ARROWS = 0       # arrows left in a mouth pointing into the junction
CHECK_PARTNERS = 0     # dual carriageways crossed on one side only
CHECK_DOTS = 0         # zebras under 1 m
CHECK_SHORT_CYCLE = 1  # cycle crossings beside a zebra that stop short of it

MINOR = {"service", "living_street"}
MAIN = {"motorway", "trunk", "primary", "secondary", "tertiary",
        "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"}
CUT_KINDS = ("lane", "centre", "solid", "bus")
ZEBRA_HALF = 1.8      # m: map_builder paints a zebra's stripes 3.6 m wide
ZEBRA_GAP = 0.6       # m: lines stop this far short of the stripes (bake_roads ZEBRA_GAP)
STOP_GAP = 0.3        # m: and this far past a stop line
MOUTH_REACH = 30.0    # m from a zebra or stop line to the junction node it guards...
MOUTH_GAP = 12.0      # ...with at most this much road between its far edge and the crossing street's
                      # ribbon (a crossing further out is mid-block: the lines carry on to the junction)...
MOUTH_GAP_SIGNAL = 20.0  # ...or this much at a signalised crossing (a stop line and a zebra together)
T_SLACK = 10.0        # m: a junction node this far past either end of a crossing still lies ahead of it
PAIR_REACH = 10.0     # m: a stop line and a zebra this near, parallel and side by side, are one crossing
NODE_STEP = 22.0      # m: the next junction node of the same crossing (a dual carriageway's other half)
ALONG_COS = 0.7       # a line runs along the street (cut in a mouth) when this parallel to its axis
CROSS_COS = 0.9       # another street's ribbon crosses a line when less parallel than this
BOX_INSET = 0.3       # m inside that ribbon's edge before a line is cut
LINE_STEP = 0.25      # m between samples along a line
LINE_MIN = 2.0        # m: a shorter piece left by a cut is dropped
CUT_MIN = 3.0         # m: a shorter cut in the middle of a line is not made
ARROW_BACK = 6.0      # m behind the zebra's (or stop line's) far edge an arrow is moved to
ARROW_LANE = 1.2      # m aside: the same lane
ARROW_NEAR = 8.0      # m: an arrow of that lane this close to the target already marks it
PARTNER_GAP = 8.0     # m: a median, island or tram bed this wide or less between two carriageways
PARTNER_RUN = 2.0     # m: the far carriageway at least this wide on the zebra's line
PARTNER_SEEN = 4.0    # m: a zebra this close to the far carriageway's middle already crosses it
EDGE_KEEP = 0.3       # m a zebra or cycle crossing stops short of the asphalt's edge
RUN_ON = 8.0          # m an end may run on to reach the kerb
CYCLE_BESIDE = 4.5    # m: a cycle crossing this far from a zebra's line, parallel, is beside it
CYCLE_COS = 0.94
SHORT_LEFT = 1.5      # m: a cycle crossing still this much shorter than its zebra (on no asphalt) is short
CYCLE_LINK = 1.0      # m: a cycle crossing's end this close to another's or a cycle path's is not free


def _ground(item):
    return int(item.get("dk", -1)) < 0


def _unit(a, b):
    return RS.unit(a, b)


def _chord(p):
    q = RS.pts_of(p["p"])
    return q[0], q[-1]


class Ribbons:
    """The ground's main and minor street ribbons as capsules (the drawn width, `c`/`cv` offsets),
    with each piece's road index and direction, on a 16 m grid."""

    def __init__(self, out, keep):
        self.grid = defaultdict(list)
        for ri, r in enumerate(out["roads"]):
            if not _ground(r) or not keep(r):
                continue
            q = RS.pts_of(r["p"])
            wv, cv = r.get("wv"), r.get("cv")
            for i in range(len(q) - 1):
                a, b = q[i], q[i + 1]
                u = _unit(a, b)
                if u is None:
                    continue
                w = min(wv[i], wv[i + 1]) if wv else r["w"]
                c = (cv[i] + cv[i + 1]) / 2 if cv else r.get("c", 0.0)
                nx, nz = -u[1], u[0]
                a2 = (a[0] + nx * c, a[1] + nz * c)
                b2 = (b[0] + nx * c, b[1] + nz * c)
                piece = (a2, b2, w / 2, ri, u)
                for cx in range(int(math.floor((min(a2[0], b2[0]) - w) / 16)), int(math.floor((max(a2[0], b2[0]) + w) / 16)) + 1):
                    for cz in range(int(math.floor((min(a2[1], b2[1]) - w) / 16)), int(math.floor((max(a2[1], b2[1]) + w) / 16)) + 1):
                        self.grid[(cx, cz)].append(piece)

    def at(self, x, z, inset=0.0):
        """The pieces whose ribbon holds (x, z), at least `inset` inside the edge."""
        out = []
        for a, b, hw, ri, u in self.grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()):
            if RS.seg_dist((x, z), a, b) < hw - inset:
                out.append((a, b, hw, ri, u))
        return out


def junction_nodes(out):
    """Junction nodes: points where ground streets (not service roads) of at least two names meet,
    or three or more ends and passes of them. {(x, z): set of road indices}."""
    at = defaultdict(list)
    for ri, r in enumerate(out["roads"]):
        if not _ground(r) or r["k"] in MINOR:
            continue
        p = RS.pts_of(r["p"])
        for j, (x, z) in enumerate(p):
            at[(round(x, 1), round(z, 1))].append((ri, 1 if j in (0, len(p) - 1) else 2))
    nodes = {}
    for key, refs in at.items():
        names = {out["roads"][ri]["name"] for ri, _ in refs if out["roads"][ri]["name"]}
        degree = sum(n for _, n in refs)
        if len(names) >= 2 or degree >= 3:
            nodes[key] = {ri for ri, _ in refs}
    return nodes


def _rondo(out, ri):
    return out["roads"][ri]["name"].startswith("Rondo")


def mouths(out, nodes, ribbons):
    """Every zebra's and stop line's mouth: (a, b, n, d0, d1, t0, t1, kind) where a->b is its chord,
    n the unit normal towards the junction, the mouth the points P with t = (P-a).u in [t0, t1] and
    d = (P-a).n in (d0, d1]."""
    node_grid = defaultdict(list)
    for key in nodes:
        node_grid[(int(key[0] // 40), int(key[1] // 40))].append(key)

    def near_nodes(x, z, r):
        cx, cz = int(x // 40), int(z // 40)
        k = int(r // 40) + 1
        for i in range(cx - k, cx + k + 1):
            for j in range(cz - k, cz + k + 1):
                for key in node_grid.get((i, j), ()):
                    if math.dist(key, (x, z)) <= r:
                        yield key

    crossings = []
    for p in out.get("paths", []):
        if p["k"] == "zebra" and _ground(p):
            crossings.append((_chord(p), ZEBRA_HALF + ZEBRA_GAP, "zebra"))
    for m in out.get("markings", []):
        if m["k"] == "stop" and _ground(m):
            crossings.append((_chord(m), STOP_GAP, "stop"))
    # A signalised crossing's stop line stands before its zebra: the junction is on the zebra's
    # side of the stop line, and on the side of the zebra away from the stop line.
    cgrid = defaultdict(list)
    for k, ((a, b), half, kind) in enumerate(crossings):
        cgrid[(int(((a[0] + b[0]) / 2) // 20), int(((a[1] + b[1]) / 2) // 20))].append(k)

    def facing(k, a, b, u, n0, kind):
        """+1 / -1: the junction lies along +n0 / -n0 (a stop line and its zebra say so); 0: unknown."""
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        L = math.dist(a, b)
        vote = 0.0
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for o in cgrid.get((int(mid[0] // 20) + i, int(mid[1] // 20) + j), ()):
                    (oa, ob), _, okind = crossings[o]
                    if okind == kind:
                        continue
                    ol = math.dist(oa, ob)
                    if ol < 1.0:
                        continue
                    ou = ((ob[0] - oa[0]) / ol, (ob[1] - oa[1]) / ol)
                    if abs(ou[0] * u[0] + ou[1] * u[1]) < 0.9:
                        continue
                    om = ((oa[0] + ob[0]) / 2, (oa[1] + ob[1]) / 2)
                    off = (om[0] - a[0]) * n0[0] + (om[1] - a[1]) * n0[1]
                    t = (om[0] - a[0]) * u[0] + (om[1] - a[1]) * u[1]
                    if not 0.5 <= abs(off) <= PAIR_REACH or t < -1.0 or t > L + 1.0:
                        continue
                    # a stop line votes for the zebra's side; a zebra for the side away from its stop line
                    vote += math.copysign(1.0, off) * (1.0 if kind == "stop" else -1.0)
        return 0 if vote == 0 else (1 if vote > 0 else -1)

    found = []
    for k, ((a, b), half, kind) in enumerate(crossings):
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        n0 = (-u[1], u[0])
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        # the street it crosses: the ribbons under its middle running across it
        under = [pc for pc in ribbons.at(*mid) if abs(pc[4][0] * u[0] + pc[4][1] * u[1]) < 0.6
                 and out["roads"][pc[3]]["k"] not in MINOR]
        if not under:
            continue
        roads = {pc[3] for pc in under}
        if any(_rondo(out, ri) for ri in roads):
            continue
        # (by name: the way under a crossing often ends at a join short of the junction)
        rnames = {out["roads"][ri]["name"] for ri in roads}
        side = facing(k, a, b, u, n0, kind)
        gap_max = MOUTH_GAP_SIGNAL if side else MOUTH_GAP
        # the junction it guards: the nearest node on that street ahead of it (on its side, if known)
        best = None
        for key in near_nodes(mid[0], mid[1], MOUTH_REACH):
            if not (nodes[key] & roads or rnames & {out["roads"][ri]["name"] for ri in nodes[key]} - {""}):
                continue
            d = (key[0] - a[0]) * n0[0] + (key[1] - a[1]) * n0[1]
            t = (key[0] - a[0]) * u[0] + (key[1] - a[1]) * u[1]
            if abs(d) <= half or t < -T_SLACK or t > L + T_SLACK or d * side < 0:
                continue
            others = [out["roads"][ri] for ri in nodes[key] if ri not in roads and out["roads"][ri]["name"] not in rnames]
            box = max((r["w"] * 0.5 + abs(r.get("c", 0.0)) for r in others), default=0.0)
            if abs(d) - box - half > gap_max:
                continue
            if best is None or abs(d) < abs(best[0]):
                best = (d, key)
        if best is None:
            continue
        sg = 1.0 if best[0] > 0 else -1.0
        n = (n0[0] * sg, n0[1] * sg)
        # out to the last node of the same crossing (a dual carriageway's other half)
        names = {out["roads"][ri]["name"] for ri in nodes[best[1]] if ri not in roads} - rnames - {""}
        reach = abs(best[0])
        last = best[1]
        while True:
            nxt = None
            for key in near_nodes(last[0], last[1], NODE_STEP):
                d = (key[0] - a[0]) * n[0] + (key[1] - a[1]) * n[1]
                t = (key[0] - a[0]) * u[0] + (key[1] - a[1]) * u[1]
                if d <= reach + 0.5 or d > MOUTH_REACH + NODE_STEP or t < -T_SLACK or t > L + T_SLACK:
                    continue
                if not names & {out["roads"][ri]["name"] for ri in nodes[key]}:
                    continue
                if nxt is None or d < nxt[0]:
                    nxt = (d, key)
            if nxt is None:
                break
            reach, last = nxt
        found.append((a, b, n, half, reach, -0.5, L + 0.5, kind))
    return found


class MouthIndex:
    def __init__(self, ms):
        self.ms = ms
        self.grid = defaultdict(list)
        for k, (a, b, n, d0, d1, t0, t1, kind) in enumerate(ms):
            xs = [a[0], b[0], a[0] + n[0] * d1, b[0] + n[0] * d1]
            zs = [a[1], b[1], a[1] + n[1] * d1, b[1] + n[1] * d1]
            for cx in range(int(math.floor((min(xs) - 1) / 16)), int(math.floor((max(xs) + 1) / 16)) + 1):
                for cz in range(int(math.floor((min(zs) - 1) / 16)), int(math.floor((max(zs) + 1) / 16)) + 1):
                    self.grid[(cx, cz)].append(k)

    def hit(self, x, z, along=None, d_from=None):
        """The mouth holding (x, z) (and, given `along`, whose street that direction runs along), or None.
        d_from overrides d0 (an arrow on the stripes counts too)."""
        for k in self.grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()):
            a, b, n, d0, d1, t0, t1, kind = self.ms[k]
            L = math.dist(a, b)
            u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
            t = (x - a[0]) * u[0] + (z - a[1]) * u[1]
            d = (x - a[0]) * n[0] + (z - a[1]) * n[1]
            lo = d0 if d_from is None else d_from
            if t0 <= t <= t1 and lo < d <= d1:
                if along is not None and abs(along[0] * n[0] + along[1] * n[1]) < ALONG_COS:
                    continue
                return k
        return None


def in_box(out, main_ribbons, x, z, d):
    """On another main street's ribbon crossing direction d (not a roundabout's ring, not a way of
    the line's own street: two ways of one street meeting at an angle are a merge, not a junction)."""
    hits = main_ribbons.at(x, z, BOX_INSET)
    if not hits or any(_rondo(out, h[3]) for h in hits):
        return False
    own = {out["roads"][h[3]]["name"] for h in main_ribbons.at(x, z) if abs(h[4][0] * d[0] + h[4][1] * d[1]) >= CROSS_COS}
    for a, b, hw, ri, u in hits:
        name = out["roads"][ri]["name"]
        if abs(u[0] * d[0] + u[1] * d[1]) < CROSS_COS and name and own and name not in own:
            return True
    return False


def cut_lines(out, mi, main_ribbons, dry=False):
    """Cuts lane, centre, solid and bus lines out of mouths and boxes. Returns (m in mouths, m in boxes)."""
    kept = []
    cut = {}
    m_mouth = m_box = 0.0
    for m in out["markings"]:
        if m["k"] not in CUT_KINDS or not _ground(m):
            kept.append(m)
            continue
        pts = RS.pts_of(m["p"])
        if len(pts) < 2:
            kept.append(m)
            continue
        flags = []
        dense = []
        for a, b in zip(pts, pts[1:]):
            u = _unit(a, b)
            L = math.dist(a, b)
            if u is None:
                continue
            k = max(1, int(math.ceil(L / LINE_STEP)))
            for i in range(k):
                x, z = a[0] + (b[0] - a[0]) * i / k, a[1] + (b[1] - a[1]) * i / k
                dense.append((x, z))
                if mi.hit(x, z, u) is not None:
                    flags.append("m")
                    m_mouth += L / k
                elif in_box(out, main_ribbons, x, z, u):
                    flags.append("b")
                    m_box += L / k
                else:
                    flags.append("")
        if not dense:
            kept.append(m)
            continue
        dense.append(pts[-1])
        flags.append(flags[-1])
        # a short flagged stretch with paint on both sides is a line grazing a mouth's or a box's
        # corner: cutting it would only break the line (road_smooth's line jogs)
        i = 0
        while i < len(flags):
            if not flags[i]:
                i += 1
                continue
            j = i
            while j < len(flags) and flags[j]:
                j += 1
            if i > 0 and j < len(flags) and (j - i) * LINE_STEP < CUT_MIN:
                for k in range(i, j):
                    if flags[k] == "m":
                        m_mouth -= LINE_STEP
                    else:
                        m_box -= LINE_STEP
                    flags[k] = ""
            i = j
        if dry or not any(flags):
            kept.append(m)
            continue
        run = []
        cut[id(m)] = (m, [])
        for p, f in zip(dense, flags):
            if f:
                if len(run) >= 2 and RS.length(run) >= LINE_MIN:
                    kept.append(dict(m, p=RS.flat_of(RS.simplify(run, 0.002))))
                    cut[id(m)][1].append(kept[-1])
                run = []
            else:
                run.append(p)
        if len(run) >= 2 and RS.length(run) >= LINE_MIN:
            kept.append(dict(m, p=RS.flat_of(RS.simplify(run, 0.002))))
            cut[id(m)][1].append(kept[-1])
    if dry:
        return round(m_mouth), round(m_box)
    # A cut end that now reads as a line jog (another lane's line starting just aside: road_smooth's
    # K2 check) means the line was a turn's guide stitched to its neighbour: that line stays whole.
    before = _jog_ends(out["markings"])
    piece_of = {id(q): orig for orig, pieces in cut.values() for q in pieces}
    cut_ends = defaultdict(list)
    for orig, pieces in cut.values():
        for last in (False, True):
            p, _ = RS._line_end(orig, last)
            cut_ends[(round(p[0]), round(p[1]))].append((p, orig))
    restore = set()
    for i, last, j, lj, along, side in RS.jogs(kept):
        if abs(side) <= RS.STEP_MIN:
            continue
        for k, end in ((i, last), (j, lj)):
            if _end_key(kept[k], end) in before:
                continue
            orig = piece_of.get(id(kept[k]))
            if orig is not None:
                restore.add(id(orig))
            # ...and the line it carried on into, if the cut took it
            p, _ = RS._line_end(kept[k], end)
            for dx in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for q, o in cut_ends.get((round(p[0]) + dx, round(p[1]) + dz), ()):
                        if math.dist(p, q) < 0.5:
                            restore.add(id(o))
    if restore:
        keep2 = []
        for q in kept:
            orig = piece_of.get(id(q))
            if orig is not None and id(orig) in restore:
                if q is cut[id(orig)][1][0]:
                    keep2.append(orig)
                    length = RS.length(RS.pts_of(orig["p"])) - sum(RS.length(RS.pts_of(x["p"])) for x in cut[id(orig)][1])
                    m_mouth -= max(0.0, length)
                continue
            keep2.append(q)
        # a restored line whose every piece was too short to keep
        for oid in restore - {id(piece_of[id(q)]) for q in kept if id(q) in piece_of}:
            keep2.append(cut[oid][0])
        kept = keep2
    out["markings"] = kept
    return round(m_mouth), round(m_box)


def _end_key(m, last):
    p, _ = RS._line_end(m, last)
    return (m["k"], round(p[0], 1), round(p[1], 1))


def _jog_ends(marks):
    """The line ends road_smooth already counts as jogs (they stay as they are)."""
    out = set()
    for i, last, j, lj, along, side in RS.jogs(marks):
        if abs(side) <= RS.STEP_MIN:
            continue
        out.add(_end_key(marks[i], last))
        out.add(_end_key(marks[j], lj))
    return out


def move_arrows(out, mi, asphalt, dry=False):
    """Arrows in a mouth (or on its stripes) pointing into the junction go back behind the zebra or
    stop line, or are dropped. Returns (moved, dropped, left)."""
    syms = out.get("symbols", [])
    arrows = [s for s in syms if s["k"] == "arrow" and _ground(s)]
    moved = dropped = 0
    drop = set()
    for s in arrows:
        k = mi.hit(s["x"], s["z"], d_from=-ZEBRA_HALF - 0.5)
        if k is None:
            continue
        a, b, n, d0, d1, t0, t1, kind = mi.ms[k]
        dx, dz = s["d"]
        cosn = dx * n[0] + dz * n[1]
        if cosn < 0.5:
            continue
        d = (s["x"] - a[0]) * n[0] + (s["z"] - a[1]) * n[1]
        back = (d + d0 + ARROW_BACK) / cosn
        tx, tz = s["x"] - dx * back, s["z"] - dz * back
        # behind the stop line too, where it stands further back than the zebra's mouth reaches
        for _ in range(3):
            k2 = mi.hit(tx, tz, d_from=-ZEBRA_HALF - 0.5)
            if k2 is None:
                break
            a2, b2, n2, d02, d12, t02, t12, kind2 = mi.ms[k2]
            c2 = dx * n2[0] + dz * n2[1]
            if c2 < 0.5:
                break
            back2 = ((tx - a2[0]) * n2[0] + (tz - a2[1]) * n2[1] + d02 + ARROW_BACK) / c2
            tx, tz = tx - dx * back2, tz - dz * back2
        if dry:
            moved += 1
            continue
        lane = any(o is not s and id(o) not in drop and o["d"][0] * dx + o["d"][1] * dz > 0.9
                   and abs((o["x"] - tx) * -dz + (o["z"] - tz) * dx) < ARROW_LANE
                   and abs((o["x"] - tx) * dx + (o["z"] - tz) * dz) < ARROW_NEAR for o in arrows)
        if lane or not asphalt(tx, tz) or mi.hit(tx, tz, d_from=-ZEBRA_HALF - 0.5) is not None:
            drop.add(id(s))
            dropped += 1
            continue
        s["x"], s["z"] = round(tx, 2), round(tz, 2)
        moved += 1
    if drop:
        out["symbols"] = [s for s in syms if id(s) not in drop]
    return moved, dropped


def _run_from(test, x, z, ux, uz, limit, step=0.25):
    """How far from (x, z) along (ux, uz) test() holds (sampled every step), at most limit."""
    t = 0.0
    while t < limit and test(x + ux * (t + step), z + uz * (t + step)):
        t += step
    return t


def fix_zebras(out, asphalt, raised, on_bed, ribbons, dry=False):
    """Drops dot zebras, runs short ends on to the kerb, adds the other carriageway's piece.
    Returns (dots, metres run on, pieces added)."""
    paths = out["paths"]
    road = lambda x, z: asphalt(x, z) and not raised(x, z)  # noqa: E731
    dots = [p for p in paths if p["k"] == "zebra" and RS.length(RS.pts_of(p["p"])) < 1.0]
    if not dry:
        out["paths"] = paths = [p for p in paths if not (p["k"] == "zebra" and RS.length(RS.pts_of(p["p"])) < 1.0)]
    zebras = [p for p in paths if p["k"] == "zebra" and _ground(p)]
    run_on = 0.0
    for p in zebras:
        q = RS.pts_of(p["p"])
        for end, prev in ((len(q) - 1, len(q) - 2), (0, 1)):
            u = _unit(q[prev], q[end])
            if u is None:
                continue
            t = _run_from(road, q[end][0], q[end][1], u[0], u[1], RUN_ON)
            if t - EDGE_KEEP >= 0.5 and RS._in_map(out, q[end][0] + u[0] * t, q[end][1] + u[1] * t):
                run_on += t - EDGE_KEEP
                q[end] = (q[end][0] + u[0] * (t - EDGE_KEEP), q[end][1] + u[1] * (t - EDGE_KEEP))
        if not dry:
            p["p"] = RS.flat_of(q)
    # the other carriageway
    segs = [_chord(p) for p in zebras]
    grid = defaultdict(list)
    for k, (a, b) in enumerate(segs):
        for cx in range(int(math.floor(min(a[0], b[0]) / 16)) - 1, int(math.floor(max(a[0], b[0]) / 16)) + 2):
            for cz in range(int(math.floor(min(a[1], b[1]) / 16)) - 1, int(math.floor(max(a[1], b[1]) / 16)) + 2):
                grid[(cx, cz)].append(k)

    def crossed(x, z):
        return any(RS.seg_dist((x, z), *segs[k]) < PARTNER_SEEN for k in grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()))

    def names(x, z):
        return {out["roads"][h[3]]["name"] for h in ribbons.at(x, z) if out["roads"][h[3]]["k"] not in MINOR} - {""}

    added = []
    for p, (a, b) in zip(zebras, segs):
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        mine = names((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        if not mine:
            continue
        for e, s in ((b, 1.0), (a, -1.0)):
            ux, uz = u[0] * s, u[1] * s
            # across a median, island or tram bed: never across bare pavement or a building
            t = EDGE_KEEP
            ok = True
            while t < PARTNER_GAP + EDGE_KEEP and not road(e[0] + ux * t, e[1] + uz * t):
                x, z = e[0] + ux * t, e[1] + uz * t
                if not (raised(x, z) or on_bed(x, z)):
                    ok = False
                    break
                t += 0.25
            if not ok or t >= PARTNER_GAP + EDGE_KEEP or t < 0.5:
                continue
            g = t
            t = g + _run_from(road, e[0] + ux * g, e[1] + uz * g, ux, uz, 30.0)
            if t - g < PARTNER_RUN:
                continue
            s0, s1 = g + EDGE_KEEP, t - EDGE_KEEP
            mid = (e[0] + ux * (s0 + s1) / 2, e[1] + uz * (s0 + s1) / 2)
            if not (mine & names(*mid)) or crossed(*mid):
                continue
            pa = (e[0] + ux * s0, e[1] + uz * s0)
            pb = (e[0] + ux * s1, e[1] + uz * s1)
            if not (RS._in_map(out, *pa) and RS._in_map(out, *pb)):
                continue
            piece = {k: v for k, v in p.items() if k != "p"}
            piece["p"] = RS.flat_of([pa, pb])
            added.append(piece)
            segs.append((pa, pb))
            k = len(segs) - 1
            grid[(int(math.floor(mid[0] / 16)), int(math.floor(mid[1] / 16)))].append(k)
    if not dry:
        out["paths"].extend(added)
    return len(dots), round(run_on), len(added)


def fix_cycle_crossings(out, asphalt, raised, dry=False):
    """Cycle crossings beside a zebra run on as far as the zebra reaches; free ends on the asphalt run
    on to the kerb. Returns (beside ones lengthened, free ends run on, metres added, short left)."""
    road = lambda x, z: asphalt(x, z) and not raised(x, z)  # noqa: E731
    paths = out["paths"]
    zebras = [_chord(p) for p in paths if p["k"] == "zebra" and _ground(p)]
    zgrid = defaultdict(list)
    for k, (a, b) in enumerate(zebras):
        zgrid[(int(((a[0] + b[0]) / 2) // 30), int(((a[1] + b[1]) / 2) // 30))].append(k)
    ends = defaultdict(list)
    for p in paths:
        if p["k"] in ("cycle", "cyclecross") and _ground(p):
            q = RS.pts_of(p["p"])
            for e in (q[0], q[-1]):
                ends[(int(e[0] // 4), int(e[1] // 4))].append((e, id(p)))
    # a cycle path running along the street touches the crossing's middle, not just its ends
    cyc_segs = defaultdict(list)
    for p in paths:
        if p["k"] == "cycle" and _ground(p):
            q = RS.pts_of(p["p"])
            for s0, s1 in zip(q, q[1:]):
                cyc_segs[(int(((s0[0] + s1[0]) / 2) // 30), int(((s0[1] + s1[1]) / 2) // 30))].append((s0, s1, id(p)))

    def linked(e, me):
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for o, pid in ends.get((int(e[0] // 4) + i, int(e[1] // 4) + j), ()):
                    if pid != me and math.dist(o, e) < CYCLE_LINK:
                        return True
        cx, cz = int(e[0] // 30), int(e[1] // 30)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for s0, s1, pid in cyc_segs.get((cx + i, cz + j), ()):
                    if pid != me and RS.seg_dist(e, s0, s1) < CYCLE_LINK:
                        return True
        return False

    beside = free = 0
    added = 0.0
    short = 0
    for p in paths:
        if p["k"] != "cyclecross" or not _ground(p):
            continue
        q = RS.pts_of(p["p"])
        a, b = q[0], q[-1]
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        n = (-u[1], u[0])
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        # the zebra beside it: parallel, its line within CYCLE_BESIDE, overlapping along it
        want0, want1 = 0.0, L
        cx, cz = int(mx // 30), int(mz // 30)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for k in zgrid.get((cx + i, cz + j), ()):
                    za, zb = zebras[k]
                    zl = math.dist(za, zb)
                    if zl < 1.0:
                        continue
                    zu = ((zb[0] - za[0]) / zl, (zb[1] - za[1]) / zl)
                    if abs(zu[0] * u[0] + zu[1] * u[1]) < CYCLE_COS:
                        continue
                    off = ((za[0] + zb[0]) / 2 - a[0]) * n[0] + ((za[1] + zb[1]) / 2 - a[1]) * n[1]
                    if abs(off) > CYCLE_BESIDE:
                        continue
                    ta = (za[0] - a[0]) * u[0] + (za[1] - a[1]) * u[1]
                    tb = (zb[0] - a[0]) * u[0] + (zb[1] - a[1]) * u[1]
                    lo, hi = min(ta, tb), max(ta, tb)
                    if hi < -1.0 or lo > L + 1.0:
                        continue
                    want0, want1 = min(want0, lo), max(want1, hi)
        grew = False
        for end, prev, want, sgn in ((len(q) - 1, len(q) - 2, want1 - L, 1.0), (0, 1, -want0, -1.0)):
            uu = _unit(q[prev], q[end])
            if uu is None:
                continue
            e = q[end]
            if linked(e, id(p)):
                continue   # it carries on as the next piece of the crossing, or as the cycle path
            if want > 0.5:
                # beside a zebra that reaches further: on along the asphalt, as far as it reaches
                t = min(_run_from(road, e[0], e[1], uu[0], uu[1], want + EDGE_KEEP) - EDGE_KEEP, want)
                if want - max(t, 0.0) > SHORT_LEFT:
                    short += 1
                if t >= 0.5:
                    q[end] = (e[0] + uu[0] * t, e[1] + uu[1] * t)
                    added += t
                    grew = True
                    beside += 1
                continue
            if road(e[0], e[1]):
                t = _run_from(road, e[0], e[1], uu[0], uu[1], RUN_ON) - EDGE_KEEP
                if t >= 0.5:
                    q[end] = (e[0] + uu[0] * t, e[1] + uu[1] * t)
                    added += t
                    grew = True
                    free += 1
        if grew and not dry:
            p["p"] = RS.flat_of(q)
    return beside, free, round(added), short


def measure(out):
    """What is left (the --check numbers)."""
    asphalt, raised = RS._street_tests(out)
    on_bed = RS._bed_index(out)
    nodes = junction_nodes(out)
    all_ribbons = Ribbons(out, lambda r: True)
    main_ribbons = Ribbons(out, lambda r: r["k"] in MAIN)
    mi = MouthIndex(mouths(out, nodes, all_ribbons))
    m_mouth, m_box = cut_lines(out, mi, main_ribbons, dry=True)
    arrows, _ = move_arrows(out, mi, asphalt, dry=True)
    probe = json.loads(json.dumps({k: out[k] for k in ("paths", "roads", "bounds", "outside") if k in out}))
    dots, _, partners = fix_zebras(probe, asphalt, raised, on_bed, all_ribbons, dry=True)
    _, _, _, short = fix_cycle_crossings(probe, asphalt, raised, dry=True)
    return {"mouth_m": m_mouth, "box_m": m_box, "arrows": arrows, "partners": partners, "dots": dots, "short_cycle": short}


def apply(out):
    """Fixes the finished map data in place; returns a one-line summary."""
    if int(out.get("road_fixes", 0)) >= VERSION:
        return "already fixed"
    asphalt, raised = RS._street_tests(out)
    on_bed = RS._bed_index(out)
    all_ribbons = Ribbons(out, lambda r: True)
    dots, run_on, partners = fix_zebras(out, asphalt, raised, on_bed, all_ribbons)
    beside, free, cyc_m, short = fix_cycle_crossings(out, asphalt, raised)
    nodes = junction_nodes(out)
    main_ribbons = Ribbons(out, lambda r: r["k"] in MAIN)
    mi = MouthIndex(mouths(out, nodes, all_ribbons))
    moved, dropped = move_arrows(out, mi, asphalt)
    m_mouth, m_box = cut_lines(out, mi, main_ribbons)
    out["road_fixes"] = VERSION
    return (f"{dots} dot zebras dropped, zebras run on {run_on} m to the kerbs, {partners} far carriageways given "
            f"their zebra; {beside} cycle crossing ends run on beside their zebra and {free} free ends to the kerb "
            f"({cyc_m} m, {short} still short); {len(mi.ms)} junction mouths: {moved} arrows moved behind the stop "
            f"line, {dropped} dropped; lane lines cut: {m_mouth} m in mouths, {m_box} m in junction boxes")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    path = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    if "--check" in sys.argv:
        m = measure(d)
        limits = {"mouth_m": CHECK_MOUTH_M, "box_m": CHECK_BOX_M, "arrows": CHECK_ARROWS,
                  "partners": CHECK_PARTNERS, "dots": CHECK_DOTS, "short_cycle": CHECK_SHORT_CYCLE}
        ok = bool(d.get("road_fixes")) and all(m[k] <= v for k, v in limits.items())
        why = "" if d.get("road_fixes") else " (the map was never fixed: run tools/road_fixes.py)"
        print(f"road_fixes: {'OK' if ok else 'FAIL'}: " + ", ".join(f"{k} {m[k]} (max {v})" for k, v in limits.items()) + why)
        sys.exit(0 if ok else 1)
    if "--dry" in sys.argv:
        print("road_fixes (dry): " + json.dumps(measure(d)))
        return
    print("road_fixes: " + apply(d))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(d, fh, separators=(",", ":"), ensure_ascii=False)


if __name__ == "__main__":
    main()
