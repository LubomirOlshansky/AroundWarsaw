extends SceneTree
## RF4's roof shapes (scripts/osm_roofs.gd, docs/design/roofs.md): a plain rectangle gets a
## gable (two slopes, two vertical ends), a square a hip, a trapezoid a hip; a concave, big,
## tall, narrow or flat-kind footprint stays flat; every slope faces up, the ridge is the rise,
## the eave is 0, and the slopes and ends together cover the footprint exactly once.
##   godot --headless --path game --script res://tools/check_osm_roofs.gd

var failed := 0


func _initialize() -> void:
	var rect := PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 8), Vector2(0, 8)])
	var g := OsmRoofs.shape(rect, 9.0, "yes")
	_expect(not g.is_empty(), "rectangle takes a roof")
	_expect((g["gables"] as Array).size() == 2, "rectangle: two gable ends, got %d" % (g["gables"] as Array).size())
	_expect((g["roof"] as Array).size() == 4, "rectangle: two slopes of two triangles, got %d" % (g["roof"] as Array).size())
	_cover(g, rect, "rectangle")
	var square := PackedVector2Array([Vector2(0, 0), Vector2(9, 0), Vector2(9, 9), Vector2(0, 9)])
	var s := OsmRoofs.shape(square, 7.0, "house")
	_expect(not s.is_empty() and (s["gables"] as Array).is_empty(), "square is a hip, no gable ends")
	_cover(s, square, "square")
	var trap := PackedVector2Array([Vector2(0, 0), Vector2(18, 0), Vector2(15, 9), Vector2(3, 9)])
	var t := OsmRoofs.shape(trap, 8.0, "apartments")
	_expect(not t.is_empty(), "trapezoid takes a roof")
	_cover(t, trap, "trapezoid")
	var ell := PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(16, 6), Vector2(6, 6), Vector2(6, 14), Vector2(0, 14)])
	_expect(OsmRoofs.shape(ell, 9.0, "yes").is_empty(), "an L stays flat")
	var big := PackedVector2Array([Vector2(0, 0), Vector2(40, 0), Vector2(40, 20), Vector2(0, 20)])
	_expect(OsmRoofs.shape(big, 9.0, "yes").is_empty(), "a big footprint stays flat")
	_expect(OsmRoofs.shape(rect, 30.0, "yes").is_empty(), "a tall one stays flat")
	_expect(OsmRoofs.shape(rect, 2.5, "yes").is_empty(), "a low one stays flat")
	_expect(OsmRoofs.shape(rect, 9.0, "office").is_empty(), "an office stays flat")
	var thin := PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 3), Vector2(0, 3)])
	_expect(OsmRoofs.shape(thin, 9.0, "yes").is_empty(), "a passage stays flat")
	var low := OsmRoofs.shape(rect, 4.0, "yes")
	_expect(not low.is_empty() and float(low["rise"]) <= 4.0 - OsmRoofs.MIN_EAVE + 0.001, "the eave keeps its height")
	if failed == 0:
		print("check_osm_roofs: OK")
	quit(0 if failed == 0 else 1)


## The slopes and ends cover the footprint once (their plan areas add up), the slopes face up
## and the ridge is `rise` high.
func _cover(shape: Dictionary, poly: PackedVector2Array, what: String) -> void:
	var rise := float(shape["rise"])
	var top := 0.0
	var plan := 0.0
	for tri: Array in shape["roof"]:
		var n := ((tri[1] - tri[0]) as Vector3).cross((tri[2] - tri[0]) as Vector3)
		if n.length() > 0.0001:
			n = n.normalized()
			if n.y < 0.0:
				n = -n
			_expect(n.y > 0.3, what + ": a slope faces up")
		for k in 3:
			var v: Vector3 = tri[k]
			top = maxf(top, v.y)
			_expect(v.y > -0.001, what + ": nothing under the eave")
		plan += absf(Vector2((tri[1] - tri[0]).x, (tri[1] - tri[0]).z).cross(Vector2((tri[2] - tri[0]).x, (tri[2] - tri[0]).z))) * 0.5
	_expect(absf(top - rise) < 0.001, what + ": the ridge is the rise")
	var area := absf(OsmRoofs._area(poly))
	_expect(absf(plan - area) < area * 0.01, what + ": slopes cover the footprint (%.1f of %.1f)" % [plan, area])


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_osm_roofs: FAIL: ", what)
