extends RefCounted
## The land past the map's edge (railway lane, 2026-11-01): the city stopped at its outline over the
## sky's colour, so from Warszawa Wschodnia the yard ran into blue and Dworzec Gdański's north edge
## ended in a band of bare ground. One mesh rings the whole outline instead: the ground goes on (the
## river where the edge cuts the river), a tree line stands a few dozen metres out, low blocks of a
## city beyond stand further back, and the railway and the main roads run on past the edge; all of
## it fades into the sky's colour (`edge_haze`, time_of_day.gd) as it goes out, so the world has no
## visible end. One mesh, one material, no shadows: one draw call wherever the edge is in view.
##
## Built in map_builder.setup_streamed (both city paths) from the index's outline, rails and roads;
## heights come from the ground at the nearest point of the outline (terrain_height), so the ring
## meets the drawn ground a few centimetres under it.

## How far out the ring reaches (m) and where the haze is total.
const REACH := 700.0
const HAZE_FROM := 10.0
const HAZE_TO := 520.0
## Grid lines past the outline (m out), and the spacing along it.
const OUT_STEPS: Array[float] = [6.0, 16.0, 30.0, 50.0, 80.0, 120.0, 170.0, 240.0, 330.0, 440.0, 560.0, 700.0]
const ALONG := 25.0
## Under the drawn ground at the outline (m), so the city's own ground (its last row reaches a
## little past the edge) always wins.
const SINK := 0.06

## sRGB, as the city's vertex colours: the bare ground at the edge, the scrub and grass beyond.
const EDGE_GROUND := Color("#bdb6a3")
const FAR_GROUND := Color("#8e9a70")
const RIVER := Color("#699999")
const TREE := Color("#4d6a3e")
const TREE_DARK := Color("#3f5734")
const BLOCKS: Array[Color] = [Color("#b9b2a5"), Color("#aba69c"), Color("#c3b9a4"), Color("#a1a5a6"), Color("#b5a796")]
const BLOCK_ROOF := Color("#86827c")
const BALLAST := Color("#857d72")
const RAIL := Color("#4a4744")
const ASPHALT := Color("#6a6c6f")

var _mb
## One SurfaceTool per CHUNK x CHUNK square (by a triangle's centre): only the pieces in view are
## drawn, so the city's middle costs nothing and an edge in view one or two draw calls.
const CHUNK := 1024.0
var _tools := {}
var _st: SurfaceTool
var _tris := 0
## 1 while a block's walls are laid (windows in the shader), else 0.
var _wall := 0.0
var _node_cache := {}
## Corridors kept free of trees and blocks: [a, b, half width].
var _corridors: Array = []


## The ring for this builder's map: a node of a few meshes (null when the map has no bounds).
static func build(mb) -> Node3D:
	var e = (load("res://scripts/map_edge.gd") as GDScript).new()
	return e._build(mb)


func _build(mb) -> Node3D:
	_mb = mb
	if mb.bounds.size == Vector2.ZERO:
		return null
	var t0 := Time.get_ticks_msec()
	_extensions()
	_ground()
	_trees_and_blocks()
	var root := Node3D.new()
	root.name = "MapEdge"
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/map_edge.gdshader")
	var keys := _tools.keys()
	keys.sort()
	for k: Vector2i in keys:
		var mi := MeshInstance3D.new()
		mi.name = "Edge_%d_%d" % [k.x, k.y]
		mi.mesh = (_tools[k] as SurfaceTool).commit()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.material_override = mat
		root.add_child(mi)
	print("map edge: %d pieces, %d triangles, %d ms" % [keys.size(), _tris, Time.get_ticks_msec() - t0])
	return root


# --- the outline ---------------------------------------------------------------

## An outside part as the region it removes: its sides on the bounds pushed out, so a point on the
## bounds' line over it counts as off the map.
func _notch(o: Rect2) -> Rect2:
	var b: Rect2 = _mb.bounds
	var r := o
	if absf(r.position.x - b.position.x) < 0.05:
		r.position.x -= 1.0
		r.size.x += 1.0
	if absf(r.position.y - b.position.y) < 0.05:
		r.position.y -= 1.0
		r.size.y += 1.0
	if absf(r.end.x - b.end.x) < 0.05:
		r.size.x += 1.0
	if absf(r.end.y - b.end.y) < 0.05:
		r.size.y += 1.0
	return r.grow(-0.01)


## The point of the map nearest to p (p itself on the map).
func _nearest(p: Vector2) -> Vector2:
	var b: Rect2 = _mb.bounds
	var q := Vector2(clampf(p.x, b.position.x, b.end.x), clampf(p.y, b.position.y, b.end.y))
	for o: Rect2 in _mb.outside:
		var n := _notch(o)
		if not n.has_point(q):
			continue
		var best := q
		var best_d := INF
		for c: Vector2 in [Vector2(o.position.x, q.y), Vector2(o.end.x, q.y), Vector2(q.x, o.position.y), Vector2(q.x, o.end.y)]:
			if n.has_point(c) or not b.grow(0.01).has_point(c):
				continue
			var d := p.distance_squared_to(c)
			if d < best_d:
				best_d = d
				best = c
		q = best
	return q


## A grid node's [height, metres out, wet]: the ground and water at the nearest outline point.
func _node(p: Vector2) -> Array:
	var key := Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))
	if _node_cache.has(key):
		return _node_cache[key]
	var q := _nearest(p)
	var b: Rect2 = _mb.bounds
	var inner := q + (b.get_center() - q).normalized() * 4.0
	var wet: bool = _mb.shore_distance(q.x, q.y) > 0.0 or _mb.shore_distance(inner.x, inner.y) > 0.0
	var v := [float(_mb.terrain_height(q.x, q.y)) - SINK, p.distance_to(q), wet]
	_node_cache[key] = v
	return v


func _haze(d: float) -> float:
	return smoothstep(HAZE_FROM, HAZE_TO, d)


## One vertex: colour (sRGB), haze share in UV.x, the normal given.
func _vertex(v: Vector3, col: Color, haze: float, n: Vector3) -> void:
	_st.set_color(col)
	_st.set_uv(Vector2(haze, _wall))
	_st.set_normal(n)
	_st.add_vertex(v)


## A triangle facing `out` (Godot's front faces are clockwise as seen from the front).
func _tri(a: Vector3, b: Vector3, c: Vector3, cols: Array, hazes: Array, out: Vector3) -> void:
	var n := (c - a).cross(b - a)
	if n.length_squared() < 1e-10:
		return
	var m := (a + b + c) / 3.0
	var key := Vector2i(floori(m.x / CHUNK), floori(m.z / CHUNK))
	_st = _tools.get(key)
	if _st == null:
		_st = SurfaceTool.new()
		_st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[key] = _st
	_tris += 1
	n = n.normalized()
	if n.dot(out) < 0.0:
		_vertex(a, cols[0], hazes[0], -n)
		_vertex(c, cols[2], hazes[2], -n)
		_vertex(b, cols[1], hazes[1], -n)
	else:
		_vertex(a, cols[0], hazes[0], n)
		_vertex(b, cols[1], hazes[1], n)
		_vertex(c, cols[2], hazes[2], n)


# --- the ground ----------------------------------------------------------------

## Grid lines along one axis: the outline's own coordinates, spaced at most ALONG between them,
## and OUT_STEPS past each end.
func _lines(lo: float, hi: float, keys: Array) -> PackedFloat32Array:
	var k := [lo, hi]
	for key: float in keys:
		if key > lo + 0.5 and key < hi - 0.5:
			k.append(key)
	k.sort()
	var out := PackedFloat32Array()
	for s in range(OUT_STEPS.size() - 1, -1, -1):
		out.append(lo - OUT_STEPS[s])
	for i in k.size():
		if i > 0:
			var a: float = k[i - 1]
			var c: float = k[i]
			if c - a < 0.5:
				continue
			var n := maxi(1, ceili((c - a) / ALONG))
			for j in range(1, n):
				out.append(a + (c - a) * j / n)
		out.append(k[i])
	for s in OUT_STEPS:
		out.append(hi + s)
	return out


func _ground() -> void:
	var b: Rect2 = _mb.bounds
	var kx := []
	var kz := []
	for o: Rect2 in _mb.outside:
		kx.append_array([o.position.x, o.end.x])
		kz.append_array([o.position.y, o.end.y])
	var xs := _lines(b.position.x, b.end.x, kx)
	var zs := _lines(b.position.y, b.end.y, kz)
	for j in zs.size() - 1:
		for i in xs.size() - 1:
			var c := Vector2((xs[i] + xs[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5)
			if _mb.in_map(c):
				continue
			var p := [Vector2(xs[i], zs[j]), Vector2(xs[i + 1], zs[j]), Vector2(xs[i + 1], zs[j + 1]), Vector2(xs[i], zs[j + 1])]
			var v := []
			var cols := []
			var hz := []
			for q: Vector2 in p:
				var nd := _node(q)
				v.append(Vector3(q.x, nd[0], q.y))
				cols.append(_ground_colour(q, nd[1], nd[2]))
				hz.append(_haze(nd[1]))
			_tri(v[0], v[1], v[2], [cols[0], cols[1], cols[2]], [hz[0], hz[1], hz[2]], Vector3.UP)
			_tri(v[0], v[2], v[3], [cols[0], cols[2], cols[3]], [hz[0], hz[2], hz[3]], Vector3.UP)


## The ground's colour d metres out: the edge's bare ground, then patches of scrub and grass.
func _ground_colour(p: Vector2, d: float, wet: bool) -> Color:
	if wet:
		return RIVER
	var patch := 0.5 + 0.5 * sin(p.x * 0.013 + sin(p.y * 0.011) * 2.0) * cos(p.y * 0.017 - p.x * 0.004)
	var far := FAR_GROUND.lerp(EDGE_GROUND, 0.35 * patch)
	return EDGE_GROUND.lerp(far, smoothstep(4.0, 40.0, d))


# --- what runs on past the edge -------------------------------------------------

## The rails and the main roads that end at the outline, run on outwards along their last piece.
func _extensions() -> void:
	var idx: Dictionary = _mb.index_data if not _mb.index_data.is_empty() else _mb.data
	for r: Dictionary in idx.get("rails", []):
		if int(r.get("dk", -1)) >= 0:
			continue
		for e in _ends(r["p"]):
			_corridors.append([e[0], e[0] + e[1] * 320.0, 6.0])
			_run(e[0], e[1], 320.0, 3.4, BALLAST, 0.02)
			var side := Vector2(-e[1].y, e[1].x)
			for s in [-0.72, 0.72]:
				_run(e[0] + side * s, e[1], 320.0, 0.16, RAIL, 0.05)
	for r: Dictionary in idx.get("roads", []):
		if r.get("bridge", false) or r.has("hide") or int(r.get("dk", -1)) >= 0:
			continue
		var w := float(r.get("w", 0.0))
		if w < 7.0:
			continue
		for e in _ends(r["p"]):
			_corridors.append([e[0], e[0] + e[1] * 240.0, w * 0.5 + 4.0])
			_run(e[0], e[1], 240.0, w, ASPHALT, 0.0)


## A polyline's ends at the outline, heading out: [end, direction].
func _ends(flat: Array) -> Array:
	var out := []
	var n := flat.size() / 2
	if n < 2:
		return out
	for first in [true, false]:
		var e := Vector2(flat[0], flat[1]) if first else Vector2(flat[n * 2 - 2], flat[n * 2 - 1])
		var k := 1 if first else n - 2
		var prev := Vector2(flat[k * 2], flat[k * 2 + 1])
		var dir := (e - prev).normalized()
		if dir == Vector2.ZERO or _mb.in_map(e, -10.0) or not _mb.in_map(e - dir * 25.0, -2.0):
			continue
		if _mb.in_map(e + dir * 30.0, 0.0):
			continue
		out.append([e, dir])
	return out


## A flat strip w wide from p along dir for len metres, in 20 m pieces, lift metres over the ring.
func _run(p: Vector2, dir: Vector2, length: float, w: float, col: Color, lift: float) -> void:
	var side := Vector2(-dir.y, dir.x) * w * 0.5
	var steps := ceili(length / 20.0)
	for s in steps:
		var a := p + dir * (length * s / steps)
		var c := p + dir * (length * (s + 1) / steps)
		var na := _node(a)
		var nc := _node(c)
		var ya: float = na[0] + SINK + lift
		var yc: float = nc[0] + SINK + lift
		var ha := _haze(na[1])
		var hc := _haze(nc[1])
		var v0 := Vector3(a.x - side.x, ya, a.y - side.y)
		var v1 := Vector3(a.x + side.x, ya, a.y + side.y)
		var v2 := Vector3(c.x + side.x, yc, c.y + side.y)
		var v3 := Vector3(c.x - side.x, yc, c.y - side.y)
		_tri(v0, v1, v2, [col, col, col], [ha, ha, hc], Vector3.UP)
		_tri(v0, v2, v3, [col, col, col], [ha, hc, hc], Vector3.UP)


func _in_corridor(p: Vector2, pad: float) -> bool:
	for c in _corridors:
		var q := Geometry2D.get_closest_point_to_segment(p, c[0], c[1])
		if p.distance_to(q) < float(c[2]) + pad:
			return true
	return false


# --- the tree line and the blocks beyond -----------------------------------------

func _trees_and_blocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 87031
	var ring: PackedVector2Array = _mb.map_outline(0.0)
	for k in ring.size():
		var a := ring[k]
		var c := ring[(k + 1) % ring.size()]
		var along := c - a
		var length := along.length()
		if length < 1.0:
			continue
		var d := along / length
		var out := Vector2(-d.y, d.x)
		if _mb.in_map(a + d * length * 0.5 + out * 3.0):
			out = -out
		# The tree line: a crown every ~5 m, 10-70 m out, densest near the edge.
		var t := -60.0
		while t < length + 60.0:
			t += rng.randf_range(3.0, 7.0)
			var off := 10.0 + 60.0 * pow(rng.randf(), 2.2)
			_tree(a + d * t + out * off, rng)
		# Blocks of the city beyond in three loose rows, 90-400 m out.
		for row: Vector2 in [Vector2(90.0, 150.0), Vector2(175.0, 260.0), Vector2(290.0, 400.0)]:
			t = -row.y
			while t < length + row.y:
				t += rng.randf_range(30.0, 52.0)
				_block(a + d * t + out * rng.randf_range(row.x, row.y), d, rng)


func _tree(p: Vector2, rng: RandomNumberGenerator) -> void:
	if _mb.in_map(p, 4.0) or _in_corridor(p, 3.0):
		return
	var nd := _node(p)
	if nd[2]:
		return
	var y: float = nd[0] + SINK
	var r := rng.randf_range(3.0, 5.4)
	var h := r * rng.randf_range(1.5, 2.1)
	var col := TREE.lerp(TREE_DARK, rng.randf())
	var top := col.lightened(0.12)
	var hz := _haze(nd[1])
	var rot := rng.randf() * TAU
	var low := []
	var mid := []
	for s in 5:
		var u := Vector2.from_angle(rot + TAU * s / 5.0)
		low.append(Vector3(p.x + u.x * r * 0.55, y + h * 0.18, p.y + u.y * r * 0.55))
		mid.append(Vector3(p.x + u.x * r, y + h * 0.45, p.y + u.y * r))
	var apex := Vector3(p.x, y + h, p.y)
	var centre := Vector3(p.x, y + h * 0.45, p.y)
	for s in 5:
		var s2 := (s + 1) % 5
		var o1: Vector3 = ((low[s] + low[s2] + mid[s] + mid[s2]) * 0.25 - centre)
		_tri(low[s], low[s2], mid[s2], [col, col, col], [hz, hz, hz], o1)
		_tri(low[s], mid[s2], mid[s], [col, col, col], [hz, hz, hz], o1)
		var o2: Vector3 = ((mid[s] + mid[s2] + apex) / 3.0 - centre)
		_tri(mid[s], mid[s2], apex, [top, top, top], [hz, hz, hz], o2)


func _block(p: Vector2, d: Vector2, rng: RandomNumberGenerator) -> void:
	if _mb.in_map(p, 30.0) or _in_corridor(p, 30.0):
		return
	var nd := _node(p)
	if nd[2]:
		return
	var y: float = nd[0] + SINK
	var hx := rng.randf_range(10.0, 24.0)
	var hz_ := rng.randf_range(7.0, 15.0)
	var h := rng.randf_range(8.0, 30.0) if rng.randf() < 0.85 else rng.randf_range(35.0, 60.0)
	var ax := d * hx
	var az := Vector2(-d.y, d.x) * hz_
	var foot := [p - ax - az, p + ax - az, p + ax + az, p - ax + az]
	var wall: Color = BLOCKS[rng.randi() % BLOCKS.size()]
	var hz := _haze(nd[1])
	for s in 4:
		var f0: Vector2 = foot[s]
		var f1: Vector2 = foot[(s + 1) % 4]
		var b0 := Vector3(f0.x, y, f0.y)
		var b1 := Vector3(f1.x, y, f1.y)
		var t0 := Vector3(f0.x, y + h, f0.y)
		var t1 := Vector3(f1.x, y + h, f1.y)
		var o := (b0 + b1) * 0.5 - Vector3(p.x, y, p.y)
		_wall = 1.0
		_tri(b0, b1, t1, [wall, wall, wall], [hz, hz, hz], o)
		_tri(b0, t1, t0, [wall, wall, wall], [hz, hz, hz], o)
		_wall = 0.0
	var r := []
	for f: Vector2 in foot:
		r.append(Vector3(f.x, y + h, f.y))
	_tri(r[0], r[1], r[2], [BLOCK_ROOF, BLOCK_ROOF, BLOCK_ROOF], [hz, hz, hz], Vector3.UP)
	_tri(r[0], r[2], r[3], [BLOCK_ROOF, BLOCK_ROOF, BLOCK_ROOF], [hz, hz, hz], Vector3.UP)
