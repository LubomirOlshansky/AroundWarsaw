"""What Mapillary's detections see on the street, against what the game draws there.
    python3 -I tools/street_features.py [--street=NAME] [--box=X0,Z0,X1,Z1] [--r=12] [--json=OUT] [--offline]

Mapillary runs object detection on every street-level photo and triangulates the detections into
map features (points with a class such as object--street-light, marking--discrete--crosswalk-zebra,
regulatory--no-entry--g1). This tool fetches them for the map (or a box, or one street), sorts them
into the game's prop layers (lamps, signals, bins, benches, bike racks, zebra crossings, arrows,
stop lines) plus the classes the game has no layer for yet (poles, bollards, hydrants, manholes,
signs, roadworks), and matches each against the game's own points within `r` metres.

It prints, per class: what Mapillary sees, what the game has, how many match, and what is only on
one side. "Game only" is counted only in 30 m cells where Mapillary saw anything at all (a street no
one photographed says nothing). Detections are approximate (a few metres) and incomplete (only what
the cameras saw), so the numbers are evidence for the road-objects sweep (docs/design/roads-and-
objects-plan.md, docs/design/road-objects.md 3.2 S5), not a ground truth to copy.

Box and street are game metres (+x east, +z south). `--json` writes every point with its class and
match, for the dev console's map. Responses are cached in build/street_features/ (gitignored);
`--offline` uses only the cache. Needs MAPILLARY_TOKEN in the environment (never in a file) and
game/map/centrum.json. Licence: Mapillary data is CC BY-SA 4.0: evidence for decisions; anything
placed in the game from it is credited in the attribution list. Standard library only.
"""
import collections
import json
import math
import os
import sys
import urllib.parse
import urllib.request

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from bake_osm import LAT0, LON0, M_PER_DEG_LAT, M_PER_DEG_LON  # noqa: E402

CACHE = os.path.join(ROOT, "build", "street_features")
UA = "AroundWarsaw-street-features/1.0 (game road-object checks)"
TILE_LAT, TILE_LON = 0.003, 0.005  # ~330 x 340 m per request
CELL = 30.0
# Detections of one object are often several points a few metres apart, and the game's zebra is one
# polyline per stripe: both sides are merged into clusters this wide (m) before matching.
MERGE = {"zebra": 8.0, "stop_line": 6.0, "signal": 5.0, "ped_signal": 5.0, "sign": 2.0, "shop_sign": 2.0}
MERGE_DEFAULT = 4.0

# class -> (label, game layer, stride) ; layer None = the game has no such layer yet
CLASSES = {
    "lamp": ("Street lights", "lamps", 2),
    "signal": ("Traffic lights (vehicles)", "signals", 3),
    "ped_signal": ("Pedestrian lights", None, 0),
    "bin": ("Bins", "bins", 3),
    "bench": ("Benches", "benches", 3),
    "bike_rack": ("Bike racks", "bikes", 3),
    "zebra": ("Zebra crossings", "m:stripe", 0),
    "stop_line": ("Stop lines", "m:stop", 0),
    "arrow": ("Lane arrows", "s:arrow", 0),
    "bike_mark": ("Bike symbols", "s:bike", 0),
    "pole": ("Utility poles", None, 0),
    "bollard": ("Bollards", None, 0),
    "hydrant": ("Fire hydrants", None, 0),
    "manhole": ("Manholes and drains", None, 0),
    "box": ("Junction boxes", None, 0),
    "cctv": ("CCTV cameras", None, 0),
    "roadworks": ("Cones and temporary barriers", None, 0),
    "sign": ("Traffic signs", None, 0),
    "shop_sign": ("Shop signs and ads", None, 0),
}


def classify(v):
    if v == "object--street-light":
        return "lamp"
    if v.startswith("object--traffic-light--pedestrians"):
        return "ped_signal"
    if v.startswith("object--traffic-light"):
        return "signal"
    if v == "object--trash-can":
        return "bin"
    if v == "object--bench":
        return "bench"
    if v == "object--bike-rack":
        return "bike_rack"
    if v.startswith("marking--discrete--crosswalk"):
        return "zebra"
    if v == "marking--discrete--stop-line":
        return "stop_line"
    if v.startswith("marking--discrete--arrow"):
        return "arrow"
    if v == "marking--discrete--symbol--bicycle":
        return "bike_mark"
    if v.startswith("object--support"):
        return "pole"
    if v == "object--bollard":
        return "bollard"
    if v == "object--fire-hydrant":
        return "hydrant"
    if v in ("object--manhole", "object--catch-basin", "object--water-valve"):
        return "manhole"
    if v == "object--junction-box":
        return "box"
    if v == "object--cctv-camera":
        return "cctv"
    if v in ("object--traffic-cone", "construction--barrier--temporary") or v.startswith("construction--"):
        return "roadworks"
    if v.split("--")[0] in ("regulatory", "warning", "information", "complementary") or v.startswith("object--traffic-sign"):
        return "sign"
    if v.startswith("object--sign"):
        return "shop_sign"
    return None


def project(lat, lon):
    return (lon - LON0) * M_PER_DEG_LON, (LAT0 - lat) * M_PER_DEG_LAT


def unproject(x, z):
    return LAT0 - z / M_PER_DEG_LAT, LON0 + x / M_PER_DEG_LON


def fetch_tile(s, w, n, e, offline):
    key = f"{s:.4f}_{w:.4f}_{n:.4f}_{e:.4f}"
    path = os.path.join(CACHE, key + ".json")
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    if offline:
        return []
    token = os.environ.get("MAPILLARY_TOKEN", "")
    if not token:
        sys.exit("street_features: MAPILLARY_TOKEN not set (and no cache for this box)")
    q = urllib.parse.urlencode({"access_token": token, "fields": "id,object_value,geometry,last_seen_at",
                                "bbox": f"{w:.6f},{s:.6f},{e:.6f},{n:.6f}", "limit": 2000})
    req = urllib.request.Request("https://graph.mapillary.com/map_features?" + q, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = json.load(r).get("data", [])
    if len(data) >= 2000:  # the API's cap: split the tile in four
        mlat, mlon = (s + n) / 2, (w + e) / 2
        data = []
        for a, b, c, d in ((s, w, mlat, mlon), (s, mlon, mlat, e), (mlat, w, n, mlon), (mlat, mlon, n, e)):
            data += fetch_tile(a, b, c, d, offline)
    os.makedirs(CACHE, exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f)
    return data


def game_points(d, layer, stride):
    if layer.startswith("m:"):
        k = layer[2:]
        return [centre(m["p"]) for m in d["markings"] if m["k"] == k]
    if layer.startswith("s:"):
        k = layer[2:]
        return [centre(s["p"]) if isinstance(s.get("p"), list) else (s["x"], s["z"]) for s in d["symbols"] if s.get("k") == k]
    v = d.get(layer, [])
    return [(float(v[i]), float(v[i + 1])) for i in range(0, len(v) - stride + 1, stride)]


def centre(p):
    xs, zs = p[0::2], p[1::2]
    return sum(xs) / len(xs), sum(zs) / len(zs)


class Grid:
    def __init__(self, pts, cell=16.0):
        self.cell = cell
        self.g = collections.defaultdict(list)
        for i, (x, z) in enumerate(pts):
            self.g[(int(x // cell), int(z // cell))].append(i)
        self.pts = pts

    def near(self, x, z, r):
        cx, cz, n = int(x // self.cell), int(z // self.cell), int(r // self.cell) + 1
        for i in range(cx - n, cx + n + 1):
            for j in range(cz - n, cz + n + 1):
                for k in self.g.get((i, j), ()):
                    px, pz = self.pts[k]
                    if (px - x) ** 2 + (pz - z) ** 2 <= r * r:
                        yield k


def merge(pts, r):
    """Greedy clusters of points within r of a cluster's first point; returns the centres."""
    if not pts:
        return []
    grid = Grid([(p[0], p[1]) for p in pts], max(r, 4.0))
    seen = set()
    out = []
    for i, p in enumerate(pts):
        if i in seen:
            continue
        group = [k for k in grid.near(p[0], p[1], r) if k not in seen]
        seen.update(group)
        cx = sum(pts[k][0] for k in group) / len(group)
        cz = sum(pts[k][1] for k in group) / len(group)
        out.append((cx, cz) + tuple(p[2:]) + (len(group),))
    return out


def street_filter(d, name, reach=25.0):
    segs = []
    for r in d["roads"]:
        if r.get("name", "").lower() == name.lower():
            p = list(zip(r["p"][0::2], r["p"][1::2]))
            segs += list(zip(p, p[1:]))
    if not segs:
        sys.exit(f"street_features: no road named {name!r}")

    def inside(x, z):
        for (ax, az), (bx, bz) in segs:
            dx, dz = bx - ax, bz - az
            L = dx * dx + dz * dz or 1e-9
            t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / L))
            if math.hypot(ax + t * dx - x, az + t * dz - z) <= reach:
                return True
        return False
    xs = [p[0] for s in segs for p in s]
    zs = [p[1] for s in segs for p in s]
    return (min(xs) - reach, min(zs) - reach, max(xs) + reach, max(zs) + reach), inside


def main():
    args = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if "help" in args:
        print(__doc__)
        return
    with open(os.path.join(ROOT, "game", "map", "centrum.json")) as f:
        d = json.load(f)
    r = float(args.get("r", 12))
    inside = None
    if "street" in args:
        box, inside = street_filter(d, args["street"])
    elif "box" in args:
        box = tuple(float(v) for v in args["box"].split(","))
    else:
        box = tuple(d["bounds"])
    x0, z0, x1, z1 = min(box[0], box[2]), min(box[1], box[3]), max(box[0], box[2]), max(box[1], box[3])

    def keep(x, z):
        return x0 <= x <= x1 and z0 <= z <= z1 and (inside is None or inside(x, z))
    n, w = unproject(x0, z0)
    s, e = unproject(x1, z1)
    feats = {}
    lat = math.floor(s / TILE_LAT) * TILE_LAT
    while lat < n:
        lon = math.floor(w / TILE_LON) * TILE_LON
        while lon < e:
            for f in fetch_tile(round(lat, 4), round(lon, 4), round(lat + TILE_LAT, 4), round(lon + TILE_LON, 4), "offline" in args):
                feats[f["id"]] = f
            lon += TILE_LON
        lat += TILE_LAT
    mly = collections.defaultdict(list)
    covered = set()
    for f in feats.values():
        lon_, lat_ = f["geometry"]["coordinates"]
        x, z = project(lat_, lon_)
        if not keep(x, z):
            continue
        covered.add((int(x // CELL), int(z // CELL)))
        c = classify(f["object_value"])
        if c:
            mly[c].append((x, z, f["object_value"], f["id"]))
    out_pts = []
    rows = []
    for c, (label, layer, stride) in CLASSES.items():
        mr = MERGE.get(c, MERGE_DEFAULT)
        m = merge(mly.get(c, []), mr)
        game = []
        if layer:
            game = [(p[0], p[1]) for p in merge([p for p in game_points(d, layer, stride) if keep(*p)], mr)]
        g_cov = [p for p in game if (int(p[0] // CELL), int(p[1] // CELL)) in covered]
        grid = Grid(game) if game else None
        used = set()
        hit = 0
        for x, z, v, fid, _n in m:
            k = None
            if grid:
                free = [k2 for k2 in grid.near(x, z, r) if k2 not in used]
                if free:
                    k = min(free, key=lambda k2: (game[k2][0] - x) ** 2 + (game[k2][1] - z) ** 2)
            if k is not None:
                used.add(k)
                hit += 1
            out_pts.append({"c": c, "v": v, "x": round(x, 1), "z": round(z, 1), "id": fid,
                            "match": k is not None if layer else None})
        g_only = [p for i, p in enumerate(game) if i not in used and (int(p[0] // CELL), int(p[1] // CELL)) in covered]
        for x, z in g_only:
            out_pts.append({"c": c, "v": "game-only", "x": round(x, 1), "z": round(z, 1), "match": False})
        rows.append((label, len(m), len(g_cov) if layer else "-", hit if layer else "-",
                     len(m) - hit if layer else len(m), len(g_only) if layer else "-"))
    where = args.get("street") or ("box" if "box" in args else "whole map")
    print(f"street_features: {where}, {len(feats)} Mapillary features in the box, {len(covered)} covered {int(CELL)} m cells, match within {r:g} m")
    print(f"{'class':30} {'mapillary':>9} {'game*':>6} {'match':>6} {'mly only':>8} {'game only*':>10}")
    for row in rows:
        print(f"{row[0]:30} {row[1]:>9} {row[2]:>6} {row[3]:>6} {row[4]:>8} {row[5]:>10}")
    print("* game points inside cells Mapillary covered; both sides merged into objects first (MERGE)")
    if "json" in args:
        with open(args["json"], "w") as f:
            json.dump({"where": where, "r": r, "points": out_pts,
                       "attribution": "Map features: Mapillary contributors, CC BY-SA 4.0"}, f)
        print(f"street_features: wrote {len(out_pts)} points to {args['json']}")


if __name__ == "__main__":
    main()
