extends SceneTree
## GAMEPLAY_PLAN 3.5 / 0.3 (the playtest, 2026-11-03: the car hidden under Trasa Łazienkowska): the
## tunnel x-ray (tunnel_xray.gd) also shows the car while a bridge or viaduct deck stands between
## it and the camera (map_builder.gd `deck_hides`, main.gd's frame). From the map's data alone (no
## meshes), the camera at the game's pitch (main.gd `camera_pitch`) from YAWS compass directions:
##
## 1. SPOTS: a car on the road under a deck is hidden from most of the directions; the same car up
##    on that deck from none.
## 2. Open streets: hidden from none.
## 3. Every deck piece's centreline every 10 m, a car on top, one direction: hidden only where a
##    higher deck really crosses over it (the stacked spans), at most STACKED_MAX samples.
## 4. Every ground road (centrelines every 5 m, the car at drive_height), one direction: the
##    samples a deck hides, at least UNDER_MIN (the Trasa, Most Łazienkowski's land spans, the
##    viaducts).
##
## Needs the terrain (game/map/terrain.json, the map pack): on flat ground no deck stands over a road.
## Prints `check_deck_xray: OK` or the failures and exit 1. ~10 s.
##   godot --headless --path game --script res://tools/check_deck_xray.gd [-- --verbose]

const MapBuilder := preload("res://scripts/map_builder.gd")
const MAP_PATH := "res://map/centrum.json"
const PITCH := 30.0
const YAWS := 8
## The point tested: the car's middle, over its origin (main.gd).
const MIDDLE := 0.8

## [x, z, what]: a ground road crossing under a deck (centrum.json's roads: a bridge way over a
## street on the ground).
const SPOTS := [
	[847.4, 1330.5, "Łazienkowska under the Trasa at Rondo Sedlaczka"],
	[790.5, 1349.8, "Myśliwiecka under the Trasa"],
	[1356.0, 1068.9, "Solec under Most Łazienkowski"],
	[2085.4, 825.2, "Wał Miedzeszyński under Most Łazienkowski"],
	[822.4, -85.5, "Aleja 3 Maja under the Poniatowski viaduct"],
]
## [x, z, what]: no deck near the car here.
const OPEN := [
	[-1013.0, -45.0, "Marszałkowska by Centrum"],
	[-387.0, -187.0, "Nowy Świat"],
]
## At least this many of the YAWS directions see the deck hide a SPOT's car (half: a spot by a deck's
## edge is seen past it from the other side).
const SPOT_MIN := 4
const STACKED_MAX := 400
const UNDER_MIN := 100


func _initialize() -> void:
	var verbose := "--verbose" in OS.get_cmdline_user_args()
	var map: Node3D = MapBuilder.new()
	root.add_child(map)
	map._setup(JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH)), ShaderMaterial.new(), ShaderMaterial.new())
	var fails: Array[String] = []
	var dirs: Array[Vector3] = []
	for k in YAWS:
		var yaw := TAU * k / YAWS
		var c := cos(deg_to_rad(PITCH))
		dirs.append(Vector3(sin(yaw) * c, sin(deg_to_rad(PITCH)), cos(yaw) * c))

	for s: Array in SPOTS:
		var x := float(s[0])
		var z := float(s[1])
		var low: float = map.drive_height(x, z, map.terrain_height(x, z))
		var top: float = map.ground_height(x, z)
		var hid := 0
		var hid_top := 0
		for d in dirs:
			hid += int(map.deck_hides(Vector3(x, low + MIDDLE, z), d))
			hid_top += int(map.deck_hides(Vector3(x, top + MIDDLE, z), d))
		print("  %s: road %.1f m, deck %.1f m, hidden from %d of %d, on top from %d" % [s[2], low, top, hid, YAWS, hid_top])
		if hid < SPOT_MIN:
			fails.append("%s: the deck hides the car under it from %d of %d directions (min %d)" % [s[2], hid, YAWS, SPOT_MIN])
		if hid_top > 0:
			fails.append("%s: the car on the deck counts as hidden from %d directions" % [s[2], hid_top])

	for s: Array in OPEN:
		var x := float(s[0])
		var z := float(s[1])
		for d in dirs:
			if map.deck_hides(Vector3(x, map.ground_height(x, z) + MIDDLE, z), d):
				fails.append("%s: hidden by a deck on an open street" % s[2])
				break

	var stacked := 0
	var on_top := 0
	for d: Dictionary in map._decks:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		for k in pts.size() - 1:
			var n := maxi(1, ceili(pts[k].distance_to(pts[k + 1]) / 10.0))
			for i in n:
				var t := float(i) / n
				var p := pts[k].lerp(pts[k + 1], t)
				on_top += 1
				if map.deck_hides(Vector3(p.x, lerpf(hs[k], hs[k + 1], t) + MIDDLE, p.y), dirs[1]):
					stacked += 1
					if verbose:
						print("  stacked: (%.0f, %.0f)" % [p.x, p.y])
	print("  on the decks: %d of %d samples hidden by another deck (max %d)" % [stacked, on_top, STACKED_MAX])
	if stacked > STACKED_MAX:
		fails.append("%d deck samples hidden by another deck (max %d)" % [stacked, STACKED_MAX])

	var under_n := 0
	var names := {}
	for r: Dictionary in map.data["roads"]:
		if bool(r.get("bridge", false)):
			continue
		var name := String(r.get("name", ""))
		var flat: Array = r["p"]
		for k in range(0, flat.size() - 2, 2):
			var a := Vector2(flat[k], flat[k + 1])
			var b := Vector2(flat[k + 2], flat[k + 3])
			var n := maxi(1, ceili(a.distance_to(b) / 5.0))
			for i in n:
				var p := a.lerp(b, float(i) / n)
				var y: float = map.drive_height(p.x, p.y, map.terrain_height(p.x, p.y))
				if map.deck_hides(Vector3(p.x, y + MIDDLE, p.y), dirs[1]):
					if verbose and not names.has(name):
						print("  hidden: %s (%.1f, %.1f)" % [name, p.x, p.y])
					under_n += 1
					names[name] = int(names.get(name, 0)) + 1
	print("  ground-road samples a deck hides: %d (min %d) on %d streets" % [under_n, UNDER_MIN, names.size()])
	# The per-frame cost: a car on the ground under the Trasa and on an open street.
	var cost := []
	for at: Vector3 in [Vector3(847.4, -13.8, 1330.5), Vector3(-1013.0, 0.8, -45.0)]:
		var t0 := Time.get_ticks_usec()
		for i in 2000:
			map.deck_hides(at, dirs[i % YAWS])
		cost.append((Time.get_ticks_usec() - t0) / 2000.0)
	print("  deck_hides: %.1f µs a call under the Trasa, %.1f on an open street" % cost)
	if under_n < UNDER_MIN:
		fails.append("only %d ground-road samples a deck hides (min %d)" % [under_n, UNDER_MIN])

	map.free()
	for f in fails:
		print("check_deck_xray: FAIL " + f)
	if fails.is_empty():
		print("check_deck_xray: OK")
	quit(0 if fails.is_empty() else 1)
