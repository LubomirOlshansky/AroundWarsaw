extends Node
## Loop MW-4 (docs/design/vision.md 3.4): "Na czasie" · On trend, the trend courier's side job.
## Passing an open Wiralek slot (within 60 m, its shop open, the trend on days 1-7) with nothing
## else on brings a request card like Podwózka's: an office worker at Rondo Daszyńskiego wants
## today's trend before it's over. Accept, stop 2 s by the queue ("odbiór na aplikację": the
## queue lets the courier through), then deliver to a real address door within 300 m of the
## roundabout in 6 minutes. Pay 25 zł + 8 zł a km by road, +15 respect, a 10 zł tip *guess*; on
## the trend's day 6 or 7 the customer says "to już niemodne" and tips nothing (the joke). Late:
## half the pay, no tip, no respect *guess*. One activity at a time, like every job (jobs.gd,
## rides.gd and this script see each other's `busy`).

const Beacon := preload("res://scripts/beacon.gd")
const Missions := preload("res://scripts/missions.gd")
const CityLife := preload("res://scripts/city_life.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## Wiralek's pink (not the kebab's orange, not the passengers' teal).
const COLOUR := Color("#ff7ac8")
const FAIL_COLOUR := Color("#e2574c")
const OFFER_R := 60.0
const OFFER_LIFE := 10.0
## A slot offers again after this long (s).
const SLOT_COOL := 240.0
const PICKUP := 7.0
const PICKUP_SPEED := 2.5
const PICKUP_HOLD := 2.0
const ARRIVE := 7.0
const ARRIVE_SPEED := 2.5
const LIMIT := 360.0
const BASE := 25
const PER_KM := 8
const TIP := 10
const RESPECT := 15
const DEST_ID := "rondo_daszynskiego"
const DEST_R := 300.0
const RESULT_LIFE := 10.0
const CUSTOMERS := ["Ania z HR", "Tomek z IT", "Kasia z marketingu", "Paweł z finansów", "Ola z działu prawnego", "Michał ze sprzedaży"]

enum State { IDLE, OFFER, PICKUP, DELIVER, RESULT }

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var missions: Node
var rivals: Node
var jobs: Node
var rides: Node
var graph: LaneGraph
var map: Node3D
var car: CharacterBody3D
## city_life.gd: the slots' state and doors.
var life: Node3D
var state := State.IDLE
## Set by the game each frame (no offers from the helicopter, the title screen or the bench).
var flying := false
var away := false
## Spacer: no request comes by itself.
var quiet := false
var autopilot := false
## --trend-log: `trend job:` lines.
var log_on := false
var last_usec := 0
## The order: {slot, word, day, kerb, ring (pickup), door ring, road, customer, name}.
var order := {}
## The jobs done (the check, the log).
var done := 0

var _dest := Vector2.INF
var _cool := {}
var _t := 0.0
var _clock := 0.0
var _hold := 0.0
var _beacon: Node3D
var _rng := RandomNumberGenerator.new()
var _session := 0.0


## The pay for a delivery `road_m` metres by road on the trend's day `day`: {zl, base, tip,
## respect, out (day 6-7: "niemodne")}.
static func pay(road_m: float, day: int, on_time: bool) -> Dictionary:
	var base := BASE + roundi(PER_KM * road_m / 1000.0)
	var out := day >= 6
	var tip := TIP if on_time and not out else 0
	var zl := (base if on_time else roundi(base * 0.5)) + tip
	return {"zl": zl, "base": base, "tip": tip, "respect": RESPECT if on_time else 0, "out": out}


## An open slot offers the job: its shop open, the trend on days 1-7 (state: slot_state's).
static func offers(st: Dictionary, hour: float) -> bool:
	return int(st.get("day", 8)) < CityLife.CYCLE and hour >= float(CityLife.SHOP_HOURS[0]) and hour < float(CityLife.SHOP_HOURS[1])


func setup(nodes: Dictionary, places: Dictionary, world: Node3D) -> void:
	hud = nodes["hud"]
	dialogue = nodes["dialogue"]
	wallet = nodes["wallet"]
	missions = nodes["missions"]
	rivals = nodes.get("rivals")
	jobs = nodes["jobs"]
	rides = nodes.get("rides")
	graph = nodes["graph"]
	map = nodes["map"]
	car = nodes["car"]
	life = nodes["life"]
	_rng.randomize()
	_dest = places.get(DEST_ID, Vector2.INF)
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#2f6fb5"))
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func() -> void:
		if state == State.PICKUP or state == State.DELIVER:
			_fail(["Anulowane", "Cancelled"]))


func busy() -> bool:
	return state != State.IDLE and state != State.OFFER


func has_target() -> bool:
	return state == State.PICKUP or state == State.DELIVER


func target_position() -> Vector3:
	return order["ring"] if state == State.PICKUP else order["door_ring"]


func target_colour() -> Color:
	return COLOUR


func primary() -> bool:
	if state == State.OFFER or state == State.RESULT:
		_on_card(0)
		return true
	return false


func secondary() -> bool:
	if state == State.OFFER:
		_on_card(1)
		return true
	return false


func _free() -> bool:
	if flying or away or quiet or car.in_water or missions.has_target():
		return false
	if not (missions.state == Missions.State.CLOSED or missions.state == Missions.State.RINGING):
		return false
	if jobs != null and jobs.own_busy():
		return false
	if rides != null and rides.state != 0:
		return false
	return rivals == null or not rivals.busy()


func _process(dt: float) -> void:
	if life == null or graph == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	if not away:
		_session += dt
	match state:
		State.IDLE:
			if int(_session * 2.0) != int((_session - dt) * 2.0):
				_look()
		State.OFFER:
			if flying or away or (jobs != null and jobs.own_busy()) or (rides != null and rides.busy()):
				_withdraw()
			elif autopilot and _t > 2.0:
				_accept()
			elif _t > OFFER_LIFE:
				_withdraw()
		State.PICKUP:
			_pickup_tick(dt)
		State.DELIVER:
			_deliver_tick(dt)
		State.RESULT:
			if _t > RESULT_LIFE:
				_release()
	last_usec = Time.get_ticks_usec() - t0


## Twice a second: an open slot within 60 m offers the job.
func _look() -> void:
	if not _free() or life.slots_now.is_empty() or _dest == Vector2.INF:
		return
	var p := Vector2(car.global_position.x, car.global_position.z)
	var hour: float = life.hour_now()
	for i in life.slot_doors.size():
		var door: Vector2 = life.slot_doors[i]
		if door == Vector2.INF or p.distance_to(door) > OFFER_R or _session < float(_cool.get(i, 0.0)):
			continue
		if offers(life.slots_now[i], hour):
			_cool[i] = _session + SLOT_COOL
			offer(i)
			return


## The request at slot `i` (--trend-job too). False if no door fits.
func offer(i: int) -> bool:
	var door: Vector2 = life.slot_doors[i]
	var st: Dictionary = life.slots_now[i]
	var k: Dictionary = jobs._kerb(door, door - life.slot_out[i] * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 7919 + i * 31 + int(st["cycle"]) * 3
	var dest := _dest
	var to: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, 0.0, 9000.0, rng,
			func(a: Dictionary) -> bool: return (a["door"] as Vector2).distance_to(dest) <= DEST_R)
	if to.is_empty():
		if log_on:
			print("trend job: no door by Rondo Daszyńskiego reached from slot %d" % (i + 1))
		return false
	order = {"slot": i, "word": str(st["word"]), "day": int(st["day"]), "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y),
			"door_ring": to["ring"], "road": float(to["road"]), "name": str(to["name"]),
			"customer": CUSTOMERS[rng.randi() % CUSTOMERS.size()]}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("NA CZASIE · %s" % order["word"], "Biuro z Ronda Daszyńskiego chce trend, zanim minie. Dowóz w 6 min.",
			PackedStringArray(["ACCEPT", "SKIP"]), COLOUR, "On trend · %s" % st["word"],
			"Rondo Daszyńskiego wants it before it's over. 6 min to deliver.")
	hud.ticker_out()
	if log_on:
		print("trend job: offer at slot %d (day %d, %s) for %s, %s, %.0f m by road" % [i + 1, order["day"], order["word"],
				order["customer"], order["name"], order["road"]])
	return true


func _withdraw() -> void:
	hud.hide_card()
	state = State.IDLE
	_t = 0.0


func _on_card(index: int) -> void:
	match state:
		State.OFFER:
			if index == 0:
				_accept()
			else:
				_withdraw()
		State.RESULT:
			_release()


func _accept() -> void:
	state = State.PICKUP
	_t = 0.0
	_hold = 0.0
	hud.hide_card()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_challenge()
	_beacon.recolour(COLOUR)
	_beacon.waving = false
	_beacon.place(order["ring"], PICKUP - 0.5, true, false)
	hud.toast("Na czasie: odbiór przy kolejce", "On trend: pick up by the queue")
	if log_on:
		print("trend job: accepted")


func _pickup_tick(dt: float) -> void:
	var d := _flat(car.global_position, order["ring"])
	if d < PICKUP and car.vel.length() < PICKUP_SPEED and not flying:
		_hold += dt
		if _hold >= PICKUP_HOLD:
			state = State.DELIVER
			_clock = 0.0
			_t = 0.0
			_beacon.waving = true
			_beacon.place(order["door_ring"], ARRIVE - 0.5)
			hud.toast("Odbiór na aplikację: kolejka przepuszcza kuriera", "App pickup: the queue lets the courier through")
			if log_on:
				print("trend job: picked up at slot %d, %.0f m by road to go" % [int(order["slot"]) + 1, order["road"]])
			return
	else:
		_hold = 0.0
	hud.show_status("NA CZASIE · ODBIÓR", "", "%d m" % roundi(d), "Stań przy kolejce na 2 s", _hold / PICKUP_HOLD, COLOUR, "", {},
			"Stop by the queue for 2 s")


func _deliver_tick(dt: float) -> void:
	_clock += dt
	var d := _flat(car.global_position, order["door_ring"])
	if d < ARRIVE and car.vel.length() < ARRIVE_SPEED and not flying:
		_arrive()
		return
	var left := LIMIT - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := ["Jedź do różowego światła", "Head for the pink beacon"] if d > 40.0 else ["Stań pod drzwiami", "Stop at the door"]
	if left <= 0.0:
		hint = ["Spóźnione, ale dowieź", "Late, but deliver it"]
	hud.show_status("NA CZASIE → %s" % order["name"], clock, "%d m" % roundi(d), hint[0], clampf(_clock / LIMIT, 0.0, 1.0),
			COLOUR if left > 0.0 else FAIL_COLOUR, "", {}, hint[1])


func _arrive() -> void:
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	var on_time := _clock <= LIMIT
	var r := pay(float(order["road"]), int(order["day"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["", ""]
	if bool(r["out"]):
		var l: Array = dialogue.line("viral", "late", true) if dialogue != null else []
		if not l.is_empty():
			line = [str(l[0]), str(l[1])]
	elif not on_time:
		line = ["Spóźnione. Trend poszedł dalej beze mnie.", "Late. The trend moved on without me."]
	else:
		line = ["Jeszcze ciepłe i jeszcze modne. Dziękuję!", "Still warm and still trendy. Thank you!"]
	var head := "NA CZASIE · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	hud.show_side_card(head, body, PackedStringArray(["OK"]), COLOUR, "On trend · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered %s to %s in %.0f s (%s, trend day %d): +%d zł (base %d, tip %d), +%d respect%s" % [order["word"],
			order["name"], _clock, "on time" if on_time else "late", int(order["day"]), int(r["zl"]), int(r["base"]), int(r["tip"]),
			int(r["respect"]), ", \"to już niemodne\"" if bool(r["out"]) else ""])


func _fail(words: Array) -> void:
	hud.toast(str(words[0]), str(words[1]))
	if log_on:
		print("trend job: %s" % words[1])
	_release()


func _release() -> void:
	state = State.IDLE
	_t = 0.0
	_beacon.visible = false
	hud.hide_card()
	hud.hide_status()
	missions.paused = false
	missions.close()
	order = {}


## --autopilot: the car slides straight to the pickup, then the door (as the missions' autopilot).
func drive_player() -> bool:
	if not autopilot or not has_target():
		return false
	var to3: Vector3 = target_position() - car.global_position
	var to := Vector3(to3.x, 0.0, to3.z)
	var d := to.length()
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	var dt := get_process_delta_time()
	if d > 1.0:
		var step := minf(d - 0.5, 22.0 * dt)
		car.global_position += to / d * step
		car.global_position.y = map.ground_height(car.global_position.x, car.global_position.z) + 0.05
		car.rotation.y = atan2(-to.x, -to.z)
	return true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
