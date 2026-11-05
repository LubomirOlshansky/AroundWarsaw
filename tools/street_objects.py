"""The street-objects ledger: every object the street-level cameras saw and every object the game
draws, counted street by street, with the game's object budget beside it.
    python3 -I tools/street_objects.py [--md=docs/inventory/street_objects.md] [--json=build/street_objects.json] [--min=150]

F (2026-11-04): "map them and write it down, but decide wisely what goes into the game; don't
overload the city." So this is the log, not a placement list: it records what is really there
(Mapillary detections, from tools/street_features.py's cache) next to what the game has, per named
street, as objects per 100 m, and marks what the object budget (docs/design/roads-and-objects-plan.md
section 3a) lets into the game. Nothing here is placed in the game by itself.

Every detection and every game point within REACH metres of a named road is given to the nearest
one. Lengths are the mapped ways' length (a dual carriageway counts both ways). "Recent" means seen
since RECENT (older detections can be gone: a 2015 cone is not roadworks today). Points inside the
game's pedestrian zones are counted apart, because cones or barriers there are almost always
temporary. Streets shorter than --min metres are left out of the Markdown (all are in the JSON).

Needs game/map/centrum.json and the cache build/street_features/ (run tools/street_features.py once;
offline after that). Standard library only.
"""
import collections
import glob
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import street_features as sf  # noqa: E402

REACH = 20.0
RECENT = "2025-05-01"
# The columns of the ledger, in order: (class, short head). Classes are street_features.CLASSES.
COLS = [("lamp", "lamps"), ("signal", "signals"), ("ped_signal", "ped. lights"), ("zebra", "zebras"),
        ("arrow", "arrows"), ("sign", "signs"), ("pole", "poles"), ("box", "boxes"),
        ("manhole", "manholes"), ("roadworks", "cones/barriers"), ("bin", "bins"), ("bench", "benches"),
        ("bike_rack", "racks")]
# The object budget (plan section 3a): what each class may become in the game.
BUDGET = {
    "lamp": "in game; density decided by a look test (night shots, bench), not the real count",
    "signal": "in game (traffic uses them); no new ones; fewer visible poles is an A/B for F",
    "ped_signal": "log only",
    "zebra": "in game; checked against the orthophoto",
    "arrow": "in game from turn:lanes; detections are evidence",
    "sign": "log only; a few gameplay signs at most (F decides)",
    "pole": "log only",
    "box": "log only",
    "manhole": "log only; maybe shader marks (no geometry)",
    "roadworks": "log only; only recent, on a carriageway, never in a pedestrian zone, and as a roadworks event, not a fixed prop",
    "bin": "in game as is",
    "bench": "in game as is",
    "bike_rack": "in game as is",
}


def load_detections():
    feats = {}
    for path in glob.glob(os.path.join(sf.CACHE, "*.json")):
        with open(path) as f:
            for item in json.load(f):
                feats[item["id"]] = item
    if not feats:
        sys.exit("street_objects: no cache in build/street_features/, run tools/street_features.py first")
    return feats


def in_poly(x, z, pts):
    c = False
    n = len(pts)
    for i in range(n):
        x1, z1 = pts[i]
        x2, z2 = pts[i - 1]
        if (z1 > z) != (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1 + 1e-12) + x1:
            c = not c
    return c


class Streets:
    def __init__(self, d):
        self.length = collections.Counter()
        self.kinds = collections.defaultdict(collections.Counter)
        self.segs = []
        self.grid = collections.defaultdict(list)
        for r in d["roads"]:
            name = r.get("name")
            if not name:
                continue
            p = list(zip(r["p"][0::2], r["p"][1::2]))
            for a, b in zip(p, p[1:]):
                L = math.dist(a, b)
                self.length[name] += L
                self.kinds[name][r["k"]] += L
                i = len(self.segs)
                self.segs.append((a, b, name))
                for cx in range(int(min(a[0], b[0]) // 25) - 1, int(max(a[0], b[0]) // 25) + 2):
                    for cz in range(int(min(a[1], b[1]) // 25) - 1, int(max(a[1], b[1]) // 25) + 2):
                        self.grid[(cx, cz)].append(i)

    def nearest(self, x, z):
        best, name = REACH, None
        for i in self.grid.get((int(x // 25), int(z // 25)), ()):
            (ax, az), (bx, bz), n = self.segs[i]
            dx, dz = bx - ax, bz - az
            L = dx * dx + dz * dz or 1e-9
            t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / L))
            dd = math.hypot(ax + t * dx - x, az + t * dz - z)
            if dd < best:
                best, name = dd, n
        return name


def main():
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if "help" in args:
        print(__doc__)
        return
    with open(os.path.join(ROOT, "game", "map", "centrum.json")) as f:
        d = json.load(f)
    streets = Streets(d)
    zones = [list(zip(z["p"][0::2], z["p"][1::2])) for z in d.get("ped_zones", [])]
    zone_box = [(min(p[0] for p in z), min(p[1] for p in z), max(p[0] for p in z), max(p[1] for p in z)) for z in zones]

    def in_zone(x, z):
        return any(b[0] <= x <= b[2] and b[1] <= z <= b[3] and in_poly(x, z, zones[i]) for i, b in enumerate(zone_box))

    x0, z0, x1, z1 = d["bounds"]
    by_class = collections.defaultdict(list)
    for item in load_detections().values():
        lon, lat = item["geometry"]["coordinates"]
        x, z = sf.project(lat, lon)
        if not (x0 <= x <= x1 and z0 <= z <= z1):
            continue
        c = sf.classify(item["object_value"])
        if c:
            by_class[c].append((x, z, str(item.get("last_seen_at", ""))[:10]))
    mly = collections.defaultdict(collections.Counter)
    recent = collections.defaultdict(collections.Counter)
    zoned = collections.Counter()
    for c, pts in by_class.items():
        r = sf.MERGE.get(c, sf.MERGE_DEFAULT)
        for x, z, seen, _n in sf.merge(pts, r):
            name = streets.nearest(x, z)
            if not name:
                continue
            mly[name][c] += 1
            if seen >= RECENT:
                recent[name][c] += 1
            if c == "roadworks" and in_zone(x, z):
                zoned[name] += 1
    game = collections.defaultdict(collections.Counter)
    for c, (_label, layer, stride) in sf.CLASSES.items():
        if not layer:
            continue
        for p in sf.merge(sf.game_points(d, layer, stride), sf.MERGE.get(c, sf.MERGE_DEFAULT)):
            name = streets.nearest(p[0], p[1])
            if name:
                game[name][c] += 1
    rows = []
    for name, L in streets.length.items():
        kind = streets.kinds[name].most_common(1)[0][0]
        row = {"street": name, "kind": kind, "m": round(L), "objects": {}}
        for c, _h in COLS:
            row["objects"][c] = {"real": mly[name][c], "recent": recent[name][c], "game": game[name][c] if sf.CLASSES[c][1] else None}
        row["roadworks_in_ped_zone"] = zoned[name]
        rows.append(row)
    rows.sort(key=lambda r: -r["m"])
    if "json" in args:
        with open(args["json"], "w") as f:
            json.dump({"recent_since": RECENT, "reach": REACH, "budget": BUDGET, "streets": rows,
                       "attribution": "Detections: Mapillary contributors, CC BY-SA 4.0"}, f, ensure_ascii=False)
        print(f"street_objects: wrote {len(rows)} streets to {args['json']}")
    if "md" in args:
        write_md(args["md"], rows, int(args.get("min", 150)))
        print(f"street_objects: wrote {args['md']}")
    tot = collections.Counter()
    for row in rows:
        for c, _h in COLS:
            tot[c, "real"] += row["objects"][c]["real"]
            tot[c, "game"] += row["objects"][c]["game"] or 0
    print(f"street_objects: {len(rows)} named streets, {round(sum(r['m'] for r in rows) / 1000)} km")
    for c, h in COLS:
        print(f"  {h:15} real {tot[c, 'real']:6}  game {tot[c, 'game'] if sf.CLASSES[c][1] else '-':>6}")


def per100(n, m):
    return f"{100.0 * n / m:.1f}" if m else "0"


def write_md(path, rows, min_m):
    out = ["# Street objects ledger (generated)", "",
           "Generated by `python3 -I tools/street_objects.py --md=docs/inventory/street_objects.md` from Mapillary",
           "detections (CC BY-SA 4.0, merged into objects) and the game's own layers. **A log, not a placement list**:",
           "what goes into the game follows the object budget below and docs/design/roads-and-objects-plan.md section 3a.",
           f"Cells are \"real / game\" objects per 100 m of mapped way (a dual carriageway counts both ways); \"real\"",
           f"is what the cameras saw, so a street few people photographed reads low. Cones/barriers: seen since {RECENT}",
           "(all-time in brackets), and how many stand in a pedestrian zone. Streets under "
           f"{min_m} m are only in the JSON.", "",
           "## The object budget", "", "| Class | Into the game? |", "| --- | --- |"]
    for c, h in COLS:
        out.append(f"| {h} | {BUDGET[c]} |")
    out += ["", "## Street by street", "",
            "| Street | Kind | m | " + " | ".join(h for _c, h in COLS) + " | cones in ped. zone |",
            "| --- | --- | --- | " + " | ".join("---" for _ in COLS) + " | --- |"]
    for row in rows:
        if row["m"] < min_m:
            continue
        cells = []
        for c, _h in COLS:
            o = row["objects"][c]
            if c == "roadworks":
                cells.append(f"{o['recent']} ({o['real']})")
            elif o["game"] is None:
                cells.append(per100(o["real"], row["m"]))
            else:
                cells.append(f"{per100(o['real'], row['m'])} / {per100(o['game'], row['m'])}")
        out.append(f"| {row['street']} | {row['kind']} | {row['m']} | " + " | ".join(cells) + f" | {row['roadworks_in_ped_zone']} |")
    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
