extends RefCounted
## F's ask (2026-10-31, BACKLOG top): the full map drawn as a game map, not a survey sheet. This
## builds its two meshes once, from centrum.json's own lists, in its own original style (a sunny
## poster: a cream city, pastel districts, bright water and greens, bold roads by class with a dark
## casing, the bridges on top):
## - `base(outline)`: the city's land inside the map's outline (one colour);
## - `districts(view)`: each district's polygons in its pastel tint (districts.gd `view()`);
## - `streets(data, outside)`: the greens, plazas, water (with a darker shore), the railways and
##   tunnels dashed, then every road twice (its casing, then its fill), minor classes first and the
##   bridges last. Road vertices carry their sideways offset in UV, in points, so WIDEN (the
##   shader) keeps them a readable width at any zoom: the line, not the street, is to scale.
## All in map metres (+x east, +z south). Indexed; one surface each: one draw call each.
## `prepare` does the heavy part (the triangulation, ~0.5 s on a computer) as plain arrays, so
## hud.gd runs it on a worker thread at start and the first open only makes the meshes.

## The shader of the streets' mesh: a road vertex is moved sideways by its UV (points) × widen
## (metres per point at this zoom, set by full_map.gd).
const WIDEN := """shader_type canvas_item;
uniform float widen = 1.0;
void vertex() {
	VERTEX += UV * widen;
}
"""

const LAND := Color("#f4ead5")
const OFF_MAP := Color("#1f2735")
const EDGE := Color("#fff8e8")
const PARK := Color("#86cc69")
const GRASS := Color("#a9da8a")
const PITCH := Color("#62b955")
const PLAZA := Color("#e9dec8")
const WATER := Color("#3aa0dc")
const SHORE := Color("#2479b5")
const CASING := Color("#3a3346")
const BRIDGE_CASING := Color("#1d1a24")
const RAIL := Color("#7a7088")
const TUNNEL := Color("#b9ad9a")
## The districts' pastels, in districts.json's order (a tint over LAND).
const TINTS := [Color("#f6c7a4"), Color("#f3b9c8"), Color("#d9c8ef"), Color("#f8e4a3"), Color("#c6e3f2"),
		Color("#bfe5c8"), Color("#e9cfa7"), Color("#d4e3b1"), Color("#c9d6f3")]
const TINT_MIX := 0.42

## Road classes: [fill colour, fill width (pt), casing width (pt; 0: none), order].
const CLASSES := {
	"primary": [Color("#ffb53b"), 6.2, 8.4, 5], "primary_link": [Color("#ffb53b"), 3.6, 5.4, 4],
	"secondary": [Color("#ffe07e"), 5.0, 7.0, 4], "secondary_link": [Color("#ffe07e"), 3.2, 5.0, 3],
	"tertiary": [Color("#ffffff"), 3.8, 5.6, 3], "tertiary_link": [Color("#ffffff"), 2.6, 4.2, 2],
	"unclassified": [Color("#ffffff"), 3.0, 4.6, 2],
	"residential": [Color("#fbf7ef"), 2.4, 3.8, 1], "living_street": [Color("#fbf7ef"), 2.0, 3.4, 1],
	"service": [Color("#ece5d6"), 1.2, 0.0, 0],
}


## A growing indexed triangle list.
class Buf:
	var v := PackedVector2Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()

	func add(p: Vector2, col: Color, off := Vector2.ZERO) -> int:
		v.append(p)
		c.append(col)
		uv.append(off)
		return v.size() - 1

	func tri(a: int, b: int, cc: int) -> void:
		idx.append_array([a, b, cc])

	## A filled polygon (its own triangulation).
	func poly(pts: PackedVector2Array, col: Color) -> void:
		if pts.size() < 3:
			return
		var ids := Geometry2D.triangulate_polygon(pts)
		if ids.is_empty():
			return
		var o := v.size()
		for p in pts:
			add(p, col)
		for i in ids:
			idx.append(o + i)

	## A line along pts, `width` points wide, its ends round (when `caps`): the centre in the
	## vertex, the sideways reach in UV (the shader widens it).
	func line(pts: PackedVector2Array, col: Color, width: float, caps := true, closed := false) -> void:
		var n := pts.size()
		if n < 2:
			return
		var hw := width * 0.5
		var first := -1
		var prev_l := -1
		var prev_r := -1
		for i in n:
			var t_in := Vector2.ZERO
			var t_out := Vector2.ZERO
			if i > 0:
				t_in = (pts[i] - pts[i - 1]).normalized()
			elif closed:
				t_in = (pts[0] - pts[n - 1]).normalized()
			if i < n - 1:
				t_out = (pts[i + 1] - pts[i]).normalized()
			elif closed:
				t_out = (pts[0] - pts[i]).normalized()
			if t_in == Vector2.ZERO:
				t_in = t_out
			if t_out == Vector2.ZERO:
				t_out = t_in
			var m := (t_in + t_out).normalized()
			if m == Vector2.ZERO:
				m = t_out
			var nrm := m.orthogonal()
			# The miter, held to twice the half width at sharp bends.
			var k := hw / maxf(absf(nrm.dot(t_out.orthogonal())), 0.5)
			var l := add(pts[i], col, nrm * k)
			var r := add(pts[i], col, -nrm * k)
			if prev_l >= 0:
				tri(prev_l, prev_r, l)
				tri(prev_r, r, l)
			else:
				first = l
			prev_l = l
			prev_r = r
		if closed:
			tri(prev_l, prev_r, first)
			tri(prev_r, first + 1, first)
		elif caps:
			cap(pts[0], (pts[0] - pts[1]).normalized(), hw, col)
			cap(pts[n - 1], (pts[n - 1] - pts[n - 2]).normalized(), hw, col)

	## A half disc of radius hw (points) beyond p, facing `dir`.
	func cap(p: Vector2, dir: Vector2, hw: float, col: Color) -> void:
		var o := add(p, col)
		var side := dir.orthogonal()
		var last := add(p, col, side * hw)
		for s in range(1, 5):
			var a := PI * s / 4.0
			var q := add(p, col, (side * cos(a) + dir * sin(a)) * hw)
			tri(o, last, q)
			last = q

	func mesh() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_COLOR] = c
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = idx
		var out := ArrayMesh.new()
		if not v.is_empty():
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
		return out


static func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


## The land inside the map's outline.
static func base(outline: PackedVector2Array) -> ArrayMesh:
	var b := Buf.new()
	b.poly(outline, LAND)
	return b.mesh()


## Each district's polygons in its tint (districts.gd `view()`, in its order), clipped to the map's
## outline (the districts run on past the map's edge).
static func districts(view: Array[Dictionary], outline := PackedVector2Array()) -> ArrayMesh:
	var b := Buf.new()
	for i in view.size():
		var col: Color = LAND.lerp(TINTS[i % TINTS.size()], TINT_MIX)
		for poly: PackedVector2Array in view[i]["polys"]:
			var parts: Array[PackedVector2Array] = [poly]
			if outline.size() >= 3:
				parts = Geometry2D.intersect_polygons(poly, outline)
			for part in parts:
				b.poly(part, col)
	return b.mesh()


## The tint of district i (for its label).
static func tint(i: int) -> Color:
	return TINTS[i % TINTS.size()]


static func _outside(p: Vector2, outside: Array[Rect2]) -> bool:
	for o in outside:
		if o.has_point(p):
			return true
	return false


## Dashes of `on` metres every `every` metres along pts.
static func _dashes(pts: PackedVector2Array, on: float, every: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var run := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var c := pts[i + 1]
		var ln := a.distance_to(c)
		var t := 0.0
		while t < ln:
			var phase := fmod(run + t, every)
			if phase < on:
				var t1 := minf(t + on - phase, ln)
				out.append(PackedVector2Array([a.lerp(c, t / ln), a.lerp(c, t1 / ln)]))
				t = t1
			else:
				t += every - phase
		run += ln
	return out


## The streets' mesh (see the file's comment). `outside`: the parts of the bounds left off the
## map (map north's L): nothing whose first point lies there. The side streets (residential,
## living streets, service: order < 2) go in `minor`'s own mesh, drawn under it and only close in.
static func streets(data: Dictionary, outside: Array[Rect2] = [], minor: Buf = null) -> ArrayMesh:
	return _streets(data, outside, minor if minor != null else Buf.new()).mesh()


static func _streets(data: Dictionary, outside: Array[Rect2], minor: Buf) -> Buf:
	var b := Buf.new()
	var water: Array[PackedVector2Array] = []
	for pass_k in ["grass", "park", "pitch", "plaza"]:
		var col: Color = {"grass": GRASS, "park": PARK, "pitch": PITCH, "plaza": PLAZA}[pass_k]
		for a in data.get("areas", []):
			if String(a["k"]) != pass_k:
				continue
			var pts := _pts(a["p"])
			if pts.size() >= 3 and not _outside(pts[0], outside):
				b.poly(pts, col)
	for a in data.get("areas", []):
		if String(a["k"]) == "water":
			var pts := _pts(a["p"])
			if pts.size() >= 3:
				water.append(pts)
	# The shore first (a ring 3 pt wide), the water over it: a darker rim on the land's side.
	for pts in water:
		b.line(pts, SHORE, 3.0, false, true)
	for pts in water:
		b.poly(pts, WATER)
	for r in data.get("rails", []):
		var pts := _pts(r["p"])
		if pts.size() >= 2 and not _outside(pts[0], outside):
			for d in _dashes(pts, 10.0, 18.0):
				b.line(d, RAIL, 1.4, false)
	for r in data.get("tunnels", {}).get("roads", []):
		var pts := _pts(r["p"])
		if pts.size() >= 2:
			for d in _dashes(pts, 8.0, 16.0):
				b.line(d, TUNNEL, 2.2, false)
	# The roads: grouped by their class's order, ground roads first, bridges last; within a group
	# every casing, then every fill.
	var groups := {}
	for r in data.get("roads", []):
		var k := String(r["k"])
		if not CLASSES.has(k):
			continue
		var pts := _pts(r["p"])
		if pts.size() < 2 or _outside(pts[0], outside):
			continue
		var bridge := bool(r.get("bridge", false))
		var key: int = int(CLASSES[k][3]) + (10 if bridge else 0)
		if not groups.has(key):
			groups[key] = []
		groups[key].append([pts, k, bridge])
	var keys := groups.keys()
	keys.sort()
	# Ground casings of every class first, so a minor road's fill runs into a major one cleanly.
	for key in keys:
		if key >= 10:
			continue
		var to: Buf = minor if key < 2 else b
		for g: Array in groups[key]:
			var cl: Array = CLASSES[g[1]]
			if float(cl[2]) > 0.0:
				to.line(g[0], CASING, cl[2])
	for key in keys:
		if key >= 10:
			continue
		var to: Buf = minor if key < 2 else b
		for g: Array in groups[key]:
			var cl: Array = CLASSES[g[1]]
			to.line(g[0], cl[0], cl[1])
	for key in keys:
		if key < 10:
			continue
		for g: Array in groups[key]:
			var cl: Array = CLASSES[g[1]]
			b.line(g[0], BRIDGE_CASING, maxf(float(cl[2]), float(cl[1]) + 1.4) + 1.6)
		for g: Array in groups[key]:
			var cl: Array = CLASSES[g[1]]
			b.line(g[0], cl[0], cl[1])
	return b


## Everything the full map needs that takes time, off the main thread (no nodes, no resources but
## the arrays): {"base", "streets", "edge": Buf, "bridges": Dictionary}. `meshes` turns it into
## the meshes on the main thread.
static func prepare(data: Dictionary, outline: PackedVector2Array, outside: Array[Rect2]) -> Dictionary:
	var base_b := Buf.new()
	base_b.poly(outline, LAND)
	var edge_b := Buf.new()
	edge_b.line(outline, EDGE, 3.0, false, true)
	var minor := Buf.new()
	var streets_b := _streets(data, outside, minor)
	return {"base": base_b, "streets": streets_b, "minor": minor, "edge": edge_b, "bridges": bridges(data),
			"outline": outline}


## The meshes of a `prepare` result: {"base", "streets", "edge": ArrayMesh}.
static func meshes(prepared: Dictionary) -> Dictionary:
	return {"base": (prepared["base"] as Buf).mesh(), "streets": (prepared["streets"] as Buf).mesh(),
			"minor": (prepared["minor"] as Buf).mesh(), "edge": (prepared["edge"] as Buf).mesh()}


## The map's edge: a light line round the outline (points wide, in the streets' shader).
static func edge(outline: PackedVector2Array) -> ArrayMesh:
	var b := Buf.new()
	b.line(outline, EDGE, 3.0, false, true)
	return b.mesh()


## Where each named bridge's icon goes: the middle of its points over the water (or of all its
## points): {name: Vector2}. Only roads named "Most ...".
static func bridges(data: Dictionary) -> Dictionary:
	var water: Array[PackedVector2Array] = []
	for a in data.get("areas", []):
		if String(a["k"]) == "water":
			water.append(_pts(a["p"]))
	var sums := {}
	for r in data.get("roads", []):
		var n := String(r.get("name", ""))
		if not bool(r.get("bridge", false)) or not n.begins_with("Most "):
			continue
		var pts := _pts(r["p"])
		for p in pts:
			var wet := false
			for w in water:
				if Geometry2D.is_point_in_polygon(p, w):
					wet = true
					break
			if not sums.has(n):
				sums[n] = [Vector2.ZERO, 0, Vector2.ZERO, 0]
			var s: Array = sums[n]
			s[0] += p
			s[1] += 1
			if wet:
				s[2] += p
				s[3] += 1
	var out := {}
	for n in sums:
		var s: Array = sums[n]
		out[n] = (s[2] / s[3]) if int(s[3]) > 0 else (s[0] / s[1])
	return out
