"""Bake GUGiK LoD2 buildings, aerial-photo roof colours and terrain for the game.

Usage:
  python3 -I tools/bake_gugik.py data/work/demo game/map     (loop 3d-1: tools/prepare_demo.py's folder)

Reads   data/raw/gugik/sheets/*.gml   LoD2 CityGML (easting, northing, height; PL-KRON86-NH)
        data/raw/gugik/ortho.bmp      aerial photo of the map's lat/lon box (ortho.json)
        data/raw/gugik/terrain_10m.json  elevation grid in local map coordinates
        game/map/centrum.json         the OpenStreetMap bake (buildings decide what to keep)
Writes  game/map/lod2.bin   float32 arrays: positions, normals, colours, UVs (one vertex per corner)
        game/map/lod2.json  counts, and which OpenStreetMap buildings still need drawing
        (loop 3d-1: terrain.json is written by tools/bake_terrain.py, which runs first)

A LoD2 building is kept when it stands inside a mapped OSM building (so buildings
demolished since the 2018 survey drop out); an OSM building is kept only where
no LoD2 building covers it (so newer towers such as Varso stay).
"""
import array
import glob
import json
import math
import os
import struct
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bake_osm  # noqa: E402
from pl1992 import from_pl1992  # noqa: E402

BASE_HEIGHT = 100.0  # metres above sea level that becomes y = 0 in the game
NS = {"bldg": "http://www.opengis.net/citygml/building/2.0", "gml": "http://www.opengis.net/gml"}
BLDG = "{%s}" % NS["bldg"]
GML = "{%s}" % NS["gml"]

FACADES = ["#e9dcc2", "#d8c6a6", "#cfc4b2", "#e3c993", "#c9b08e", "#b9bec4", "#d9b98f",
           "#b59c7e", "#e6dccd", "#c98f6b", "#a8a49d", "#d6a77a"]
GLASS = ["#8fb4cb", "#9fbfd2", "#7ea4bd", "#a9c3cf"]
# Facade colours for landmarks that the data doesn't colour (OSM name -> sRGB).
LANDMARKS = {
    "Pałac Kultury i Nauki": "#d8c49c",
    "PAST-a": "#a9563c",
    "Mała PAST-a": "#ad5f44",
}
NAMED = {"white": (1, 1, 1), "grey": (0.5, 0.5, 0.5), "gray": (0.5, 0.5, 0.5), "black": (0.1, 0.1, 0.1),
         "red": (0.75, 0.25, 0.2), "brown": (0.55, 0.38, 0.26), "beige": (0.9, 0.85, 0.72),
         "yellow": (0.95, 0.85, 0.45), "orange": (0.9, 0.6, 0.3), "green": (0.45, 0.6, 0.4),
         "blue": (0.45, 0.6, 0.8), "silver": (0.75, 0.75, 0.78), "maroon": (0.5, 0.15, 0.15),
         "tan": (0.82, 0.7, 0.55), "cream": (0.96, 0.92, 0.8)}


# --- colour helpers -----------------------------------------------------------

def hex_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def parse_colour(value):
    v = (value or "").strip().lower()
    if not v:
        return None
    if v.startswith("#") and len(v) in (4, 7):
        try:
            return hex_rgb(v)
        except ValueError:
            return None
    return NAMED.get(v)


def lerp3(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


# --- terrain ------------------------------------------------------------------

class Terrain:
    """Heights on a regular grid, interpolated on the same two triangles per cell the game draws."""

    def __init__(self, path):
        d = json.load(open(path))
        self.x0, self.z0, self.step = d["x0"], d["z0"], d["step"]
        self.nx, self.nz, self.h = d["nx"], d["nz"], d["h"]

    def at(self, x, z):
        fx = min(max((x - self.x0) / self.step, 0.0), self.nx - 1.0001)
        fz = min(max((z - self.z0) / self.step, 0.0), self.nz - 1.0001)
        i, j = int(fx), int(fz)
        u, v = fx - i, fz - j
        h00 = self.h[j * self.nx + i]
        h10 = self.h[j * self.nx + i + 1]
        h01 = self.h[(j + 1) * self.nx + i]
        h11 = self.h[(j + 1) * self.nx + i + 1]
        if u >= v:
            return h00 + (h10 - h00) * u + (h11 - h10) * v
        return h00 + (h11 - h01) * u + (h01 - h00) * v


# --- aerial photo -------------------------------------------------------------

class Ortho:
    def __init__(self, bmp_path, meta_path):
        meta = json.load(open(meta_path))
        self.s, self.w, self.n, self.e = meta["bbox"]
        with open(bmp_path, "rb") as f:
            data = f.read()
        offset = struct.unpack_from("<I", data, 10)[0]
        self.width, height = struct.unpack_from("<ii", data, 18)
        bpp = struct.unpack_from("<H", data, 28)[0]
        if bpp not in (24, 32):
            raise SystemExit(f"unsupported BMP depth {bpp}")
        self.bottom_up = height > 0
        self.height = abs(height)
        self.bytes_pp = bpp // 8
        self.row = (self.width * self.bytes_pp + 3) & ~3
        self.data = data
        self.offset = offset

    def sample(self, lat, lon):
        px = int((lon - self.w) / (self.e - self.w) * self.width)
        py = int((self.n - lat) / (self.n - self.s) * self.height)
        if not (0 <= px < self.width and 0 <= py < self.height):
            return None
        row = self.height - 1 - py if self.bottom_up else py
        k = self.offset + row * self.row + px * self.bytes_pp
        b, g, r = self.data[k], self.data[k + 1], self.data[k + 2]
        return (r / 255, g / 255, b / 255)


# --- geometry -----------------------------------------------------------------

def sub(a, b):
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def normalize(v):
    ln = math.sqrt(dot(v, v))
    return (v[0] / ln, v[1] / ln, v[2] / ln) if ln > 1e-12 else (0.0, 1.0, 0.0)


def newell(ring):
    nx = ny = nz = 0.0
    for i in range(len(ring)):
        a, b = ring[i], ring[(i + 1) % len(ring)]
        nx += (a[1] - b[1]) * (a[2] + b[2])
        ny += (a[2] - b[2]) * (a[0] + b[0])
        nz += (a[0] - b[0]) * (a[1] + b[1])
    return (nx, ny, nz)


def area2d(pts):
    return sum(pts[i][0] * pts[(i + 1) % len(pts)][1] - pts[(i + 1) % len(pts)][0] * pts[i][1]
               for i in range(len(pts))) / 2


def _orient(a, b, c):
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _in_tri(p, a, b, c):
    d1, d2, d3 = _orient(a, b, p), _orient(b, c, p), _orient(c, a, p)
    return d1 > 1e-9 and d2 > 1e-9 and d3 > 1e-9


def _segments_cross(p1, p2, q1, q2):
    d1, d2 = _orient(q1, q2, p1), _orient(q1, q2, p2)
    d3, d4 = _orient(p1, p2, q1), _orient(p1, p2, q2)
    return d1 * d2 < -1e-12 and d3 * d4 < -1e-12


def bridge_holes(pts, outer, holes):
    """Join holes into the outer ring with zero-width bridges (indices into pts)."""
    for hole in sorted(holes, key=lambda h: -max(pts[i][0] for i in h)):
        m = max(range(len(hole)), key=lambda k: pts[hole[k]][0])
        mp = pts[hole[m]]
        edges = [(outer[i], outer[(i + 1) % len(outer)]) for i in range(len(outer))]
        for h in holes:
            edges += [(h[i], h[(i + 1) % len(h)]) for i in range(len(h))]
        order = sorted(range(len(outer)), key=lambda k: (pts[outer[k]][0] - mp[0]) ** 2 + (pts[outer[k]][1] - mp[1]) ** 2)
        best = order[0]
        for vi in order:
            vp = pts[outer[vi]]
            if all(_segments_cross(mp, vp, pts[a], pts[b]) is False for a, b in edges
                   if a not in (outer[vi], hole[m]) and b not in (outer[vi], hole[m])):
                best = vi
                break
        outer = outer[:best + 1] + hole[m:] + hole[:m + 1] + outer[best:]
    return outer


def ear_clip(pts, ring):
    """Triangulate a counter-clockwise ring of indices into pts (2D)."""
    idx = list(ring)
    tris = []
    while len(idx) > 3:
        clipped = False
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = pts[i0], pts[i1], pts[i2]
            if _orient(a, b, c) <= 1e-10:
                continue
            blocked = False
            for j in idx:
                if j in (i0, i1, i2):
                    continue
                p = pts[j]
                if p in (a, b, c):
                    continue
                if _in_tri(p, a, b, c):
                    blocked = True
                    break
            if not blocked:
                tris.append((i0, i1, i2))
                idx.pop(k)
                clipped = True
                break
        if not clipped:
            # Only collinear or degenerate corners left: drop one and carry on.
            flat = [k for k in range(len(idx)) if abs(_orient(pts[idx[k - 1]], pts[idx[k]], pts[idx[(k + 1) % len(idx)]])) <= 1e-10]
            if flat:
                idx.pop(flat[0])
            else:
                for k in range(1, len(idx) - 1):
                    tris.append((idx[0], idx[k], idx[k + 1]))
                return tris
    if len(idx) == 3:
        tris.append(tuple(idx))
    return tris


def triangulate(exterior, interiors):
    """3D planar polygon with holes -> (triangles as vertex triples, normal)."""
    n = newell(exterior)
    axis = max(range(3), key=lambda k: abs(n[k]))
    keep = [k for k in range(3) if k != axis]
    verts = list(exterior)
    rings = [list(range(len(exterior)))]
    for hole in interiors:
        rings.append(list(range(len(verts), len(verts) + len(hole))))
        verts += hole
    pts = [(v[keep[0]], v[keep[1]]) for v in verts]
    outer = rings[0]
    if area2d([pts[i] for i in outer]) < 0:
        outer = outer[::-1]
    holes = []
    for h in rings[1:]:
        if area2d([pts[i] for i in h]) > 0:
            h = h[::-1]
        holes.append(h)
    ring = bridge_holes(pts, outer, holes) if holes else outer
    return [(verts[a], verts[b], verts[c]) for a, b, c in ear_clip(pts, ring)], normalize(n)


def point_in_poly(x, z, poly):
    return bake_osm.point_in_poly(x, z, poly)


# --- CityGML ------------------------------------------------------------------

def read_ring(ring_el, convert):
    pts = []
    for pos in ring_el.iter(GML + "pos"):
        e, n, h = (float(v) for v in pos.text.split())
        pts.append(convert(e, n, h))
    pl = ring_el.find(GML + "posList")
    if pl is not None:
        vals = [float(v) for v in pl.text.split()]
        for k in range(0, len(vals) - 2, 3):
            pts.append(convert(vals[k], vals[k + 1], vals[k + 2]))
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts.pop()
    return pts


def buildings_in(path, convert):
    for _, el in ET.iterparse(path, events=("end",)):
        if el.tag != BLDG + "Building":
            continue
        surfaces = []
        for kind in ("RoofSurface", "WallSurface", "GroundSurface"):
            for surf in el.iter(BLDG + kind):
                for poly in surf.iter(GML + "Polygon"):
                    ext = poly.find(GML + "exterior/" + GML + "LinearRing")
                    if ext is None:
                        continue
                    outer = read_ring(ext, convert)
                    holes = [read_ring(r, convert) for r in poly.findall(GML + "interior/" + GML + "LinearRing")]
                    if len(outer) >= 3:
                        surfaces.append((kind, outer, [h for h in holes if len(h) >= 3]))
        yield el.get(GML + "id"), surfaces
        el.clear()


# --- main ---------------------------------------------------------------------

def main(raw, out_dir):
    terrain = Terrain(os.path.join(raw, "terrain_10m.json"))
    ortho = Ortho(os.path.join(raw, "ortho.bmp"), os.path.join(raw, "ortho.json"))
    osm = json.load(open(os.path.join(out_dir, "centrum.json"), encoding="utf-8"))
    bx0, bz0, bx1, bz1 = osm["bounds"]

    cache = {}

    def convert(e, n, h):
        key = (e, n)
        if key not in cache:
            lat, lon = from_pl1992(n, e)
            x, z = bake_osm.project(lat, lon)
            cache[key] = (x, z, lat, lon)
        x, z, _, _ = cache[key]
        return (x, h, z)  # (x, absolute height, z)

    def latlon(x, z):
        return bake_osm.LAT0 - z / bake_osm.M_PER_DEG_LAT, bake_osm.LON0 + x / bake_osm.M_PER_DEG_LON

    # OSM building polygons, gridded for point lookups.
    osm_polys = []
    for b in osm["buildings"]:
        p = list(zip(b["p"][0::2], b["p"][1::2]))
        xs, zs = [q[0] for q in p], [q[1] for q in p]
        osm_polys.append((p, min(xs), min(zs), max(xs), max(zs), b))
    cell = 50.0
    grid = {}
    for k, (_, x0, z0, x1, z1, _) in enumerate(osm_polys):
        for gi in range(int(x0 // cell), int(x1 // cell) + 1):
            for gj in range(int(z0 // cell), int(z1 // cell) + 1):
                grid.setdefault((gi, gj), []).append(k)

    def osm_at(x, z):
        hits = []
        for k in grid.get((int(x // cell), int(z // cell)), []):
            p, x0, z0, x1, z1, _ = osm_polys[k]
            if x0 <= x <= x1 and z0 <= z <= z1 and point_in_poly(x, z, p):
                hits.append(k)
        return hits

    seen = set()
    kept = []
    for path in sorted(glob.glob(os.path.join(raw, "sheets", "*.gml"))):
        for gid, surfaces in buildings_in(path, convert):
            if gid in seen or not surfaces:
                continue
            seen.add(gid)
            ground = [s for s in surfaces if s[0] == "GroundSurface"]
            ref = ground[0] if ground else surfaces[0]
            tris, _ = triangulate(ref[1], ref[2])
            if not tris:
                continue
            big = max(tris, key=lambda t: abs(_orient((t[0][0], t[0][2]), (t[1][0], t[1][2]), (t[2][0], t[2][2]))))
            cx = sum(v[0] for v in big) / 3
            cz = sum(v[2] for v in big) / 3
            if not (bx0 <= cx <= bx1 and bz0 <= cz <= bz1):
                continue
            outline = ground[0][1] if ground else ref[1]
            if any(not (bx0 - 6 <= v[0] <= bx1 + 6 and bz0 - 6 <= v[2] <= bz1 + 6) for v in outline):
                continue  # hangs over the edge of the map
            matches = osm_at(cx, cz)
            if not matches:
                continue  # not on today's map: demolished or never there
            footprints = [[(v[0], v[2]) for v in g[1]] for g in ground] or [[(v[0], v[2]) for v in ref[1]]]
            kept.append((gid, surfaces, matches, footprints))

    # OSM buildings that no LoD2 footprint covers stay as simple extrusions.
    # An OSM building is covered when its centre, or most of its corners, fall inside LoD2 footprints.
    covered = set()
    for _, _, matches, footprints in kept:
        covered.update(matches)
        for footprint in footprints:
            fx = [p[0] for p in footprint]
            fz = [p[1] for p in footprint]
            for k, (p, x0, z0, x1, z1, _) in enumerate(osm_polys):
                if k in covered or x1 < min(fx) or x0 > max(fx) or z1 < min(fz) or z0 > max(fz):
                    continue
                cx = sum(q[0] for q in p) / len(p)
                cz = sum(q[1] for q in p) / len(p)
                inside = sum(1 for q in p if point_in_poly(q[0], q[1], footprint))
                if point_in_poly(cx, cz, footprint) or inside * 2 >= len(p):
                    covered.add(k)
    keep_osm = [k for k in range(len(osm_polys)) if k not in covered]

    landmark_polys = [(l["name"], list(zip(l["p"][0::2], l["p"][1::2]))) for l in osm.get("landmarks", [])
                      if l["name"] in LANDMARKS]

    def landmark_colour(points):
        for name, poly in landmark_polys:
            if any(point_in_poly(x, z, poly) for x, z in points):
                return hex_rgb(LANDMARKS[name])
        return None

    pos, nrm, col, uvs = array.array("f"), array.array("f"), array.array("f"), array.array("f")
    uv2s = array.array("f")  # x: per-building random 0..1 (facade style), y: wall top above ground (-1 on roofs)
    footprints_out = []

    def emit(tri, n, rgba, uv, uv2):
        """Append one triangle, wound for Godot (clockwise front faces)."""
        a, b, c = tri
        if dot(cross(sub(b, a), sub(c, a)), n) > 0:
            tri = [a, c, b]
        for v in tri:
            pos.extend(v)
            nrm.extend(n)
            col.extend(rgba)
            uvs.extend(uv)
            uv2s.extend(uv2)

    def rooftop_boxes(outer, roof_y, axis, seed01, rnd_seed):
        """A few vents, lift rooms and AC units on a large flat roof."""
        pts2 = [(v[0], v[2]) for v in outer]
        area = abs(area2d(pts2))
        if area < 150:
            return
        xs, zs = [p[0] for p in pts2], [p[1] for p in pts2]
        ux, uz = math.cos(axis), math.sin(axis)
        placed = 0
        want = min(6, int(area / 160))
        for k in range(want * 6):
            if placed >= want:
                break
            h1 = (math.sin((rnd_seed + k) * 12.9898) * 43758.5453) % 1.0
            h2 = (math.sin((rnd_seed + k) * 78.233) * 12543.123) % 1.0
            h3 = (math.sin((rnd_seed + k) * 37.719) * 9631.77) % 1.0
            px = min(xs) + (max(xs) - min(xs)) * h1
            pz = min(zs) + (max(zs) - min(zs)) * h2
            w = 1.4 + 2.8 * h3
            d = 1.2 + 2.2 * ((h3 * 7.1) % 1.0)
            hgt = 0.8 + 1.8 * ((h3 * 3.3) % 1.0)
            probe = [(px + ux * sx * (w / 2 + 1) - uz * sz * (d / 2 + 1), pz + uz * sx * (w / 2 + 1) + ux * sz * (d / 2 + 1))
                     for sx in (-1, 1) for sz in (-1, 1)]
            if not all(point_in_poly(qx, qz, pts2) for qx, qz in probe):
                continue
            shade = (0.78, 0.76, 0.72) if h1 < 0.5 else ((0.86, 0.85, 0.82) if h2 < 0.6 else (0.62, 0.6, 0.57))
            corner = lambda sx, sz, yy: (px + ux * sx * w / 2 - uz * sz * d / 2, yy, pz + uz * sx * w / 2 + ux * sz * d / 2)
            y0, y1 = roof_y - 0.1, roof_y + hgt
            top = [corner(-1, -1, y1), corner(1, -1, y1), corner(1, 1, y1), corner(-1, 1, y1)]
            emit([top[0], top[1], top[2]], (0.0, 1.0, 0.0), shade + (1.0,), (-1.0, -1.0), (seed01, -1.0))
            emit([top[0], top[2], top[3]], (0.0, 1.0, 0.0), shade + (1.0,), (-1.0, -1.0), (seed01, -1.0))
            sides = [((-1, -1), (1, -1)), ((1, -1), (1, 1)), ((1, 1), (-1, 1)), ((-1, 1), (-1, -1))]
            for (ax_, az_), (bx_, bz_) in sides:
                a0, b0 = corner(ax_, az_, y0), corner(bx_, bz_, y0)
                a1, b1 = corner(ax_, az_, y1), corner(bx_, bz_, y1)
                mx, mz = (a0[0] + b0[0]) / 2 - px, (a0[2] + b0[2]) / 2 - pz
                ln = math.hypot(mx, mz) or 1.0
                n = (mx / ln, 0.0, mz / ln)
                side = tuple(c * 0.92 for c in shade) + (1.0,)
                emit([a0, b0, b1], n, side, (-1.0, -1.0), (seed01, -1.0))
                emit([a0, b1, a1], n, side, (-1.0, -1.0), (seed01, -1.0))
            placed += 1
    stats = {"roof": 0, "wall": 0}
    for gid, surfaces, matches, footprints in kept:
        all_y = [v[1] for s in surfaces for v in s[1]]
        ground_z, top_z = min(all_y), max(all_y)
        height = top_z - ground_z
        seed = sum(ord(ch) for ch in gid)
        glass = height > 55.0
        osm_b = osm_polys[matches[0]][5]
        wall = parse_colour(osm_b.get("c"))
        palette = hex_rgb((GLASS if glass else FACADES)[seed % (len(GLASS) if glass else len(FACADES))])
        wall = lerp3(wall, palette, 0.3) if wall else palette
        probe = [(sum(q[0] for q in f) / len(f), sum(q[1] for q in f) / len(f)) for f in footprints]
        osm_poly = osm_polys[matches[0]][0]
        probe.append((sum(q[0] for q in osm_poly) / len(osm_poly), sum(q[1] for q in osm_poly) / len(osm_poly)))
        special = landmark_colour(probe)
        if special:
            wall, glass = special, False
        corners = [q for f in footprints for q in f]
        cx = sum(q[0] for q in corners) / len(corners)
        cz = sum(q[1] for q in corners) / len(corners)
        seed01 = (seed * 0.6180339887) % 1.0
        main = max(footprints, key=lambda f: abs(area2d(f)))
        edges = [(main[i], main[(i + 1) % len(main)]) for i in range(len(main))]
        ea, eb = max(edges, key=lambda e: math.hypot(e[1][0] - e[0][0], e[1][1] - e[0][1]))
        axis = math.atan2(eb[1] - ea[1], eb[0] - ea[0])
        for f in footprints:
            if abs(area2d(f)) >= 8:
                ring = f if area2d(f) > 0 else f[::-1]
                footprints_out.append([round(c, 1) for q in ring for c in q])

        for kind, outer, holes in surfaces:
            if kind == "GroundSurface":
                continue
            tris, n = triangulate(outer, holes)
            if kind == "RoofSurface":
                if n[1] < 0:
                    n = (-n[0], -n[1], -n[2])
                samples = []
                for t in tris[:8]:
                    sx = sum(v[0] for v in t) / 3
                    sz = sum(v[2] for v in t) / 3
                    c = ortho.sample(*latlon(sx, sz))
                    if c:
                        samples.append(c)
                if samples:
                    avg = tuple(sum(c[i] for c in samples) / len(samples) for i in range(3))
                    # Aerial photos are dull; lift them a little towards a warm grey.
                    colour = lerp3(tuple(min(1.0, v * 1.12) for v in avg), (0.55, 0.52, 0.5), 0.2)
                else:
                    colour = (0.55, 0.52, 0.5)
                # Very light roofs facing the sun blow out to white; cap their brightness.
                lum = 0.3 * colour[0] + 0.59 * colour[1] + 0.11 * colour[2]
                if lum > 0.7:
                    colour = tuple(c * 0.7 / lum for c in colour)
                stats["roof"] += 1
            else:
                mid = (sum(v[0] for v in outer) / len(outer), 0, sum(v[2] for v in outer) / len(outer))
                if (mid[0] - cx) * n[0] + (mid[2] - cz) * n[2] < 0:
                    n = (-n[0], -n[1], -n[2])
                colour = wall
                stats["wall"] += 1
            tangent = normalize((-n[2], 0.0, n[0])) if kind == "WallSurface" else None
            wall_top = max(v[1] for v in outer) - ground_z
            for a, b, c in tris:
                tri = [a, b, c]
                if dot(cross(sub(b, a), sub(c, a)), n) > 0:  # Godot draws clockwise triangles as front faces
                    tri = [a, c, b]
                for v in tri:
                    x, h, z = v
                    y = h - BASE_HEIGHT
                    if h <= ground_z + 0.3:
                        # Sink the base into the ground. Where the newer terrain model disagrees
                        # by more than a storey (a construction pit), keep the survey height.
                        ground = terrain.at(x, z)
                        if abs(ground - h) < 2.5:
                            y = min(ground, h) - BASE_HEIGHT - 0.4
                    pos.extend((x, y, z))
                    nrm.extend(n)
                    if kind == "WallSurface":
                        shade = min(max((h - ground_z) / 6.0, 0.0), 1.0)
                        rgb = lerp3(tuple(ch * 0.88 for ch in colour), colour, shade)
                        col.extend((rgb[0], rgb[1], rgb[2], 0.5 if glass else 1.0))
                        uvs.extend((x * tangent[0] + z * tangent[2], h - ground_z))
                        uv2s.extend((seed01, wall_top))
                    else:
                        col.extend((colour[0], colour[1], colour[2], 1.0))
                        uvs.extend((-1.0, -1.0))
                        uv2s.extend((seed01, -1.0))
            if kind == "RoofSurface" and n[1] > 0.97:
                roof_y = sum(v[1] for v in outer) / len(outer) - BASE_HEIGHT
                rooftop_boxes(outer, roof_y, axis, seed01, seed + len(pos))

    count = len(pos) // 3
    with open(os.path.join(out_dir, "lod2.bin"), "wb") as f:
        f.write(struct.pack("<I", count))
        for arr in (pos, nrm, col, uvs, uv2s):
            arr.tofile(f)
    with open(os.path.join(out_dir, "lod2.json"), "w") as f:
        json.dump({"vertices": count, "buildings": len(kept), "keep_osm": keep_osm, "footprints": footprints_out,
                   "source": "GUGiK LoD2 3D building models (2018), aerial photo, NMT"}, f)
    # Loop 3d-1: terrain.json is tools/bake_terrain.py's now (it runs first, from the same grid).
    print(f"LoD2 buildings {len(kept)} ({stats['roof']} roof and {stats['wall']} wall polygons), "
          f"{count} vertices; OSM buildings kept {len(keep_osm)} of {len(osm_polys)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
