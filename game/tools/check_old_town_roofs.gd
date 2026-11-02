extends SceneTree
## The Old Town's roof detail (scripts/old_town_roofs.gd): a dormer and now and then a chimney
## on a big pitched roof triangle, none on a small or a flat one; every piece stays on or above
## the slope, faces outward, and stays small (the budget: no more than 40 vertices a slope);
## Mariensztat counts as a historic district (map_builder MARIENSZTAT).
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
	var bare := 0
	var sizes := {}
	for s in 120:
		var d := OldTownRoofs.dress(p0, p1, p2, n, wall, tile, fposmod(s * 0.137, 1.0))
		if d.is_empty():
			bare += 1  # G7: some slopes carry nothing
			continue
		sizes[(d["pos"] as PackedVector3Array).size()] = true
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
	# G7: the dress varies: some slopes bare, most dressed, and many different shapes and sizes.
	_expect(bare > 3 and bare < 40, "a few slopes stay bare (%d of 120)" % bare)
	_expect(sizes.size() >= 4, "slopes carry different pieces (%d distinct vertex counts)" % sizes.size())
	var mb0 = load("res://scripts/map_builder.gd").new()
	var tones := {}
	for h in 400:
		tones[mb0._tile_colour(h * 37 + 5).to_html(false)] = true
	_expect(tones.size() >= 40, "roofs take many tones (%d)" % tones.size())
	mb0.free()
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
	# Plac Zamkowy's gables: the three kinds (stepped, pediment, curved) by seed, each solid,
	# on its wall, wound outward, rising a believable height; a 3 m front takes none.
	var kinds := {}
	for sd in [0.01, 0.2, 0.4, 0.6, 0.8, 0.95]:
		var pg := OldTownRoofs.plac_gable(ga, gb, gn, wall, sd)
		_expect(not pg.is_empty(), "plac: a 9 m front takes a gable (seed %.2f)" % sd)
		var pp: PackedVector3Array = pg["pos"]
		var pn: PackedVector3Array = pg["nrm"]
		_expect(pp.size() % 3 == 0 and pp.size() == pn.size() and pp.size() <= 400, "plac gable arrays agree (%d vertices)" % pp.size())
		var ptop := 0.0
		for i in pp.size():
			ptop = maxf(ptop, pp[i].y - 12.0)
			_expect(pp[i].y >= 11.99 and pp[i].x >= -0.01 and pp[i].x <= 9.01, "plac gable stays on its wall: %s" % pp[i])
			_expect(pp[i].z > -0.5 and pp[i].z < 0.2, "plac gable thin and at the wall: %s" % pp[i])
		_expect(ptop > 2.0 and ptop < 5.0, "plac gable rises 2 to 5 m (%.1f)" % ptop)
		kinds[int(fposmod(sd * 17.0, 1.0) * 3.0)] = true
		for t in range(0, pp.size(), 3):
			var pf := (pp[t + 1] - pp[t]).cross(pp[t + 2] - pp[t]).normalized()
			_expect(pf.dot(pn[t]) > 0.99, "plac gable winding matches the normal")
	_expect(kinds.size() == 3, "the test seeds cover all three plac gable kinds (%d)" % kinds.size())
	_expect(OldTownRoofs.plac_gable(ga, ga + Vector3(3, 0, 0), gn, wall, 0.3).is_empty(), "plac: a 3 m front takes none")
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
	# Mariensztat (MARIENSZTAT) is a historic district too: Rynek Mariensztacki and its houses in,
	# St Anne's up the escarpment and the Bednarska school beyond the estate out, and a
	# house's 12 x 8 m slope there takes its tiles and a dormer.
	_expect(mb._historic(Vector2(-481.9, -1365.6), 0.0), "Rynek Mariensztacki is historic")
	_expect(mb._historic(Vector2(-394.7, -1327.3), 0.0), "Mariensztat 11A is historic")
	_expect(not mb._historic(Vector2(-655.0, -1350.0), 0.0), "St Anne's is not Mariensztat")
	_expect(not mb._historic(Vector2(-367.0, -1212.0), 0.0), "the music school on Bednarska is not")
	_expect(Geometry2D.triangulate_polygon(PackedVector2Array(mb.MARIENSZTAT)).size() > 0, "Mariensztat's outline is a simple polygon")
	var mx := -486.0
	var mz := -1335.0
	var sp := PackedVector3Array([Vector3(mx, 10.0, mz), Vector3(mx + 12.0, 10.0, mz), Vector3(mx + 12.0, 10.0 + 8.0 * rise, mz + 8.0)])
	var sn := (sp[1] - sp[0]).cross(sp[2] - sp[0]).normalized()
	if sn.y < 0.0:
		sp = PackedVector3Array([sp[0], sp[2], sp[1]])
		sn = -sn
	var sc := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE])
	mb.data = {"buildings": [{"p": [mx - 1, mz - 1, mx + 13, mz - 1, mx + 13, mz + 9, mx - 1, mz + 9], "c": "",
			"kind": "apartments", "h": 11, "mh": 0, "rc": "", "name": ""}]}
	var marien: Array = mb._tenement_facades(sp, PackedVector3Array([sn, sn, sn]), sc,
			PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]), PackedByteArray([0]))
	_expect(not (marien[0] as PackedColorArray)[0].is_equal_approx(Color.WHITE), "a Mariensztat roof takes its tiles")
	_expect((marien[2]["pos"] as PackedVector3Array).size() > 0, "a Mariensztat roof takes a dormer")
	mb.free()
	if failed == 0:
		print("check_old_town_roofs: OK")
	quit(failed)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failed += 1
		if failed <= 10:
			print("check_old_town_roofs: FAIL: ", what)
