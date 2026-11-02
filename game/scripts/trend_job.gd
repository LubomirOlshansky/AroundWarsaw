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
##
## Trend follow-up: **"Limitka" · the limited drop** (docs/design/trends-2025-26.md). On Fridays
## 16:00-18:30 PISTACJA DO KOŃCA sells a limited run (crowds.gd `pistacja_drop`). A car within 60 m
## of its door gets the request: a friend wants a box, 5 minutes before it melts. Stand in the
## queue's ring 5 s ("stoisz w kolejce"); if the drop ends first it is "wyprzedane" and the job
## drops. Deliver to a door 500-1800 m away in 5 minutes. Pay 40 zł + 10 zł a km, +12 respect, a
## 15 zł tip *guess*; late: half, no tip, no respect.##
## **"Mlask" · Cringulo's review** (docs/design/gaulle-and-food-hype.md G5): Cringulo, the food
## reviewer on wheels (a parody type, never the real man), parks his cream van at one of four
## spots by the weekday (ML_SPOTS), 11:00-21:00. Stop by it: he wants a bite of a new place (the
## nearest open Wiralek slot on its days 1-3, else KUKŁA's nearest door). Stop 2 s there ("na
## wynos dla Cringula"), bring it back while it's warm (5 min), get his review on a card in his
## grade, the MLASK, then take his sticker to the place in 4 min: 40 zł + 10 zł a km (both legs),
## +15 respect, a 15 zł tip *guess*, and the "Cringulo effect": that place's queue stands at its
## longest for the rest of the game day (crowds.gd `cringulo`). A cold delivery: three MLASKI,
## half the pay, no tip, no respect, the queue grows anyway (any review is a review).

const Beacon := preload("res://scripts/beacon.gd")
const Models := preload("res://scripts/models.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")
const Missions := preload("res://scripts/missions.gd")
const CityLife := preload("res://scripts/city_life.gd")
const Crowds := preload("res://scripts/crowds.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")

## Wiralek's pink (not the kebab's orange, not the passengers' teal).
const COLOUR := Color("#ff7ac8")
const FAIL_COLOUR := Color("#e2574c")
const OFFER_R := 60.0
const OFFER_LIFE := 10.0
## A slot offers again after this long (s).
const SLOT_COOL := 240.0
const PICKUP := StopAssist.RING
const PICKUP_SPEED := StopAssist.STOP_SPEED
const PICKUP_HOLD := 1.5
const ARRIVE := StopAssist.RING
const ARRIVE_SPEED := StopAssist.STOP_SPEED
const LIMIT := 360.0
const BASE := 25
const PER_KM := 8
const TIP := 10
const RESPECT := 15
const DROP_BASE := 40
const DROP_PER_KM := 10
const DROP_TIP := 15
const DROP_RESPECT := 12
const DROP_HOLD := 5.0
const DROP_LIMIT := 300.0
const DROP_FROM := 500.0
const DROP_TO := 1800.0
const DROP_COLOUR := Color("#8fc46a")
const DROP_FRIENDS := ["Zuzia", "Bartek", "Magda", "Kuba", "Iga", "Olek"]
## "Czwarty" (docs/design/padel.md): PADELNIA's fourth player. Fetch a player from a door 400-1500 m
## away and bring them to the court's door in 7 minutes. 45 zł + 8 zł a km (there and back), +14
## respect, a 15 zł tip *guess*; late: half, no tip, no respect.
const CZ_BASE := 45
const CZ_PER_KM := 8
const CZ_TIP := 15
const CZ_RESPECT := 14
const CZ_LIMIT := 420.0
const CZ_FROM := 400.0
const CZ_TO := 1500.0
const CZ_MIN_QUEUE := 10
const CZ_COLOUR := Color("#2fd0e0")
const CZ_PLAYERS := ["Prezes z Mokotowa", "Pani Basia", "Trener Dominik", "kuzyn Kuby", "Ola z recepcji", "Michał od Excela"]
## "Mlask" (G5): the van's spots (places.json ids) by weekday, its hours, the offer's reach, the
## legs' limits, the pay *guess*.
const ML_SPOTS := ["plac_zbawiciela", "hala_koszyki", "kebab_palma", "plac_trzech_krzyzy"]
const ML_HOURS := [11.0, 21.0]
const ML_OFFER_R := 30.0
const ML_COOL := 300.0
const ML_WARM := 300.0
const ML_STICKER := 240.0
const ML_BASE := 40
const ML_PER_KM := 10
const ML_TIP := 15
const ML_RESPECT := 15
const ML_COLOUR := Color("#ffbf5f")
const ML_GRADES := [7.5, 8.0, 8.5, 9.0, 9.5]
const ML_COLD_GRADE := 3.0
const VAN_CREAM := Color("#efe6cf")
const VAN_PINK := Color("#d9467f")
const VAN_DARK := Color("#26262b")
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
## crowds.gd (the PISTACJA site and its drop); may be null.
var crowds: Node
var state := State.IDLE
## Set by the game each frame (no offers from the helicopter, the title screen or the bench).
var flying := false
var away := false
## Spacer: no request comes by itself.
var quiet := false
var autopilot := false
## --trend-job=4: the drop never ends (the test run).
var force_drop := false
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
## "Mlask": the places' points (setup), the van {spot, at: Vector3, ring: Vector3, yaw} or {}, its node.
var _places := {}
var van := {}
var _van_node: MeshInstance3D
var _van_day := -1


## The pay for a delivery `road_m` metres by road on the trend's day `day`: {zl, base, tip,
## respect, out (day 6-7: "niemodne")}.
static func pay(road_m: float, day: int, on_time: bool) -> Dictionary:
	var base := BASE + roundi(PER_KM * road_m / 1000.0)
	var out := day >= 6
	var tip := TIP if on_time and not out else 0
	var zl := (base if on_time else roundi(base * 0.5)) + tip
	return {"zl": zl, "base": base, "tip": tip, "respect": RESPECT if on_time else 0, "out": out}


## The limited drop's pay for a delivery `road_m` metres by road: {zl, base, tip, respect}.
static func drop_pay(road_m: float, on_time: bool) -> Dictionary:
	var base := DROP_BASE + roundi(DROP_PER_KM * road_m / 1000.0)
	var tip := DROP_TIP if on_time else 0
	return {"zl": (base if on_time else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": DROP_RESPECT if on_time else 0}


## The "Czwarty" pay for `road_m` metres by road (one way): {zl, base, tip, respect}.
static func cz_pay(road_m: float, on_time: bool) -> Dictionary:
	var base := CZ_BASE + roundi(CZ_PER_KM * 2.0 * road_m / 1000.0)
	var tip := CZ_TIP if on_time else 0
	return {"zl": (base if on_time else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": CZ_RESPECT if on_time else 0}


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
	crowds = nodes.get("crowds")
	_rng.randomize()
	_dest = places.get(DEST_ID, Vector2.INF)
	_places = places
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(COLOUR, Color("#2f6fb5"))
	_van_node = MeshInstance3D.new()
	_van_node.mesh = van_mesh()
	_van_node.material_override = Models.material()
	_van_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_van_node.visible = false
	world.add_child(_van_node)
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


## Where the car should stop now (stop_assist.gd): the queue, then the door.
func stop_spot() -> Vector3:
	return target_position() if has_target() else Vector3.INF


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
			if _is_ml() and str(order.get("stage", "")) == "review":
				if autopilot and _t > 2.0:
					_start_sticker()
			elif _t > RESULT_LIFE:
				_release()
	last_usec = Time.get_ticks_usec() - t0


## Twice a second: an open slot within 60 m offers the job.
func _look() -> void:
	if not _free() or life.slots_now.is_empty() or _dest == Vector2.INF:
		return
	var p := Vector2(car.global_position.x, car.global_position.z)
	var hour: float = life.hour_now()
	_van_tick(hour, life.weekday_now())
	if not van.is_empty() and _van_node.visible and p.distance_to(Vector2(van["ring"].x, van["ring"].z)) <= ML_OFFER_R \
			and _session >= float(_cool.get(-3, 0.0)):
		_cool[-3] = _session + ML_COOL
		if offer_mlask():
			return
	if crowds != null and Crowds.pistacja_drop(hour, life.weekday_now()) and crowds.by_id.has(Crowds.PISTACJA_ID):
		var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]
		if p.distance_to(site["door"]) <= OFFER_R and _session >= float(_cool.get(-1, 0.0)):
			_cool[-1] = _session + SLOT_COOL
			if offer_drop():
				return
	if crowds != null and crowds.by_id.has(Crowds.PADEL_ID) and int(Crowds.padel_queue(hour, life.weekday_now())[0]) >= CZ_MIN_QUEUE:
		var psite: Dictionary = crowds.sites[crowds.by_id[Crowds.PADEL_ID]]
		if p.distance_to(psite["door"]) <= OFFER_R and _session >= float(_cool.get(-2, 0.0)):
			_cool[-2] = _session + SLOT_COOL
			if offer_czwarty():
				return
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


## The limited drop's request at PISTACJA (--trend-job=4 too). False if no kerb or door fits.
func offer_drop() -> bool:
	if crowds == null or not crowds.by_id.has(Crowds.PISTACJA_ID):
		return false
	var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PISTACJA_ID]]
	var door: Vector2 = site["door"]
	var out: Vector2 = site["out"]
	var k: Dictionary = jobs._kerb(door, door - out * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 6007 + 17
	var to: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, DROP_FROM, DROP_TO, rng, func(_a: Dictionary) -> bool: return true)
	if to.is_empty():
		if log_on:
			print("trend job: no door %.0f-%.0f m from PISTACJA" % [DROP_FROM, DROP_TO])
		return false
	order = {"kind": "drop", "slot": -1, "word": "PISTACJA", "day": 0, "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y),
			"door_ring": to["ring"], "road": float(to["road"]), "name": str(to["name"]),
			"customer": DROP_FRIENDS[rng.randi() % DROP_FRIENDS.size()]}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("LIMITKA · PISTACJA", "Dropu jest tylko do 18:30. Znajomy chce pudełko, zanim się roztopi. Dowóz w 5 min.",
			PackedStringArray(["ACCEPT", "SKIP"]), DROP_COLOUR, "Limited drop · PISTACJA",
			"A friend wants a box before it melts. The drop ends at 18:30. 5 min to deliver.")
	hud.ticker_out()
	if log_on:
		print("trend job: drop offer at PISTACJA for %s, %s, %.0f m by road" % [order["customer"], order["name"], order["road"]])
	return true


## The "Czwarty" request at PADELNIA (--trend-job=5 too): the pickup is the player's door, the
## delivery the court's kerb. False if no kerb or door fits.
func offer_czwarty() -> bool:
	if crowds == null or not crowds.by_id.has(Crowds.PADEL_ID):
		return false
	var site: Dictionary = crowds.sites[crowds.by_id[Crowds.PADEL_ID]]
	var door: Vector2 = site["door"]
	var out: Vector2 = site["out"]
	var k: Dictionary = jobs._kerb(door, door - out * 4.0, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return false
	var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = done * 4001 + 29
	var from: Dictionary = jobs._pick_address(k["edge"], k["s"], kerb, CZ_FROM, CZ_TO, rng, func(_a: Dictionary) -> bool: return true)
	if from.is_empty():
		if log_on:
			print("trend job: no door %.0f-%.0f m from PADELNIA" % [CZ_FROM, CZ_TO])
		return false
	order = {"kind": "czwarty", "slot": -1, "word": "PADEL", "day": 0, "ring": from["ring"],
			"door_ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "road": float(from["road"]),
			"name": "PADELNIA", "customer": CZ_PLAYERS[rng.randi() % CZ_PLAYERS.size()], "from": str(from["name"])}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("CZWARTY · PADELNIA", "Grają we trzech. Zabierz %s spod %s i dowieź na kort w 7 min." % [order["customer"], order["from"]],
			PackedStringArray(["ACCEPT", "SKIP"]), CZ_COLOUR, "Fourth player · PADELNIA",
			"Three players are waiting. Fetch %s from %s and bring them to the court in 7 min." % [order["customer"], order["from"]])
	hud.ticker_out()
	if log_on:
		print("trend job: czwarty offer at PADELNIA: %s from %s, %.0f m by road" % [order["customer"], order["from"], order["road"]])
	return true


# --- "Mlask": Cringulo's review (G5) ----------------------------------------------------------

## The van's mesh: a cream box van, a pink band, dark windows, the big lens on the roof, in the
## models' one material (~150 triangles). Local frame: +Z forward, origin on the ground.
static func van_mesh() -> ArrayMesh:
	var st := Models._begin()
	Models.box(st, Vector3(0, 1.25, 0), Vector3(2.0, 1.9, 5.2), VAN_CREAM)
	Models.box(st, Vector3(0, 0.95, 0), Vector3(2.04, 0.28, 5.24), VAN_PINK)
	Models.box(st, Vector3(0, 1.75, 2.35), Vector3(1.86, 0.6, 0.56), VAN_DARK)
	Models.box(st, Vector3(1.01, 1.7, 0.6), Vector3(0.04, 0.55, 1.6), VAN_DARK)
	Models.box(st, Vector3(-1.01, 1.7, 0.6), Vector3(0.04, 0.55, 1.6), VAN_DARK)
	for z: float in [-1.7, 1.7]:
		for x: float in [-0.95, 0.95]:
			Models.box(st, Vector3(x, 0.32, z), Vector3(0.3, 0.64, 0.64), VAN_DARK)
	Models.box(st, Vector3(0, 2.3, -0.4), Vector3(0.5, 0.2, 0.5), VAN_DARK)
	Models.box(st, Vector3(0, 2.62, -0.4), Vector3(0.62, 0.44, 0.9), VAN_DARK)
	Models.box(st, Vector3(0, 2.62, 0.12), Vector3(0.5, 0.36, 0.16), VAN_PINK)
	return st.commit()


## Is the van out at `hour`? Its spot on `weekday` (1 Monday .. 7 Sunday).
static func van_out(hour: float) -> bool:
	return hour >= float(ML_HOURS[0]) and hour < float(ML_HOURS[1])


static func van_spot(weekday: int) -> String:
	return ML_SPOTS[posmod(weekday, ML_SPOTS.size())]


## The grade's words: [Polish, English] ("7,5 MLASKA", "8 MLASKÓW", "3 MLASKI"; "7.5 SMACKS").
static func grade_words(g: float) -> Array:
	var whole := is_equal_approx(g, roundf(g))
	var num_pl := ("%d" % int(g)) if whole else ("%d,%d" % [int(g), int(roundf(g * 10.0)) % 10])
	var num_en := ("%d" % int(g)) if whole else ("%.1f" % g)
	var word := "MLASKA"
	if whole:
		var n := int(g)
		word = "MLASK" if n == 1 else ("MLASKI" if n % 10 >= 2 and n % 10 <= 4 and (n % 100 < 12 or n % 100 > 14) else "MLASKÓW")
	return ["%s %s" % [num_pl, word], "%s SMACK%s" % [num_en, "" if num_en == "1" else "S"]]


## The pay for `road_m` metres by road (the bring leg; the sticker goes back the same way).
static func ml_pay(road_m: float, warm: bool, on_time: bool) -> Dictionary:
	var base := ML_BASE + roundi(ML_PER_KM * 2.0 * road_m / 1000.0)
	var good := warm and on_time
	var tip := ML_TIP if good else 0
	return {"zl": (base if good else roundi(base * 0.5)) + tip, "base": base, "tip": tip, "respect": ML_RESPECT if good else 0}


## Puts the van at today's spot while it is out (twice a second, from _look).
func _van_tick(hour: float, weekday: int) -> void:
	var out := van_out(hour)
	if weekday != _van_day:
		_van_day = weekday
		van = _park_van(van_spot(weekday))
	var show := out and not van.is_empty()
	if _van_node != null and _van_node.visible != show:
		_van_node.visible = show


## The van by the kerb nearest the place `spot` (or at the point `near`): {spot, at, ring, yaw}.
func _park_van(spot: String, near := Vector2.INF) -> Dictionary:
	var p: Vector2 = near if near != Vector2.INF else _places.get(spot, Vector2.INF)
	if p == Vector2.INF:
		return {}
	var hit: Array = graph.snap(p, 80.0)
	if hit.is_empty():
		return {}
	var road: Vector2 = graph.point_at(hit[0], hit[2])
	var toward := road if road.distance_to(p) > 1.0 else p + Vector2(4.0, 0.0)
	var k: Dictionary = jobs._kerb(road + (p - road).normalized() * 0.5 if road.distance_to(p) > 1.0 else p, toward, 3.5, [1.4, 2.2, 3.0])
	if k.is_empty():
		return {}
	var side: Vector2 = k["side"]
	var c: Vector2 = k["centre"]
	var ring2 := c + side * 2.0
	var at2 := c + side * 4.4
	var y: float = graph.surface(k["edge"], ring2)
	var yaw := atan2(side.y, -side.x)
	var v := {"spot": spot, "ring": Vector3(ring2.x, y, ring2.y), "at": Vector3(at2.x, map.ground_height(at2.x, at2.y), at2.y), "yaw": yaw}
	if _van_node != null:
		_van_node.global_transform = Transform3D(Basis(Vector3.UP, yaw), v["at"])
	if log_on:
		print("trend job: Cringulo's van at %s (%.0f, %.0f)" % [spot, at2.x, at2.y])
	return v


## The new place he wants: the nearest open Wiralek slot on its days 1-3, else KUKŁA's nearest
## door: {name, ring: Vector3, edge, s, slot (index or -1), site (crowds id or "")} or {}.
func _new_place(from: Vector2, hour: float) -> Dictionary:
	var best := {}
	var bd := INF
	for i in life.slot_doors.size():
		var door: Vector2 = life.slot_doors[i]
		var st: Dictionary = life.slots_now[i]
		if door == Vector2.INF or int(st.get("day", 8)) > 3 or not offers(st, hour):
			continue
		var d := door.distance_to(from)
		if d < bd:
			var k: Dictionary = jobs._kerb(door, door - life.slot_out[i] * 4.0, 3.5, [1.4, 2.2, 3.0])
			if not k.is_empty():
				bd = d
				var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
				best = {"name": str(st["word"]), "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "edge": k["edge"],
						"s": k["s"], "slot": i, "site": CityLife.SLOTS[i]}
	if not best.is_empty() or crowds == null:
		return best
	for id: String in Crowds.KUKLA:
		if not crowds.by_id.has(id):
			continue
		var site: Dictionary = crowds.sites[crowds.by_id[id]]
		if not site.has("door"):
			continue
		var door: Vector2 = site["door"]
		var d := door.distance_to(from)
		if d < bd:
			var k: Dictionary = jobs._kerb(door, door - (site["out"] as Vector2) * 4.0, 3.5, [1.4, 2.2, 3.0])
			if not k.is_empty():
				bd = d
				var kerb: Vector2 = (k["centre"] as Vector2) + (k["side"] as Vector2) * 2.0
				best = {"name": "KUKŁA", "ring": Vector3(kerb.x, graph.surface(k["edge"], kerb), kerb.y), "edge": k["edge"],
						"s": k["s"], "slot": -1, "site": id}
	return best


## Cringulo's request by his van (--trend-job=6 too, which first parks the van by the car).
func offer_mlask(force_here := false) -> bool:
	if force_here:
		var p := Vector2(car.global_position.x, car.global_position.z)
		van = _park_van("here", p + Vector2(0.0, -12.0))
		_van_day = life.weekday_now() if life != null else -1
		if _van_node != null:
			_van_node.visible = not van.is_empty()
	if van.is_empty():
		return false
	var vr: Vector3 = van["ring"]
	var place := _new_place(Vector2(vr.x, vr.z), life.hour_now())
	if place.is_empty():
		if log_on:
			print("trend job: Cringulo found no new place open")
		return false
	var road := Vector2(vr.x, vr.z).distance_to(Vector2(place["ring"].x, place["ring"].z)) * 1.3
	order = {"kind": "mlask", "stage": "fetch", "slot": int(place["slot"]), "word": str(place["name"]), "day": 0,
			"ring": place["ring"], "door_ring": vr, "road": road, "name": "Cringulo", "customer": "Cringulo",
			"site": str(place["site"]), "place_ring": place["ring"], "warm": true}
	state = State.OFFER
	_t = 0.0
	hud.show_side_card("MLASK · CRINGULO", "Siema, tu Cringulo! %s, nowe miejsce. Weź mi coś, tylko ma być ciepłe." % order["word"],
			PackedStringArray(["ACCEPT", "SKIP"]), ML_COLOUR, "Smack · Cringulo",
			"Hi, Cringulo here! %s, a new place. Grab me something, and keep it warm." % order["word"])
	hud.ticker_out()
	if log_on:
		print("trend job: Cringulo's offer: %s, %.0f m" % [order["word"], road])
	return true


func _is_ml() -> bool:
	return str(order.get("kind", "")) == "mlask"


## At the van: the review card; the sticker leg starts when it is closed.
func _arrive_ml_review() -> void:
	var warm := _clock <= ML_WARM
	order["warm"] = warm
	order["bring_s"] = _clock
	var g: float = ML_GRADES[_rng.randi() % ML_GRADES.size()] if warm else ML_COLD_GRADE
	order["grade"] = g
	var gw := grade_words(g)
	var l: Array = dialogue.line("cringulo_review", "warm" if warm else "cold", true) if dialogue != null else []
	var line := [str(l[0]), str(l[1])] if not l.is_empty() else ["Je się. Mlaska się.", "One eats. One smacks."]
	order["stage"] = "review"
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	hud.show_side_card("RECENZJA · %s" % gw[0], "„%s”\nZawieź naklejkę do %s w 4 min." % [line[0], order["word"]],
			PackedStringArray(["NAKLEJKA"]), ML_COLOUR, "Review · %s" % gw[1], "\"%s\"\nTake the sticker to %s in 4 min." % [line[1], order["word"]])
	print("trend job: Cringulo reviewed %s after %.0f s (%s): %s" % [order["word"], _clock, "warm" if warm else "cold", gw[0]])


## The sticker leg: back to the place.
func _start_sticker() -> void:
	order["stage"] = "sticker"
	order["door_ring"] = order["place_ring"]
	state = State.DELIVER
	_clock = 0.0
	_t = 0.0
	hud.hide_card()
	_beacon.waving = true
	_beacon.place(order["door_ring"], ARRIVE - 0.5)
	hud.toast("Naklejka MLASK: do %s" % order["word"], "The MLASK sticker: to %s" % order["word"])


func _arrive_ml_sticker() -> void:
	var on_time := _clock <= ML_STICKER
	var r := ml_pay(float(order["road"]), bool(order["warm"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	if crowds != null and crowds.has_method("cringulo_boost") and str(order["site"]) != "":
		crowds.cringulo_boost(str(order["site"]))
	var l: Array = dialogue.line("cringulo_owner", "", false) if dialogue != null else []
	var line := [str(l[0]), str(l[1])] if not l.is_empty() else ["Cringulo nas polecił? Otwieram drugą kasę.", "Cringulo recommends us? Opening a second till."]
	var gw := grade_words(float(order["grade"]))
	var head := "MLASK · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n%s · +%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["word"], gw[0], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n%s · +%d zł (tip %d zł), +%d respect" % [line[1], gw[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	order["stage"] = "done"
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card(head, body, PackedStringArray(["OK"]), ML_COLOUR, "Smack · +%d zł" % int(r["zl"]), body_en)
	print("trend job: the MLASK sticker at %s in %.0f s (%s, %s): +%d zł (base %d, tip %d), +%d respect, the queue grows" % [
			order["word"], _clock, "warm" if bool(order["warm"]) else "cold", "on time" if on_time else "late", int(r["zl"]),
			int(r["base"]), int(r["tip"]), int(r["respect"])])


func _is_cz() -> bool:
	return str(order.get("kind", "")) == "czwarty"


func _is_drop() -> bool:
	return str(order.get("kind", "")) == "drop"


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
			if _is_ml() and str(order.get("stage", "")) == "review":
				_start_sticker()
			else:
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
	_beacon.recolour(ML_COLOUR if _is_ml() else (DROP_COLOUR if _is_drop() else (CZ_COLOUR if _is_cz() else COLOUR)))
	_beacon.waving = false
	_beacon.place(order["ring"], PICKUP - 0.5, true, false)
	if _is_ml():
		hud.toast("Mlask: na wynos dla Cringula", "Smack: a takeaway for Cringulo")
	elif _is_drop():
		hud.toast("Limitka: stań w kolejce po pudełko", "Limited drop: join the queue for a box")
	elif _is_cz():
		hud.toast("Czwarty: jedź po gracza", "Fourth player: go and fetch them")
	else:
		hud.toast("Na czasie: odbiór przy kolejce", "On trend: pick up by the queue")
	if log_on:
		print("trend job: accepted")


func _pickup_tick(dt: float) -> void:
	var d := _flat(car.global_position, order["ring"])
	var drop := _is_drop()
	if drop and not force_drop and crowds != null and life != null and not Crowds.pistacja_drop(life.hour_now(), life.weekday_now()):
		_fail(["Wyprzedane! Drop się skończył.", "Sold out! The drop is over."])
		return
	var hold_for := DROP_HOLD if drop else PICKUP_HOLD
	if d < PICKUP and car.vel.length() < PICKUP_SPEED and not flying:
		_hold += dt
		if _hold >= hold_for:
			state = State.DELIVER
			_clock = 0.0
			_t = 0.0
			_beacon.waving = true
			_beacon.place(order["door_ring"], ARRIVE - 0.5)
			if _is_ml():
				hud.toast("Kolejka przepuszcza: to dla Cringula! Wieź, póki ciepłe", "The queue lets you through: it's for Cringulo! Bring it warm")
			elif _is_cz():
				hud.toast("Jest! Na kort, grają bez ciebie", "Got them! To the court, they're starting without you")
			elif drop:
				hud.toast("Ostatnie pudełko! Zanim się roztopi", "The last box! Before it melts")
			else:
				hud.toast("Odbiór na aplikację: kolejka przepuszcza kuriera", "App pickup: the queue lets the courier through")
			if log_on:
				print("trend job: picked up at slot %d, %.0f m by road to go" % [int(order["slot"]) + 1, order["road"]])
			return
	else:
		_hold = 0.0
	if drop:
		hud.show_status("LIMITKA · KOLEJKA", "", "%d m" % roundi(d), "Stań w kolejce", _hold / hold_for, DROP_COLOUR, "", {},
				"Wait in the queue")
		return
	if _is_ml():
		hud.show_status("MLASK · %s" % order["word"], "", "%d m" % roundi(d), "Stań przy kolejce", _hold / PICKUP_HOLD, ML_COLOUR, "", {},
				"Stop by the queue")
		return
	if _is_cz():
		hud.show_status("CZWARTY · ODBIÓR", "", "%d m" % roundi(d), "Stań pod drzwiami gracza", _hold / PICKUP_HOLD, CZ_COLOUR, "", {},
				"Stop at the player's door")
		return
	hud.show_status("NA CZASIE · ODBIÓR", "", "%d m" % roundi(d), "Stań przy kolejce", _hold / PICKUP_HOLD, COLOUR, "", {},
			"Stop by the queue")


func _deliver_tick(dt: float) -> void:
	_clock += dt
	var d := _flat(car.global_position, order["door_ring"])
	if d < ARRIVE and car.vel.length() < ARRIVE_SPEED and not flying:
		_arrive()
		return
	if _is_ml():
		_ml_status(d)
		return
	var drop := _is_drop()
	var cz := _is_cz()
	var limit := DROP_LIMIT if drop else (CZ_LIMIT if cz else LIMIT)
	var tint := DROP_COLOUR if drop else (CZ_COLOUR if cz else COLOUR)
	var left := limit - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := (["Jedź do turkusowego światła", "Head for the teal beacon"] if cz else ["Jedź do zielonego światła", "Head for the green beacon"] if drop else ["Jedź do różowego światła", "Head for the pink beacon"]) if d > 40.0 else ["Stań pod drzwiami", "Stop at the door"]
	if left <= 0.0:
		hint = ["Spóźnione, ale dowieź", "Late, but deliver it"]
	hud.show_status(("CZWARTY → %s" if cz else "LIMITKA → %s" if drop else "NA CZASIE → %s") % order["name"], clock, "%d m" % roundi(d), hint[0],
			clampf(_clock / limit, 0.0, 1.0), tint if left > 0.0 else FAIL_COLOUR, "", {}, hint[1])


func _ml_status(d: float) -> void:
	var sticker := str(order.get("stage", "")) == "sticker"
	var limit := ML_STICKER if sticker else ML_WARM
	var left := limit - _clock
	var clock := ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left > 0.0 else "+%d:%02d" % [int(-left) / 60, int(-left) % 60]
	var hint := ["Stań przy drzwiach", "Stop at the door"] if sticker else ["Do vana Cringula, póki ciepłe", "To Cringulo's van while it's warm"]
	if left <= 0.0:
		hint = ["Spóźnione, ale dowieź", "Late, but deliver it"] if sticker else ["Stygnie… jedź dalej", "It's going cold… keep going"]
	hud.show_status(("MLASK → %s" % order["word"]) if sticker else "MLASK → CRINGULO", clock, "%d m" % roundi(d), hint[0],
			clampf(_clock / limit, 0.0, 1.0), ML_COLOUR if left > 0.0 else FAIL_COLOUR, "", {}, hint[1])


func _arrive() -> void:
	if _is_ml():
		if str(order.get("stage", "")) == "sticker":
			_arrive_ml_sticker()
		else:
			_arrive_ml_review()
		return
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	if _is_drop():
		_arrive_drop()
		return
	if _is_cz():
		_arrive_cz()
		return
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


func _arrive_cz() -> void:
	var on_time := _clock <= CZ_LIMIT
	var r := cz_pay(float(order["road"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["Jesteśmy w czterech! Ściana nas nie zje.", "Four of us! The wall won't eat us."]
	if not on_time:
		line = ["Zagraliśmy w trzech. Piłka i tak wróciła.", "We played three-a-side. The ball came back anyway."]
	var head := "CZWARTY · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card(head, body, PackedStringArray(["OK"]), CZ_COLOUR, "Fourth player · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered %s (Czwarty) to PADELNIA in %.0f s (%s): +%d zł (base %d, tip %d), +%d respect" % [order["customer"], _clock,
			"on time" if on_time else "late", int(r["zl"]), int(r["base"]), int(r["tip"]), int(r["respect"])])


func _arrive_drop() -> void:
	var on_time := _clock <= DROP_LIMIT
	var r := drop_pay(float(order["road"]), on_time)
	wallet.pay(int(r["zl"]), int(r["respect"]), "trend")
	done += 1
	var line := ["Jeszcze zimne i jeszcze pistacjowe. Zdjęcie zrobione, dziękuję!", "Still cold and still pistachio. Photo taken, thank you!"]
	if not on_time:
		line = ["Roztopiło się. Wrzucę jako „vibe”.", "It melted. I'll post it as a \"vibe\"."]
	var head := "LIMITKA · +%d zł" % int(r["zl"])
	var body := "„%s” · %s\n+%d zł (napiwek %d zł), +%d szacunku" % [line[0], order["customer"], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	var body_en := "\"%s\"\n+%d zł (tip %d zł), +%d respect" % [line[1], int(r["zl"]), int(r["tip"]), int(r["respect"])]
	state = State.RESULT
	_t = 0.0
	hud.hide_status()
	_beacon.waving = false
	_beacon.place(order["door_ring"], ARRIVE - 0.5, false, true)
	hud.show_side_card(head, body, PackedStringArray(["OK"]), DROP_COLOUR, "Limited drop · +%d zł" % int(r["zl"]), body_en)
	print("trend job: delivered the PISTACJA drop to %s in %.0f s (%s): +%d zł (base %d, tip %d), +%d respect" % [order["name"], _clock,
			"on time" if on_time else "late", int(r["zl"]), int(r["base"]), int(r["tip"]), int(r["respect"])])


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
