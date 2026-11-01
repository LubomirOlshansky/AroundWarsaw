extends SceneTree
## The Old Town's roof detail (scripts/old_town_roofs.gd): a dormer and now and then a chimney
## on a big pitched roof triangle, none on a small or a flat one; every piece stays on or above
## the slope, faces outward, and stays small (the budget: no more than 40 vertices a slope).
##   godot --headless --path game --script res://tools/check_old_town_roofs.gd

var failed := 0


func _initialize() -> void:
	# A 12 x 8 m slope rising towards +z (30 degrees), as two triangles.
	var rise := tan(deg_to_rad(30.0))
	var p0 := Vector3(0, 10.0, 0)
	var p1 := Vector3(12, 10.0, 0)
	var p2 := Vector3(12, 10.0 + 8.0 * rise, 8)
	var p3 := Vector3(0, 10.0 + 8.0 * rise, 8)
	var n := (p1 - p0).cross(p2 - p0).normalized()
	if n.y < 0.0:
		n = -n
	var wall := Color("#e1968f")
	var tile := Color("#9c4a35")
	var chimneys := 0
	var slopes := 0
	for s in 40:
		var d := OldTownRoofs.dress(p0, p1, p2, n, wall, tile, fposmod(s * 0.137, 1.0))
		_expect(not d.is_empty(), "a big slope takes a dormer")
		var pos: PackedVector3Array = d["pos"]
		var nrm: PackedVector3Array = d["nrm"]
		_expect(pos.size() % 3 == 0 and pos.size() == nrm.size() and pos.size() == (d["col"] as PackedColorArray).size(), "arrays agree")
		_expect(pos.size() <= 120, "a slope's dress stays small (%d vertices)" % pos.size())
		slopes += 1
		if pos.size() > 48:
			chimneys += 1
		for i in pos.size():
			# On or above the roof plane, bar a chimney's foot (under it, hidden by the slope).
			_expect((pos[i] - p0).dot(n) > -0.7, "nothing sinks under the roof: %s" % pos[i])
		for t in range(0, pos.size(), 3):
			var face := (pos[t + 1] - pos[t]).cross(pos[t + 2] - pos[t]).normalized()
			_expect(face.dot(nrm[t]) > 0.99, "winding matches the normal")
	_expect(chimneys > 0 and chimneys < slopes, "some slopes, not all, get a chimney (%d of %d)" % [chimneys, slopes])
	# A small triangle, a thin one and a flat one take none.
	_expect(OldTownRoofs.dress(p0, p0 + Vector3(2, 0, 0), p0 + Vector3(0, 1, 2), n, wall, tile, 0.3).is_empty(), "small: none")
	_expect(OldTownRoofs.dress(p0, p1, p0 + Vector3(6, 0.01, 0.4), n, wall, tile, 0.3).is_empty(), "thin: none")
	_expect(OldTownRoofs.dress(p0, p1, p2, Vector3.UP, wall, tile, 0.3).is_empty(), "flat: none")
	# Stepped gables: a 9 m front facing +z on a wall top at y = 12.
	var ga := Vector3(0, 12, 0)
	var gb := Vector3(9, 12, 0)
	var gn := Vector3(0, 0, 1)
	for sd in [0.1, 0.6]:
		var g := OldTownRoofs.gable(ga, gb, gn, wall, sd)
		_expect(not g.is_empty(), "a 9 m front takes a gable")
		var gp: PackedVector3Array = g["pos"]
		var gm: PackedVector3Array = g["nrm"]
		_expect(gp.size() % 3 == 0 and gp.size() == gm.size() and gp.size() <= 300, "gable arrays agree, stay small (%d vertices)" % gp.size())
		var top := 0.0
		for i in gp.size():
			top = maxf(top, gp[i].y - 12.0)
			_expect(gp[i].y >= 11.99 and gp[i].x >= -0.01 and gp[i].x <= 9.01, "gable stays on its wall: %s" % gp[i])
			_expect(gp[i].z > -0.5 and gp[i].z < 0.2, "gable thin and at the wall: %s" % gp[i])
		_expect(top > 2.5 and top < 5.0, "gable rises 2.5 to 5 m (%.1f)" % top)
		for t in range(0, gp.size(), 3):
			var gf := (gp[t + 1] - gp[t]).cross(gp[t + 2] - gp[t]).normalized()
			_expect(gf.dot(gm[t]) > 0.99, "gable winding matches the normal")
	_expect(OldTownRoofs.gable(ga, ga + Vector3(3, 0, 0), gn, wall, 0.3).is_empty(), "a 3 m front takes none")
	# Through the builder: a 20 m east-side wall facing the square takes gables in the dress arrays.
	var mb = load("res://scripts/map_builder.gd").new()
	var wp := PackedVector3Array([Vector3(-760, 0, -1780), Vector3(-760, 0, -1760), Vector3(-760, 14, -1760),
			Vector3(-760, 0, -1780), Vector3(-760, 14, -1760), Vector3(-760, 14, -1780)])
	var wn := PackedVector3Array()
	var wc := PackedColorArray()
	var wu := PackedVector2Array()
	for i in 6:
		wn.append(Vector3(-1, 0, 0))
		wc.append(Color.WHITE)
		wu.append(Vector2.ZERO)
	mb.data = {"buildings": [{"p": [-766, -1782, -754, -1782, -754, -1758, -766, -1758], "c": "", "kind": "apartments",
			"h": 14, "mh": 0, "rc": "", "name": ""}]}
	var built: Array = mb._tenement_facades(wp, wn, wc, wu, PackedByteArray([0, 0]))
	_expect((built[2]["pos"] as PackedVector3Array).size() >= 3 * 3 * 20, "the builder adds the square's gables")
	mb.free()
	if failed == 0:
		print("check_old_town_roofs: OK")
	quit(failed)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_old_town_roofs: FAIL: ", what)
