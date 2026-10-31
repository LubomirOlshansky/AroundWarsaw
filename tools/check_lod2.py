"""Map north (2026-10-31): the LoD2 models and the OpenStreetMap blocks never both, never neither.

Usage: python3 -I tools/check_lod2.py [--map=game/map] [--before=DIR] [--quiet]

tools/bake_gugik.py keeps a LoD2 model where OpenStreetMap maps a building and draws an OSM
outline as a plain block only where no kept model covers it (lod2.json `keep_osm`, its
`footprints`). Over the whole map this counts:

  L1 doubled   an OSM block still drawn whose area lies in kept LoD2 footprints by DOUBLE or more
               (two buildings drawn into each other)
  L2 lost      an OSM outline not drawn whose area lies in kept LoD2 footprints by less than
               LOST (a building the map maps, drawn by neither)

Areas are sampled every 1 m (finer for small outlines). Building parts (`mh`, min_height) and
outlines under 20 m² are left out. With --before=DIR (a map folder of an earlier bake: its
centrum.json and lod2.json) it also prints how many OSM blocks gained a LoD2 model and how many
lost one. Prints `check_lod2: OK` and exits 0 when L1 and L2 are at most the counts recorded in
L1_MAX and L2_MAX, 1 otherwise. Standard library only (~35 s).
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
from bake_osm import point_in_poly, ring_area  # noqa: E402

DOUBLE = 0.5
LOST = 0.25
# The counts on the map-north bake (2026-10-31), the ceilings: L1 16 -> 15 and L2 83 -> 73 with the
# looser match and the newer-building rule (bake_gugik.py); the old box had 16 and 81. What is left:
# L1 OSM blocks under a model whose centroid misses them (towers' podiums, courtyard wings); L2 big
# outlines a small model's centroid falls in (BACKLOG "From map north").
L1_MAX = 15
L2_MAX = 73
MIN_AREA = 20.0
CELL = 50.0


def polys_of(flat_list):
    return [list(zip(f[0::2], f[1::2])) for f in flat_list]


class Index:
    def __init__(self, polys):
        self.polys = polys
        self.boxes = []
        self.cells = {}
        for k, p in enumerate(polys):
            xs, zs = [q[0] for q in p], [q[1] for q in p]
            b = (min(xs), min(zs), max(xs), max(zs))
            self.boxes.append(b)
            for i in range(int(b[0] // CELL), int(b[2] // CELL) + 1):
                for j in range(int(b[1] // CELL), int(b[3] // CELL) + 1):
                    self.cells.setdefault((i, j), []).append(k)

    def hit(self, x, z):
        for k in self.cells.get((int(x // CELL), int(z // CELL)), ()):
            b = self.boxes[k]
            if b[0] <= x <= b[2] and b[1] <= z <= b[3] and point_in_poly(x, z, self.polys[k]):
                return True
        return False


def covered_share(poly, idx):
    area = abs(ring_area(poly))
    step = min(1.0, max(0.2, math.sqrt(area / 400.0)))
    xs, zs = [q[0] for q in poly], [q[1] for q in poly]
    total = inside = 0
    z = min(zs) + step * 0.5
    while z < max(zs):
        x = min(xs) + step * 0.5
        while x < max(xs):
            if point_in_poly(x, z, poly):
                total += 1
                inside += idx.hit(x, z)
            x += step
        z += step
    return inside / total if total else 0.0


def load(map_dir):
    d = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
    meta = json.load(open(os.path.join(map_dir, "lod2.json"), encoding="utf-8"))
    return d, meta


def judge(d, meta):
    blds = d["buildings"]
    keep = set(meta["keep_osm"])
    idx = Index(polys_of(meta["footprints"]))
    doubled, lost, shares = [], [], {}
    for k, b in enumerate(blds):
        if float(b.get("mh", 0) or 0) > 0:
            continue
        p = list(zip(b["p"][0::2], b["p"][1::2]))
        if len(p) < 3 or abs(ring_area(p)) < MIN_AREA:
            continue
        s = covered_share(p, idx)
        shares[k] = s
        cx, cz = sum(q[0] for q in p) / len(p), sum(q[1] for q in p) / len(p)
        if k in keep and s >= DOUBLE:
            doubled.append((cx, cz, s, b.get("name", "")))
        elif k not in keep and s < LOST:
            lost.append((cx, cz, s, b.get("name", "")))
    return doubled, lost, keep


def main(argv):
    map_dir, before, quiet = os.path.join(ROOT, "game", "map"), None, False
    for a in argv:
        if a.startswith("--map="):
            map_dir = a.split("=", 1)[1]
        elif a.startswith("--before="):
            before = a.split("=", 1)[1]
        elif a == "--quiet":
            quiet = True
        else:
            print(__doc__.strip().splitlines()[2])
            return 2
    if not os.path.exists(os.path.join(map_dir, "lod2.json")):
        print("check_lod2: no lod2.json (derived from GUGiK's raw data: tools/setup_map.sh --full); nothing to check")
        print("check_lod2 counts: -")
        return 0
    d, meta = load(map_dir)
    doubled, lost, keep = judge(d, meta)
    print(f"check_lod2: {meta['buildings']} LoD2 models, {len(keep)} of {len(d['buildings'])} OSM outlines drawn as blocks")
    for rule, name, found in (("L1", "doubled (an OSM block in LoD2 footprints)", doubled),
                              ("L2", "lost (an outline drawn by neither)", lost)):
        print(f"{rule} {name}: {len(found)}")
        if not quiet:
            for x, z, s, n in sorted(found, key=lambda f: -f[2])[:8]:
                print(f"  {n or 'building'} at ({x:.0f}, {z:.0f}), {s:.0%} in LoD2  [--at={x:.0f},{z:.0f}]")
    if before:
        bd, bmeta = load(before)
        bkeep = set(bmeta["keep_osm"])
        # The same outline in both bakes: matched by its whole outline.
        key = lambda b: tuple(b["p"])
        bidx = {key(b): k for k, b in enumerate(bd["buildings"])}
        gained, regressed = [], []
        for k, b in enumerate(d["buildings"]):
            o = bidx.get(key(b))
            if o is None:
                continue
            if o in bkeep and k not in keep:
                gained.append((b["p"][0], b["p"][1]))
            elif o not in bkeep and k in keep:
                regressed.append((b["p"][0], b["p"][1]))
        print(f"against {before}: {len(gained)} OSM blocks now drawn by LoD2, {len(regressed)} back to blocks; "
              f"LoD2 models {bmeta['buildings']} -> {meta['buildings']}, vertices {bmeta['vertices']} -> {meta['vertices']}")
        bdoubled, blost, _ = judge(bd, bmeta)
        for rule, now, was in (("L1", doubled, bdoubled), ("L2", lost, blost)):
            old = {(round(x), round(z)) for x, z, _, _ in was}
            new = [f for f in now if (round(f[0]), round(f[1])) not in old]
            print(f"{rule} against {before}: {len(was)} -> {len(now)}" + "".join(
                f"\n  new: {n or 'building'} at ({x:.0f}, {z:.0f}), {s:.0%} in LoD2  [--at={x:.0f},{z:.0f}]" for x, z, s, n in new))
        if not quiet:
            for x, z in gained:
                print(f"  gained at ({x:.0f}, {z:.0f})  [--at={x:.0f},{z:.0f}]")
    print("check_lod2 counts: L1 %d L2 %d" % (len(doubled), len(lost)))
    over = [f"{r} {n} > {m}" for r, n, m in (("L1", len(doubled), L1_MAX), ("L2", len(lost), L2_MAX)) if n > m]
    if over:
        print("check_lod2: FAIL (" + ", ".join(over) + ": a bake drew more buildings twice or lost more; "
              "if on purpose, record the new counts in L1_MAX / L2_MAX with the reason)")
        return 1
    print(f"check_lod2: OK (L1 {len(doubled)} of at most {L1_MAX}, L2 {len(lost)} of at most {L2_MAX})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
