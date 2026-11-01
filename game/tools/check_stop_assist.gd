extends SceneTree
## The quest stop assist (stop_assist.gd, car.gd `assist_at`): the real car script on a flat test
## ground, the gas held the whole time as a finger on the stick would, and a quest ring ahead,
## beside or behind it. A car heading into the ring at 30, 50 or 90 km/h must come to rest inside
## it and stay still long enough for every quest's hold, then be let go (it drives on with the gas
## still held); a car passing beside the ring or driving away from it, or with no ring, is never
## touched; BRAKE held at a standstill in the ring reverses out at once. The quests' stop rings
## and "stopped" speeds must be the shared ones. Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_stop_assist.gd

const Car := preload("res://scripts/car.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Missions := preload("res://scripts/missions.gd")
const Rides := preload("res://scripts/rides.gd")
const Jobs := preload("res://scripts/jobs.gd")
const TrendJob := preload("res://scripts/trend_job.gd")
const Roundup := preload("res://scripts/roundup_job.gd")
const KMH := 1.0 / 3.6
## The longest quest hold (s): missions.gd and trend_job.gd.
const QUEST_HOLD := 1.5

var _tests: Array[Dictionary] = []
var _i := -1
var _t := 0.0
var _test: Dictionary
var _world: Node3D
var _car: Car
var _log: Dictionary
var _problems: Array[String] = []


func _initialize() -> void:
	_constants()
	var ring := Vector3(0, 0, -60)
	for kmh: float in [30.0, 50.0, 90.0]:
		_tests.append({"name": "head-on %d km/h" % kmh, "v": kmh * KMH, "ring": ring, "start": Vector3.ZERO, "dur": 12.0, "want": "stop"})
	_tests.append({"name": "slightly off line 50 km/h", "v": 50.0 * KMH, "ring": ring + Vector3(5.0, 0, 0), "start": Vector3.ZERO, "dur": 12.0, "want": "stop"})
	_tests.append({"name": "passing beside 50 km/h", "v": 50.0 * KMH, "ring": ring + Vector3(15.0, 0, 0), "start": Vector3.ZERO, "dur": 7.0, "want": "free"})
	_tests.append({"name": "driving away 50 km/h", "v": 50.0 * KMH, "ring": Vector3(0, 0, 20), "start": Vector3.ZERO, "dur": 5.0, "want": "free"})
	_tests.append({"name": "no ring 50 km/h", "v": 50.0 * KMH, "ring": Vector3.INF, "start": Vector3.ZERO, "dur": 5.0, "want": "free"})
	_tests.append({"name": "reverse out", "v": 0.0, "ring": Vector3(0, 0, -2), "start": Vector3.ZERO, "dur": 2.0, "want": "reverse"})
	print("check_stop_assist: %d runs, ring %.0f m, stopped under %.1f m/s" % [_tests.size(), StopAssist.RING, StopAssist.STOP_SPEED])


## The quests share the assist's ring and "stopped".
func _constants() -> void:
	var rings := {"missions CAR_REACH": Missions.CAR_REACH, "rides BOARD": Rides.BOARD, "rides ARRIVE": Rides.ARRIVE,
			"jobs ARRIVE": Jobs.ARRIVE, "trend PICKUP": TrendJob.PICKUP, "trend ARRIVE": TrendJob.ARRIVE, "roundup UNLOAD_R": Roundup.UNLOAD_R}
	for k: String in rings:
		if not is_equal_approx(float(rings[k]), StopAssist.RING):
			_problems.append("%s is %.1f, not the shared ring %.1f" % [k, rings[k], StopAssist.RING])
	var speeds := {"missions CAR_STOPPED": Missions.CAR_STOPPED, "rides BOARD_SPEED": Rides.BOARD_SPEED,
			"rides ARRIVE_SPEED": Rides.ARRIVE_SPEED, "jobs ARRIVE_SPEED": Jobs.ARRIVE_SPEED, "trend PICKUP_SPEED": TrendJob.PICKUP_SPEED,
			"trend ARRIVE_SPEED": TrendJob.ARRIVE_SPEED, "roundup UNLOAD_SPEED": Roundup.UNLOAD_SPEED}
	for k: String in speeds:
		if not is_equal_approx(float(speeds[k]), StopAssist.STOP_SPEED):
			_problems.append("%s is %.1f, not the shared stop speed %.1f" % [k, speeds[k], StopAssist.STOP_SPEED])
	for hold: float in [Missions.HOLD_TIME, TrendJob.PICKUP_HOLD, Rides.BOARD_HOLD]:
		if hold > StopAssist.HOLD - 0.5:
			_problems.append("a quest hold of %.1f s is not well under the assist's %.1f s" % [hold, StopAssist.HOLD])


func _physics_process(delta: float) -> bool:
	if _i < 0 or _t >= float(_test["dur"]):
		if _i >= 0:
			_finish()
		_i += 1
		if _i >= _tests.size():
			return _summary()
		_start()
	_step(delta)
	_t += delta
	return false


func _start() -> void:
	_test = _tests[_i]
	_t = 0.0
	_world = Node3D.new()
	root.add_child(_world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(600, 1, 600)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_car = Car.new()
	_world.add_child(_car)
	_car.global_position = _test["start"]
	var v: float = _test["v"]
	# Heading north (-z): the car's forward.
	_car.vel = Vector3(0, 0, -v)
	_car.forward_speed = v
	_car.assist_at = _test["ring"]
	_car.assist_reach = StopAssist.RING
	_log = {"min_v": INF, "assisted": false, "rest_at": -1.0, "rest_d": INF, "still": 0.0, "best_still": 0.0, "end_v": 0.0, "min_fwd": INF}


func _step(_dt: float) -> void:
	var want: String = _test["want"]
	if want == "reverse":
		_car.throttle = 0.0
		_car.braking = true
	else:
		# The gas held at the speed it came in at (a share of top speed), as a finger left on the stick.
		_car.throttle = clampf(float(_test["v"]) / _car.max_speed, 0.0, 1.0)
		_car.braking = false
	var v := _car.vel.length()
	_log["min_v"] = minf(_log["min_v"], v)
	_log["min_fwd"] = minf(_log["min_fwd"], _car.forward_speed if _t > 0.2 else INF)
	_log["end_v"] = v
	if _car.assisting:
		_log["assisted"] = true
	var ring: Vector3 = _test["ring"]
	if ring != Vector3.INF:
		var d := Vector2(_car.global_position.x - ring.x, _car.global_position.z - ring.z).length()
		if v < StopAssist.STOP_SPEED and d < StopAssist.RING:
			_log["still"] += _dt
			_log["best_still"] = maxf(_log["best_still"], _log["still"])
			if _log["rest_at"] < 0.0:
				_log["rest_at"] = _t
				_log["rest_d"] = d
		else:
			_log["still"] = 0.0


func _finish() -> void:
	var name: String = _test["name"]
	var want: String = _test["want"]
	var line := "%s: " % name
	var bad := ""
	match want:
		"stop":
			line += "in the ring and stopped at %.1f s, %.1f m from the centre, held %.1f s, end speed %.0f km/h" % [
					_log["rest_at"], _log["rest_d"], _log["best_still"], _log["end_v"] * 3.6]
			if _log["rest_at"] < 0.0:
				bad = "never stopped in the ring"
			elif _log["best_still"] < QUEST_HOLD + 0.2:
				bad = "held only %.1f s (a quest needs %.1f)" % [_log["best_still"], QUEST_HOLD]
			elif _log["end_v"] < 3.0:
				bad = "never let go (the gas is held)"
		"free":
			line += "slowest %.0f km/h, assist %s" % [_log["min_v"] * 3.6, "ON" if _log["assisted"] else "off"]
			if _log["assisted"] or _log["min_v"] < float(_test["v"]) * 0.9:
				bad = "the assist touched a car not heading into the ring"
		"reverse":
			line += "slowest forward speed %.1f m/s" % _log["min_fwd"]
			if _log["min_fwd"] > -0.5:
				bad = "BRAKE at a standstill in the ring did not reverse out"
	if bad != "":
		_problems.append("%s: %s" % [name, bad])
		line += "  <-- " + bad
	print("  " + line)
	_world.queue_free()
	_world = null
	_car = null


func _summary() -> bool:
	if _problems.is_empty():
		print("check_stop_assist: OK")
		quit(0)
	else:
		for p in _problems:
			print("check_stop_assist: PROBLEM: " + p)
		quit(1)
	return true
