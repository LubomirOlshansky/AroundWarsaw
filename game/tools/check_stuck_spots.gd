extends SceneTree
## PT bug log (docs/PLAYTEST.md): the spots where a playtest found the car stopping dead, driven
## again by the real car script (car.gd) in the real city (the sectors round the spots, built from
## their files, or the prebuilt sector scenes with --prebuilt), gas held, no steering, no traffic.
## Each spot is a start, a heading and a speed; the car fails it if it sits under STALL m/s for
## more than STALL_TIME s, needs an unstick, or ends under its share of the start speed.
##
## PT-1 (2026-11-02): at 24-30 m/s the car stopped dead on Marszałkowska's west kerb line north of
## the start. It had driven inside Centrum's 0.9 m tram platform (not solid, so the car rode in the
## slab) and hit the shelter on it end on; brushing the fence along the kerb cost 1.2/s of its whole
## speed. Fixed: platforms that high are solid at their edges away from roads (map_builder.gd
## SOLID_PLATFORM, PLATFORM_ROAD_CLEAR) and
## the scrape scales with how hard the car presses in (car.gd SCRAPE_PRESS).
##
## (Head on into the platform's 3 m end the car stops, as at any wall, and is turned out.)
##
## Prints one line per spot and `check_stuck_spots: OK`, or the failures and exit 1. ~10 s on the Mac.
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_stuck_spots.gd [-- --prebuilt --verbose]

const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const INDEX_JSON := "res://map/index.json"
const INDEX_SCENE := "res://map/index.res"

## [x, z, compass heading, start speed m/s, seconds, the share of the start speed kept at the end, what].
const SPOTS := [
	[-1013.0, -45.0, -20.0, 27.0, 4.0, 0.9, "PT-1 Marszałkowska, the left lane along Centrum's tram-stop fence"],
	[-1013.0, -45.0, -25.0, 27.0, 3.0, 0.85, "PT-1 Marszałkowska, drifting 5° into the tram-stop fence"],
	[-1001.2, -5.0, -20.0, 27.0, 4.0, 0.8, "PT-1 Marszałkowska, the left side clipping the tram platform's north tip"],
	[-1025.0, -45.0, -20.0, 27.0, 4.0, 0.9, "PT-1 Marszałkowska, the tram tracks west of the platform"],
	[-1025.0, -45.0, -12.0, 27.0, 4.0, 0.5, "PT-1 Marszałkowska, off the tram tracks into the platform's side (the dead stop on the shelter)"],
]
## Sectors within this of a spot are loaded.
const REACH := 300.0
const STALL := 3.0
const STALL_TIME := 0.5

var prebuilt := false
var verbose := false
var map: Node3D
var car: CharacterBody3D
var _frames := 0
var _i := -1
var _t := 0
var _stalled := 0.0
var _worst := 0.0
var _v0 := 0.0
var _failures := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--prebuilt":
			prebuilt = true
		elif a == "--verbose":
			verbose = true
	var t0 := Time.get_ticks_msec()
	if prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
		root.add_child(map)
	else:
		map = MapBuilder.new()
		root.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	var n := 0
	for k: Array in map.index_data["sectors"]["keys"]:
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := Rect2(key.x * MapBuilder.SECTOR, key.y * MapBuilder.SECTOR, MapBuilder.SECTOR, MapBuilder.SECTOR)
		var near := false
		for s: Array in SPOTS:
			near = near or rect.grow(REACH).has_point(Vector2(s[0], s[1]))
		if not near:
			continue
		var r: Node3D = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate() \
				if prebuilt else map.build_sector(key)
		map.add_child(r)
		n += 1
	if not prebuilt:
		map.measure_sectors()
	IndexPack.pack(map.index_data)
	print("check_stuck_spots: %d sectors %s in %d ms" % [n, "loaded" if prebuilt else "built", Time.get_ticks_msec() - t0])


func _next() -> bool:
	if car != null:
		car.queue_free()
	_i += 1
	if _i >= SPOTS.size():
		return false
	var s: Array = SPOTS[_i]
	car = Car.new()
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	car.global_position = Vector3(s[0], map.ground_height(s[0], s[1]), s[1])
	car.rotation.y = -deg_to_rad(float(s[2]))
	car.vel = -car.global_transform.basis.z * float(s[3])
	car.forward_speed = float(s[3])
	car.throttle = 1.0
	_v0 = float(s[3])
	_t = 0
	_stalled = 0.0
	_worst = 0.0
	return true


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if car == null:
		return not _next()
	_t += 1
	var s: Array = SPOTS[_i]
	var v := Vector2(car.vel.x, car.vel.z).length()
	_stalled = _stalled + dt if v < STALL else 0.0
	_worst = maxf(_worst, _stalled)
	if verbose and _t % 15 == 0:
		print("   t=%.2f at %.1f, %.1f  %.1f m/s%s" % [_t * dt, car.global_position.x, car.global_position.z, v,
				"  touching" if car.get_slide_collision_count() > 0 else ""])
	if _t * dt < float(s[4]):
		return false
	var why: Array[String] = []
	if _worst > STALL_TIME:
		why.append("stalled under %.0f m/s for %.1f s" % [STALL, _worst])
	if int(car.unsticks) > 0:
		why.append("unstuck %d×" % int(car.unsticks))
	if v < _v0 * float(s[5]):
		why.append("ended at %.1f m/s, under %.0f %% of %.0f" % [v, float(s[5]) * 100.0, _v0])
	var p := car.global_position
	print("%s %s: %.1f → %.1f m/s, at %.0f, %.0f%s  (--at=%.0f,%.0f --heading=%.0f)" % [
			"FAIL" if not why.is_empty() else "ok  ", s[6], _v0, v, p.x, p.z,
			"" if why.is_empty() else " · " + ", ".join(why), s[0], s[1], s[2]])
	if not why.is_empty():
		_failures += 1
	if _next():
		return false
	if _failures == 0:
		print("check_stuck_spots: OK")
	else:
		print("check_stuck_spots: %d of %d spots fail" % [_failures, SPOTS.size()])
	quit(1 if _failures > 0 else 0)
	return false
