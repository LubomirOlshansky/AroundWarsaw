extends Node
## Side jobs (v0.65): kebab delivery and the słoiki run.
##
## Kebab: stands at real places (the mapped kebab places and a few busy corners,
## `kebab` pois) glow on the minimap and wear a ring on the road. Pull into one and
## the vendor hands over an order for a real address 400-1500 m away by road
## (sometimes across the river, "basically the centre"). There is no hard clock: a
## heat meter (the steam over the kebab) fades as you drive, the tip goes with the
## heat, nights pay more. The customer waits at the door and says how it arrived.
##
## Słoiki: Sunday evening at Dworzec Centralny, a newcomer with mum's jars needs a
## lift to a rented flat in Powiśle. Hard bumps (the car's closing speed), heavy
## braking and fast corners stress the jars; too much and one breaks. Careful
## driving at speed is fine. The passenger talks on the way; the fare goes by the
## jars that arrive whole.
##
## One activity at a time: a job starts only when no rescue or race runs (and not
## from the helicopter); while it runs, rescue calls and race challenges wait.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Beacon := preload("res://scripts/beacon.gd")
const Models := preload("res://scripts/models.gd")
const Props := preload("res://scripts/props.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

const KEBAB_COLOUR := Color("#ff8a3d")
const SLOIK_COLOUR := Color("#4fd8c4")
const FAIL_COLOUR := Color("#e2574c")
const PULL_IN := 7.0          # stop in this ring to start a job...
const PULL_IN_SPEED := 8.0    # ...going slower than this (m/s): pulling in, not passing
const ARRIVE := 7.0           # the door's ring
const ARRIVE_SPEED := 2.5
const ORDER_MIN := 400.0
const ORDER_MAX := 1500.0
## Across the river it is "basically the centre": the customer's word, not the map's.
## (Rondo Dmowskiego to the Saska Kępa streets is 3-3.9 km by road, round by Rondo
## Waszyngtona just off the map.)
const ACROSS_MAX := 3600.0
const JARS := 6
const NIGHT_BONUS := 1.5
## Jar stress: braking harder than this (m/s²), and cornering harder than this
## (lateral m/s²), add to it; a bump adds by its closing speed above BUMP_FREE.
const BRAKE_FREE := 16.0
const CORNER_FREE := 14.0
const BUMP_FREE := 3.0
const CUSTOMERS := ["Ania", "Kasia", "Ola", "Magda", "Zosia", "Ewa", "Basia", "Marta",
		"Tomek", "Kuba", "Piotrek", "Michał", "Paweł", "Marek", "Wojtek", "Krzysiek"]
const NEWCOMERS := ["Kuba", "Ola", "Bartek", "Kasia", "Michał", "Magda"]

enum Job { NONE, KEBAB, SLOIK }
enum State { IDLE, ORDER, DELIVER, RESULT }

var hud: CanvasLayer
var bubbles: Control
var dialogue: Node
var wallet: Node
var missions: Node
var rivals: Node
var graph: LaneGraph
var traffic: Node3D
var map: Node3D
var car: CharacterBody3D
var tod: Node
var state := State.IDLE
var job := Job.NONE
## How long the last update took, for --bench.
var last_usec := 0
## Set by the game each frame.
var flying := false
## Testing (--autopilot): drive the job's route on a ghost driver.
var autopilot := false
## Testing: the kebab's starting heat (--heat=), jars already broken (--sloik=K).
var start_heat := 1.0
var start_broken := 0

## Stands: {ring: Vector3, at: Vector3, yaw, heading, node, marker, cool, across}.
var _stands: Array[Dictionary] = []
## The station pick-up: {ring, at, yaw, heading, person, marker, cool}.
var _station: Dictionary = {}
## Addresses: {name, door: Vector2, at: Vector2, office, d}.
var _addresses: Array[Dictionary] = []
var _order: Dictionary = {}
var _orders := 0
var _t := 0.0
var _clock := 0.0
var _heat := 1.0
var _jars := JARS
var _stress := 0.0
var _brake_s := 0.0
var _lat_s := 0.0
var _last_v := 0.0
var _last_yaw := 0.0
var _have_last := false
var _bump_wait := 0.0
var _warn_wait := 0.0
var _chat_t := 0.0
var _said_order := false
var _beacon: Node3D
var _ghost = null
var _slide := false
var _stall := 0.0
var _ring_mats := {}
var _stand_halo: ArrayMesh
var _halo_mat: ShaderMaterial
var _places_shown := false
var _rng := RandomNumberGenerator.new()


func setup(nodes: Dictionary, data: Dictionary, world: Node3D) -> void:
	hud = nodes["hud"]
	bubbles = nodes["bubbles"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	missions = nodes["missions"]
	rivals = nodes["rivals"]
	graph = nodes["graph"]
	traffic = nodes["traffic"]
	map = nodes["map"]
	car = nodes["car"]
	tod = nodes["tod"]
	_rng.randomize()
	var t0 := Time.get_ticks_msec()
	var stand_mesh := Props.kebab_stand()
	_stand_halo = Props.halo(7.5, Color(1.0, 0.5, 0.25, 0.5))
	_halo_mat = Props.glow_material(true)
	for p in data.get("pois", []):
		match String(p["k"]):
			"kebab":
				_add_stand(p, stand_mesh, world)
			"station":
				_add_station(p, world)
			"address":
				var door: Array = p["door"]
				_addresses.append({"name": p["name"], "door": Vector2(door[0], door[1]), "at": Vector2(p["x"], p["z"]),
						"office": p.has("o"), "d": String(p.get("d", ""))})
	for s in _stands:
		s["across"] = _district_near(Vector2(s["ring"].x, s["ring"].z)) == "praga"
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(KEBAB_COLOUR, Color("#2f6fb5"))
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func():
		if state == State.ORDER or state == State.DELIVER:
			_abandon())
	car.bumped.connect(_on_bump)
	var where := PackedStringArray()
	for st in _stands:
		where.append("%d,%d" % [roundi(st["at"].x), roundi(st["at"].z)])
	print("jobs: %d kebab stands (%s), %d addresses, station %s in %d ms" % [_stands.size(), " ".join(where), _addresses.size(),
			"%d,%d" % [roundi(_station["ring"].x), roundi(_station["ring"].z)] if not _station.is_empty() else "none", Time.get_ticks_msec() - t0])


# --- places ---------------------------------------------------------------------------

## Where a job place meets the road: a point on the lane graph's centreline near
## the baked door (a connected road if there is one), the road's direction there,
## the side (unit normal) the place is on, and a free spot on the pavement `half` +
## one of `offsets` metres from the centre (no roof over it, no lane under it). If the
## door's own spot has no room, it looks up to 40 m along the road, then across it.
func _kerb(door: Vector2, at: Vector2, half: float, offsets: Array) -> Dictionary:
	# A stand or a pick-up belongs on a street, not up on a bridge.
	var hit := graph.snap(door, 30.0, Vector2.ZERO, true, true)
	if hit.is_empty():
		hit = graph.snap(door, 30.0, Vector2.ZERO, false, true)
	if hit.is_empty():
		return {}
	var e: int = hit[0]
	for flip in [1.0, -1.0]:
		for shift in [0.0, 8.0, -8.0, 16.0, -16.0, 24.0, -24.0, 32.0, -32.0, 40.0, -40.0]:
			var s := clampf(float(hit[2]) + shift, graph.e_s0[e] + 2.0, graph.e_s1[e] - 2.0)
			var centre := graph.point_at(e, s)
			var dir := graph.direction(e, s)
			var right := Vector2(-dir.y, dir.x)
			var side := right if (at - centre).dot(right) >= 0.0 else -right
			side *= flip
			for off in offsets:
				var p: Vector2 = centre + side * (half + float(off))
				var ground: float = map.terrain_height(p.x, p.y)
				# Free pavement: no roof, no bridge deck overhead, no lane.
				if map.top_height(p.x, p.y, 1.8) > ground + 0.5 or not graph.snap(p, 3.0).is_empty():
					continue
				# Cars keep right: on the place's side they drive along `dir` if that side is the right.
				return {"centre": centre, "side": side, "heading": dir if side == right else -dir, "edge": e, "s": s, "spot": p}
	return {}


func _add_stand(p: Dictionary, mesh: ArrayMesh, world: Node3D) -> void:
	var door: Array = p["door"]
	var half := float(p.get("w", 7.0)) * 0.5
	var k := _kerb(Vector2(door[0], door[1]), Vector2(p["x"], p["z"]), half, [2.4, 1.6, 3.4, 4.4])
	if k.is_empty():
		print("jobs: no room for the kebab stand at %d,%d" % [roundi(float(p["x"])), roundi(float(p["z"]))])
		return
	var spot: Vector2 = k["spot"]
	var side: Vector2 = k["side"]
	var ring2: Vector2 = k["centre"] + side * maxf(half - 2.0, 0.0)
	var ring := Vector3(ring2.x, _road_y(ring2, k["edge"]), ring2.y)
	var at := Vector3(spot.x, map.terrain_height(spot.x, spot.y), spot.y)
	var yaw := atan2(side.x, side.y)  # the counter faces the road
	var node := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Models.material()
	node.add_child(mi)
	# Solid: the car stops at the kiosk.
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 2.6, 2.1)
	shape.shape = box
	shape.position.y = 1.3
	body.add_child(shape)
	node.add_child(body)
	# The board's glow at night.
	var halo := MeshInstance3D.new()
	halo.mesh = _stand_halo
	halo.material_override = _halo_mat
	halo.position = Vector3(0, 3.9, 0)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.visible = false
	halo.add_to_group("night_lights")
	node.add_child(halo)
	world.add_child(node)
	node.global_position = at
	node.rotation.y = yaw
	var marker := _marker(KEBAB_COLOUR, PULL_IN - 1.0)
	world.add_child(marker)
	marker.global_position = ring
	_stands.append({"ring": ring, "at": at, "heading": k["heading"], "node": node, "marker": marker, "cool": false,
			"edge": k["edge"], "s": k["s"]})


func _add_station(p: Dictionary, world: Node3D) -> void:
	var door: Array = p["door"]
	var half := float(p.get("w", 7.0)) * 0.5
	var k := _kerb(Vector2(door[0], door[1]), Vector2(p["x"], p["z"]), half, [1.2, 2.0, 3.0])
	if k.is_empty():
		return
	var spot: Vector2 = k["spot"]
	var side: Vector2 = k["side"]
	var ring2: Vector2 = k["centre"] + side * maxf(half - 2.0, 0.0)
	var ring := Vector3(ring2.x, _road_y(ring2, k["edge"]), ring2.y)
	var person := MeshInstance3D.new()
	person.mesh = Props.person(Color("#3b8f5a"), Color("#2d3442"), true)
	person.material_override = Models.material()
	person.scale = Vector3.ONE * 1.35
	world.add_child(person)
	person.global_position = Vector3(spot.x, map.terrain_height(spot.x, spot.y), spot.y)
	person.rotation.y = atan2(side.x, side.y)
	var marker := _marker(SLOIK_COLOUR, PULL_IN - 1.0)
	world.add_child(marker)
	marker.global_position = ring
	_station = {"ring": ring, "at": person.global_position, "heading": k["heading"], "person": person,
			"marker": marker, "cool": false, "edge": k["edge"], "s": k["s"], "name": String(p["name"])}


## A ring on the road: "pull in here" (the stand's own sign and the minimap mark
## the place from afar).
func _marker(colour: Color, radius: float) -> Node3D:
	var root := Node3D.new()
	if not _ring_mats.has(colour):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = colour
		_ring_mats[colour] = m
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		var y := Vector3(0, 0.4, 0)
		# Dashed: every other segment, so it reads as a pull-in bay, not a beacon.
		if i % 2 == 1:
			continue
		for v in [o0 * radius, o1 * radius, o0 * (radius - 0.5), o1 * radius, o1 * (radius - 0.5), o0 * (radius - 0.5)]:
			st.add_vertex(v + y)
	var ring := MeshInstance3D.new()
	ring.mesh = st.commit()
	ring.material_override = _ring_mats[colour]
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	return root


## The road surface at a point beside lane graph edge e: its bridge deck if it is a
## bridge, else the ground (a street under a bridge stays on the ground).
func _road_y(p: Vector2, e: int) -> float:
	return map.ground_height(p.x, p.y) if graph.e_bridge[e] == 1 else map.terrain_height(p.x, p.y)


## The district of the address nearest a point ("praga" across the river).
func _district_near(p: Vector2) -> String:
	var best := INF
	var d := ""
	for a in _addresses:
		var dd: float = (a["at"] as Vector2).distance_squared_to(p)
		if dd < best:
			best = dd
			d = a["d"]
	return d


# --- the flow ---------------------------------------------------------------------------

func busy() -> bool:
	return state != State.IDLE


func has_target() -> bool:
	return state == State.DELIVER


func target_position() -> Vector3:
	return _order["ring"]


func target_colour() -> Color:
	return KEBAB_COLOUR if job == Job.KEBAB else SLOIK_COLOUR


## Nothing else on: no rescue under way, no race, not flying.
func _free() -> bool:
	if flying or missions.has_target():
		return false
	return rivals == null or not rivals.busy()


func _process(dt: float) -> void:
	if graph == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	match state:
		State.IDLE:
			_look_for_work()
		State.ORDER:
			_order_tick()
		State.DELIVER:
			_deliver_tick(dt)
	last_usec = Time.get_ticks_usec() - t0


func _look_for_work() -> void:
	var free := _free()
	_show_places(free)
	if not free:
		return
	var p := car.global_position
	var slow: bool = car.vel.length() < PULL_IN_SPEED
	for i in _stands.size():
		var s := _stands[i]
		var d := _flat(p, s["ring"])
		if s["cool"]:
			s["cool"] = d < 25.0
		elif d < PULL_IN and slow:
			_begin_kebab(i, _orders)
			return
	if not _station.is_empty():
		var d := _flat(p, _station["ring"])
		if _station["cool"]:
			_station["cool"] = d < 25.0
		elif d < PULL_IN and slow:
			_begin_sloik(_orders)


## Rings, columns and minimap squares for the job places while nothing else runs.
func _show_places(on: bool) -> void:
	if on == _places_shown:
		return
	_places_shown = on
	for s in _stands:
		(s["marker"] as Node3D).visible = on
	if not _station.is_empty():
		(_station["marker"] as Node3D).visible = on
	var pts := PackedVector2Array()
	var colours := PackedColorArray()
	if on:
		for s in _stands:
			pts.append(Vector2(s["ring"].x, s["ring"].z))
			colours.append(KEBAB_COLOUR)
		if not _station.is_empty():
			pts.append(Vector2(_station["ring"].x, _station["ring"].z))
			colours.append(SLOIK_COLOUR)
	hud.set_minimap_pois(pts, colours)


## Other activities stop offering themselves while a job runs.
func _claim() -> void:
	_show_places(false)
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()


func _release() -> void:
	state = State.IDLE
	job = Job.NONE
	_beacon.visible = false
	hud.hide_card()
	hud.hide_status()
	missions.paused = false
	missions.close()
	if not _station.is_empty():
		(_station["person"] as Node3D).visible = true
	_remove_ghost()


# --- kebab -------------------------------------------------------------------------------

## Order n from stand i (the same n always gives the same order).
func _make_kebab_order(i: int, n: int) -> Dictionary:
	var s := _stands[i]
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7907 + i * 131 + 3
	# Now and then the customer is across the river from the stand.
	var want_across := rng.randf() < 0.3
	var from := Vector2(s["ring"].x, s["ring"].z)
	var pick := _pick_address(s["edge"], s["s"], from, ORDER_MIN, ACROSS_MAX if want_across else ORDER_MAX, rng,
			func(a: Dictionary) -> bool: return want_across == ((a["d"] == "praga") != bool(s["across"])))
	if pick.is_empty():
		pick = _pick_address(s["edge"], s["s"], from, ORDER_MIN, ORDER_MAX, rng, func(_a: Dictionary) -> bool: return true)
	if pick.is_empty():
		return {}
	var across: bool = (pick["d"] == "praga") != bool(s["across"])
	var tag := "praga" if pick["d"] == "praga" else ("office" if pick["office"] else String(pick["d"]))
	# Across the river the customer's line says so; elsewhere any line that fits.
	var l: Array = dialogue.line("kebab_order", tag, across)
	var customer: String = dialogue.notes(l).get("customer", CUSTOMERS[rng.randi() % CUSTOMERS.size()])
	pick["customer"] = customer
	pick["line"] = l
	pick["across"] = across
	pick["stand"] = i
	pick["n"] = n
	# A decent drive takes about this long; the kebab is lukewarm by then.
	pick["fair"] = 25.0 + float(pick["road"]) / 8.0
	return pick


## An address `lo`-`hi` metres by road from lane point (e, s) that passes `test`,
## picked with `rng`; with its door's ring, the trip length and the way there.
func _pick_address(e: int, s: float, from: Vector2, lo: float, hi: float, rng: RandomNumberGenerator, test: Callable) -> Dictionary:
	var dist := graph.distances_from(graph.e_b[e])
	var list: Array[Dictionary] = []
	for a in _addresses:
		var d: float = (a["door"] as Vector2).distance_to(from)
		if d >= lo * 0.55 and d <= hi and test.call(a):
			list.append(a)
	# Shuffle with the order's own random numbers.
	for k in range(list.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var t := list[k]
		list[k] = list[j]
		list[j] = t
	for a in list.slice(0, 80):
		var hit := graph.snap(a["door"], 30.0)
		if hit.is_empty():
			continue
		var road := graph.trip(dist, e, s, hit[0], hit[2])
		var reached := road < INF
		var finish: int = graph.e_b[hit[0]]
		if not reached:
			# The little streets over the river join the network outside the map: drive
			# to the connected junction nearest the door, then the last stretch.
			finish = graph.nearest_node(a["door"])
			if finish < 0 or dist[finish] >= INF:
				continue
			road = (graph.e_len[e] - s) + dist[finish] + graph.node_pos[finish].distance_to(a["door"]) * 1.3
		if road < lo or road > hi:
			continue
		var out: Dictionary = a.duplicate()
		var door: Vector2 = a["door"]
		var side: Vector2 = ((a["at"] as Vector2) - door).normalized()
		var ring2 := door + side * 2.0
		out["ring"] = Vector3(ring2.x, _road_y(ring2, hit[0]), ring2.y)
		out["road"] = road
		out["edge"] = hit[0]
		out["s"] = hit[2]
		out["reached"] = reached
		out["finish"] = finish
		return out
	return {}


func _begin_kebab(i: int, n: int) -> void:
	var o := _make_kebab_order(i, n)
	if o.is_empty():
		hud.toast("No orders right now")
		_stands[i]["cool"] = true
		return
	_orders += 1
	job = Job.KEBAB
	state = State.ORDER
	_t = 0.0
	_order = o
	_said_order = false
	_claim()
	var stand: Node3D = _stands[i]["node"]
	dialogue.say(stand, "Kebab 24h", "kebab_vendor", "", 2.4, KEBAB_COLOUR, 5.2)
	var where := "%s, %s" % [o["customer"], o["name"]]
	var extra := " Across the river: \"basically the centre\"." if o["across"] else ""
	var night := " Night pays ×%.1f." % NIGHT_BONUS if _night() else ""
	hud.show_card("KEBAB ORDER · %d m" % roundi(o["road"]),
			"Deliver to %s.%s\nIt cools on the way: the hotter it arrives, the bigger the tip.%s" % [where, extra, night],
			PackedStringArray(["GO!", "NOT NOW"]), KEBAB_COLOUR, true)
	print("kebab order %d: stand %d -> %s (%s), %d m by road%s" % [n, i, o["name"], o["customer"], roundi(o["road"]),
			", across the river" if o["across"] else ""])


## The order line follows the vendor's; the job goes when the player drives off,
## presses GO, or after a few seconds.
func _order_tick() -> void:
	var at: Vector3 = _stands[_order["stand"]]["ring"] if job == Job.KEBAB else _station["ring"]
	if job == Job.KEBAB and not _said_order and _t > 2.6:
		_said_order = true
		var l: Array = _order["line"]
		if not l.is_empty():
			bubbles.say(_stands[_order["stand"]]["node"], "Kebab 24h", l[0], l[1], 3.5, KEBAB_COLOUR, 5.2)
	if _flat(car.global_position, at) > PULL_IN + 7.0 or _t > (4.0 if autopilot else 9.0):
		_go()


func _go() -> void:
	state = State.DELIVER
	_t = 0.0
	_clock = 0.0
	hud.hide_card()
	var ring: Vector3 = _order["ring"]
	_beacon.waving = true
	_beacon.recolour(KEBAB_COLOUR if job == Job.KEBAB else SLOIK_COLOUR)
	_beacon.place(ring, ARRIVE - 0.5)
	if job == Job.KEBAB:
		_heat = start_heat
		_beacon.recolour(KEBAB_COLOUR)
		hud.toast("Go! %s is waiting" % _order["customer"])
	else:
		_jars = JARS - clampi(start_broken, 0, JARS)
		_stress = 0.0
		_have_last = false
		_chat_t = 9.0
		_warn_wait = 0.0
		(_station["person"] as Node3D).visible = false
		_beacon.recolour(SLOIK_COLOUR)
		# Nobody waits at the flat: the passenger rides with you.
		_beacon.place(ring, ARRIVE - 0.5, true, false)
		hud.toast("Drive smoothly: hard bumps, braking and fast corners break jars")
	_slide = false


func _deliver_tick(dt: float) -> void:
	_clock += dt
	var target: Vector3 = _order["ring"]
	var p := car.global_position
	var d := _flat(p, target)
	var speed: float = car.vel.length()
	if job == Job.KEBAB:
		_heat = maxf(0.0, _heat - dt * 0.6 / float(_order["fair"]))
	if d < ARRIVE and speed < ARRIVE_SPEED and not flying:
		_arrive()
		return
	var hint := ""
	if flying:
		hint = "Land and take the car: the order rides in the car"
	elif d > 40.0:
		hint = "Head for the %s beacon" % ("orange" if job == Job.KEBAB else "teal")
	elif d < ARRIVE:
		hint = "Stop at the door"
	else:
		hint = "Pull up inside the ring"
	if job == Job.KEBAB:
		var word := "HOT" if _heat >= 0.7 else ("WARM" if _heat >= 0.4 else "COLD")
		hud.show_status("KEBAB → %s" % _order["name"], "%s %d%%" % [word, roundi(_heat * 100.0)], "%d m" % roundi(d),
				hint, 0.0, KEBAB_COLOUR, "", {"heat": _heat})
	else:
		_chat_t -= dt
		if _chat_t <= 0.0 and not bubbles.is_talking(car):
			_chat_t = _rng.randf_range(20.0, 32.0)
			dialogue.say(car, _order["customer"], "passenger", "", 4.5, SLOIK_COLOUR, 2.4)
		if _stress > 0.55 and d > ARRIVE:
			hint = "Easy! The jars are rattling"
		hud.show_status("SŁOIKI → %s" % _order["name"], _clock_text(_clock), "%d m" % roundi(d),
				hint, _stress, SLOIK_COLOUR, "", {"jars": [_jars, JARS], "shake": clampf(_stress, 0.0, 1.0)})


func _arrive() -> void:
	state = State.RESULT
	hud.hide_status()
	_remove_ghost()
	# The passenger's chatter stops: the last word is at the door.
	bubbles.hush(car)
	var ring: Vector3 = _order["ring"]
	# The customer (or the passenger, home at last) stands at the door.
	_beacon.waving = false
	_beacon.place(ring, ARRIVE - 0.5, false, true)
	if job == Job.KEBAB:
		_kebab_result()
	else:
		_sloik_result()
	Input.vibrate_handheld(120, 0.8)


func _kebab_result() -> void:
	var hot := _heat >= 0.4
	var road: float = _order["road"]
	var fare := roundi(12.0 + road * 0.015)
	var tip := roundi(_heat * (10.0 + road * 0.02)) if hot else 0
	var bonus := NIGHT_BONUS if _night() else 1.0
	var total := roundi((fare + tip) * bonus)
	wallet.pay(total, 10 if hot else 0, "kebab")
	var key := "kebab:%d:%s" % [_order["stand"], _order["name"]]
	var best: float = wallet.best_time(key)
	var record: bool = wallet.record(key, _clock)
	var l: Array = dialogue.say(_beacon, _order["customer"], "kebab_hot" if hot else "kebab_cold", "", 5.0,
			KEBAB_COLOUR if hot else Color("#7fb8de"), 3.6)
	var quote := "„%s”\n%s\n" % [l[0], l[1]] if not l.is_empty() else ""
	var money := "Fare %d zł + tip %d zł%s = %d zł · wallet %s" % [fare, tip,
			(" · night ×%.1f" % NIGHT_BONUS) if bonus > 1.0 else "", total, _money(wallet.zl)]
	var times := "%s at %d%% heat%s" % [_clock_text(_clock), roundi(_heat * 100.0),
			" · new best!" if record and best > 0.0 else (" · best %s" % _clock_text(best) if best > 0.0 else "")]
	hud.show_card("DELIVERED · " + ("STILL HOT" if _heat >= 0.7 else ("WARM" if hot else "COLD")),
			"%s%s, %s: %s\n%s" % [quote, _order["customer"], _order["name"], times, money],
			PackedStringArray(["OK"]), KEBAB_COLOUR if hot else Color("#7fb8de"), true)
	print("kebab delivered: %s in %.1f s, heat %d%%, %s, paid %d zł (wallet %d zł)" % [_order["name"], _clock,
			roundi(_heat * 100.0), "hot" if hot else "cold", total, wallet.zl])


# --- słoiki ------------------------------------------------------------------------------

func _begin_sloik(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 3571 + 11
	var from := Vector2(_station["ring"].x, _station["ring"].z)
	var pick := _pick_address(_station["edge"], _station["s"], from, 1000.0, 2400.0, rng, func(a: Dictionary) -> bool:
		return a["d"] == "powisle" and not a["office"])
	if pick.is_empty():
		hud.toast("Nobody needs a lift right now")
		_station["cool"] = true
		return
	_orders += 1
	job = Job.SLOIK
	state = State.ORDER
	_t = 0.0
	_order = pick
	_order["customer"] = NEWCOMERS[rng.randi() % NEWCOMERS.size()]
	_claim()
	var person: Node3D = _station["person"]
	dialogue.say(person, _order["customer"], "sloik_start", "", 4.0, SLOIK_COLOUR, 2.9)
	hud.show_card("SŁOIKI RUN · SUNDAY EVENING",
			"%s is back from home with %d of mum's jars. Take them to the rented flat at %s, Powiśle (%d m by road).\nHard bumps, heavy braking and fast corners break jars." % [
			_order["customer"], JARS, _order["name"], roundi(_order["road"])],
			PackedStringArray(["GO!", "NOT NOW"]), SLOIK_COLOUR, true)
	print("słoiki run %d: %s to %s, %d m by road" % [n, _order["customer"], _order["name"], roundi(_order["road"])])


func _physics_process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _step(dt: float) -> void:
	_bump_wait = maxf(0.0, _bump_wait - dt)
	_warn_wait = maxf(0.0, _warn_wait - dt)
	if job != Job.SLOIK or state != State.DELIVER or dt <= 0.0:
		_have_last = false
		return
	var v: float = car.forward_speed
	var yaw := car.rotation.y
	if not _have_last:
		_last_v = v
		_last_yaw = yaw
		_have_last = true
		return
	var a_long: float = (v - _last_v) / dt
	var lat := absf(v * angle_difference(_last_yaw, yaw) / dt)
	_last_v = v
	_last_yaw = yaw
	# A crash shows as a huge jump here; the bump has already counted it.
	if absf(a_long) < 60.0:
		var k := 1.0 - exp(-dt / 0.12)
		_brake_s = lerpf(_brake_s, maxf(0.0, -a_long * signf(v)), k)
		_lat_s = lerpf(_lat_s, minf(lat, 60.0), k)
	_stress += dt * (maxf(0.0, _brake_s - BRAKE_FREE) / 10.0 + maxf(0.0, _lat_s - CORNER_FREE) / 10.0)
	_stress = maxf(0.0, _stress - dt * 0.12)
	_check_jars()


## v0.9: the jars in the boot (sfx.gd): 0 = they clink, 1 = one broke.
signal jars(kind: int)


func _on_bump(_collider: Object, speed: float) -> void:
	if job == Job.SLOIK and state == State.DELIVER and _bump_wait <= 0.0 and _jars > 0:
		jars.emit(0)
	if job != Job.SLOIK or state != State.DELIVER or _bump_wait > 0.0 or speed < BUMP_FREE:
		return
	_bump_wait = 0.4
	_stress += (speed - BUMP_FREE) / 5.0
	_check_jars()


func _check_jars() -> void:
	var broke := false
	while _stress >= 1.0 and _jars > 0:
		_jars -= 1
		_stress -= 0.75
		broke = true
	if _jars == 0:
		_stress = minf(_stress, 0.99)
	if broke:
		print("słoiki: a jar broke at %.1f s, %d/%d left" % [_clock, _jars, JARS])
		jars.emit(1)
		Input.vibrate_handheld(90, 0.9)
		dialogue.say(car, _order["customer"], "sloik_crash", "", 3.5, FAIL_COLOUR, 2.4)
		hud.toast("Crash! A jar broke · %d of %d left" % [_jars, JARS])
		_warn_wait = 3.0
		_chat_t = maxf(_chat_t, 8.0)
	elif _stress > 0.6 and _warn_wait <= 0.0 and _jars > 0:
		_warn_wait = 7.0
		jars.emit(0)
		dialogue.say(car, _order["customer"], "sloik_bump", "", 2.5, Color("#ffb05a"), 2.4)
		Input.vibrate_handheld(40, 0.4)


func _sloik_result() -> void:
	var intact := _jars
	var group := "sloik_done" if intact >= 3 else "sloik_broken"
	var pay := 50 + 35 * intact
	wallet.pay(pay, 30 if intact == JARS else 0, "sloik")
	var best: float = wallet.best_time("sloik")
	var record: bool = intact == JARS and wallet.record("sloik", _clock)
	var l: Array = dialogue.say(_beacon, _order["customer"], group, "all" if intact == JARS else "some", 5.0,
			SLOIK_COLOUR if intact >= 3 else FAIL_COLOUR, 3.6)
	var quote := "„%s”\n%s\n" % [l[0], l[1]] if not l.is_empty() else ""
	var times := _clock_text(_clock)
	if record and best > 0.0:
		times += " · new best!"
	elif best > 0.0:
		times += " · best with every jar %s" % _clock_text(best)
	hud.show_card("DELIVERED · %d/%d JARS" % [intact, JARS],
			"%s%s, %s: %s\nFare 50 zł + %d jars × 35 zł = %d zł · wallet %s" % [quote, _order["customer"], _order["name"],
			times, intact, pay, _money(wallet.zl)],
			PackedStringArray(["OK"]), SLOIK_COLOUR if intact >= 3 else FAIL_COLOUR, true)
	print("słoiki delivered: %s in %.1f s, %d/%d jars, paid %d zł (wallet %d zł)" % [_order["name"], _clock, intact, JARS,
			pay, wallet.zl])


# --- cards, giving up ------------------------------------------------------------------------

func _on_card(index: int) -> void:
	match state:
		State.ORDER:
			if index == 0:
				_go()
			else:
				# Not now: the place waits until the car has driven off.
				if job == Job.KEBAB:
					_stands[_order["stand"]]["cool"] = true
				else:
					_station["cool"] = true
				bubbles.hush(_stands[_order["stand"]]["node"] if job == Job.KEBAB else _station["person"])
				_release()
		State.RESULT:
			_release()


## Keyboard: M answers a job card's first button (GO, OK), K its second (NOT NOW).
## Returns false when no job card is up.
func primary() -> bool:
	if state == State.ORDER or state == State.RESULT:
		_on_card(0)
		return true
	return false


func secondary() -> bool:
	if state == State.ORDER:
		_on_card(1)
		return true
	return false


func _abandon() -> void:
	state = State.RESULT
	hud.hide_status()
	_beacon.visible = false
	_remove_ghost()
	if job == Job.KEBAB:
		hud.show_card("ORDER DROPPED", "%s at %s will never know. The pigeons on Plac Defilad had a feast." % [
				_order["customer"], _order["name"]], PackedStringArray(["OK"]), FAIL_COLOUR, true)
	else:
		hud.show_card("RUN ABANDONED", "%s took a taxi. With the jars. Mum has been told." % _order["customer"],
				PackedStringArray(["OK"]), FAIL_COLOUR, true)


# --- testing aids --------------------------------------------------------------------------

## --kebab=N: puts the car in stand (N mod stands)'s ring and starts order N.
func start_kebab(n: int) -> bool:
	if _stands.is_empty():
		return false
	var i := posmod(n, _stands.size())
	_put_car(_stands[i])
	_begin_kebab(i, n)
	return state == State.ORDER


## --sloik: puts the car at the station and starts the run (`broken` jars already gone).
func start_sloik(broken := 0) -> bool:
	if _station.is_empty():
		return false
	start_broken = broken
	_put_car(_station)
	_begin_sloik(0)
	return state == State.ORDER


func _put_car(place: Dictionary) -> void:
	var ring: Vector3 = place["ring"]
	var heading: Vector2 = place["heading"]
	car.global_position = ring
	car.rotation.y = atan2(-heading.x, -heading.y)
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()


## The autopilot drives the job's route (returns true while it does): on a ghost
## driver along the lane graph, then straight to the door's ring.
func drive_player() -> bool:
	if not autopilot or state != State.DELIVER:
		return false
	var target: Vector3 = _order["ring"]
	if _ghost == null and not _slide:
		_start_ghost()
		if _ghost == null:
			_slide = true
	if _ghost != null:
		if _ghost.arrived or _flat(_ghost.pos, target) < 22.0:
			_remove_ghost()
			_slide = true
		else:
			# Stuck behind a knot of cars (the autopilot car ghosts anyway): slip through.
			_stall = _stall + get_process_delta_time() if _ghost.v < 0.5 else 0.0
			if _stall > 4.0:
				_stall = 0.0
				_ghost.squeeze = 3.0
			_follow(_ghost.pos, _ghost.yaw, _ghost.v)
			return true
	var to := Vector3(target.x - car.global_position.x, 0.0, target.z - car.global_position.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	if d > 0.5:
		var dt := get_process_delta_time()
		car.global_position += to / d * minf(d, 12.0 * dt)
		car.rotation.y = atan2(-to.x, -to.z)
	return true


func _start_ghost() -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		hit = graph.snap(p, 60.0, Vector2.ZERO, true)
	if hit.is_empty():
		return
	# The door's road, or (over the river) the connected junction nearest to it.
	var finish: int = _order["finish"]
	_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	# Kebabs go fast; mum's jars go gently.
	_ghost.speed_factor = 1.3 if job == Job.KEBAB else 0.95
	_ghost.accel_factor = 1.5 if job == Job.KEBAB else 0.9
	traffic.race_to(_ghost, finish, graph.distances_to(finish))


func _remove_ghost() -> void:
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null


func _follow(at: Vector3, yaw: float, speed: float) -> void:
	car.collision_mask = 0
	car.global_position = at
	car.rotation.y = yaw
	car.vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


# --- helpers ---------------------------------------------------------------------------------

func _night() -> bool:
	return tod != null and tod.mode == 2


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _clock_text(seconds: float) -> String:
	var tenths := maxi(0, int(seconds * 10.0))
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out + " zł"
