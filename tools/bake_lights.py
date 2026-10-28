"""Bake the street-lamp light map for the night look: a pool of light on the
ground under every lamp, warm sodium orange or cold white LED, cut off where a
building stands between the lamp and the ground (pools stop at walls). The
ground, facade and tree shaders add it as emission when the lights are on, so
1.8k lamps cost one texture read instead of 1.8k lights.

Usage: python3 -I tools/bake_lights.py game/map

Reads  game/map/centrum.json (lamps, roads, paths, buildings), game/map/lod2.json (footprints)
Writes game/map/lights.bin (uint32 width, uint32 height, float32 x0, z0, metres per pixel,
       then width*height pairs of bytes: sodium, LED; 160 = full brightness, so
       overlapping pools have headroom up to 255; then uint32 n and n triples of
       float32 x, z, yaw: lamps this bake adds where OpenStreetMap maps none, on
       the bridges; map_builder.gd puts lamp posts there)

Which lamps are LED: lamps by footpaths and in parks (no street within 14 m), and every
lamp along about a quarter of the named streets (picked by a hash of the name, so a
street is lit one way along its length). The rest are sodium.
"""
import json
import math
import os
import struct
import sys
import zlib

PX = 1.0             # metres per pixel (matches ao.bin)
RADIUS = {"sodium": 15.0, "led": 12.0}
PEAK = {"sodium": 1.0, "led": 0.9}
ARM = 1.2            # the lamp head hangs 1.2 m out from the pole (map_builder.gd)
RAYS = 240           # shadow rays per lamp
STEP = 0.5           # ray march step, metres
SINK = 1.5           # light reaches this far into a wall (lights the facade's own pixels)
SCALE = 160.0        # byte value of brightness 1.0
LED_STREETS = 0.27   # share of named streets with LED lamps
BRIDGE_SPACING = 34.0  # metres between the lamps added along bridges
ROAD_KINDS = {"primary", "primary_link", "secondary", "secondary_link", "tertiary", "tertiary_link",
              "residential", "living_street", "unclassified", "service"}


def fill_polygon(grid, w, h, x0, z0, poly):
    """Scanline fill (even-odd) of a polygon in metres."""
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
                grid[row + i] = 1


def name_hash(s):
    return (zlib.crc32(s.encode("utf-8")) % 1000) / 1000.0


class RoadIndex:
    """Points every 4 m along the streets, bucketed in 32 m cells, with the street's name."""

    CELL = 32.0

    def __init__(self, roads):
        self.cells = {}
        for r in roads:
            if r["k"] not in ROAD_KINDS:
                continue
            name = r.get("name") or ""
            half = float(r.get("w", 6.0)) * 0.5
            flat = r["p"]
            pts = list(zip(flat[0::2], flat[1::2]))
            for (ax, az), (bx, bz) in zip(pts, pts[1:]):
                length = math.hypot(bx - ax, bz - az)
                steps = max(1, int(length / 4.0))
                for s in range(steps + 1):
                    t = s / steps
                    x, z = ax + (bx - ax) * t, az + (bz - az) * t
                    key = (int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL)))
                    self.cells.setdefault(key, []).append((x, z, half, name, r["k"]))

    def nearest(self, x, z):
        """(distance to the kerb, name, kind) of the closest street, or None."""
        ci, cj = int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))
        best = None
        for dj in (-1, 0, 1):
            for di in (-1, 0, 1):
                for (px, pz, half, name, kind) in self.cells.get((ci + di, cj + dj), ()):
                    d = math.hypot(px - x, pz - z) - half
                    if best is None or d < best[0]:
                        best = (d, name, kind)
        return best


def bridge_lamps(roads):
    """Lamps every BRIDGE_SPACING metres along both edges of every bridge carriageway
    (OpenStreetMap maps none on Most Poniatowskiego): (x, z, arm angle) with the arm
    leaning over the road."""
    out = []
    for r in roads:
        if not r.get("bridge") or r["k"] in ("service", "footway", "path"):
            continue
        flat = r["p"]
        pts = list(zip(flat[0::2], flat[1::2]))
        length = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))
        if length < 40.0:
            continue
        side_off = float(r.get("w", 7.0)) * 0.5 + 0.2
        shift = float(r.get("c", 0.0))  # the carriageway's centre, right of the way's line
        count = max(1, int(length // BRIDGE_SPACING))
        start = (length - (count - 1) * BRIDGE_SPACING) * 0.5
        for k in range(count):
            at = start + k * BRIDGE_SPACING
            run = 0.0
            for (ax, az), (bx, bz) in zip(pts, pts[1:]):
                seg = math.hypot(bx - ax, bz - az)
                if seg > 0 and run + seg >= at:
                    t = (at - run) / seg
                    x, z = ax + (bx - ax) * t, az + (bz - az) * t
                    dx, dz = (bx - ax) / seg, (bz - az) / seg
                    for side in (-1.0, 1.0):
                        nx, nz = -dz * side, dx * side
                        # Arm towards the road's middle: (cos a, -sin a) = -n.
                        a = math.atan2(nz, -nx)
                        off = side_off + shift * side
                        out.append((x + nx * off, z + nz * off, a))
                    break
                run += seg
    return out


def main(map_dir):
    osm = json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))
    lod2 = json.load(open(os.path.join(map_dir, "lod2.json")))
    x0, z0, x1, z1 = osm["bounds"]
    w = int(math.ceil((x1 - x0) / PX))
    h = int(math.ceil((z1 - z0) / PX))

    solid = bytearray(w * h)

    def ring(flat):
        return list(zip(flat[0::2], flat[1::2]))

    for f in lod2.get("footprints", []):
        fill_polygon(solid, w, h, x0, z0, ring(f))
    keep = lod2.get("keep_osm")
    buildings = osm["buildings"]
    for k in (keep if keep is not None else range(len(buildings))):
        b = buildings[k]
        if b["mh"] < 0.5:
            fill_polygon(solid, w, h, x0, z0, ring(b["p"]))

    def blocked(x, z):
        i = int((x - x0) / PX)
        j = int((z - z0) / PX)
        if i < 0 or j < 0 or i >= w or j >= h:
            return True
        return solid[j * w + i] != 0

    roads = RoadIndex(osm["roads"])
    warm = [0.0] * (w * h)
    cold = [0.0] * (w * h)
    lamps = osm.get("lamps", [])
    # (x, z, arm angle, kind or None): mapped lamps turn their arm by position (as
    # map_builder.gd does); bridge lamps lean over the carriageway, all sodium.
    todo = []
    for n in range(0, len(lamps) - 1, 2):
        px, pz = float(lamps[n]), float(lamps[n + 1])
        a = math.fmod(px * 0.37 + pz * 0.11, math.tau)
        todo.append((px, pz, a + math.tau if a < 0 else a, None))
    added = bridge_lamps(osm["roads"])
    for (px, pz, a) in added:
        todo.append((px, pz, a, "sodium"))
    counts = {"sodium": 0, "led": 0}
    for (px, pz, a, fixed) in todo:
        # The head hangs out along the arm: Basis(UP, a) turns +X to (cos a, -sin a).
        cx, cz = px + ARM * math.cos(a), pz - ARM * math.sin(a)
        near = roads.nearest(px, pz)
        if fixed:
            kind = fixed
        elif near is None or near[0] > 14.0:
            kind = "led"
        elif near[1] and name_hash(near[1]) < LED_STREETS:
            kind = "led"
        else:
            kind = "sodium"
        counts[kind] += 1
        radius = RADIUS[kind]
        peak = PEAK[kind]
        target = warm if kind == "sodium" else cold

        # How far each ray gets before a wall (plus SINK, so the wall itself is lit).
        start_inside = blocked(cx, cz)
        reach = []
        for r_i in range(RAYS):
            ang = math.tau * r_i / RAYS
            dx, dz = math.cos(ang), math.sin(ang)
            d = STEP
            free = radius
            while d < radius:
                if blocked(cx + dx * d, cz + dz * d):
                    # A lamp mapped a little inside a footprint still lights the street.
                    if not (start_inside and d < 3.0):
                        free = d + SINK
                        break
                d += STEP
            reach.append(free)

        i0 = max(0, int((cx - radius - x0) / PX))
        i1 = min(w - 1, int((cx + radius - x0) / PX) + 1)
        j0 = max(0, int((cz - radius - z0) / PX))
        j1 = min(h - 1, int((cz + radius - z0) / PX) + 1)
        for j in range(j0, j1 + 1):
            zc = z0 + (j + 0.5) * PX - cz
            row = j * w
            for i in range(i0, i1 + 1):
                xc = x0 + (i + 0.5) * PX - cx
                r = math.hypot(xc, zc)
                if r >= radius:
                    continue
                ang = math.atan2(zc, xc)
                bin_ = int(round(ang / math.tau * RAYS)) % RAYS
                if r > reach[bin_]:
                    continue
                q = 1.0 - (r / radius) ** 2
                # A bright core under the head and a long soft skirt.
                v = peak * (0.7 * q * q + 0.3 * math.exp(-(r / 3.2) ** 2))
                target[row + i] += v

    data = bytearray(w * h * 2)
    lit = 0
    for k in range(w * h):
        a = min(255, int(warm[k] * SCALE + 0.5))
        b = min(255, int(cold[k] * SCALE + 0.5))
        data[2 * k] = a
        data[2 * k + 1] = b
        if a or b:
            lit += 1
    with open(os.path.join(map_dir, "lights.bin"), "wb") as f:
        f.write(struct.pack("<IIfff", w, h, x0, z0, PX))
        f.write(data)
        f.write(struct.pack("<I", len(added)))
        for (px, pz, a) in added:
            f.write(struct.pack("<fff", px, pz, a))
    print(f"lights {w}x{h} at {PX} m/px: {counts['sodium']} sodium, {counts['led']} LED lamps "
          f"({len(added)} added on bridges), {100.0 * lit / (w * h):.1f}% of the map lit")


if __name__ == "__main__":
    main(sys.argv[1])
