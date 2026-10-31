"""Loop 3d-1: prepare the demo box's bake inputs from the raw downloads (data/raw stays read-only).

    python3 tools/prepare_demo.py [all|osm|ortho|terrain|sheets|trees]   (default: all; ~1-2 min)

(Not `-I`-only: the aerial photo step needs Pillow, like tools/overlay_ortho.py; every other
step is standard library.) Reads data/raw/demo (tools/fetch_demo.py's downloads, MANIFEST.md),
data/raw/gugik/sheets and data/raw/gugik/trees/1465, and writes data/work/demo/ (gitignored),
the folder the bake chain reads for the box bake_osm.BBOX (docs/DEVELOPMENT.md "Map data"):

  osm_demo.json      the 9-tile Overpass export cut to the box: every node within PAD of it, every
                     way with a node there (with all its nodes), every multipolygon (with all its
                     member ways and nodes) that has a member way there. Route relations are
                     left out (each brings its whole line, from Gdańsk to Kyiv: NOTES.md 5).
  ortho.bmp/.json    the four aerial-photo tiles joined and cut to the box (24-bit BMP, the shape
                     bake_gugik.py, check_roads.py and the overlays read)
  terrain_10m.json   the 10 m elevation grid (EVRF2007) cut to the nodes at or just past the box
  sheets/            links to the LoD2 1:5000 sheets (CityGML) that meet the box
  trees/             links to the GUGiK tree sheets (1:2500) that meet the box, for
                     tools/bake_trees_gugik.py data/work/demo/trees data/work/demo/trees_area.json

Coordinates and the box come from tools/bake_osm.py (ORIGIN, BBOX; map north: BBOX_NORTH too, the
map's boxes are bake_osm.BOXES and their bounding box bake_osm.HULL).
"""
import glob
import json
import math
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402
from pl1992 import from_pl1992  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
RAW = os.path.join(ROOT, "data", "raw")
WORK = os.path.join(ROOT, "data", "work", "demo")
PAD = 0.003   # degrees (~330 m north-south, ~200 m east-west) of nodes kept round the box
KEEP_RELATIONS = {"multipolygon"}


def box_meets(s, w, n, e, pad=0.0):
    """Whether the lat/lon box meets one of the map's boxes (map north: BBOX or BBOX_NORTH)."""
    return any(s <= bn + pad and n >= bs - pad and w <= be + pad and e >= bw - pad for bs, bw, bn, be in bake_osm.BOXES)


def osm():
    src = os.path.join(RAW, "demo", "osm", "osm_demo.json")
    data = json.load(open(src, encoding="utf-8"))
    els = data["elements"]
    near = set()
    nodes = {}
    for el in els:
        if el["type"] == "node":
            nodes[el["id"]] = el
            if bake_osm.in_bbox(el["lat"], el["lon"], PAD):
                near.add(el["id"])
    ways = {el["id"]: el for el in els if el["type"] == "way"}
    keep_ways = {i for i, way in ways.items() if any(k in near for k in way.get("nodes", []))}
    rels = []
    for el in els:
        if el["type"] != "relation" or el.get("tags", {}).get("type") not in KEEP_RELATIONS:
            continue
        members = el.get("members", [])
        if any(m["type"] == "way" and m["ref"] in keep_ways for m in members) or \
                any(m["type"] == "node" and m["ref"] in near for m in members):
            rels.append(el)
            keep_ways |= {m["ref"] for m in members if m["type"] == "way" and m["ref"] in ways}
    keep_nodes = set(near)
    for i in keep_ways:
        keep_nodes.update(ways[i].get("nodes", []))
    out = [nodes[i] for i in sorted(keep_nodes) if i in nodes]
    out += [ways[i] for i in sorted(keep_ways)]
    out += sorted(rels, key=lambda r: r["id"])
    dst = os.path.join(WORK, "osm_demo.json")
    with open(dst, "w", encoding="utf-8") as fh:
        json.dump({"version": data.get("version"), "generator": data.get("generator"),
                   "osm3s": data.get("osm3s"), "elements": out}, fh, separators=(",", ":"), ensure_ascii=False)
    print("osm: %d nodes, %d ways, %d multipolygons of %d elements -> %s (%.1f MB)" % (
        len(keep_nodes), len(keep_ways), len(rels), len(els), os.path.relpath(dst, ROOT), os.path.getsize(dst) / 1e6))


def ortho():
    from PIL import Image
    meta = json.load(open(os.path.join(RAW, "demo", "gugik", "ortho", "ortho_tiles.json")))
    bs, bw, bn, be = meta["box"]
    tiles = meta["tiles"]
    xs = sorted({t["bbox"][1] for t in tiles})
    ys = sorted({t["bbox"][2] for t in tiles}, reverse=True)
    tw, th = tiles[0]["width"], tiles[0]["height"]
    full = Image.new("RGB", (tw * len(xs), th * len(ys)))
    for t in tiles:
        im = Image.open(os.path.join(RAW, "demo", "gugik", "ortho", t["file"])).convert("RGB")
        full.paste(im, (xs.index(t["bbox"][1]) * tw, ys.index(t["bbox"][2]) * th))
    s, w, n, e = bake_osm.HULL   # map north: the whole bounding box (the part left outside unused)
    W, H = full.size
    x0 = round((w - bw) / (be - bw) * W)
    x1 = round((e - bw) / (be - bw) * W)
    y0 = round((bn - n) / (bn - bs) * H)
    y1 = round((bn - s) / (bn - bs) * H)
    crop = full.crop((x0, y0, x1, y1))
    # The cut's real edges (whole pixels), so the photo's box is exact.
    cw = bw + x0 / W * (be - bw)
    ce = bw + x1 / W * (be - bw)
    cn = bn - y0 / H * (bn - bs)
    cs = bn - y1 / H * (bn - bs)
    crop.save(os.path.join(WORK, "ortho.bmp"))
    with open(os.path.join(WORK, "ortho.json"), "w") as fh:
        json.dump({"bbox": [round(cs, 7), round(cw, 7), round(cn, 7), round(ce, 7)],
                   "width": crop.size[0], "height": crop.size[1],
                   "source": "data/raw/demo/gugik/ortho (4 tiles, 0.87 m/px), cut by tools/prepare_demo.py"}, fh)
    print("ortho: %d x %d px -> data/work/demo/ortho.bmp" % crop.size)


def terrain():
    d = json.load(open(os.path.join(RAW, "demo", "gugik", "nmt10", "terrain_10m.json")))
    o = d.get("origin")
    if o and (abs(o[0] - bake_osm.LAT0) > 1e-9 or abs(o[1] - bake_osm.LON0) > 1e-9):
        raise SystemExit("terrain: the grid's origin %s is not bake_osm.ORIGIN" % o)
    hull = bake_osm.HULL   # map north: the lattice spans the bounding box; the builder draws the map's part
    sw, ne = bake_osm.project(hull[0], hull[1]), bake_osm.project(hull[2], hull[3])
    x0, z0, step, nx, nz = d["x0"], d["z0"], d["step"], d["nx"], d["nz"]
    # The nodes at or just past the box's edges, no more: a row beyond them puts ground
    # triangles past the sector grid (check_streaming's identity: 26 tiles north of j -4).
    i0 = max(math.floor((sw[0] - x0) / step + 1e-6), 0)
    i1 = min(math.ceil((ne[0] - x0) / step - 1e-6), nx - 1)
    j0 = max(math.floor((ne[1] - z0) / step + 1e-6), 0)
    j1 = min(math.ceil((sw[1] - z0) / step - 1e-6), nz - 1)
    # Loop 3d-1: the box's east edge (21.056) lies past the 10 m fetch's last column; the 1 m
    # grid covers it, so the lattice goes on there.
    i1 = math.ceil((ne[0] - x0) / step - 1e-6)
    j1 = math.ceil((sw[1] - z0) / step - 1e-6)
    h = d["h"]
    nmt1 = Mosaic(os.path.join(RAW, "demo", "gugik", "nmt1_box"), os.path.join(RAW, "demo", "gugik", "nmt1_north"))
    roads = RoadCells(os.path.join(WORK, "osm_demo.json")) if nmt1.ok else None
    cut, stats = [], {"10 m grid": 0, "1 m ground": 0, "1 m road": 0}
    for j in range(j0, j1 + 1):
        jac = None
        for i in range(i0, i1 + 1):
            x, z = x0 + i * step, z0 + j * step
            v = nmt1.node(x, z, roads, (i - i0) % 32 == 0) if nmt1.ok else None
            if v is None:
                v = h[min(j, nz - 1) * nx + min(i, nx - 1)]
                stats["10 m grid"] += 1
            else:
                v, kind = v
                stats[kind] += 1
            cut.append(round(v, 2))
    out = {"x0": round(x0 + i0 * step, 2), "z0": round(z0 + j0 * step, 2), "step": step,
           "nx": i1 - i0 + 1, "nz": j1 - j0 + 1, "h": cut, "origin": [bake_osm.LAT0, bake_osm.LON0],
           "heights": "EVRF2007; loop 3d-1: from the 1 m NMT (" + NODE_RULE + ")" if nmt1.ok else d.get("heights", "EVRF2007")}
    with open(os.path.join(WORK, "terrain_10m.json"), "w") as fh:
        json.dump(out, fh, separators=(",", ":"))
    print("terrain: %d x %d points, x0 %.2f z0 %.2f; %s" % (out["nx"], out["nz"], out["x0"], out["z0"],
          ", ".join("%s %d" % kv for kv in stats.items())))


# Loop 3d-1 (the 1 m NMT of the whole box, the user's yes): a 10 m node is what the ground does over
# its 10 m cell, not one point of it. Point samples at the demo fetch's nodes (3.5 m east, 5 m south
# of the first box's) read an embankment's top or its foot by chance (up to 3 m apart; Wybrzeże
# Kościuszkowskie by Tamka stepped 2.4 m in 6 m). Each node takes the 1 m cells within 5 m of it:
# where ROAD_MIN or more of them lie on a drivable road at grade (OpenStreetMap's way and width
# estimate), the ROAD_PCT percentile of those (the road's own level, under any deck or footbridge
# the bare earth keeps); else the median of all of them.
NODE_RULE = "a node: the median of the 1 m cells within 5 m, or the median of its road cells"
NODE_R = 5.0
ROAD_MIN = 12
ROAD_PCT = 0.5


class Mosaic:
    """The 1 m tiles of gugik/nmt1_box/ as one grid (they share the WCS cell edges). Map north:
    and those of gugik/nmt1_north/ (the extension's), laid first so the box's own tiles win
    where they overlap (the same cells from the same service)."""

    def __init__(self, folder, *more):
        import array
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import geotiff
        from pl1992 import to_pl1992
        self._to = to_pl1992
        paths = sorted(glob.glob(os.path.join(folder, "*.tif")))
        if paths:
            for d in more:
                paths = sorted(glob.glob(os.path.join(d, "*.tif"))) + paths
        self.ok = bool(paths)
        if not self.ok:
            return
        grids = [geotiff.read(q) for q in paths]
        self.e0 = min(g.x0 for g in grids)
        self.n0 = max(g.y0 for g in grids)
        self.w = round(max(g.x0 + g.ncols for g in grids) - self.e0)
        self.h = round(self.n0 - min(g.y0 - g.nrows for g in grids))
        self.v = array.array("f", [float("nan")]) * (self.w * self.h)
        for g in grids:
            c0, r0 = round(g.x0 - self.e0), round(self.n0 - g.y0)
            for r in range(g.nrows):
                self.v[(r0 + r) * self.w + c0:(r0 + r) * self.w + c0 + g.ncols] = g.values[r * g.ncols:(r + 1) * g.ncols]
        self._jac = None
        offs = []
        k = int(NODE_R)
        for dz in range(-k, k + 1):
            for dx in range(-k, k + 1):
                if dx * dx + dz * dz <= NODE_R * NODE_R:
                    offs.append((dx, dz))
        self.offs = offs

    def en(self, x, z):
        lat = bake_osm.LAT0 - z / bake_osm.M_PER_DEG_LAT
        lon = bake_osm.LON0 + x / bake_osm.M_PER_DEG_LON
        n, e = self._to(lat, lon)
        return e, n

    def node(self, x, z, roads, fresh):
        e, n = self.en(x, z)
        if fresh or self._jac is None:
            ex, nx_ = self.en(x + 1.0, z)
            ez, nz_ = self.en(x, z + 1.0)
            self._jac = (ex - e, ez - e, nx_ - n, nz_ - n)
        a, b, c, d = self._jac
        near = roads.near(x, z) if roads is not None else []
        allv, roadv = [], []
        w, v = self.w, self.v
        for dx, dz in self.offs:
            col = int(e + a * dx + b * dz - self.e0)
            row = int(self.n0 - (n + c * dx + d * dz))
            if not (0 <= col < w and 0 <= row < self.h):
                return None
            hv = v[row * w + col]
            if hv != hv:
                return None
            hv -= 0.0
            allv.append(hv)
            if near and roads.on(x + dx, z + dz, near):
                roadv.append(hv)
        if len(roadv) >= ROAD_MIN:
            roadv.sort()
            return roadv[int(len(roadv) * ROAD_PCT)], "1 m road"
        allv.sort()
        return allv[len(allv) // 2], "1 m ground"


class RoadCells:
    """Drivable OpenStreetMap ways on the ground (no bridge, no tunnel), as segments with half
    widths in 16 m cells, from the cut export."""

    def __init__(self, path):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import bake_roads
        els = json.load(open(path, encoding="utf-8"))["elements"]
        nodes = {e["id"]: (e["lat"], e["lon"]) for e in els if e["type"] == "node"}
        self.cells = {}
        for w in els:
            t = w.get("tags", {})
            if w["type"] != "way" or t.get("highway") not in bake_osm.DRIVABLE or t.get("area") == "yes":
                continue
            if t.get("bridge") not in (None, "no") or t.get("tunnel") not in (None, "no"):
                continue
            half = bake_roads.road_width(t)[0] * 0.5
            pts = [bake_osm.project(*nodes[i]) for i in w.get("nodes", []) if i in nodes]
            for p, q in zip(pts, pts[1:]):
                for ci in range(int((min(p[0], q[0]) - half) // 16), int((max(p[0], q[0]) + half) // 16) + 1):
                    for cj in range(int((min(p[1], q[1]) - half) // 16), int((max(p[1], q[1]) + half) // 16) + 1):
                        self.cells.setdefault((ci, cj), []).append((p, q, half))

    def near(self, x, z):
        out = []
        for ci in (int((x - 6) // 16), int((x + 6) // 16)):
            for cj in (int((z - 6) // 16), int((z + 6) // 16)):
                out.extend(self.cells.get((ci, cj), ()))
        return out

    @staticmethod
    def on(x, z, segs):
        for (ax, az), (bx, bz), half in segs:
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz
            t = max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / l2)) if l2 > 0 else 0.0
            px, pz = ax + dx * t - x, az + dz * t - z
            if px * px + pz * pz <= half * half:
                return True
        return False


def envelope_latlon(path):
    head = open(path, encoding="utf-8", errors="replace").read(4000)
    lo = [float(v) for v in head.split("<gml:lowerCorner>")[1].split("<")[0].split()]
    hi = [float(v) for v in head.split("<gml:upperCorner>")[1].split("<")[0].split()]
    corners = [from_pl1992(n, e) for e in (lo[0], hi[0]) for n in (lo[1], hi[1])]
    return (min(c[0] for c in corners), min(c[1] for c in corners),
            max(c[0] for c in corners), max(c[1] for c in corners))


def link_sheets(kind, pattern_dirs, out_name):
    out = os.path.join(WORK, out_name)
    os.makedirs(out, exist_ok=True)
    for old in os.listdir(out):
        os.remove(os.path.join(out, old))
    kept, skipped = [], 0
    for d in pattern_dirs:
        for path in sorted(glob.glob(os.path.join(d, "*.gml"))):
            if box_meets(*envelope_latlon(path)):
                os.symlink(path, os.path.join(out, os.path.basename(path)))
                kept.append(os.path.basename(path))
            else:
                skipped += 1
    print("%s: %d sheets meet the box (%d left out) -> data/work/demo/%s/" % (kind, len(kept), skipped, out_name))


def sheets():
    link_sheets("LoD2", [os.path.join(RAW, "gugik", "sheets"), os.path.join(RAW, "demo", "gugik", "sheets")], "sheets")


def trees():
    link_sheets("trees", [os.path.join(RAW, "gugik", "trees", "1465")], "trees")


STEPS = {"osm": osm, "ortho": ortho, "terrain": terrain, "sheets": sheets, "trees": trees}


def main(argv):
    os.makedirs(WORK, exist_ok=True)
    want = argv or ["all"]
    for step in (list(STEPS) if want == ["all"] else want):
        if step not in STEPS:
            print("unknown step %r (all, %s)" % (step, ", ".join(STEPS)))
            return 2
        STEPS[step]()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
