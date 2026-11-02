"""Street details along the main line (docs/design/street-details.md, BACKLOG audit item 5).

    python3 -I tools/bake_street_details.py [MAP.json] [--out=FILE]

Reads the finished map data (default game/map/centrum.json; nothing else, so it runs in the
cloud) and writes game/data/street_details.json: the character props (newspaper kiosks, flower
stalls, café tables, planters, ad columns, bollards, an ice-cream cart, tram and bus stop kits)
on the pavements of the streets the main line sends the player down (CORRIDORS), as

    {"_about", "src": <sha1 of the map keys read>, "kinds": [...],
     "items": [[kind, x, z, yaw, colour], ...]}

`yaw` is atan2(ax, az) with (ax, az) the way from the street to the prop, so Basis(UP, yaw) turns
+z away from the street and the prop's -z front faces it (as first_scene.gd). The first scene's
own rectangle, the Palm and the Rotunda are left alone. The props keep clear of everything
bake_street_pois.Solids knows (carriageway, kerbs, tracks, buildings, platforms, lamps, trees,
benches, bins, shelters, parked cars...). Deterministic: hashes of positions, never Python's
hash. Re-run after every centrum.json re-bake; game/tools/check_street_details.gd fails when
`src` no longer matches. Standard library only.
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

SEED = "street-details-2026"
OUT = os.path.join(ROOT, "game", "data", "street_details.json")
SRC_KEYS = ("roads", "carriage", "kerbs", "paths", "trams", "rails", "buildings", "lines", "walls", "steps",
            "guards", "medians", "areas", "platforms", "islands", "surfaces", "lamps", "signals", "benches",
            "bins", "bikes", "columns", "shelters", "parked", "trees3d", "palm", "pois", "landmarks")

# [id, character, waypoints (game x, z)] (the spec's section 1: the places the guide, the ladder and
# the final send the player through, and the streets between them).
CORRIDORS = [
    ("C1", "avenue", [(-1091, -256), (-977, 53), (-952, 172), (-872, 411)]),
    ("C2", "avenue", [(-872, 411), (-711, 426), (-433, 330), (-195, 253), (-44, 197), (150, 131), (300, 80)]),
    ("C3", "cafe", [(-195, 253), (-300, 0), (-430, -330), (-242, -285)]),
    ("C4", "cafe", [(-242, -285), (38, -323), (81, -497), (-95, -717), (-215, -958), (-221, -1201)]),
    ("C5", "river", [(-25, -1225), (162, -1057), (404, -478), (566, -22)]),
    ("C6", "avenue", [(-2644, 412), (-2149, 242), (-1671, 75), (-1181, -94)]),
    ("C7", "avenue", [(73, -1835), (900, -1800), (1321, -1948)]),
    ("C8", "avenue", [(1417, -292), (1722, -391), (1611, -372), (1496, -601)]),
]
REACH = 38.0                     # a road is on a corridor when its middle is this near the waypoints' line
ROAD_KINDS = {"primary", "secondary", "tertiary", "unclassified", "residential", "living_street", "trunk"}
NOT_NAMES = {"Wybrzeże Szczecińskie", "Nowy Zjazd"}
FIRST_SCENE = (-1080.0 - 30.0, -160.0 - 30.0, -880.0 + 30.0, 260.0 + 30.0)   # main.gd FIRST_SCENE grown by 30 m
DISCS = [(-852.0, 334.0, 40.0)]   # the Rotunda (jobs.gd FIRST_PAST); the Palm is added from the map
LANDMARK_CLEAR = 6.0
# Props: footprint radius (m), own-kind spacing (m), poster/awning colours.
RADIUS = {"kiosk": 2.2, "stall": 1.9, "cafe": 1.7, "planter": 0.9, "column": 1.2, "bollards": 1.0,
          "cart": 1.4, "post": 0.5, "ticket": 0.7}
SPACING = {"kiosk": 250.0, "stall": 250.0, "column": 150.0, "cart": 400.0}
SOLID = ("kiosk", "stall", "cart")
KINDS = ["kiosk", "stall", "cafe", "planter", "column", "bollards", "cart", "post", "ticket"]
FLOWERS = ["#e63946", "#ffd23f", "#9b5de5", "#f4a261", "#e8a6b8"]
PARASOLS = ["#2f6b4f", "#f4f1de", "#24324a", "#c8282a", "#e07a5f"]
POSTERS = ["#e07a5f", "#9db4d8", "#e8d36a", "#81b29a", "#e8a6b8"]
AWNINGS = ["#e63946", "#2a9d8f", "#ffd23f"]
MAX_ITEMS = 900
MAX_SECTOR = 70
SECTOR = 512.0
PROBE_FROM, PROBE_TO, PROBE_STEP = 1.5, 8.0, 0.5
STOP_REACH = 40.0
# G9: a café set's centre this far from the nearest building outline (the solids keep 2.25 m clear
# of a wall for its 1.7 m footprint): the shop's own frontage, a terrace at most 2 m deep.
CAFE_FRONT = (2.25, 4.3)


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


def line_dist(x, z, pts):
    return min(P.seg_dist(x, z, a, b) for a, b in zip(pts, pts[1:]))


class Placer:
    def __init__(self, data):
        self.data = data
        self.solids = P.Solids(data)
        s = self.solids.segs
        for lm in data.get("landmarks", []):
            pts = P.pairs(lm["p"])
            s.add_line(pts + pts[:1], LANDMARK_CLEAR, "landmark")
        for p in data.get("pois", []):
            if p["k"] in ("kebab", "scooter", "scooter_zone", "subway_entrance"):
                s.add((p["x"], p["z"]), (p["x"], p["z"]), 2.0, "poi")
        self.discs = list(DISCS)
        if data.get("palm"):
            self.discs.append((data["palm"][0], data["palm"][1], 40.0))
        self.items = []
        self.by_kind = {}
        self.sector = {}
        # G9 (2026-11-01): a café set stands on paving against a shopfront, never on a lawn.
        self.green = P.Polys()
        for a in data.get("areas", []):
            if a["k"] in ("grass", "park", "pitch", "water"):
                self.green.add(P.pairs(a["p"]), a["k"])

    def frontage(self, x, z):
        """True if (x, z) is on paving CAFE_FRONT m from a building's front: not in a park or a lawn,
        not nearer the wall than a parasol's reach, not farther than a terrace's depth."""
        if self.green.inside(x, z):
            return False
        gap = self.solids.segs.dist(x, z, "building")
        return CAFE_FRONT[0] <= gap <= CAFE_FRONT[1]

    def excluded(self, x, z):
        if FIRST_SCENE[0] <= x <= FIRST_SCENE[2] and FIRST_SCENE[1] <= z <= FIRST_SCENE[3]:
            return True
        return any(math.hypot(x - cx, z - cz) < r for cx, cz, r in self.discs)

    def spaced(self, kind, x, z):
        gap = SPACING.get(kind)
        if gap is None:
            return True
        near = [o for o in self.by_kind.get(kind, ()) if abs(o[0] - x) < gap and abs(o[1] - z) < gap]
        if any(math.hypot(o[0] - x, o[1] - z) < gap for o in near):
            return False
        if kind == "column":
            c = self.data.get("columns", [])
            for i in range(0, len(c) - 2, 3):
                if math.hypot(c[i] - x, c[i + 1] - z) < gap:
                    return False
        return True

    def clear(self, kind, x, z, skip=()):
        if self.excluded(x, z):
            return False
        if len(self.items) >= MAX_ITEMS:
            return False
        key = (int(x // SECTOR), int(z // SECTOR))
        if self.sector.get(key, 0) >= MAX_SECTOR:
            return False
        if self.solids.blocked(x, z, RADIUS[kind] + 0.15, skip=skip) is not None:
            return False
        for o in self.items:   # no two props overlap (cheap: lists are short per area)
            if abs(o[1] - x) < 4.0 and abs(o[2] - z) < 4.0 and math.hypot(o[1] - x, o[2] - z) < RADIUS[kind] + RADIUS[o[0]]:
                return False
        return self.spaced(kind, x, z)

    def add(self, kind, x, z, face, colour="", count=True):
        yaw = math.atan2(face[0], face[1])
        item = [kind, round(x, 1), round(z, 1), round(yaw, 2), colour]
        self.items.append(item)
        self.by_kind.setdefault(kind, []).append((item[1], item[2]))
        key = (int(x // SECTOR), int(z // SECTOR))
        self.sector[key] = self.sector.get(key, 0) + 1

    def pavement(self, kind, ax, az, tx, tz, nx, nz, half_w, lateral=0.0, ok=None):
        """The first clear pavement point out from the road's edge on the normal's side, at `lateral`
        m along the road from (ax, az): (x, z) or None."""
        d = half_w + PROBE_FROM
        while d <= half_w + PROBE_TO:
            x = ax + tx * lateral + nx * d
            z = az + tz * lateral + nz * d
            if self.clear(kind, x, z) and (ok is None or ok(x, z)):
                return x, z
            d += PROBE_STEP
        return None


def corridor_roads(data):
    """[(character, road)] for every road on a corridor: not a bridge, a street class, middle near the line."""
    out = []
    for r in data["roads"]:
        if r.get("bridge") or r["k"] not in ROAD_KINDS or r.get("name", "") in NOT_NAMES:
            continue
        p = P.pairs(r["p"])
        if len(p) < 2:
            continue
        mid = p[len(p) // 2]
        for cid, ch, way in CORRIDORS:
            if line_dist(mid[0], mid[1], way) < REACH:
                out.append((ch, r))
                break
    return out


def cluster(pl, ch, road, side, x0, z0, tx, tz, nx, nz, w, anchor_key, corner):
    """One cluster at the anchor point; `corner`: a junction is near."""
    face = (nx, nz)   # the way from the street to the prop = the normal's side
    half = w * 0.5
    r = h01(*anchor_key, "kind")

    def put(kind, lateral, colour=""):
        at = pl.pavement(kind, x0, z0, tx, tz, nx, nz, half, lateral, pl.frontage if kind == "cafe" else None)
        if at is None:
            return None
        pl.add(kind, at[0], at[1], face, colour)
        return at

    if ch == "avenue":
        if corner:
            kind = "stall" if r < 0.45 else "kiosk"
            if put(kind, 0.0) is None:
                put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
            put("planter", 6.0, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", -6.0, pick(FLOWERS, *anchor_key, "p2"))
        elif r < 0.5:
            put("planter", -1.5, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", 1.5, pick(FLOWERS, *anchor_key, "p2"))
        elif r < 0.8:
            put("bollards", 0.0)
        else:
            put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
    elif ch == "cafe":
        if r < 0.15 and corner:
            put("stall", 0.0)
        elif r < 0.25:
            put("column", 0.0, pick(POSTERS, *anchor_key, "c"))
        else:
            n = 2 + int(h01(*anchor_key, "n") * 2)
            first = -3.5 * (n - 1) * 0.5
            sets = [put("cafe", first + 3.5 * k, pick(PARASOLS, *anchor_key, "cafe", k)) for k in range(n)]
            if any(sets):   # G9: the planters only flank a terrace that stands against a shopfront
                put("planter", first - 4.0, pick(FLOWERS, *anchor_key, "pa"))
                put("planter", first + 3.5 * (n - 1) + 4.0, pick(FLOWERS, *anchor_key, "pb"))
    else:   # river: the boulevard side only (the buildings/areas side has no free pavement)
        if r < 0.3:
            put("cart", 0.0, pick(AWNINGS, *anchor_key, "a"))
        elif r < 0.6:
            put("cafe", -2.0, pick(PARASOLS, *anchor_key, "k1"))
            put("cafe", 2.0, pick(PARASOLS, *anchor_key, "k2"))
        else:
            put("planter", -1.5, pick(FLOWERS, *anchor_key, "p1"))
            put("planter", 1.5, pick(FLOWERS, *anchor_key, "p2"))


def stop_kits(pl, roads):
    """A stop post (and for a tram stop a ticket machine) beside every map shelter on a corridor, inside
    the shelter's own cleared disc's reach (so no new obstruction on a platform)."""
    data = pl.data
    sh = data.get("shelters", [])
    plat = [P.pairs(p["p"]) for p in data.get("platforms", [])]
    segs = []
    for ch, r in roads:
        p = P.pairs(r["p"])
        segs.extend(zip(p, p[1:]))
    n = 0
    for i in range(0, len(sh) - 2, 3):
        x, z = sh[i], sh[i + 1]
        best = None
        for a, b in segs:
            d = P.seg_dist(x, z, a, b)
            if d < STOP_REACH and (best is None or d < best[0]):
                best = (d, a, b)
        if best is None or pl.excluded(x, z):
            continue
        _, a, b = best
        ln = math.hypot(b[0] - a[0], b[1] - a[1]) or 1.0
        tx, tz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
        # the way from the road to the shelter = the prop's face-away direction
        u = max(0.0, min(1.0, ((x - a[0]) * tx + (z - a[1]) * tz) / ln))
        qx, qz = a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u
        dx, dz = x - qx, z - qz
        dl = math.hypot(dx, dz) or 1.0
        face = (dx / dl, dz / dl)
        tram = any(P.point_in_poly(x, z, poly) or min(P.seg_dist(x, z, p, q) for p, q in zip(poly, poly[1:] + poly[:1])) < 3.0 for poly in plat)
        for kind, sign in (("post", 2.3), ("ticket", -2.3)):
            if kind == "ticket" and not tram:
                continue
            px, pz = x + tx * sign, z + tz * sign
            if pl.excluded(px, pz) or len(pl.items) >= MAX_ITEMS:
                continue
            if pl.solids.blocked(px, pz, RADIUS[kind], skip=("shelter", "platform", "island")) is not None:
                continue
            pl.add(kind, px, pz, face)
            n += 1
    return n


def bake(data):
    pl = Placer(data)
    roads = corridor_roads(data)
    for ch, r in roads:
        p = P.pairs(r["p"])
        side_key = (r.get("name", ""), r["k"])
        walked = {1: h01(*side_key, p[0][0], p[0][1], 1.0) * 70.0, -1: h01(*side_key, p[0][0], p[0][1], -1.0) * 70.0}
        total = sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(p, p[1:]))
        run = 0.0
        for a, b in zip(p, p[1:]):
            ln = math.hypot(b[0] - a[0], b[1] - a[1])
            if ln < 1.0:
                continue
            tx, tz = (b[0] - a[0]) / ln, (b[1] - a[1]) / ln
            for side in (1, -1):
                nx, nz = -tz * side, tx * side
                pos = walked[side]
                while pos < run + ln:
                    if pos >= run + 4.0:
                        x0, z0 = a[0] + tx * (pos - run), a[1] + tz * (pos - run)
                        to_end = min(pos, total - pos)
                        corner = 15.0 <= to_end <= 40.0 or (total < 80.0 and to_end < 40.0)
                        key = (round(x0, 0), round(z0, 0), side)
                        cluster(pl, ch, r, side, x0, z0, tx, tz, nx, nz, r["w"], key, corner)
                    pos += 70.0 + h01(round(a[0]), round(a[1]), round(pos), side) * 40.0
                walked[side] = pos
            run += ln
    stops = stop_kits(pl, roads)
    items = sorted(pl.items, key=lambda i: (i[1], i[2], i[0]))
    return items, stops


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    out = OUT
    for a in argv:
        if a.startswith("--out="):
            out = a[6:]
        else:
            path = a
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    items, stops = bake(data)
    counts = {}
    for it in items:
        counts[it[0]] = counts.get(it[0], 0) + 1
    doc = {"_about": "Street details along the main line (tools/bake_street_details.py, docs/design/street-details.md): "
                     "[kind, x, z, yaw, colour]; yaw turns +z away from the street. Derived from game/map/centrum.json.",
           "src": src_hash(data), "kinds": KINDS, "items": items}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, separators=(",", ":"))
        f.write("\n")
    print("street details: %d items (%s), %d stop kit pieces -> %s" % (len(items), ", ".join("%s %d" % kv for kv in sorted(counts.items())), stops, out))


if __name__ == "__main__":
    main(sys.argv[1:])
