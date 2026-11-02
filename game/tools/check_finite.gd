extends SceneTree
## The NaN car (BACKLOG "From loop 3h slice 4"): every number the player's car and the traffic
## take from the map is a number. Once in ~10 first-10 replays the car's position went NaN; the
## car puts itself back (car.gd `_keep_finite`), and this check looks for a source in the data:
##
##  1. The heights the car drives on (map_builder.gd terrain_height, ground_height, drive_height
##     at the street, a deck's and a tunnel's level, tunnel_floor_under) on a STEP grid over the
##     whole map, and densely (every DENSE m along and across) in every deck, tunnel, approach
##     fill and apron corridor, where the divisions are (a segment's length, an apron's blend).
##  2. Every lane of the lane graph (lane_graph.gd point_at, height, direction every LANE_STEP m)
##     and every junction curve a car can take (connector, bezier_length and its points).
##  3. The car itself (car.gd `_step`) driven by the real map heights with the stick pointed every
##     way, full gas and the brake, at a standstill and at speed, and with every input zero; and
##     the safety net: a NaN written into its stick, steering, pedal or position is
##     dropped or put back (car.gd `_clean_inputs`, `_keep_finite`) and the car drives on.
##
## Prints the first findings and `check_finite: OK` when every number is finite, else the count
## and exit 1. From the map index alone (no sector built), ~1 min.
##   godot --headless --path game --script res://tools/check_finite.gd [-- --step=M]

const MapBuilder := preload("res://scripts/map_builder.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Car := preload("res://scripts/car.gd")
const INDEX_JSON := "res://map/index.json"

const STEP := 8.0
const DENSE := 1.0
const LANE_STEP := 2.0
const SHOW := 12

var map: Node3D
var graph: LaneGraph
var step := STEP
var bad := 0
var samples := 0
var _frames := 0
var _cars: Array[Car] = []
var _cases: Array = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--step="):
			step = float(a.trim_prefix("--step="))
	var t0 := Time.get_ticks_msec()
	if not FileAccess.file_exists(INDEX_JSON):
		print("check_finite: no map/index.json: run tools/setup_map.sh once")
		quit(1)
		return
	map = MapBuilder.new()
	root.add_child(map)
	map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	graph = LaneGraph.new(map.data["graph"], map)
	print("check_finite: the map index opened in %d ms" % (Time.get_ticks_msec() - t0))
	t0 = Time.get_ticks_msec()
	_heights()
	print("check_finite: %d height samples in %d ms" % [samples, Time.get_ticks_msec() - t0])
	t0 = Time.get_ticks_msec()
	var before := samples
	_lanes()
	print("check_finite: %d lane and junction samples in %d ms" % [samples - before, Time.get_ticks_msec() - t0])


func _bad(what: String) -> void:
	bad += 1
	if bad <= SHOW:
		print("  not a number: " + what)


# --- 1. the heights -------------------------------------------------------------------------

func _at(x: float, z: float) -> void:
	samples += 1
	var t: float = map.terrain_height(x, z)
	var g: float = map.ground_height(x, z)
	if not is_finite(t) or not is_finite(g):
		_bad("terrain %s / ground %s at --at=%.2f,%.2f" % [t, g, x, z])
		return
	for near_y: float in [t, g, t + 8.0, t - 12.0]:
		var d: float = map.drive_height(x, z, near_y)
		if not is_finite(d):
			_bad("drive_height %s at --at=%.2f,%.2f from y %.2f" % [d, x, z, near_y])
	var u: float = map.tunnel_floor_under(x, z)
	if not is_nan(u) and not is_finite(u):
		_bad("tunnel_floor_under %s at --at=%.2f,%.2f" % [u, x, z])


func _heights() -> void:
	var b: Rect2 = map.bounds
	var z := b.position.y
	while z <= b.end.y:
		var x := b.position.x
		while x <= b.end.x:
			_at(x, z)
			x += step
		z += step
	# The corridors, densely: decks, tunnels and approach fills (polylines with a left and right
	# width), and the aprons (a start, a direction and a length).
	for list: Array in [map._decks, map._tunnels, map._fills]:
		for d: Dictionary in list:
			var pts: PackedVector2Array = d["pts"]
			var l := float(d["l"]) + 2.0
			var r := float(d["r"]) + 2.0
			for k in pts.size() - 1:
				var a := pts[k]
				var ab := pts[k + 1] - a
				var length := ab.length()
				var dir := ab / length if length > 0.0 else Vector2.RIGHT
				var right := Vector2(-dir.y, dir.x)
				var s := -1.0
				while s <= length + 1.0:
					var lat := -l
					while lat <= r:
						var p := a + dir * s + right * lat
						_at(p.x, p.y)
						lat += DENSE * 2.0
					s += DENSE
				# The vertices themselves (a zero-length step lands exactly on them).
				_at(a.x, a.y)
	for a: PackedFloat32Array in map._aprons:
		var o := Vector2(a[0], a[1])
		var dir := Vector2(a[2], a[3])
		var right := Vector2(-dir.y, dir.x)
		var s := -1.0
		while s <= a[4] + 1.0:
			var lat := -a[6] - MapBuilder.APRON_TAPER - 1.0
			while lat <= a[7] + MapBuilder.APRON_TAPER + 1.0:
				var p := o + dir * s + right * lat
				_at(p.x, p.y)
				lat += DENSE * 2.0
			s += DENSE
		# Exactly at the hold's end and at the apron's end (the blend's divisions).
		for s2: float in [0.0, a[8], a[4]]:
			var p := o + dir * s2
			_at(p.x, p.y)


# --- 2. the lanes and the junction curves ---------------------------------------------------

func _lanes() -> void:
	for e in graph.e_a.size():
		var length := graph.e_len[e]
		for k in graph.e_lanes[e]:
			var off := graph.lane_offset(e, k)
			var s := 0.0
			while true:
				samples += 1
				var p := graph.point_at(e, s, off)
				var h := graph.height(e, s)
				var dir := graph.direction(e, s)
				if not p.is_finite() or not is_finite(h) or not dir.is_finite():
					_bad("lane %d/%d at s %.2f: point %s, height %s, direction %s" % [e, k, s, p, h, dir])
				if s >= length:
					break
				s = minf(s + LANE_STEP, length)
		# Every junction curve out of every lane, as traffic.gd _choose_next and turn_next build them.
		var outs: PackedInt32Array = graph.node_out[graph.e_b[e]]
		for k in graph.e_lanes[e]:
			for f in outs:
				samples += 1
				var j := graph.next_lane(e, k, f)
				var c := graph.connector(e, k, f, j)
				var cl := LaneGraph.bezier_length(c)
				var ok := is_finite(cl) and cl > 0.0
				for q in c:
					ok = ok and q.is_finite()
				for i in 9:
					ok = ok and LaneGraph.bezier(c, i / 8.0).is_finite()
				if not ok:
					_bad("junction curve %d/%d -> %d/%d: %s, length %s" % [e, k, f, j, c, cl])


# --- 3. the car's own step ------------------------------------------------------------------

## Every case's car at once (collision off: they don't meet), CAR_FRAMES physics frames each.
const CAR_FRAMES := 90
## The NaNs written into a car at frame POISON_AT: where.
const POISONS := ["target_dir", "steer", "throttle", "position"]
const POISON_AT := 20


func _physics_process(_dt: float) -> bool:
	_frames += 1
	if _frames < 2:
		return false
	if _cases.is_empty():
		_make_cases()
		for c in _cases:
			_cars.append(_start(c))
	for k in _cars.size():
		_drive(_cars[k], _cases[k], _frames)
	if _frames < CAR_FRAMES + 2:
		return false
	for k in _cars.size():
		_judge(_cars[k], k)
		_cars[k].free()
	_cars.clear()
	print("check_finite: %d car cases driven %d frames" % [_cases.size(), CAR_FRAMES])
	print("check_finite: %s" % ("OK" if bad == 0 else "%d FAILED" % bad))
	map.free()
	quit(0 if bad == 0 else 1)
	return true


## [at, speed, target_dir, steer, throttle, braking]: spots on the street, a deck and a tunnel's
## floor (the first of each the map has), every input way.
func _make_cases() -> void:
	var spots: Array[Vector3] = []
	var b: Rect2 = map.bounds
	spots.append(Vector3(b.get_center().x, 0.0, b.get_center().y))
	for list: Array in [map._decks, map._tunnels]:
		if not list.is_empty():
			var pts: PackedVector2Array = (list[0] as Dictionary)["pts"]
			var m := pts[0].lerp(pts[pts.size() - 1], 0.5)
			spots.append(Vector3(m.x, 1.0 if list == map._tunnels else 0.0, m.y))
	var dirs: Array[Vector3] = [Vector3.ZERO, Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3(1, 0, 1).normalized()]
	for at in spots:
		for speed: float in [0.0, 25.0, -5.0]:
			for d in dirs:
				for brake: bool in [false, true]:
					_cases.append([at, speed, d, 0.0, 1.0, brake])
			_cases.append([at, speed, Vector3.ZERO, 1.0, 0.0, false])
			_cases.append([at, speed, Vector3.ZERO, -1.0, 1.0, true])
	# The safety net (car.gd `_clean_inputs`, `_keep_finite`): a NaN written into the car's stick,
	# steering, pedal or position (as a test driver copying a bad ghost would) is dropped or put
	# back, and the car drives on with numbers.
	for poison: String in POISONS:
		_cases.append([spots[0], 10.0, Vector3.FORWARD, 0.0, 1.0, false, poison])


func _start(c: Array) -> Car:
	var at: Vector3 = c[0]
	var car := Car.new()
	car.ground_height = map.drive_height
	car.water_at = func(_x: float, _z: float, _y: float) -> bool: return false
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	var y: float = map.ground_height(at.x, at.z)
	if at.y > 0.5:
		var u: float = map.tunnel_floor_under(at.x, at.z)
		y = u if not is_nan(u) else y
	car.global_position = Vector3(at.x, y, at.z)
	car.collision_mask = 0
	car.vel = -car.global_transform.basis.z * float(c[1])
	car.forward_speed = float(c[1])
	return car


func _drive(car: Car, c: Array, frame: int) -> void:
	car.target_dir = c[2]
	car.steer = NAN if car.has_meta("nan_steer") and frame < POISON_AT + 10 else float(c[3])
	car.throttle = float(c[4])
	car.braking = bool(c[5])
	# The stop assist's ring right on the car (the replay's pickup): its distance is 0.
	car.assist_at = car.global_position if frame > 30 and c.size() < 7 else Vector3.INF
	if c.size() < 7 or frame != POISON_AT:
		return
	car.nan_quiet = true
	match String(c[6]):
		"target_dir": car.target_dir = Vector3(NAN, 0.0, NAN)
		"steer":
			car.target_dir = Vector3.ZERO
			car.steer = NAN
		"throttle": car.throttle = NAN
		"position": car.global_position = Vector3(NAN, NAN, NAN)
	if String(c[6]) != "steer":
		return
	# A NaN steer is read once (the next frame's _drive writes a number again): hold it there.
	car.set_meta("nan_steer", true)


func _judge(car: Car, k: int) -> void:
	samples += 1
	var x := car.global_transform
	var poisoned: bool = (_cases[k] as Array).size() >= 7
	if poisoned:
		# Recovered (at least once) and driving again: the gas is on, so it moved on after.
		if int(car.nan_recoveries) == 0 or not x.origin.is_finite() or not x.basis.z.is_finite() \
				or not car.vel.is_finite() or car.vel.length() < 1.0:
			_bad("the safety net, %s: at %s, vel %s, %d recoveries" % [_cases[k][6], x.origin, car.vel, int(car.nan_recoveries)])
		return
	if int(car.nan_recoveries) > 0 or not x.origin.is_finite() or not x.basis.z.is_finite() \
			or not car.vel.is_finite() or not is_finite(car.steer_now) or not is_finite(car.yaw_rate):
		_bad("the car (case %d %s): at %s, vel %s, steer_now %s, %d recoveries" % [k, _cases[k], x.origin,
				car.vel, car.steer_now, int(car.nan_recoveries)])
