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
            shift = float(r.get("c", 0.0))   # map round 2: the drawn carriageway's centre
            for (ax, az), (bx, bz) in zip(pts, pts[1:]):
                length = math.hypot(bx - ax, bz - az)
                steps = max(1, int(length / 2.0))
                for s in range(steps + 1):
                    t = s / steps
                    x, z = ax + (bx - ax) * t, az + (bz - az) * t
                    if shift and length > 0:
                        x, z = x - (bz - az) / length * shift, z + (bx - ax) / length * shift
                    key = (int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL)))
                    self.cells.setdefault(key, []).append((x, z, half, name, r["k"]))

    def nearest(self, x, z, named=False):
        """(distance to the kerb, name, kind) of the closest street (`named`: with a name), or None."""
        ci, cj = int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))
        best = None
        for dj in (-1, 0, 1):
            for di in (-1, 0, 1):
                for (px, pz, half, name, kind) in self.cells.get((ci + di, cj + dj), ()):
                    if named and not name:
                        continue
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


class CarriageIndex:
    """Map round 2: the ground's carriageway areas (`carriage`, dk none), for a point-in-area test."""
    CELL = 32.0

    def __init__(self, carriage):
        self.cells = {}
        self.polys = []
        for c in carriage:
            if c.get("dk") is not None:
                continue
            q = list(zip(c["p"][0::2], c["p"][1::2]))
            k = len(self.polys)
            self.polys.append(q)
            xs, zs = [p[0] for p in q], [p[1] for p in q]
            for i in range(int(math.floor(min(xs) / self.CELL)), int(math.floor(max(xs) / self.CELL)) + 1):
                for j in range(int(math.floor(min(zs) / self.CELL)), int(math.floor(max(zs) / self.CELL)) + 1):
                    self.cells.setdefault((i, j), []).append(k)

    def hit(self, x, z):
        for k in self.cells.get((int(math.floor(x / self.CELL)), int(math.floor(z / self.CELL))), ()):
            q = self.polys[k]
            inside = False
            for (ax, az), (bx, bz) in zip(q, q[1:] + q[:1]):
                if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
                    inside = not inside
            if inside:
                return True
        return False


STREET_KINDS = {"primary", "secondary", "tertiary", "residential", "unclassified"}   # map round 2: the streets (named, see street_lamps)
STREET_SPACING = 34.0  # map round 2: lamps along a main street's stretch OpenStreetMap leaves unlit...
LAMP_GAP = 22.0        # ...where no lamp (mapped or added) stands within this of the kerb point
APPROACH_SPACING = 20.0  # map round 2 (D7): lamps along a structure's approaches on the ground
DECK_LAMP_AIR = 2.0    # map round 2: a lamp this far over the ground on a deck lights only the deck
THROUGH_STREET = 600.0 # ...and a named residential street this long or longer (all its ways; Nowy Świat 1.1 km)


def street_lamps(roads, lamps, blocked, taken, decks, trams, kerb_of, spacing=STREET_SPACING, min_len=STREET_SPACING, gap=LAMP_GAP):
    """Map round 2 (2026-10-29, L3/D7): the main streets read dark at night wherever OpenStreetMap
    maps no street lamps along them (Al. Jerozolimskie east of Rondo Dmowskiego: none within 40 m
    of (-615, 394); Nowy Świat at (-331, 18); Most Poniatowskiego's abutments between the towers).
    Along every ground primary, secondary or tertiary street a lamp goes every STREET_SPACING at
    the kerb (0.6 m out; a one-way carriageway on its right, the outer side of a dual
    carriageway; a two-way street on both sides, staggered) wherever no lamp stands within
    LAMP_GAP, the spot is not in a building, on a carriageway, a tram track or under or on a
    deck. (x, z, arm angle) with the arm over the road."""
    out = []
    near = {}

    def add_near(x, z):
        near.setdefault((int(x // 32), int(z // 32)), []).append((x, z))

    def has_near(x, z, r):
        ci, cj = int(x // 32), int(z // 32)
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                for lx, lz in near.get((ci + di, cj + dj), ()):
                    if (lx - x) ** 2 + (lz - z) ** 2 < r * r:
                        return True
        return False
    for i in range(0, len(lamps) - 1, 2):
        add_near(lamps[i], lamps[i + 1])
    for x, z, *_ in taken:
        add_near(x, z)
    tram_cells = {}
    for t in trams:
        p = list(zip(t["p"][0::2], t["p"][1::2]))
        for (ax, az), (bx, bz) in zip(p, p[1:]):
            n = max(1, int(math.hypot(bx - ax, bz - az) / 2.0))
            for k in range(n + 1):
                x, z = ax + (bx - ax) * k / n, az + (bz - az) * k / n
                tram_cells.setdefault((int(x // 8), int(z // 8)), []).append((x, z))

    def on_tram(x, z):
        ci, cj = int(x // 8), int(z // 8)
        return any((tx - x) ** 2 + (tz - z) ** 2 < 2.0 ** 2 for di in (-1, 0, 1) for dj in (-1, 0, 1)
                   for tx, tz in tram_cells.get((ci + di, cj + dj), ()))
    through = {}
    for r in roads:
        if r.get("name") and r["k"] in STREET_KINDS:
            p = list(zip(r["p"][0::2], r["p"][1::2]))
            through[r["name"]] = through.get(r["name"], 0.0) + sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(p, p[1:]))
    for r in roads:
        if r["k"] not in STREET_KINDS or r.get("bridge") or r.get("dk") is not None or r.get("tn") is not None:
            continue
        if r["k"] in ("residential", "unclassified") and through.get(r.get("name") or "", 0.0) < THROUGH_STREET:
            continue   # a named through street only (Nowy Świat; driveways and short side streets stay as mapped)
        pts = list(zip(r["p"][0::2], r["p"][1::2]))
        length = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))
        if length < min_len:
            continue
        shift = float(r.get("c", 0.0))
        side_off = float(r.get("w", 7.0)) * 0.5 + 0.6
        # A side street (residential, unclassified) is lit from one side, as Warsaw's are.
        sides = (1.0,) if r.get("oneway") or r["k"] in ("residential", "unclassified") else (1.0, -1.0)
        for side in sides:
            stagger = 0.0 if side > 0 else spacing * 0.5
            at = min(spacing * 0.5 + stagger, length * (0.35 if side > 0 else 0.65))
            while at < length:
                run = 0.0
                for (ax, az), (bx, bz) in zip(pts, pts[1:]):
                    seg = math.hypot(bx - ax, bz - az)
                    if seg > 0 and run + seg >= at:
                        t = (at - run) / seg
                        x, z = ax + (bx - ax) * t, az + (bz - az) * t
                        dx, dz = (bx - ax) / seg, (bz - az) / seg
                        # "Right" of a direction (dx, dz) is (-dz, dx) (bake_roads).
                        nx, nz = -dz * side, dx * side
                        off = side_off + shift * side
                        px, pz = x + nx * off, z + nz * off
                        free = not has_near(px, pz, gap) and not blocked(px, pz) and not on_tram(px, pz)
                        if free:
                            kerb = kerb_of(px, pz)
                            free = kerb is None or kerb[0] >= 0.3
                        if free and decks is not None:
                            free = not decks.at(px, pz) and not decks.at(x, z)
                        if free:
                            a = math.atan2(nz, -nx)   # arm towards the road (as bridge_lamps)
                            out.append((px, pz, a, r.get("name") or ""))
                            add_near(px, pz)
                        break
                    run += seg
                at += spacing
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
    # Map round 2b: a street that carries on from a bridge (a ground road sharing an end with a
    # bridge road: Al. Poniatowskiego past the towers) is lit like its bridge, sodium; its name's
    # hash made it LED, and the colour changed at the towers.
    bridge_ends = [q for r in osm["roads"] if r.get("bridge")
                   for q in ((r["p"][0], r["p"][1]), (r["p"][-2], r["p"][-1]))]
    from_bridge = set()
    for r in osm["roads"]:
        if r.get("bridge") or not r.get("name"):
            continue
        for q in ((r["p"][0], r["p"][1]), (r["p"][-2], r["p"][-1])):
            if any(abs(q[0] - b[0]) < 2.0 and abs(q[1] - b[1]) < 2.0 for b in bridge_ends):
                from_bridge.add(r["name"])

    def street_is_led(name):
        return bool(name) and name not in from_bridge and name_hash(name) < LED_STREETS
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
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import check_roads
    terrain = check_roads.Map(map_dir)
    decks = terrain.decks
    # Map round 2: a bridge lamp stands on its deck. Where the deck's corridor was narrowed beside
    # a lane under it (bake_structures narrow_decks), the edge lamp stood just off the deck, on the
    # road under the viaduct (the Jana Pawła II viaduct): it moves in along its arm onto the deck.
    added = []
    for (px, pz, a) in bridge_lamps(osm["roads"]):
        ux, uz = math.cos(a), -math.sin(a)   # along the arm, towards the road's middle
        for k in range(9):
            qx, qz = px + ux * 0.2 * k, pz + uz * 0.2 * k
            if decks.at(qx, qz):
                added.append((qx, qz, a))
                break
    for (px, pz, a) in added:
        todo.append((px, pz, a, "sodium"))
    # Map round 2: the main streets' unlit stretches (street_lamps); sodium or LED by the street
    # as the mapped lamps are (map_builder reads the kind back from this map at the lamp's head).
    carriage = CarriageIndex(osm.get("carriage", []))
    # Loop 3d-1: never on the ground's asphalt as check_streets S1 sees it (the carriageway areas
    # and the roads' drawn strips; an island or a median is fine, a deck is a deck lamp's): the
    # strips catch the streets with no mapped carriageway area (5 lamps stood in lanes).
    import check_streets
    on_asphalt, raised = check_streets.pole_tests(osm)

    def lamp_blocked(x, z):
        return blocked(x, z) or (on_asphalt(x, z) and not raised(x, z) and not decks.at(x, z))
    streets = street_lamps(osm["roads"], lamps, lamp_blocked, added, decks, osm.get("trams", []),
                           lambda x, z: (-1.0,) if carriage.hit(x, z) else roads.nearest(x, z))
    # Map round 2 (D7): a structure's approaches on the ground (road `fills` that meet a deck's end:
    # Most Poniatowskiego's abutments between its towers) are lit like the deck, every
    # APPROACH_SPACING both sides, sodium.
    ends = [q for pc in osm.get("decks", {}).get("pieces", []) if pc.get("k", "road") == "road"
            for q in ((pc["p"][0], pc["p"][1]), (pc["p"][-2], pc["p"][-1]))]
    approaches = []
    for f in osm.get("fills", []):
        if f.get("k") != "road":
            continue
        fp = list(zip(f["p"][0::2], f["p"][1::2]))
        if any(math.hypot(ex - q[0], ez - q[1]) < 3.0 for ex, ez in ends for q in (fp[0], fp[-1])):
            approaches.append({"p": f["p"], "w": float(f["l"]) + float(f["r"]), "c": (float(f["r"]) - float(f["l"])) * 0.5,
                               "k": "secondary", "name": "", "oneway": False})
    abut = street_lamps(approaches, lamps, lamp_blocked, added + streets, decks, osm.get("trams", []),
                        lambda x, z: (-1.0,) if carriage.hit(x, z) else None, APPROACH_SPACING, 12.0, 12.0)
    # The street's own kind (as its mapped lamps: LED_STREETS by its name), not the nearest
    # road's at the lamp (an unnamed ramp beside it made every other lamp LED).
    for (px, pz, a, name) in streets:
        todo.append((px, pz, a, "led" if street_is_led(name) else "sodium"))
    for (px, pz, a, name) in abut:
        todo.append((px, pz, a, "sodium"))
    streets = [q[:3] for q in streets + abut]
    n_bridge = len(added)
    added = added + streets
    counts = {"sodium": 0, "led": 0}
    for (px, pz, a, fixed) in todo:
        # The head hangs out along the arm: Basis(UP, a) turns +X to (cos a, -sin a).
        cx, cz = px + ARM * math.cos(a), pz - ARM * math.sin(a)
        near = roads.nearest(px, pz)
        if fixed:
            kind = fixed
        elif near is None or near[0] > 14.0:
            kind = "led"
        else:
            # Map round 2b: the kind of the named street the lamp lights (an unnamed ramp or
            # service way nearer to it doesn't decide), sodium on a street that carries a bridge.
            named = near if near[1] else roads.nearest(px, pz, named=True)
            kind = "led" if street_is_led(named[1] if named is not None and named[0] <= 14.0 else "") else "sodium"
        counts[kind] += 1
        radius = RADIUS[kind]
        peak = PEAK[kind]
        target = warm if kind == "sodium" else cold
        # Map round 2 (D6): a lamp on a bridge deck lights its deck, not the river, the shoals
        # or the boulevard beside and under it 10-20 m down (the light map is flat: its pool fell
        # on Most Poniatowskiego's gravel shoals). Its pool keeps to the deck's own corridors.
        deck_y = None
        for hd, _, _ in decks.at(px, pz):
            if hd > terrain.terrain(px, pz) + DECK_LAMP_AIR and (deck_y is None or hd > deck_y):
                deck_y = hd

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
                if deck_y is not None and not any(abs(hd - deck_y) < 3.0 for hd, _, _ in
                                                  decks.at(cx + xc, cz + zc)):
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
          f"({n_bridge} added on bridges, {len(added) - n_bridge} on unlit main streets), {100.0 * lit / (w * h):.1f}% of the map lit")


if __name__ == "__main__":
    main(sys.argv[1])
