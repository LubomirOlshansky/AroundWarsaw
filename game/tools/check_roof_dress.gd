extends SceneTree
## The roofs lane's geometry (scripts/roof_dress.gd, docs/design/roofs.md RF2-RF3): a flat
## roof gets a parapet on each outer edge and none inside (two roof polygons meeting, a
## T-junction) nor round a plant box's top; a small roof gets none; a tenement's flat roof
## gets party-wall chimneys, a slab's none; every piece stands
## on or over the roof and the budget holds (two triangles a parapet edge).
##   godot --headless --path game --script res://tools/check_roof_dress.gd

var failed := 0
var pos := PackedVector3Array()
var nrm := PackedVector3Array()
var col := PackedColorArray()
var uv := PackedVector2Array()


func _initialize() -> void:
	# A 20 x 12 m block, 15 m tall: four walls, a flat roof in two polygons (split at x = 8,
	# the east one triangulated with a T-junction on the west polygon's edge), a plant box.
	var y := 15.0
	_wall(Vector3(0, 0, 0), Vector3(20, 0, 0), y)
	_wall(Vector3(20, 0, 0), Vector3(20, 0, 12), y)
	_wall(Vector3(20, 0, 12), Vector3(0, 0, 12), y)
	_wall(Vector3(0, 0, 12), Vector3(0, 0, 0), y)
	_flat(Vector3(0, y, 0), Vector3(8, y, 0), Vector3(8, y, 12))
	_flat(Vector3(0, y, 0), Vector3(8, y, 12), Vector3(0, y, 12))
	_flat(Vector3(8, y, 0), Vector3(20, y, 0), Vector3(8, y, 6))
	_flat(Vector3(20, y, 0), Vector3(20, y, 12), Vector3(8, y, 6))
	_flat(Vector3(8, y, 6), Vector3(20, y, 12), Vector3(8, y, 12))
	# The plant box: 2 x 2 m, 1.5 m tall, sides with no window UV.
	var b := [Vector3(10, y, 4), Vector3(12, y, 4), Vector3(12, y, 6), Vector3(10, y, 6)]
	for i in 4:
		var p: Vector3 = b[i]
		var q: Vector3 = b[(i + 1) % 4]
		_add(p, q, q + Vector3.UP * 1.5, Vector3(0, 0, -1), Vector2(-1, -1))
		_add(p, q + Vector3.UP * 1.5, p + Vector3.UP * 1.5, Vector3(0, 0, -1), Vector2(-1, -1))
	var top := Vector3.UP * 1.5
	_flat(b[0] + top, b[1] + top, b[2] + top)
	_flat(b[0] + top, b[2] + top, b[3] + top)

	var before := RoofDress.parapets
	var slab := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 2, false)
	var edges := RoofDress.parapets - before
	_expect(edges == 6, "a 20 x 12 m roof's outer edges, split at x = 8 and the T-junction: 6 parapets, got %d" % edges)
	_expect((slab["pos"] as PackedVector3Array).size() == edges * 6, "two triangles a parapet edge, no chimneys on a slab")
	for p: Vector3 in slab["pos"]:
		_expect(p.y >= y - 0.01 and p.y <= y + RoofDress.PARAPET_H + 0.01, "a parapet stands on its roof")
		_expect(p.x < 0.01 or p.x > 19.99 or p.z < 0.01 or p.z > 11.99, "a parapet stands on the outer edge, not round the box (%s)" % p)
	var chimneys := RoofDress.chimneys
	var tenement := RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 1, false)
	_expect(RoofDress.chimneys > chimneys, "a tenement's flat roof gets party-wall chimneys")
	_expect((tenement["pos"] as PackedVector3Array).size() > (slab["pos"] as PackedVector3Array).size(), "the chimneys are drawn")
	for p: Vector3 in tenement["pos"]:
		_expect(p.y >= y - RoofDress.SINK - 0.01 and p.y <= y + 3.0, "a chimney stands on its roof")
	var old := RoofDress.chimneys
	RoofDress.building(pos, nrm, col, uv, 0, pos.size(), 1, true)
	_expect(RoofDress.chimneys == old, "the Old Town's roofs are old_town_roofs.gd's")

	# A small roof (6 x 6 m) takes none.
	var small_from := pos.size()
	_flat(Vector3(100, 9, 0), Vector3(106, 9, 0), Vector3(106, 9, 6))
	_flat(Vector3(100, 9, 0), Vector3(106, 9, 6), Vector3(100, 9, 6))
	var small := RoofDress.building(pos, nrm, col, uv, small_from, pos.size(), 2, false)
	_expect((small["pos"] as PackedVector3Array).is_empty(), "a 36 m² roof takes no parapet")

	# A steep tenement face (a mansard, 60 degrees): only chimneys, never under it.
	var steep_from := pos.size()
	var rise := tan(deg_to_rad(60.0)) * 4.0
	_slope(Vector3(200, 20, 0), Vector3(212, 20, 0), Vector3(212, 20 + rise, -4), Vector3(200, 20 + rise, -4))
	var steep := RoofDress.building(pos, nrm, col, uv, steep_from, pos.size(), 1, false)
	for p: Vector3 in steep["pos"]:
		_expect(p.y >= 20.0 - RoofDress.SINK - 0.01 and p.y <= 20.0 + rise + 3.0, "a mansard's chimney stands on it")
	if failed == 0:
		print("check_roof_dress: OK")
	quit(failed)


func _add(a: Vector3, b: Vector3, c: Vector3, n: Vector3, u: Vector2) -> void:
	pos.append_array([a, b, c])
	nrm.append_array([n, n, n])
	col.append_array([Color("#b8a58c"), Color("#b8a58c"), Color("#b8a58c")])
	uv.append_array([u, u, u])


func _wall(a: Vector3, b: Vector3, h: float) -> void:
	var n := Vector3((b - a).z, 0, -(b - a).x).normalized()
	_add(a, b, b + Vector3.UP * h, n, Vector2(0, 0))
	_add(a, b + Vector3.UP * h, a + Vector3.UP * h, n, Vector2(0, 0))


func _flat(a: Vector3, b: Vector3, c: Vector3) -> void:
	_add(a, b, c, Vector3.UP, Vector2(-1, -1))


func _slope(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	_add(a, b, c, n, Vector2(-1, -1))
	_add(a, c, d, n, Vector2(-1, -1))


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_roof_dress: FAIL: ", what)
