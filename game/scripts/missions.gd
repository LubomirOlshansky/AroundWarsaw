extends Node
## Rescue missions. A call comes in for a person at a real place on the map: the
## roof of a named building, a named street, a park or square, a Vistula beach or
## sandbar. The player gets there, holds still next to them for a moment, then
## brings them to a real hospital before the clock runs out. Every place comes
## from the baked map data (landmarks, roads and pois in centrum.json). The person
## says a line when picked up, the crew another at the hospital (dialogue.gd), and
## a rescue pays złoty and respect (wallet.gd).

const Beacon := preload("res://scripts/beacon.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

const HOLD_TIME := 2.0
const CAR_REACH := 6.0       # stop this close to the person...
const CAR_STOPPED := 1.0     # ...going no faster than this (m/s)
const HELI_REACH := 8.0      # hover or land this close...
const HELI_LOW := 4.0        # ...with the skids no higher above the person than this
const MIN_ROOF := 20.0       # a roof rescue is at least this high above the street
const OPEN_RADIUS := 4.5     # street spots need this much open sky for the helicopter
const PICKUP_COLOUR := Color("#ffc23a")
const DROPOFF_COLOUR := Color("#56d68a")
const FAIL_COLOUR := Color("#e2574c")

enum Kind { STREET, ROOF, RIVER, PARK }
## Mission n is of kind ORDER[(n - 1) % 4], so --mission=2 is always a roof.
const ORDER := [Kind.STREET, Kind.ROOF, Kind.RIVER, Kind.PARK]
const TITLES := ["STREET RESCUE", "ROOF RESCUE", "RIVER RESCUE", "PARK RESCUE"]
enum State { IDLE, OFFER, CLOSED, PICKUP, DROPOFF, RESULT }

var map: Node3D
var hud: CanvasLayer
var state := State.IDLE
var number := 0
var total_score := 0
## Where the player is, kept by tick(); new calls come from places near it.
var player := Vector3.ZERO
## A street race or a side job is on: no calls until it ends (one activity at a time).
var paused := false
## Set by the game: the wallet, everybody's lines, and where the vehicle's cabin is.
var wallet: Node
var dialogue: Node
var vehicle_anchor: Callable
## Who needs rescuing: first names only.
const NAMES := ["Ania", "Kuba", "Ola", "Tomek", "Zosia", "Bartek", "Magda", "Piotrek", "Ewa", "Marek"]
const KIDS := ["Staś", "Zuzia", "Antek", "Hania"]

## Kind -> places: {kind, name, short, text, pos, heli, child}.
var _places := {}
var _hospitals: Array[Dictionary] = []
var _mission: Dictionary = {}
var _success := false
var _time_left := 0.0
var _limit := 0.0
var _hold := 0.0
var _inner: Rect2
var _road_points := PackedVector2Array()
var _road_names := PackedStringArray()
var _pickup: Node3D
var _dropoff: Node3D


func setup(map_node: Node3D, data: Dictionary, world: Node3D, hud_layer: CanvasLayer) -> void:
	map = map_node
	hud = hud_layer
	var b: Array = data["bounds"]
	_inner = Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-40.0)
	for k in ORDER:
		_places[k] = []
	var t0 := Time.get_ticks_msec()
	_collect_road_names(data["roads"])
	_find_roofs(data.get("landmarks", []))
	_find_streets(data["roads"])
	_find_pois(data.get("pois", []))
	print("missions: %d roofs, %d streets, %d riverside, %d parks, %d hospitals in %d ms" % [
			_places[Kind.ROOF].size(), _places[Kind.STREET].size(), _places[Kind.RIVER].size(),
			_places[Kind.PARK].size(), _hospitals.size(), Time.get_ticks_msec() - t0])

	_pickup = Beacon.new()
	world.add_child(_pickup)
	_pickup.setup(PICKUP_COLOUR, Color("#e8762e"))
	_dropoff = Beacon.new()
	world.add_child(_dropoff)
	_dropoff.setup(DROPOFF_COLOUR, Color("#f2efe8"))
	_dropoff.waving = false
	hud.card_pressed.connect(_on_card)
	hud.pill_pressed.connect(func(): offer(number + 1))
	hud.abort_pressed.connect(func():
		if has_target():
			_finish(false, "You called the rescue off."))


# --- the flow -------------------------------------------------------------------

## Shows the call card for mission n.
func offer(n: int) -> void:
	if _hospitals.is_empty() or paused:
		return
	number = n
	_mission = _make(n)
	state = State.OFFER
	_pickup.visible = false
	_dropoff.visible = false
	hud.hide_status()
	hud.hide_pill()
	var limit := _limit_for(_mission)
	hud.show_card("CALL %d · %s" % [n, TITLES[_mission["kind"]]],
			"%s\nTake them to %s.\nTime limit %s." % [_mission["text"], _mission["hospital"]["name"], _clock(limit)],
			PackedStringArray(["ACCEPT", "SKIP", "LATER"]), PICKUP_COLOUR)


## Offers mission n and accepts it at once (the --mission flag).
func start(n: int) -> void:
	offer(n)
	print("rescue call %d: %s" % [n, _mission.get("short", "?")])
	accept()


func accept() -> void:
	if _mission.is_empty():
		return
	state = State.PICKUP
	_limit = _limit_for(_mission)
	_time_left = _limit
	_hold = 0.0
	hud.hide_card()
	_dropoff.visible = false
	_pickup.waving = true
	_pickup.place(_mission["pos"], HELI_REACH if _mission["heli"] else CAR_REACH)
	hud.toast("Go! " + ("Take the helicopter." if _mission["heli"] else "Car or helicopter."))


## Hides the card; a small RESCUE CALLS button brings the next call.
func close() -> void:
	state = State.CLOSED
	_pickup.visible = false
	_dropoff.visible = false
	hud.hide_card()
	hud.hide_status()
	hud.show_pill("RESCUE CALLS")


## Keyboard: M answers the card's first button (or opens the next call).
func primary() -> void:
	if paused:
		return
	match state:
		State.OFFER, State.RESULT:
			_on_card(0)
		State.CLOSED:
			offer(number + 1)


## Keyboard: N skips a call, or moves on to the next call from a result.
func secondary() -> void:
	if paused:
		return
	match state:
		State.OFFER:
			_on_card(1)
		State.RESULT:
			_on_card(0 if _success else 1)


## Card buttons: an offer is ACCEPT / SKIP / LATER, a success NEXT CALL / FREE ROAM,
## a failure TRY AGAIN / NEXT CALL / FREE ROAM.
func _on_card(index: int) -> void:
	if state == State.RESULT and _success:
		index += 1  # no TRY AGAIN button
	if state == State.OFFER:
		if index == 0:
			accept()
		elif index == 1:
			offer(number + 1)
		else:
			close()
	elif state == State.RESULT:
		if index == 0:
			accept()  # the same call again, timed from here
		elif index == 1:
			offer(number + 1)
		else:
			close()


func has_target() -> bool:
	return state == State.PICKUP or state == State.DROPOFF


func target_position() -> Vector3:
	return _mission["pos"] if state == State.PICKUP else _mission["hospital"]["pos"]


func target_colour() -> Color:
	return PICKUP_COLOUR if state == State.PICKUP else DROPOFF_COLOUR


## True while the person still waits somewhere only the helicopter reaches.
func needs_heli() -> bool:
	return state == State.PICKUP and _mission["heli"]


## Runs the clock and checks for pick-up and hand-over. `pos` is the vehicle
## (the bottom of the skids for the helicopter), `speed` its speed in m/s.
func tick(dt: float, pos: Vector3, speed: float, flying: bool) -> void:
	player = pos
	if not has_target():
		return
	_time_left -= dt
	if _time_left <= 0.0:
		_finish(false, "Out of time. Another crew took over.")
		return
	var target := target_position()
	var d := Vector2(pos.x - target.x, pos.z - target.z).length()
	var dy := pos.y - target.y
	var picking := state == State.PICKUP
	var ok := false
	var hint := ""
	if picking and _mission["heli"] and not flying:
		hint = "Only the helicopter gets there: press HELI (H)"
	elif d > 40.0:
		hint = "Head for the yellow beacon" if picking else "Patient on board: head for the green beacon"
	elif flying:
		ok = d <= HELI_REACH and dy < HELI_LOW and dy > -1.0
		if dy >= HELI_LOW:
			hint = "Go down: within 4 m of them (▼ / F)"
		elif d > HELI_REACH:
			hint = "Move over the ring"
	else:
		ok = d <= CAR_REACH and speed < CAR_STOPPED and absf(dy) < 2.5
		if d > CAR_REACH:
			hint = "Stop inside the ring"
		elif speed >= CAR_STOPPED:
			hint = "Stop to " + ("pick them up" if picking else "hand them over")
	if ok:
		_hold += dt
		hint = "Hold still… " + ("picking up" if picking else "handing over")
	else:
		_hold = 0.0
	if _hold >= HOLD_TIME:
		_hold = 0.0
		if picking:
			_picked_up()
		else:
			_finish(true, "")
		return
	var where: String = _mission["short"] if picking else _mission["hospital"]["name"]
	hud.show_status(("PICK UP · " if picking else "DELIVER · ") + where, _clock(_time_left), "%d m" % roundi(d),
			hint, _hold / HOLD_TIME, target_colour())


func _picked_up() -> void:
	state = State.DROPOFF
	_pickup.visible = false
	var h: Dictionary = _mission["hospital"]
	_dropoff.place(h["pos"], CAR_REACH + 2.0)
	hud.toast("Picked up! Now to " + h["name"])
	Input.vibrate_handheld(60, 0.6)
	if dialogue != null and vehicle_anchor.is_valid():
		dialogue.say(vehicle_anchor, _mission["who"], "rescue_person", _tag(), 4.5, PICKUP_COLOUR, 0.0)


## Which rescue lines fit this call: "roof", "street", "river", "child" or "square".
func _tag() -> String:
	match int(_mission["kind"]):
		Kind.ROOF:
			return "roof"
		Kind.RIVER:
			return "river"
		Kind.PARK:
			return "child" if _mission["child"] else "square"
	return "street"


func _finish(success: bool, why: String) -> void:
	_success = success
	state = State.RESULT
	print("rescue %s: %s, %s left" % ["done" if success else "failed", _mission["short"], _clock(_time_left)])
	hud.hide_status()
	if success:
		var route := _flat(_mission["pos"], _mission["hospital"]["pos"])
		var score := 500 + int(_time_left) * 10 + int(route / 4.0)
		total_score += score
		var pay := roundi(score * 0.08)
		if wallet != null:
			wallet.pay(pay, 40, "rescue")
		# The patient stands with the hospital crew; the light goes out.
		var at: Vector3 = _mission["hospital"]["pos"]
		_dropoff.place(at, CAR_REACH + 2.0, false, true)
		_pickup.waving = false
		_pickup.place(at + Vector3(1.6, 0, 0.8), HELI_REACH, false, true)
		hud.show_card("RESCUED", "Safe and sound at %s.\nTime %s of %s.\nScore +%d · total %d · +%d zł" % [
				_mission["hospital"]["name"], _clock(_limit - _time_left), _clock(_limit), score, total_score, pay],
				PackedStringArray(["NEXT CALL", "FREE ROAM"]), DROPOFF_COLOUR)
		Input.vibrate_handheld(120, 0.8)
		if dialogue != null:
			dialogue.say(_dropoff, "Ratownik", "rescue_done", "", 5.0, DROPOFF_COLOUR, 3.6)
	else:
		_pickup.visible = false
		_dropoff.visible = false
		hud.show_card("TOO LATE", "%s\nScore total %d" % [why, total_score],
				PackedStringArray(["TRY AGAIN", "NEXT CALL", "FREE ROAM"]), FAIL_COLOUR)


## The call for mission n: a place of its kind a short trip from the player
## (a seeded pick, so the same start gives the same call), and a hospital.
func _make(n: int) -> Dictionary:
	var kind: int = ORDER[(n - 1) % ORDER.size()]
	var list: Array = _places[kind]
	if list.is_empty():
		list = _places[Kind.STREET]
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + 17
	var by_distance := list.duplicate()
	by_distance.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _flat(player, a["pos"]) < _flat(player, b["pos"]))
	var near := by_distance.filter(func(p: Dictionary) -> bool: return _flat(player, p["pos"]) >= 150.0 and _flat(player, p["pos"]) <= 1100.0)
	if near.size() < 3:
		# Nothing much in reach (the river from the west end): one of the three nearest.
		near = by_distance.filter(func(p: Dictionary) -> bool: return _flat(player, p["pos"]) >= 60.0).slice(0, 3)
	if near.is_empty():
		near = by_distance
	var place: Dictionary = near[rng.randi() % near.size()]
	var m := place.duplicate()
	m["hospital"] = _hospital_for(place)
	m["who"] = KIDS[rng.randi() % KIDS.size()] if place["child"] else NAMES[rng.randi() % NAMES.size()]
	return m


## The nearest hospital; the children's hospital takes only children.
func _hospital_for(place: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	for h in _hospitals:
		if h["children"] and not place["child"]:
			continue
		if best.is_empty() or _flat(place["pos"], h["pos"]) < _flat(place["pos"], best["pos"]):
			best = h
	return best if not best.is_empty() else _hospitals[0]


## A fair time: the straight-line trip at a city pace, the climb to a roof, and slack.
func _limit_for(m: Dictionary) -> float:
	var route := _flat(player, m["pos"]) + _flat(m["pos"], m["hospital"]["pos"])
	var pos: Vector3 = m["pos"]
	var climb := maxf(0.0, pos.y - map.ground_height(pos.x, pos.z)) / 5.0
	var t := 35.0 + route / (17.0 if m["heli"] else 9.5) + climb
	return ceilf(t / 5.0) * 5.0


# --- finding places -------------------------------------------------------------

func _find_roofs(landmarks: Array) -> void:
	var best := {}
	for l in landmarks:
		var name: String = l["name"]
		var spot := _flat_roof(_pts(l["p"]))
		if spot == Vector3.INF or (best.has(name) and (best[name]["pos"] as Vector3).y >= spot.y):
			continue
		var up := roundi(spot.y - map.ground_height(spot.x, spot.z))
		best[name] = {"kind": Kind.ROOF, "name": name, "short": "roof of " + name, "pos": spot, "heli": true, "child": false,
				"text": "Someone is stranded on the roof of %s, %d m up. Only the helicopter can reach them." % [name, up]}
	_places[Kind.ROOF].append_array(best.values())


## The highest spot on a building's roof that is flat enough to land on (the
## cells around it within a metre of it), or Vector3.INF.
func _flat_roof(poly: PackedVector2Array) -> Vector3:
	if poly.size() < 3:
		return Vector3.INF
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var cell := MapBuilder.ROOF_CELL
	var best := Vector3.INF
	var best_h := -INF
	var z := lo.y + cell * 0.5
	while z < hi.y:
		var x := lo.x + cell * 0.5
		while x < hi.x:
			var p := Vector2(x, z)
			var h: float = map.roof_height(x, z)
			if h > best_h and _inner.has_point(p) and Geometry2D.is_point_in_polygon(p, poly) \
					and h - map.ground_height(x, z) >= MIN_ROOF and _is_flat(x, z, h, cell):
				best_h = h
				best = Vector3(x, h, z)
			x += cell
		z += cell
	return best


func _is_flat(x: float, z: float, h: float, cell: float) -> bool:
	for j in range(-1, 2):
		for i in range(-1, 2):
			if absf(map.roof_height(x + i * cell, z + j * cell) - h) > 1.0:
				return false
	return true


## One spot per named street: the open point nearest the middle of its longest piece.
func _find_streets(roads: Array) -> void:
	var best := {}
	for r in roads:
		var name: String = r["name"]
		if name == "" or r["k"] == "service":
			continue
		var poly := _pts(r["p"])
		var length := 0.0
		for i in poly.size() - 1:
			length += poly[i].distance_to(poly[i + 1])
		if best.has(name) and float(best[name][0]) >= length:
			continue
		var s := 0.0
		while s <= length * 0.5:
			var spot := Vector3.INF
			for along in [length * 0.5 + s, length * 0.5 - s]:
				var p := _point_along(poly, along)
				if _is_open(p.x, p.y):
					spot = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
					break
			if spot != Vector3.INF:
				best[name] = [length, spot]
				break
			s += 6.0
	for name in best:
		var at := "at" if name.begins_with("Plac") or name.begins_with("Rondo") else "on"
		_places[Kind.STREET].append({"kind": Kind.STREET, "name": name, "short": name, "pos": best[name][1],
				"heli": false, "child": false,
				"text": "A cyclist is hurt %s %s. The car or the helicopter will do." % [at, name]})


func _find_pois(pois: Array) -> void:
	for p in pois:
		var kind: String = p["k"]
		# The side jobs' and easter eggs' places (kebab stands, addresses...) are not calls.
		if not kind in ["hospital", "beach", "shore", "sandbar", "park", "square"]:
			continue
		var name: String = p["name"]
		var x := float(p["x"])
		var z := float(p["z"])
		if kind == "hospital":
			var door: Array = p["door"]
			var spot := _open_near(float(door[0]), float(door[1]), 40.0)
			if spot != Vector3.INF:
				_hospitals.append({"name": name, "pos": spot, "children": name.to_lower().contains("dzieci")})
			continue
		var spot := _open_near(x, z, 24.0)
		if spot == Vector3.INF:
			continue
		var place := {"name": name, "pos": spot, "heli": false, "child": false}
		match kind:
			"beach":
				place["kind"] = Kind.RIVER
				if name != "":
					place["short"] = name + " beach"
					place["text"] = "A swimmer is in trouble at %s, the beach on the Vistula." % name
				else:
					place["short"] = "Vistula beach"
					place["text"] = "A swimmer is in trouble on a Vistula beach near %s." % _nearest_road(x, z)
			"shore":
				place["kind"] = Kind.RIVER
				place["short"] = "Vistula shore"
				place["text"] = "Someone slipped on the Vistula shore near %s. The car or the helicopter will do." % _nearest_road(x, z)
			"sandbar":
				place["kind"] = Kind.RIVER
				place["heli"] = true
				place["short"] = "Vistula sandbar"
				place["text"] = "Someone is stranded on a sandbar in the Vistula near %s. Only the helicopter can reach them." % _nearest_road(x, z)
			"park":
				place["kind"] = Kind.PARK
				place["child"] = true
				place["short"] = name
				place["text"] = "A child fell off a climbing frame in %s." % name
			"square":
				place["kind"] = Kind.PARK
				place["short"] = name
				place["text"] = "A tourist fainted at %s." % name
			_:
				continue
		_places[place["kind"]].append(place)


## Open sky: no building within OPEN_RADIUS, so the helicopter can come down too.
func _is_open(x: float, z: float) -> bool:
	return _inner.has_point(Vector2(x, z)) and map.top_height(x, z, OPEN_RADIUS) <= map.ground_height(x, z) + 1.5


## The point itself if it's open, else the nearest open point within `reach` metres.
func _open_near(x: float, z: float, reach: float) -> Vector3:
	var r := 0.0
	while r <= reach:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * k / steps
			var px := x + cos(a) * r
			var pz := z + sin(a) * r
			if _is_open(px, pz):
				return Vector3(px, map.ground_height(px, pz), pz)
		r += 4.0
	return Vector3.INF


func _collect_road_names(roads: Array) -> void:
	for r in roads:
		if r["name"] == "" or r["k"] == "service":
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 1, 2):
			_road_points.append(Vector2(flat[i], flat[i + 1]))
			_road_names.append(r["name"])


func _nearest_road(x: float, z: float) -> String:
	var best := INF
	var name := "the river"
	var p := Vector2(x, z)
	for i in _road_points.size():
		var d := p.distance_squared_to(_road_points[i])
		if d < best:
			best = d
			name = _road_names[i]
	return name


# --- helpers --------------------------------------------------------------------

func _point_along(poly: PackedVector2Array, s: float) -> Vector2:
	for i in poly.size() - 1:
		var seg := poly[i].distance_to(poly[i + 1])
		if s <= seg and seg > 0.0:
			return poly[i].lerp(poly[i + 1], s / seg)
		s -= seg
	return poly[poly.size() - 1]


func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _clock(seconds: float) -> String:
	var s := maxi(0, ceili(seconds))
	return "%d:%02d" % [s / 60, s % 60]
