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
}

# ul. Chmielna, Nowy Świat to Pasaż Wiecha (RS Architektura Krajobrazu for ZTP, opened 2024): the
# pedestrian street's centre (the OSM footway west of Plac Pięciu Rogów, the living street across
# it, the footway east of it), west to east; s is metres along it from Pasaż Wiecha.
CHMIELNA = [(-851.0, 253.2), (-809.3, 238.8), (-751.2, 218.7), (-703.5, 203.6), (-643.3, 184.9),
            (-626.7, 179.7), (-580.1, 168.7), (-566.2, 163.8), (-532.4, 151.9), (-475.0, 131.7),
            (-433.3, 117.0), (-389.8, 101.8), (-324.9, 79.0), (-312.3, 74.6)]


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
]


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


def plant(data, place, solids=None):
    """The new trees for one place, [x, z, top, radius, base, 0] each (not yet in the data)."""
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


def apply(data, verbose=True):
    """Plants every PLACE into the finished map data; returns how many trees were added."""
    import bake_osm
    trees = data.setdefault("trees3d", [])
    crowns = data.setdefault("trees3d_crown", [])
    have = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    added = 0
    for place in PLACES:
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
        if verbose:
            print(f"planted trees: {place['id']}: {len(new)} young trees added")
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
    before = json.dumps(data.get("surfaces", []))
    n = apply(data)
    if (n or json.dumps(data.get("surfaces", [])) != before) and not dry:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
