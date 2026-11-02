"""The plazas of Rondo Daszyńskiego's towers (Krajobraz places K5, 2026-11-02).

    python3 -I tools/plaza_gardens.py [MAP.json] [--dry]     (rewrites the map in place, idempotent)

The three tower groups at Rondo Daszyńskiego (Skyliner, Generation Park, Mennica Legacy Tower;
2020-21, planted by RS Architektura Krajobrazu among others) stand on open OSM ground: the map
has the buildings, the road and a few scanned trees, but none of the planting between them. The
2023 laser scan predates most of it. This module adds, on the finished map data and after
planted_trees (bake_osm.py calls `apply(out)` there, before the content POIs):

  * three tiers of planting, as the studio describes Skyliner's green passage ("forest-like": tall
    trees with open crowns, solitary shrubs, low shrubs and perennials): the trees go into
    `trees3d` (+ `trees3d_crown`), the shrubs and perennials into `areas` as small "park" beds;
  * wooden benches into `benches` ([x, z, yaw] as OSM's, the seat faces yaw's -z), a pair
    to a grove, turned towards the tower the plaza belongs to.

Each PLAZA names its zones (game x, z polygons), the tower it faces (`focus`), the tree spacing,
the species mix, and the density of its beds. A spot must be clear of buildings, carriageways,
lamps, poles, benches and the scanned trees (the existing trunks count as the grove, a new tree
keeps TREE_GAP m from each). Everything is deterministic (hashes of the position, never Python's
hash) and `plaza_gardens` in the data lists the places already planted, so a second run adds
nothing. Standard library only. Sources: docs/design/krajobraz-places.md K5 and
docs/design/rondo-plazas.md (the spec).
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
TREE_GAP = 4.2      # a new trunk keeps this far from every other trunk (scanned or ours)
CLEAR = 1.1         # the trunk's disc that must be clear of the solids (carriageway edges, kerbs, buildings)
BED_CLEAR = 0.5     # a bed's rim keeps this clear of the solids

# 2021 plantings, 4-5 years on: [top, crown radius, crown base, kind] (kind 1 = conifer).
SPECIES = {
    "birch": [10.5, 2.3, 3.6, 0],      # brzoza brodawkowata: the open crown of a forest's tall tier
    "linden": [9.0, 2.7, 2.8, 0],      # lipa drobnolistna
    "hornbeam": [8.0, 2.2, 2.4, 0],    # grab
    "pine": [11.5, 2.0, 3.4, 1],       # sosna zwyczajna: a few, for the forest's winter
    "rowan": [5.8, 1.8, 1.8, 0],       # jarzębina: the small tree by the benches
}

PLAZAS = [
    {
        "id": "skyliner",
        "name": "Skyliner's green passage (west of Rondo Daszyńskiego, Prosta)",
        # The strip between the podium block and the oval tower, and the forecourt north of the tower.
        "zones": [
            [(-2742.0, 456.0), (-2704.0, 456.0), (-2698.0, 486.0), (-2742.0, 490.0)],
            [(-2736.0, 505.0), (-2712.0, 530.0), (-2704.0, 612.0), (-2736.0, 612.0)],
            # The two lawns east of the oval tower, between it and the Prosta carriageways.
            [(-2704.0, 484.0), (-2680.0, 498.0), (-2682.0, 530.0), (-2700.0, 524.0)],
            [(-2676.0, 512.0), (-2660.0, 524.0), (-2666.0, 548.0), (-2680.0, 540.0)],
        ],
        "focus": (-2707.0, 507.0),
        "spacing": 6.2,
        "mix": ["birch", "birch", "linden", "pine", "birch", "hornbeam", "pine", "linden"],
        "beds": 0.9,        # beds per tree: the shrub and perennial tiers under the crowns
        "benches": 3,
    },
    {
        "id": "generation_park",
        "name": "Generation Park's plazas between buildings X, Y and Z",
        "zones": [
            [(-2718.0, 296.0), (-2650.0, 308.0), (-2640.0, 340.0), (-2712.0, 332.0)],
            [(-2672.0, 232.0), (-2610.0, 244.0), (-2606.0, 292.0), (-2664.0, 284.0)],
        ],
        "focus": (-2652.0, 290.0),
        "spacing": 7.0,
        "mix": ["linden", "hornbeam", "birch", "linden", "rowan", "hornbeam"],
        "beds": 0.8,
        "benches": 4,
    },
    {
        "id": "mennica",
        "name": "Mennica Legacy Tower's forecourts (Prosta, Żelazna)",
        "zones": [
            [(-2165.0, 58.0), (-2090.0, 58.0), (-2096.0, 94.0), (-2166.0, 88.0)],
            [(-2168.0, 166.0), (-2098.0, 168.0), (-2100.0, 198.0), (-2160.0, 198.0)],
        ],
        "focus": (-2112.0, 126.0),
        "spacing": 7.5,
        "mix": ["linden", "linden", "hornbeam", "rowan", "linden", "birch"],
        "beds": 0.6,
        "benches": 4,
    },
]


def _hash01(x, z, salt):
    """A stable 0..1 from a position (never Python's hash)."""
    return (math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453) % 1.0


def _inside(x, z, poly):
    hit = False
    for i in range(len(poly)):
        (ax, az), (bx, bz) = poly[i], poly[i - 1]
        if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
            hit = not hit
    return hit


def _in_any(x, z, zones):
    return any(_inside(x, z, zone) for zone in zones)


def _bed(x, z, rx, rz, seed):
    """A bed's outline: an uneven 10-gon, flat [x, z, ...] as the map's areas."""
    out = []
    for i in range(10):
        a = i / 10 * math.tau
        k = 0.78 + _hash01(x + i, z - i, seed) * 0.44
        out += [round(x + math.cos(a) * rx * k, 1), round(z + math.sin(a) * rz * k, 1)]
    return out


def _trunks(data):
    t = data.get("trees3d", [])
    return [(t[i], t[i + 1]) for i in range(0, len(t) - 5, 6)]


def plan(data, place, solids, trunks):
    """One place's additions: (trees [x, z, top, radius, base, kind], beds [flat polygons],
    benches [x, z, yaw]), none of them in the data yet."""
    zones = place["zones"]
    xs = [p[0] for zone in zones for p in zone]
    zs = [p[1] for zone in zones for p in zone]
    step = place["spacing"]
    mix = place["mix"]
    taken = [t for t in trunks if min(xs) - 8 < t[0] < max(xs) + 8 and min(zs) - 8 < t[1] < max(zs) + 8]
    mine = []
    trees = []
    z = min(zs)
    row = 0
    while z <= max(zs):
        x = min(xs) + (step * 0.5 if row % 2 else 0.0)   # staggered rows, as a planted grove reads
        while x <= max(xs):
            jx = x + (_hash01(x, z, 3) - 0.5) * step * 0.55
            jz = z + (_hash01(x, z, 4) - 0.5) * step * 0.55
            x += step
            if not _in_any(jx, jz, zones):
                continue
            if solids.blocked(jx, jz, CLEAR, skip=("tree",)):
                continue
            if any(math.hypot(jx - tx, jz - tz) < TREE_GAP for tx, tz in taken + mine):
                continue
            kind = mix[int(_hash01(jx, jz, 1) * len(mix)) % len(mix)]
            top, radius, base, conifer = SPECIES[kind]
            k = 0.9 + _hash01(jx, jz, 2) * 0.22
            trees.append([round(jx, 1), round(jz, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), conifer])
            mine.append((jx, jz))
        z += step * 0.87
        row += 1
    # The shrub and perennial tiers: a bed beside some of the trunks (not under a pine).
    beds = []
    for i, t in enumerate(trees):
        if t[5] == 1 or _hash01(t[0], t[1], 5) > place["beds"]:
            continue
        a = _hash01(t[0], t[1], 6) * math.tau
        bx, bz = t[0] + math.cos(a) * 2.4, t[1] + math.sin(a) * 2.4
        rx, rz = 1.5 + _hash01(bx, bz, 7) * 1.3, 1.2 + _hash01(bx, bz, 8) * 1.1
        if not _in_any(bx, bz, zones):
            continue
        ring = _bed(bx, bz, rx, rz, 9)
        pts = list(zip(ring[0::2], ring[1::2]))
        if any(solids.blocked(px, pz, BED_CLEAR, skip=("tree",)) for px, pz in pts):
            continue
        if any(math.hypot(bx - ox, bz - oz) < 3.2 for ox, oz in [(sum(b[0::2]) / 10, sum(b[1::2]) / 10) for b in beds]):
            continue
        beds.append(ring)
    # Benches: beside every few trees, seat towards the tower.
    benches = []
    fx, fz = place["focus"]
    for i, t in enumerate(trees):
        if len(benches) >= place["benches"]:
            break
        if i % 3 != 1 or t[5] == 1:
            continue
        dx, dz = fx - t[0], fz - t[1]
        d = math.hypot(dx, dz) or 1.0
        for off in (2.3, -2.3):
            bx, bz = t[0] + dz / d * off, t[1] - dx / d * off     # beside the trunk, across the line to the tower
            if _in_any(bx, bz, zones) and not solids.blocked(bx, bz, 1.0, skip=("tree",)):
                benches.append([round(bx, 1), round(bz, 1), round(math.atan2(-dx, -dz), 2)])
                break
    return trees, beds, benches


def apply(data, verbose=True):
    """Adds every PLAZA to the finished map data; returns the number of trees added."""
    import bake_osm
    trees = data.setdefault("trees3d", [])
    crowns = data.setdefault("trees3d_crown", [])
    solids = P.Solids(data)
    trunks = _trunks(data)
    done = data.setdefault("plaza_gardens", [])   # the places already planted: a second run adds nothing
    added = 0
    for place in PLAZAS:
        if place["id"] in done:
            if verbose:
                print(f"plaza gardens: {place['id']}: already planted")
            continue
        new_trees, beds, benches = plan(data, place, solids, trunks)
        done.append(place["id"])
        flat = [v for t in new_trees for v in t]
        crowns.extend(bake_osm.crown_scales(flat, data.get("roads", [])))
        trees.extend(flat)
        areas = data.setdefault("areas", [])
        areas.extend({"p": b, "k": "park"} for b in beds)
        data.setdefault("benches", []).extend(v for b in benches for v in b)
        trunks.extend((t[0], t[1]) for t in new_trees)
        added += len(new_trees)
        if verbose:
            print(f"plaza gardens: {place['id']}: {len(new_trees)} trees, {len(beds)} beds, {len(benches)} benches")
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
