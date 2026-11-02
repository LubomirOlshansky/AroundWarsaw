extends Node3D
## City-life satire #1 (F, 2026-11-02; docs/design/city-life-satire.md 1): "loaded rides". A car
## meet at Browary Warszawskie, a row of generic supercars (no marque, no badge: models.gd
## spec "supercar", the taxis' family shape TAXI_SUPERCAR) parked on the paving west of
## Haberbuscha i Schielego by the Grzybowska gate, people round them with their phones (crowds.gd
## kind `meet`, the figures there), and a few loud supercars in the traffic (traffic.gd `loud`,
## at most `loud_target` at once): when one passes near the view it revs (`loud_rev`, tools/
## make_sfx.py, original synthesis), now and then its driver says a `loud_driver` line, and KEBAB
## FM's host reads a `radio_host` line tagged "loud" ("Sąsiedzi znów liczą obroty") at most once
## every RADIO_GAP seconds. At the meet a parked car revs every MEET_REV seconds while the view is
## near and the crowd answers (`car_meet` lines tagged "rev").
##
## Drawing: the meet's cars are one MultiMesh of the taxis' family mesh in the actors' material
## (models.gd), one draw call while the meet is in view (culled by its own box otherwise), and at
## night one more for their headlight pools (in the `night_lights` group, as traffic's); the
## loud cars are in traffic's taxi MultiMesh (no draw call). The cars stop the player's car (a
## box each in one static body). Everything else ticks at TICK (4 Hz): no per-frame work.

const Models := preload("res://scripts/models.gd")

## Haberbuscha i Schielego from Grzybowska (FRAME_O) south through the Browary: `s` metres along
## it (FRAME_S), `t` metres to its east (FRAME_T). The street is a 2.75 m living street; west of it
## (t -4 to -16, s 0 to 22) is the paved gate square in front of Biura przy Bramie (clear of
## every building outline by 2 m or more: check_loud_cars.gd).
const FRAME_O := Vector2(-2523.9, -32.4)
const FRAME_S := Vector2(-0.24516, -0.96948)
const FRAME_T := Vector2(0.96948, -0.24516)
## The meet: [s, t, heading (degrees from the street's direction, + towards the street's east),
## paint]. The front row noses towards the street at an angle, as cars on show stand, round the
## square's two trees (s 7.9 and 18.6); the back row stands along it.
const MEET := [
	[2.6, -6.4, 40.0, "#a6e22e"],
	[12.4, -6.4, 40.0, "#1a1a1d"],
	[23.6, -6.4, 40.0, "#e8f03a"],
	[2.6, -11.8, 180.0, "#f4f1ea"],
	[8.2, -11.8, 180.0, "#ff5fb4"],
	[13.8, -11.8, 180.0, "#16a39a"],
	[19.6, -12.2, 180.0, "#7b3fd1"],
]
## People per car in the meet's crowd (crowds.gd `meet`), MEET_RING m from its middle.
const PER_CAR := 3
const MEET_RING := 2.4
## The meet is heard and revs within this of the view's focus (m).
const MEET_NEAR := 80.0
const MEET_REV := Vector2(9.0, 16.0)
## A loud car revs when it passes within REV_NEAR m of the view's focus, then not for REV_GAP s.
const REV_NEAR := 45.0
const REV_GAP := Vector2(7.0, 12.0)
## The chance that a loud car's driver says a line the first time it revs near the view.
const DRIVER_SAYS := 0.4
## KEBAB FM's "loud" line: at most once in this many seconds, after a rev near the view.
const RADIO_GAP := 600.0
const TICK := 0.25
const BUBBLE := Color("#a6e22e")
const SOUND := "loud_rev"

var traffic: Node
var sfx: Node
var dialogue: Node
var radio: Node
var map: Node3D
## -> Vector3: the view's focus (the ear).
var focus: Callable
var log_on := false
## Counters for the checks and the log.
var revs := 0
var meet_revs := 0
var driver_lines := 0
var radio_lines := 0

var _t := 0.0
var _rng := RandomNumberGenerator.new()
## Driver -> seconds until it may rev again; Driver -> true once it has had its chance to talk.
var _wait := {}
var _talked := {}
var _meet_wait := 4.0
var _radio_wait := 0.0
var _meet: MultiMeshInstance3D


func setup() -> void:
	_rng.seed = 2029
	_build_meet()


## A point of the frame.
static func at(s: float, t: float) -> Vector2:
	return FRAME_O + FRAME_S * s + FRAME_T * t


## The meet's cars: [where (x, z), yaw (traffic.gd's: the car's front, -Z, turned to it), paint].
static func meet_cars() -> Array:
	var out: Array = []
	for c: Array in MEET:
		var a := deg_to_rad(float(c[2]))
		var f := FRAME_S * cos(a) + FRAME_T * sin(a)
		out.append([at(float(c[0]), float(c[1])), atan2(-f.x, -f.y), Color(c[3])])
	return out


## The meet's crowd: PER_CAR spots round each car, MEET_RING m off its sides and ends (the ones
## farthest from the street: the paving side), each facing the car's middle, in an order that
## spreads a small crowd over every car.
static func meet_slots() -> Array:
	var cars := meet_cars()
	var size: Vector3 = Models.TRAFFIC[1][Models.TAXI_SUPERCAR]["size"]
	var per: Array = []
	for c: Array in cars:
		var mid: Vector2 = c[0]
		var yaw: float = c[1]
		var fwd := Vector2(-sin(yaw), -cos(yaw))
		var right := Vector2(cos(yaw), -sin(yaw))
		var side := size.x * 0.5 + MEET_RING - 1.4
		var end := size.z * 0.5 + MEET_RING - 1.6
		var round_car: Array = []
		for q: Vector2 in [mid + right * side + fwd * 0.6, mid + right * side - fwd * 0.9, mid - right * side + fwd * 0.5,
				mid - right * side - fwd * 0.7, mid - fwd * end + right * 0.3, mid + fwd * end - right * 0.3]:
			var free := true
			for o: Array in cars:
				free = free and not _in_car(q, o, size, 0.45)
			if free:
				round_car.append(q)
		round_car.sort_custom(func(a: Vector2, b: Vector2) -> bool: return (a - FRAME_O).dot(FRAME_T) < (b - FRAME_O).dot(FRAME_T))
		per.append([mid, round_car])
	var out: Array = []
	for k in PER_CAR:
		for pc: Array in per:
			if k >= (pc[1] as Array).size():
				continue
			var p: Vector2 = pc[1][k]
			var to: Vector2 = (pc[0] as Vector2) - p
			out.append({"p": p, "yaw": atan2(-to.x, -to.y)})
	return out


## Whether `q` is inside car `c` ([where, yaw, ...]) of `size`, its footprint grown by `grow`.
static func _in_car(q: Vector2, c: Array, size: Vector3, grow: float) -> bool:
	var rel := q - (c[0] as Vector2)
	var yaw: float = c[1]
	return absf(rel.dot(Vector2(-sin(yaw), -cos(yaw)))) < size.z * 0.5 + grow \
			and absf(rel.dot(Vector2(cos(yaw), -sin(yaw)))) < size.x * 0.5 + grow


## The meet's middle (x, z).
static func meet_centre() -> Vector2:
	return at(11.0, -8.0)


func _build_meet() -> void:
	var cars := meet_cars()
	var size: Vector3 = Models.TRAFFIC[1][Models.TAXI_SUPERCAR]["size"]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = Models.traffic_mesh(1)
	mm.instance_count = cars.size()
	var body := StaticBody3D.new()
	body.name = "MeetSolids"
	for i in cars.size():
		var p: Vector2 = cars[i][0]
		var y: float = map.ground_height(p.x, p.y) if map != null else 0.0
		var xf := Transform3D(Basis(Vector3.UP, float(cars[i][1])), Vector3(p.x, y, p.y))
		mm.set_instance_transform(i, xf)
		var paint: Color = cars[i][2]
		mm.set_instance_custom_data(i, Color(paint.r, paint.g, paint.b, float(Models.TAXI_SUPERCAR)))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * size.y * 0.5)
		body.add_child(shape)
	_meet = MultiMeshInstance3D.new()
	_meet.name = "CarMeet"
	_meet.multimesh = mm
	_meet.material_override = Models.material()
	_meet.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_meet)
	add_child(body)
	# At night the cars on show keep their headlights on: traffic's headlight pools, one more
	# MultiMesh in the night lights (hidden by day, as the traffic's own).
	var beam := MultiMesh.new()
	beam.transform_format = MultiMesh.TRANSFORM_3D
	beam.use_custom_data = true
	beam.mesh = Models.headlight_pools(size.z * 0.5, 0.6, 11.0)
	beam.instance_count = cars.size()
	for i in cars.size():
		beam.set_instance_transform(i, mm.get_instance_transform(i))
		beam.set_instance_custom_data(i, mm.get_instance_custom_data(i))
	var bmi := MultiMeshInstance3D.new()
	bmi.name = "CarMeetLights"
	bmi.multimesh = beam
	bmi.material_override = Models.glow_material()
	bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	bmi.visible = false
	bmi.add_to_group("night_lights")
	add_child(bmi)


func _process(dt: float) -> void:
	_t += dt
	if _t < TICK:
		return
	step(_t)
	_t = 0.0


## One tick of `dt` seconds: the loud cars near the ear rev, the meet revs.
func step(dt: float) -> void:
	if not focus.is_valid():
		return
	var ear: Vector3 = focus.call()
	var ear2 := Vector2(ear.x, ear.z)
	_radio_wait = maxf(_radio_wait - dt, 0.0)
	if traffic != null:
		_loud_cars(ear2, dt)
	_meet_step(ear2, dt)


func _loud_cars(ear2: Vector2, dt: float) -> void:
	var seen := {}
	for d in traffic.drivers():
		if not d.loud:
			continue
		seen[d] = true
		var w := float(_wait.get(d, 0.0)) - dt
		_wait[d] = w
		if w > 0.0 or Vector2(d.pos.x, d.pos.z).distance_to(ear2) > REV_NEAR or d.clip < 0.5:
			continue
		_wait[d] = _rng.randf_range(REV_GAP.x, REV_GAP.y)
		revs += 1
		if sfx != null:
			sfx.play_at(SOUND, d.pos + Vector3.UP * 0.5)
		_log("rev at %.0f, %.0f" % [d.pos.x, d.pos.z])
		if not _talked.has(d):
			_talked[d] = true
			if d.visible and _rng.randf() < DRIVER_SAYS and _say_over(d, "loud_driver", ""):
				driver_lines += 1
		_announce()
	# Forget the cars that left (the pool reuses their drivers).
	for d in _wait.keys():
		if not seen.has(d):
			_wait.erase(d)
			_talked.erase(d)


func _meet_step(ear2: Vector2, dt: float) -> void:
	if ear2.distance_to(meet_centre()) > MEET_NEAR:
		return
	_meet_wait -= dt
	if _meet_wait > 0.0:
		return
	_meet_wait = _rng.randf_range(MEET_REV.x, MEET_REV.y)
	var cars := meet_cars()
	var c: Array = cars[_rng.randi() % cars.size()]
	var p: Vector2 = c[0]
	var y: float = map.ground_height(p.x, p.y) if map != null else 0.0
	var at3 := Vector3(p.x, y, p.y)
	meet_revs += 1
	if sfx != null:
		sfx.play_at(SOUND, at3 + Vector3.UP * 0.5, -2.0)
	if dialogue != null:
		var anchor := func() -> Vector3: return at3 + Vector3(0.0, 1.6, 0.0)
		dialogue.say_ambient(anchor, "", "car_meet", "rev" if _rng.randf() < 0.5 else "", 3.6, BUBBLE, 2.2, true)
	_log("meet rev")


## A line over a moving traffic car (its position each frame while the bubble shows).
func _say_over(d: Object, group: String, tag: String) -> bool:
	if dialogue == null:
		return false
	var anchor := func() -> Vector3:
		return (d.pos as Vector3) + Vector3(0.0, 1.4, 0.0) if d.active and d.loud else Vector3.INF
	return not dialogue.say_ambient(anchor, "", group, tag, 3.4, BUBBLE, 2.0, true).is_empty()


## KEBAB FM's host: the neighbours are counting the revs again (once per RADIO_GAP, a station on).
func _announce() -> void:
	if _radio_wait > 0.0 or radio == null or dialogue == null or radio.station < 0:
		return
	var l: Array = dialogue.line("radio_host", "loud", true)
	if l.is_empty() or dialogue.notes(l).get("only", "") != "loud":
		return
	_radio_wait = RADIO_GAP
	radio_lines += 1
	radio.announce(String(l[0]), String(l[1]))
	_log("radio: %s" % l[0])


func _log(text: String) -> void:
	if log_on:
		print("loud: %s" % text)
