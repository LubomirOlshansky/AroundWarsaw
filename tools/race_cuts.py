"""Street races R3 (docs/design/street-races.md): the racers' shortcuts ("skróty").

Finds straight cuts between two junctions of the lane graph that save a racer a long way round
by road (across a plaza, a forecourt, a car park, a lawn, a wide pavement) and that a car can
really drive: nothing in a 2.8 m wide corridor (buildings, landmarks, walls, fences, hedges,
platforms, steps, water, pitches, trees, lamps, parked cars, kiosks, shelters, columns, benches,
bins, bike stands, the park and street details and monuments of game/data), on the ground at both ends (no bridge or tunnel), no step in the terrain,
and not running along a road (that would be a wrong-way drive through oncoming cars).
Writes game/data/race_cuts.json: each cut as its two junctions' positions (so a re-bake that
moves node ids keeps them) and the metres it saves. rivals.gd loads it, snaps the ends to the
graph's nodes and gives each rival the share of cuts it knows (ladder.gd `cuts`).

Usage:
    python3 -I tools/race_cuts.py [--map=game/map/centrum.json] [--terrain=game/map/terrain.json]
        [--out=game/data/race_cuts.json] [--svg=build/race_cuts.svg]
Run it again after a centrum.json re-bake (check_race_cuts.gd fails when cuts no longer resolve).
"""
import heapq
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIN_LEN = 22.0       # shorter: a junction curve does it already
MAX_LEN = 160.0      # longer: not a cut any more, a cross-country drive
SAVE_MIN = 30.0      # metres saved, at least
SAVE_RATIO = 1.5     # road distance at least this × the straight line
REACH = 900.0        # Dijkstra radius per junction (m)
HALF = 1.4           # half the corridor (car 1.8 m wide + a margin)
END_FREE = 7.0       # the first/last metres (the junction box) are not checked for small things
ON_ROAD_MAX = 0.3    # share of the cut lying on a road's carriageway
CROSS_MAX = 1        # carriageways crossed on the way (a cut over a whole junction web is not one)
STEP_MAX = 1.2       # terrain off the straight slope (m)
SLOPE_MAX = 0.1
CELL = 40.0
POINTS = {  # list: (stride, radius m)
	"trees3d": (6, 1.3), "lamps": (2, 0.35), "parked": (4, 2.5), "columns": (3, 0.9),
	"shelters": (3, 2.2), "benches": (3, 1.0), "bins": (3, 0.5), "bikes": (3, 1.1),
	"signals": (3, 0.35),
}
DATA_RADIUS = {"fountain": 5.0, "carousel": 5.0, "playground": 6.0, "gazebo": 3.5, "kiosk": 2.5,
	"stall": 2.0, "cafe": 3.0, "plaque": 0.4, "duck": 0.0, "swan": 0.0, "squirrel": 0.0, "peacock": 0.0}
BLOCK_AREAS = {"water", "pitch"}
BLOCK_LINES = {"wall", "fence", "hedge", "platform"}


def arg(name, default):
	for a in sys.argv[1:]:
		if a.startswith("--%s=" % name):
			return a.split("=", 1)[1]
	return default


def ring(flat):
	return [(flat[k], flat[k + 1]) for k in range(0, len(flat) - 1, 2)]


class Grid:
	def __init__(self):
		self.cells = {}

	def add_box(self, x0, z0, x1, z1, item):
		for i in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
			for j in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
				self.cells.setdefault((i, j), []).append(item)

	def near(self, x0, z0, x1, z1):
		seen = set()
		for i in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
			for j in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
				for it in self.cells.get((i, j), ()):
					if id(it) not in seen:
						seen.add(id(it))
						yield it


def inside(p, poly):
	x, z = p
	c = False
	n = len(poly)
	for k in range(n):
		x1, z1 = poly[k]
		x2, z2 = poly[(k + 1) % n]
		if (z1 > z) != (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1) + x1:
			c = not c
	return c


def seg_dist(p, a, b):
	ax, az = a
	bx, bz = b
	dx, dz = bx - ax, bz - az
	ll = dx * dx + dz * dz
	t = 0.0 if ll == 0 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - az) * dz) / ll))
	return math.hypot(p[0] - ax - dx * t, p[1] - az - dz * t)


def seg_seg(a, b, c, d):
	def cross(o, p, q):
		return (p[0] - o[0]) * (q[1] - o[1]) - (p[1] - o[1]) * (q[0] - o[0])
	d1, d2 = cross(c, d, a), cross(c, d, b)
	d3, d4 = cross(a, b, c), cross(a, b, d)
	if ((d1 > 0) != (d2 > 0)) and ((d3 > 0) != (d4 > 0)):
		return 0.0
	return min(seg_dist(a, c, d), seg_dist(b, c, d), seg_dist(c, a, b), seg_dist(d, a, b))


def main():
	data = json.load(open(arg("map", os.path.join(ROOT, "game/map/centrum.json"))))
	terrain_path = arg("terrain", os.path.join(ROOT, "game/map/terrain.json"))
	terrain = json.load(open(terrain_path)) if os.path.exists(terrain_path) else None
	g = data["graph"]
	flat = g["nodes"]
	nodes = [(flat[k], flat[k + 1]) for k in range(0, len(flat) - 1, 2)]
	scc = g["scc"]
	out = [[] for _ in nodes]
	bad = set()  # junctions on a bridge or in a tunnel
	for e in g["edges"]:
		p = e["p"]
		length = sum(math.hypot(p[k + 2] - p[k], p[k + 3] - p[k + 1]) for k in range(0, len(p) - 3, 2))
		if e.get("br", 0) or e.get("tn", -1) >= 0:
			bad.add(e["a"])
			bad.add(e["b"])
		if e.get("tn", -1) >= 0 or e.get("cf", 0):
			continue
		out[e["a"]].append((e["b"], length))

	def height(x, z):
		if terrain is None:
			return 0.0
		fx = (x - terrain["x0"]) / terrain["step"]
		fz = (z - terrain["z0"]) / terrain["step"]
		i = max(0, min(terrain["nx"] - 2, int(fx)))
		j = max(0, min(terrain["nz"] - 2, int(fz)))
		u, v = max(0.0, min(1.0, fx - i)), max(0.0, min(1.0, fz - j))
		h = terrain["h"]
		nx = terrain["nx"]
		a, b = h[j * nx + i], h[j * nx + i + 1]
		c, d = h[(j + 1) * nx + i], h[(j + 1) * nx + i + 1]
		return (a * (1 - u) + b * u) * (1 - v) + (c * (1 - u) + d * u) * v

	polys = Grid()
	for b in data["buildings"] + data["landmarks"]:
		r = ring(b["p"])
		if len(r) >= 3:
			xs, zs = [q[0] for q in r], [q[1] for q in r]
			polys.add_box(min(xs), min(zs), max(xs), max(zs), r)
	for a in data["areas"]:
		if a["k"] in BLOCK_AREAS:
			r = ring(a["p"])
			xs, zs = [q[0] for q in r], [q[1] for q in r]
			polys.add_box(min(xs), min(zs), max(xs), max(zs), r)
	lines = Grid()
	segs = []
	for l in data["lines"]:
		if l["k"] in BLOCK_LINES:
			segs.append(ring(l["p"]))
	for key in ("walls", "steps", "rails", "platforms"):
		for l in data.get(key, []):
			segs.append(ring(l["p"]))
	for r in segs:
		for k in range(len(r) - 1):
			a, b = r[k], r[k + 1]
			lines.add_box(min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]), (a, b))
	points = Grid()
	for key, (stride, rad) in POINTS.items():
		arr = data.get(key, [])
		for k in range(0, len(arr) - 1, stride):
			x, z = arr[k], arr[k + 1]
			points.add_box(x - rad, z - rad, x + rad, z + rad, (x, z, rad))
	# The hand-placed props from game/data (park and street details, monuments): [kind, x, z, ...].
	for name in ("park_details", "street_details", "monuments"):
		path = os.path.join(ROOT, "game/data/%s.json" % name)
		if not os.path.exists(path):
			continue
		for it in json.load(open(path)).get("items", []):
			rad = DATA_RADIUS.get(it[0], 1.5)
			points.add_box(it[1] - rad, it[2] - rad, it[1] + rad, it[2] + rad, (it[1], it[2], rad))
	roads = Grid()
	for r in data["roads"]:
		pr = ring(r["p"])
		w = float(r.get("w", 6.0)) * 0.5
		for k in range(len(pr) - 1):
			a, b = pr[k], pr[k + 1]
			roads.add_box(min(a[0], b[0]) - w, min(a[1], b[1]) - w, max(a[0], b[0]) + w, max(a[1], b[1]) + w, (a, b, w))

	def clear(a, b):
		"""Why the corridor a-b is blocked, or ''."""
		ax, az = a
		bx, bz = b
		L = math.hypot(bx - ax, bz - az)
		ux, uz = (bx - ax) / L, (bz - az) / L
		nx, nz = -uz, ux
		x0, z0 = min(ax, bx) - HALF - 3, min(az, bz) - HALF - 3
		x1, z1 = max(ax, bx) + HALF + 3, max(az, bz) + HALF + 3
		ha, hb = height(ax, az), height(bx, bz)
		if abs(hb - ha) / L > SLOPE_MAX:
			return "slope"
		near_polys = list(polys.near(x0, z0, x1, z1))
		near_lines = list(lines.near(x0, z0, x1, z1))
		near_points = list(points.near(x0, z0, x1, z1))
		near_roads = list(roads.near(x0, z0, x1, z1))
		on_road = 0
		samples = 0
		crossings = 0
		was_on = False
		s = 0.0
		while s <= L:
			cx, cz = ax + ux * s, az + uz * s
			if abs(height(cx, cz) - (ha + (hb - ha) * s / L)) > STEP_MAX:
				return "step"
			for o in (-HALF, 0.0, HALF):
				q = (cx + nx * o, cz + nz * o)
				for poly in near_polys:
					if inside(q, poly):
						return "building"
			if END_FREE <= s <= L - END_FREE:
				samples += 1
				on = False
				for (a2, b2, w) in near_roads:
					if seg_dist((cx, cz), a2, b2) < w - 0.5:
						on = True
						break
				if on:
					on_road += 1
					if not was_on:
						crossings += 1
				was_on = on
			s += 1.0
		if samples and on_road / samples > ON_ROAD_MAX:
			return "road"
		if crossings > CROSS_MAX:
			return "crossings"
		for (c, d) in near_lines:
			if seg_seg(a, b, c, d) < HALF - 0.3:
				return "line"
		for (x, z, rad) in near_points:
			t = (x - ax) * ux + (z - az) * uz
			if t < END_FREE or t > L - END_FREE:
				continue
			if seg_dist((x, z), a, b) < rad + HALF - 0.3:
				return "object"
		return ""

	ngrid = {}
	for i, p in enumerate(nodes):
		ngrid.setdefault((int(math.floor(p[0] / MAX_LEN)), int(math.floor(p[1] / MAX_LEN))), []).append(i)
	pairs = {}
	why = {}
	for a, pa in enumerate(nodes):
		if a in bad or not scc[a] or not out[a]:
			continue
		near = []
		ci, cj = int(math.floor(pa[0] / MAX_LEN)), int(math.floor(pa[1] / MAX_LEN))
		for i in (ci - 1, ci, ci + 1):
			for j in (cj - 1, cj, cj + 1):
				for b in ngrid.get((i, j), ()):
					if b != a and b not in bad and scc[b]:
						L = math.hypot(nodes[b][0] - pa[0], nodes[b][1] - pa[1])
						if MIN_LEN <= L <= MAX_LEN:
							near.append((b, L))
		if not near:
			continue
		dist = {a: 0.0}
		heap = [(0.0, a)]
		while heap:
			d, n = heapq.heappop(heap)
			if d > dist.get(n, math.inf) or d > REACH:
				continue
			for m, w in out[n]:
				nd = d + w
				if nd < dist.get(m, math.inf):
					dist[m] = nd
					heapq.heappush(heap, (nd, m))
		for b, L in near:
			road = dist.get(b, REACH * 1.5)
			save = road - L
			if road >= L * SAVE_RATIO and save >= SAVE_MIN:
				key = (min(a, b), max(a, b))
				pairs[key] = max(pairs.get(key, 0.0), save)
	cuts = []
	for (a, b), save in sorted(pairs.items(), key=lambda kv: -kv[1]):
		w = clear(nodes[a], nodes[b])
		why[w or "ok"] = why.get(w or "ok", 0) + 1
		if not w:
			cuts.append([round(nodes[a][0], 1), round(nodes[a][1], 1), round(nodes[b][0], 1), round(nodes[b][1], 1), round(save)])
	cuts.sort(key=lambda c: (c[0], c[1], c[2], c[3]))
	out_path = arg("out", os.path.join(ROOT, "game/data/race_cuts.json"))
	with open(out_path, "w") as f:
		f.write('{"_note": "Street races R3: racer shortcuts [ax, az, bx, bz, metres saved] between two junctions. Made by tools/race_cuts.py from centrum.json; do not edit by hand, re-run it.",\n"cuts": [\n')
		f.write(",\n".join(json.dumps(c) for c in cuts))
		f.write("\n]}\n")
	print("race_cuts: %d candidate pairs, %d clear -> %s; rejected: %s" % (len(pairs), len(cuts), os.path.relpath(out_path, ROOT),
			", ".join("%s %d" % (k, v) for k, v in sorted(why.items()) if k != "ok")))
	svg = arg("svg", "")
	if svg:
		x0, z0, x1, z1 = data["bounds"]
		with open(svg, "w") as f:
			f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%f %f %f %f" style="background:#111">' % (x0, z0, x1 - x0, z1 - z0))
			for e in g["edges"]:
				p = e["p"]
				f.write('<polyline fill="none" stroke="#555" stroke-width="3" points="%s"/>' % " ".join("%.0f,%.0f" % (p[k], p[k + 1]) for k in range(0, len(p) - 1, 2)))
			for c in cuts:
				f.write('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#ff4fd8" stroke-width="5"/>' % tuple(c[:4]))
			f.write("</svg>")


if __name__ == "__main__":
	main()
