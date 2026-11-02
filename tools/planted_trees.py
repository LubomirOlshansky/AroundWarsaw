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
    # The stadium's grounds (2012, ten years on): lime and plane rows on the avenues, and the
    # pollarded willows of the Mazovian landscape (a short trunk, a broad knobbly head).
    "linden": [9.4, 2.7, 3.1],        # lipa
    "plane_row": [10.2, 3.0, 3.4],    # platan
    "willow": [6.4, 2.9, 2.0],        # wierzba głowiasta
}

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
        "row_mix": ["linden", "linden", "plane_row"],
        "willow_groups": 9,
        "willow_gap": 45.0,           # groups at least this far apart
        "willow_min_area": 1500.0,    # a lawn at least this big (m²) takes a group
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


def _tree(x, z, kind):
    top, radius, base = SPECIES[kind]
    k = 0.92 + _hash01(x, z, 2) * 0.16
    return [round(x, 1), round(z, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), 0]


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


def plant(data, place, solids=None):
    """The new trees for one place, [x, z, top, radius, base, 0] each (not yet in the data)."""
    if place.get("kind") == "grounds":
        return plant_grounds(data, place, solids)
    zone = place["zone"]
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
    done = data.setdefault("planted_places", [])
    for place in PLACES:
        if place.get("kind") == "grounds" and place["id"] in done:
            if verbose:
                print(f"planted trees: {place['id']}: already planted")
            continue
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
        if place.get("kind") == "grounds":
            done.append(place["id"])
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
