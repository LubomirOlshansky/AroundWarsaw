"""Loop 3b-2: the river's banks and its sand, from OpenStreetMap.

Usage: imported by tools/bake_osm.py (`bake_banks.bake(...)` after the shore runs); it has no
command line of its own and prints its counts with the bake's.

- **Which banks are built** (`classify_shore`): bake_roads' `shore` runs (the water's edge a
  car must not cross) are split into built stretches (a quay or a boulevard: the granite edge
  stays, as loop 10a drew it everywhere) and natural ones (a beach, reeds, a grassy bank: the
  builder draws a wet band and a foam line on the waterline instead, no stone; the car is held
  back there by the same invisible collider on the line). Built, from OpenStreetMap, every
  2 m along the edge: a footway or cycleway running along the edge within PROMENADE m (the
  Bulwary), a road within ROAD_NEAR m of it, paving or a plaza on the land side, a mapped
  wall or embankment along it within WALL_NEAR m, or a bridge deck within ABUTMENT m (the
  abutments). A sand, beach, shoal, wetland, scrub or wood polygon on the land side beats a
  promenade (a path along a beach). Short flips (under MIN_RUN m) are smoothed away. A natural
  run is written with `n`: 1 a sandy bank, 2 a green one (grass, park, reeds, scrub, wood).
- **Sand on land** (`sand` in centrum.json): natural=beach / sand / shoal / shingle polygons,
  drawn as sand under the water (any part mapped past the edge is covered by the water);
  `g`: 1 marks gravel (surface=gravel: the rubble round the bridge piers);
  `f`: 1 a gap fill (`sand_gaps`: the thin strips OpenStreetMap leaves between sand polygons).
- **Sandbars** (`sandbars`): the part of those polygons that lies on the river, rasterised at
  PX m, opened by SLIVER m (nothing narrower than 2 * SLIVER survives), traced, smoothed and
  simplified, pieces under MIN_BAR m2 dropped: smooth outlines, no slivers. The builder draws
  them over the water with a darker wet rim and a foam line; they stay water for the car's
  water test (water.bin), so nothing changes for the tow, the helicopter or check_water.
"""
import math

from bake_roads import Grid, Polys, pairs, point_in_poly, ring_area, seg_dist, simplify

SAND_KINDS = {"beach", "sand", "shoal", "shingle"}
GRAVEL_SURFACES = {"gravel", "pebblestone", "fine_gravel", "rock"}
# Land-side cover that makes a bank natural even with a path along it, and green banks.
WILD_NATURAL = {"wetland", "scrub", "wood", "grassland", "heath"}
WILD_LANDUSE = {"meadow", "forest"}
RIVER_AREA = 20000.0   # water bodies at least this big are the river (bake_water.py's rule)

STEP = 2.0          # classify the edge every this many metres
LAND = 3.0          # the land-side sample point, this far in from the edge
PROMENADE = 9.0     # a footway or cycleway along the edge within this is a boulevard
ALONG = 0.75        # "along": |cos| of the angle between the path and the edge at least this
ROAD_NEAR = 10.0    # a road's edge this close to the water's edge: a quay road
WALL_NEAR = 4.0     # a mapped wall or embankment along the edge within this
ABUTMENT = 20.0     # a bridge deck within this: its abutment is built
MIN_RUN = 14.0      # a built or natural stretch shorter than this takes its neighbours' kind

PX = 0.5            # sandbar raster, metres per cell
SLIVER = 1.0        # opening radius: parts narrower than twice this go
MIN_BAR = 6.0       # sandbars smaller than this (m2) go
SMOOTH = 3          # Chaikin passes over the traced outline
GAP_CLOSE = 3.0     # gaps between sand polygons up to twice this wide are filled with sand...
GAP_MIN_SAND = 400.0  # ...in a group of sand polygons this big (m2) or more
SIMPLIFY = 0.12     # then Douglas-Peucker tolerance (m)


def _area(poly):
    return abs(ring_area(poly))


def _box(poly, pad=0.0):
    xs = [p[0] for p in poly]
    zs = [p[1] for p in poly]
    return (min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad)


def _overlap(a, b):
    return a[0] <= b[2] and b[0] <= a[2] and a[1] <= b[3] and b[1] <= a[3]


def collect(els, nodes, ways, project, in_bbox, clip_polygon, rect, stitch):
    """The sand polygons (natural=beach/sand/shoal/shingle), those of them that are gravel
    (surface=gravel / pebblestone: the rubble round Most Poniatowskiego's piers) and the wild land cover (wetland, scrub, wood, meadow ...) on the map, clipped to
    it: three lists of point lists."""
    sand, gravel, wild = [], [], []

    def kind_of(t):
        nat = t.get("natural")
        if nat in SAND_KINDS:
            # Shingle reads as the beach it lies in (Poniatówka's tidal shingle is pale on the
            # photo); only a mapped gravel surface (the piers' rubble) is drawn grey.
            return "gravel" if t.get("surface") in GRAVEL_SURFACES else "sand"
        if nat in WILD_NATURAL or t.get("landuse") in WILD_LANDUSE:
            return "wild"
        return None

    def add(kind, ids):
        if not any(i in nodes and in_bbox(*nodes[i]) for i in ids):
            return
        pts = [project(*nodes[i]) for i in ids[:-1] if i in nodes]
        pts = clip_polygon(pts, rect)
        if len(pts) >= 3 and _area(pts) >= 1.0:
            if kind == "wild":
                wild.append(pts)
            else:
                sand.append(pts)
                if kind == "gravel":
                    gravel.append(pts)

    for w in ways.values():
        ids = w.get("nodes", [])
        if len(ids) < 4 or ids[0] != ids[-1]:
            continue
        kind = kind_of(w.get("tags", {}))
        if kind:
            add(kind, ids)
    for r in (e for e in els if e["type"] == "relation"):
        t = r.get("tags", {})
        kind = kind_of(t)
        if t.get("type") != "multipolygon" or not kind:
            continue
        outer = [ways[m["ref"]]["nodes"] for m in r.get("members", [])
                 if m["type"] == "way" and m.get("role") == "outer" and m["ref"] in ways]
        for ring in stitch(outer):
            add(kind, ring)
    return sand, gravel, wild


# -- which banks are built ----------------------------------------------------------------

def classify_shore(shore, water, paths, roads, plazas, paving, walls, embankments, sand, wild, green, on_deck):
    """Split the shore runs ({"p": flat}) into built runs and natural ones ({"p", "n"})."""
    along = Grid(16.0)   # (a, b, reach, kind): paths, walls, embankments that count when along
    for p in paths:
        if p["k"] in ("foot", "cycle"):
            for a, b in zip(pairs(p["p"]), pairs(p["p"])[1:]):
                along.add((a, b, PROMENADE, "path"), *_seg_box(a, b, PROMENADE))
    for line in walls + embankments:
        for a, b in zip(line, line[1:]):
            along.add((a, b, WALL_NEAR, "wall"), *_seg_box(a, b, WALL_NEAR))
    near_road = Grid(16.0)
    for r in roads:
        half = float(r["w"]) * 0.5
        for a, b in zip(pairs(r["p"]), pairs(r["p"])[1:]):
            near_road.add((a, b, half), *_seg_box(a, b, half + ROAD_NEAR))
    paved = Polys(plazas + paving)
    natural = Polys(sand + wild)
    grassy = Polys(wild + green)

    out = []
    counts = {"built": 0.0, "natural": 0.0}
    for run in shore:
        pts = _resample(pairs(run["p"]), STEP)
        if len(pts) < 2:
            continue
        labels = []
        greens = []
        for k, (x, z) in enumerate(pts):
            a = pts[max(0, k - 1)]
            b = pts[min(len(pts) - 1, k + 1)]
            tx, tz = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(tx, tz) or 1.0
            tx, tz = tx / ln, tz / ln
            nx, nz = -tz, tx
            # The land side: the one off the water.
            if water.hit(x + nx * 1.5, z + nz * 1.5) >= 0 and water.hit(x - nx * 1.5, z - nz * 1.5) < 0:
                nx, nz = -nx, -nz
            lx, lz = x + nx * LAND, z + nz * LAND
            wildside = natural.hit(lx, lz) >= 0
            built = on_deck(x, z, ABUTMENT) >= 0 or paved.hit(lx, lz) >= 0
            if not built:
                for a2, b2, half in near_road.at(x, z):
                    if seg_dist(x, z, a2, b2) - half <= ROAD_NEAR:
                        built = True
                        break
            if not built:
                for a2, b2, reach, kind in along.at(x, z):
                    if kind == "path" and wildside:
                        continue
                    d = (b2[0] - a2[0], b2[1] - a2[1])
                    dl = math.hypot(*d)
                    if dl < 0.01 or abs((d[0] * tx + d[1] * tz) / dl) < ALONG:
                        continue
                    if seg_dist(x, z, a2, b2) <= reach:
                        built = True
                        break
            labels.append(1 if built else 0)
            greens.append(grassy.hit(lx, lz) >= 0)
        labels = _settle(labels, max(1, int(round(MIN_RUN / STEP))))
        start = 0
        for k in range(1, len(pts) + 1):
            if k < len(pts) and labels[k] == labels[start]:
                continue
            piece = pts[start:k + 1] if k < len(pts) else pts[start:]
            if len(piece) >= 2:
                length = sum(math.dist(p, q) for p, q in zip(piece, piece[1:]))
                item = {"p": _flat(simplify(piece, 0.3))}
                if labels[start] == 0:
                    share = sum(greens[start:k]) / max(1, k - start)
                    item["n"] = 2 if share > 0.5 else 1
                    counts["natural"] += length
                else:
                    counts["built"] += length
                out.append(item)
            start = k
    return out, counts


def _seg_box(a, b, pad):
    return (min(a[0], b[0]) - pad, min(a[1], b[1]) - pad, max(a[0], b[0]) + pad, max(a[1], b[1]) + pad)


def _resample(pts, step):
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        for k in range(1, n + 1):
            out.append((a[0] + (b[0] - a[0]) * k / n, a[1] + (b[1] - a[1]) * k / n))
    return out


def _settle(labels, shortest):
    """Runs of one label shorter than `shortest` samples take the label around them (a
    majority vote first, then the short runs, shortest first)."""
    n = len(labels)
    if n < 3:
        return labels
    half = max(1, shortest // 2)
    voted = []
    for k in range(n):
        window = labels[max(0, k - half):k + half + 1]
        voted.append(1 if sum(window) * 2 > len(window) else 0)
    labels = voted
    changed = True
    while changed:
        changed = False
        runs = []
        s = 0
        for k in range(1, n + 1):
            if k == n or labels[k] != labels[s]:
                runs.append((s, k))
                s = k
        if len(runs) < 2:
            break
        short = [r for r in runs if r[1] - r[0] < shortest]
        if not short:
            break
        s, e = min(short, key=lambda r: r[1] - r[0])
        flip = 1 - labels[s]
        for k in range(s, e):
            labels[k] = flip
        changed = True
    return labels


def _flat(pts):
    out = []
    for x, z in pts:
        out += [round(x, 2), round(z, 2)]
    return out


# -- sandbars ------------------------------------------------------------------------------

def sandbars(sand, river):
    """The sand polygons' parts on the river (a list of rings), opened, traced, smoothed."""
    rivers = [(r, _box(r)) for r in river]
    items = []
    for poly in sand:
        box = _box(poly, 3.0)
        mine = [r for r, rb in rivers if _overlap(box, rb)]
        # Only sand that is (at least partly) on the river.
        if mine and any(point_in_poly(x, z, r) for r in mine for x, z in _resample(poly + poly[:1], 2.0)):
            items.append((poly, box))
    # Clusters of overlapping sand polygons are rasterised together.
    parent = list(range(len(items)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if _overlap(items[i][1], items[j][1]):
                parent[find(i)] = find(j)
    groups = {}
    for i in range(len(items)):
        groups.setdefault(find(i), []).append(items[i][0])
    out = []
    for polys in groups.values():
        box = _box([p for poly in polys for p in poly], 3.0)
        mine = [r for r, rb in rivers if _overlap(box, rb)]
        out += _raster_bars(polys, mine, box)
    return out


def _raster_bars(polys, rivers, box):
    x0, z0 = box[0], box[1]
    w = int(math.ceil((box[2] - box[0]) / PX)) + 1
    h = int(math.ceil((box[3] - box[1]) / PX)) + 1
    sandm = bytearray(w * h)
    for poly in polys:
        _scan(sandm, w, h, x0, z0, poly)
    waterm = bytearray(w * h)
    for r in rivers:
        _scan(waterm, w, h, x0, z0, r)
    mask = bytearray(1 if sandm[k] and waterm[k] else 0 for k in range(w * h))
    # Open: erode by SLIVER, then grow back by SLIVER (inside the original mask).
    inner = _chamfer(mask, w, h)
    core = bytearray(1 if inner[k] > SLIVER else 0 for k in range(w * h))
    outer = _chamfer(bytearray(1 - v for v in core), w, h)
    opened = bytearray(1 if mask[k] and outer[k] <= SLIVER + PX * 0.5 else 0 for k in range(w * h))
    rings = []
    for loop in _trace(opened, w, h):
        pts = [(x0 + i * PX, z0 + j * PX) for i, j in loop]
        if ring_area(pts) <= 0 or _area(pts) < MIN_BAR:
            continue  # holes (negative) and crumbs
        for _ in range(SMOOTH):
            pts = _chaikin(pts)
        pts = simplify(pts + pts[:1], SIMPLIFY)[:-1]
        if len(pts) >= 3 and _area(pts) >= MIN_BAR:
            rings.append(pts)
    return rings


def _scan(buf, w, h, x0, z0, poly):
    """Scanline fill (even-odd) at cell centres."""
    n = len(poly)
    zs = [p[1] for p in poly]
    j0 = max(0, int((min(zs) - z0) / PX))
    j1 = min(h - 1, int((max(zs) - z0) / PX) + 1)
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
            i0 = max(0, int(math.ceil((a - x0) / PX - 0.5)))
            i1 = min(w - 1, int(math.floor((b - x0) / PX - 0.5)))
            for i in range(i0, i1 + 1):
                buf[row + i] = 1


def _chamfer(mask, w, h):
    """Distance (m) from each set cell to the nearest unset one (cells off the grid are unset)."""
    inf = 1e9
    a, b = PX, PX * math.sqrt(2.0)
    d = [inf if mask[k] else 0.0 for k in range(w * h)]
    for j in range(h):
        for i in range(w):
            k = j * w + i
            if d[k] == 0.0:
                continue
            v = d[k]
            v = min(v, d[k - 1] + a if i > 0 else a)
            if j > 0:
                v = min(v, d[k - w] + a, d[k - w - 1] + b if i > 0 else b, d[k - w + 1] + b if i < w - 1 else b)
            else:
                v = min(v, a)
            d[k] = v
    for j in range(h - 1, -1, -1):
        for i in range(w - 1, -1, -1):
            k = j * w + i
            if d[k] == 0.0:
                continue
            v = d[k]
            v = min(v, d[k + 1] + a if i < w - 1 else a)
            if j < h - 1:
                v = min(v, d[k + w] + a, d[k + w + 1] + b if i < w - 1 else b, d[k + w - 1] + b if i > 0 else b)
            else:
                v = min(v, a)
            d[k] = v
    return d


def _trace(mask, w, h):
    """The outlines of the set cells as loops of grid corners (i, j), set cells on the right
    of the walk (+x east, +z south): outer loops have a positive ring_area, holes negative."""
    def cell(i, j):
        return 0 <= i < w and 0 <= j < h and mask[j * w + i]

    out_edges = {}
    for j in range(h):
        for i in range(w):
            if not mask[j * w + i]:
                continue
            if not cell(i, j - 1):
                out_edges.setdefault((i, j), []).append((i + 1, j))
            if not cell(i + 1, j):
                out_edges.setdefault((i + 1, j), []).append((i + 1, j + 1))
            if not cell(i, j + 1):
                out_edges.setdefault((i + 1, j + 1), []).append((i, j + 1))
            if not cell(i - 1, j):
                out_edges.setdefault((i, j + 1), []).append((i, j))
    loops = []
    while out_edges:
        start = next(iter(out_edges))
        loop = [start]
        prev = None
        cur = start
        while True:
            nexts = out_edges.get(cur)
            if not nexts:
                break
            if len(nexts) == 1 or prev is None:
                nxt = nexts.pop(0)
            else:
                # A saddle: turn right (keeps diagonal cells apart).
                din = (cur[0] - prev[0], cur[1] - prev[1])
                right = (-din[1], din[0])
                nxt = next((q for q in nexts if (q[0] - cur[0], q[1] - cur[1]) == right), nexts[0])
                nexts.remove(nxt)
            if not nexts:
                del out_edges[cur]
            prev, cur = cur, nxt
            if cur == start:
                break
            loop.append(cur)
        # Drop the corners on straight runs.
        pts = []
        n = len(loop)
        for k in range(n):
            a, b, c = loop[k - 1], loop[k], loop[(k + 1) % n]
            if (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]) != 0:
                pts.append(b)
        if len(pts) >= 3:
            loops.append(pts)
    return loops


def _chaikin(pts):
    out = []
    n = len(pts)
    for k in range(n):
        a, b = pts[k], pts[(k + 1) % n]
        out.append((a[0] * 0.75 + b[0] * 0.25, a[1] * 0.75 + b[1] * 0.25))
        out.append((a[0] * 0.25 + b[0] * 0.75, a[1] * 0.25 + b[1] * 0.75))
    return out


# -- gaps between sand polygons ------------------------------------------------------------

def sand_gaps(sand, keep_out):
    """Loop 3b-2 (the orchestrator's beach review): OpenStreetMap's sand polygons leave thin
    strips between them (a beach cut round a groyne, a beach and a shingle bank mapped a
    metre or two apart, two beaches split under a bridge). While the beach was bare ground
    nobody saw them; drawn as sand they were straight bands of bare ground on the beach. In a
    group of touching sand polygons of GAP_MIN_SAND m2 or more, the gaps up to 2 * GAP_CLOSE
    wide are filled: the sand's union closed by GAP_CLOSE (grown,
    then shrunk back), less the original sand and anything mapped in the gap (`keep_out`: grass,
    parks, plazas, paving), grown 0.5 m into the sand on both sides so no seam shows. Returns
    rings (drawn as sand)."""
    items = [(poly, _box(poly, GAP_CLOSE + 2.0)) for poly in sand]
    parent = list(range(len(items)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if _overlap(items[i][1], items[j][1]):
                parent[find(i)] = find(j)
    groups = {}
    for i in range(len(items)):
        groups.setdefault(find(i), []).append(items[i][0])
    others = [(q, _box(q)) for q in keep_out]
    out = []
    for polys in groups.values():
        if sum(_area(q) for q in polys) < GAP_MIN_SAND:
            continue  # a playground's sand pits are no beach
        box = _box([p for poly in polys for p in poly], GAP_CLOSE + 2.0)
        x0, z0 = box[0], box[1]
        w = int(math.ceil((box[2] - box[0]) / PX)) + 1
        h = int(math.ceil((box[3] - box[1]) / PX)) + 1
        mask = bytearray(w * h)
        for poly in polys:
            _scan(mask, w, h, x0, z0, poly)
        grown = _chamfer(bytearray(1 - v for v in mask), w, h)
        dilated = bytearray(1 if mask[k] or grown[k] <= GAP_CLOSE else 0 for k in range(w * h))
        inner = _chamfer(dilated, w, h)
        blocked = bytearray(w * h)
        for q, qb in others:
            if _overlap(qb, box):
                _scan(blocked, w, h, x0, z0, q)
        gap = bytearray(1 if inner[k] > GAP_CLOSE and not mask[k] and not blocked[k] else 0 for k in range(w * h))
        if not any(gap):
            continue
        # Grow the fill half a metre (into the sand only), so it overlaps both sides.
        near = _chamfer(bytearray(1 - v for v in gap), w, h)
        fill = bytearray(1 if gap[k] or (mask[k] and near[k] <= 0.5 + PX * 0.5) else 0 for k in range(w * h))
        for loop in _trace(fill, w, h):
            pts = [(x0 + i * PX, z0 + j * PX) for i, j in loop]
            if ring_area(pts) <= 0 or _area(pts) < 1.0:
                continue
            pts = simplify(pts + pts[:1], 0.1)[:-1]
            if len(pts) >= 3:
                out.append(pts)
    return out


# -- the whole step ------------------------------------------------------------------------

def bake(bed, els, nodes, ways, project, in_bbox, clip_polygon, rect, stitch, paths, roads, areas, details):
    """Classify bed.shore in place; return {"sand": [...], "sandbars": [...]} for centrum.json."""
    sand, gravel, wild = collect(els, nodes, ways, project, in_bbox, clip_polygon, rect, stitch)
    water = Polys([pairs(a["p"]) for a in areas if a["k"] == "water"])
    river = [q for q in water.polys if _area(q) >= RIVER_AREA]
    plazas = [pairs(a["p"]) for a in areas if a["k"] == "plaza"]
    green = [pairs(a["p"]) for a in areas if a["k"] in ("park", "grass", "pitch")]
    paving = [pairs(s["p"]) for s in details.get("surfaces", []) if s["k"] == "paving"]
    walls = [pairs(m["p"]) for m in details.get("lines", []) if m["k"] == "wall"]
    embankments = []
    for w in ways.values():
        if w.get("tags", {}).get("man_made") == "embankment":
            ids = w.get("nodes", [])
            if any(i in nodes and in_bbox(*nodes[i]) for i in ids):
                embankments.append([project(*nodes[i]) for i in ids if i in nodes])
    shore, counts = classify_shore(bed.shore, water, paths, roads, plazas, paving, walls, embankments,
                                   sand, wild, green, bed.on_deck)
    bed.shore = shore
    bars = sandbars(sand, river)
    gravels = Polys(gravel)
    gravel_ids = {id(p) for p in gravel}

    def item(poly, is_gravel):
        out = {"p": _flat(poly)}
        if is_gravel:
            out["g"] = 1
        return out

    # A sandbar is gravel when its inner point lies on a gravel polygon.
    bar_items = [item(b, gravels.hit(*_inner(b)) >= 0) for b in bars]
    gaps = sand_gaps(sand, green + plazas + paving)
    # Map north (tools/check_outline.py O2): the fills are traced on a raster, so a fill on the
    # map's edge reached a pixel past it; cut to the map like the sand itself.
    gaps = [c for c in (clip_polygon(g, rect) for g in gaps) if len(c) >= 3]
    print(f"banks: {counts['built'] / 1000:.2f} km built, {counts['natural'] / 1000:.2f} km natural "
          f"({sum(1 for s in shore if s.get('n') == 1)} sandy runs, {sum(1 for s in shore if s.get('n') == 2)} green); "
          f"sand {len(sand)} polygons ({len(gravel)} gravel) + {len(gaps)} gap fills ({sum(_area(g) for g in gaps):.0f} m2); "
          f"sandbars {len(bars)} ({sum(_area(b) for b in bars):.0f} m2, {sum(1 for b in bar_items if b.get('g'))} gravel)")
    # The gap fills go first: the sand and gravel polygons drawn after them keep their edges.
    return {"sand": [{"p": _flat(g), "f": 1} for g in gaps] + [item(p, id(p) in gravel_ids) for p in sand],
            "sandbars": bar_items}


def _inner(poly):
    """A point well inside a ring: the middle of the widest span across its middle row."""
    zs = [p[1] for p in poly]
    z = (min(zs) + max(zs)) * 0.5
    xs = []
    n = len(poly)
    for k in range(n):
        ax, az = poly[k]
        bx, bz = poly[(k + 1) % n]
        if (az > z) != (bz > z):
            xs.append(ax + (z - az) * (bx - ax) / (bz - az))
    xs.sort()
    spans = list(zip(xs[0::2], xs[1::2]))
    if not spans:
        return poly[0]
    a, b = max(spans, key=lambda s: s[1] - s[0])
    return ((a + b) * 0.5, z)
