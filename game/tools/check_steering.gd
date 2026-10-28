extends SceneTree
## Loop 2a: an input replay for the car's steering. Scripted stick, key and pedal inputs
## over time drive the real car script on a flat test ground (with walls where a test
## needs them) through the same input mapping and follow camera as the game, and the
## heading, speed and the car's place on screen are logged and measured: a held
## direction (does it get there, circle or oscillate), the turn radius at 20/50/90 km/h,
## a 90° turn from those speeds and from a standstill, pointing straight back, letting go
## (the camera coming round), the Mac keys, Classic's self-centring, sliding along a wall,
## a head-on wall, and getting out of an inside corner. Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_steering.gd
##   -- --legacy     the car, input mapping and camera before loop 2a (the "before" numbers;
##                   tools/steering_legacy_car.gd is the car script as it was)
##   -- --verbose    also print every test's log, one line per 0.5 s
##   -- --only=NAME  run only the tests whose name starts with NAME
##
## Screen positions are in pixels on an iPhone's landscape screen (2532 x 1170) at the
## game's default view height. Headings are compass degrees (0 north, 90 east).

const LegacyCar := preload("res://tools/steering_legacy_car.gd")
const Car := preload("res://scripts/car.gd")
const Controls := preload("res://scripts/drive_controls.gd")

const PITCH := -30.0
const SCREEN := Vector2(2532, 1170)
const KMH := 1.0 / 3.6
## The view height (m) before loop 2a.
const LEGACY_SIZE := 110.0

var legacy := false
var verbose := false
var only := ""
var _tests: Array[Dictionary] = []
var _i := -1
var _test: Dictionary
var _scheme := ""
var _t := 0.0
var _car: CharacterBody3D
var _world: Node3D
var _ctl: RefCounted
var _cam := {}
var _rows: Array[Dictionary] = []
var _held_dir := Vector3.ZERO
var _results: Array[String] = []
var _problems := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--legacy":
			legacy = true
		elif a == "--verbose":
			verbose = true
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	_plan()
	print("check_steering: %s, %d runs" % ["BEFORE loop 2a (legacy car, mapping and camera)" if legacy
			else "loop 2a car and controls", _tests.size()])


func _plan() -> void:
	var point_schemes := ["follow", "fixed"] if legacy else ["point", "fixed"]
	var all_schemes := point_schemes + ["classic"]
	for v in [20.0, 50.0, 90.0]:
		_add({"name": "radius_%d" % v, "schemes": ["car"], "v0": v * KMH, "dur": 4.0, "kind": "radius"})
	for s in point_schemes:
		# The stick held towards a compass heading (the car starts going north at 50 km/h):
		# 90° right, 45°, 15°, and straight behind.
		_add({"name": "hold_right", "schemes": [s], "v0": 50 * KMH, "dur": 10.0, "kind": "hold", "aim": 90.0})
		_add({"name": "hold_diagonal", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 45.0})
		_add({"name": "hold_slight", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 15.0})
		_add({"name": "behind", "schemes": [s], "v0": 50 * KMH, "dur": 8.0, "kind": "hold", "aim": 180.0})
		# Held 90° right for 2.5 s, then let go: how the camera comes round behind the car.
		_add({"name": "release", "schemes": [s], "v0": 50 * KMH, "dur": 7.0, "kind": "hold", "aim": 90.0, "until": 2.5})
	# The Mac keyboard, D held: Point points at the screen's right (before loop 2a the keys
	# steered car-relative, so a held D circled; in Classic it still steers, by design).
	_add({"name": "keys_right", "schemes": [point_schemes[0]], "v0": 50 * KMH, "dur": 8.0, "kind": "hold",
			"aim": 90.0, "keys": {"right": true, "up": true}})
	# Classic: full right for 0.6 s, then the stick back to the middle (gas held): how fast the
	# turning stops (self-centring) and how far it carries on.
	_add({"name": "steer_release", "schemes": ["classic"], "v0": 50 * KMH, "dur": 4.0, "kind": "release"})
	for s in all_schemes:
		for v in [0.0, 20.0, 50.0, 90.0]:
			_add({"name": "turn90_%d" % v, "schemes": [s], "v0": v * KMH, "dur": 6.0, "kind": "turn90"})
		_add({"name": "wall_glance", "schemes": [s], "v0": 50 * KMH, "dur": 4.0, "kind": "wall", "heading": 60.0,
				"walls": [[Vector3(0, 2, -16), Vector3(400, 4, 1)]]})
		_add({"name": "wall_headon", "schemes": [s], "v0": 20 * KMH, "dur": 5.0, "kind": "wall", "heading": 0.0,
				"walls": [[Vector3(0, 2, -12), Vector3(400, 4, 1)]]})
		# Into an inside corner, held there 3 s, then pointing back out (Classic: reversing).
		_add({"name": "corner", "schemes": [s], "v0": 15 * KMH, "dur": 6.0, "kind": "wall", "heading": 45.0, "out_at": 3.0,
				"walls": [[Vector3(-20, 2, -14.5), Vector3(40, 4, 1)], [Vector3(0.5, 2, 5), Vector3(1, 4, 40)]],
				"start": Vector3(-9, 0, -4)})


func _add(t: Dictionary) -> void:
	if only != "" and not String(t["name"]).begins_with(only):
		return
	for s in t["schemes"]:
		var copy := t.duplicate()
		copy["scheme"] = s
		_tests.append(copy)


# --- running ----------------------------------------------------------------------------------

func _physics_process(delta: float) -> bool:
	if _i < 0 or _t >= float(_test["dur"]):
		if _i >= 0:
			_finish_test()
		_i += 1
		if _i >= _tests.size():
			_summary()
			return true
		_start_test()
	_step(delta)
	_t += delta
	return false


func _start_test() -> void:
	_test = _tests[_i]
	_scheme = _test["scheme"]
	_t = 0.0
	_rows.clear()
	_world = Node3D.new()
	root.add_child(_world)
	for w in _test.get("walls", []):
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = w[1]
		shape.shape = box
		body.add_child(shape)
		body.position = w[0]
		_world.add_child(body)
	_car = LegacyCar.new() if legacy else Car.new()
	_world.add_child(_car)
	var heading: float = _test.get("heading", 0.0)
	_car.global_position = _test.get("start", Vector3.ZERO)
	_car.rotation.y = -deg_to_rad(heading)
	var v0: float = _test["v0"]
	_car.vel = _fwd(heading) * v0
	_car.forward_speed = v0
	_ctl = null if legacy else Controls.new()
	if _ctl != null:
		_ctl.scheme = {"point": Controls.POINT, "fixed": Controls.FIXED, "classic": Controls.CLASSIC}.get(_scheme, Controls.POINT)
	var follow: bool = _scheme in ["follow", "point", "classic", "car"]
	# The camera starts settled: behind the car when following, on the 45° diagonal when fixed.
	var yaw := rad_to_deg(_car.rotation.y) if follow else 45.0
	var size := LEGACY_SIZE if legacy else Controls.DEFAULT_SIZE
	_cam = {"yaw": yaw, "yaw_target": yaw, "follow": follow, "focus": _car.global_position, "size": size, "base": size}
	_held_dir = Vector3.ZERO


func _finish_test() -> void:
	var line := _measure()
	_results.append(line)
	print(line)
	if verbose:
		_print_log()
	_world.queue_free()
	_world = null
	_car = null


## One physics step: this test's input → the car's controls (as the game maps them) →
## the camera (as the game moves it). The car itself moves in its own physics step.
func _step(dt: float) -> void:
	var inp := _input()
	if legacy:
		_legacy_controls(inp)
		_legacy_camera(dt)
	else:
		_new_controls(inp, dt)
		_new_camera(dt)
	_record(inp)


## What the player does in this test, at time _t.
func _input() -> Dictionary:
	var kind: String = _test["kind"]
	var inp := {"stick": Vector2.ZERO, "gas": false, "brake": false, "steer": 0.0, "direct": false}
	var v0: float = _test["v0"]
	if kind == "radius":
		# Full lock to the right at a held speed: the car's own turning, whatever the scheme.
		inp["direct"] = true
		inp["steer"] = -1.0
		inp["hold"] = v0
		return inp
	if kind == "hold":
		if _test.has("keys"):
			inp["keys"] = _test["keys"]
		elif _t < float(_test.get("until", INF)):
			inp["stick"] = _stick_for(_test["aim"])
		return inp
	if kind == "release":
		inp["gas"] = true
		inp["stick"] = Vector2(1.0 if _t < 0.6 else 0.0, 0.0)
		return inp
	if kind == "turn90":
		# Turn to 90° right of the start heading (east), at full gas.
		if _scheme == "classic":
			inp["gas"] = true
			# A driver: full lock until 25° short, then easing the stick back to the middle.
			var err := _wrap(90.0 - _go_heading())
			inp["stick"] = Vector2(clampf(err / 25.0, -1.0, 1.0), 0.0)
		else:
			inp["stick"] = _stick_for(90.0)
		return inp
	if kind == "wall":
		# Keep going the way the car started (into the wall).
		var heading: float = _test.get("heading", 0.0)
		var out: bool = _t >= float(_test.get("out_at", INF))
		if _scheme == "classic":
			# Getting out: reverse while still facing the corner (0, -14); once it faces away, gas.
			var to_corner := Vector3(0.0, 0.0, -14.0) - _car.global_position
			var facing := (-_car.global_transform.basis.z).dot(to_corner) > 0.0
			inp["gas"] = not out or not facing
			inp["brake"] = out and facing
		elif out:
			inp["stick"] = _stick_for(heading + 180.0, "_stick_out")
		else:
			inp["stick"] = _stick_for(heading)
		return inp
	return inp


## The stick (screen space) that points at compass heading `c` with the camera as it was
## when the test started (the finger goes down at t = 0 and stays put).
func _stick_for(c: float, key := "_stick") -> Vector2:
	if not _test.has(key):
		var view := -float(_cam["yaw"])  # compass heading the camera looks along
		var rel := deg_to_rad(c - view)
		_test[key] = Vector2(sin(rel), -cos(rel))
	return _test[key]


# --- the controls and camera before loop 2a (main.gd's _read_input / _update_camera) ---------

func _legacy_controls(inp: Dictionary) -> void:
	if inp["direct"]:
		_car.target_dir = Vector3.ZERO
		_car.steer = inp["steer"]
		_car.braking = false
		_car.throttle = clampf((float(inp["hold"]) - _car.forward_speed) * 3.0, 0.0, 1.0)
		return
	var stick: Vector2 = inp["stick"]
	if inp.has("keys"):
		# Before loop 2a the keys were car-relative in every scheme: A / D steer, W gas.
		var k: Dictionary = inp["keys"]
		_car.target_dir = Vector3.ZERO
		_car.steer = float(k.get("left", false)) - float(k.get("right", false))
		_car.throttle = 1.0 if k.get("up", false) else 0.0
		_car.braking = false
		return
	if _scheme == "classic":
		# Before loop 2a the keyboard was car-relative: A / D steer, W gas (keys are all or nothing).
		_car.target_dir = Vector3.ZERO
		_car.steer = -signf(stick.x) if absf(stick.x) > 0.5 else 0.0
		_car.throttle = 1.0 if inp["gas"] else 0.0
	elif stick.length() > 0.2:
		_car.target_dir = _screen_to_world(stick, _cam["yaw"]).normalized()
		_car.throttle = clampf((stick.length() - 0.2) / 0.8, 0.0, 1.0)
		_car.steer = 0.0
	else:
		_car.target_dir = Vector3.ZERO
		_car.throttle = 0.0
	_car.braking = inp["brake"]
	if _held_dir == Vector3.ZERO and _car.target_dir != Vector3.ZERO:
		_held_dir = _car.target_dir


func _legacy_camera(dt: float) -> void:
	var speed: float = absf(_car.forward_speed)
	if _cam["follow"]:
		var heading := rad_to_deg(_car.rotation.y)
		var rate := 2.2 * clampf(speed / 8.0, 0.0, 1.0)
		_cam["yaw"] = rad_to_deg(lerp_angle(deg_to_rad(_cam["yaw"]), deg_to_rad(heading), 1.0 - exp(-rate * dt)))
	else:
		_cam["yaw"] = lerpf(_cam["yaw"], _cam["yaw_target"], 1.0 - exp(-8.0 * dt))
	var lead: Vector3 = _car.vel * 0.6
	if lead.length() > 22.0:
		lead = lead.normalized() * 22.0
	var size: float = _cam["base"] * (1.0 + 0.25 * clampf(speed / _car.max_speed, 0.0, 1.0))
	_cam["focus"] = (_cam["focus"] as Vector3).lerp(_car.global_position + lead, 1.0 - exp(-3.5 * dt))
	_cam["size"] = lerpf(_cam["size"], size, 1.0 - exp(-2.5 * dt))


# --- the loop 2a controls and camera (drive_controls.gd, as main.gd uses it) -------------------

func _new_controls(inp: Dictionary, dt: float) -> void:
	if inp["direct"]:
		_car.target_dir = Vector3.ZERO
		_car.steer = inp["steer"]
		_car.braking = false
		_car.throttle = float(inp["hold"]) / _car.max_speed
		return
	var stick: Vector2 = inp["stick"]
	var keys: Dictionary = inp.get("keys", {"left": false, "right": false, "up": false, "down": false, "brake": false})
	if inp.has("keys") and _scheme != "classic":
		keys = keys.duplicate()
		keys["up"] = false  # Point: W would point up the screen too; D alone points right
	_ctl.drive(_car, stick, stick != Vector2.ZERO, keys, inp["gas"], inp["brake"], _cam["yaw"], dt)
	if _held_dir == Vector3.ZERO and _car.target_dir != Vector3.ZERO:
		_held_dir = _car.target_dir


func _new_camera(dt: float) -> void:
	var speed: float = absf(_car.forward_speed)
	if _cam["follow"]:
		_cam["yaw"] = _ctl.follow_yaw(_cam["yaw"], rad_to_deg(_car.rotation.y), speed, dt) if _ctl != null \
				else _cam["yaw"]
	else:
		_cam["yaw"] = lerpf(_cam["yaw"], _cam["yaw_target"], 1.0 - exp(-8.0 * dt))
	var size: float = _cam["base"] * (1.0 + Controls.SPEED_ZOOM * clampf(speed / _car.max_speed, 0.0, 1.0))
	var lead: Vector3 = _ctl.lead(_car.vel, _cam["size"], dt) if _ctl != null else Vector3.ZERO
	_cam["focus"] = (_cam["focus"] as Vector3).lerp(_car.global_position + lead, 1.0 - exp(-Controls.FOCUS_RATE * dt))
	_cam["size"] = lerpf(_cam["size"], size, 1.0 - exp(-2.5 * dt))


# --- logging and measuring ---------------------------------------------------------------------

func _record(inp: Dictionary) -> void:
	var p := _car.global_position
	var b := Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(_cam["yaw"]), 0.0))
	var off: Vector3 = p - _cam["focus"]
	var size: float = _cam["size"]
	var sx := off.dot(b.x) / (size * SCREEN.x / SCREEN.y) * SCREEN.x + SCREEN.x * 0.5
	var sy := -off.dot(b.y) / size * SCREEN.y + SCREEN.y * 0.5
	var moved := 0.0
	if not _rows.is_empty():
		moved = Vector2(p.x - float(_rows.back()["x"]), p.z - float(_rows.back()["z"])).length() * 60.0
	_rows.append({"t": _t, "x": p.x, "z": p.z, "heading": _body_heading(), "go": _go_heading(),
			"speed": _car.vel.length(), "moved": moved, "fs": _car.forward_speed, "cam": -float(_cam["yaw"]),
			"sx": sx, "sy": sy, "contact": _car.get_slide_collision_count() > 0,
			"braking": _car.get("brakes_on") if _car.get("brakes_on") != null else _car.braking,
			"held": _held_dir, "size": size})


func _body_heading() -> float:
	var f := -_car.global_transform.basis.z
	return fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0)


## Where the car is going: its velocity's heading (its body's when nearly still).
func _go_heading() -> float:
	if _car.vel.length() < 0.5:
		return _body_heading()
	return fposmod(rad_to_deg(atan2(_car.vel.x, -_car.vel.z)), 360.0)


static func _fwd(compass: float) -> Vector3:
	return Vector3(sin(deg_to_rad(compass)), 0.0, -cos(deg_to_rad(compass)))


static func _wrap(a: float) -> float:
	return wrapf(a, -180.0, 180.0)


static func _compass(v: Vector3) -> float:
	return fposmod(rad_to_deg(atan2(v.x, -v.z)), 360.0)


func _screen_to_world(s: Vector2, yaw: float) -> Vector3:
	var b := Basis.from_euler(Vector3(deg_to_rad(PITCH), deg_to_rad(yaw), 0.0))
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var ahead := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	return right * s.x + ahead * -s.y


func _measure() -> String:
	var name := "%-14s %-8s" % [_test["name"], _scheme]
	match String(_test["kind"]):
		"radius":
			return name + _m_radius()
		"hold":
			return name + _m_hold()
		"release":
			return name + _m_release()
		"turn90":
			return name + _m_turn90()
		"wall":
			return name + _m_wall()
	return name


## Steady full-lock radius over the last 2 s: mean speed over mean turn rate of the path.
func _m_radius() -> String:
	var turn := 0.0
	var dist := 0.0
	var n := 0
	for k in range(1, _rows.size()):
		if _rows[k]["t"] < 2.0:
			continue
		turn += absf(_wrap(_rows[k]["go"] - _rows[k - 1]["go"]))
		dist += Vector2(_rows[k]["x"] - _rows[k - 1]["x"], _rows[k]["z"] - _rows[k - 1]["z"]).length()
		n += 1
	var r := dist / maxf(deg_to_rad(turn), 0.0001)
	var v: float = _rows.back()["speed"]
	return "full-lock radius %5.1f m at %3.0f km/h (yaw %.2f rad/s, sideways pull %.1f m/s² = %.1f g)" % [
			r, v * 3.6, v / r, v * v / r, v * v / r / 9.81]


## A held stick: the error between where the car goes and where the stick pointed when the
## finger went down; total turn (full circles), settling, overshoot and oscillation.
func _m_hold() -> String:
	var held: Vector3 = _rows.back()["held"]
	var want := _compass(held)
	var total := 0.0
	var errs := PackedFloat32Array()
	for k in _rows.size():
		if k > 0:
			total += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		errs.append(_wrap(_rows[k]["go"] - want))
	var settle := _settle_time(errs, 5.0)
	var first_in := -1
	for k in errs.size():
		if absf(errs[k]) < 5.0:
			first_in = k
			break
	var over := 0.0
	var flips := 0
	if first_in >= 0:
		var side := signf(errs[0])
		for k in range(first_in, errs.size()):
			if signf(errs[k]) == -side:
				over = maxf(over, absf(errs[k]))
		for k in range(first_in + 1, errs.size()):
			if absf(errs[k]) > 1.0 and absf(errs[k - 1]) > 1.0 and signf(errs[k]) != signf(errs[k - 1]):
				flips += 1
	var min_speed := INF
	var brake_t := 0.0
	for r in _rows:
		min_speed = minf(min_speed, r["speed"])
		if r["braking"]:
			brake_t += 1.0 / 60.0
	var circles := absf(total) / 360.0
	var final_err := errs[errs.size() - 1]
	var swing := _swing()
	if _test.has("until"):
		# After letting go: when the camera is within 10° of the car's heading, and how fast it turned.
		var aligned := -1.0
		var fastest := 0.0
		for k in range(1, _rows.size()):
			if _rows[k]["t"] < float(_test["until"]):
				continue
			fastest = maxf(fastest, absf(_wrap(_rows[k]["cam"] - _rows[k - 1]["cam"])) * 60.0)
			if aligned < 0.0 and absf(_wrap(_rows[k]["cam"] - _rows[k]["heading"])) < 10.0:
				aligned = _rows[k]["t"] - float(_test["until"])
		swing += " | let go at %.1f s: camera behind the car %s after, turning at most %.0f°/s, the car at %.0f km/h at the end" % [
				_test["until"], ("%.1f s" % aligned) if aligned >= 0.0 else "never", fastest, _rows.back()["speed"] * 3.6]
	var ok := circles < 0.75 and absf(final_err) < 5.0 and over < 10.0
	if not ok and not legacy:
		_problems += 1
	var errs_line := ""
	for t in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0]:
		var k := mini(int(t * 60.0), errs.size() - 1)
		errs_line += " %+4.0f" % errs[k]
	return "aim %03.0f° | error at 0.5/1/1.5/2/3/4/6/8 s:%s | turned %4.0f° (%.1f circles) | settles in %s | overshoot %2.0f° | flips %d | min %3.0f km/h, braked %.1f s | %s%s" % [
			want, errs_line, total, circles, ("%.1f s" % settle) if settle >= 0.0 else "never", over, flips,
			min_speed * 3.6, brake_t, swing, "" if ok or legacy else "  <-- PROBLEM"]


## Classic, steer and let go: the yaw rate when the stick returns, how long until the car stops
## turning (under 0.05 rad/s), and how far it turns after the release.
func _m_release() -> String:
	var k0 := int(0.6 * 60.0)
	var rate0 := 0.0
	var settle := -1.0
	var after := 0.0
	for k in range(k0, _rows.size()):
		var rate := absf(_wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])) * 60.0
		if k == k0:
			rate0 = rate
		if k > k0:
			after += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		if settle < 0.0 and k > k0 and rate < rad_to_deg(0.05):
			settle = (k - k0) / 60.0
	return "turning %.0f°/s when the stick returns, stops turning %s later, turns %.1f° more after letting go, then holds %03.0f°" % [
			rate0, ("%.2f s" % settle) if settle >= 0.0 else "never", absf(after), _rows.back()["heading"]]


## The first time the error enters ±tol and stays there to the end (-1: never).
func _settle_time(errs: PackedFloat32Array, tol: float) -> float:
	var k := errs.size() - 1
	if absf(errs[k]) > tol:
		return -1.0
	while k > 0 and absf(errs[k - 1]) <= tol:
		k -= 1
	return k / 60.0


## The car's place on screen: how far it wanders from the middle, and how fast.
func _swing() -> String:
	var lo := Vector2(INF, INF)
	var hi := -lo
	var fastest := 0.0
	var cam_rate := 0.0
	for k in range(6, _rows.size()):
		var s := Vector2(_rows[k]["sx"], _rows[k]["sy"])
		lo = lo.min(s)
		hi = hi.max(s)
		if k > 6:
			var s0 := Vector2(_rows[k - 1]["sx"], _rows[k - 1]["sy"])
			fastest = maxf(fastest, s.distance_to(s0) * 60.0)
			cam_rate = maxf(cam_rate, absf(_wrap(_rows[k]["cam"] - _rows[k - 1]["cam"])) * 60.0)
	return "on screen x %4.0f-%4.0f y %4.0f-%4.0f px, fastest %4.0f px/s, camera turns up to %3.0f°/s" % [
			lo.x, hi.x, lo.y, hi.y, fastest, cam_rate]


## A 90° turn to the right: time until the car goes within 5° of east, how far past it
## swings, the size of the turn (mean of the ground covered ahead and sideways), and the
## speed there.
func _m_turn90() -> String:
	var hit := -1
	for k in _rows.size():
		if absf(_wrap(_rows[k]["go"] - 90.0)) < 5.0 and _rows[k]["speed"] > 0.3:
			hit = k
			break
	var over := 0.0
	var flips := 0
	if hit >= 0:
		for k in range(hit, _rows.size()):
			over = maxf(over, _wrap(_rows[k]["go"] - 90.0))
		for k in range(hit + 1, _rows.size()):
			var a := _wrap(_rows[k]["go"] - 90.0)
			var b := _wrap(_rows[k - 1]["go"] - 90.0)
			if absf(a) > 1.0 and absf(b) > 1.0 and signf(a) != signf(b):
				flips += 1
	var final_err := _wrap(_rows.back()["go"] - 90.0)
	if hit < 0:
		var turned := 0.0
		for k in range(1, _rows.size()):
			turned += _wrap(_rows[k]["heading"] - _rows[k - 1]["heading"])
		if not legacy:
			_problems += 1
		return "never reaches east (turned %.0f°, final heading %03.0f°)  <-- PROBLEM" % [turned, _rows.back()["go"]]
	var r: Dictionary = _rows[hit]
	var ahead := -(float(r["z"]) - float(_rows[0]["z"]))
	var side := float(r["x"]) - float(_rows[0]["x"])
	var dist := 0.0
	for k in range(1, hit + 1):
		dist += Vector2(_rows[k]["x"] - _rows[k - 1]["x"], _rows[k]["z"] - _rows[k - 1]["z"]).length()
	var ok := over < 10.0 and absf(final_err) < 5.0
	if not ok and not legacy:
		_problems += 1
	return "east in %.2f s, %4.1f m ahead + %4.1f m right (turn size %4.1f m), %5.1f m driven, %3.0f km/h there | overshoot %2.0f°, flips %d, after 6 s %+3.0f° | %s%s" % [
			hit / 60.0, ahead, side, (absf(ahead) + absf(side)) * 0.5, dist, r["speed"] * 3.6, over, flips, final_err,
			_swing(), "" if ok or legacy else "  <-- PROBLEM"]


## Into a wall: the ground speed (real movement) kept 1 s after the first touch, the ground
## covered in the 2 s after it, how long the car sat pinned (touching, moving under 1 m/s),
## the unsticks, and the end: still moving, and (corner) how far out of the corner it got.
func _m_wall() -> String:
	var first := -1
	for k in _rows.size():
		if _rows[k]["contact"]:
			first = k
			break
	if first < 0:
		return "never touched the wall"
	var v_in: float = _rows[maxi(first - 1, 1)]["moved"]
	var k1 := mini(first + 60, _rows.size() - 1)
	var k2 := mini(first + 120, _rows.size() - 1)
	var along := Vector2(_rows[k2]["x"] - _rows[first]["x"], _rows[k2]["z"] - _rows[first]["z"]).length()
	var pinned := 0.0
	var longest := 0.0
	var run := 0.0
	for k in range(first, _rows.size()):
		if _rows[k]["contact"] and _rows[k]["moved"] < 1.0:
			pinned += 1.0 / 60.0
			run += 1.0 / 60.0
			longest = maxf(longest, run)
		else:
			run = 0.0
	var end: Dictionary = _rows.back()
	var end_speed := 0.0
	for k in range(_rows.size() - 30, _rows.size()):
		end_speed += float(_rows[k]["moved"]) / 30.0
	var unstuck := ""
	if _car.get("unsticks") != null:
		unstuck = ", unstuck %d×" % int(_car.get("unsticks"))
	var out := ""
	if _test.has("out_at"):
		# The corner is at (0, -14).
		var d := Vector2(float(end["x"]), float(end["z"]) + 14.0).length()
		out = ", %.1f m from the corner at the end" % d
	var ok := end_speed >= 2.0 and longest <= 2.0
	if not ok and not legacy:
		_problems += 1
	return "touch at %3.0f km/h, 1 s later %3.0f km/h (%3.0f%%), %4.1f m covered in 2 s, pinned %.1f s (longest %.1f s)%s, last 0.5 s %3.0f km/h heading %03.0f°%s %s%s" % [
			v_in * 3.6, float(_rows[k1]["moved"]) * 3.6, 100.0 * float(_rows[k1]["moved"]) / maxf(v_in, 0.01), along,
			pinned, longest, unstuck, end_speed * 3.6, end["go"], out, "(moving)" if end_speed >= 2.0 else "(STUCK)",
			"" if ok or legacy else "  <-- PROBLEM"]


func _print_log() -> void:
	for r in _rows:
		var k := int(round(float(r["t"]) * 60.0))
		if k % 30 != 0:
			continue
		print("    t %4.1f  heading %03.0f  going %03.0f  %3.0f km/h  camera %03.0f  screen %4.0f,%4.0f%s" % [
				r["t"], r["heading"], r["go"], r["speed"] * 3.6, fposmod(r["cam"], 360.0), r["sx"], r["sy"],
				"  wall" if r["contact"] else ""])


func _summary() -> void:
	var car_len := 4.0 * SCREEN.y / (LEGACY_SIZE if legacy else Controls.DEFAULT_SIZE)
	print("car on screen at the default view (%.0f m): %.0f px long side-on, %.0f px nose-up, of 1170 lines" % [
			LEGACY_SIZE if legacy else Controls.DEFAULT_SIZE, car_len, car_len * (0.5 + 1.5 / 4.0 * 0.87)])
	if legacy:
		print("check_steering: legacy run (numbers only)")
	else:
		print("check_steering: %s" % ("OK" if _problems == 0 else "%d PROBLEM(S)" % _problems))
	if _problems > 0 and not legacy:
		quit(1)
