extends SceneTree
## G4 (F, 2026-11-01: "very drifty and sensitive, this is a city, not a racer"): the real car script
## on a flat test ground in both handling profiles (car.gd PROFILES). Cruise must hold the road:
## a lane change at 50 km/h and a 90 degree corner at 25 km/h with full lock held keep the
## sideways speed (`slip`) under CRUISE_SLIP, and braking hard from 90 km/h with the wheel
## straight does not swing the tail. Sport keeps the old feel (it may slide more than Cruise, and
## the profile numbers differ), the profile switch round-trips, and the gas pulls away more softly
## in Cruise. Exits 1 on a problem.
##
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_handling.gd

const Car := preload("res://scripts/car.gd")
const KMH := 1.0 / 3.6
## The most sideways speed (m/s) Cruise may show in the tests below.
const CRUISE_SLIP := 1.2

var _problems: Array[String] = []
var _world: Node3D
var _car: Car
var _frames := 0
var _stage := 0
var _profile := 0
var _max_slip := 0.0
var _case := 0
var _results := {}

## name, speed (km/h), steering held (-1..1) for the first `hold` s, duration s, brake from 2 s
const CASES := [
	{"name": "lane change 50 km/h", "kmh": 50.0, "steer": 1.0, "hold": 0.6, "dur": 2.5, "brake": false},
	{"name": "90 degree corner 25 km/h", "kmh": 25.0, "steer": 1.0, "hold": 1.2, "dur": 3.0, "brake": false},
	{"name": "full lock 50 km/h", "kmh": 50.0, "steer": 1.0, "hold": 2.0, "dur": 3.0, "brake": false},
	{"name": "hard brake 90 km/h", "kmh": 90.0, "steer": 0.0, "hold": 0.0, "dur": 2.5, "brake": true},
]


func _initialize() -> void:
	# The profile numbers: Cruise holds the road harder and turns less sharply than Sport.
	var c: Dictionary = Car.PROFILES[Car.Handling.CRUISE]
	var s: Dictionary = Car.PROFILES[Car.Handling.SPORT]
	if not (c["grip"] > s["grip"] and c["drift_grip"] > s["drift_grip"] and c["turn_pull"] < s["turn_pull"] \
			and c["turn_cap"] < s["turn_cap"] and c["steer_time"] > s["steer_time"] and c["onset"] < s["onset"]):
		_problems.append("Cruise is not softer than Sport in every number")
	var probe := Car.new()
	probe.set_handling(Car.Handling.SPORT)
	if probe.grip != s["grip"] or probe.handling != Car.Handling.SPORT:
		_problems.append("set_handling(SPORT) did not set the numbers")
	probe.set_handling(Car.Handling.CRUISE)
	if probe.grip != c["grip"] or probe.handling != Car.Handling.CRUISE:
		_problems.append("set_handling(CRUISE) did not set the numbers")
	probe.set_handling(99)
	if probe.handling != Car.Handling.CRUISE:
		_problems.append("an unknown profile did not fall back to Cruise")
	probe.free()
	var fresh := Car.new()
	if fresh.handling != Car.Handling.CRUISE:
		_problems.append("a new car is not in Cruise")
	fresh.free()
	_begin()


func _begin() -> void:
	if _world != null:
		_world.queue_free()
	_world = Node3D.new()
	root.add_child(_world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000, 1, 2000)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0, -0.5, 0)
	_world.add_child(floor_body)
	_car = Car.new()
	_car.set_handling(_profile)
	_world.add_child(_car)
	var cs: Dictionary = CASES[_case]
	var v: float = float(cs["kmh"]) * KMH
	_car.vel = Vector3(0, 0, -v)
	_car.forward_speed = v
	_frames = 0
	_max_slip = 0.0


func _physics_process(dt: float) -> bool:
	var cs: Dictionary = CASES[_case]
	var t := _frames * dt
	_frames += 1
	_car.throttle = clampf(float(cs["kmh"]) * KMH / _car.max_speed, 0.0, 1.0)
	_car.steer = float(cs["steer"]) if t < float(cs["hold"]) else 0.0
	_car.braking = bool(cs["brake"]) and t > 0.3
	if t > 0.3:
		_max_slip = maxf(_max_slip, _car.slip)
	if t < float(cs["dur"]):
		return false
	_results["%d/%s" % [_profile, cs["name"]]] = _max_slip
	print("  %s %-26s max slip %.2f m/s" % ["Cruise" if _profile == 0 else "Sport ", cs["name"], _max_slip])
	_case += 1
	if _case >= CASES.size():
		_case = 0
		_profile += 1
		if _profile > 1:
			return _finish()
	_begin()
	return false


func _finish() -> bool:
	# Freed now, not queued: nothing is left alive when the script quits (verify.sh fails on leak warnings).
	_world.free()
	for cs in CASES:
		var cr: float = _results["0/%s" % cs["name"]]
		var sp: float = _results["1/%s" % cs["name"]]
		if cr > CRUISE_SLIP:
			_problems.append("Cruise %s slides %.2f m/s (limit %.1f)" % [cs["name"], cr, CRUISE_SLIP])
		if cr > sp + 0.01:
			_problems.append("Cruise %s slides more than Sport (%.2f vs %.2f)" % [cs["name"], cr, sp])
	# The gas: a quarter push for 1 s reaches a lower speed in Cruise than in Sport.
	var cruise_v := _pull_away(Car.Handling.CRUISE)
	var sport_v := _pull_away(Car.Handling.SPORT)
	print("  quarter gas for 1 s: Cruise %.1f m/s, Sport %.1f m/s" % [cruise_v, sport_v])
	if cruise_v >= sport_v:
		_problems.append("Cruise does not pull away more softly (%.1f vs %.1f m/s)" % [cruise_v, sport_v])
	if _problems.is_empty():
		print("check_handling: OK")
		quit(0)
	else:
		for p in _problems:
			printerr("check_handling: " + p)
		print("check_handling: %d PROBLEM(S)" % _problems.size())
		quit(1)
	return true


func _pull_away(h: int) -> float:
	var car := Car.new()
	car.set_handling(h)
	car.throttle = 0.25
	var v := 0.0
	for i in 60:
		v = v + car.accel * (car.onset + (1.0 - car.onset) * 0.25) * (1.0 / 60.0) * (1.0 - 0.6 * clampf(v / car.max_speed, 0.0, 1.0))
	car.free()
	return v
