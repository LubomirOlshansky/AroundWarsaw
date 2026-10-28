"""Real roads (v0.75): the road surface, its markings and the bridges, baked into
centrum.json by tools/bake_osm.py (which imports this file).

- Carriageway shapes: where OpenStreetMap maps the carriageway as an area
  (`area:highway=*`), that polygon is the road surface; the road's own strip is
  hidden under it ("hide" ranges along the road). Elsewhere the width comes from
  `width`, then the lane counts (`lanes:forward` + `lanes:backward`, `lanes`) and the
  painted cycle lanes, then the road class.
- Lane extents: under an area the carriageway edges are measured left and right of
  the centreline, so the lane graph's lanes and the painted lane lines both sit on
  the drawn asphalt (`w` + `c`, the strip's shift right of the centreline).
- Bridge decks: every bridge road gets a height profile that clears what runs under
  it (5 m over roads, rails and trams, 7.5 m over water), ramps at 6 %, and meets the
  roads at its ends; footways, tram tracks and rails on a bridge take the deck height
  beside them. Decks come as pieces (polylines with a height per point) in groups
  (one structure, one layer); everything drawn on a deck carries its group ("dk").
- Markings: edge lines along the carriageway boundary, lane lines on the lane
  boundaries, stop lines at every signal-controlled approach, turn arrows from
  `turn:lanes`, bus lanes (solid line + BUS), painted cycle lanes (line, red surface,
  bike symbol), hatched areas (`area:highway=emergency/prohibited`).
- Kerbs along carriageway edges against pavements, medians and islands; guard rails
  on bridge edges and on mapped `barrier=guard_rail`; dual-carriageway medians.

Coordinates: metres, +x east, +z south. "Right" of a direction (dx, dz) is (-dz, dx).
"""
import json
import math
import os

LANE_WIDTH = {"motorway": 3.5, "trunk": 3.5, "primary": 3.25, "secondary": 3.25, "tertiary": 3.0,
              "unclassified": 3.0, "residential": 3.0, "living_street": 2.75, "service": 2.75}
BIKE_LANE = 1.5
DEFAULT_WIDTH = {
    "motorway": 10.0, "trunk": 9.0, "primary": 8.0, "secondary": 7.5,
    "tertiary": 6.5, "unclassified": 5.5, "residential": 5.5,
    "living_street": 4.5, "service": 3.5,
    "motorway_link": 5.0, "trunk_link": 5.0, "primary_link": 5.0,
    "secondary_link": 5.0, "tertiary_link": 5.0,
}
MAIN = {"motorway", "trunk", "primary", "secondary", "tertiary",
        "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"}
MINOR = {"service", "living_street"}
# area:highway values that are road surface; hatched areas are painted on asphalt.
CARRIAGE_KINDS = {"primary", "secondary", "tertiary", "unclassified", "residential", "service",
                  "living_street", "yes", "bus_bay", "primary_link", "secondary_link",
                  "tertiary_link", "trunk", "bus", "taxi_stop"}
HATCH_KINDS = {"emergency", "prohibited"}

CLEAR_ROAD = 5.0     # deck clearance over roads, rails and trams
CLEAR_WATER = 7.5    # and over the river
GRADE = 0.06         # ramps up to a clearance
END_GRADE = 0.12     # the steepest a deck may leave the road it starts from
DECK_STEP = 6.0      # deck heights every this many metres

KERB_W = 0.3         # granite kerb, metres across...
EDGE_INSET = 0.35    # ...and the edge line this far inside the carriageway


def num(value):
    if value is None:
        return None
    try:
        return float(str(value).split(";")[0].replace("m", "").replace(",", ".").strip())
    except ValueError:
        return None


def oneway_of(t):
    """1 = only along the way, -1 = only against it, 0 = both directions."""
    ow = t.get("oneway")
    if ow in ("yes", "true", "1"):
        return 1
    if ow in ("-1", "reverse"):
        return -1
    if ow != "no" and t.get("junction") in ("roundabout", "circular"):
        return 1
    return 0


def bike_lanes(t):
    """Painted cycle lanes on the carriageway: (width on the way's left, on its right)."""
    def lane(v):
        return v in ("lane", "opposite_lane")
    ow = oneway_of(t)
    left = right = 0.0
    if lane(t.get("cycleway:both")):
        left = right = BIKE_LANE
    if lane(t.get("cycleway:right")):
        right = BIKE_LANE
    if lane(t.get("cycleway:left")):
        left = BIKE_LANE
    cw = t.get("cycleway")
    if lane(cw):
        if ow == 0:
            left = right = BIKE_LANE
        elif cw == "opposite_lane":
            if ow > 0:
                left = BIKE_LANE
            else:
                right = BIKE_LANE
        elif ow > 0:
            right = BIKE_LANE
        else:
            left = BIKE_LANE
    return left, right


def road_width(t):
    """Carriageway width (cycle lanes included) from the tags, and the cycle lanes."""
    hw = t.get("highway", "")
    bl, br = bike_lanes(t)
    w = num(t.get("width"))
    if w is not None and 3.0 <= w <= 45.0:
        return w, bl, br
    lw = LANE_WIDTH.get(hw.replace("_link", ""), 3.0)
    if hw.endswith("_link"):
        lw = 3.25
    lanes = num(t.get("lanes"))
    nf, nb, both = num(t.get("lanes:forward")), num(t.get("lanes:backward")), num(t.get("lanes:both_ways"))
    n = None
    if nf or nb:
        n = (nf or 0) + (nb or 0) + (both or 0)
        if lanes and lanes > n:
            n = lanes
    elif lanes:
        n = lanes
    if n:
        return n * lw + bl + br, bl, br
    w = DEFAULT_WIDTH.get(hw, 5.5)
    if t.get("service") == "parking_aisle":
        w = 4.5
    elif t.get("service") == "driveway":
        w = 3.0
    return w + bl + br, bl, br


def lane_split(t, width):
    """(oneway, lanes forward, lanes backward) on a carriageway `width` wide (cycle
    lanes left out). A one-way road has nf == nb; lanes narrower than a car are dropped."""
    ow = oneway_of(t)
    lanes = int(num(t.get("lanes")) or 0)
    if ow == 0:
        nf = int(num(t.get("lanes:forward")) or 0) or max(1, lanes // 2)
        nb = int(num(t.get("lanes:backward")) or 0) or (max(1, lanes - nf) if lanes else 1)
    else:
        nf = nb = lanes or (2 if width >= 7.0 else 1)
    while (nf + (nb if ow == 0 else 0)) > (2 if ow == 0 else 1) and width / (nf + (nb if ow == 0 else 0)) < 2.6:
        if ow == 0 and nb > nf:
            nb -= 1
        else:
            nf -= 1
            if ow != 0:
                nb = nf
    return ow, nf, nb


# --- geometry ----------------------------------------------------------------------

def ring_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, z1 = pts[i]
        x2, z2 = pts[(i + 1) % len(pts)]
        a += x1 * z2 - x2 * z1
    return a / 2


def point_in_poly(x, z, pts):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, zi = pts[i]
        xj, zj = pts[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            inside = not inside
        j = i
    return inside


def seg_dist(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = dx * dx + dz * dz
    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
    return math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)


def seg_cross(a, b, c, d):
    """Where segments a-b and c-d cross: (t along a-b, u along c-d) in 0..1, or None."""
    rx, rz = b[0] - a[0], b[1] - a[1]
    sx, sz = d[0] - c[0], d[1] - c[1]
    den = rx * sz - rz * sx
    if abs(den) < 1e-12:
        return None
    qx, qz = c[0] - a[0], c[1] - a[1]
    t = (qx * sz - qz * sx) / den
    u = (qx * rz - qz * rx) / den
    if -1e-9 <= t <= 1 + 1e-9 and -1e-9 <= u <= 1 + 1e-9:
        return t, u
    return None


def pairs(flat_list):
    return list(zip(flat_list[0::2], flat_list[1::2]))


def flat(pts):
    out = []
    for x, z in pts:
        out += [round(x, 2), round(z, 2)]
    return out


def polyline_length(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def resample(pts, step):
    """The polyline with extra points so no segment is longer than `step` (keeps its own points)."""
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        for k in range(1, n + 1):
            out.append((a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n))
    return out


def offset_line(pts, off):
    """The polyline shifted `off` metres to its right, with mitred corners."""
    out = []
    n = len(pts)
    for i in range(n):
        dirs = []
        if i > 0:
            dirs.append(_unit(pts[i - 1], pts[i]))
        if i < n - 1:
            dirs.append(_unit(pts[i], pts[i + 1]))
        dirs = [d for d in dirs if d is not None]
        if not dirs:
            out.append(pts[i])
            continue
        r0 = (-dirs[0][1], dirs[0][0])
        r1 = (-dirs[-1][1], dirs[-1][0])
        mx, mz = r0[0] + r1[0], r0[1] + r1[1]
        ln = math.hypot(mx, mz)
        if ln < 1e-6:
            mx, mz = r1
        else:
            mx, mz = mx / ln, mz / ln
        scale = 1.0 / max(mx * r1[0] + mz * r1[1], 0.5)
        out.append((pts[i][0] + mx * off * scale, pts[i][1] + mz * off * scale))
    return out


def _unit(a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dz)
    return None if ln < 1e-6 else (dx / ln, dz / ln)


def project_onto(pts, cum, x, z):
    """(distance along, signed lateral offset (right +), squared distance) of the point
    nearest (x, z) on the polyline, clamped to its ends."""
    best = None
    for k in range(len(pts) - 1):
        a, b = pts[k], pts[k + 1]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln2 = dx * dx + dz * dz
        if ln2 < 1e-9:
            continue
        u = max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln2))
        px, pz = a[0] + u * dx, a[1] + u * dz
        d2 = (x - px) ** 2 + (z - pz) ** 2
        if best is None or d2 < best[2]:
            ln = math.sqrt(ln2)
            lat = ((x - a[0]) * (-dz) + (z - a[1]) * dx) / ln
            best = (cum[k] + u * ln, lat, d2)
    return best


def simplify(pts, tol):
    """Douglas-Peucker on an open polyline."""
    if len(pts) < 3:
        return list(pts)
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        i, j = stack.pop()
        best, bi = 0.0, -1
        for k in range(i + 1, j):
            d = seg_dist(pts[k][0], pts[k][1], pts[i], pts[j])
            if d > best:
                best, bi = d, k
        if best > tol:
            keep[bi] = True
            stack += [(i, bi), (bi, j)]
    return [p for p, k in zip(pts, keep) if k]


class Terrain:
    """The GUGiK elevation grid (game/map/terrain.json), sampled with the same two
    triangles per cell the game draws; flat 0 when it hasn't been baked."""

    def __init__(self, path):
        self.t = json.load(open(path)) if path and os.path.exists(path) else None

    def h(self, x, z):
        t = self.t
        if t is None:
            return 0.0
        step, nx, nz, hh = t["step"], t["nx"], t["nz"], t["h"]
        fx = min(max((x - t["x0"]) / step, 0.0), nx - 1.0001)
        fz = min(max((z - t["z0"]) / step, 0.0), nz - 1.0001)
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        h00, h10 = hh[j * nx + i], hh[j * nx + i + 1]
        h01, h11 = hh[(j + 1) * nx + i], hh[(j + 1) * nx + i + 1]
        if u >= v:
            return h00 + (h10 - h00) * u + (h11 - h10) * v
        return h00 + (h11 - h01) * u + (h01 - h00) * v


class Grid:
    """Items with bounding boxes in square cells, for nearby queries."""

    def __init__(self, cell=16.0):
        self.cell = cell
        self.cells = {}

    def add(self, item, x0, z0, x1, z1):
        c = self.cell
        for i in range(int(math.floor(x0 / c)), int(math.floor(x1 / c)) + 1):
            for j in range(int(math.floor(z0 / c)), int(math.floor(z1 / c)) + 1):
                self.cells.setdefault((i, j), []).append(item)

    def at(self, x, z):
        return self.cells.get((int(math.floor(x / self.cell)), int(math.floor(z / self.cell))), ())

    def box(self, x0, z0, x1, z1):
        c = self.cell
        seen = set()
        out = []
        for i in range(int(math.floor(x0 / c)), int(math.floor(x1 / c)) + 1):
            for j in range(int(math.floor(z0 / c)), int(math.floor(z1 / c)) + 1):
                for item in self.cells.get((i, j), ()):
                    if id(item) not in seen:
                        seen.add(id(item))
                        out.append(item)
        return out


class Polys:
    """Polygons (lists of points) for inside tests; each with its own bounding box."""

    def __init__(self, polys):
        self.polys = polys
        self.grid = Grid(16.0)
        self.boxes = []
        for i, p in enumerate(polys):
            xs = [q[0] for q in p]
            zs = [q[1] for q in p]
            box = (min(xs), min(zs), max(xs), max(zs))
            self.boxes.append(box)
            self.grid.add(i, *box)

    def hit(self, x, z):
        """Index of a polygon holding the point, or -1."""
        for i in self.grid.at(x, z):
            b = self.boxes[i]
            if b[0] <= x <= b[2] and b[1] <= z <= b[3] and point_in_poly(x, z, self.polys[i]):
                return i
        return -1


class Capsules:
    """Road strips as capsules (segment + half width) for "is this on the road" tests."""

    def __init__(self):
        self.grid = Grid(16.0)

    def add(self, a, b, half, tag):
        self.grid.add((a, b, half, tag), min(a[0], b[0]) - half, min(a[1], b[1]) - half,
                      max(a[0], b[0]) + half, max(a[1], b[1]) + half)

    def hit(self, x, z, pad=0.0, skip=None):
        for a, b, half, tag in self.grid.at(x, z):
            if tag == skip and skip is not None:
                continue
            if seg_dist(x, z, a, b) <= half + pad:
                return tag
        return None


# --- the bake -----------------------------------------------------------------------

class Roadbed:
    def __init__(self, ways, nodes, project, in_bbox, clip_polygon, rect, terrain_path, roads, paths, trams,
                 details, areas):
        self.ways = ways
        self.nodes = nodes
        self.project = project
        self.rect = rect
        self.terrain = Terrain(terrain_path)
        # The map rectangle, cut to where the terrain mesh reaches (the 10 m elevation grid
        # stops a few metres short of the map's south and east edges): areas and kerbs
        # beyond it would hang over the diorama's earth wall.
        self.land = rect
        if self.terrain.t is not None:
            t = self.terrain.t
            self.land = (max(rect[0], t["x0"]), max(rect[1], t["z0"]),
                         min(rect[2], t["x0"] + (t["nx"] - 1) * t["step"]), min(rect[3], t["z0"] + (t["nz"] - 1) * t["step"]))
        self.roads = roads
        self.paths = paths
        self.trams = trams
        self.details = details
        self.areas = areas
        self.water = Polys([pairs(a["p"]) for a in areas if a["k"] == "water"])
        self.green = Polys([pairs(a["p"]) for a in areas if a["k"] in ("park", "grass", "pitch")])
        self.islands = details.get("islands", [])
        self.island_polys = Polys([pairs(a["p"]) for a in self.islands])
        self._collect_areas(in_bbox, clip_polygon)

    # -- areas ---------------------------------------------------------------------

    def _collect_areas(self, in_bbox, clip_polygon):
        """Carriageway and hatched polygons (area:highway), clipped to the map."""
        self.carriage = []   # {"p": pts, "k", "jn": junction box, "ly": layer tag}
        self.hatch = []
        for w in self.ways.values():
            t = w.get("tags", {})
            kind = t.get("area:highway")
            if kind not in CARRIAGE_KINDS and kind not in HATCH_KINDS:
                continue
            ids = w.get("nodes", [])
            if len(ids) < 4 or ids[0] != ids[-1] or not any(i in self.nodes and in_bbox(*self.nodes[i]) for i in ids):
                continue
            pts = [self.project(*self.nodes[i]) for i in ids[:-1] if i in self.nodes]
            pts = clip_polygon(pts, self.land)
            if len(pts) < 3 or abs(ring_area(pts)) < 1.0:
                continue
            item = {"p": pts, "k": kind, "jn": t.get("junction") == "yes", "ly": num(t.get("layer")) or 0}
            (self.hatch if kind in HATCH_KINDS else self.carriage).append(item)
        print(f"roadbed: {len(self.carriage)} carriageway areas, {len(self.hatch)} hatched areas")

    # -- bridge decks ----------------------------------------------------------------

    def solve_decks(self):
        """Height profiles for every bridge road, then decks for what else is on a bridge."""
        T = self.terrain
        roads = self.roads
        x0, z0, x1, z1 = self.rect

        def on_rim(p):
            return min(abs(p[0] - x0), abs(p[0] - x1), abs(p[1] - z0), abs(p[1] - z1)) < 0.5

        def key(p):
            return (round(p[0] * 2), round(p[1] * 2))

        ground_vertices = set()
        for r in roads:
            if not r["bridge"]:
                for p in pairs(r["p"]):
                    ground_vertices.add(key(p))
        bridges = [i for i, r in enumerate(roads) if r["bridge"]]
        ends = {}
        for i in bridges:
            pts = pairs(roads[i]["p"])
            for e, p in ((0, pts[0]), (1, pts[-1])):
                ends.setdefault(key(p), []).append((i, e))

        # What runs under: ground roads, trams and rails, and lower bridge roads.
        under = Grid(32.0)
        for r in roads:
            for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                under.add((a, b, r["w"] * 0.5, "road", r), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for t in self.trams:
            if not t.get("_br"):
                for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                    under.add((a, b, 1.5, "rail", None), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for t in self.details.get("rails", []):
            if not t.get("_br"):
                for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                    under.add((a, b, 2.0, "rail", None), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))

        profile = {}  # road index -> (pts, cum, heights)
        order = sorted(bridges, key=lambda i: roads[i].get("_ly", 1))
        info = {}
        for i in order:
            r = roads[i]
            pts = pairs(r["p"])
            cum = [0.0]
            for a, b in zip(pts, pts[1:]):
                cum.append(cum[-1] + math.dist(a, b))
            length = cum[-1]
            cons = []  # (s, height, half)
            n = max(2, int(length / 3.0) + 1)
            for k in range(n + 1):
                s = length * k / n
                x, z = _at(pts, cum, s)
                if self.water.hit(x, z) >= 0:
                    cons.append((s, T.h(x, z) + CLEAR_WATER, 1.5))
            for a, b, half, kind, other in under.box(min(p[0] for p in pts), min(p[1] for p in pts),
                                                     max(p[0] for p in pts), max(p[1] for p in pts)):
                if other is r:
                    continue
                lower = 0.0
                if other is not None and other["bridge"]:
                    if other.get("_ly", 1) >= r.get("_ly", 1) or id(other) not in profile:
                        continue
                for k in range(len(pts) - 1):
                    hit = seg_cross(pts[k], pts[k + 1], a, b)
                    if hit is None:
                        continue
                    s = cum[k] + hit[0] * (cum[k + 1] - cum[k])
                    if s < 1.0 or s > length - 1.0:
                        continue  # a road meeting the bridge at its end, not passing under
                    px = a[0] + (b[0] - a[0]) * hit[1]
                    pz = a[1] + (b[1] - a[1]) * hit[1]
                    if other is not None and other["bridge"]:
                        opts, ocum, oh = profile[id(other)]
                        so = project_onto(opts, ocum, px, pz)[0]
                        lower = _interp(ocum, oh, so)
                    else:
                        lower = T.h(px, pz)
                    d1 = _unit(pts[k], pts[k + 1])
                    d2 = _unit(a, b)
                    sin = abs(d1[0] * d2[1] - d1[1] * d2[0]) if d1 and d2 else 1.0
                    cons.append((s, lower + CLEAR_ROAD, half / max(sin, 0.25) + 1.5))
            info[i] = {"pts": pts, "cum": cum, "len": length, "cons": cons}

        def envelope(inf, s, extra):
            best = -1e9
            for cs, ch, half in inf["cons"] + extra:
                best = max(best, ch - GRADE * max(0.0, abs(s - cs) - half))
            return best

        # Ends: pinned to the ground road they meet, free at a joint between bridge
        # roads (it takes the higher envelope of both), free at the map's edge.
        end_h = {}
        joint_extra = {i: [] for i in bridges}
        for _ in range(4):
            for k, members in ends.items():
                p = (k[0] / 2.0, k[1] / 2.0)
                pinned = k in ground_vertices or (len(members) == 1 and not on_rim(p))
                if pinned:
                    h = T.h(*p)
                else:
                    h = T.h(*p)
                    for i, e in members:
                        inf = info[i]
                        h = max(h, envelope(inf, 0.0 if e == 0 else inf["len"], joint_extra[i]))
                end_h[k] = (h, pinned)
            for i in bridges:
                inf = info[i]
                joint_extra[i] = []
                for e in (0, 1):
                    h, pinned = end_h[key(inf["pts"][0 if e == 0 else -1])]
                    if not pinned:
                        joint_extra[i].append((0.0 if e == 0 else inf["len"], h, 0.0))

        self.pieces = []   # {"pts", "cum", "h", "l", "r", "ly", "g", "kind"}
        self.road_piece = {}
        for i in order:
            r = roads[i]
            inf = info[i]
            pts = resample(inf["pts"], DECK_STEP)
            cum = [0.0]
            for a, b in zip(pts, pts[1:]):
                cum.append(cum[-1] + math.dist(a, b))
            h0, pin0 = end_h[key(inf["pts"][0])]
            h1, pin1 = end_h[key(inf["pts"][-1])]
            length = cum[-1]
            hs = []
            for s, p in zip(cum, pts):
                h = max(h0 + (h1 - h0) * (s / length if length > 0 else 0.0), envelope(inf, s, joint_extra[i]))
                if pin0:
                    h = min(h, h0 + END_GRADE * s)
                if pin1:
                    h = min(h, h1 + END_GRADE * (length - s))
                hs.append(max(h, T.h(*p)))
            piece = {"pts": pts, "cum": cum, "h": hs, "l": r["w"] * 0.5 + 0.5, "r": r["w"] * 0.5 + 0.5,
                     "ly": r.get("_ly", 1), "kind": "road", "road": i}
            profile[id(r)] = (pts, cum, hs)
            self.road_piece[i] = len(self.pieces)
            self.pieces.append(piece)

        # Footways, tram tracks and rails on a bridge: the height of the deck beside
        # them; a bridge with no road on it (a railway, a footbridge) solves its own.
        road_pieces = list(self.pieces)
        lonely = []
        for kind, items, half in (("path", self.paths, None), ("tram", self.trams, 1.6),
                                  ("rail", self.details.get("rails", []), 2.2)):
            for it in items:
                if not it.get("_br"):
                    continue
                pts = resample(pairs(it["p"]), DECK_STEP)
                if len(pts) < 2:
                    continue
                cum = [0.0]
                for a, b in zip(pts, pts[1:]):
                    cum.append(cum[-1] + math.dist(a, b))
                hs = []
                found = 0
                for p in pts:
                    best = None
                    for pc in road_pieces:
                        if abs(pc["ly"] - it.get("_ly", 1)) > 0 and kind != "tram":
                            continue
                        pr = project_onto(pc["pts"], pc["cum"], p[0], p[1])
                        if pr and pr[2] < 40.0 ** 2 and (best is None or pr[2] < best[0]):
                            best = (pr[2], _interp(pc["cum"], pc["h"], pr[0]))
                    if best is not None:
                        found += 1
                        hs.append(best[1])
                    else:
                        hs.append(None)
                hw = half if half is not None else float(it.get("w", 2.0)) * 0.5 + 0.3
                if found >= 0.6 * len(pts):
                    # Fill the gaps (past the deck's ends) from the neighbours.
                    known = [k for k, h in enumerate(hs) if h is not None]
                    for k in range(len(hs)):
                        if hs[k] is None:
                            j = min(known, key=lambda q: abs(q - k))
                            hs[k] = hs[j]
                    piece = {"pts": pts, "cum": cum, "h": hs, "l": hw, "r": hw, "ly": it.get("_ly", 1), "kind": kind, "item": it}
                    it["_piece"] = len(self.pieces)
                    self.pieces.append(piece)
                elif kind != "path" or polyline_length(pts) > 30.0:
                    lonely.append((kind, it, pts, cum, hw))
        for kind, it, pts, cum, hw in lonely:
            hs = self._lonely_profile(pts, cum, under)
            it["_piece"] = len(self.pieces)
            self.pieces.append({"pts": pts, "cum": cum, "h": hs, "l": hw, "r": hw, "ly": it.get("_ly", 1), "kind": kind, "item": it})

        # Groups: the pieces of one structure (same layer, within 30 m of each other).
        parent = list(range(len(self.pieces)))

        def find(a):
            while parent[a] != a:
                parent[a] = parent[parent[a]]
                a = parent[a]
            return a

        for a in range(len(self.pieces)):
            for b in range(a + 1, len(self.pieces)):
                pa, pb = self.pieces[a], self.pieces[b]
                if pa["ly"] != pb["ly"] and "tram" not in (pa["kind"], pb["kind"]):
                    continue
                if _near(pa, pb, 30.0):
                    parent[find(a)] = find(b)
        roots = {}
        for k, pc in enumerate(self.pieces):
            pc["g"] = roots.setdefault(find(k), len(roots))
        self.groups = len(roots)
        for it_list in (self.paths, self.trams, self.details.get("rails", [])):
            for it in it_list:
                if "_piece" in it:
                    it["dk"] = self.pieces[it.pop("_piece")]["g"]
        for i, k in self.road_piece.items():
            roads[i]["dk"] = self.pieces[k]["g"]
        self.piece_grid = Grid(32.0)
        for k, pc in enumerate(self.pieces):
            xs = [p[0] for p in pc["pts"]]
            zs = [p[1] for p in pc["pts"]]
            self.piece_grid.add(k, min(xs) - 25, min(zs) - 25, max(xs) + 25, max(zs) + 25)
        tall = max((max(h - T.h(*p) for p, h in zip(pc["pts"], pc["h"])) for pc in self.pieces), default=0.0)
        print(f"decks: {len(self.pieces)} pieces in {self.groups} structures ({len(road_pieces)} bridge roads, "
              f"{len(lonely)} without a road), highest {tall:.1f} m over the ground")

    def _lonely_profile(self, pts, cum, under):
        """A footbridge or railway bridge on its own: ends on the ground, clears what's under."""
        T = self.terrain
        length = cum[-1]
        cons = []
        for s, p in zip(cum, pts):
            if self.water.hit(*p) >= 0:
                cons.append((s, T.h(*p) + CLEAR_WATER, 1.5))
        for a, b, half, kind, other in under.box(min(p[0] for p in pts), min(p[1] for p in pts),
                                                 max(p[0] for p in pts), max(p[1] for p in pts)):
            if other is not None and other["bridge"]:
                continue
            for k in range(len(pts) - 1):
                hit = seg_cross(pts[k], pts[k + 1], a, b)
                if hit and 2.0 < cum[k] + hit[0] * (cum[k + 1] - cum[k]) < length - 2.0:
                    px = a[0] + (b[0] - a[0]) * hit[1]
                    pz = a[1] + (b[1] - a[1]) * hit[1]
                    cons.append((cum[k] + hit[0] * (cum[k + 1] - cum[k]), T.h(px, pz) + CLEAR_ROAD, half + 1.0))
        h0, h1 = T.h(*pts[0]), T.h(*pts[-1])
        x0, z0, x1, z1 = self.rect
        rim0 = min(abs(pts[0][0] - x0), abs(pts[0][0] - x1), abs(pts[0][1] - z0), abs(pts[0][1] - z1)) < 0.5
        rim1 = min(abs(pts[-1][0] - x0), abs(pts[-1][0] - x1), abs(pts[-1][1] - z0), abs(pts[-1][1] - z1)) < 0.5
        out = []
        for s, p in zip(cum, pts):
            h = h0 + (h1 - h0) * (s / length if length > 0 else 0.0)
            for cs, ch, half in cons:
                h = max(h, ch - GRADE * max(0.0, abs(s - cs) - half))
            if not rim0:
                h = min(h, h0 + END_GRADE * s)
            if not rim1:
                h = min(h, h1 + END_GRADE * (length - s))
            out.append(max(h, T.h(*p)))
        return out

    def deck_height(self, g, x, z):
        """Height of deck group g at a point: the nearest of its pieces, projected."""
        best = None
        for k in self.piece_grid.at(x, z):
            pc = self.pieces[k]
            if pc["g"] != g:
                continue
            pr = project_onto(pc["pts"], pc["cum"], x, z)
            if pr and (best is None or pr[2] < best[0]):
                best = (pr[2], _interp(pc["cum"], pc["h"], pr[0]))
        if best is None:
            for pc in self.pieces:
                if pc["g"] == g:
                    pr = project_onto(pc["pts"], pc["cum"], x, z)
                    if pr and (best is None or pr[2] < best[0]):
                        best = (pr[2], _interp(pc["cum"], pc["h"], pr[0]))
        return best[1] if best else self.terrain.h(x, z)

    def on_deck(self, x, z, pad=0.0):
        """The deck group whose corridor holds the point, or -1 (the highest one)."""
        best = (-1, -1e9)
        for k in self.piece_grid.at(x, z):
            pc = self.pieces[k]
            pr = project_onto(pc["pts"], pc["cum"], x, z)
            if pr is None or pr[0] <= 0.01 or pr[0] >= pc["cum"][-1] - 0.01:
                continue
            if -pc["l"] - pad <= pr[1] <= pc["r"] + pad:
                h = _interp(pc["cum"], pc["h"], pr[0])
                if h > best[1]:
                    best = (pc["g"], h)
        return best[0]

    # -- levels of the flat things --------------------------------------------------

    def assign_levels(self):
        """Which deck (or the ground, -1) each carriageway/hatched area and island lies on."""
        segs = Grid(16.0)
        for r in self.roads:
            if r["k"] not in DEFAULT_WIDTH:
                continue
            for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                segs.add((a, b, r), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for item in self.carriage + self.hatch + self.islands:
            pts = item["p"] if isinstance(item["p"][0], tuple) else pairs(item["p"])
            xs = [p[0] for p in pts]
            zs = [p[1] for p in pts]
            lengths = {}
            for a, b, r in segs.box(min(xs), min(zs), max(xs), max(zs)):
                # Centreline length inside the polygon, by the road's level.
                n = max(1, int(math.dist(a, b) / 1.0))
                inside = 0
                for k in range(n):
                    x = a[0] + (b[0] - a[0]) * (k + 0.5) / n
                    z = a[1] + (b[1] - a[1]) * (k + 0.5) / n
                    if point_in_poly(x, z, pts):
                        inside += 1
                if inside:
                    lv = r.get("dk", -1)
                    lengths[lv] = lengths.get(lv, 0.0) + inside * math.dist(a, b) / n
            level = -1
            if item.get("jn") and not item.get("ly"):
                level = -1
            elif lengths:
                best = max(lengths.items(), key=lambda kv: (kv[1], kv[0] == -1))
                if best[0] != -1 and best[1] > lengths.get(-1, 0.0) + 2.0:
                    level = best[0]
            else:
                # No road through it (an island, a painted area): on a deck only if all of
                # it lies on one.
                decks = {self.on_deck(x, z, 1.0) for x, z in pts}
                if len(decks) == 1 and -1 not in decks:
                    level = decks.pop()
            item["dk"] = level

    # -- carriageway extents ------------------------------------------------------------

    def measure(self):
        """Left/right carriageway extents of the roads under an area, per way."""
        self.cpolys = {}   # level -> Polys of carriageway areas (junction boxes included)
        for lv in {c["dk"] for c in self.carriage}:
            self.cpolys[lv] = Polys([c["p"] for c in self.carriage if c["dk"] == lv])
        self.cjunction = {lv: [c["jn"] for c in self.carriage if c["dk"] == lv] for lv in self.cpolys}
        cl = Capsules()
        for r in self.roads:
            if r["k"] in DEFAULT_WIDTH:
                for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                    cl.add(a, b, 0.0, r)
        samples = {}
        for r in self.roads:
            lv = r.get("dk", -1)
            polys = self.cpolys.get(lv)
            if polys is None:
                continue
            pts = pairs(r["p"])
            for a, b in zip(pts, pts[1:]):
                d = _unit(a, b)
                if d is None:
                    continue
                ln = math.dist(a, b)
                n = int(ln / 4.0)
                for k in range(n):
                    s = (k + 0.5) * ln / n
                    x, z = a[0] + d[0] * s, a[1] + d[1] * s
                    i = polys.hit(x, z)
                    if i < 0 or self.cjunction[lv][i]:
                        continue
                    nx, nz = -d[1], d[0]
                    right = self._ray(polys, x, z, nx, nz, d, r, cl)
                    left = self._ray(polys, x, z, -nx, -nz, d, r, cl)
                    samples.setdefault(r["_id"], []).append((left, right))
        self.extents = {}
        for wid, ss in samples.items():
            if len(ss) < 2:
                continue
            ls = sorted(s[0] for s in ss)
            rs = sorted(s[1] for s in ss)
            left, right = ls[len(ls) // 2], rs[len(rs) // 2]
            if 3.0 <= left + right <= 40.0 and left >= 0.8 and right >= 0.8:
                self.extents[wid] = (left, right)
        print(f"roadbed: measured {len(self.extents)} ways under carriageway areas")

    def _ray(self, polys, x, z, nx, nz, d, road, cl, reach=24.0):
        """How far the carriageway runs from (x, z) along (nx, nz): to the edge of the
        areas, or half way to another road running alongside."""
        ex, ez = x + nx * reach, z + nz * reach
        cand = polys.grid.box(min(x, ex), min(z, ez), max(x, ex), max(z, ez))
        ts = []
        for i in cand:
            p = polys.polys[i]
            for k in range(len(p)):
                hit = seg_cross((x, z), (ex, ez), p[k], p[(k + 1) % len(p)])
                if hit:
                    ts.append(hit[0] * reach)
        ts.sort()
        edge = reach
        prev = 0.0
        for t in ts + [reach]:
            if t - prev < 0.02:
                continue
            m = (prev + t) * 0.5
            mx, mz = x + nx * m, z + nz * m
            if not any(point_in_poly(mx, mz, polys.polys[i]) for i in cand):
                edge = prev
                break
            prev = t
        # Another road alongside (not crossing): the carriageway is shared half way.
        for a, b, _, other in cl.grid.box(min(x, ex), min(z, ez), max(x, ex), max(z, ez)):
            if other is road or other.get("_id") == road.get("_id") or other.get("dk", -1) != road.get("dk", -1):
                continue
            od = _unit(a, b)
            if od is None or abs(od[0] * d[0] + od[1] * d[1]) < 0.85:
                continue
            hit = seg_cross((x, z), (ex, ez), a, b)
            if hit:
                edge = min(edge, hit[0] * reach * 0.5)
        return edge

    # -- roads --------------------------------------------------------------------------

    def finish_roads(self):
        """Each road's drawn width, shift and the stretches an area already covers."""
        self.way_ext = {}
        for r in self.roads:
            t = r["_t"]
            w, bl, br = road_width(t)
            ext = self.extents.get(r["_id"])
            if ext:
                left, right = ext
            else:
                left = right = w * 0.5
            r["w"] = round(left + right, 2)
            r["c"] = round((right - left) * 0.5, 2)
            # The cars' part of it, without the cycle lanes.
            cl, cr = left - bl, right - br
            if cl + cr < 2.6:
                cl, cr, bl, br = left, right, 0.0, 0.0
            r["_ext"] = (left, right, cl, cr, bl, br)
            self.way_ext.setdefault(r["_id"], r["_ext"])
            lv = r.get("dk", -1)
            polys = self.cpolys.get(lv)
            hide = []
            if polys is not None:
                pts = pairs(r["p"])
                s = 0.0
                state = None
                start = 0.0
                step = 1.0
                for a, b in zip(pts, pts[1:]):
                    ln = math.dist(a, b)
                    n = max(1, int(math.ceil(ln / step)))
                    for k in range(n + 1):
                        if k == 0 and s > 0:
                            continue
                        x = a[0] + (b[0] - a[0]) * k / n
                        z = a[1] + (b[1] - a[1]) * k / n
                        here = polys.hit(x, z) >= 0
                        at = s + ln * k / n
                        if state is None:
                            state, start = here, at
                        elif here != state:
                            if state:
                                hide.append([start, at])
                            state, start = here, at
                    s += ln
                if state:
                    hide.append([start, s])
                # Drop specks: short covered bits stay drawn, short gaps get covered.
                merged = []
                for h0, h1 in hide:
                    if merged and h0 - merged[-1][1] < 3.0:
                        merged[-1][1] = h1
                    else:
                        merged.append([h0, h1])
                hide = [[round(h0, 2), round(h1, 2)] for h0, h1 in merged if h1 - h0 >= 3.0]
            if hide:
                r["hide"] = hide

    def visible_segments(self, r):
        """The road's centreline pieces not covered by an area: lists of points."""
        pts = pairs(r["p"])
        hide = r.get("hide", [])
        runs, cur = [], []
        s = 0.0
        for a, b in zip(pts, pts[1:]):
            ln = math.dist(a, b)
            cuts = [0.0, ln]
            for h0, h1 in hide:
                for c in (h0 - s, h1 - s):
                    if 0.0 < c < ln:
                        cuts.append(c)
            cuts.sort()
            for c0, c1 in zip(cuts, cuts[1:]):
                mid = s + (c0 + c1) * 0.5
                p0 = (a[0] + (b[0] - a[0]) * c0 / ln, a[1] + (b[1] - a[1]) * c0 / ln) if ln > 0 else a
                p1 = (a[0] + (b[0] - a[0]) * c1 / ln, a[1] + (b[1] - a[1]) * c1 / ln) if ln > 0 else b
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

    # -- "is this carriageway" ------------------------------------------------------------

    def build_region(self):
        self.caps = {}    # level -> Capsules of drawn road strips (tag: road)
        self.allcaps = {}  # level -> every road's strip, drawn or under an area (for cuts)
        for r in self.roads:
            lv = r.get("dk", -1)
            half = r["w"] * 0.5
            shifted = offset_line(pairs(r["p"]), r["c"])
            for a, b in zip(shifted, shifted[1:]):
                self.allcaps.setdefault(lv, Capsules()).add(a, b, half, r)
            for run in self.visible_segments(r):
                run = offset_line(run, r["c"])
                for a, b in zip(run, run[1:]):
                    self.caps.setdefault(lv, Capsules()).add(a, b, half, r)
        self.hpolys = {}
        for lv in {h["dk"] for h in self.hatch}:
            self.hpolys[lv] = Polys([h["p"] for h in self.hatch if h["dk"] == lv])
        self.ipolys = {}
        for lv in {i["dk"] for i in self.islands}:
            self.ipolys[lv] = Polys([pairs(i["p"]) for i in self.islands if i["dk"] == lv])
        self.tram_caps = Capsules()
        for t in self.trams:
            for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                self.tram_caps.add(a, b, 1.3, t.get("dk", -1))

    def paintable(self, lv, x, z):
        """On the asphalt and free to paint: not under an island or a hatched area."""
        if not self.road_at(lv, x, z):
            return False
        ip, hp = self.ipolys.get(lv), self.hpolys.get(lv)
        return not ((ip is not None and ip.hit(x, z) >= 0) or (hp is not None and hp.hit(x, z) >= 0))

    def road_at(self, lv, x, z):
        polys = self.cpolys.get(lv)
        if polys is not None and polys.hit(x, z) >= 0:
            return True
        caps = self.caps.get(lv)
        return caps is not None and caps.hit(x, z) is not None

    def outside_kind(self, lv, x, z):
        """What lies beyond a carriageway edge: None (more carriageway), "hatch", "island" or "kerb"."""
        if self.road_at(lv, x, z):
            return None
        hp = self.hpolys.get(lv)
        if hp is not None and hp.hit(x, z) >= 0:
            return "hatch"
        ip = self.ipolys.get(lv)
        if ip is not None and ip.hit(x, z) >= 0:
            return "island"
        return "kerb"

    # -- kerbs and edge lines ---------------------------------------------------------------

    def bake_edges(self):
        """Walk every carriageway boundary (area outlines and drawn road edges) in 1 m
        steps; where the outside is not road there is an edge: a kerb against a pavement
        or a median, a painted edge only against a hatched area or an island (whose own
        kerb rings it)."""
        kerbs, lines = [], []

        def walk(points, lv, main, outward_right):
            # points: the boundary in order, outward on the right (or left).
            run_k, run_l = [], []
            out_k, out_l = [], []
            sgn = 1.0 if outward_right else -1.0
            for a, b in zip(points, points[1:]):
                d = _unit(a, b)
                if d is None:
                    continue
                ln = math.dist(a, b)
                n = max(1, int(math.ceil(ln / 1.0)))
                ox, oz = -d[1] * sgn, d[0] * sgn
                for k in range(n + 1):
                    x = a[0] + d[0] * ln * k / n
                    z = a[1] + d[1] * ln * k / n
                    kind = self.outside_kind(lv, x + ox * 0.45, z + oz * 0.45)
                    if not (self.land[0] + 0.5 <= x <= self.land[2] - 0.5 and self.land[1] + 0.5 <= z <= self.land[3] - 0.5):
                        kind = None  # past the terrain's edge
                    if kind == "kerb" and self.tram_caps.hit(x, z) is not None:
                        kind = "track"   # a tram track leaves the road here: no kerb across it
                    is_k = kind == "kerb"
                    is_l = kind is not None and main
                    for flag, run, out in ((is_k, run_k, out_k), (is_l, run_l, out_l)):
                        if flag:
                            run.append((x, z))
                        elif len(run) >= 2:
                            out.append(list(run))
                            run.clear()
                        else:
                            run.clear()
            for run, out in ((run_k, out_k), (run_l, out_l)):
                if len(run) >= 2:
                    out.append(list(run))
            for run in out_k:
                run = _dedupe(run)
                if polyline_length(run) >= 1.5:
                    pts = simplify(run, 0.06)
                    if not outward_right:
                        pts = pts[::-1]
                    kerbs.append({"p": flat(pts), "dk": lv})
            for run in out_l:
                run = _dedupe(run)
                if polyline_length(run) >= 3.0:
                    pts = offset_line(simplify(run, 0.06), -EDGE_INSET * sgn)
                    lines.append({"k": "edge", "p": flat(pts), "dk": lv})

        for c in self.carriage:
            pts = list(c["p"])
            # With +z south a positive ring_area runs clockwise seen from above: the
            # inside is on the right, the outside on the left.
            cw = ring_area(pts) > 0
            ring = pts + [pts[0]]
            main = c["k"] in MAIN or c["k"] == "bus_bay" or (c["k"] == "yes" and not c["jn"])
            walk(ring, c["dk"], main and not c["jn"], not cw)
        for r in self.roads:
            if r["k"] in MINOR:
                continue
            lv = r.get("dk", -1)
            main = r["k"] in MAIN or (r["_t"].get("lanes") and (num(r["_t"].get("lanes")) or 0) >= 2)
            half = r["w"] * 0.5
            for run in self.visible_segments(r):
                centre = offset_line(run, r["c"])
                walk(offset_line(centre, half), lv, main, True)
                walk(offset_line(centre, -half)[::-1], lv, main, True)
                # Round the outer side of bends, as the drawn discs do.
                for k in range(1, len(centre) - 1):
                    d0 = _unit(centre[k - 1], centre[k])
                    d1 = _unit(centre[k], centre[k + 1])
                    if d0 is None or d1 is None:
                        continue
                    turn = math.atan2(d0[0] * d1[1] - d0[1] * d1[0], d0[0] * d1[0] + d0[1] * d1[1])
                    if abs(turn) < 0.12:
                        continue
                    # Outer side: left for a right turn (turn > 0 turns towards +right).
                    sgn = -1.0 if turn > 0 else 1.0
                    a0 = math.atan2(d0[0] * sgn, -d0[1] * sgn)
                    steps = max(2, int(abs(turn) * half / 0.8))
                    arc = []
                    for q in range(steps + 1):
                        ang = a0 + (turn * q / steps)
                        arc.append((centre[k][0] + math.cos(ang) * half, centre[k][1] + math.sin(ang) * half))
                    walk(arc, lv, main, turn < 0)
        self.kerbs = kerbs
        self.edge_lines = lines
        print(f"roadbed: kerbs {len(kerbs)} runs, {sum(polyline_length(pairs(k['p'])) for k in kerbs) / 1000:.1f} km; "
              f"edge lines {len(lines)}")

    # -- medians --------------------------------------------------------------------------

    def bake_medians(self):
        """The strip between the two halves of a dual carriageway (one-way roads running
        opposite ways side by side): raised, its edges kerbed by bake_edges; grass, or
        paving where trams run in it. Mapped grass, islands and hatching stay as they are."""
        out = []
        for r in self.roads:
            t = r["_t"]
            ow = oneway_of(t)
            if ow == 0 or r["k"] in MINOR:
                continue
            lv = r.get("dk", -1)
            caps = self.allcaps.get(lv)
            ip, hp = self.ipolys.get(lv), self.hpolys.get(lv)
            # The other half is on the travel direction's left: the way's left for
            # oneway=yes, its right for oneway=-1.
            sgn = -1.0 if ow > 0 else 1.0
            pts = pairs(r["p"])
            strip = []

            def flush():
                if len(strip) >= 2:
                    near = [p for p, _ in strip]
                    far = [q for _, q in strip]
                    mid = strip[len(strip) // 2]
                    mx = (mid[0][0] + mid[1][0]) * 0.5
                    mz = (mid[0][1] + mid[1][1]) * 0.5
                    tram = any(self.tram_caps.hit((p[0] + q[0]) * 0.5, (p[1] + q[1]) * 0.5) is not None for p, q in strip)
                    if abs(ring_area(near + far[::-1])) > 4.0 and self.green.hit(mx, mz) < 0:
                        out.append({"s": flat([v for pq in strip for v in pq]), "k": "paving" if tram else "grass", "dk": lv})
                strip.clear()

            for a, b in zip(pts, pts[1:]):
                d = _unit(a, b)
                if d is None:
                    continue
                travel = (d[0] * ow, d[1] * ow)
                ln = math.dist(a, b)
                n = max(1, int(ln / 3.0))
                nx, nz = -d[1] * sgn, d[0] * sgn
                for k in range(n + 1):
                    x = a[0] + d[0] * ln * k / n
                    z = a[1] + d[1] * ln * k / n
                    # Out from the centreline: across our own carriageway, then the gap,
                    # then (maybe) the other half.
                    g = 0.25
                    while g <= 25.0 and self.road_at(lv, x + nx * g, z + nz * g):
                        g += 0.25
                    edge = g
                    far = None
                    blocked = False
                    while g <= edge + 16.0:
                        qx, qz = x + nx * g, z + nz * g
                        if self.road_at(lv, qx, qz):
                            far = (qx, qz, g - edge)
                            break
                        if (ip is not None and ip.hit(qx, qz) >= 0) or (hp is not None and hp.hit(qx, qz) >= 0):
                            blocked = True
                            break
                        g += 0.5
                    ok = not blocked and edge > 1.0 and far is not None and far[2] >= 1.0 and caps is not None
                    if ok:
                        other = caps.hit(far[0], far[1], 0.5, r)
                        ow2 = oneway_of(other["_t"]) if other is not None else 0
                        od = _road_dir(other, far[0], far[1]) if ow2 else None
                        ok = od is not None and (od[0] * ow2 * travel[0] + od[1] * ow2 * travel[1]) < -0.8
                    if not ok:
                        flush()
                        continue
                    ex, ez = x + nx * (edge - 0.2), z + nz * (edge - 0.2)
                    strip.append(((ex, ez), (far[0] - nx * 0.3, far[1] - nz * 0.3)))
            flush()
        # Each median is found from both sides: keep one.
        kept = []
        polys = []
        for m in out:
            s4 = m["s"]
            q = [(s4[i], s4[i + 1]) for i in range(0, len(s4), 4)] + [(s4[i + 2], s4[i + 3]) for i in range(0, len(s4), 4)][::-1]
            mid = len(s4) // 8 * 4
            cx, cz = (s4[mid] + s4[mid + 2]) * 0.5, (s4[mid + 1] + s4[mid + 3]) * 0.5
            if any(lv == m["dk"] and point_in_poly(cx, cz, poly) for lv, poly in polys):
                continue
            polys.append((m["dk"], q))
            kept.append(m)
        self.medians = kept
        print(f"roadbed: {len(kept)} median strips ({sum(1 for m in kept if m['k'] == 'paving')} with trams)")

    # -- lane lines, stop lines, arrows, bus and cycle lanes -----------------------------

    def _crossed(self, r, lv, x, z, d):
        """True where another road crosses (its strip, at an angle) or a junction box."""
        caps = self.allcaps.get(lv)
        if caps is not None:
            for a, b, half, other in caps.grid.at(x, z):
                if other is r or other.get("_id") == r.get("_id"):
                    continue
                od = _unit(a, b)
                if od is None or abs(od[0] * d[0] + od[1] * d[1]) > 0.94:
                    continue  # the same street carrying on, or a parallel carriageway
                if seg_dist(x, z, a, b) < half + 0.3:
                    return True
        # Junction boxes stay unpainted, except a roundabout's own ring (its box is the ring).
        polys = self.cpolys.get(lv)
        if polys is not None and r["_t"].get("junction") not in ("roundabout", "circular"):
            i = polys.hit(x, z)
            if i >= 0 and self.cjunction[lv][i]:
                return True
        return False

    def _paint_along(self, r, lv, off, kind, out, width=None, min_len=2.0):
        """A line `off` metres right of road r's centreline, cut at crossings and kept
        on the asphalt."""
        pts = offset_line(pairs(r["p"]), off)
        run = []

        def flush():
            if len(run) >= 2 and polyline_length(run) >= min_len:
                m = {"k": kind, "p": flat(simplify(run, 0.05)), "dk": lv}
                if width is not None:
                    m["w"] = round(width, 2)
                out.append(m)
            run.clear()

        for a, b in zip(pts, pts[1:]):
            d = _unit(a, b)
            if d is None:
                continue
            ln = math.dist(a, b)
            n = max(1, int(math.ceil(ln)))
            for k in range(n + 1):
                x = a[0] + d[0] * ln * k / n
                z = a[1] + d[1] * ln * k / n
                if self._crossed(r, lv, x, z, d) or not self.paintable(lv, x, z):
                    flush()
                else:
                    run.append((x, z))
        flush()

    def bake_lane_lines(self):
        out = []
        symbols = []
        for r in self.roads:
            if r["k"] in MINOR:
                continue
            t = r["_t"]
            lv = r.get("dk", -1)
            left, right, cl, cr, bl, br = r["_ext"]
            ow, nf, nb = lane_split(t, cl + cr)
            total = nf + nb if ow == 0 else nf
            lw = (cl + cr) / total
            for k in range(1, total):
                off = -cl + k * lw
                if ow == 0 and k == nb:
                    solid = total >= 4 or r["k"] in ("primary", "secondary", "trunk")
                    self._paint_along(r, lv, off, "centre" if solid else "lane", out)
                else:
                    self._paint_along(r, lv, off, "lane", out)
            # Painted cycle lanes: the line between them and the cars, red surface, bikes.
            for side, width in ((-1, bl), (1, br)):
                if width <= 0:
                    continue
                line = -cl if side < 0 else cr
                centre = line + side * width * 0.5
                self._paint_along(r, lv, line, "cycle", out)
                self._paint_along(r, lv, centre, "cyclefill", out, width - 0.15)
                # Riding direction: the way's right lane goes with it, the left one against
                # it on a two-way road or a contraflow lane.
                along = side > 0 if ow >= 0 else side < 0
                if side < 0 and ow > 0 and t.get("cycleway:left") == "lane":
                    along = True
                self._symbols_along(r, lv, centre, "bike", along, 40.0, symbols)
        self.lane_lines = out
        self.symbols = symbols

    def _symbols_along(self, r, lv, off, kind, along, spacing, out, start=12.0):
        pts = offset_line(pairs(r["p"]), off)
        cum = [0.0]
        for a, b in zip(pts, pts[1:]):
            cum.append(cum[-1] + math.dist(a, b))
        length = cum[-1]
        s = start
        while s < length - 6.0:
            x, z = _at(pts, cum, s)
            k = max(0, min(len(pts) - 2, next((i for i in range(len(cum) - 1) if cum[i + 1] >= s), len(pts) - 2)))
            d = _unit(pts[k], pts[k + 1])
            if d is not None and self.paintable(lv, x, z) and not self._crossed(r, lv, x, z, d):
                if not along:
                    d = (-d[0], -d[1])
                out.append({"k": kind, "x": round(x, 2), "z": round(z, 2), "d": [round(d[0], 3), round(d[1], 3)], "dk": lv})
            s += spacing

    def bake_lane_marks(self, edges):
        """Stop lines, turn arrows and bus lanes on the lane graph's edges (so they sit
        exactly where the cars stop and drive)."""
        out = []
        sym = self.symbols
        for e in edges:
            pts = pairs(e["p"])
            cum = [0.0]
            for a, b in zip(pts, pts[1:]):
                cum.append(cum[-1] + math.dist(a, b))
            n, lw, o = e["n"], e["lw"], e["o"]
            left, right = o - lw * 0.5, o + (n - 0.5) * lw
            lv = -1
            if e.get("br"):
                mid = _edge_point(pts, cum, cum[-1] * 0.5, (left + right) * 0.5)
                lv = self.on_deck(mid[0], mid[1], 1.0)
            for st in e.get("st", []):
                s = max(0.5, min(st[0] - 0.4, cum[-1] - 0.5))
                a = _edge_point(pts, cum, s, left + 0.15)
                b = _edge_point(pts, cum, s, right - 0.15)
                out.append({"k": "stop", "p": flat([a, b]), "dk": lv})
            turns = e.get("_turn")
            span = e["s1"] - e["s0"]
            if turns and e.get("_last") and span > 14.0 and e["s1"] < cum[-1] - 0.5:
                m = len(turns)
                wide = (right - left) / m
                spots = [e["s1"] - 7.0] + ([e["s1"] - 38.0] if span > 60.0 else [])
                for s in spots:
                    d = _edge_dir(pts, cum, s)
                    for i, code in enumerate(turns):
                        if not code:
                            continue
                        x, z = _edge_point(pts, cum, s, left + (i + 0.5) * wide)
                        if self.paintable(lv, x, z):
                            sym.append({"k": "arrow", "t": code, "x": round(x, 2), "z": round(z, 2),
                                        "d": [round(d[0], 3), round(d[1], 3)], "dk": lv})
            bus = e.get("_bus")
            if bus:
                for i in bus:
                    if not 0 <= i < n:
                        continue
                    edge_off = o + (i - 0.5) * lw
                    if i > 0:
                        run = [_edge_point(pts, cum, s, edge_off) for s in _range(e["s0"] + 1.0, e["s1"] - 1.0, 4.0)]
                        if len(run) >= 2:
                            out.append({"k": "bus", "p": flat(run), "dk": lv})
                    s = e["s0"] + 15.0
                    while s < e["s1"] - 10.0:
                        x, z = _edge_point(pts, cum, s, o + i * lw)
                        d = _edge_dir(pts, cum, s)
                        sym.append({"k": "bus", "x": round(x, 2), "z": round(z, 2), "d": [round(d[0], 3), round(d[1], 3)], "dk": lv})
                        s += 60.0
        self.lane_marks = out
        print(f"roadbed: {sum(1 for m in out if m['k'] == 'stop')} stop lines, "
              f"{sum(1 for m in sym if m['k'] == 'arrow')} turn arrows, {sum(1 for m in out if m['k'] == 'bus')} bus lane lines, "
              f"{sum(1 for m in sym if m['k'] == 'bus')} BUS, {sum(1 for m in sym if m['k'] == 'bike')} bikes")

    # -- hatched areas ------------------------------------------------------------------

    def bake_hatching(self):
        """Hatched no-drive areas: an outline and white stripes, chevrons in long thin ones."""
        out = []
        for h in self.hatch:
            pts = h["p"]
            lv = h["dk"]
            ring = pts + [pts[0]]
            out.append({"k": "edge", "p": flat(ring), "dk": lv})
            a, b = max(zip(ring, ring[1:]), key=lambda e: math.dist(e[0], e[1]))
            ux, uz = _unit(a, b) or (1.0, 0.0)
            vx, vz = -uz, ux
            uv = [((p[0] - a[0]) * ux + (p[1] - a[1]) * uz, (p[0] - a[0]) * vx + (p[1] - a[1]) * vz) for p in pts]
            us = [q[0] for q in uv]
            vs = [q[1] for q in uv]
            chevron = (max(us) - min(us)) > 2.5 * (max(vs) - min(vs))
            vm = (max(vs) + min(vs)) * 0.5
            edges = list(zip(uv, uv[1:] + uv[:1]))
            spacing = 2.2
            for fam in ((1.0, -1.0),) if not chevron else ((1.0, 1.0), (-1.0, -1.0)):
                slope, half = fam
                # v = slope * u - c  (c runs across the area)
                cs = [q[0] * slope - q[1] for q in uv]
                c = min(cs) + spacing * 0.5
                while c < max(cs):
                    xs = []
                    for (u0, v0), (u1, v1) in edges:
                        f0 = slope * u0 - v0 - c
                        f1 = slope * u1 - v1 - c
                        if (f0 > 0) != (f1 > 0):
                            tt = f0 / (f0 - f1)
                            xs.append(u0 + (u1 - u0) * tt)
                    xs.sort()
                    for u0, u1 in zip(xs[0::2], xs[1::2]):
                        if chevron:
                            # Keep this family on its own half: v >= vm (half 1) or v <= vm.
                            ub = (vm + c) / slope
                            if half > 0:
                                u0, u1 = (max(u0, ub), u1) if slope > 0 else (u0, min(u1, ub))
                            else:
                                u0, u1 = (max(u0, ub), u1) if slope < 0 else (u0, min(u1, ub))
                        if u1 - u0 < 0.4:
                            continue
                        p0 = (a[0] + ux * u0 + vx * (slope * u0 - c), a[1] + uz * u0 + vz * (slope * u0 - c))
                        p1 = (a[0] + ux * u1 + vx * (slope * u1 - c), a[1] + uz * u1 + vz * (slope * u1 - c))
                        out.append({"k": "stripe", "p": flat([p0, p1]), "dk": lv})
                    c += spacing
        self.hatching = out

    # -- guard rails and the river's edge --------------------------------------------------

    def bake_guards(self, clip_lines):
        out = []
        for k in self.kerbs:
            if k["dk"] < 0:
                continue
            pts = offset_line(pairs(k["p"]), 0.2)
            if polyline_length(pts) >= 4.0:
                out.append({"p": flat(pts), "dk": k["dk"]})
        mapped = []
        for w in self.ways.values():
            t = w.get("tags", {})
            if t.get("barrier") != "guard_rail":
                continue
            pts = [self.project(*self.nodes[i]) for i in w.get("nodes", []) if i in self.nodes]
            if len(pts) >= 2:
                mapped.append({"p": flat(pts)})
        mapped = clip_lines(mapped, self.rect)
        for m in mapped:
            pts = pairs(m["p"])
            if polyline_length(pts) < 2.0:
                continue
            decks = [self.on_deck(x, z, 0.5) for x, z in pts]
            lv = max(set(decks), key=decks.count)
            out.append({"p": flat(pts), "dk": lv})
        self.guards = out
        print(f"roadbed: guard rails {len(out)} runs ({len(mapped)} mapped), "
              f"{sum(polyline_length(pairs(g['p'])) for g in out) / 1000:.2f} km")

    def bake_shore(self):
        """Where the car would roll into the water: the river's (and ponds') edges, not
        under a bridge, not on the map's rim, not where a road runs."""
        x0, z0, x1, z1 = self.rect
        out = []
        ground = self.allcaps.get(-1)
        for poly in self.water.polys:
            ring = poly + [poly[0]]
            run = []
            for a, b in zip(ring, ring[1:]):
                ln = math.dist(a, b)
                n = max(1, int(math.ceil(ln / 2.0)))
                for k in range(n + 1):
                    x = a[0] + (b[0] - a[0]) * k / n
                    z = a[1] + (b[1] - a[1]) * k / n
                    rim = min(abs(x - x0), abs(x - x1), abs(z - z0), abs(z - z1)) < 1.0
                    bad = rim or self.on_deck(x, z, 6.0) >= 0 or (ground is not None and ground.hit(x, z, 1.0) is not None)
                    if bad:
                        if len(run) >= 2:
                            out.append(run)
                        run = []
                    elif not run or math.dist(run[-1], (x, z)) > 0.05:
                        run.append((x, z))
            if len(run) >= 2:
                out.append(run)
        self.shore = [{"p": flat(simplify(r, 0.3))} for r in out if polyline_length(r) >= 3.0]
        print(f"roadbed: shore walls {len(self.shore)} runs, {sum(polyline_length(pairs(s['p'])) for s in self.shore) / 1000:.1f} km")

    # -- output ----------------------------------------------------------------------------

    def deck_json(self):
        pieces = []
        for pc in self.pieces:
            outer = []
            for k, p in enumerate(pc["pts"]):
                d = _unit(pc["pts"][max(k - 1, 0)], pc["pts"][min(k + 1, len(pc["pts"]) - 1)]) or (1.0, 0.0)
                bits = 0
                for bit, side, reach in ((1, -1.0, pc["l"]), (2, 1.0, pc["r"])):
                    x = p[0] - d[1] * side * (reach + 1.2)
                    z = p[1] + d[0] * side * (reach + 1.2)
                    if self.on_deck(x, z, 0.0) != pc["g"]:
                        bits |= bit
                outer.append(bits)
            pieces.append({"p": flat(pc["pts"]), "h": [round(h, 2) for h in pc["h"]], "l": round(pc["l"], 2),
                           "r": round(pc["r"], 2), "g": pc["g"], "k": pc["kind"], "o": outer})
        return {"pieces": pieces, "groups": self.groups}

    def set_corridors(self):
        """Deck corridors from the measured road widths (a deck holds its road's strip)."""
        for i, k in self.road_piece.items():
            r = self.roads[i]
            pc = self.pieces[k]
            pc["l"] = max(0.5, r["w"] * 0.5 - r["c"] + 0.4)
            pc["r"] = max(0.5, r["w"] * 0.5 + r["c"] + 0.4)


def _range(a, b, step):
    out = []
    s = a
    while s <= b:
        out.append(s)
        s += step
    return out


def _edge_point(pts, cum, s, off):
    for k in range(len(pts) - 1):
        if s <= cum[k + 1] or k == len(pts) - 2:
            seg = cum[k + 1] - cum[k]
            t = 0.0 if seg <= 0 else max(0.0, min(1.0, (s - cum[k]) / seg))
            d = _unit(pts[k], pts[k + 1]) or (1.0, 0.0)
            x = pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t
            z = pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t
            return (x - d[1] * off, z + d[0] * off)
    return pts[-1]


def _edge_dir(pts, cum, s):
    for k in range(len(pts) - 1):
        if s <= cum[k + 1] or k == len(pts) - 2:
            return _unit(pts[k], pts[k + 1]) or (1.0, 0.0)
    return (1.0, 0.0)


def _road_dir(r, x, z):
    pts = pairs(r["p"])
    best = None
    for a, b in zip(pts, pts[1:]):
        d = seg_dist(x, z, a, b)
        if best is None or d < best[0]:
            best = (d, _unit(a, b))
    return best[1] if best else None


def _dedupe(run):
    out = []
    for p in run:
        if not out or math.dist(out[-1], p) > 0.05:
            out.append(p)
    return out


def _at(pts, cum, s):
    for k in range(len(pts) - 1):
        if s <= cum[k + 1] or k == len(pts) - 2:
            seg = cum[k + 1] - cum[k]
            t = 0.0 if seg <= 0 else max(0.0, min(1.0, (s - cum[k]) / seg))
            return (pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t)
    return pts[-1]


def _interp(cum, hs, s):
    if s <= 0:
        return hs[0]
    for k in range(len(cum) - 1):
        if s <= cum[k + 1]:
            seg = cum[k + 1] - cum[k]
            t = 0.0 if seg <= 0 else (s - cum[k]) / seg
            return hs[k] + (hs[k + 1] - hs[k]) * t
    return hs[-1]


def _near(pa, pb, reach):
    xa = [p[0] for p in pa["pts"]]
    za = [p[1] for p in pa["pts"]]
    xb = [p[0] for p in pb["pts"]]
    zb = [p[1] for p in pb["pts"]]
    if min(xa) - reach > max(xb) or min(xb) - reach > max(xa) or min(za) - reach > max(zb) or min(zb) - reach > max(za):
        return False
    for p in pa["pts"][::2]:
        pr = project_onto(pb["pts"], pb["cum"], p[0], p[1])
        if pr and pr[2] < reach * reach:
            return True
    return False
