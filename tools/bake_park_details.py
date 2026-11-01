"""Park details (BACKLOG "Parks", 2026-11-01): statues, a fountain, a carousel, a playground, a
gazebo, a sundial, a pergola, a footbridge, ducks and swans, squirrels, people on the benches,
picnics and a yoga class in Ogród Saski, Ogród Krasińskich and Park Ujazdowski (with the castle's
park).

    python3 -I tools/bake_park_details.py [MAP.json] [--out=FILE]

Reads the finished map data (default game/map/centrum.json; nothing else, so it runs in the
cloud) and writes game/data/park_details.json:

    {"_about", "src": <sha1 of the map keys read>, "kinds": [...],
     "items": [[kind, x, z, yaw, colour], ...]}

Same shape as street_details.json; game/scripts/park_details.gd builds it. `yaw` turns the piece
about Y (Basis(UP, yaw)); its front faces -Z, so a bench person copies the bench's yaw. The
anchors (ANCHORS) are spots chosen on the map's own plaza circles, lawns and ponds; each is moved
the shortest way to a free place (bake_street_pois.Solids: roads, buildings, water, trees, lamps,
benches). Łazienki Królewskie itself (the Palace on the Isle, the Chopin monument, the peacocks)
lies south of the map's edge and waits for the map extension (docs/QUESTIONS.md). Deterministic:
hashes of positions. Re-run after every centrum.json re-bake; game/tools/check_park_details.gd and
tools/check_park_details.py fail when `src` no longer matches. Standard library only.
"""
import hashlib
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as P  # noqa: E402

SEED = "park-details-2026"
OUT = os.path.join(ROOT, "game", "data", "park_details.json")
SRC_KEYS = ("roads", "carriage", "kerbs", "paths", "trams", "rails", "buildings", "lines", "walls", "steps",
            "guards", "medians", "areas", "platforms", "islands", "surfaces", "lamps", "signals", "benches",
            "bins", "bikes", "columns", "shelters", "parked", "trees3d", "pois", "landmarks")
KINDS = ["duck", "swan", "footbridge", "fountain", "rowboat", "carousel", "playground", "gazebo", "sundial",
         "pergola", "seated", "picnic", "peacock", "squirrel", "statue", "yoga"]
RADIUS = {"duck": 0.3, "swan": 0.5, "footbridge": 3.6, "fountain": 3.3, "rowboat": 1.6, "carousel": 2.8,
          "playground": 3.7, "gazebo": 2.6, "sundial": 0.8, "pergola": 3.3, "seated": 0.0, "picnic": 1.4,
          "peacock": 0.8, "squirrel": 0.15, "statue": 1.0, "yoga": 3.0}
MAX_ITEMS = 700
SECTOR = 512.0

# Each park: the point inside its big green area, the numbers of the scattered pieces.
PARKS = {
    "saski": dict(poi=(-1125.2, -691.8), seated=0.30, statues=16, picnic=4, yoga=1, squirrels=7, ducks=8, swans=2),
    "krasinski": dict(poi=(-1481.2, -1579.6), seated=0.30, statues=0, picnic=4, yoga=1, squirrels=7, ducks=9, swans=2),
    "ujazdowski": dict(poi=(109.2, 1224.0), seated=0.28, statues=0, picnic=6, yoga=1, squirrels=8, ducks=10, swans=3),
    "zamek": dict(poi=(380.0, 1560.0), seated=0.5, statues=0, picnic=3, yoga=0, squirrels=5, ducks=0, swans=0),
}
# [kind, x, z, yaw, colour, park]: where the one-off pieces stand (before the snap to a free spot).
ANCHORS = [
    ("sundial", -1010.0, -735.0, 0.3, "#c9b99a", "saski"),
    ("fountain", -1406.0, -1666.0, 0.0, "#c8c2b4", "krasinski"),
    ("carousel", -1610.0, -1455.0, 0.0, "#c8282a", "krasinski"),
    ("playground", -1640.0, -1520.0, 0.5, "#e0a82e", "krasinski"),
    ("gazebo", 81.0, 1309.0, 0.0, "#6b8f71", "ujazdowski"),
    ("pergola", 70.0, 1330.0, 1.5708, "#8a6a45", "ujazdowski"),
    ("footbridge", 167.0, 1479.0, 0.0, "#5a4632", "ujazdowski"),
    ("pergola", -1355.0, -1560.0, 0.0, "#8a6a45", "krasinski"),
]
STONE = ["#cdbf9f", "#c4b690", "#d4c8a8"]
SHIRTS = ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#c96b2c", "#5aa9c9", "#9c2f3a"]
BLANKETS = ["#c8282a", "#2f6fb5", "#e0b23a", "#3b8f5a", "#7a4fa8"]
FUR = ["#b5532c", "#a64a26", "#8f4a2c"]
DUCKS = ["#7a6a4a", "#8a7a52", "#6a6a60"]


def h01(*key):
    s = SEED + "|" + "|".join(("%.1f" % k) if isinstance(k, float) else str(k) for k in key)
    return int.from_bytes(hashlib.sha1(s.encode("utf-8")).digest()[:7], "big") / float(1 << 56)


def pick(seq, *key):
    return seq[int(h01(*key) * len(seq)) % len(seq)]


def src_hash(data):
    h = hashlib.sha1()
    for k in SRC_KEYS:
        h.update(json.dumps(data.get(k), separators=(",", ":"), sort_keys=True).encode("utf-8"))
    return h.hexdigest()


def poly_area(pts):
    return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(pts, pts[1:] + pts[:1]))) / 2.0


def edge_dist(x, z, pts):
    return min(P.seg_dist(x, z, a, b) for a, b in zip(pts, pts[1:] + pts[:1]))


class Baker:
    def __init__(self, data):
        self.data = data
        self.solids = P.Solids(data)
        self.items = []
        self.parks = {}
        areas = [(P.pairs(a["p"]), a["k"]) for a in data["areas"]]
        for name, cfg in PARKS.items():
            x, z = cfg["poi"]
            best = None
            for pts, k in areas:
                if k == "park" and P.point_in_poly(x, z, pts) and (best is None or poly_area(pts) > poly_area(best)):
                    best = pts
            if best is None:
                sys.exit("no park area at %s" % name)
            water = [pts for pts, k in areas if k == "water" and P.point_in_poly(sum(q[0] for q in pts) / len(pts),
                                                                                  sum(q[1] for q in pts) / len(pts), best)]
            paths = [(P.pairs(p["p"]), p["w"]) for p in data["paths"]
                     if p["k"] == "foot" and P.point_in_poly(p["p"][0], p["p"][1], best)]
            self.parks[name] = dict(poly=best, water=water, paths=paths)

    def path_dist(self, park, x, z):
        return min((P.seg_dist(x, z, a, b) - w * 0.5 for pts, w in self.parks[park]["paths"]
                    for a, b in zip(pts, pts[1:])), default=99.0)

    def free(self, kind, x, z, skip=()):
        for o in self.items:
            if abs(o[1] - x) < 8 and abs(o[2] - z) < 8 and math.hypot(o[1] - x, o[2] - z) < RADIUS[kind] + RADIUS[o[0]] + 0.3:
                return False
        return self.solids.blocked(x, z, RADIUS[kind] + 0.15, skip=skip) is None and len(self.items) < MAX_ITEMS

    def put(self, kind, x, z, yaw, colour):
        self.items.append([kind, round(x, 2), round(z, 2), round(yaw, 3), colour])

    def snap(self, kind, x, z, park):
        """The nearest free spot to (x, z) inside the park, searched in growing rings."""
        poly = self.parks[park]["poly"]
        for r in [0.0] + [1.5 * k for k in range(1, 30)]:
            for k in range(1 if r == 0 else 16):
                a = k * math.tau / 16 + r
                px, pz = x + math.cos(a) * r, z + math.sin(a) * r
                if P.point_in_poly(px, pz, poly) and self.free(kind, px, pz):
                    return px, pz
        return None

    def anchors(self):
        for kind, x, z, yaw, col, park in ANCHORS:
            s = self.snap(kind, x, z, park)
            if s is None:
                print("park_details: no spot for %s near (%d, %d)" % (kind, x, z))
                continue
            self.put(kind, s[0], s[1], yaw, col)

    def seated(self, park):
        cfg, poly = PARKS[park], self.parks[park]["poly"]
        b = self.data["benches"]
        n = 0
        for i in range(0, len(b) - 2, 3):
            x, z, yaw = b[i], b[i + 1], b[i + 2]
            if not P.point_in_poly(x, z, poly) or h01("seat", x, z) >= cfg["seated"]:
                continue
            self.put("seated", x, z, yaw, pick(SHIRTS, "shirt", x, z))
            n += 1
            if n >= 30:
                break

    def water_life(self, park):
        cfg = PARKS[park]
        for wi, pts in enumerate(self.parks[park]["water"]):
            xs, zs = [p[0] for p in pts], [p[1] for p in pts]
            if (max(xs) - min(xs)) * (max(zs) - min(zs)) < 600:
                continue
            for kind, want in (("swan", cfg["swans"]), ("duck", cfg["ducks"])):
                placed = k = 0
                while placed < want and k < 400:
                    k += 1
                    x = min(xs) + h01(park, wi, kind, k, "x") * (max(xs) - min(xs))
                    z = min(zs) + h01(park, wi, kind, k, "z") * (max(zs) - min(zs))
                    if not P.point_in_poly(x, z, pts) or edge_dist(x, z, pts) < 2.5:
                        continue
                    if any(o[0] in ("duck", "swan") and math.hypot(o[1] - x, o[2] - z) < 3.0 for o in self.items):
                        continue
                    self.put(kind, x, z, h01(park, kind, k, "yaw") * math.tau,
                             pick(DUCKS, "duck", x, z) if kind == "duck" else "#f4f1ea")
                    placed += 1

    def statues(self, park):
        """Sandstone statues in pairs along the longest wide alleys, 30 m apart."""
        want = PARKS[park]["statues"]
        if not want:
            return
        n = 0
        paths = sorted(self.parks[park]["paths"], key=lambda p: -sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(p[0], p[0][1:])))
        for pts, w in paths[:14]:
            walked, next_at = 0.0, 12.0
            for a, b in zip(pts, pts[1:]):
                ln = math.hypot(b[0] - a[0], b[1] - a[1])
                while ln and walked + ln >= next_at and n < want:
                    t = (next_at - walked) / ln
                    px, pz = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
                    nx, nz = -(b[1] - a[1]) / ln, (b[0] - a[0]) / ln
                    side = 1 if int(next_at / 30) % 2 else -1
                    sx, sz = px + nx * side * (w * 0.5 + 1.8), pz + nz * side * (w * 0.5 + 1.8)
                    if self.free("statue", sx, sz, skip=("tree",)) and self.free("statue", sx, sz):
                        self.put("statue", sx, sz, math.atan2(-nx * side, -nz * side), pick(STONE, "stone", sx, sz))
                        n += 1
                    next_at += 30.0
                walked += ln
            if n >= want:
                break

    def lawn(self, park):
        cfg, poly = PARKS[park], self.parks[park]["poly"]
        xs, zs = [p[0] for p in poly], [p[1] for p in poly]
        for kind, want in (("picnic", cfg["picnic"]), ("yoga", cfg["yoga"])):
            placed = k = 0
            while placed < want and k < 3000:
                k += 1
                x = min(xs) + h01(park, kind, k, "x") * (max(xs) - min(xs))
                z = min(zs) + h01(park, kind, k, "z") * (max(zs) - min(zs))
                if not P.point_in_poly(x, z, poly) or self.path_dist(park, x, z) < 4.5 or not self.free(kind, x, z):
                    continue
                if any(o[0] in ("picnic", "yoga") and math.hypot(o[1] - x, o[2] - z) < 25 for o in self.items):
                    continue
                self.put(kind, x, z, h01(park, kind, k, "yaw") * math.tau,
                         pick(BLANKETS, "blanket", x, z) if kind == "picnic" else pick(SHIRTS, "yogatop", x, z))
                placed += 1

    def squirrels(self, park):
        """Beside a trunk near an alley (a squirrel wants a tree and a person with a crumb)."""
        cfg, poly = PARKS[park], self.parks[park]["poly"]
        t = self.data["trees3d"]
        placed = 0
        for i in range(0, len(t) - 5, 6):
            if placed >= cfg["squirrels"]:
                break
            x, z = t[i], t[i + 1]
            if h01("sq", x, z) > 0.25 or not P.point_in_poly(x, z, poly) or self.path_dist(park, x, z) > 8:
                continue
            a = h01("sqa", x, z) * math.tau
            sx, sz = x + math.cos(a) * 0.7, z + math.sin(a) * 0.7
            if self.free("squirrel", sx, sz, skip=("tree",)):
                self.put("squirrel", sx, sz, a + math.pi, pick(FUR, "fur", x, z))
                placed += 1


def main(argv):
    src = os.path.join(ROOT, "game", "map", "centrum.json")
    out = OUT
    for a in argv:
        if a.startswith("--out="):
            out = a[6:]
        elif not a.startswith("--"):
            src = a
    data = json.load(open(src))
    b = Baker(data)
    b.anchors()
    for park in PARKS:
        b.statues(park)
        b.water_life(park)
        b.lawn(park)
        b.squirrels(park)
        b.seated(park)
    counts = {}
    for it in b.items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    doc = {"_about": "Park details: tools/bake_park_details.py from game/map/centrum.json",
           "src": src_hash(data), "kinds": KINDS, "items": b.items}
    with open(out, "w") as f:
        json.dump(doc, f, separators=(",", ":"))
        f.write("\n")
    print("bake_park_details: %d items %s" % (len(b.items), json.dumps(counts, sort_keys=True)))


if __name__ == "__main__":
    main(sys.argv[1:])
