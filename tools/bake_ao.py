"""Bake a soft ambient-occlusion map of the ground: darker next to building walls,
under parked cars and beneath trees. The ground shader multiplies it in.

Usage: python3 -I tools/bake_ao.py game/map

Reads  game/map/centrum.json, game/map/lod2.json
Writes game/map/ao.bin  (uint32 width, uint32 height, float32 x0, z0, metres per pixel, then
                         width*height pairs of bytes: the buildings' occlusion, then the small
                         things' (parked cars, trees); the ground multiplies the two)

Loop 1: the buildings' share is its own channel so the occlusion fade (building.gdshader's
ghost) can lift it where a ghosted building's footprint shows through, while the trees and
parked cars keep their contact shadows.
"""
import json
import math
import os
import struct
import sys

PX = 1.0          # metres per pixel
RADIUS = 4        # blur radius for buildings, in pixels (two box passes, roughly Gaussian)
SMALL_RADIUS = 1  # tighter blur for parked cars and trees, so their contact shadows stay crisp
STRENGTH = 0.72   # how dark the ground gets right at a wall
SMALL_STRENGTH = 0.55


def fill_polygon(grid, w, h, x0, z0, poly, value):
    """Scanline fill (even-odd) of a polygon in metres; keeps the max value per pixel."""
    zs = [p[1] for p in poly]
    j0 = max(0, int((min(zs) - z0) / PX))
    j1 = min(h - 1, int((max(zs) - z0) / PX) + 1)
    n = len(poly)
    for j in range(j0, j1 + 1):
        zc = z0 + (j + 0.5) * PX
        xs = []
        for k in range(n):
            ax, az = poly[k]
            bx, bz = poly[(k + 1) % n]
            if (az > zc) != (bz > zc):
                xs.append(ax + (zc - az) * (bx - ax) / (bz - az))
        xs.sort()
        row = j * w
        for a, b in zip(xs[0::2], xs[1::2]):
            i0 = max(0, int((a - x0) / PX + 0.5))
            i1 = min(w - 1, int((b - x0) / PX - 0.5))
            for i in range(i0, i1 + 1):
                if grid[row + i] < value:
                    grid[row + i] = value


def box_blur(src, w, h, r):
    out = [0.0] * (w * h)
    tmp = [0.0] * (w * h)
    size = 2 * r + 1
    for j in range(h):
        row = j * w
        acc = sum(src[row + min(max(i, 0), w - 1)] for i in range(-r, r + 1))
        for i in range(w):
            tmp[row + i] = acc / size
            acc += src[row + min(i + r + 1, w - 1)] - src[row + max(i - r, 0)]
    for i in range(w):
        acc = sum(tmp[min(max(j, 0), h - 1) * w + i] for j in range(-r, r + 1))
        for j in range(h):
            out[j * w + i] = acc / size
            acc += tmp[min(j + r + 1, h - 1) * w + i] - tmp[max(j - r, 0) * w + i]
    return out


def main(map_dir):
    osm = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
    lod2 = json.load(open(os.path.join(map_dir, "lod2.json")))
    x0, z0, x1, z1 = osm["bounds"]
    w = int(math.ceil((x1 - x0) / PX))
    h = int(math.ceil((z1 - z0) / PX))
    occ = [0.0] * (w * h)
    small = [0.0] * (w * h)

    def ring(flat):
        return list(zip(flat[0::2], flat[1::2]))

    for f in lod2.get("footprints", []):
        fill_polygon(occ, w, h, x0, z0, ring(f), 1.0)
    keep = lod2.get("keep_osm") if lod2 else None
    buildings = osm["buildings"]
    for k in (keep if keep is not None else range(len(buildings))):
        b = buildings[k]
        if b["mh"] < 0.5:
            fill_polygon(occ, w, h, x0, z0, ring(b["p"]), 1.0)

    cars = osm.get("parked", [])
    for i in range(0, len(cars) - 3, 4):
        cx, cz, yaw = cars[i], cars[i + 1], cars[i + 2]
        fx, fz = -math.sin(yaw), -math.cos(yaw)
        sx, sz = -fz, fx
        corners = [(cx + fx * a * 2.3 + sx * b * 1.0, cz + fz * a * 2.3 + sz * b * 1.0) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        fill_polygon(small, w, h, x0, z0, corners, 0.85)

    trees = osm.get("trees", [])
    for i in range(0, len(trees) - 3, 4):
        cx, cz, s = trees[i], trees[i + 1], trees[i + 2]
        r = 2.0 * s
        disc = [(cx + math.cos(a * math.pi / 4) * r, cz + math.sin(a * math.pi / 4) * r) for a in range(8)]
        fill_polygon(small, w, h, x0, z0, disc, 0.5)
    real = osm.get("trees3d", [])  # GUGiK trees: shade under most of the real crown
    for i in range(0, len(real) - 5, 6):
        cx, cz, r = real[i], real[i + 1], min(real[i + 3], 7.0) * 0.75
        disc = [(cx + math.cos(a * math.pi / 4) * r, cz + math.sin(a * math.pi / 4) * r) for a in range(8)]
        fill_polygon(small, w, h, x0, z0, disc, 0.45)

    blurred = box_blur(box_blur(occ, w, h, RADIUS), w, h, RADIUS)
    near = box_blur(box_blur(small, w, h, SMALL_RADIUS), w, h, SMALL_RADIUS)
    data = bytearray(w * h * 2)
    for k in range(w * h):
        data[2 * k] = max(0, min(255, int(255 * (1.0 - STRENGTH * blurred[k]) + 0.5)))
        data[2 * k + 1] = max(0, min(255, int(255 * (1.0 - SMALL_STRENGTH * near[k]) + 0.5)))
    with open(os.path.join(map_dir, "ao.bin"), "wb") as f:
        f.write(struct.pack("<IIfff", w, h, x0, z0, PX))
        f.write(data)
    print(f"ao {w}x{h} at {PX} m/px, two channels")


if __name__ == "__main__":
    main(sys.argv[1])
