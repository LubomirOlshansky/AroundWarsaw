"""Young trees the laser scan doesn't have yet (Krajobraz places, 2026-11-02).

    python3 -I tools/planted_trees.py [MAP.json] [--dry]     (rewrites the map in place, idempotent)

The scanned trees (GUGiK, `trees3d`) are older than some of the city's newest streets: when the
scan was flown, ul. Bracka's woonerf (the Nowe Centrum Warszawy programme, RS Architektura
Krajobrazu, opened summer 2024) was still being planted, so the map has its new beds (OSM
`leisure=garden` pieces, `areas` kind "park"), benches and bike racks but only 9 of its
about 33 young trees. This module plants the rest on the finished map data: bake_osm.py calls
`apply(out)` after snap_props (before the content POIs, which keep clear of trees); this file is
also a command line tool for a map that is already baked, as the cloud has no OSM download.

Each PLACE names its zone (game x, z), its target number of young trees counting the scanned
young ones already there (a tree no taller than YOUNG_MAX m), its species mix, and which `areas`
kinds count as beds (default "park"; Chmielna's beds by Varso are mapped as "grass"). One tree
goes into every bed of at least BED_MIN m² that has no tree within TREE_GAP m, a second into a
bed of at least BED_TWO m² when it fits, until the target is reached; a spot must be clear of
buildings, carriageways, benches, racks, lamps and other poles (bake_street_pois.Solids).
Trees are appended to `trees3d` (x, z, top, crown radius, crown base, kind 0) with their crown
scale in `trees3d_crown` (bake_osm.crown_scales). A spot that already has a tree within
SAME m is skipped, so running it twice adds nothing. Deterministic; standard library only.

A PLACE may give a centre `line` (game x, z) and a `half` width instead of a `zone` polygon (ul.
Chmielna, 2026-11-02): its zone is the band round the line, and its `mixes` pick the species
by the distance along the line ([s0, s1, mix]). `bed_min` and `bed_two` lower BED_MIN and BED_TWO for a
street of tree pits, `skip` names solids a trunk may touch (a bed's own low fence), `count_all` counts every tree in the zone towards the target (old trees that were kept;
the project's number is the street's total), and `paving`, when set, re-tags the OSM pedestrian
area surfaces (`surfaces` kind "paving") whose centre is in the zone, e.g. "granite" for the new
slabs (map_builder.gd SURFACE_STYLE).

Sources for Bracka: krajobraz.com.pl/projekt/ul-bracka/ (Al. Jerozolimskie to Krucza, 2023-24,
for Zarząd Terenów Publicznych), whiteMAD 26.04.2024 (33 trees replacing a temporary car park:
planes, bird cherry, cherries, maples), Architektura & Biznes (a woonerf, "nearly 40" trees,
benches and racks, a triangular square under the trees).
Sources for Varso: Wikipedia "Varso" (new pavements, lamps, benches, bike stands, shrubs and
trees round Chmielna), Eurobuild CEE "Chmielna zyska przy Varso" (almost 200 m of Chmielna,
wider pavements, greener), ZinCo's Varso Place reference (~4,000 m² of green on the garage slabs).
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as P  # noqa: E402

MAP = os.path.join(ROOT, "game", "map", "centrum.json")
YOUNG_MAX = 9.0     # a scanned tree no taller than this (m) counts as one of the new plantings
BED_MIN = 7.0       # a bed smaller than this (m²) holds shrubs and perennials, no tree
BED_TWO = 35.0      # a bed this big takes a second tree
TREE_GAP = 3.5      # no new tree this near another tree's trunk
SAME = 0.5          # a tree this near the spot is this module's own from an earlier run
CLEAR = 0.45        # the trunk's disc that must be clear of the solids

# Young street trees, 2-3 years after planting (the scanned young ones on Bracka: 6.5-7.4 m
# tall, crown radius 1.8-2.1 m, crown base 2.1-2.5 m): [top, crown radius, crown base].
SPECIES = {
    "plane": [7.6, 2.2, 2.6],         # platan
    "maple": [7.0, 2.0, 2.4],         # klon
    "cherry": [5.6, 1.9, 1.9],        # wiśnia (ozdobna)
    "bird_cherry": [6.2, 1.8, 2.1],   # czeremcha
    # Chmielna (2026-11-02): narrow-crowned street elms for the narrow stretches, a linden and a
    # black locust as the project's single trees.
    "elm": [7.8, 1.6, 2.6],           # wiąz (a narrow street cultivar)
    "linden": [7.0, 2.0, 2.4],        # lipa
    "robinia": [6.8, 2.0, 2.6],       # robinia
    # The stadium's grounds (K9, 2012, ten years on): lime and plane rows on the avenues and the
    # pollarded willows of the Mazovian landscape (a short trunk, a broad knobbly head).
    "linden_row": [9.4, 2.7, 3.1],    # lipa
    "plane_row": [10.2, 3.0, 3.4],    # platan
    "willow": [6.4, 2.9, 2.0],        # wierzba głowiasta
    # Norblin and Browary (K6, 2021): the court's multi-stem planes trained as candelabras (a short
    # trunk, a broad head), and the Central Garden's lindens, birches and maples over the vaults.
    "candelabra": [10.5, 3.6, 3.0],   # platan kandelabrowy
    "garden_linden": [7.2, 2.4, 2.4],   # lipa
    "birch": [8.0, 1.9, 2.8],         # brzoza
    "garden_maple": [7.0, 2.2, 2.3],  # klon
}

# ul. Chmielna, Nowy Świat to Pasaż Wiecha (RS Architektura Krajobrazu for ZTP, opened 2024): the
# pedestrian street's centre (the OSM footway west of Plac Pięciu Rogów, the living street across
# it, the footway east of it), west to east; s is metres along it from Pasaż Wiecha.
CHMIELNA = [(-851.0, 253.2), (-809.3, 238.8), (-751.2, 218.7), (-703.5, 203.6), (-643.3, 184.9),
            (-626.7, 179.7), (-580.1, 168.7), (-566.2, 163.8), (-532.4, 151.9), (-475.0, 131.7),
            (-433.3, 117.0), (-389.8, 101.8), (-324.9, 79.0), (-312.3, 74.6)]


# Browary Warszawskie's Central Garden (photo report browary.md): the curving gravel path in an S
# from the south gate (between two of the scanned trees) to the north slab, 2.4 m wide, and the
# two clearings beside its bends with the white café tables and dark-blue parasols. landmarks.gd draws them from the
# same numbers (BROWARY_PATH, BROWARY_CLEARINGS): keep the two lists equal.
BROWARY_PATH = [(-2459.0, -84.0), (-2456.4, -87.3), (-2454.7, -90.6), (-2454.3, -93.6), (-2455.5, -96.4),
                (-2458.1, -99.0), (-2461.5, -101.5), (-2464.9, -104.0), (-2467.5, -106.6), (-2468.7, -109.4),
                (-2468.3, -112.4), (-2466.6, -115.7), (-2464.0, -119.0)]
BROWARY_CLEARINGS = [(-2459.4, -93.2), (-2463.6, -109.8)]
PATH_CLEAR = 2.9       # a trunk this far from the path's centre line (1.75 m to its edging)
CLEARING_R = 4.8       # and this far from a clearing's middle (landmarks.gd BROWARY_CLEARING_R 4.2)
PATHS = {"browary": (BROWARY_PATH, BROWARY_CLEARINGS)}

# Courts OpenStreetMap maps inside a building's outline (multipolygon holes the bake drops), from
# the Mac's photo reports. Each is carved out of the outline as a notch from the nearest wall:
# [building name, the court's middle, half width along that wall, depth from the wall (m), and
# optionally the point on the wall the notch leaves from (else the wall's nearest point)]. The
# same notch goes out of the building and of its landmark outline, so the car, the trees, the
# crowds and landmarks.gd's model all see the open court. Fabryka Norblina's (norblin.md): the
# court of candelabra planes north of the glass street, in "Plater", and the west block's small
# garden court, in "Galwan"; both open onto the glass street (*guess*: the ortho shows the courts,
# not whether a passage closes them).
COURTS = [
    ["Plater", (-2232.0, 181.5), 8.0, 30.0],
    # (Galwan's nearest outline point is a corner: the notch leaves from its south wall.)
    ["Galwan", (-2310.5, 211.5), 6.5, 30.0, (-2303.6, 229.7)],
]

PLACES = [
    {
        "id": "bracka",
        "name": "ul. Bracka, Al. Jerozolimskie to Krucza (woonerf, 2024)",
        # Between CeDeT (Krucza 50) and the houses of Bracka 18-20: the wedge by Krucza's end,
        # the diagonal street and the triangle by Al. Jerozolimskie.
        "zone": [(-562.0, 205.0), (-500.0, 200.0), (-430.0, 262.0), (-412.0, 300.0), (-450.0, 306.0),
                 (-520.0, 268.0), (-562.0, 252.0)],
        "target": 33,
        "mix": ["plane", "maple", "cherry", "plane", "bird_cherry", "maple", "cherry", "plane"],
    },
    {
        "id": "varso",
        "name": "ul. Chmielna by Varso Place, Al. Jana Pawła II to Varso 2's west end (2022)",
        # The south pavement between Chmielna's carriageway and the fronts of Varso Tower, Varso 1
        # and Varso 2: the street beds OSM maps as grass along Varso 1 and 2 (10-38 m² each). The
        # 2023 scan has 15 trees here, all of 11 m or more (the nursery stock planted with the
        # buildings); the beds it left bare get one young tree each (docs/landmarks/specs/varso_place.md S1).
        "zone": [(-1596.0, 532.0), (-1603.0, 527.0), (-1690.0, 560.0), (-1768.0, 590.0), (-1830.0, 612.0),
                 (-1822.0, 630.0), (-1790.0, 622.0), (-1745.0, 606.0), (-1700.0, 588.0), (-1660.0, 570.0),
                 (-1620.0, 553.0), (-1598.0, 560.0)],
        "target": 6,
        "beds": ("park", "grass"),
        "mix": ["maple", "plane", "maple", "bird_cherry"],
    },
    {
        "id": "chmielna",
        "name": "ul. Chmielna, Nowy Świat to Pasaż Wiecha (granite and elms, 2024)",
        # Front to front along the street, from Pasaż Wiecha's corner (Ali's square, s 0) to
        # the mouth on Nowy Świat (s 565).
        "zone": None,
        "line": CHMIELNA,
        "half": 13.0,
        # 95 trees (Architektura & Biznes), 88 of them in the city's list (Super Express: 57 elms,
        # 24 planes, 5 cherries, a linden, a black locust), rows both sides ("szpalery") placed so
        # the fronts stay in view and the café gardens fit. OSM has the new layout: a tree pit
        # every few metres along both sides (2.4-8 m² beds) and the bigger beds of the squares by
        # Kino Atlantic and Pasaż Wiecha; the scan has 20 trees in the zone, mostly the square's
        # old ones, kept. One tree per pit; every tree in the zone counts towards the 95.
        "target": 95,
        "count_all": True,
        "bed_min": 2.4,
        "bed_two": 20.0,
        # The squares' beds are edged with low fences (OSM barrier=fence round each bed).
        "skip": ["fence"],
        "paving": "granite",
        "mix": ["elm"],
        # [s0, s1, mix] along the line: planes on the two squares (Ali's by Pasaż Wiecha and
        # Kino Atlantic's with the fountain), elms in two rows on the narrow stretches either
        # side of Plac Pięciu Rogów, the odd cherry, linden and black locust.
        "mixes": [
            [0.0, 60.0, ["plane", "plane", "cherry", "plane"]],
            [60.0, 146.0, ["plane", "plane", "linden", "plane", "plane", "cherry", "plane"]],
            [146.0, 296.0, ["elm"]],
            [296.0, 600.0, ["elm", "elm", "elm", "elm", "plane", "elm", "elm", "cherry", "elm", "robinia",
                            "elm", "elm", "plane"]],
        ],
    },
    {
        # K9: GMP's grounds round the Stadion Narodowy (landscape: RS Architektura Krajobrazu, 2012):
        # tree rows along the wide entrance avenues (the mapped plazas that run out of the bowl)
        # and groups of pollarded willows on the lawns between the avenues.
        "id": "stadion",
        "name": "Stadion Narodowy grounds (avenues and willows, 2012)",
        "kind": "grounds",
        "centre": (1480.5, -605.1),
        "ring": (150.0, 330.0),       # metres from the centre: the grounds' zone
        "row_step": 9.0,              # trunk spacing along an avenue's edge
        "row_inset": 1.4,             # how far inside the plaza's long edge the row stands
        "row_mix": ["linden_row", "linden_row", "plane_row"],
        "willow_groups": 9,
        "willow_gap": 45.0,           # groups at least this far apart
        "willow_min_area": 1500.0,    # a lawn at least this big (m²) takes a group
    },
    {
        # K6, rebuilt from the Mac's photo report (docs/landmarks/photo-reports/norblin.md, GUGiK
        # ortho, 2026-11-02): Fabryka Norblina's court of big multi-stem planes trained as
        # candelabras, 3-4 broad crowns (7-9 m across) at x -2239..-2225, z 173..190, in the yard
        # north of the glass street. OSM maps the yard inside the outline of the office block
        # "Plater"; COURTS carves it out first. (The first K6 pass planted them in the court of
        # "Modsen", north of ul. Łucka: the wrong block.)
        "id": "norblin",
        "name": "Fabryka Norblina's court (candelabra planes, 2021)",
        "kind": "garden",
        "zone": [(-2240.0, 172.0), (-2223.0, 172.0), (-2223.0, 191.0), (-2240.0, 191.0)],
        "target": 4,
        "step": 1.0,
        "gap": 7.0,                   # candelabras stand well apart
        "mix": ["candelabra"],
    },
    {
        # The report's other Norblin trees: a row of young trees along the Żelazna front, small
        # trees in planters on the glass street's south side, and the west block's small garden
        # court (carved out of "Galwan" by COURTS).
        "id": "norblin_zelazna",
        "name": "Fabryka Norblina, the young trees on the Żelazna front",
        "kind": "garden",
        "zone": [(-2193.0, 201.0), (-2183.0, 201.0), (-2183.0, 228.0), (-2193.0, 228.0)],
        "target": 4,
        "step": 1.0,
        "gap": 6.0,
        "mix": ["linden", "maple"],
    },
    {
        "id": "norblin_street",
        "name": "Fabryka Norblina, the planters along the glass street",
        "kind": "garden",
        "zone": [(-2280.0, 222.0), (-2220.0, 222.0), (-2220.0, 237.0), (-2280.0, 237.0)],
        "target": 4,
        "step": 1.0,
        "gap": 9.0,
        "mix": ["cherry", "bird_cherry"],
    },
    {
        "id": "norblin_west",
        "name": "Fabryka Norblina, the west block's garden court",
        "kind": "garden",
        "zone": [(-2317.0, 204.0), (-2304.0, 204.0), (-2304.0, 219.0), (-2317.0, 219.0)],
        "target": 2,
        "step": 1.0,
        "gap": 5.0,
        "mix": ["birch", "garden_maple"],
    },
    {
        # K6, rebuilt from the Mac's photo report (docs/landmarks/photo-reports/browary.md, GUGiK
        # ortho, 2026-11-02): Browary Warszawskie's Central Garden on the slab over the Leżakownia,
        # the lawn OSM maps as a park at x -2480..-2440, z -123..-79, densely planted with about
        # 20-25 young lindens, birches and maples (3-6 m crowns) round an S-shaped gravel path
        # (BROWARY_PATH) with café tables in two clearings (BROWARY_CLEARINGS). 22 crowns in all,
        # counting the scan's five along the south edge. (The first K6 pass planted 12 on the
        # paved yard west of the lawn.)
        "id": "browary",
        "name": "Browary Warszawskie's Central Garden (2021)",
        "kind": "garden",
        "zone": [(-2471.2, -79.4), (-2480.3, -114.9), (-2476.3, -115.8), (-2476.4, -116.4),
                 (-2448.1, -122.9), (-2440.1, -88.2), (-2441.3, -88.0), (-2441.2, -87.3)],
        "inset": 1.6,                 # trunks this far inside the lawn's edge
        "target": 22,
        "step": 1.0,
        "gap": 4.4,
        "path": "browary",
        # F's look check (2026-11-03): group the trees, so the main path and the two cafe
        # clearings read apart from them. The young trees stand in four clumps on the lawn (the
        # scanned five along the south edge stay), 3.2 m apart inside each clump.
        "groups": [(-2468.0, -89.5, 5.5), (-2447.0, -99.0, 6.0), (-2474.0, -105.0, 5.5), (-2454.0, -114.5, 5.5)],
        "group_gap": 3.2,
        "mix": ["garden_linden", "birch", "garden_maple", "garden_linden", "birch"],
    },
    {
        # The report's tree group south-east of the garden, by Willa Schielego.
        "id": "browary_se",
        "name": "Browary Warszawskie, the tree group by Willa Schielego",
        "kind": "garden",
        "zone": [(-2440.0, -76.0), (-2418.0, -76.0), (-2418.0, -58.0), (-2440.0, -58.0)],
        "target": 4,
        "step": 1.0,
        "gap": 4.5,
        "mix": ["garden_linden", "garden_maple"],
    },
]


# ul. Chmielna's furniture (K2b, 2026-11-02): the project counts 64 pieces (urban chairs, benches
# and long benches with flowing shapes); OSM maps 4 benches in the band. The game has one bench
# model, so each piece is a bench, a seat every FURNITURE_STEP m along the street, alternate sides,
# at the first pavement spot (not a bed, tree pit, café or lane) that is clear, turned to face the
# street's middle. Kept FURNITURE_NS m off Nowy Świat's roads (the Chopin benches there are black
# granite with the button).
FURNITURE_TARGET = 64
FURNITURE_STEP = 7.5
FURNITURE_T = [2.6 + 0.6 * i for i in range(10)]   # metres off the centre line, nearest first
FURNITURE_TREE_GAP = 2.3
FURNITURE_BENCH_GAP = 3.6
FURNITURE_NS = 16.0


def _hash01(x, z, salt):
    """A stable 0..1 from a position (never Python's hash)."""
    return (math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453) % 1.0


def _area(poly):
    return abs(sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1]
                   for i in range(len(poly)))) * 0.5


def _inside(x, z, poly):
    hit = False
    for i in range(len(poly)):
        (ax, az), (bx, bz) = poly[i], poly[i - 1]
        if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
            hit = not hit
    return hit


def _spots(bed, n):
    """Up to n trunk spots inside a bed: its middle for one, its long axis' thirds for two."""
    cx = sum(p[0] for p in bed) / len(bed)
    cz = sum(p[1] for p in bed) / len(bed)
    if n == 1:
        return [(cx, cz)]
    far = max(bed, key=lambda p: (p[0] - cx) ** 2 + (p[1] - cz) ** 2)
    dx, dz = far[0] - cx, far[1] - cz
    return [(cx + dx * 0.4, cz + dz * 0.4), (cx - dx * 0.4, cz - dz * 0.4)]


class Line:
    """A polyline with distance along it (s) and square to it (t, + up the map's side)."""

    def __init__(self, pts):
        self.segs = []
        acc = 0.0
        for (ax, az), (bx, bz) in zip(pts, pts[1:]):
            n = math.hypot(bx - ax, bz - az)
            self.segs.append((ax, az, (bx - ax) / n, (bz - az) / n, n, acc))
            acc += n
        self.length = acc

    def at(self, s):
        """(x, z, ux, uz) at s: the point and the line's direction there."""
        for ax, az, ux, uz, n, a0 in self.segs:
            if s <= a0 + n:
                return ax + ux * (s - a0), az + uz * (s - a0), ux, uz
        ax, az, ux, uz, n, _ = self.segs[-1]
        return ax + ux * n, az + uz * n, ux, uz

    def along(self, x, z):
        """s of the line's nearest point to (x, z)."""
        best = (1e18, 0.0)
        for ax, az, ux, uz, n, a0 in self.segs:
            u = max(0.0, min(n, (x - ax) * ux + (z - az) * uz))
            d = (x - ax - ux * u) ** 2 + (z - az - uz * u) ** 2
            if d < best[0]:
                best = (d, a0 + u)
        return best[1]

    def zone(self, half):
        """A polygon round the line, `half` m each side (mitred joints)."""
        left, right = [], []
        pts = [self.at(0.0)] + [self.at(a0 + n) for _, _, _, _, n, a0 in self.segs]
        for i, (x, z, ux, uz) in enumerate(pts):
            if 0 < i < len(pts) - 1:
                _, _, vx, vz = self.at(self.segs[i][5] + 0.01)
                ux, uz = (ux + vx), (uz + vz)
                k = math.hypot(ux, uz)
                ux, uz = ux / k, uz / k
            nx, nz = uz, -ux
            left.append((x + nx * half, z + nz * half))
            right.append((x - nx * half, z - nz * half))
        return left + right[::-1]


def zone_of(place):
    if place.get("zone"):
        return place["zone"]
    return Line(place["line"]).zone(place["half"])


def _poly(a):
    return list(zip(a["p"][0::2], a["p"][1::2]))


def plant_grounds(data, place, solids=None):
    """A rowed-and-willowed park round a landmark: a tree row down both long edges of every plaza
    strip in the ring (the entrance avenues), and groups of pollarded willows on the biggest
    lawns. Skips any spot near an existing tree (so a second run adds nothing)."""
    cx, cz = place["centre"]
    lo, hi = place["ring"]
    solids = solids or P.Solids(data)
    trees = data.get("trees3d", [])
    taken = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)
             if lo - 40 < math.hypot(trees[i] - cx, trees[i + 1] - cz) < hi + 40]
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address"]
    out = []

    def ok(x, z, poly=None):
        r = math.hypot(x - cx, z - cz)
        if r < lo - 30 or r > hi:
            return False
        if poly is not None and not _inside(x, z, poly):
            return False
        if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken):
            return False
        if any(math.hypot(x - px, z - pz) < 1.5 for px, pz in pois):
            return False
        return not solids.blocked(x, z, CLEAR, skip=("tree",))

    # Avenues: the plaza strips (long, narrow) inside the ring.
    for a in sorted(data.get("areas", []), key=lambda a: a["p"][:2]):
        if a["k"] != "plaza":
            continue
        poly = _poly(a)
        mx = sum(p[0] for p in poly) / len(poly)
        mz = sum(p[1] for p in poly) / len(poly)
        if not lo - 30 < math.hypot(mx - cx, mz - cz) < hi:
            continue
        # principal axis by the covariance of the vertices
        sxx = sum((p[0] - mx) ** 2 for p in poly)
        szz = sum((p[1] - mz) ** 2 for p in poly)
        sxz = sum((p[0] - mx) * (p[1] - mz) for p in poly)
        ang = 0.5 * math.atan2(2 * sxz, sxx - szz)
        ux, uz = math.cos(ang), math.sin(ang)
        vx, vz = -uz, ux
        us = [(p[0] - mx) * ux + (p[1] - mz) * uz for p in poly]
        vs = [(p[0] - mx) * vx + (p[1] - mz) * vz for p in poly]
        length, width = max(us) - min(us), max(vs) - min(vs)
        if length < 40.0 or length < width * 1.6:
            continue
        step = place["row_step"]
        n = int((length - 6.0) / step) + 1
        for side in (-1.0, 1.0):
            for i in range(n):
                u = min(us) + 3.0 + i * step
                # walk in from the side's extreme until inside the plaza
                v = max(vs) if side > 0 else min(vs)
                for _ in range(int(width * 2) + 1):
                    if _inside(mx + u * ux + v * vx, mz + u * uz + v * vz, poly):
                        break
                    v -= side * 0.5
                v -= side * place["row_inset"]
                x, z = mx + u * ux + v * vx, mz + u * uz + v * vz
                if not ok(x, z, poly):
                    continue
                mix = place["row_mix"]
                kind = mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]
                out.append(_tree(x, z, kind))
                taken.append((x, z))

    # Willows: groups on the biggest lawns in the ring, kept apart.
    lawns = []
    for a in data.get("areas", []):
        if a["k"] != "grass":
            continue
        poly = _poly(a)
        size = _area(poly)
        mx = sum(p[0] for p in poly) / len(poly)
        mz = sum(p[1] for p in poly) / len(poly)
        if size >= place["willow_min_area"] and lo < math.hypot(mx - cx, mz - cz) < hi:
            lawns.append((size, poly, mx, mz))
    lawns.sort(key=lambda t: (-t[0], t[2]))
    centres = []
    for size, poly, mx, mz in lawns:
        if len(centres) >= place["willow_groups"]:
            break
        heart = None
        for dx, dz in ((0, 0), (20, 0), (-20, 0), (0, 20), (0, -20), (35, 35), (-35, -35)):
            if _inside(mx + dx, mz + dz, poly):
                heart = (mx + dx, mz + dz)
                break
        if heart is None or any(math.hypot(heart[0] - a, heart[1] - b) < place["willow_gap"] for a, b in centres):
            continue
        group = []
        for j in range(7):
            ang = _hash01(heart[0], heart[1], 5 + j) * math.tau
            dist = 2.0 + _hash01(heart[0], heart[1], 20 + j) * 9.0
            x, z = heart[0] + math.cos(ang) * dist, heart[1] + math.sin(ang) * dist
            if len(group) < 5 and ok(x, z, poly):
                group.append(_tree(x, z, "willow"))
                taken.append((x, z))
        if len(group) >= 3:
            out.extend(group)
            centres.append(heart)
    return out




def plant_garden(data, place, solids=None):
    """A court or yard garden (K6): trees on a ring-first grid round the centre (or, with a `zone`,
    round the zone's middle and only inside it, `inset` m from its edge), at spots clear of
    buildings, roads, lamps and the scanned trees (TREE_GAP, or `gap` apart from each other), and
    of the place's `path` (PATHS). `count` trees, or with `target` as many as bring the zone's
    trees to that number. Deterministic."""
    zone = place.get("zone")
    if zone:
        xs, zs = [p[0] for p in zone], [p[1] for p in zone]
        cx, cz = (min(xs) + max(xs)) * 0.5, (min(zs) + max(zs)) * 0.5
        r = math.hypot(max(xs) - min(xs), max(zs) - min(zs)) * 0.5
    else:
        cx, cz = place["centre"]
        r = place["radius"]
    step = place["step"]
    inset = place.get("inset", 0.0)
    solids = solids or P.Solids(data)
    trees = data.get("trees3d", [])
    taken = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)
             if math.hypot(trees[i] - cx, trees[i + 1] - cz) < r + 10]
    count = place.get("count", 0)
    if zone and "target" in place:
        count = place["target"] - sum(1 for x, z in taken if _inside(x, z, zone))
    path, clearings = PATHS.get(place.get("path"), ([], []))
    edges = list(zip(zone, zone[1:] + zone[:1])) if zone else []
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address"]
    cands = []
    n = int(r / step)
    for i in range(-n, n + 1):
        for j in range(-n, n + 1):
            x, z = cx + i * step, cz + j * step
            d = math.hypot(x - cx, z - cz)
            if d > r:
                continue
            if zone and not _inside(x, z, zone):
                continue
            if inset and any(P.seg_dist(x, z, a, b) < inset for a, b in edges):
                continue
            cands.append((round(d, 3), x, z))
    cands.sort()

    def clear(x, z):
        """The spot is free of the place's path and clearings, POIs and every solid."""
        if any(P.seg_dist(x, z, a, b) < PATH_CLEAR for a, b in zip(path, path[1:])):
            return False
        if any(math.hypot(x - qx, z - qz) < CLEARING_R for qx, qz in clearings):
            return False
        if any(math.hypot(x - px, z - pz) < 1.5 for px, pz in pois):
            return False
        return not solids.blocked(x, z, CLEAR + 0.6, skip=("tree",))

    cands = [c for c in cands if clear(c[1], c[2])]
    out = []
    mine = []
    if place.get("groups"):
        # Clumps: the groups take turns, each its next free spot nearest its middle (clear of
        # the scanned trees by TREE_GAP and of this place's by group_gap).
        groups = place["groups"]
        gap = place.get("group_gap", place["gap"])
        lists = [sorted((math.hypot(x - gx, z - gz), x, z) for _, x, z in cands if math.hypot(x - gx, z - gz) <= gr)
                 for gx, gz, gr in groups]
        moved = True
        while len(out) < count and moved:
            moved = False
            for spots in lists:
                if len(out) >= count:
                    break
                for _, x, z in spots:
                    if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken):
                        continue
                    if any(math.hypot(x - tx, z - tz) < gap for tx, tz in mine):
                        continue
                    mix = place["mix"]
                    out.append(_tree(x, z, mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]))
                    mine.append((x, z))
                    moved = True
                    break
        return out
    if place.get("spread"):
        # A garden, not a court: each tree goes where it is farthest from every tree so far
        # (the scanned ones and this place's), so the crowns spread over the whole lawn.
        pts = [(x, z) for x, z in taken if math.hypot(x - cx, z - cz) < r + 3.0]
        while len(out) < count:
            best = None
            for i, (_, x, z) in enumerate(cands):
                d = min((math.hypot(x - px, z - pz) for px, pz in pts), default=1e9)
                if d >= max(place["gap"], TREE_GAP) and (best is None or d > best[0]):
                    best = (d, x, z)
            if best is None:
                break
            _, x, z = best
            mix = place["mix"]
            out.append(_tree(x, z, mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]))
            pts.append((x, z))
        return out
    for _, x, z in cands:
        if len(out) >= count:
            break
        if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken):
            continue
        if any(math.hypot(x - tx, z - tz) < place["gap"] for tx, tz in mine):
            continue
        mix = place["mix"]
        out.append(_tree(x, z, mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]))
        mine.append((x, z))
    return out


def _notch(ring, court, half, depth, wall=None):
    """The ring with a notch cut from its nearest wall to `court`: `half` m either side along the
    wall, `depth` m in. None when the court's middle is not inside the ring (carved already)."""
    if not _inside(court[0], court[1], ring):
        return None
    n = len(ring)
    best = None
    for i in range(n):
        (ax, az), (bx, bz) = ring[i], ring[(i + 1) % n]
        ex, ez = bx - ax, bz - az
        ln = ex * ex + ez * ez
        u = max(0.0, min(1.0, ((court[0] - ax) * ex + (court[1] - az) * ez) / ln))
        px, pz = ax + ex * u, az + ez * u
        d = math.hypot(court[0] - px, court[1] - pz)
        if best is None or d < best[0]:
            best = (d, px, pz)
    _, bx0, bz0 = best
    if wall:
        bx0, bz0 = wall
    k = math.hypot(court[0] - bx0, court[1] - bz0)
    nx, nz = (court[0] - bx0) / k, (court[1] - bz0) / k                # into the building
    tx, tz = -nz, nx                                                   # along the wall

    def tn(p):
        return (p[0] - bx0) * tx + (p[1] - bz0) * tz, (p[0] - bx0) * nx + (p[1] - bz0) * nz

    def cut(i):
        """Where edge i crosses the notch's sides near the wall: [(t at the side, point)]."""
        a, b = ring[i], ring[(i + 1) % n]
        (ta, na), (tb, nb) = tn(a), tn(b)
        hits = []
        for side in (-half, half):
            if (ta - side) * (tb - side) < 0:
                k = (side - ta) / (tb - ta)
                if abs(na + (nb - na) * k) < 4.0:
                    hits.append((k, side, (a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k)))
        return sorted(hits)

    out = []
    inside_notch = False
    for i in range(n):
        p = ring[i]
        t, nn = tn(p)
        if not (inside_notch or (abs(t) < half and abs(nn) < 4.0)):
            out.append(p)
        for _, side, q in cut(i):
            if not inside_notch:
                out.append(q)
                out.append((bx0 + tx * side + nx * depth, bz0 + tz * side + nz * depth))
                inside_notch = True
            else:
                out.append((bx0 + tx * side + nx * depth, bz0 + tz * side + nz * depth))
                out.append(q)
                inside_notch = False
    if inside_notch or len(out) < len(ring) - 20:
        return None
    return [(round(x, 1), round(z, 1)) for x, z in out]


def carve(data, verbose=True):
    """Cuts every COURT out of its building's and landmark's outline; returns how many changed.
    Idempotent: a court that is open already is left alone."""
    changed = 0
    for name, court, half, depth, *wall in COURTS:
        for key in ("buildings", "landmarks"):
            for b in data.get(key, []):
                if b.get("name") != name:
                    continue
                ring = list(zip(b["p"][0::2], b["p"][1::2]))
                new = _notch(ring, court, half, depth, wall[0] if wall else None)
                if new is None:
                    continue
                b["p"] = [v for q in new for v in q]
                changed += 1
                if verbose:
                    print(f"planted trees: court carved out of {key[:-1]} {name}")
    return changed


def plant(data, place, solids=None):
    """The new trees for one place, [x, z, top, radius, base, 0] each (not yet in the data)."""
    if place.get("kind") == "grounds":
        return plant_grounds(data, place, solids)
    if place.get("kind") == "garden":
        return plant_garden(data, place, solids)
    zone = zone_of(place)
    trees = data.get("trees3d", [])
    near = [(trees[i], trees[i + 1], trees[i + 2]) for i in range(0, len(trees) - 5, 6)
            if _inside(trees[i], trees[i + 1], zone)]
    have = len(near) if place.get("count_all") else sum(1 for _, _, h in near if h <= YOUNG_MAX)
    want = place["target"] - have
    bed_min = place.get("bed_min", BED_MIN)
    line = Line(place["line"]) if place.get("line") else None
    if want <= 0:
        return []
    solids = solids or P.Solids(data)
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address"]
    beds = []
    for a in data.get("areas", []):
        if a["k"] not in place.get("beds", ("park",)):
            continue
        poly = list(zip(a["p"][0::2], a["p"][1::2]))
        cx = sum(p[0] for p in poly) / len(poly)
        cz = sum(p[1] for p in poly) / len(poly)
        if not _inside(cx, cz, zone):
            continue
        size = _area(poly)
        if size >= bed_min:
            beds.append((size, poly))
    # Biggest beds first: they read as the square's grove; the small ones along the street fill in.
    beds.sort(key=lambda b: (-b[0], b[1][0]))
    taken = [(x, z) for x, z, _ in near]
    out = []
    for size, poly in beds:
        for x, z in _spots(poly, 2 if size >= place.get("bed_two", BED_TWO) else 1):
            if len(out) >= want:
                return out
            if not _inside(x, z, poly):
                continue
            if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken):
                continue
            if any(math.hypot(x - px, z - pz) < 1.5 for px, pz in pois):
                continue
            if solids.blocked(x, z, CLEAR, skip=("tree",) + tuple(place.get("skip", ()))):
                continue
            mix = place["mix"]
            if line:
                along = line.along(x, z)
                mix = next((m for s0, s1, m in place["mixes"] if s0 <= along < s1), mix)
            out.append(_tree(x, z, mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]))
            taken.append((x, z))
    return out


def unplant(data, place):
    """Takes a garden place's own young trees out of trees3d (and their crown scales): the trees
    inside its zone whose sizes are one of its mix's nursery sizes (_nursery). Returns how many."""
    trees = data.get("trees3d", [])
    crowns = data.get("trees3d_crown", [])
    zone = place["zone"]
    keep, keep_crowns, gone = [], [], 0
    for k in range(0, len(trees) - 5, 6):
        t = trees[k:k + 6]
        mine = _inside(t[0], t[1], zone) and any(_nursery(t, kind) for kind in place["mix"])
        if mine:
            gone += 1
            continue
        keep.extend(t)
        if k // 6 < len(crowns):
            keep_crowns.append(crowns[k // 6])
    trees[:] = keep
    crowns[:] = keep_crowns
    return gone


def _nursery(t, kind):
    """Whether tree t ([x, z, top, radius, base, 0]) has the sizes _tree gives `kind`: one scale
    k (0.92-1.08) for all three, to their rounding."""
    top, radius, base = SPECIES[kind]
    k = t[2] / top
    return (0.915 <= k <= 1.085 and abs(radius * k - t[3]) <= 0.1 and abs(base * k - t[4]) <= 0.1
            and t[5] == 0)


def _tree(x, z, kind):
    top, radius, base = SPECIES[kind]
    k = 0.92 + _hash01(x, z, 2) * 0.16   # nursery stock varies a little
    return [round(x, 1), round(z, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), 0]


def regrade(data, place):
    """Re-tags the place's OSM pedestrian surfaces (its new paving); returns how many changed."""
    kind = place.get("paving")
    if not kind:
        return 0
    zone = zone_of(place)
    n = 0
    for srf in data.get("surfaces", []):
        if srf["k"] != "paving":
            continue
        xs, zs = srf["p"][0::2], srf["p"][1::2]
        if _inside(sum(xs) / len(xs), sum(zs) / len(zs), zone):
            srf["k"] = kind
            n += 1
    return n


def furnish(data, verbose=True):
    """Adds Chmielna's benches to data["benches"] (x, z, yaw triples); returns how many were added.
    Idempotent: once the band holds FURNITURE_TARGET benches nothing is added."""
    place = next(p for p in PLACES if p["id"] == "chmielna")
    line = Line(place["line"])
    zone = zone_of(place)
    bn = data.setdefault("benches", [])
    have = [(bn[i], bn[i + 1]) for i in range(0, len(bn) - 2, 3) if _inside(bn[i], bn[i + 1], zone)]
    solids = P.Solids(data)
    trees = data.get("trees3d", [])
    tree_pts = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address"]
    beds = []
    for a in data.get("areas", []):
        if a["k"] in ("park", "grass", "water"):
            poly = list(zip(a["p"][0::2], a["p"][1::2]))
            xs, zs = [q[0] for q in poly], [q[1] for q in poly]
            beds.append((min(xs) - 0.8, min(zs) - 0.8, max(xs) + 0.8, max(zs) + 0.8, poly))
    ns = [P.pairs(r["p"]) for r in data.get("roads", []) if r.get("name") == "Nowy Świat"]
    added = 0
    n = 0
    s = FURNITURE_STEP * 0.5
    while len(have) < FURNITURE_TARGET and s < line.length:
        side = 1 if n % 2 == 0 else -1
        n += 1
        px, pz, ux, uz = line.at(s)
        s += FURNITURE_STEP
        for sd in (side, -side):
            hit = None
            for t in FURNITURE_T:
                x, z = px + uz * t * sd, pz - ux * t * sd
                if solids.blocked(x, z, 0.9):
                    continue
                if any(b[0] <= x <= b[2] and b[1] <= z <= b[3] and _inside(x, z, b[4]) for b in beds):
                    continue
                if any(math.hypot(x - tx, z - tz) < FURNITURE_TREE_GAP for tx, tz in tree_pts):
                    continue
                if any(math.hypot(x - hx, z - hz) < FURNITURE_BENCH_GAP for hx, hz in have):
                    continue
                if any(math.hypot(x - qx, z - qz) < 1.8 for qx, qz in pois):
                    continue
                if any(P.seg_dist(x, z, a, b) < FURNITURE_NS for pts in ns for a, b in zip(pts, pts[1:])):
                    continue
                hit = (x, z, sd)
                break
            if hit:
                x, z, sg = hit
                # The seat looks at the street's middle (snap_props: yaw = atan2(-nx, -nz), n the way it faces).
                nx, nz = -uz * sg, ux * sg
                bn.extend([round(x, 1), round(z, 1), round(math.atan2(-nx, -nz), 2)])
                have.append((x, z))
                added += 1
                break
    if verbose:
        print(f"planted trees: chmielna furniture: {added} benches added, {len(have)} in the band")
    return added


def apply(data, verbose=True):
    """Plants every PLACE into the finished map data; returns how many trees were added."""
    import bake_osm
    trees = data.setdefault("trees3d", [])
    crowns = data.setdefault("trees3d_crown", [])
    have = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    added = 0
    carve(data, verbose)
    done = data.setdefault("planted_places", [])
    for place in PLACES:
        if place.get("groups") and place["id"] in done and place["id"] + "@groups" not in done:
            # Planted before the clumps (a map from before 2026-11-03): its young trees come out
            # (told from the scanned ones by their exact nursery sizes, _tree) and it plants again.
            gone = unplant(data, place)
            done.remove(place["id"])
            have = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
            if verbose:
                print(f"planted trees: {place['id']}: {gone} young trees taken out to plant in clumps")
        if place.get("kind") in ("grounds", "garden") and place["id"] in done:
            if verbose:
                print(f"planted trees: {place['id']}: already planted")
            continue
        paved = regrade(data, place)
        if paved and verbose:
            print(f"planted trees: {place['id']}: {paved} pedestrian surfaces re-tagged {place['paving']}")
        new = [t for t in plant(data, place)
               if not any(math.hypot(t[0] - x, t[1] - z) < SAME for x, z in have)]
        if not new:
            if verbose:
                print(f"planted trees: {place['id']}: none needed")
            continue
        flat = [v for t in new for v in t]
        scales = bake_osm.crown_scales(flat, data.get("roads", []))
        trees.extend(flat)
        crowns.extend(scales)
        have.extend((t[0], t[1]) for t in new)
        added += len(new)
        if place.get("kind") in ("grounds", "garden"):
            done.append(place["id"])
            if place.get("groups"):
                done.append(place["id"] + "@groups")
        if verbose:
            print(f"planted trees: {place['id']}: {len(new)} young trees added")
    furnish(data, verbose)
    return added


def main(argv):
    path = MAP
    dry = False
    for arg in argv:
        if arg == "--dry":
            dry = True
        elif arg.startswith("--"):
            print(__doc__)
            return 2
        else:
            path = arg
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    def state():
        return json.dumps([data.get("surfaces", []), data.get("benches", []),
                           [b["p"] for b in data.get("buildings", []) + data.get("landmarks", []) if b.get("name") in [c[0] for c in COURTS]]])
    before = state()
    n = apply(data)
    if (n or state() != before) and not dry:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
