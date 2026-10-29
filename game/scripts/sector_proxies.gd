extends RefCounted
## Loop 3c: one low-detail mesh per sector (docs/DEMO.md 2.4), shown where the sector is not
## in full detail: while it loads, and where a far view would reach past the loaded ones.
## One mesh and one material each (vertex colours, no shadows, no colliders), from the global
## index only, so both city paths make the same ones (tools/bake_city.gd saves them in
## map/proxies.scn): the ground as a 32 m grid coloured by what covers it (water, green,
## plaza), the main roads as flat strips, the buildings and landmarks as a skyline of boxes
## from the helicopter's roof grid (8 m, merged along each row), and the trees as blobs per
## 24 m. Under 15k triangles and 0.3 MB a sector. The streamer hides a sector's proxy once the
## sector is in; visibility ranges (fade Disabled: an alpha fade would make it transparent,
## which the Mobile renderer pays for) only drop it past the camera's farthest view.

const MapBuilder := preload("res://scripts/map_builder.gd")
const CELL := 32.0
const SKY := 8.0
const BLOB := 24.0
const MAX_TRIANGLES := 15000
const MAIN_ROADS := ["motorway", "trunk", "primary", "secondary", "tertiary", "motorway_link", "trunk_link",
		"primary_link", "secondary_link", "tertiary_link"]
const ROOF := Color("#857a70")
const WALL := Color("#cfc4b2")
const CANOPY := Color("#6f9a3c")
const ROAD := Color("#4f535a")
## Landmarks' skyline colours by landmarks.gd site key.
const LANDMARK := {"palace": Color("#d8c49c"), "tarasy": Color("#8fb4cb"), "rotunda": Color("#9cc4d4"),
		"varso": Color("#5f7f9f"), "stadium": Color("#c9473b"), "centralna": Color("#a9adb0"),
		"poniatowski": Color("#b9b09a")}
## Past this many metres from the camera a proxy is dropped (beyond the farthest view).
const RANGE_END := 2400.0


static func build_all(map, keys: Array[Vector2i]) -> Node3D:
	var root := Node3D.new()
	root.name = "Proxies"
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.roughness = 1.0
	var ctx := _context(map)
	for key in keys:
		var mi := MeshInstance3D.new()
		mi.name = "p_%d_%d" % [key.x, key.y]
		mi.mesh = build(map, key, ctx)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = RANGE_END
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		root.add_child(mi)
	return root


## What every sector's proxy reads, sorted once: the areas (kind, outline, box), the main
## roads' segments, the scanned trees.
static func _context(map) -> Dictionary:
	var data: Dictionary = map.index_data
	var areas := []
	for a in data.get("areas", []):
		var poly := PackedVector2Array()
		var flat: Array = a["p"]
		for i in range(0, flat.size() - 1, 2):
			poly.append(Vector2(flat[i], flat[i + 1]))
		if poly.size() >= 3:
			areas.append([String(a["k"]), poly, MapBuilder._poly_box(poly)])
	var roads := []
	for r in data.get("roads", []):
		if not String(r["k"]) in MAIN_ROADS or int(r.get("dk", -1)) >= 0:
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 3, 2):
			roads.append([Vector2(flat[i], flat[i + 1]), Vector2(flat[i + 2], flat[i + 3]), float(r["w"])])
	return {"areas": areas, "roads": roads, "trees": data.get("trees3d", [])}


static func build(map, key: Vector2i, ctx: Dictionary) -> ArrayMesh:
	var rect := Rect2(Vector2(key) * MapBuilder.SECTOR, Vector2(MapBuilder.SECTOR, MapBuilder.SECTOR)).intersection(map.bounds)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := _ground(st, map, rect, ctx)
	tris += _roads(st, map, rect, ctx)
	tris += _trees(st, map, rect, ctx)
	var sky := SKY
	var sky_tris := _skyline(null, map, rect, sky)
	while tris + sky_tris > MAX_TRIANGLES and sky < 32.0:
		sky *= 2.0
		sky_tris = _skyline(null, map, rect, sky)
	_skyline(st, map, rect, sky)
	st.index()
	return st.commit(null, Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	for v in [a, b, c, a, c, d]:
		st.set_color(col)
		st.set_normal(n)
		st.add_vertex(v)


## A quad wound to face `n` (Godot's front faces are clockwise seen from the front).
static func _face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		_quad(st, a, d, c, b, n, col)
	else:
		_quad(st, a, b, c, d, n, col)


static func _ground(st: SurfaceTool, map, rect: Rect2, ctx: Dictionary) -> int:
	var near := []
	for a: Array in ctx["areas"]:
		if (a[2] as Rect2).intersects(rect):
			near.append(a)
	var tris := 0
	var z := rect.position.y
	while z < rect.end.y - 0.01:
		var z1 := minf(z + CELL, rect.end.y)
		var x := rect.position.x
		while x < rect.end.x - 0.01:
			var x1 := minf(x + CELL, rect.end.x)
			var mid := Vector2((x + x1) * 0.5, (z + z1) * 0.5)
			var col: Color = MapBuilder.COL["ground"]
			for pass_kind in ["plaza", "green", "water"]:
				for a: Array in near:
					var k: String = a[0]
					var group := "plaza" if k == "plaza" else ("water" if k == "water" else "green")
					if group == pass_kind and (a[2] as Rect2).has_point(mid) and Geometry2D.is_point_in_polygon(mid, a[1]):
						col = MapBuilder.COL.get(k, col)
			var y := 0.0
			_face(st, Vector3(x, map.terrain_height(x, z) + y, z), Vector3(x1, map.terrain_height(x1, z) + y, z),
					Vector3(x1, map.terrain_height(x1, z1) + y, z1), Vector3(x, map.terrain_height(x, z1) + y, z1), Vector3.UP, col)
			tris += 2
			x = x1
		z = z1
	return tris


static func _roads(st: SurfaceTool, map, rect: Rect2, ctx: Dictionary) -> int:
	var tris := 0
	for r: Array in ctx["roads"]:
		var a: Vector2 = r[0]
		var b: Vector2 = r[1]
		var mid := (a + b) * 0.5
		if not rect.has_point(mid) or a.distance_to(b) < 0.5:
			continue
		var side := (b - a).normalized().orthogonal() * float(r[2]) * 0.5
		var ya: float = map.terrain_height(a.x, a.y) + 0.35
		var yb: float = map.terrain_height(b.x, b.y) + 0.35
		_face(st, Vector3(a.x + side.x, ya, a.y + side.y), Vector3(b.x + side.x, yb, b.y + side.y),
				Vector3(b.x - side.x, yb, b.y - side.y), Vector3(a.x - side.x, ya, a.y - side.y), Vector3.UP, ROAD)
		tris += 2
	return tris


static func _trees(st: SurfaceTool, map, rect: Rect2, ctx: Dictionary) -> int:
	var cells := {}
	var real: Array = ctx["trees"]
	for i in range(0, real.size() - 5, 6):
		var p := Vector2(float(real[i]), float(real[i + 1]))
		if not rect.has_point(p):
			continue
		var c := Vector2i(floori(p.x / BLOB), floori(p.y / BLOB))
		var acc: Array = cells.get(c, [Vector2.ZERO, 0, 0.0, 0.0, 0.0])
		acc[0] = (acc[0] as Vector2) + p
		acc[1] = int(acc[1]) + 1
		acc[2] = maxf(float(acc[2]), float(real[i + 2]))   # top
		acc[3] = float(acc[3]) + float(real[i + 3])        # crown radius
		acc[4] = float(acc[4]) + minf(float(real[i + 4]), float(real[i + 2]) - 1.5)  # crown base
		cells[c] = acc
	for c in cells:
		var acc: Array = cells[c]
		var n := float(acc[1])
		var p: Vector2 = acc[0] / n
		var g: float = map.terrain_height(p.x, p.y)
		var base := g + float(acc[4]) / n
		var top := g + float(acc[2])
		var r := clampf(float(acc[3]) / n * (1.0 + 0.15 * sqrt(n)), 2.5, BLOB * 0.6)
		var centre := Vector3(p.x, (base + top) * 0.5, p.y)
		var h := maxf((top - base) * 0.5, 1.5)
		var ring := [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
		for k in 4:
			var e0: Vector3 = centre + ring[k]
			var e1: Vector3 = centre + ring[(k + 1) % 4]
			for tip in [centre + Vector3(0, h, 0), centre - Vector3(0, h, 0)]:
				var n3: Vector3 = ((e0 + e1 + tip) / 3.0 - centre).normalized()
				var col := CANOPY if tip.y > centre.y else CANOPY.darkened(0.2)
				if (e1 - e0).cross(tip - e0).dot(n3) > 0.0:
					for v in [e0, tip, e1]:
						st.set_color(col)
						st.set_normal(n3)
						st.add_vertex(v)
				else:
					for v in [e0, e1, tip]:
						st.set_color(col)
						st.set_normal(n3)
						st.add_vertex(v)
	return cells.size() * 8


## The buildings as boxes over cells of `size` metres (the roof grid's highest point in each),
## merged along each row where the top (to a metre) and the landmark agree. With `st` null it
## only counts the triangles.
static func _skyline(st, map, rect: Rect2, size: float) -> int:
	var n := int(size / map.ROOF_CELL)
	var tris := 0
	var z := rect.position.y
	while z < rect.end.y - 0.01:
		var run_top := -INF
		var run_id := 0
		var run_x0 := 0.0
		var x := rect.position.x
		while x < rect.end.x + size - 0.01:
			var top := -INF
			var id := 0
			if x < rect.end.x - 0.01:
				for dz in n:
					for dx in n:
						var h: float = map.roof_height(x + (dx + 0.5) * map.ROOF_CELL, z + (dz + 0.5) * map.ROOF_CELL)
						if h > top:
							top = h
						var lid: int = map.landmark_at(x + (dx + 0.5) * map.ROOF_CELL, z + (dz + 0.5) * map.ROOF_CELL) + 1
						if lid > 0:
							id = lid
				top = roundf(top) if top > MapBuilder.NO_ROOF + 1.0 else -INF
			if top != run_top or id != run_id:
				if run_top > -INF:
					tris += 10
					if st != null:
						_box(st, map, Rect2(run_x0, z, x - run_x0, minf(size, rect.end.y - z)), run_top, run_id)
				run_top = top
				run_id = id
				run_x0 = x
			x += size
		z += size
	return tris


static func _box(st: SurfaceTool, map, r: Rect2, top: float, id: int) -> void:
	var c := r.get_center()
	var g: float = map.terrain_height(c.x, c.y) - 1.0
	var wall := WALL
	var roof := ROOF
	if id > 0 and id <= map.landmark_info.size():
		wall = LANDMARK.get(String(map.landmark_info[id - 1]["key"]), WALL)
		roof = wall.darkened(0.15)
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	_face(st, Vector3(x0, top, z0), Vector3(x1, top, z0), Vector3(x1, top, z1), Vector3(x0, top, z1), Vector3.UP, roof)
	_face(st, Vector3(x0, g, z0), Vector3(x1, g, z0), Vector3(x1, top, z0), Vector3(x0, top, z0), Vector3.FORWARD, wall)
	_face(st, Vector3(x0, g, z1), Vector3(x1, g, z1), Vector3(x1, top, z1), Vector3(x0, top, z1), Vector3.BACK, wall.darkened(0.08))
	_face(st, Vector3(x0, g, z0), Vector3(x0, g, z1), Vector3(x0, top, z1), Vector3(x0, top, z0), Vector3.LEFT, wall.darkened(0.04))
	_face(st, Vector3(x1, g, z0), Vector3(x1, g, z1), Vector3(x1, top, z1), Vector3(x1, top, z0), Vector3.RIGHT, wall.darkened(0.12))
