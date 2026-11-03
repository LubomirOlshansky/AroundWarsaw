"""Courtyards: the open courts inside mapped building outlines, read from the GUGiK LoD2 roofs.

Usage (from the repository root, after the LoD2 bake or tools/map_pack.py fetch):
    python3 -I tools/bake_courts.py            write game/data/courts.json
    python3 -I tools/bake_courts.py --check    exit 1 when game/data/courts.json is not what
                                               the current game/map files give

F (2026-11-03): "some kamienica from the top have the hole in the center, I want it where it
has one". The LoD2 blocks already show their courts (each GUGiK model is roofed only where the
building stands), but a hand-built landmark model (game/scripts/landmarks.gd) lifts the mapped
OpenStreetMap outline, and bake_osm keeps only a multipolygon's outer ring: the Ministry of
Finance, the National Museum and Hotel Bristol came out as one solid roof over their courts.

A court here is a patch of ground with no LoD2 roof over it, closed in on every side by roofs
(a flood fill from round the outline does not reach it), of COURT_MIN m² or more, that lies
INSIDE_SHARE or more inside one mapped outline. Each is traced at CELL m, simplified to
SIMPLIFY m and written once (the outlines of a block find the same court). landmarks.gd cuts
the courts of the sites it lists in COURT_SITES out of their roofs and walls them in.

Writes game/data/courts.json: {"cell": CELL, "courts": [[x0, z0, x1, z1, ...], ...]} in game
metres (+x east, +z south), each ring counter-clockwise on the map (clockwise in x/z).
"""
import array
import json
import math
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
MAP = os.path.join(ROOT, "game", "map")
OUT = os.path.join(ROOT, "game", "data", "courts.json")
CELL = 0.5           # m per raster cell
MARGIN = 4.0         # m of raster round each outline's box (the flood fill starts here)
OUTLINE_MIN = 300.0  # m²: smaller outlines hold no court worth a hole
COURT_MIN = 30.0     # m²: a smaller gap is a light well or a seam between two models
COURT_MAX = 20000.0  # m²: a larger "court" is a square ringed by blocks, not a building's
INSIDE_SHARE = 0.6   # this share of the court's cells inside one outline
UP = 0.3             # a triangle with normal.y over this is a roof (map_builder's flat_ish)
SIMPLIFY = 0.5       # m: Douglas-Peucker tolerance of the traced rings
GRID = 32.0          # m: the triangle index's cell


def load_roofs():
    """The LoD2 roof triangles, 2D, indexed by GRID cells: (tris, cells)."""
    with open(os.path.join(MAP, "lod2.bin"), "rb") as f:
        raw = f.read()
    count = int.from_bytes(raw[:4], "little")
    fl = array.array("f")
    fl.frombytes(raw[4:4 + count * 6 * 4])
    if sys.byteorder != "little":
        fl.byteswap()
    tris = []
    cells = {}
    n0 = count * 3
    for t in range(0, count, 3):
        if fl[n0 + t * 3 + 1] < UP:
            continue
        tri = tuple((fl[(t + k) * 3], fl[(t + k) * 3 + 2]) for k in range(3))
        xs = [p[0] for p in tri]
        zs = [p[1] for p in tri]
        k = len(tris)
        tris.append(tri)
        for i in range(int(math.floor(min(xs) / GRID)), int(math.floor(max(xs) / GRID)) + 1):
            for j in range(int(math.floor(min(zs) / GRID)), int(math.floor(max(zs) / GRID)) + 1):
                cells.setdefault((i, j), []).append(k)
    return tris, cells


def ring_area(pts):
    return 0.5 * sum(pts[i - 1][0] * pts[i][1] - pts[i][0] * pts[i - 1][1] for i in range(len(pts)))


def fill_poly(grid, w, h, poly, x0, z0, value):
    """Scanline fill of poly (world points) into grid (cell centres inside get value)."""
    n = len(poly)
    for r in range(h):
        z = z0 + (r + 0.5) * CELL
        xs = []
        for i in range(n):
            ax, az = poly[i - 1]
            bx, bz = poly[i]
            if (az <= z < bz) or (bz <= z < az):
                xs.append(ax + (z - az) * (bx - ax) / (bz - az))
        xs.sort()
        for a, b in zip(xs[0::2], xs[1::2]):
            c0 = max(0, int(math.ceil((a - x0) / CELL - 0.5)))
            c1 = min(w - 1, int(math.floor((b - x0) / CELL - 0.5)))
            for c in range(c0, c1 + 1):
                grid[r * w + c] = value


def trace(cells_set, w):
    """The outer boundary of a 4-connected set of cells, as corner points (grid units)."""
    edges = {}
    for k in cells_set:
        r, c = divmod(k, w)
        # each cell side that borders a cell outside the set, walked with the set on the left
        if (r - 1) * w + c not in cells_set or r == 0:
            edges.setdefault((c + 1, r), []).append((c, r))
        if (r + 1) * w + c not in cells_set:
            edges.setdefault((c, r + 1), []).append((c + 1, r + 1))
        if c == 0 or r * w + c - 1 not in cells_set:
            edges.setdefault((c, r), []).append((c, r + 1))
        if c == w - 1 or r * w + c + 1 not in cells_set:
            edges.setdefault((c + 1, r + 1), []).append((c + 1, r))
    loops = []
    while edges:
        start = next(iter(edges))
        loop = []
        p = start
        while p in edges:
            loop.append(p)
            outs = edges[p]
            q = outs.pop()
            if not outs:
                del edges[p]
            p = q
            if p == start:
                break
        loops.append(loop)
    return max(loops, key=lambda lp: abs(ring_area(lp)))


def simplify(pts, tol):
    """Douglas-Peucker on a closed ring."""
    if len(pts) < 4:
        return pts
    # split at the two points farthest apart
    a = 0
    b = max(range(len(pts)), key=lambda i: (pts[i][0] - pts[0][0]) ** 2 + (pts[i][1] - pts[0][1]) ** 2)

    def dp(seq):
        if len(seq) < 3:
            return seq
        (ax, az), (bx, bz) = seq[0], seq[-1]
        dx, dz = bx - ax, bz - az
        ln = math.hypot(dx, dz) or 1e-9
        best, at = -1.0, 0
        for i in range(1, len(seq) - 1):
            d = abs((seq[i][0] - ax) * dz - (seq[i][1] - az) * dx) / ln
            if d > best:
                best, at = d, i
        if best <= tol:
            return [seq[0], seq[-1]]
        return dp(seq[:at + 1])[:-1] + dp(seq[at:])

    first = dp(pts[a:b + 1])
    second = dp(pts[b:] + [pts[0]])
    return first[:-1] + second[:-1]


def courts():
    tris, tcells = load_roofs()
    with open(os.path.join(MAP, "centrum.json"), encoding="utf-8") as f:
        data = json.load(f)
    found = []
    seen = set()
    for bld in data["buildings"]:
        if bld.get("br"):
            continue
        p = bld["p"]
        poly = list(zip(p[0::2], p[1::2]))
        if len(poly) < 3 or abs(ring_area(poly)) < OUTLINE_MIN:
            continue
        x0 = min(q[0] for q in poly) - MARGIN
        z0 = min(q[1] for q in poly) - MARGIN
        w = int(math.ceil((max(q[0] for q in poly) + MARGIN - x0) / CELL))
        h = int(math.ceil((max(q[1] for q in poly) + MARGIN - z0) / CELL))
        roof = bytearray(w * h)
        picked = set()
        for i in range(int(math.floor(x0 / GRID)), int(math.floor((x0 + w * CELL) / GRID)) + 1):
            for j in range(int(math.floor(z0 / GRID)), int(math.floor((z0 + h * CELL) / GRID)) + 1):
                picked.update(tcells.get((i, j), ()))
        if not picked:
            continue
        for k in picked:
            fill_poly(roof, w, h, list(tris[k]), x0, z0, 1)
        inside = bytearray(w * h)
        fill_poly(inside, w, h, poly, x0, z0, 1)
        # flood the roofless cells from the window's rim: what it cannot reach is closed in
        seen_cells = bytearray(w * h)
        stack = [r * w + c for r in (0, h - 1) for c in range(w)] + [r * w + c for r in range(h) for c in (0, w - 1)]
        for k in stack:
            seen_cells[k] = 1
        while stack:
            k = stack.pop()
            if roof[k]:
                continue
            r, c = divmod(k, w)
            for q in ((k - w) if r > 0 else -1, (k + w) if r < h - 1 else -1, (k - 1) if c > 0 else -1, (k + 1) if c < w - 1 else -1):
                if q >= 0 and not seen_cells[q]:
                    seen_cells[q] = 1
                    stack.append(q)
        for k0 in range(w * h):
            if seen_cells[k0] or roof[k0]:
                continue
            comp = []
            stack = [k0]
            seen_cells[k0] = 1
            while stack:
                k = stack.pop()
                comp.append(k)
                r, c = divmod(k, w)
                for q in ((k - w) if r > 0 else -1, (k + w) if r < h - 1 else -1, (k - 1) if c > 0 else -1, (k + 1) if c < w - 1 else -1):
                    if q >= 0 and not seen_cells[q] and not roof[q]:
                        seen_cells[q] = 1
                        stack.append(q)
            area = len(comp) * CELL * CELL
            if area < COURT_MIN or area > COURT_MAX:
                continue
            if sum(inside[k] for k in comp) < INSIDE_SHARE * len(comp):
                continue
            ring = [(round(x0 + c * CELL, 1), round(z0 + r * CELL, 1)) for c, r in trace(set(comp), w)]
            ring = simplify(ring, SIMPLIFY)
            if len(ring) < 3:
                continue
            cx = sum(q[0] for q in ring) / len(ring)
            cz = sum(q[1] for q in ring) / len(ring)
            key = (round(cx / 2.0), round(cz / 2.0))
            if key in seen:
                continue
            seen.add(key)
            if ring_area(ring) > 0:
                ring.reverse()
            found.append([v for q in ring for v in q])
    found.sort(key=lambda r: (r[1], r[0]))
    return found


def main(argv):
    if argv not in ([], ["--check"]):
        print(__doc__)
        return 2
    out = {"cell": CELL, "courts": courts()}
    text = json.dumps(out, separators=(",", ":")) + "\n"
    if argv == ["--check"]:
        try:
            with open(OUT, encoding="utf-8") as f:
                same = f.read() == text
        except OSError:
            same = False
        print("courts: OK" if same else "courts: game/data/courts.json is stale (python3 -I tools/bake_courts.py)")
        return 0 if same else 1
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"courts: {len(out['courts'])} courts, {sum(len(r) // 2 for r in out['courts'])} points -> game/data/courts.json")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
