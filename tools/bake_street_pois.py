"""Loop "content POIs" (2026-10-31): the street pois the content lane asked for (docs/BACKLOG.md
"From loop MW-2", docs/design/parodies.md 5.2), added to the finished map data.

    python3 -I tools/bake_street_pois.py [MAP.json] [OSM.json] [--out=FILE]   (a dry run, see below)

bake_osm.py calls `add(out, els, nodes, ways, map_dir)` at its end, after bake_structures (the
solids are final), on the map data it is about to write. It appends, after every older poi (so
their order and the address list's order are unchanged):

  convenience      shop=convenience: `x, z` the shop, `door` the road point a car pulls up at
                   (like `address`), `fr` 1 for the chain the Frogs parody (parodies.md 2), `lv` its
                   level when mapped off the ground floor. No names: brands only as parodies.
  subway_entrance  railway=subway_entrance: `x, z`, `yaw` the way down (atan2(dx, dz): Basis(UP,
                   yaw) turns +Z to it; `f` how it was found: "steps" from a stair or underground
                   way through the node, "canopy" from the canopy outline it sits on, "footway"
                   along the nearest footway), `st` the station (nearest railway=station
                   station=subway within STATION_REACH), `ref` the exit's number when tagged, `u` 1
                   when it opens off an underground passage only (no street-level way through it).
  bicycle_rental   amenity=bicycle_rental (the city bike docks): `x, z`, `yaw` along the dock's
                   long side (or the nearest road), `l` the dock's length when mapped as an area.
  address          (more) the addresses of EXTRA_ADDRESSES: buildings or address points the
                   address bake leaves out (not a home or an office) that a place in the game is
                   at; `v` 1 marks them (not a home: the kebab and ride jobs may skip them).
  scooter_zone     parodies.md 5.2: a painted 3 x 1.5 m parking zone on the pavement beside a
                   street in the hero districts, ZONE_SPACING m apart: `x, z`, `yaw` (its 3 m side
                   along the street), `egg` "easter_lezak" on the one nearest Metro Nowy
                   Świat-Uniwersytet (it holds the one standing scooter).
  scooter          the Leżaks: `x, z`, `yaw`, `p` the pose: "lie" (on its side on a footway near
                   a junction, a stop, a metro exit, the boulevards or a park's edge), the odd
                   places (1 in 15) "grass", "bench" (across its front), "frogs" (at the door of a
                   corner shop of the parodied chain), "hedge" (half in it), "roof" (1 in 40, on a
                   bus shelter's roof, `h` the height over the ground), "stand" (the egg's, in its
                   zone); `zn` the zone (its order among the scooter_zone pois) it lies round.

Everything is deterministic: the order and the random numbers come from hashes of positions
(SEED), never from Python's hash or the iteration order of a set. The scooters keep CLEAR of
everything solid or drivable (the carriageway, the road strips, kerbs, crossings and their kerb
ramps, tram and rail tracks, buildings, LoD2 footprints, walls, fences, steps, platforms,
islands, poles, trees, props, parked cars, piers, portals, fountains, water) and keep RIM m inside
the map; tools/check_pois.py checks the result with the same Solids over the whole map.

The dry run reads a finished centrum.json (default game/map/centrum.json) and the OSM export
(default data/work/demo/osm_demo.json), drops the kinds above (and the EXTRA_ADDRESSES ones) and
adds them again; with --out it writes the result there (never over game/map: re-bake with
bake_osm.py). Standard library only.
"""
import hashlib
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import map_shape  # noqa: E402

KINDS = ("convenience", "subway_entrance", "bicycle_rental", "scooter_zone", "scooter")
SEED = "lezak-5205"
# The hero districts (docs/DEMO.md 2.3: Śródmieście, the Royal Route, the Old Town, Powiśle,
# Praga and the stadium): the map east of Emilii Plater, as storefronts.gd HERO (x0, z0, x1, z1).
HERO = (-1500.0, -2050.0, 2200.0, 1750.0)
# parodies.md 5.2 (*guess*): scooters a km² in the hero districts and elsewhere.
PER_KM2_HERO = 30
PER_KM2_OTHER = 12
CELL = 500.0          # the density is met per CELL x CELL square, on its land (not water)
ODD_EVERY = 15        # 1 in 15 lies somewhere odd...
ROOF_EVERY = 40       # ...1 in 40 of all on a bus shelter's roof (one of the odd ones)
ODD_KINDS = ("grass", "bench", "frogs", "hedge")
ODD_SPACING = 150.0   # odd ones this far apart
SPOT_SPACING = 15.0   # lying spots (one or two scooters) this far apart
PAIR_SHARE = 0.3      # a spot with two
ZONE_SPACING = 400.0  # parodies.md 5.2: one zone per ~400 m (as storefronts.gd ZONE_SPACING)
ZONE_SIZE = (3.0, 1.5)
ZONE_STREET = 14.0    # a zone's footway point this near a street's centre line
ZONE_SCOOTERS = (2, 3)
EGG_STATION = "Nowy Świat-Uniwersytet"
EGG_REACH = 60.0     # the egg zone this near one of its street exits
SAMPLE = 4.0          # footway sample step (m)
# What a footway point must be near to hold a scooter (m): the lane graph's junctions, bus and
# tram stops, metro exits; the boulevards (the river) and park edges.
NEAR_JUNCTION = 30.0
NEAR_STOP = 20.0
NEAR_METRO = 20.0
NEAR_RIVER = 80.0
NEAR_PARK = 6.0
RIM = 10.0            # this far inside the map's outline
R = 0.6               # a lying scooter's footprint radius (1.1 m long)
SHELTER_ROOF = 2.6    # map_builder.gd's shelter: the roof's top 2.585 m up, 4.3 x 1.95 m
STATION_REACH = 400.0
METRO_STAIRS = 8.0    # a metro entrance's stairs this long down its yaw (kept clear)
DOOR_REACH = 70.0     # a corner shop's door: the nearest street within this (as `address`)
# Addresses a place in the game is at (game/data/places.json, the notebook and the venues) that
# the address bake leaves out (its kinds are homes and offices): (street as OpenStreetMap has it,
# number). The building with that address, else an address point (a node), else any node with it.
# Plac Żelaznej Bramy 1 (Hala Gwardii) is in no OSM element, so it isn't here.
EXTRA_ADDRESSES = [
    ("Leona Kruczkowskiego", "3B"),        # kasa_biletowa: Warszawa Powiśle's pavilion (building=train_station)
    ("Jasna", "1"),                        # jasna_0: address points only
    ("Aleje Jerozolimskie", "123A"),       # level_26: address points only
    ("Kredytowa", "9"),                    # milosc_hipoteczna, zwir: address points only
    ("Emilii Plater", "29"),               # m2_1499: a school building
    ("Aleja Wyzwolenia", "18"),            # plan_c: address points only
    ("Nowy Świat", "22/28"),               # apteczka, pawilony
    ("Krakowskie Przedmieście", "13"),     # przegryzki_zagryzki: address points only
    ("Dobra", "56/66"),                    # buw_ogrod: the university library
    ("Plac Mirowski", "1"),                # hala_mirowska: the market hall
    ("Koszykowa", "63"),                   # hala_koszyki: the food hall
]
JOB_ROADS = {"primary", "secondary", "tertiary", "unclassified", "residential", "living_street"}
STREETS = JOB_ROADS | {"trunk"}


def h01(*key):
    """A number in [0, 1) from the key (a fixed hash: the same on every machine and run)."""
    s = SEED + "|" + "|".join(("%.1f" % k) if isinstance(k, float) else str(k) for k in key)
    return int.from_bytes(hashlib.sha1(s.encode("utf-8")).digest()[:7], "big") / float(1 << 56)


def pairs(flat):
    return list(zip(flat[0::2], flat[1::2]))


def seg_dist(x, z, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = dx * dx + dz * dz
    u = 0.0 if ln == 0 else max(0.0, min(1.0, ((x - a[0]) * dx + (z - a[1]) * dz) / ln))
    return math.hypot(a[0] + u * dx - x, a[1] + u * dz - z)


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


def offset_line(p, off):
    """A polyline moved `off` m to its left (as overlay_ortho.py and the bake's road strips)."""
    if not off:
        return p
    out = []
    for i in range(len(p)):
        a = p[max(i - 1, 0)]
        b = p[min(i + 1, len(p) - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dz) or 1.0
        out.append((p[i][0] - dz / ln * off, p[i][1] + dx / ln * off))
    return out


class Segs:
    """Segments (or points: a == b) with a clearance each, in CELL m cells: `near(x, z, r)` is
    the first one closer than its clearance + r, as (what, distance) or None."""

    CELL = 16.0

    def __init__(self):
        self.cells = {}

    def add(self, a, b, clear, what):
        ln = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(math.ceil(ln / self.CELL)))
        for k in range(n):
            p = (a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n)
            q = (a[0] + (b[0] - a[0]) * (k + 1) / n, a[1] + (b[1] - a[1]) * (k + 1) / n)
            reach = clear + 2.0
            for i in range(int(math.floor((min(p[0], q[0]) - reach) / self.CELL)), int(math.floor((max(p[0], q[0]) + reach) / self.CELL)) + 1):
                for j in range(int(math.floor((min(p[1], q[1]) - reach) / self.CELL)), int(math.floor((max(p[1], q[1]) + reach) / self.CELL)) + 1):
                    self.cells.setdefault((i, j), []).append((p, q, clear, what))

    def add_line(self, pts, clear, what):
        for a, b in zip(pts, pts[1:]):
            self.add(a, b, clear, what)

    def near(self, x, z, r=0.0, skip=()):
        for p, q, clear, what in self.cells.get((int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))), ()):
            if what in skip:
                continue
            d = seg_dist(x, z, p, q)
            if d < clear + r:
                return what, d
        return None

    def dist(self, x, z, what):
        """The distance to the nearest `what` within its cell's reach (INF beyond)."""
        best = math.inf
        for p, q, clear, w in self.cells.get((int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))), ()):
            if w == what:
                best = min(best, seg_dist(x, z, p, q))
        return best


class Polys:
    """Polygons in 32 m cells by their bounding boxes: `inside(x, z)` is the first one holding it."""

    CELL = 32.0

    def __init__(self):
        self.cells = {}
        self.polys = []

    def add(self, pts, what):
        if len(pts) < 3:
            return
        xs, zs = [p[0] for p in pts], [p[1] for p in pts]
        k = len(self.polys)
        self.polys.append((min(xs), min(zs), max(xs), max(zs), pts, what))
        for i in range(int(math.floor(min(xs) / self.CELL)), int(math.floor(max(xs) / self.CELL)) + 1):
            for j in range(int(math.floor(min(zs) / self.CELL)), int(math.floor(max(zs) / self.CELL)) + 1):
                self.cells.setdefault((i, j), []).append(k)

    def inside(self, x, z, skip=()):
        for k in self.cells.get((int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))), ()):
            x0, z0, x1, z1, pts, what = self.polys[k]
            if what not in skip and x0 <= x <= x1 and z0 <= z <= z1 and point_in_poly(x, z, pts):
                return what
        return None


class Solids:
    """Everything a scooter on the pavement must keep clear of, from the finished map data (and
    the OpenStreetMap kerb and crossing nodes when the bake passes them). `blocked(x, z, r)` is
    the reason a disc of radius r there is not clear (None when it is); `skip` names solids a
    pose may touch ("bench", "hedge")."""

    def __init__(self, data, lod2=None, kerb_nodes=(), metros=None):
        self.shape = map_shape.Shape(data["bounds"], data.get("outside", []))
        s = self.segs = Segs()
        poly = self.polys = Polys()
        for r in data.get("roads", []):
            centre = offset_line(pairs(r["p"]), r.get("c", 0.0))
            s.add_line(centre, r["w"] * 0.5 + 0.8, "carriageway")
        for r in data.get("tunnels", {}).get("roads", []) if isinstance(data.get("tunnels"), dict) else []:
            if "p" in r and "w" in r:
                s.add_line(pairs(r["p"]), r["w"] * 0.5 + 0.8, "carriageway")
        for c in data.get("carriage", []):
            pts = pairs(c["p"])
            poly.add(pts, "carriageway")
            s.add_line(pts + pts[:1], 0.6, "carriageway")
        for k in data.get("kerbs", []):
            s.add_line(pairs(k["p"]), 0.6, "kerb")
        for p in data.get("paths", []):
            if p["k"] in ("zebra", "cyclecross"):
                pts = pairs(p["p"])
                s.add_line(pts, p["w"] * 0.5 + 1.2, "crossing")
                for e in (pts[0], pts[-1]):
                    s.add(e, e, 3.0, "kerb ramp")
        for x, z in kerb_nodes:
            s.add((x, z), (x, z), 3.0, "kerb ramp")
        for t in data.get("trams", []):
            s.add_line(pairs(t["p"]), 2.0, "tram track")
        for t in data.get("rails", []):
            s.add_line(pairs(t["p"]), 3.0, "rail")
        for b in data.get("buildings", []):
            pts = pairs(b["p"])
            poly.add(pts, "building")
            s.add_line(pts + pts[:1], 0.4, "building")
        for fp in (lod2 or {}).get("footprints", []):
            pts = pairs(fp)
            poly.add(pts, "building")
            s.add_line(pts + pts[:1], 0.4, "building")
        for line in data.get("lines", []):
            clear = {"hedge": 0.8, "platform": 1.0}.get(line["k"], 0.5)
            s.add_line(pairs(line["p"]), clear, line["k"])
        for w in data.get("walls", []):
            s.add_line(pairs(w["p"]), 0.8, "wall")
        for st in data.get("steps", []):
            s.add_line(pairs(st["p"]), 1.2, "steps")
        for g in data.get("guards", []):
            s.add_line(pairs(g["p"]), 1.0, "guard rail")
        for m in data.get("medians", []):
            s4 = m["s"]
            ring = [(s4[i], s4[i + 1]) for i in range(0, len(s4) - 3, 4)] + [(s4[i + 2], s4[i + 3]) for i in range(0, len(s4) - 3, 4)][::-1]
            poly.add(ring, "carriageway")
        for a in data.get("areas", []):
            if a["k"] == "water":
                pts = pairs(a["p"])
                poly.add(pts, "water")
                s.add_line(pts + pts[:1], 1.0, "water")
        for key, what in (("platforms", "platform"), ("islands", "island")):
            for a in data.get(key, []):
                pts = pairs(a["p"])
                poly.add(pts, what)
                s.add_line(pts + pts[:1], 0.5, what)
        for a in data.get("surfaces", []):
            if a["k"] in ("fountain", "flowerbed", "construction", "ballast"):
                pts = pairs(a["p"])
                poly.add(pts, a["k"])
                s.add_line(pts + pts[:1], 0.5, a["k"])
        for t in data.get("towers", []):
            if t.get("zone"):
                poly.add(pairs(t["zone"]), "tower")
        for p in data.get("decks", {}).get("piers", []) if isinstance(data.get("decks"), dict) else []:
            c = p["c"]
            s.add((c[0], c[1]), (c[0], c[1]), max(p["s"]) * 0.5 + 1.0, "pier")
        for x, z, _ in data.get("tunnels", {}).get("portals", []) if isinstance(data.get("tunnels"), dict) else []:
            s.add((x, z), (x, z), 15.0, "tunnel portal")
        for g in data.get("garages", []):
            s.add((g[0], g[1]), (g[0], g[1]), 6.0, "garage ramp")
        for key, stride, clear, what in (("lamps", 2, 0.5, "pole"), ("signals", 3, 0.5, "pole"),
                                         ("benches", 3, 1.2, "bench"), ("bins", 3, 0.7, "bin"),
                                         ("bikes", 3, 1.2, "bike rack"), ("columns", 3, 1.3, "column"),
                                         ("shelters", 3, 2.6, "shelter"), ("parked", 4, 2.8, "parked car"),
                                         ("trees3d", 6, 0.7, "tree")):
            v = data.get(key, [])
            for i in range(0, len(v) - stride + 1, stride):
                s.add((v[i], v[i + 1]), (v[i], v[i + 1]), clear, what)
        if data.get("palm"):
            x, z = data["palm"]
            s.add((x, z), (x, z), 2.0, "palm")
        # The metro's stairs: the entrance and METRO_STAIRS m down its way (canopies are no
        # buildings in the map data, and the stairs below ground are not drawn).
        for m in metros if metros is not None else [p for p in data.get("pois", []) if p["k"] == "subway_entrance"]:
            a = (m["x"], m["z"])
            s.add(a, a, 3.0, "metro stairs")
            if "yaw" in m and not m.get("u"):
                b = (m["x"] + math.sin(m["yaw"]) * METRO_STAIRS, m["z"] + math.cos(m["yaw"]) * METRO_STAIRS)
                s.add(a, b, 2.2, "metro stairs")

    def blocked(self, x, z, r=R, skip=()):
        if not self.shape.contains(x, z) or self.shape.rim(x, z) < RIM:
            return "map edge"
        what = self.polys.inside(x, z, skip)
        if what:
            return what
        hit = self.segs.near(x, z, r, skip)
        return hit[0] if hit else None


def _first_num(v):
    try:
        return float(str(v).split(";")[0].strip())
    except ValueError:
        return None


def _road_grid(data, kinds):
    import bake_osm
    return bake_osm.SegGrid(data["roads"], kinds)


def add(out, els, nodes, ways, map_dir):
    """Append the street pois to out["pois"] (see the module's docstring). Prints the counts."""
    import bake_osm
    shape = map_shape.Shape(out["bounds"], out.get("outside", []))
    inner = shape.grow(-RIM)
    pois = out["pois"]
    lod2 = None
    lod2_path = os.path.join(map_dir, "lod2.json")
    if os.path.exists(lod2_path):
        with open(lod2_path, encoding="utf-8") as f:
            lod2 = json.load(f)
    roads_grid = _road_grid(out, JOB_ROADS)
    water = Polys()
    for a in out.get("areas", []):
        if a["k"] == "water":
            water.add(pairs(a["p"]), "water")
    def on_map(x, z):
        return inner.contains(x, z) and not water.inside(x, z)

    def door(x, z):
        hit = roads_grid.nearest(x, z, DOOR_REACH)
        return [round(hit[1][0], 1), round(hit[1][1], 1)] if hit else None

    # --- convenience shops ---------------------------------------------------------------
    shops = []
    for e in els:
        t = e.get("tags", {})
        if t.get("shop") != "convenience":
            continue
        lv = _first_num(t.get("level", "0"))
        if lv is not None and lv < 0:
            continue   # in an underpass or a station's passage: not on a street
        p = bake_osm.element_point(e, nodes, ways)
        if p is None or not on_map(*p):
            continue
        d = door(*p)
        if d is None:
            continue
        poi = {"k": "convenience", "x": round(p[0], 1), "z": round(p[1], 1), "door": d}
        if "żabka" in (t.get("brand", "") + " " + t.get("name", "")).lower():
            poi["fr"] = 1
        if lv:
            poi["lv"] = lv
        shops.append(poi)

    # --- metro entrances -----------------------------------------------------------------
    stations = []
    for e in els:
        t = e.get("tags", {})
        if e["type"] == "node" and t.get("railway") == "station" and t.get("station") == "subway" and t.get("name"):
            stations.append((bake_osm.project(e["lat"], e["lon"]), t["name"]))
    through = {}   # node id -> ways through it
    entrance_ids = {e["id"] for e in els if e["type"] == "node" and e.get("tags", {}).get("railway") == "subway_entrance"}
    for w in ways.values():
        for k, i in enumerate(w.get("nodes", [])):
            if i in entrance_ids:
                through.setdefault(i, []).append((w, k))
    metros = []
    for e in els:
        t = e.get("tags", {})
        if e["type"] != "node" or t.get("railway") != "subway_entrance":
            continue
        x, z = bake_osm.project(e["lat"], e["lon"])
        if not on_map(x, z):
            continue
        down, how, street, canopy = None, "", False, False
        for w, k in through.get(e["id"], []):
            wt = w.get("tags", {})
            ids = w["nodes"]
            below = (wt.get("tunnel") not in (None, "no") or (_first_num(wt.get("layer", "0")) or 0) < 0
                     or wt.get("indoor") not in (None, "no") or (_first_num(wt.get("level", "0")) or 0) < 0)
            if wt.get("highway") and not below and wt.get("highway") != "steps":
                street = True
            if wt.get("highway") == "steps" or (wt.get("highway") and below):
                # Down the stair: along it when it is tagged incline=down (or up, reversed), else
                # away from the entrance into the way.
                nxt = ids[k + 1] if k + 1 < len(ids) else ids[k - 1]
                if wt.get("incline") == "up" and k > 0:
                    nxt = ids[k - 1]
                elif wt.get("incline") == "down" and k + 1 < len(ids):
                    nxt = ids[k + 1]
                if nxt in nodes and down is None:
                    q = bake_osm.project(*nodes[nxt])
                    if math.hypot(q[0] - x, q[1] - z) > 0.3:
                        down, how = (q[0] - x, q[1] - z), "steps"
            elif wt.get("building") in ("roof", "transportation") or wt.get("man_made") == "canopy":
                canopy = True
                ring = [bake_osm.project(*nodes[i]) for i in ids[:-1] if i in nodes]
                if len(ring) >= 3 and down is None:
                    c = bake_osm.centroid(ring)
                    if math.hypot(c[0] - x, c[1] - z) > 0.3:
                        down, how = (c[0] - x, c[1] - z), "canopy"
        if down is None:
            best = None
            for p in out.get("paths", []):
                if p["k"] != "foot" or "dk" in p:
                    continue
                pts = pairs(p["p"])
                if not any(abs(a[0] - x) < 40 and abs(a[1] - z) < 40 for a in pts):
                    continue
                for a, b in zip(pts, pts[1:]):
                    d = seg_dist(x, z, a, b)
                    if best is None or d < best[0]:
                        best = (d, (b[0] - a[0], b[1] - a[1]))
            if best and best[0] < 25.0:
                down, how = best[1], "footway"
        poi = {"k": "subway_entrance", "x": round(x, 1), "z": round(z, 1)}
        if down is not None:
            poi["yaw"] = round(math.atan2(down[0], down[1]), 2)
            poi["f"] = how
        near = min(((math.hypot(sx - x, sz - z), n) for (sx, sz), n in stations), default=(math.inf, ""))
        if near[0] <= STATION_REACH:
            poi["st"] = near[1]
        if t.get("ref"):
            poi["ref"] = t["ref"]
        # Off an underground passage only: every way through it is below ground (no street-level
        # way, no canopy it stands on) and it isn't tagged level=0.
        if not street and not canopy and through.get(e["id"]) and t.get("level") != "0":
            poi["u"] = 1
        metros.append(poi)

    # --- city bike docks -------------------------------------------------------------------
    docks = []
    for e in els:
        t = e.get("tags", {})
        if t.get("amenity") != "bicycle_rental":
            continue
        p = bake_osm.element_point(e, nodes, ways)
        if p is None or not on_map(*p):
            continue
        poi = {"k": "bicycle_rental", "x": round(p[0], 1), "z": round(p[1], 1)}
        ring = [bake_osm.project(*nodes[i]) for i in e.get("nodes", [])[:-1] if i in nodes] if e["type"] == "way" else []
        if len(ring) >= 3:
            # The long side's direction (the rack row) and its length.
            a, b = max(zip(ring, ring[1:] + ring[:1]), key=lambda s: math.hypot(s[1][0] - s[0][0], s[1][1] - s[0][1]))
            poi["yaw"] = round(math.atan2(b[0] - a[0], b[1] - a[1]), 2)
            poi["l"] = round(math.hypot(b[0] - a[0], b[1] - a[1]), 1)
        else:
            hit = roads_grid.nearest(p[0], p[1], 40.0)
            if hit:
                pts = pairs(hit[2]["p"])
                a, b = min(zip(pts, pts[1:]), key=lambda s: seg_dist(p[0], p[1], s[0], s[1]))
                poi["yaw"] = round(math.atan2(b[0] - a[0], b[1] - a[1]), 2)
        docks.append(poi)

    # --- the addresses the address bake leaves out --------------------------------------------
    have = {p["name"] for p in pois if p["k"] == "address"}
    extra = []
    for street, number in EXTRA_ADDRESSES:
        found = []
        for e in els:
            t = e.get("tags", {})
            if t.get("addr:street") == street and t.get("addr:housenumber", "").lower() == number.lower():
                rank = 0 if e["type"] != "node" and t.get("building") else (1 if not (t.get("amenity") or t.get("shop")) else 2)
                found.append((rank, e))
        if not found:
            print(f"street pois: no OSM element has the address {street} {number}")
            continue
        found.sort(key=lambda f: f[0])
        e = found[0][1]
        name = f'{street} {e["tags"]["addr:housenumber"]}'
        p = bake_osm.element_point(e, nodes, ways)
        if name in have or p is None or not on_map(*p):
            continue
        d = door(*p)
        if d is None:
            continue
        extra.append({"k": "address", "name": name, "x": round(p[0], 1), "z": round(p[1], 1), "door": d, "v": 1})
        have.add(name)

    solids = Solids(out, lod2, kerb_points(els, nodes), metros)
    zones, scooters = scatter(out, els, solids, shops, metros, water)
    pois += shops + metros + docks + extra + zones + scooters
    counts = {"convenience": len(shops), "subway_entrance": len(metros), "bicycle_rental": len(docks),
              "address (extra)": len(extra), "scooter_zone": len(zones), "scooter": len(scooters)}
    poses = {}
    for s in scooters:
        poses[s["p"]] = poses.get(s["p"], 0) + 1
    print("street pois: " + ", ".join(f"{k} {v}" for k, v in counts.items()) + "; scooter poses: "
          + ", ".join(f"{k} {poses[k]}" for k in sorted(poses)))
    return counts


def kerb_points(els, nodes):
    """The kerb ramps and crossings OpenStreetMap maps as nodes (kerb=*, barrier=kerb, highway=crossing)."""
    import bake_osm
    out = []
    for e in els:
        if e["type"] != "node":
            continue
        t = e.get("tags", {})
        if t.get("highway") == "crossing" or t.get("barrier") == "kerb" or t.get("kerb") in ("lowered", "flush", "raised", "no"):
            out.append(bake_osm.project(e["lat"], e["lon"]))
    return out


def in_hero(x, z):
    return HERO[0] <= x < HERO[2] and HERO[1] <= z < HERO[3]


def scatter(data, els, solids, shops, metros, water):
    """The zones and the scooters (parodies.md 5.2): returns (zone pois, scooter pois)."""
    import bake_osm
    shape = solids.shape
    # Anchors: what a footway point must be near.
    anchors = Segs()
    stops = Segs()      # the stops OpenStreetMap maps (a bus shelter's roof is by one)
    g = data["graph"]
    nb = {}
    for e in g["edges"]:
        if e.get("br") or "dk" in e or "tn" in e:
            continue
        nb.setdefault(e["a"], set()).add(e["b"])
        nb.setdefault(e["b"], set()).add(e["a"])
    nodes_xy = g["nodes"]
    for n in sorted(nb):
        if len(nb[n]) >= 3:
            x, z = nodes_xy[2 * n], nodes_xy[2 * n + 1]
            anchors.add((x, z), (x, z), NEAR_JUNCTION, "junction")
    for e in els:
        t = e.get("tags", {})
        if e["type"] == "node" and (t.get("highway") == "bus_stop" or t.get("railway") == "tram_stop"
                                     or t.get("public_transport") == "platform"):
            x, z = bake_osm.project(e["lat"], e["lon"])
            anchors.add((x, z), (x, z), NEAR_STOP, "stop")
            stops.add((x, z), (x, z), 15.0, "stop")
    sh = data.get("shelters", [])
    for i in range(0, len(sh) - 2, 3):
        anchors.add((sh[i], sh[i + 1]), (sh[i], sh[i + 1]), NEAR_STOP, "stop")
    for m in metros:
        if not m.get("u"):
            anchors.add((m["x"], m["z"]), (m["x"], m["z"]), NEAR_METRO, "metro")
    river = max((pairs(a["p"]) for a in data["areas"] if a["k"] == "water"), key=lambda r: abs(_area(r)), default=[])
    anchors.add_line(river + river[:1], NEAR_RIVER, "boulevard")
    for a in data["areas"]:
        if a["k"] == "park":
            pts = pairs(a["p"])
            anchors.add_line(pts + pts[:1], NEAR_PARK, "park edge")
    footways = Segs()
    for p in data.get("paths", []):
        if p["k"] == "foot" and "dk" not in p:
            footways.add_line(pairs(p["p"]), p["w"] * 0.5 + 1.0, "footway")
    green = Polys()
    for a in data["areas"]:
        if a["k"] in ("grass", "park"):
            green.add(pairs(a["p"]), a["k"])

    # Footway samples near an anchor, by 500 m cell.
    samples = {}
    for p in data["paths"]:
        if p["k"] != "foot" or "dk" in p:
            continue
        pts = pairs(p["p"])
        half = max(0.0, p["w"] * 0.5 - 0.5)
        for a, b in zip(pts, pts[1:]):
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            if ln < 0.5:
                continue
            ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            n = int(ln // SAMPLE)
            for k in range(n + 1):
                s = (k + 0.5) * ln / (n + 1)
                side = (h01("side", a[0], a[1], k) * 2.0 - 1.0) * min(half, 0.5)
                x, z = a[0] + ux * s - uz * side, a[1] + uz * s + ux * side
                why = anchors.near(x, z)
                if why is None:
                    continue
                key = (int(math.floor(x / CELL)), int(math.floor(z / CELL)))
                samples.setdefault(key, []).append((h01("order", x, z), x, z, math.atan2(ux, uz), why[0]))
    for v in samples.values():
        v.sort()

    # Each cell's quota: the density times its land (on the map, not water), from a 25 m lattice.
    quota = {}
    total = 0
    x0, z0, x1, z1 = shape
    for i in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
        for j in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
            land = hero = 0
            for a in range(20):
                for b in range(20):
                    x, z = i * CELL + (a + 0.5) * 25.0, j * CELL + (b + 0.5) * 25.0
                    if shape.contains(x, z) and not water.inside(x, z):
                        land += 1
                        hero += 1 if in_hero(x, z) else 0
            km2 = land * 625.0 / 1e6
            want = (hero * PER_KM2_HERO + (land - hero) * PER_KM2_OTHER) * 625.0 / 1e6
            q = int(math.floor(want + h01("quota", i, j)))
            if km2 > 0 and q > 0:
                quota[(i, j)] = q
                total += q

    zones, scooters = [], []
    taken = Segs()      # placed scooters and zones, for spacing

    def cell_of(x, z):
        return (int(math.floor(x / CELL)), int(math.floor(z / CELL)))

    count = {}

    def put(x, z, yaw, pose, **more):
        poi = {"k": "scooter", "x": round(x, 1), "z": round(z, 1), "yaw": round(yaw % (2 * math.pi), 2), "p": pose}
        poi.update(more)
        scooters.append(poi)
        c = cell_of(x, z)
        count[c] = count.get(c, 0) + 1
        taken.add((x, z), (x, z), 1.2, "scooter")

    def free(x, z, r=R, skip=(), foot=False):
        # Tested where the poi will say it is (0.1 m): tools/check_pois.py sees the same point.
        x, z = round(x, 1), round(z, 1)
        if foot and footways.near(x, z) is None:
            return False   # a lying one stays on the footway (its half-width + 1 m)
        return solids.blocked(x, z, r, skip) is None and taken.near(x, z, r) is None

    streets = Segs()
    for r in data["roads"]:
        if r["k"] in STREETS:
            streets.add_line(pairs(r["p"]), ZONE_STREET, "street")
    zone_pts = []

    def try_zone(x, z, yaw):
        """A zone at this footway point if it fits (its corners clear, beside a street, ZONE_SPACING
        from the others), with ZONE_SCOOTERS lying round it: its index, or None."""
        if any(math.hypot(x - zx, z - zz) < ZONE_SPACING for zx, zz in zone_pts) or streets.near(x, z) is None:
            return None
        x, z, yaw = round(x, 1), round(z, 1), round(yaw % (2 * math.pi), 2)
        ux, uz = math.sin(yaw), math.cos(yaw)
        corners = [(x + ux * a * ZONE_SIZE[0] * 0.5 - uz * b * ZONE_SIZE[1] * 0.5,
                    z + uz * a * ZONE_SIZE[0] * 0.5 + ux * b * ZONE_SIZE[1] * 0.5) for a in (-1, 0, 1) for b in (-1, 0, 1)]
        if (not all(solids.blocked(cx, cz, 0.2) is None and taken.near(cx, cz, 0.2) is None for cx, cz in corners)
                or not free(x, z, 0.2, foot=True)):
            return None
        zone_pts.append((x, z))
        zi = len(zones)
        zones.append({"k": "scooter_zone", "x": x, "z": z, "yaw": yaw})
        taken.add((x, z), (x, z), 2.4, "zone")
        # The joke: the zone is empty and they lie round it.
        n = ZONE_SCOOTERS[0] + int(h01("zn", x, z) * (ZONE_SCOOTERS[1] - ZONE_SCOOTERS[0] + 1))
        placed = 0
        for k in range(12):
            if placed >= n:
                break
            along = (h01("za", x, z, k) * 2.0 - 1.0) * 2.8
            across = (1.0 if (k % 2) == 0 else -1.0) * (1.6 + h01("zc", x, z, k) * 0.6)
            px, pz = x + ux * along - uz * across, z + uz * along + ux * across
            if free(px, pz, foot=True):
                put(px, pz, h01("zy", x, z, k) * 2 * math.pi, "lie", zn=zi)
                placed += 1
        return zi

    hero_samples = [smp for v in samples.values() for smp in v if in_hero(smp[1], smp[2])]
    # The egg first: the zone that fits nearest a street exit of Metro Nowy Świat-Uniwersytet
    # (within EGG_REACH) holds the one standing scooter (easter_lezak).
    exits = [(m["x"], m["z"]) for m in metros if m.get("st") == EGG_STATION and not m.get("u")]
    if exits:
        near = sorted((min(math.hypot(x - ex, z - ez) for ex, ez in exits), x, z, yaw) for _, x, z, yaw, _w in hero_samples)
        for d, x, z, yaw in near:
            if d > EGG_REACH:
                break
            zi = try_zone(x, z, yaw)
            if zi is not None:
                zn = zones[zi]
                zn["egg"] = "easter_lezak"
                put(zn["x"] + math.sin(zn["yaw"]) * 0.6, zn["z"] + math.cos(zn["yaw"]) * 0.6, zn["yaw"], "stand", zn=zi)
                break
    if not any(zn.get("egg") for zn in zones):
        print("street pois: no zone fits by Metro Nowy Świat-Uniwersytet: no easter_lezak zone")
    # 1. The zones: hero footway points beside a street, a zone's corners all clear.
    for _, x, z, yaw, _why in sorted(hero_samples, key=lambda smp: h01("zone", smp[1], smp[2])):
        try_zone(x, z, yaw)

    # 2. The odd ones: 1 in ODD_EVERY of the total, 1 in ROOF_EVERY on a shelter's roof.
    n_roof = int(round(total / ROOF_EVERY))
    n_odd = max(0, int(round(total / ODD_EVERY)) - n_roof)
    odd_at = []

    def odd_ok(x, z):
        return all(math.hypot(x - ox, z - oz) >= ODD_SPACING for ox, oz in odd_at)

    shelters = sorted(((h01("roof", sh[i], sh[i + 1]), sh[i], sh[i + 1], sh[i + 2]) for i in range(0, len(sh) - 2, 3)))
    for _, x, z, yaw in shelters:
        if n_roof <= 0:
            break
        if (not odd_ok(x, z) or stops.near(x, z) is None or solids.blocked(x, z, 0.0, skip=("shelter",)) is not None
                or count.get(cell_of(x, z), 0) >= quota.get(cell_of(x, z), 0)):
            continue
        along = (h01("ra", x, z) * 2.0 - 1.0) * 1.2
        # The shelter's roof runs along its local X: (cos yaw, -sin yaw); the scooter's length is its local Z.
        px, pz = x + math.cos(yaw) * along + math.sin(yaw) * 0.08, z - math.sin(yaw) * along + math.cos(yaw) * 0.08
        put(px, pz, yaw + math.pi * 0.5 + (h01("ry", x, z) - 0.5) * 0.5, "roof", h=SHELTER_ROOF)
        odd_at.append((x, z))
        n_roof -= 1
    want = {k: n_odd // len(ODD_KINDS) + (1 if i < n_odd % len(ODD_KINDS) else 0) for i, k in enumerate(ODD_KINDS)}
    # Grass: a lawn point 1.5-3 m off a footway sample.
    if want["grass"]:
        for _, x, z, yaw, _why in sorted((s for v in samples.values() for s in v), key=lambda s: h01("grass", s[1], s[2])):
            if want["grass"] <= 0:
                break
            side = 1.0 if h01("gs", x, z) < 0.5 else -1.0
            off = 2.0 + h01("go", x, z) * 1.5
            px, pz = x - math.cos(yaw) * side * off, z + math.sin(yaw) * side * off
            if not odd_ok(px, pz) or not green.inside(px, pz) or not free(px, pz) or count.get(cell_of(px, pz), 0) >= quota.get(cell_of(px, pz), 0):
                continue
            put(px, pz, h01("gy", x, z) * 2 * math.pi, "grass")
            odd_at.append((px, pz))
            want["grass"] -= 1
    # Bench: lying across its front, 0.75 m out (the bench faces its local -Z).
    bn = data.get("benches", [])
    for _, x, z, yaw in sorted((h01("bench", bn[i], bn[i + 1]), bn[i], bn[i + 1], bn[i + 2]) for i in range(0, len(bn) - 2, 3)):
        if want["bench"] <= 0:
            break
        px, pz = x - math.sin(yaw) * 0.75, z - math.cos(yaw) * 0.75
        if not odd_ok(px, pz) or not free(px, pz, R, skip=("bench",)) or count.get(cell_of(px, pz), 0) >= quota.get(cell_of(px, pz), 0):
            continue
        put(px, pz, yaw + math.pi * 0.5, "bench")
        odd_at.append((px, pz))
        want["bench"] -= 1
    # Frogs: by the door of a corner shop of the parodied chain: out of its building towards the street.
    for poi in sorted((s for s in shops if s.get("fr") and not s.get("lv")), key=lambda s: h01("frogs", s["x"], s["z"])):
        if want["frogs"] <= 0:
            break
        x, z = poi["x"], poi["z"]
        dx, dz = poi["door"][0] - x, poi["door"][1] - z
        ln = math.hypot(dx, dz)
        if ln < 1.0:
            continue
        ux, uz = dx / ln, dz / ln
        s = 0.0
        while s < ln and solids.polys.inside(x + ux * s, z + uz * s) == "building":
            s += 0.5
        s += 1.0
        px, pz = x + ux * s, z + uz * s
        if s > 30.0 or not odd_ok(px, pz) or not free(px, pz) or count.get(cell_of(px, pz), 0) >= quota.get(cell_of(px, pz), 0):
            continue
        put(px, pz, math.atan2(uz, -ux) + (h01("fy", x, z) - 0.5) * 0.8, "frogs")
        odd_at.append((px, pz))
        want["frogs"] -= 1
    # Hedge: half in a hedge beside a footway, sticking out across it.
    hedges = [pairs(line["p"]) for line in data.get("lines", []) if line["k"] == "hedge"]
    hpts = []
    for pts in hedges:
        for a, b in zip(pts, pts[1:]):
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            for k in range(int(ln // 6.0)):
                s = (k + 0.5) * 6.0
                hpts.append((h01("hedge", a[0], a[1], k), a, b, s, ln))
    for _, a, b, s, ln in sorted(hpts):
        if want["hedge"] <= 0:
            break
        ux, uz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
        for side in (1.0, -1.0):
            px, pz = a[0] + ux * s - uz * side * 0.35, a[1] + uz * s + ux * side * 0.35
            if footways.dist(px, pz, "footway") > 3.0:
                continue
            if not odd_ok(px, pz) or not free(px, pz, R, skip=("hedge",)) or count.get(cell_of(px, pz), 0) >= quota.get(cell_of(px, pz), 0):
                continue
            put(px, pz, math.atan2(-uz * side, ux * side) + (h01("hy", px, pz) - 0.5) * 0.4, "hedge")
            odd_at.append((px, pz))
            want["hedge"] -= 1
            break

    # 3. The lying ones fill each cell's quota: one or two at a footway point near an anchor.
    spots = Segs()
    for zx, zz in zone_pts:
        spots.add((zx, zz), (zx, zz), SPOT_SPACING, "spot")
    for key in sorted(samples):
        for _, x, z, yaw, why in samples[key]:
            if count.get(key, 0) >= quota.get(key, 0):
                break
            if spots.near(x, z) is not None or not free(x, z, foot=True):
                continue
            put(x, z, h01("ly", x, z) * 2 * math.pi, "lie")
            spots.add((x, z), (x, z), SPOT_SPACING, "spot")
            if h01("pair", x, z) < PAIR_SHARE and count.get(key, 0) < quota.get(key, 0):
                for k in range(4):
                    a = h01("pa", x, z, k) * 2 * math.pi
                    px, pz = x + math.cos(a) * 1.3, z + math.sin(a) * 1.3
                    if free(px, pz, foot=True):
                        put(px, pz, h01("py", x, z, k) * 2 * math.pi, "lie")
                        break
    short = sum(max(0, q - count.get(k, 0)) for k, q in quota.items())
    print(f"street pois: scooters {len(scooters)} of a density quota of {total} over {len(quota)} cells "
          f"({short} short where the cell has too few clear footway points near a junction, stop, metro exit, "
          f"the river or a park), {len(zones)} zones")
    return zones, scooters


def _area(pts):
    return 0.5 * sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))


def main(argv):
    root = os.path.dirname(TOOLS)
    args = [a for a in argv if not a.startswith("--")]
    out_path = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), None)
    src = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    osm = args[1] if len(args) > 1 else os.path.join(root, "data", "work", "demo", "osm_demo.json")
    with open(src, encoding="utf-8") as f:
        data = json.load(f)
    data["pois"] = [p for p in data["pois"] if p["k"] not in KINDS and not (p["k"] == "address" and p.get("v"))]
    print(f"pois before: {len(data['pois'])}")
    with open(osm, encoding="utf-8") as f:
        els = json.load(f)["elements"]
    nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
    ways = {e["id"]: e for e in els if e["type"] == "way"}
    add(data, els, nodes, ways, os.path.dirname(os.path.abspath(src)))
    print(f"pois after: {len(data['pois'])}")
    if out_path:
        if os.path.abspath(os.path.dirname(out_path)) == os.path.abspath(os.path.join(root, "game", "map")):
            print("bake_street_pois: not writing into game/map: re-bake with tools/bake_osm.py")
            return 2
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
