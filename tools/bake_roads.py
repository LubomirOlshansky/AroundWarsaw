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
CLEAR_FOOT = 2.6     # a footbridge over a footway (loop 3a)
GRADE = 0.06         # ramps up to a clearance
END_GRADE = 0.12     # the steepest a deck may leave the road it starts from
DECK_STEP = 6.0      # deck heights every this many metres

# Loop 3a (docs/DEMO.md 4.4): structure chains (R1), hard clearance (R3).
CHAIN_JOIN = 150.0   # R1 (a): non-bridge ways linking two bridge ways within this are the structure's
EMBANK = 2.0         # R1 (c): a way standing this much above the terrain...
EMBANK_SIDE = (15.0, 20.0, 25.0)   # ...this far to both sides...
EMBANK_SHARE = 0.6   # ...over this share of its length is an embankment
BLUR_REACH = 40.0    # R1 (d): a way steeper than END_GRADE this close to a structure is its approach
NODE_STEP = DECK_STEP  # profile nodes at most this far apart
TARGET_W = 0.01      # how hard an approach way is pulled onto its own terrain (per metre)
SOLVE_ITER = 6000    # projected over-relaxation: sweeps at most...
SOLVE_TOL = 0.001    # ...until no node moves more than this
SOR_W = 1.8
DIP_MAX = 2.0        # R3: the most a road under a deck may dip to get its clearance...
DIP_GRADE = 0.08     # ...with ramps this steep
PIT_SPAN = 20.0      # a dip in a road's terrain narrower than this is a pit to bridge...
PIT_MIN = 0.4        # ...when it is at least this deep...
PIT_PORTAL = 80.0    # ...and not this close to a tunnel's portal (loop 3b: its open ramp's trench)
TUNNEL_COVER = 6.0   # R4: a tunnel runs this far under the terrain...
TUNNEL_GRADE = 0.08  # ...its portal ramps no steeper than this
BLUR_FREE = 30.0     # within this of a bridge way the terrain only bounds an approach from below
BESIDE_REACH = 6.0   # a footway or tram track this far past a road deck's edge is held to its height
STAIR_GRADE = 0.5    # a footbridge meets the ground by stairs: its ends may be this steep
TARGET_DECK = 0.5    # R2: how hard a measured deck height pulls (per node)
DECK_OBS = 2.0       # R2 (loop 3b): the surface model sampled every this many metres along a deck...
DECK_PCT = 0.3       # ...this percentile across the carriageway (the deck is the low envelope)...
DECK_STRUCT = 2.0    # ...from cells this far over the bare earth (a structure)...
DECK_GRADE = 0.06    # ...smoothed to this grade...
DECK_BAND = 1.0      # ...within this of the measured heights
R2_FAMILIES = ("road", "rail")   # R2: measured where these are solved (footbridges and tram tracks
                                 # follow the road deck beside them; the surface model over a footbridge
                                 # often sees the viaduct above it)
PIN_FADE = 40.0      # R2: the measured deck pulls in full this far from a pin, less nearer (squared)
DECK_OPEN = 6.0      # R2: spikes narrower than twice this (a pylon, a gantry) are opened away
PILLAR_AREA = 12.0   # R2: a mapped building this small under a road deck is one of its pillars...
PILLAR_SLAB = 1.3 + 0.08 + 0.05   # ...and the deck's surface stands this far over its top (the slab)
SURFACE_BASE = 100.0  # R2: the surface model's heights minus this are the map's (bake_gugik BASE_HEIGHT)

SPIRAL_LANES = 3     # loop 3b-2: a roundabout ring with this many lanes or more...
SPIRAL_RADIUS = 25.0  # ...and at least this big (Rondo Dmowskiego) gets spiral lane lines
SPIRAL_EXIT_MERGE = 15.0  # exits closer than this along the ring are one
SPIRAL_HOLD = 0.35   # the share of each gap between exits a lane line keeps its lane before sweeping out
HATCH_FLOW_REACH = 15.0   # loop 3b-2: roads this close to a hatched area tell its traffic's way
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

    # -- R2 inputs (loop 3b) ------------------------------------------------------------

    def set_trees(self, trees3d):
        """The scanned trees (trees3d: x, z, top, radius, base, kind per tree), for the
        surface model: a deck sample under a crown is a tree, not the deck."""
        self.crowns = Grid(16.0)
        for k in range(0, len(trees3d) - 5, 6):
            x, z, r = trees3d[k], trees3d[k + 1], trees3d[k + 3]
            self.crowns.add((x, z, r), x - r, z - r, x + r, z + r)

    def under_crown(self, x, z):
        for tx, tz, r in getattr(self, "crowns", Grid()).at(x, z):
            if (x - tx) ** 2 + (z - tz) ** 2 < r * r:
                return True
        return False

    def set_pillars(self, buildings):
        """R2: small mapped buildings (under PILLAR_AREA m2) with a height: a deck over one
        rests on it (`_solve` takes its top + the slab as the deck's lower bound there)."""
        self.pillars = Grid(32.0)
        for b in buildings:
            q = pairs(b["p"])
            if len(q) < 3 or b.get("br") or b["h"] <= b["mh"] or abs(ring_area(q)) > PILLAR_AREA:
                continue
            g = min(self.terrain.h(x, z) for x, z in q)
            cx, cz = sum(p[0] for p in q) / len(q), sum(p[1] for p in q) / len(q)
            self.pillars.add((cx, cz, g + b["h"]), cx, cz, cx, cz)

    # -- bridge decks ----------------------------------------------------------------

    def solve_decks(self):
        """Loop 3a (R1, R3): height profiles for every structure, solved as chains.

        A structure is its bridge ways plus the non-bridge ways that belong to it
        (`_members`: the abutments between two bridges, embankments, and the approach
        ways where the 10 m terrain grid blurs the abutment into a dip). Each family
        (rails, then roads) is solved as one graph of nodes every 6 m (`_solve`): smooth,
        never under the terrain, pinned only where a structure meets an ordinary way,
        the approaches pulled onto their own terrain, and the clearance over what runs
        under (5 m over roads, rails and trams, 7.5 m over water) a hard minimum. Where
        the clearance can't be met within END_GRADE of a pin, the road underneath dips
        (`dips`, up to DIP_MAX at DIP_GRADE, logged); anything beyond that fails the bake.
        Footways and tram tracks on a structure take the height of the road deck beside
        them; those with no road beside them (footbridges) are solved like the roads."""
        T = self.terrain
        roads = self.roads
        self.surface_model = SurfaceModel.load(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "raw", "demo", "gugik"))

        # What runs under: ground roads, trams and rails, and the structures below.
        under = Grid(32.0)
        for r in roads:
            for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                under.add((a, b, r["w"] * 0.5, "road", r), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for t in self.trams:
            for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                under.add((a, b, 1.5, "tram", t), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for t in self.details.get("rails", []):
            for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                under.add((a, b, 2.0, "rail", t), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        self.under = under
        # Footways run under footbridges too (2.6 m: check_roads C3 wants 2.5).
        self.under_foot = Grid(32.0)
        for t in self.paths:
            if t["k"] in ("foot", "cycle"):
                for a, b in zip(pairs(t["p"]), pairs(t["p"])[1:]):
                    self.under_foot.add((a, b, float(t.get("w", 2.0)) * 0.5, "footway", t),
                                        min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))

        rails = self.details.get("rails", [])
        road_mem = self._members(roads, lambda r: r["bridge"], "road")
        rail_mem = self._members(rails, lambda t: t.get("_br"), "rail")
        tram_mem = self._members(self.trams, lambda t: t.get("_br"), "tram")
        path_ok = [p["k"] in ("foot", "cycle") for p in self.paths]
        path_mem = self._members(self.paths, lambda p: p.get("_br"), "path", usable=path_ok)
        for items, mem in ((roads, road_mem), (rails, rail_mem), (self.trams, tram_mem), (self.paths, path_mem)):
            for it, why in zip(items, mem):
                if why:
                    it["_on"] = why   # "bridge", or why a non-bridge way is part of a structure
        self.dips = []
        self.profiles = {}   # id(item) -> (pts, cum, heights) once solved
        self.pieces = []     # {"pts", "cum", "h", "l", "r", "ly", "g", "kind", "a"}
        self.road_piece = {}
        self._solve(rails, rail_mem, "rail", 2.2)
        self._solve(roads, road_mem, "road", None)
        for i, r in enumerate(roads):
            if road_mem[i]:
                pts, cum, hs = self.profiles[id(r)]
                self.road_piece[i] = len(self.pieces)
                self.pieces.append({"pts": pts, "cum": cum, "h": hs, "l": r["w"] * 0.5 + 0.5, "r": r["w"] * 0.5 + 0.5,
                                    "ly": r["_sly"], "kind": "road", "road": i, "a": road_mem[i] != "bridge"})
        for i, t in enumerate(rails):
            if rail_mem[i]:
                pts, cum, hs = self.profiles[id(t)]
                t["_piece"] = len(self.pieces)
                self.pieces.append({"pts": pts, "cum": cum, "h": hs, "l": 2.2, "r": 2.2, "ly": t["_sly"], "kind": "rail",
                                    "item": t, "a": rail_mem[i] != "bridge"})

        # Footways and tram tracks on a structure: held to the road deck beside them where
        # there is one, solved like the roads elsewhere (footbridges, ramps down to the street).
        road_pieces = [pc for pc in self.pieces if pc["kind"] == "road"]
        # A short footbridge with no road deck near it (a park's little bridge over a pond)
        # stays on the ground, as before loop 3a: a deck there would open the pond's edge.
        near_road = Grid(32.0)
        for pc in road_pieces:
            xs = [p[0] for p in pc["pts"]]
            zs = [p[1] for p in pc["pts"]]
            near_road.add(1, min(xs) - 12, min(zs) - 12, max(xs) + 12, max(zs) + 12)
        for i, it in enumerate(self.paths):
            if path_mem[i] == "bridge" and polyline_length(pairs(it["p"])) <= 30.0 and \
                    not any(near_road.at(*q) for q in pairs(it["p"])):
                path_mem[i] = ""
                it.pop("_on", None)
        for kind, items, mem, half in (("tram", self.trams, tram_mem, 1.6), ("path", self.paths, path_mem, None)):
            self._solve(items, mem, kind, half, beside=road_pieces)
            for idx, it in enumerate(items):
                if mem[idx]:
                    pts, cum, hs = self.profiles[id(it)]
                    hw = half if half is not None else float(it.get("w", 2.0)) * 0.5 + 0.3
                    it["_piece"] = len(self.pieces)
                    self.pieces.append({"pts": pts, "cum": cum, "h": hs, "l": hw, "r": hw, "ly": it["_sly"], "kind": kind,
                                        "item": it, "a": mem[idx] != "bridge"})

        # An approach (a structure way not tagged bridge: an abutment, an embankment, the way
        # onto a bridge across the grid's blur) is no deck: it corrects the ground under its
        # corridor (`fills`), so whatever lies on the ground there (the road, its kerbs and
        # markings, the carriageway areas, the lanes, the car) sees the right height. Only the
        # bridges are decks.
        self.fills = [pc for pc in self.pieces if pc["a"]]
        self.pieces = [pc for pc in self.pieces if not pc["a"]]
        self.road_piece = {pc["road"]: k for k, pc in enumerate(self.pieces) if "road" in pc}
        self.road_fill = {pc["road"]: pc for pc in self.fills if "road" in pc}
        for it_list in (self.paths, self.trams, self.details.get("rails", [])):
            for it in it_list:
                it.pop("_piece", None)

        # Groups: the pieces of one structure on one level (same layer, within 30 m of
        # each other); a piece that runs under another stays out of its group.
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
                if _near(pa, pb, 30.0) and not _stacked(pa, pb):
                    parent[find(a)] = find(b)
        roots = {}
        for k, pc in enumerate(self.pieces):
            pc["g"] = roots.setdefault(find(k), len(roots))
        self.groups = len(roots)
        for pc in self.pieces:
            if "item" in pc:
                pc["item"]["dk"] = pc["g"]
        for i, k in self.road_piece.items():
            roads[i]["dk"] = self.pieces[k]["g"]
        self.piece_grid = Grid(32.0)
        for k, pc in enumerate(self.pieces):
            xs = [p[0] for p in pc["pts"]]
            zs = [p[1] for p in pc["pts"]]
            self.piece_grid.add(k, min(xs) - 25, min(zs) - 25, max(xs) + 25, max(zs) + 25)
        tall = max((max(h - T.h(*p) for p, h in zip(pc["pts"], pc["h"])) for pc in self.pieces), default=0.0)
        n_br = sum(1 for m in road_mem if m == "bridge")
        whys = {}
        for mem in (road_mem, rail_mem, tram_mem, path_mem):
            for m in mem:
                if m and m != "bridge":
                    whys[m] = whys.get(m, 0) + 1
        print(f"decks: {len(self.pieces)} pieces in {self.groups} structures ({n_br} bridge roads), highest "
              f"{tall:.1f} m over the ground; {len(self.fills)} approaches on the ground (fills: "
              f"{len(self.road_fill)} roads, {sum(1 for f in self.fills if f['kind'] == 'rail')} rail ways); "
              f"profile solve {self.solve_sweeps} sweeps")
        print("decks: structure members not tagged bridge: " + ", ".join(f"{k} {v}" for k, v in sorted(whys.items())))
        for d in self.dips:
            print(f"decks: underpass dip {d['d']:.2f} m on {d['name']} at ({d['x']:.0f}, {d['z']:.0f}) under {d['over']}")
        if self.surface_model is None:
            print("decks: no surface model (data/raw/demo/gugik/nmpt05 + nmt1): chain solver alone (R2 fallback)")
        else:
            print("decks: R2 measured decks followed: " + ", ".join(f"{k} {v}" for k, v in sorted(getattr(self, "measured", {}).items()))
                  + f"; {getattr(self, 'pillar_bounds', 0)} mapped pillars under road decks (lower bounds where not measured)")

    # -- pits (loop 3a, C1) ----------------------------------------------------------------

    def fill_pits(self):
        """Loop 3a: the bare-earth grid holds narrow pits a street crosses at grade (stairwells
        to an underpass or the metro, garage and construction pits, a ditch): following them,
        a road dips 1-3 m in a few metres (C1 found Złota at 30 %, Rondo Dmowskiego at 13 %).
        Along every road on the ground, the profile is closed over PIT_SPAN (the dips narrower
        than that bridged, the humps kept); where it stands PIT_MIN or more above the grid,
        that stretch becomes a fill like an approach's."""
        T = self.terrain
        on_structure = set(self.road_piece) | set(self.road_fill)
        n0 = len(self.fills)
        half = PIT_SPAN * 0.5
        # A fill corrects the ground under its corridor only: where another way enters it (a
        # junction, a structure's end) that way would step onto it, so pits there stay.
        others = Grid(16.0)
        for i, r in enumerate(self.roads):
            for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                others.add((a, b, i), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
        for pc in self.pieces + self.fills:
            for a, b in zip(pc["pts"], pc["pts"][1:]):
                others.add((a, b, -1), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))

        def crowded(pts, i, reach):
            for p in pts:
                for dx in (-reach, 0.0, reach):
                    for dz in (-reach, 0.0, reach):
                        for a, b, o in others.at(p[0] + dx, p[1] + dz):
                            if o != i and seg_dist(p[0], p[1], a, b) < reach:
                                return True
            return False
        for i, r in enumerate(self.roads):
            if i in on_structure:
                continue
            pts = resample(pairs(r["p"]), 2.0)
            if len(pts) < 4:
                continue
            cum = _cum(pts)
            hs = [T.h(*p) for p in pts]
            n = len(pts)
            up = [max(hs[j] for j in range(n) if abs(cum[j] - cum[k]) <= half) for k in range(n)]
            closed = [min(up[j] for j in range(n) if abs(cum[j] - cum[k]) <= half) for k in range(n)]
            k = 0
            while k < n:
                if closed[k] - hs[k] < PIT_MIN:
                    k += 1
                    continue
                a = k
                while a > 0 and closed[a - 1] - hs[a - 1] > 0.02:
                    a -= 1
                b = k
                while b < n - 1 and closed[b + 1] - hs[b + 1] > 0.02:
                    b += 1
                a, b = max(a - 1, 0), min(b + 1, n - 1)
                # Loop 3b: not in a tunnel's open ramp (the trench before a portal is real).
                near_portal = any(math.hypot(q[0] - po[0], q[1] - po[1]) < PIT_PORTAL
                                  for q in pts[a:b + 1] for po in getattr(self, "portals", []))
                if b > a and not near_portal and not crowded(pts[a:b + 1], i, r["w"] * 0.5 + 2.5):
                    self.fills.append({"pts": pts[a:b + 1], "cum": _cum(pts[a:b + 1]), "h": [max(c, h) for c, h in
                                       zip(closed[a:b + 1], hs[a:b + 1])], "l": r["w"] * 0.5 + 0.5,
                                       "r": r["w"] * 0.5 + 0.5, "kind": "road", "road": i, "a": True, "pit": True})
                k = b + 1
        print(f"pits: {len(self.fills) - n0} stretches of road across a pit in the terrain grid filled")

    # -- tunnels (R4) -------------------------------------------------------------------

    def solve_tunnels(self, tunnel_roads):
        """Loop 3a (R4): drivable tunnels as tunnel pieces. A tunnel lies TUNNEL_COVER under
        the terrain, its ramps no steeper than TUNNEL_GRADE from the portals (where it meets an
        open road: pinned there); a tunnel crossing the map's edge is free there. One group
        per connected tunnel ("tn" on the tunnel roads and the lane graph's edges); the
        portals are written for loop 3b (which builds the tunnels and their look)."""
        T = self.terrain
        x0, z0, x1, z1 = self.rect
        open_v = set()
        for r in self.roads:
            for q in pairs(r["p"]):
                open_v.add(_key(q))
        verts = {}
        for i, r in enumerate(tunnel_roads):
            for q in pairs(r["p"]):
                verts.setdefault(_key(q), set()).add(i)
        # Connected tunnels: one group each.
        parent = list(range(len(tunnel_roads)))

        def find(a):
            while parent[a] != a:
                parent[a] = parent[parent[a]]
                a = parent[a]
            return a
        for vs in verts.values():
            vs = sorted(vs)
            for o in vs[1:]:
                parent[find(o)] = find(vs[0])
        groups = {}
        for i in range(len(tunnel_roads)):
            groups.setdefault(find(i), []).append(i)
        self.tunnel_pieces = []
        self.portals = []
        for g, members in enumerate(groups.values()):
            # Nodes every NODE_STEP, portal pins, then the deepest the ramps allow.
            nodes, nbr, pins = {}, {}, {}
            per_item = {}
            for i in members:
                pts = resample(pairs(tunnel_roads[i]["p"]), NODE_STEP)
                ids = []
                for k, q in enumerate(pts):
                    key = _key(q)
                    nodes.setdefault(key, q)
                    ids.append(key)
                for a, b in zip(ids, ids[1:]):
                    d = math.dist(nodes[a], nodes[b])
                    nbr.setdefault(a, []).append((b, d))
                    nbr.setdefault(b, []).append((a, d))
                per_item[i] = (pts, ids)
                for key in (ids[0], ids[-1]):
                    q = nodes[key]
                    if key in open_v:
                        pins[key] = T.h(*q)
                        self.portals.append([round(q[0], 1), round(q[1], 1), g])
            import heapq
            ramp = {key: -1e9 for key in nodes}
            heap = [(-h, key) for key, h in pins.items()]
            for key, h in pins.items():
                ramp[key] = h
            heapq.heapify(heap)
            while heap:
                nh, key = heapq.heappop(heap)
                h = -nh
                if h < ramp[key]:
                    continue
                for o, d in nbr.get(key, ()):
                    v = h - TUNNEL_GRADE * d
                    if v > ramp[o]:
                        ramp[o] = v
                        heapq.heappush(heap, (-v, o))
            for i, (pts, ids) in per_item.items():
                hs = []
                for q, key in zip(pts, ids):
                    deep = T.h(*q) - TUNNEL_COVER
                    hs.append(pins[key] if key in pins else max(deep, ramp[key]) if ramp[key] > -1e8 else deep)
                r = tunnel_roads[i]
                r["tn"] = g
                self.tunnel_pieces.append({"pts": pts, "h": hs, "l": r["w"] * 0.5 + 0.5, "r": r["w"] * 0.5 + 0.5, "g": g})
        if tunnel_roads:
            print(f"tunnels: {len(tunnel_roads)} ways in {len(groups)} tunnels, {len(self.portals)} portals; deepest "
                  f"{max(T.h(*q) - h for pc in self.tunnel_pieces for q, h in zip(pc['pts'], pc['h'])):.1f} m under the terrain")

    def tunnel_json(self, tunnel_roads):
        pieces = [{"p": flat(pc["pts"]), "h": [round(h, 2) for h in pc["h"]], "l": round(pc["l"], 2),
                   "r": round(pc["r"], 2), "g": pc["g"], "k": "road"} for pc in getattr(self, "tunnel_pieces", [])]
        roads = [{k: v for k, v in r.items() if not k.startswith("_")} for r in tunnel_roads]
        return {"pieces": pieces, "roads": roads, "portals": getattr(self, "portals", [])}

    # -- structure membership (R1) ----------------------------------------------------

    def _members(self, items, is_bridge, family, usable=None):
        """Per item: "bridge", the reason a non-bridge way belongs to a structure, or "".

        R1: a non-bridge way joins a structure when it (a) links two bridge ways within
        CHAIN_JOIN (the abutment between a viaduct and a river span), (b) is tagged
        embankment=yes, (c) stands EMBANK above the terrain 15-25 m to both sides over most
        of its length (an embankment the terrain grid shows), or (d) touches the structure
        where its own terrain, within BLUR_REACH, is steeper than END_GRADE: the 10 m grid
        blurs the abutment's wall into a slope, so the way's real level is the structure's."""
        T = self.terrain
        n = len(items)
        usable = usable or [True] * n
        pts_of = [pairs(it["p"]) for it in items]
        length = [polyline_length(p) for p in pts_of]
        ends, verts = {}, {}
        for i, p in enumerate(pts_of):
            if not usable[i] or len(p) < 2:
                continue
            for q in p:
                verts.setdefault(_key(q), set()).add(i)
            ends.setdefault(_key(p[0]), []).append((i, 0))
            ends.setdefault(_key(p[-1]), []).append((i, 1))
        bridge = [bool(usable[i] and is_bridge(it)) for i, it in enumerate(items)]
        why = ["bridge" if b else "" for b in bridge]
        if not any(bridge):
            return why
        # (a) between two bridge ways.
        for i in range(n):
            if not bridge[i]:
                continue
            for p in (pts_of[i][0], pts_of[i][-1]):
                stack = [(_key(p), 0.0, [])]
                while stack:
                    v, dist, path = stack.pop()
                    for j, ej in ends.get(v, ()):
                        if bridge[j] or j in path:
                            continue
                        d2 = dist + length[j]
                        if d2 > CHAIN_JOIN:
                            continue
                        other = _key(pts_of[j][-1] if ej == 0 else pts_of[j][0])
                        if any(bridge[b] and b != i for b in verts.get(other, ())):
                            for q in path + [j]:
                                why[q] = why[q] or "between two bridges"
                        elif len(path) < 5:
                            stack.append((other, d2, path + [j]))
        # (b) tagged.
        for i, it in enumerate(items):
            if usable[i] and not why[i] and it.get("_t", {}).get("embankment") == "yes":
                why[i] = "embankment=yes"
        # (c), (d): grow from the structures.
        for _ in range(12):
            grew = False
            for j in range(n):
                if why[j] or not usable[j] or len(pts_of[j]) < 2:
                    continue
                touch = [q for q in pts_of[j] if any(why[o] and o != j for o in verts.get(_key(q), ()))]
                if not touch:
                    continue
                if self._embankment(pts_of[j]):
                    why[j] = "embankment"
                elif self._blurred(pts_of[j], touch):
                    why[j] = "blurred abutment"
                else:
                    continue
                grew = True
            if not grew:
                break
        return why

    def _embankment(self, pts):
        T = self.terrain
        ps = resample(pts, 6.0)
        if polyline_length(pts) < 8.0:
            return False
        high = total = 0
        for k in range(len(ps)):
            a, b = ps[max(k - 1, 0)], ps[min(k + 1, len(ps) - 1)]
            d = _unit(a, b)
            if d is None:
                continue
            x, z = ps[k]
            nx, nz = -d[1], d[0]
            left = min(T.h(x + nx * o, z + nz * o) for o in EMBANK_SIDE)
            right = min(T.h(x - nx * o, z - nz * o) for o in EMBANK_SIDE)
            total += 1
            if T.h(x, z) - max(left, right) > EMBANK:
                high += 1
        return total > 0 and high >= EMBANK_SHARE * total

    def _blurred(self, pts, touch):
        T = self.terrain
        ps = resample(pts, 2.0)
        cum = _cum(ps)
        hs = [T.h(*p) for p in ps]
        for t in touch:
            s0 = project_onto(ps, cum, *t)[0]
            for k in range(len(ps)):
                if abs(cum[k] - s0) > BLUR_REACH:
                    continue
                j = k
                while j < len(ps) - 1 and cum[j] - cum[k] < 6.0:
                    j += 1
                run = cum[j] - cum[k]
                if run >= 5.5 and abs(cum[j] - s0) <= BLUR_REACH and abs(hs[j] - hs[k]) / run > END_GRADE:
                    return True
        return False

    # -- the profile solver (R1, R3) -----------------------------------------------------

    def _solve(self, items, member, family, half_w, beside=None):
        """Heights for the member items of one family, as one graph per family: nodes
        every NODE_STEP metres (and at every crossing), smoothness between neighbours,
        approach ways pulled onto their terrain (TARGET_W), hard lower bounds (the terrain,
        the clearance over what runs under, the water), pins where a structure meets an
        ordinary way of its family. Projected over-relaxation, then the R3 check."""
        T = self.terrain
        x0, z0, x1, z1 = self.rect
        idx = [i for i, m in enumerate(member) if m]
        if not idx:
            return
        verts = {}
        for i, it in enumerate(items):
            for q in pairs(it["p"]):
                verts.setdefault(_key(q), set()).add(i)
        # The structure's layer (for grouping): its bridge ways' layer, given to its approaches.
        comp = {i: i for i in idx}

        def cfind(a):
            while comp[a] != a:
                comp[a] = comp[comp[a]]
                a = comp[a]
            return a
        for i in idx:
            for q in pairs(items[i]["p"]):
                for o in verts.get(_key(q), ()):
                    if o in comp and o != i:
                        comp[cfind(o)] = cfind(i)
        comp_ly = {}
        for i in idx:
            if member[i] == "bridge":
                c = cfind(i)
                comp_ly[c] = min(comp_ly.get(c, 99), items[i].get("_ly", 1) or 1)
        for i in idx:
            items[i]["_sly"] = comp_ly.get(cfind(i), 1) if member[i] != "bridge" else (items[i].get("_ly", 1) or 1)

        # Crossings with what runs under (positions along each member item).
        cross = {i: [] for i in idx}
        for i in idx:
            it = items[i]
            pts = pairs(it["p"])
            cum = _cum(pts)
            ly = it.get("_ly", 1 if member[i] == "bridge" else 0)
            xs = [p[0] for p in pts]
            zs = [p[1] for p in pts]
            unders = self.under.box(min(xs), min(zs), max(xs), max(zs))
            if family == "path":
                unders = unders + self.under_foot.box(min(xs), min(zs), max(xs), max(zs))
            for a, b, half, kind, other in unders:
                if other is it:
                    continue
                if (other.get("_ly") or 0) >= ly:
                    continue  # level with it (an at-grade crossing) or over it: not under
                if (other.get("_ly") or 0) < 0:
                    # A cutting (layer < 0, e.g. the WKD line by Centralna): its real level is
                    # below what the 10 m terrain grid shows, so its clearance can't be judged
                    # here (logged; check_roads C3 lists it, the allowlist says why).
                    self.cuttings_under = getattr(self, "cuttings_under", 0) + 1
                    continue
                for k in range(len(pts) - 1):
                    hit = seg_cross(pts[k], pts[k + 1], a, b)
                    if hit is None:
                        continue
                    s = cum[k] + hit[0] * (cum[k + 1] - cum[k])
                    if s < 1.0 or s > cum[-1] - 1.0:
                        continue  # meeting at the end, not passing under
                    px = a[0] + (b[0] - a[0]) * hit[1]
                    pz = a[1] + (b[1] - a[1]) * hit[1]
                    d1 = _unit(pts[k], pts[k + 1])
                    d2 = _unit(a, b)
                    sin = abs(d1[0] * d2[1] - d1[1] * d2[0]) if d1 and d2 else 1.0
                    reach = half / max(sin, 0.25) + 1.5
                    cross[i].append({"s": s, "reach": reach, "x": px, "z": pz, "other": other, "kind": kind,
                                     "clear": CLEAR_FOOT if kind == "footway" else CLEAR_ROAD})

        # Nodes.
        node_of = {}
        X, Z, TH, LB, PIN, W = [], [], [], [], [], []
        nbr = []
        coupled = []   # node -> [(other node, clearance)] (a structure under a structure)
        item_nodes = {}

        def node(p, key):
            if key in node_of:
                return node_of[key]
            k = len(X)
            node_of[key] = k
            X.append(p[0])
            Z.append(p[1])
            h = T.h(*p)
            TH.append(h)
            LB.append(h)
            PIN.append(None)
            W.append(0.0)
            nbr.append([])
            coupled.append([])
            return k

        for i in idx:
            pts = pairs(items[i]["p"])
            cum = _cum(pts)
            extra = sorted({c["s"] + d for c in cross[i] for d in (-c["reach"], 0.0, c["reach"])
                            if 0.5 < c["s"] + d < cum[-1] - 0.5})
            ps, ss, keys = [], [], []
            orig = {_key(q) for q in pts}
            for k in range(len(pts) - 1):
                seg = cum[k + 1] - cum[k]
                marks = [cum[k]] + [s for s in extra if cum[k] < s < cum[k + 1]]
                n = max(1, int(math.ceil(seg / NODE_STEP)))
                marks += [cum[k] + seg * q / n for q in range(1, n)]
                for s in sorted(set(round(m, 3) for m in marks)):
                    if ss and s - ss[-1] < 0.3:
                        continue
                    ps.append(_at(pts, cum, s))
                    ss.append(s)
            ps.append(pts[-1])
            ss.append(cum[-1])
            ids = []
            for k, (p, s) in enumerate(zip(ps, ss)):
                kk = _key(p)
                ids.append(node(p, kk if kk in orig else (i, k)))
            item_nodes[i] = (ps, ss, ids)
            approach = member[i] != "bridge"
            for k in range(len(ids) - 1):
                a, b = ids[k], ids[k + 1]
                if a == b:
                    continue
                d = max(ss[k + 1] - ss[k], 0.3)
                nbr[a].append((b, 1.0 / d))
                nbr[b].append((a, 1.0 / d))
                if approach:
                    W[a] += TARGET_W * d * 0.5
                    W[b] += TARGET_W * d * 0.5
        # The terrain is no guide near a bridge's end (the grid blurs the abutment): no pull
        # onto it within BLUR_FREE of a bridge way, only the lower bound.
        import heapq
        near = [1e9] * len(X)
        heap = []
        for i in idx:
            if member[i] == "bridge":
                for k in item_nodes[i][2]:
                    near[k] = 0.0
                    heap.append((0.0, k))
        heapq.heapify(heap)
        while heap:
            d, k = heapq.heappop(heap)
            if d > near[k] or d > BLUR_FREE:
                continue
            for o, w in nbr[k]:
                nd = d + 1.0 / w
                if nd < near[o]:
                    near[o] = nd
                    heapq.heappush(heap, (nd, o))
        for k in range(len(X)):
            if near[k] <= BLUR_FREE:
                W[k] = 0.0
        # Lower bounds: water, clearance; targets: the surface model (R2) where it has the deck.
        member_ids = {id(items[i]): i for i in idx}
        sm = self.surface_model
        measured = getattr(self, "measured", {})
        self.measured = measured
        # How far each node is from a pin along the structure (the measured deck is faded in
        # over PIN_FADE from a pin: pins stay at the 10 m grid's value so the joints with the
        # ordinary streets stay exact, and a ramp, not a step, takes the deck to its height).
        pin_dist = [1e9] * len(X)
        if sm is not None and family in R2_FAMILIES:
            heap = []
            for i in idx:
                ps, ss, ids = item_nodes[i]
                for q in pairs(items[i]["p"]):
                    others = verts.get(_key(q), set()) - {i}
                    if any(not member[o] for o in others) or not others:
                        k = node_of[_key(q)]
                        pin_dist[k] = 0.0
                        heap.append((0.0, k))
            heapq.heapify(heap)
            while heap:
                dd, k = heapq.heappop(heap)
                if dd > pin_dist[k] or dd > PIN_FADE:
                    continue
                for o, w in nbr[k]:
                    nd = dd + 1.0 / w
                    if nd < pin_dist[o]:
                        pin_dist[o] = nd
                        heapq.heappush(heap, (nd, o))
        seen_nodes = set()
        for i in idx:
            if sm is not None and member[i] == "bridge" and family in R2_FAMILIES:
                # R2 (loop 3b): each node follows the deck measured along it (TARGET_DECK), where seen.
                ps, ss, ids = item_nodes[i]
                prof = sm.deck_profile(pairs(items[i]["p"]), _cum(pairs(items[i]["p"])),
                                       half_w or items[i].get("w", 4.0) * 0.5, self.under_crown)
                if prof:
                    measured[family] = measured.get(family, 0) + 1
                    obs_s = [q[0] for q in prof]
                    for s_node, k in zip(ss, ids):
                        j = min(range(len(obs_s)), key=lambda q: abs(obs_s[q] - s_node))
                        if abs(obs_s[j] - s_node) > DECK_OBS * 1.5:
                            continue
                        TH[k] = _interp(obs_s, [q[1] for q in prof], s_node) - SURFACE_BASE
                        W[k] = max(W[k], 0.0) + TARGET_DECK * min(1.0, pin_dist[k] / PIN_FADE) ** 2
                        seen_nodes.add(k)
        # R2 (loop 3b): a road deck stands on its mapped pillars (the Jana Pawła II viaduct's
        # 48: small OpenStreetMap buildings under it): its slab never lower than their tops,
        # where the surface model hasn't measured it (where it has, the measurement wins and
        # bake_structures.py fits the pillars to the slab).
        if family == "road" and getattr(self, "pillars", None):
            for i in idx:
                if member[i] != "bridge":
                    continue
                ps, ss, ids = item_nodes[i]
                half = items[i].get("w", 4.0) * 0.5 + 1.0
                for px, pz, top in self.pillars.box(*_bbox(ps, half)):
                    best = None
                    for p, k in zip(ps, ids):
                        dd = math.hypot(p[0] - px, p[1] - pz)
                        if best is None or dd < best[0]:
                            best = (dd, k)
                    if best is not None and best[0] <= max(half, NODE_STEP * 0.6):
                        # The nodes over the pillar and one step either side (a level bearing, not a kink).
                        for p, k in zip(ps, ids):
                            if math.hypot(p[0] - px, p[1] - pz) <= NODE_STEP * 1.1 and k not in seen_nodes:
                                LB[k] = max(LB[k], top + PILLAR_SLAB)
                        self.pillar_bounds = getattr(self, "pillar_bounds", 0) + 1
        for i in idx:
            ps, ss, ids = item_nodes[i]
            for p, k in zip(ps, ids):
                if self.water.hit(*p) >= 0:
                    LB[k] = max(LB[k], T.h(*p) + CLEAR_WATER)
            for c in cross[i]:
                other = c["other"]
                if id(other) in self.profiles:
                    opts, ocum, oh = self.profiles[id(other)]
                    lower = _interp(ocum, oh, project_onto(opts, ocum, c["x"], c["z"])[0])
                    onode = None
                elif id(other) in member_ids and family == "path":
                    continue  # footbridges over footbridges (the science centre's roof ramps): left as mapped
                elif id(other) in member_ids:
                    lower = None
                    ops, oss, oids = item_nodes[member_ids[id(other)]]
                    onode = min(oids, key=lambda q: (X[q] - c["x"]) ** 2 + (Z[q] - c["z"]) ** 2)
                else:
                    lower = T.h(c["x"], c["z"])
                    onode = None
                for s, k in zip(ss, ids):
                    if abs(s - c["s"]) <= c["reach"] + 0.01:
                        if onode is not None:
                            coupled[k].append((onode, c["clear"]))
                        else:
                            LB[k] = max(LB[k], lower + c["clear"])
                            c.setdefault("nodes", []).append(k)
                c["lower"] = lower
        # Pins: where a member meets an ordinary way of its family; lone ends; not the rim.
        for i in idx:
            ps, ss, ids = item_nodes[i]
            pts = pairs(items[i]["p"])
            for q in pts:
                k = node_of[_key(q)]
                others = verts.get(_key(q), set()) - {i}
                for o in others:
                    if member[o]:
                        continue
                    if id(items[o]) in self.profiles:   # a way already on a deck: meet it there
                        opts, ocum, oh = self.profiles[id(items[o])]
                        PIN[k] = _interp(ocum, oh, project_onto(opts, ocum, q[0], q[1])[0])
                    else:
                        PIN[k] = T.h(*q)
            for q in (pts[0], pts[-1]):
                k = node_of[_key(q)]
                others = verts.get(_key(q), set()) - {i}
                rim = min(abs(q[0] - x0), abs(q[0] - x1), abs(q[1] - z0), abs(q[1] - z1)) < 0.5
                stairs = family == "path" and any(math.dist(q, v) < 1.5 for v in self._stair_ends(q))
                if not others and not rim and not stairs:
                    PIN[k] = TH[k]
        # Beside a road deck (footways, tram tracks): held to its height; the layer is the deck's.
        if beside:
            grid = Grid(32.0)
            for q, pc in enumerate(beside):
                xs = [p[0] for p in pc["pts"]]
                zs = [p[1] for p in pc["pts"]]
                grid.add(q, min(xs) - BESIDE_REACH - pc["l"], min(zs) - BESIDE_REACH - pc["l"],
                         max(xs) + BESIDE_REACH + pc["r"], max(zs) + BESIDE_REACH + pc["r"])
            for i in idx:
                ps, ss, ids = item_nodes[i]
                lys = {}
                for p, k in zip(ps, ids):
                    best = None
                    for q in grid.at(*p):
                        pc = beside[q]
                        if member[i] == "bridge" and family != "tram" and pc["ly"] != (items[i].get("_ly") or 1):
                            continue
                        pr = project_onto(pc["pts"], pc["cum"], p[0], p[1])
                        if pr is None or pr[0] <= 0.01 or pr[0] >= pc["cum"][-1] - 0.01:
                            continue
                        if abs(pr[1]) <= (pc["r"] if pr[1] > 0 else pc["l"]) + BESIDE_REACH and (best is None or pr[2] < best[0]):
                            best = (pr[2], _interp(pc["cum"], pc["h"], pr[0]), pc["ly"])
                    if best is not None:
                        PIN[k] = best[1]
                        lys[best[2]] = lys.get(best[2], 0) + 1
                if lys:
                    items[i]["_sly"] = max(lys, key=lys.get)
        # A pin that is itself under a clearance (the ways meet right under a deck) can't move.
        n_nodes = len(X)
        H = self._relax(X, Z, TH, LB, PIN, W, nbr, coupled, item_nodes, member)

        # R3: the clearance must hold within END_GRADE of every pin; where it can't, the
        # way underneath dips (up to DIP_MAX, DIP_GRADE ramps), else the bake fails.
        reach_up = self._pin_reach(PIN, nbr, n_nodes, STAIR_GRADE if family == "path" else END_GRADE)
        bad = []
        for i in idx:
            for c in cross[i]:
                for k in c.get("nodes", []):
                    if LB[k] > reach_up[k] + 0.05:
                        bad.append((LB[k] - reach_up[k], c, k))
        if bad:
            fixed = {}
            fails = []
            for need, c, k in sorted(bad, key=lambda b: -b[0]):
                key = (id(c["other"]), round(c["x"]), round(c["z"]))
                if key in fixed:
                    continue
                fixed[key] = True
                over = next((items[i] for i in idx if k in item_nodes[i][2]), {})
                what = (f"({c['x']:.0f}, {c['z']:.0f}): {family} {over.get('name') or over.get('k', '')} "
                        f"[{member[next(i for i in idx if k in item_nodes[i][2])]}] over {c['kind']} "
                        f"{c['other'].get('name') or c['other'].get('k', '')} needs {need:.1f} m more than "
                        f"{(STAIR_GRADE if family == 'path' else END_GRADE) * 100:.0f} % from its pins allows")
                if family in ("path", "tram"):
                    # A footbridge in OpenStreetMap often ends schematically at a building or a
                    # stair; its clearance is reported (check_roads C3), not dipped or failed.
                    print(f"decks: warning: {'footbridge' if family == 'path' else 'tram'} clearance short at {what}")
                    continue
                if need > DIP_MAX:
                    fails.append(what)
                    continue
                self.dips.append({"x": c["x"], "z": c["z"], "d": round(need + 0.1, 2), "other": c["other"],
                                  "name": c["other"].get("name") or c["kind"], "over": family})
            if fails:
                raise SystemExit("bake_roads: R3 clearance cannot be met (more than a "
                                 f"{DIP_MAX:.0f} m underpass dip):\n  " + "\n  ".join(fails))
            for need, c, k in bad:
                LB[k] = min(LB[k], reach_up[k])
            H = self._relax(X, Z, TH, LB, PIN, W, nbr, coupled, item_nodes, member)
        for i in idx:
            ps, ss, ids = item_nodes[i]
            hs = [max(H[k], T.h(*p)) for p, k in zip(ps, ids)]
            self.profiles[id(items[i])] = (ps, ss, hs)
        dbg = os.environ.get("NW_DECK_DEBUG")
        if dbg:
            dx, dz, dr = (float(v) for v in dbg.split(","))
            print(f"debug {family}: {len(X)} nodes, {self.solve_sweeps} sweeps")
            for i in idx:
                ps, ss, ids = item_nodes[i]
                if any(math.hypot(p[0] - dx, p[1] - dz) < dr for p in ps):
                    it = items[i]
                    print(f"  {family} {it.get('name') or it.get('k', '')} [{member[i]}] ly {it.get('_ly')} "
                          f"({ps[0][0]:.0f},{ps[0][1]:.0f})->({ps[-1][0]:.0f},{ps[-1][1]:.0f})")
                    print("     " + " ".join(f"{s:.0f}:{H[k]:.1f}/{TH[k]:.1f}/{LB[k]:.1f}{'P' if PIN[k] is not None else ''}"
                                          for s, k in zip(ss, ids)))

    def _stair_ends(self, p):
        """The vertices of the mapped steps near a point (a footbridge's stairs)."""
        if not hasattr(self, "_stairs"):
            self._stairs = Grid(16.0)
            for st in self.details.get("steps", []):
                for v in pairs(st["p"]):
                    self._stairs.add(v, v[0], v[1], v[0], v[1])
        out = []
        for dx in (-16.0, 0.0, 16.0):
            for dz in (-16.0, 0.0, 16.0):
                out += self._stairs.at(p[0] + dx, p[1] + dz)
        return out

    def _relax(self, X, Z, TH, LB, PIN, W, nbr, coupled, item_nodes, member):
        """Projected successive over-relaxation of the profile energy."""
        n = len(X)
        H = [max(LB[k], TH[k]) if PIN[k] is None else PIN[k] for k in range(n)]
        # A better start for the bridges: straight between their ends.
        for i, (ps, ss, ids) in item_nodes.items():
            if member[i] != "bridge" or len(ids) < 3:
                continue
            h0, h1 = H[ids[0]], H[ids[-1]]
            for s, k in zip(ss, ids):
                if PIN[k] is None:
                    H[k] = max(H[k], h0 + (h1 - h0) * s / max(ss[-1], 1e-3))
        free = [k for k in range(n) if PIN[k] is None]
        for it in range(SOLVE_ITER):
            worst = 0.0
            for k in free:
                num = W[k] * TH[k]
                den = W[k]
                for o, w in nbr[k]:
                    num += H[o] * w
                    den += w
                if den <= 0:
                    continue
                target = num / den
                h = H[k] + SOR_W * (target - H[k])
                lb = LB[k]
                for o, c in coupled[k]:
                    lb = max(lb, H[o] + c)
                if h < lb:
                    h = lb
                dh = abs(h - H[k])
                if dh > worst:
                    worst = dh
                H[k] = h
            if worst < SOLVE_TOL:
                break
        self.solve_sweeps = max(getattr(self, "solve_sweeps", 0), it + 1)
        return H

    def _pin_reach(self, PIN, nbr, n, grade):
        """Per node, the highest it can be while staying within `grade` of every pin."""
        import heapq
        best = [1e9] * n
        heap = []
        for k in range(n):
            if PIN[k] is not None:
                best[k] = PIN[k]
                heap.append((PIN[k], k))
        heapq.heapify(heap)
        while heap:
            h, k = heapq.heappop(heap)
            if h > best[k]:
                continue
            for o, w in nbr[k]:
                nh = h + grade / w
                if nh < best[o]:
                    best[o] = nh
                    heapq.heappush(heap, (nh, o))
        return best

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

    def on_deck(self, x, z, pad=0.0, bridges_only=False):
        """The deck group whose corridor holds the point, or -1 (the highest one).
        `bridges_only` leaves out the approaches (loop 3a: structure ways not tagged bridge)."""
        best = (-1, -1e9)
        for k in self.piece_grid.at(x, z):
            pc = self.pieces[k]
            if bridges_only and pc.get("a"):
                continue
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

    # Loop 3b-2: which mapped surfaces lie on a bridge deck. OpenStreetMap maps a bridge's
    # pavements (area:highway=footway) and its tram bed (landuse=railway) as areas, often
    # without a layer; they were drawn on the ground, so under Most Poniatowskiego a pale band
    # of paving and a grey one of ballast lay on the river ("the pale jagged band south of the
    # bridge"). A surface goes on a deck when most of it lies in the corridor of that deck's
    # pieces of its own kind (paving: footways, ballast: tram or rail) standing over the
    # ground; what lies under a bridge (a pitch, a platform, a sandbar) matches no such piece.
    SURFACE_DECK = {"paving": ("path",), "ballast": ("tram", "rail")}

    def level_surfaces(self, surfaces):
        moved = 0
        for item in surfaces:
            kinds = self.SURFACE_DECK.get(item["k"])
            if not kinds:
                continue
            pts = pairs(item["p"])
            samples = _area_samples(pts)
            votes = {}
            for x, z in samples:
                g = self._on_kind(x, z, kinds, 1.5)
                if g >= 0:
                    votes[g] = votes.get(g, 0) + 1
            if votes:
                g, n = max(votes.items(), key=lambda kv: kv[1])
                if n >= 0.6 * len(samples):
                    item["dk"] = g
                    moved += 1
        print(f"roadbed: {moved} mapped surfaces lie on a bridge deck (drawn on it, not on the ground)")

    def _on_kind(self, x, z, kinds, pad):
        """The deck group of a bridge piece of one of `kinds` whose corridor (grown by pad)
        holds the point and stands 2 m or more over the ground, or -1."""
        for k in self.piece_grid.at(x, z):
            pc = self.pieces[k]
            if pc.get("a") or pc.get("kind") not in kinds:
                continue
            pr = project_onto(pc["pts"], pc["cum"], x, z)
            if pr is None or pr[0] <= 0.01 or pr[0] >= pc["cum"][-1] - 0.01:
                continue
            if -pc["l"] - pad <= pr[1] <= pc["r"] + pad and _interp(pc["cum"], pc["h"], pr[0]) > self.terrain.h(x, z) + 2.0:
                return pc["g"]
        return -1

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
        spirals = self._spiral_rings()
        spiral_ids = {id(r) for ring in spirals for r in ring["roads"]}
        for r in self.roads:
            if r["k"] in MINOR:
                continue
            t = r["_t"]
            lv = r.get("dk", -1)
            left, right, cl, cr, bl, br = r["_ext"]
            ow, nf, nb = lane_split(t, cl + cr)
            total = nf + nb if ow == 0 else nf
            lw = (cl + cr) / total
            for k in range(1 if id(r) not in spiral_ids else total, total):
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
        for ring in spirals:
            self._paint_spiral(ring, out)
        self.lane_lines = out
        self.symbols = symbols

    # Loop 3b-2: Rondo Dmowskiego's spiral markings. A big multi-lane roundabout's lane lines
    # are not circles: each one moves out by a lane between two exits, so the outermost lane
    # leads out at every exit and a new line starts at the island (a spiral roundabout, as
    # Warsaw paints its big rondos). Between exits i and i+1 (f from 0 to 1 along the ring: held
    # at 0 for SPIRAL_HOLD of the gap, then a smoothstep), line k runs at -cl + lw * (k + f) right
    # of the ring's centreline: continuous across each exit, born at the inner edge, ending at
    # the outer edge at an exit.
    def _spiral_rings(self):
        pieces = []
        for r in self.roads:
            t = r["_t"]
            if t.get("junction") not in ("roundabout", "circular") or r["k"] in MINOR:
                continue
            pts = pairs(r["p"])
            if oneway_of(t) < 0:
                pts = pts[::-1]
            if len(pts) >= 2:
                pieces.append((pts, r))
        rings = []
        used = set()
        for i, (pts, r) in enumerate(pieces):
            if i in used:
                continue
            chain = list(pts)
            members = [r]
            used.add(i)
            while math.dist(chain[-1], chain[0]) > 0.5:
                nxt = next((j for j, (q, _) in enumerate(pieces) if j not in used and math.dist(q[0], chain[-1]) < 0.5), None)
                if nxt is None:
                    break
                used.add(nxt)
                chain += pieces[nxt][0][1:]
                members.append(pieces[nxt][1])
            if math.dist(chain[-1], chain[0]) > 0.5 or len(chain) < 6:
                continue
            first = members[0]
            left, right, cl, cr, bl, br = first["_ext"]
            ow, nf, nb = lane_split(first["_t"], cl + cr)
            cx = sum(p[0] for p in chain) / len(chain)
            cz = sum(p[1] for p in chain) / len(chain)
            radius = sum(math.dist(p, (cx, cz)) for p in chain) / len(chain)
            if nf < SPIRAL_LANES or radius < SPIRAL_RADIUS or len({m.get("dk", -1) for m in members}) != 1:
                continue
            ids = {m["_id"] for m in members}
            cum = _cum(chain)
            exits = []
            for o in self.roads:
                if o["_id"] in ids or o["k"] in MINOR:
                    continue
                q = pairs(o["p"])
                ow2 = oneway_of(o["_t"])
                ends = [q[0]] if ow2 > 0 else ([q[-1]] if ow2 < 0 else [q[0], q[-1]])
                for e in ends:
                    pr = project_onto(chain, cum, e[0], e[1])
                    if pr and pr[2] < 1.0:
                        exits.append(pr[0])
            exits.sort()
            merged = []
            for e in exits:
                if not merged or e - merged[-1] > SPIRAL_EXIT_MERGE:
                    merged.append(e)
            if len(merged) > 1 and merged[0] + cum[-1] - merged[-1] <= SPIRAL_EXIT_MERGE:
                merged.pop()
            if len(merged) < 2:
                continue
            rings.append({"pts": chain, "cum": cum, "roads": members, "lv": first.get("dk", -1), "cl": cl, "cr": cr,
                          "n": nf, "exits": merged})
            print(f"roadbed: spiral lane lines on the ring at ({cx:.0f}, {cz:.0f}): {nf} lanes, "
                  f"radius {radius:.0f} m, {len(merged)} exits")
        return rings

    def _paint_spiral(self, ring, out):
        chain, cum, lv = ring["pts"], ring["cum"], ring["lv"]
        cl, cr, n, exits = ring["cl"], ring["cr"], ring["n"], ring["exits"]
        lw = (cl + cr) / n
        length = cum[-1]
        gaps = [(exits[i], exits[(i + 1) % len(exits)] + (length if i == len(exits) - 1 else 0.0)) for i in range(len(exits))]
        for s0, s1 in gaps:
            for k in range(n):
                run = []

                def flush():
                    if len(run) >= 2 and polyline_length(run) >= 2.0:
                        out.append({"k": "lane", "p": flat(simplify(run, 0.05)), "dk": lv})
                    run.clear()

                steps = max(2, int(math.ceil(s1 - s0)))
                for j in range(steps + 1):
                    s = s0 + (s1 - s0) * j / steps
                    # Concentric for the first part of the gap, then sweeping out into the exit
                    # (a uniform drift of one lane per quarter read as plain circles).
                    t = max(0.0, min(1.0, (j / steps - SPIRAL_HOLD) / (1.0 - SPIRAL_HOLD)))
                    f = t * t * (3.0 - 2.0 * t)
                    off = -cl + lw * (k + f)
                    sm = s % length
                    if off < -cl + 0.35 or off > cr - 0.35:
                        flush()
                        continue
                    x, z = _edge_point(chain, cum, sm, off)
                    if self.paintable(lv, x, z):
                        run.append((x, z))
                    else:
                        flush()
                flush()

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
            if turns and e.get("_last") and span > 14.0 and e["s1"] < cum[-1] - 0.5 and not self._on_ring(lv, pts, cum, e):
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

    def _on_ring(self, lv, pts, cum, e):
        """Loop 3b-2: the arrows' spot on edge e lies on a roundabout's ring (the ring's
        turn:lanes made arrow confetti round Rondo Dmowskiego): no arrows there."""
        if not hasattr(self, "_ring_caps"):
            self._ring_caps = Capsules()
            for r in self.roads:
                if r["_t"].get("junction") in ("roundabout", "circular"):
                    for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
                        self._ring_caps.add(a, b, r["w"] * 0.5, r.get("dk", -1))
        x, z = _edge_point(pts, cum, e["s1"] - 7.0, e["o"])
        return self._ring_caps.hit(x, z) is not None

    # -- hatched areas ------------------------------------------------------------------

    def bake_hatching(self):
        """Hatched no-drive areas: an outline and white stripes, chevrons in long thin ones.
        Loop 3b-2: chevrons only where the traffic on both sides goes the same way, their
        points towards the oncoming traffic (like a bow parting it); between opposite
        flows, or where the way is unknown, plain diagonals."""
        out = []
        flips = chevrons = diagonals = 0
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
            if chevron:
                flow = self._hatch_flow(pts, (ux, uz), lv)
                if flow == 0:
                    chevron = False
                    diagonals += 1
                else:
                    chevrons += 1
                    if flow < 0:
                        # The points face -u: make u the way the traffic goes.
                        flips += 1
                        ux, uz, vx, vz = -ux, -uz, -vx, -vz
                        a = b
                        uv = [((p[0] - a[0]) * ux + (p[1] - a[1]) * uz, (p[0] - a[0]) * vx + (p[1] - a[1]) * vz) for p in pts]
                        us = [q[0] for q in uv]
                        vs = [q[1] for q in uv]
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
        print(f"roadbed: hatching: {chevrons} chevron areas ({flips} turned to face the traffic), "
              f"{diagonals} long areas between opposite or unknown flows get diagonals")

    def _hatch_flow(self, pts, u, lv):
        """Which way the traffic beside a hatched area goes along u: +1 with it, -1 against,
        0 opposite flows on its two sides (or none known). From the roads alongside within
        HATCH_FLOW_REACH: a one-way road by its direction; a two-way road by the side of it
        the area lies on (traffic keeps right), 0 if the area straddles it."""
        caps = self.allcaps.get(lv)
        if caps is None:
            return 0
        xs = [p[0] for p in pts]
        zs = [p[1] for p in pts]
        cx, cz = sum(xs) / len(xs), sum(zs) / len(zs)
        vote = 0.0
        seen = set()
        for a, b, half, r in caps.grid.box(min(xs) - HATCH_FLOW_REACH, min(zs) - HATCH_FLOW_REACH,
                                           max(xs) + HATCH_FLOW_REACH, max(zs) + HATCH_FLOW_REACH):
            d = _unit(a, b)
            if d is None or abs(d[0] * u[0] + d[1] * u[1]) < 0.7 or r["k"] in MINOR:
                continue
            dist = min(seg_dist(x, z, a, b) for x, z in pts + [(cx, cz)])
            if dist > half + HATCH_FLOW_REACH or (id(r), a) in seen:
                continue
            seen.add((id(r), a))
            ow = oneway_of(r["_t"])
            along = 1.0 if d[0] * u[0] + d[1] * u[1] > 0 else -1.0
            w = 1.0 / (1.0 + dist)
            if ow != 0:
                vote += along * ow * w
            else:
                # Right of a two-way road's line (offset_line's right) the traffic goes with it.
                sides = {1 if (x - a[0]) * (-d[1]) + (z - a[1]) * d[0] > 0.3 else (-1 if (x - a[0]) * (-d[1]) + (z - a[1]) * d[0] < -0.3 else 0)
                         for x, z in pts}
                sides.discard(0)
                if len(sides) == 1:
                    vote += along * sides.pop() * w
                elif len(sides) == 2:
                    return 0
        if abs(vote) < 0.05:
            return 0
        return 1 if vote > 0 else -1

    # -- guard rails and the river's edge --------------------------------------------------

    def bake_guards(self, clip_lines):
        out = []
        for k in self.kerbs:
            if k["dk"] < 0:
                continue
            # Loop 3a: only where the kerb is on a bridge, not along an approach on the ground.
            run = []
            for p in resample(offset_line(pairs(k["p"]), 0.2), 2.0) + [None]:
                if p is not None and self._on_bridge_piece(p[0], p[1], k["dk"]):
                    run.append(p)
                    continue
                if len(run) >= 2 and polyline_length(run) >= 4.0:
                    out.append({"p": flat(simplify(run, 0.05)), "dk": k["dk"]})
                run = []
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

    def _on_bridge_piece(self, x, z, g):
        """The point lies on (or within a metre of) a bridge piece of group g, not an approach."""
        for k in self.piece_grid.at(x, z):
            pc = self.pieces[k]
            if pc["g"] != g or pc.get("a"):
                continue
            pr = project_onto(pc["pts"], pc["cum"], x, z)
            if pr and 0.0 < pr[0] < pc["cum"][-1] and -pc["l"] - 1.0 <= pr[1] <= pc["r"] + 1.0:
                return True
        return False

    def bake_shore(self):
        """Where the car would roll into the water: the river's (and ponds') edges, not
        under a bridge, not on the map's rim, not where a road runs, not inside another
        water body (loop 3b-2). tools/bake_banks.py then splits the runs into built and
        natural banks."""
        x0, z0, x1, z1 = self.rect
        out = []
        ground = self.allcaps.get(-1)
        water = self.water
        for wi, poly in enumerate(water.polys):
            ring = poly + [poly[0]]
            run = []
            for a, b in zip(ring, ring[1:]):
                ln = math.dist(a, b)
                n = max(1, int(math.ceil(ln / 2.0)))
                for k in range(n + 1):
                    x = a[0] + (b[0] - a[0]) * k / n
                    z = a[1] + (b[1] - a[1]) * k / n
                    rim = min(abs(x - x0), abs(x - x1), abs(z - z0), abs(z - z1)) < 1.0
                    # Loop 3b-2: not where this water body's edge runs through another one (the
                    # Vistula is mapped as two relations: their seam crossed the river at z ~820
                    # and got a granite edge and a wall across the water).
                    seam = any(j != wi and point_in_poly(x, z, water.polys[j]) for j in water.grid.at(x, z)
                               if water.boxes[j][0] <= x <= water.boxes[j][2] and water.boxes[j][1] <= z <= water.boxes[j][3])
                    bad = rim or seam or self.on_deck(x, z, 6.0) >= 0 or (ground is not None and ground.hit(x, z, 1.0) is not None)
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
            piece = {"p": flat(pc["pts"]), "h": [round(h, 2) for h in pc["h"]], "l": round(pc["l"], 2),
                     "r": round(pc["r"], 2), "g": pc["g"], "k": pc["kind"], "o": outer}
            pieces.append(piece)
        return {"pieces": pieces, "groups": self.groups}

    def set_corridors(self):
        """Deck (and fill) corridors from the measured road widths (a deck holds its road's strip)."""
        pits = [(pc["road"], pc) for pc in self.fills if pc.get("pit")]
        for i, pc in list((i, self.pieces[k]) for i, k in self.road_piece.items()) + list(self.road_fill.items()) + pits:
            r = self.roads[i]
            pc["l"] = max(0.5, r["w"] * 0.5 - r["c"] + 0.4)
            pc["r"] = max(0.5, r["w"] * 0.5 + r["c"] + 0.4)

    def fill_json(self):
        """Loop 3a: the approaches, the ground corrected under their corridors."""
        return [{"p": flat(pc["pts"]), "h": [round(h, 2) for h in pc["h"]], "l": round(pc["l"], 2),
                 "r": round(pc["r"], 2), "k": pc["kind"]} for pc in self.fills]


def _area_samples(pts):
    """A polygon's corners, points along its outline (~60) and a grid of points inside it
    (at most ~12 x 12): a long thin polygon (a bridge's tram bed) is sampled along its length."""
    out = list(pts)
    ring = list(pts) + [pts[0]]
    per = sum(math.dist(a, b) for a, b in zip(ring, ring[1:]))
    out += resample(ring, max(1.0, per / 60.0))
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    step = max(1.0, max(max(xs) - min(xs), max(zs) - min(zs)) / 12)
    x = min(xs) + step / 2
    while x < max(xs):
        z = min(zs) + step / 2
        while z < max(zs):
            if point_in_poly(x, z, pts):
                out.append((x, z))
            z += step
        x += step
    return out


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


def _bbox(pts, pad):
    xs = [p[0] for p in pts]
    zs = [p[1] for p in pts]
    return min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad


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


def _key(p):
    return (round(p[0] * 2), round(p[1] * 2))


def _cum(pts):
    c = [0.0]
    for a, b in zip(pts, pts[1:]):
        c.append(c[-1] + math.dist(a, b))
    return c


def _stacked(pa, pb):
    """One piece passes over the other (their lines cross more than 2.5 m apart in height)."""
    for k in range(len(pa["pts"]) - 1):
        for q in range(len(pb["pts"]) - 1):
            hit = seg_cross(pa["pts"][k], pa["pts"][k + 1], pb["pts"][q], pb["pts"][q + 1])
            if hit is None:
                continue
            ha = pa["h"][k] + (pa["h"][k + 1] - pa["h"][k]) * hit[0]
            hb = pb["h"][q] + (pb["h"][q + 1] - pb["h"][q]) * hit[1]
            if abs(ha - hb) > 2.5:
                return True
    return False


class SurfaceModel:
    """R2 (docs/DEMO.md 4.4; loop 3b): GUGiK's 0.5 m surface model (NMPT, `nmpt05/`) and 1 m
    bare earth (NMT, `nmt1/`) for the structure corridors, from data/raw/demo/gugik (float32
    GeoTIFF, PL-1992, EVRF2007: tools/geotiff.py; ESRI ASCII grids read too). `load` returns
    None until both folders and data/raw/demo/MANIFEST.md are there. `deck_profile(pts, cum,
    half)` gives a deck's measured height along it: every DECK_OBS metres the DECK_PCT
    percentile of the surface over the carriageway's width (the deck is the low envelope: cars,
    lamps, parapets stand above it), cells rejected where the surface is
    within DECK_STRUCT of the bare earth (no structure there, or the NMT kept the deck) or under
    a scanned tree's crown; then smoothed to DECK_GRADE within
    DECK_BAND of what was measured (after an opening that drops anything narrower than 12 m
    standing on it). `ground(x, z)` is a robust bare-earth value (the median of
    the 1 m NMT in a 6 m disc)."""

    def __init__(self, surface, ground):
        self.surface = surface
        self.ground_grid = ground

    @staticmethod
    def load(folder):
        nmpt, nmt = os.path.join(folder, "nmpt05"), os.path.join(folder, "nmt1")
        if not (os.path.isdir(nmpt) and os.path.isdir(nmt)):
            return None
        if not os.path.exists(os.path.join(folder, "..", "MANIFEST.md")):
            print("decks: the surface model is still being fetched (no data/raw/demo/MANIFEST.md): R2 skipped")
            return None
        grids = []
        for sub in (nmpt, nmt):
            files = [os.path.join(sub, f) for f in sorted(os.listdir(sub)) if f.lower().endswith((".tif", ".tiff", ".asc"))]
            if not files:
                print(f"decks: data/raw/demo/gugik/{os.path.basename(sub)} has no grids: R2 skipped")
                return None
            grids.append([_TifGrid(f) if not f.lower().endswith(".asc") else _AscGrid(f) for f in files])
        # Only the windows that reach into this map.
        import bake_osm
        sw, ne = bake_osm.project(bake_osm.BBOX[0], bake_osm.BBOX[1]), bake_osm.project(bake_osm.BBOX[2], bake_osm.BBOX[3])
        rect = (sw[0], ne[1], ne[0], sw[1])
        grids = [[g for g in gl if g.touches(rect)] for gl in grids]
        print(f"decks: surface model (R2): {len(grids[0])} surface + {len(grids[1])} bare-earth windows in this map")
        return SurfaceModel(grids[0], grids[1]) if grids[0] and grids[1] else None

    @staticmethod
    def _sample(grids, x, z):
        for g in grids:
            h = g.at(x, z)
            if h is not None:
                return h
        return None

    def ground(self, x, z):
        vals = [self._sample(self.ground_grid, x + dx, z + dz) for dx in range(-3, 4) for dz in range(-3, 4)
                if dx * dx + dz * dz <= 9]
        vals = sorted(v for v in vals if v is not None)
        return vals[len(vals) // 2] if vals else None

    def deck_profile(self, pts, cum, half, trees=None):
        """[(s, measured deck height)] along a deck piece (absolute heights; empty where no
        structure was seen). `trees`: a function (x, z) -> True under a scanned crown."""
        raw = []
        s = 0.0
        while s <= cum[-1] + 1e-6:
            x, z = _at(pts, cum, s)
            d = _edge_dir(pts, cum, s)
            vals = []
            o = -half
            while o <= half + 1e-6:
                px, pz = x - d[1] * o, z + d[0] * o
                top = self._sample(self.surface, px, pz)
                bare = self._sample(self.ground_grid, px, pz)
                if top is not None and bare is not None and top - bare > DECK_STRUCT and not (trees and trees(px, pz)):
                    vals.append(top)
                o += 0.5
            if len(vals) >= max(3, int(half * 2 / 0.5 * 0.4)):
                vals.sort()
                raw.append((s, vals[int(len(vals) * DECK_PCT)]))
            s += DECK_OBS
        if len(raw) < 3:
            return []
        # An opening (the lowest within DECK_OPEN, then the highest of those within DECK_OPEN):
        # anything narrower than 2 x DECK_OPEN standing on the deck (a pylon, a sign gantry, a
        # bus) goes, a slope stays; then within DECK_BAND of that, no steeper than DECK_GRADE
        # (forward and backward passes).
        ero = [min(h for ss, h in raw if abs(ss - raw[k][0]) <= DECK_OPEN) for k in range(len(raw))]
        med = [max(ero[j] for j in range(len(raw)) if abs(raw[j][0] - raw[k][0]) <= DECK_OPEN) for k in range(len(raw))]
        h = list(med)
        for _ in range(50):
            moved = 0.0
            for k in range(1, len(h)):
                lim = DECK_GRADE * (raw[k][0] - raw[k - 1][0])
                v = min(max(h[k], h[k - 1] - lim), h[k - 1] + lim)
                moved, h[k] = max(moved, abs(v - h[k])), v
            for k in range(len(h) - 2, -1, -1):
                lim = DECK_GRADE * (raw[k + 1][0] - raw[k][0])
                v = min(max(h[k], h[k + 1] - lim), h[k + 1] + lim)
                moved, h[k] = max(moved, abs(v - h[k])), v
            for k in range(len(h)):
                v = min(max(h[k], med[k] - DECK_BAND), med[k] + DECK_BAND)
                moved, h[k] = max(moved, abs(v - h[k])), v
            if moved < 0.01:
                break
        return [(raw[k][0], h[k]) for k in range(len(h))]


class _TifGrid:
    """One GeoTIFF window (tools/geotiff.py) in map metres: map (x, z) -> PL-1992 (easting,
    northing) by an affine fit at the window's corners (the projections differ by under a
    centimetre across a window), nearest cell."""

    def __init__(self, path):
        import geotiff
        import bake_osm
        import pl1992
        self.g = geotiff.read(path)
        x0, y0, x1, y1 = self.g.bounds()
        corners = []
        for e, n in ((x0, y1), (x1, y1), (x0, y0)):
            lat, lon = pl1992.from_pl1992(n, e)
            corners.append((bake_osm.project(lat, lon), (e, n)))
        (ma, ea), (mb, eb), (mc, ec) = corners
        # Solve [e n] = A [x z 1] from the three corners.
        det = (mb[0] - ma[0]) * (mc[1] - ma[1]) - (mc[0] - ma[0]) * (mb[1] - ma[1])
        self.A = []
        for k in (0, 1):
            dxv, dzv = eb[k] - ea[k], ec[k] - ea[k]
            a = (dxv * (mc[1] - ma[1]) - dzv * (mb[1] - ma[1])) / det
            b = (dzv * (mb[0] - ma[0]) - dxv * (mc[0] - ma[0])) / det
            self.A.append((a, b, ea[k] - a * ma[0] - b * ma[1]))
        xs = [c[0][0] for c in corners] + [mb[0] + mc[0] - ma[0]]
        zs = [c[0][1] for c in corners] + [mb[1] + mc[1] - ma[1]]
        self.box = (min(xs), min(zs), max(xs), max(zs))

    def touches(self, rect):
        return not (self.box[2] < rect[0] or self.box[0] > rect[2] or self.box[3] < rect[1] or self.box[1] > rect[3])

    def at(self, x, z):
        if not (self.box[0] <= x <= self.box[2] and self.box[1] <= z <= self.box[3]):
            return None
        e = self.A[0][0] * x + self.A[0][1] * z + self.A[0][2]
        n = self.A[1][0] * x + self.A[1][1] * z + self.A[1][2]
        return self.g.at(e, n)


class _AscGrid:
    """One ESRI ASCII grid in PL-1992 (GUGiK: x = northing, y = easting), in map metres."""

    def __init__(self, path):
        import pl1992  # noqa: F401  (the grid's corner, to the map's frame)
        head = {}
        with open(path) as f:
            for _ in range(6):
                k, v = f.readline().split()
                head[k.lower()] = float(v)
            self.vals = [float(v) for line in f for v in line.split()]
        self.nc, self.nr = int(head["ncols"]), int(head["nrows"])
        self.cell = head["cellsize"]
        self.east0 = head.get("xllcorner", head.get("xllcenter", 0.0))
        self.north0 = head.get("yllcorner", head.get("yllcenter", 0.0))
        self.nodata = head.get("nodata_value", -9999.0)

    def touches(self, rect):
        return True

    def at(self, x, z):
        import bake_osm
        import pl1992
        lat = bake_osm.LAT0 - z / bake_osm.M_PER_DEG_LAT
        lon = bake_osm.LON0 + x / bake_osm.M_PER_DEG_LON
        north, east = pl1992.to_pl1992(lat, lon)
        c = int((east - self.east0) / self.cell)
        r = self.nr - 1 - int((north - self.north0) / self.cell)
        if 0 <= c < self.nc and 0 <= r < self.nr:
            v = self.vals[r * self.nc + c]
            return None if v == self.nodata else v
        return None
