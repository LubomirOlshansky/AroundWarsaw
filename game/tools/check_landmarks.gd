extends SceneTree
## v0.8 landmarks, checked without looking: for every landmark, is it solid for the car
## (rays at bumper height from all round hit a wall near its outline), does the
## helicopter's roof grid hold its shape (tallest cell, the cells round the spire), does a
## tap from the camera find it, and where would a roof rescue on it land.
##   godot --headless --path game --script res://tools/check_landmarks.gd [-- --grid=OUT.png]
## --grid writes the landmarks' roof-grid cells (4 m, one colour per landmark, red = id)
## and their info (bounds) for tools/overlay_landmarks.py, which lays them over the
## orthophoto.

var map: Node3D
var _frames := 0


func _initialize() -> void:
	# Loop 3c: the streamed city, every sector built from its file (the runtime path).
	map = load("res://scripts/sector_streamer.gd").open_whole(root, "--prebuilt" in OS.get_cmdline_user_args())


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	# Exit 1 on a failure, so tools/verify.sh and CI see it without reading the line.
	quit(0 if _check() == 0 else 1)
	return true


func _check() -> int:
	var space: PhysicsDirectSpaceState3D = map.get_world_3d().direct_space_state
	var missions: Node = load("res://scripts/missions.gd").new()
	missions.map = map
	var data: Dictionary = map.data
	var failures := 0
	for k in map.landmark_info.size():
		var info: Dictionary = map.landmark_info[k]
		if info["pl"] == "":
			continue  # a skin with no card (Królewska's block) is off the picking grid on purpose
		var c: Vector2 = info["centre"]
		# The tallest roof-grid cell near the centre, and what a tap straight down finds.
		var tallest := -INF
		var at := c
		var box: Rect2 = info["box"]
		for dz in range(0, int(box.size.y) + 1, 4):
			for dx in range(0, int(box.size.x) + 1, 4):
				var x := box.position.x + dx
				var z := box.position.y + dz
				if map.landmark_at(x, z) == k and map.roof_height(x, z) > tallest:
					tallest = map.roof_height(x, z)
					at = Vector2(x, z)
		c = at  # a site of several pieces (the bridge's towers): test at its tallest one
		var ground: float = map.terrain_height(c.x, c.y)
		# A tap from the game's camera angle (30° down) aimed just under the cell's top.
		var aim := Vector3(at.x, tallest - 1.0, at.y)
		var tap: int = map.pick_landmark(aim + Vector3(0.0, 500.0, 866.0), Vector3(0.0, -0.5, -0.866))
		# A car driving in from 12 directions (2 m steps at bumper height over the ground,
		# from 220 m out to the centre, or from past the site's far corner when it is bigger,
		# such as Arkadia's 300 m block): does a wall stop it before the middle?
		var reach := 220.0
		for corner in [box.position, box.end, Vector2(box.position.x, box.end.y), Vector2(box.end.x, box.position.y)]:
			reach = maxf(reach, c.distance_to(corner) + 10.0)
		var hits := 0
		for d in 12:
			var dir := Vector2.from_angle(TAU * d / 12.0)
			var r := reach
			while r > 4.0:
				var p0 := c + dir * r
				var p1 := c + dir * (r - 2.0)
				var q := PhysicsRayQueryParameters3D.create(Vector3(p0.x, map.drive_height(p0.x, p0.y, 0.0) + 0.8, p0.y),
						Vector3(p1.x, map.drive_height(p1.x, p1.y, 0.0) + 0.8, p1.y))
				if not space.intersect_ray(q).is_empty():
					hits += 1
					break
				r -= 2.0
		print("%-22s tallest cell %5.1f m above ground at %s · tap finds %s · car rays stopped %d/12" % [
				info["name"], tallest - ground, at.round(), "it" if tap == k else "id %d" % tap, hits])
		# A bridge's pylon stands in the median between two carriageways: a car from along the
		# deck passes beside it, so Most Świętokrzyski needs fewer stopped rays.
		var need := 6 if info["key"] == "swieto" else 10
		if tap != k or hits < need:
			failures += 1
	# Roof rescues that the landmarks' outlines now give (missions.gd's own search).
	for l in data.get("landmarks", []):
		if l["name"] in ["Pałac Kultury i Nauki", "Rotunda PKO", "Varso Tower", "Złote Tarasy"]:
			var poly := PackedVector2Array()
			var flat: Array = l["p"]
			for i in range(0, flat.size() - 1, 2):
				poly.append(Vector2(flat[i], flat[i + 1]))
			var spot: Vector3 = missions._flat_roof(poly)
			if spot == Vector3.INF:
				print("roof rescue on %s: none (no flat roof 20 m up)" % l["name"])
			else:
				print("roof rescue on %s: %s, %d m up, landmark cell %d" % [l["name"], spot.round(),
						roundi(spot.y - map.ground_height(spot.x, spot.z)), map.landmark_at(spot.x, spot.z)])
	# The Palace's spire: the cells round it stand to its top, so the helicopter can't
	# fly through its base; the helicopter's own test (top_height over its radius).
	for l in map.landmark_info:
		if l["key"] == "palace":
			var best := -INF
			var spire := Vector2.ZERO
			var c: Vector2 = l["centre"]
			for dz in range(-80, 81, 2):
				for dx in range(-80, 81, 2):
					var h: float = map.roof_height(c.x + dx, c.y + dz)
					if h > best:
						best = h
						spire = Vector2(c.x + dx, c.y + dz)
			var g: float = map.terrain_height(spire.x, spire.y)
			print("Palace spire cell %s: top %.1f m above ground; heli top_height there at r=3: %.1f m; 12 m off: %.1f m" % [
					spire.round(), best - g, map.top_height(spire.x, spire.y, 3.0) - g, map.top_height(spire.x + 12.0, spire.y, 3.0) - g])
	missions.free()
	failures += _fly_checks()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--grid="):
			var img := Image.create(map._roof_nx, map._roof_nz, false, Image.FORMAT_RGBA8)
			for j in map._roof_nz:
				for i in map._roof_nx:
					var id: int = map._pick[j * map._roof_nx + i]
					if id > 0:
						img.set_pixel(i, j, Color8(id * 30, 255, 0, 255))
			img.save_png(arg.trim_prefix("--grid="))
			var meta := FileAccess.open(arg.trim_prefix("--grid=").get_basename() + ".json", FileAccess.WRITE)
			var names: Array = []
			for l in map.landmark_info:
				names.append([l["key"], l["name"], l["centre"].x, l["centre"].y])
			meta.store_string(JSON.stringify({"x0": map._roof_x0, "z0": map._roof_z0, "cell": map.ROOF_CELL, "landmarks": names}))
			print("grid written to ", arg.trim_prefix("--grid="))
	print("landmark check: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	return failures


## The helicopter (heli.gd, stepped by hand at 60 Hz) flies at 45 m straight at each
## landmark from 220 m out: it must be stopped before any cell whose top is over its
## skids; then it lands on open ground beside the landmark and must touch down there.
func _fly_checks() -> int:
	var Heli = load("res://scripts/heli.gd")
	var failures := 0
	for k in map.landmark_info.size():
		var info: Dictionary = map.landmark_info[k]
		var box: Rect2 = info["box"]
		var c: Vector2 = box.get_center()
		if info["key"] == "poniatowski":
			c = Vector2(935.0, -128.0)  # the west pair
		elif info["key"] == "swieto":
			c = Vector2(735.0, -896.0)  # the pylon at 45 m (the site is a long strip: its middle is open air)
		var heli: Node3D = Heli.new()
		heli.ground_height = map.ground_height
		heli.top_height = map.top_height
		heli.bounds = map.bounds
		root.add_child(heli)
		# Fly at half the landmark's height (45 m at most), so it has to stop at its walls.
		var top := 0.0
		for dz in range(0, int(box.size.y) + 1, 4):
			for dx in range(0, int(box.size.x) + 1, 4):
				var x := box.position.x + dx
				var z := box.position.y + dz
				if map.landmark_at(x, z) == k:
					top = maxf(top, map.roof_height(x, z) - map.terrain_height(x, z))
		var alt := clampf(top * 0.5, 6.0, 45.0)
		var dir := Vector2(1, 0.35).normalized()
		var start := c + dir * maxf(box.size.length() * 0.5 + 60.0, 160.0)
		heli.place(Vector3(start.x, map.ground_height(start.x, start.y) + alt, start.y), 0.0, alt)
		var inside := false
		var blocked := false
		for f in 900:
			var p: Vector3 = heli.global_position
			var to := Vector2(c.x - p.x, c.y - p.z)
			heli.input_dir = Vector3(to.x, 0, to.y).normalized() * 0.8
			heli._physics_process(1.0 / 60.0)
			blocked = blocked or heli.blocked
			var q: Vector3 = heli.global_position
			if map.roof_height(q.x, q.z) > q.y + 1.0:
				inside = true
		var stop: Vector3 = heli.global_position
		# Then down onto open ground: back off along the way it came until the ground is clear.
		var spot := Vector2(stop.x, stop.z)
		var g0: float = map.ground_height(spot.x, spot.y)
		while map.top_height(spot.x, spot.y, 3.0) > map.ground_height(spot.x, spot.y) + 0.5 and spot.distance_to(c) < 400.0:
			spot += dir * 4.0
		heli.place(Vector3(spot.x, map.ground_height(spot.x, spot.y) + 30.0, spot.y), 0.0, 30.0)
		heli.landing = true
		var landed := false
		for f in 900:
			heli._physics_process(1.0 / 60.0)
			if not heli.landing:
				landed = true  # heli.gd clears `landing` as it touches down
				break
		var ground: float = map.ground_height(spot.x, spot.y)
		var ok := blocked and not inside and landed and absf(heli.global_position.y - ground) < 0.6
		if not ok:
			print("  blocked %s, went inside %s, landed %s, skids %.2f m over the ground" % [blocked, inside, landed, heli.global_position.y - ground])
		print("%-22s heli at %d m: %s, stopped %d m from the middle, %d m up; landed beside it %d m from the middle: %s" % [
				info["name"], roundi(alt), "blocked" if blocked else "NOT blocked", roundi(Vector2(stop.x, stop.z).distance_to(c)),
				roundi(stop.y - g0), roundi(spot.distance_to(c)), "yes" if landed else "NO"])
		if not ok:
			failures += 1
		heli.free()
	return failures
