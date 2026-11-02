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
young ones already there (a tree no taller than YOUNG_MAX m), and its species mix. One tree
goes into every bed of at least BED_MIN m² that has no tree within TREE_GAP m, a second into a
bed of at least BED_TWO m² when it fits, until the target is reached; a spot must be clear of
buildings, carriageways, benches, racks, lamps and other poles (bake_street_pois.Solids).
Trees are appended to `trees3d` (x, z, top, crown radius, crown base, kind 0) with their crown
scale in `trees3d_crown` (bake_osm.crown_scales). A spot that already has a tree within
SAME m is skipped, so running it twice adds nothing. Deterministic; standard library only.

Sources for Bracka: krajobraz.com.pl/projekt/ul-bracka/ (Al. Jerozolimskie to Krucza, 2023-24,
for Zarząd Terenów Publicznych), whiteMAD 26.04.2024 (33 trees replacing a temporary car park:
planes, bird cherry, cherries, maples), Architektura & Biznes (a woonerf, "nearly 40" trees,
benches and racks, a triangular square under the trees).
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
    # Browary's Central Garden (planted 2021, 5 years on) and Norblin's court (big stock set in 2021).
    "linden": [9.0, 2.7, 2.8],        # lipa
    "hornbeam": [8.2, 2.3, 2.5],      # grab
    "garden_plane": [10.5, 3.2, 3.2], # platan
    "candelabra": [15.5, 4.6, 4.0],   # multi-stem plane trained as a candelabra (Norblin)
}

# A place with "spots" ([x, z, species] each) plants exactly those; one with "lattice" (spacing in
# m) plants a staggered grid inside its zone, up to "target" trees, both through the same clear-
# of-solids test as the beds. Neither counts the scanned trees: they are placed by hand.
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
        "id": "norblin",
        "name": "Fabryka Norblina, the court (the candelabra planes, 2021)",
        # The court inside the U of the halls (x -2290..-2245, z 62..100) round the chapel (-2257, 72):
        # five multi-stem planes on the court's axis, the site's landmark.
        "zone": [(-2290.0, 66.0), (-2250.0, 56.0), (-2238.0, 90.0), (-2268.0, 100.0), (-2278.0, 92.0)],
        "spots": [(-2272.0, 70.0, "candelabra"), (-2270.0, 83.0, "candelabra"), (-2257.0, 88.0, "candelabra"),
                  (-2246.0, 82.0, "candelabra"), (-2279.0, 76.0, "candelabra")],
    },
    {
        "id": "browary",
        "name": "Browary Warszawskie, the Central Garden over the Leżakownia (2021)",
        # The mapped garden bed between Biura przy Warzelni and the diagonal wing (x -2480..-2440,
        # z -123..-79): trees on slabs in a staggered grid, lindens, hornbeams and planes.
        "zone": [(-2495.0, -121.0), (-2462.0, -125.0), (-2442.0, -92.0), (-2440.0, -82.0), (-2476.0, -76.0),
                 (-2500.0, -90.0)],
        "lattice": 8.0,
        "target": 18,  # counting the scanned trees already in the bed (4)
        "mix": ["linden", "hornbeam", "garden_plane", "linden", "hornbeam"],
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


def _hand_plant(data, place, solids=None):
    """The new trees of a place with fixed "spots" or a "lattice": each must be clear of the
    solids and of every tree already there (scanned or planted) by TREE_GAP."""
    solids = solids or P.Solids(data)
    trees = data.get("trees3d", [])
    taken = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    zone = place["zone"]
    if "spots" in place:
        cand = [(x, z, k) for x, z, k in place["spots"]]
    else:
        step = place["lattice"]
        xs = [p[0] for p in zone]
        zs = [p[1] for p in zone]
        mix = place["mix"]
        cand = []
        row = 0
        z = min(zs)
        while z <= max(zs):
            x = min(xs) + (step * 0.5 if row % 2 else 0.0)
            while x <= max(xs):
                if _inside(x, z, zone):
                    cand.append((x, z, mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]))
                x += step
            z += step * 0.87
            row += 1
    out = []
    # "target" counts every tree in the zone, so a second run (which sees the first's) adds nothing.
    have = sum(1 for tx, tz in taken if _inside(tx, tz, zone)) if "lattice" in place else 0
    for x, z, kind in cand:
        if have + len(out) >= place.get("target", len(cand)):
            break
        if any(math.hypot(x - tx, z - tz) < (SAME if "spots" in place else TREE_GAP) for tx, tz in taken):
            continue
        if solids.blocked(x, z, CLEAR + (1.0 if kind == "candelabra" else 0.0), skip=("tree",)):
            continue
        top, radius, base = SPECIES[kind]
        k = 0.92 + _hash01(x, z, 2) * 0.16
        out.append([round(x, 1), round(z, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), 0])
        taken.append((x, z))
    return out


def plant(data, place, solids=None):
    """The new trees for one place, [x, z, top, radius, base, 0] each (not yet in the data)."""
    zone = place["zone"]
    if "spots" in place or "lattice" in place:
        return _hand_plant(data, place, solids)
    trees = data.get("trees3d", [])
    near = [(trees[i], trees[i + 1], trees[i + 2]) for i in range(0, len(trees) - 5, 6)
            if _inside(trees[i], trees[i + 1], zone)]
    young = sum(1 for _, _, h in near if h <= YOUNG_MAX)
    want = place["target"] - young
    if want <= 0:
        return []
    solids = solids or P.Solids(data)
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address"]
    beds = []
    for a in data.get("areas", []):
        if a["k"] != "park":
            continue
        poly = list(zip(a["p"][0::2], a["p"][1::2]))
        cx = sum(p[0] for p in poly) / len(poly)
        cz = sum(p[1] for p in poly) / len(poly)
        if not _inside(cx, cz, zone):
            continue
        size = _area(poly)
        if size >= BED_MIN:
            beds.append((size, poly))
    # Biggest beds first: they read as the square's grove; the small ones along the street fill in.
    beds.sort(key=lambda b: (-b[0], b[1][0]))
    taken = [(x, z) for x, z, _ in near]
    out = []
    for size, poly in beds:
        for x, z in _spots(poly, 2 if size >= BED_TWO else 1):
            if len(out) >= want:
                return out
            if not _inside(x, z, poly):
                continue
            if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken):
                continue
            if any(math.hypot(x - px, z - pz) < 1.5 for px, pz in pois):
                continue
            if solids.blocked(x, z, CLEAR, skip=("tree",)):
                continue
            mix = place["mix"]
            kind = mix[int(_hash01(x, z, 1) * len(mix)) % len(mix)]
            top, radius, base = SPECIES[kind]
            k = 0.92 + _hash01(x, z, 2) * 0.16   # nursery stock varies a little
            out.append([round(x, 1), round(z, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), 0])
            taken.append((x, z))
    return out


def apply(data, verbose=True):
    """Plants every PLACE into the finished map data; returns how many trees were added."""
    import bake_osm
    trees = data.setdefault("trees3d", [])
    crowns = data.setdefault("trees3d_crown", [])
    have = [(trees[i], trees[i + 1]) for i in range(0, len(trees) - 5, 6)]
    added = 0
    for place in PLACES:
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
    n = apply(data)
    if n and not dry:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
