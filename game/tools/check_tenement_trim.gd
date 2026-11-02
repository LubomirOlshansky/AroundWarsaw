extends SceneTree
## Dobra and Tamka's tenement trim (scripts/tenement_trim.gd): a 20 x 12 m wall 14 m tall gets a
## cornice on its top edge and a string course and (street side only) a shop front on its foot;
## every piece stands outside the wall plane by at most the cornice's depth plus a hair, inside
## the wall's height, and a low wall takes no string course.
##   godot --headless --path game --script res://tools/check_tenement_trim.gd

var failed := 0


func _initialize() -> void:
	var a := Vector3(0, 0, 0)
	var b := Vector3(20, 0, 0)
	var h := 14.0
	var n := Vector3(0, 0, -1)  # the wall (z = 0, x 0..20) faces -z
	var quiet := _trim(a, b, h, n, false)
	var shop := _trim(a, b, h, n, true)
	_expect(quiet.size() > 0, "a tenement wall takes trim")
	_expect(shop.size() > quiet.size(), "the street side takes a shop front on top of it")
	for p: Vector3 in shop:
		_expect(p.z <= 0.001 and p.z >= -TenementTrim.CORNICE_DEPTH - 0.001, "trim stands out of the wall by no more than the cornice (%s)" % p)
		_expect(p.y >= -0.01 and p.y <= h + 0.01, "trim stays within the wall's height (%s)" % p)
		_expect(p.x >= -TenementTrim.CORNICE_DEPTH - 0.001 and p.x <= 20.0 + TenementTrim.CORNICE_DEPTH + 0.001, "trim runs past the ends by its depth at most (%s)" % p)
	var low := _trim(a, b, 6.0, n, false)
	var high_course := 0
	for p: Vector3 in quiet:
		if p.y > 3.5 and p.y < 4.5:
			high_course += 1
	var low_course := 0
	for p: Vector3 in low:
		if p.y > 3.5 and p.y < 4.5:
			low_course += 1
	_expect(high_course > 0, "a 14 m wall has a string course at the first floor")
	_expect(low_course == 0, "a 6 m wall has none")
	# a wall on a slope: the foot is 1.5 m higher at the east end, the course follows it
	var slope := _trim(Vector3(0, 0, 0), Vector3(20, 1.5, 0), h, n, false)
	var follows := false
	for p: Vector3 in slope:
		if p.x > 19.0 and p.y > 5.0 and p.y < 6.0:
			follows = true
	_expect(follows, "a sloped foot carries the string course up with it")
	var tris := shop.size() / 3
	_expect(tris <= 80, "a 20 m wall's trim stays within 80 triangles, got %d" % tris)
	if failed == 0:
		print("check_tenement_trim: OK")
	quit(failed)


## The trim of one wall quad's two triangles (foot a-b, height h), all vertices.
func _trim(a: Vector3, b: Vector3, h: float, n: Vector3, street: bool) -> PackedVector3Array:
	var out := {"pos": [], "nrm": [], "col": []}
	var up := Vector3.UP * h
	TenementTrim.wall(out, a, b, b + up, n, Color("#d6cbb2"), street)
	TenementTrim.wall(out, a, b + up, a + up, n, Color("#d6cbb2"), street)
	return PackedVector3Array(out["pos"])


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_tenement_trim: FAIL: ", what)
