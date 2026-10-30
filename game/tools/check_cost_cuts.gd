extends SceneTree
## 2026-10-30: two cost cuts from the performance lane, on synthetic data, without the city:
##  1. index_pack.gd (the memory loop): every outline `p` of the OUTLINED lists, the FLAT lists
##     and the lane graph's nodes and lanes become PackedFloat32Array with the same numbers
##     (float32: within 0.25 mm at ±3.2 km); other keys and non-arrays are left alone; packing
##     twice changes nothing; a reader that declares `var flat: Array = r["p"]` still gets the
##     numbers;
##  2. traffic.gd's on_screen (the traffic-cost loop): its own projection of a point (and of the
##     point `height` above it) onto the screen agrees with Camera3D.unproject_position for an
##     orthographic camera at several yaws, pitches and zooms, on 2000 points each.
## Prints `check_cost_cuts: OK`, or the problems and their count (exit 1). Under a second.
##   godot --headless --path game --script res://tools/check_cost_cuts.gd

const IndexPack := preload("res://scripts/index_pack.gd")
const Traffic := preload("res://scripts/traffic.gd")

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_check_pack()
	await _check_on_screen()
	if problems.is_empty():
		print("check_cost_cuts: OK")
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_cost_cuts: %d problems" % problems.size())
		quit(1)


func _check_pack() -> void:
	var outline := [-3199.123, 0.25, 1530.5, -2.75, 0.0, 3199.999]
	var index := {
		"roads": [{"p": outline.duplicate(), "k": "primary", "w": 12.0}, {"k": "no outline"}],
		"areas": [{"p": [1.0, 2.0, 3.0, 4.0]}],
		"trees3d": [10.0, 20.0, 4.5, -10.0, -20.0, 6.0],
		"parked": [],
		"graph": {"nodes": [0.0, 0.0, 100.0, -50.0], "edges": [{"a": 0, "b": 1, "p": [0.0, 0.0, 100.0, -50.0]}]},
		"water": [[1.0, 2.0]],  # not a packed list: stays as it is
		"bounds": [-900.0, -600.0, 900.0, 600.0],
	}
	IndexPack.pack(index)
	var packed: Array = [index["roads"][0]["p"], index["areas"][0]["p"], index["trees3d"], index["parked"],
			index["graph"]["nodes"], index["graph"]["edges"][0]["p"]]
	for i in packed.size():
		if not (packed[i] is PackedFloat32Array):
			problems.append("pack: list %d is %s, not PackedFloat32Array" % [i, type_string(typeof(packed[i]))])
	var roads_p: PackedFloat32Array = index["roads"][0]["p"]
	for i in outline.size():
		if absf(roads_p[i] - float(outline[i])) > 0.00025:
			problems.append("pack: %.4f became %.6f" % [outline[i], roads_p[i]])
	if index["roads"][0]["k"] != "primary" or index["roads"][1].has("p") or not (index["water"] is Array) \
			or not (index["bounds"] is Array):
		problems.append("pack: touched what it shouldn't: %s" % [index])
	var before := var_to_str(index)
	IndexPack.pack(index)
	if var_to_str(index) != before:
		problems.append("pack: packing twice changed the index")
	var flat: Array = index["roads"][0]["p"]
	if flat.size() != outline.size() or absf(float(flat[2]) - 1530.5) > 0.001:
		problems.append("pack: an Array reader got %s" % [flat])


func _check_on_screen() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1434, 660)
	vp.disable_3d = false
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	vp.add_child(cam)
	var traffic: Node3D = Traffic.new()
	traffic.cam = cam
	var rng := RandomNumberGenerator.new()
	rng.seed = 30
	var worst := 0.0
	var disagree := 0
	var tried := 0
	for setup: Array in [[0.0, -35.0, 80.0], [45.0, -35.0, 80.0], [130.0, -50.0, 160.0], [-90.0, -25.0, 30.0], [210.0, -60.0, 320.0]]:
		cam.size = setup[2]
		var basis := Basis.from_euler(Vector3(deg_to_rad(setup[1]), deg_to_rad(setup[0]), 0.0))
		var at := Vector3(rng.randf_range(-2000.0, 2000.0), 0.0, rng.randf_range(-2000.0, 2000.0))
		cam.global_transform = Transform3D(basis, at + basis.z * 200.0)
		traffic.player_pos = at
		# The project interpolates the camera between physics ticks: unproject_position uses the
		# drawn transform, which reaches the node's own a few frames later.
		for k in 10:
			await process_frame
			if cam.get_camera_transform().is_equal_approx(cam.global_transform):
				break
		traffic.call("_update_view")
		var rect := Rect2(Vector2.ZERO, Vector2(vp.size)).grow(vp.size.y * 0.06)
		for i in 2000:
			var p := at + Vector3(rng.randf_range(-1.2, 1.2) * setup[2], 0.0, rng.randf_range(-1.2, 1.2) * setup[2])
			var h := rng.randf_range(0.0, 4.0)
			var a := cam.unproject_position(p)
			var b := cam.unproject_position(p + Vector3.UP * h)
			var own: Vector2 = traffic.get("_view_mid") + Vector2((p - traffic.get("_cam_o")).dot(traffic.get("_cam_x")),
					-(p - traffic.get("_cam_o")).dot(traffic.get("_cam_y"))) * float(traffic.get("_cam_k"))
			worst = maxf(worst, own.distance_to(a))
			var want := rect.has_point(a) or rect.has_point(b)
			# Points within a pixel of the edge may fall either way.
			var near_edge := rect.grow(-1.0).has_point(a) != rect.grow(1.0).has_point(a) \
					or rect.grow(-1.0).has_point(b) != rect.grow(1.0).has_point(b)
			if traffic.on_screen(p, h) != want and not near_edge:
				disagree += 1
			tried += 1
	if worst > 0.5:
		problems.append("on_screen: its projection is %.2f px from Camera3D's" % worst)
	if disagree > 0:
		problems.append("on_screen: %d of %d points disagree with Camera3D" % [disagree, tried])
	print("on_screen: %d points, worst %.3f px from Camera3D.unproject_position" % [tried, worst])
	traffic.free()
	vp.queue_free()
