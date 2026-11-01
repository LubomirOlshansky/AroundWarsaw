extends Node
## The night-buses loop (2026-10-31; docs/design/vision.md 3.5 "Buses", eggs E23-E25): the city
## buses at night and by day, on the traffic's own buses (traffic.gd's BUS pool of 8).
##
## - **The N sign**: 22:30-05:00 by the game clock (time_of_day.gd `local_clock`) every traffic
##   bus shows an amber N route sign (traffic.gd `night_sign`: the BUS MultiMesh swaps its mesh
##   for the bus with the sign: +0 draw calls, no shader change).
## - **The night hub at Dworzec Centralny**: every half hour from 22:30 to 04:30 a ring of 5-8
##   buses (seeded by the day and the slot) gathers in two rows at the kerb of Aleje
##   Jerozolimskie in front of the station (HUB_ROWS: the shelters on both sides), each arriving
##   within ARRIVE s of the slot and standing WAIT s (2-4 min), then driving on as any bus. The
##   ring is real only while the view is near (HUB_BAND): its buses are recruited from the
##   traffic's (an out-of-sight bus is taken over) or taken from the pool, parked at their bays
##   when the bay is out of sight, or driven in from upstream when it is in sight. E23: the
##   player at the ring (HUB_NEAR) while 5 or more stand there; the `bus_stop` night line once
##   per gathering.
## - **Bus stops**: the map's shelters beside a bus road (a class 0-1 edge's kerb lane, the
##   shelter on its right: `stop_from`); the STOPS_NEAR nearest within STOP_RANGE of the view get
##   1-2 waiting figures by day (06:00-22:00; pedestrians.gd's stop slots, +0 draw calls), the
##   hub's 2-3 at night while the ring stands; a `bus_stop` bubble when the car stops beside one.
## - **The horn** (`honk`: the HUD's horn and the B key): the player's own horn (sfx.gd
##   `horn_player`), the dogs bark (city_life.gd `horn`), walkers coming at the car turn round;
##   at most one honk per HORN_GAP s. Stopped at a stop, a honk calls a bus: the nearest one
##   within CALL_REACH that can drive there, or one from the pool upstream out of sight; it pulls
##   in by the car for CALL_WAIT s. E24 when it does (the `bus_stop` request line at the honk).
## - **E25, racing the night bus**: a bus leaving the hub's eastbound row while the player is at
##   the ring drives to the Palm (Rondo de Gaulle'a); the car there first, with no speed trap's
##   flash (police.gd `trap_flashes`) on the way, finds E25.
## Nothing runs per frame but a timer: one tick every TICK s.

const Traffic := preload("res://scripts/traffic.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")

const TICK := 0.5
## The N sign's hours (game clock).
const SIGN_FROM := 22.5
const SIGN_TO := 5.0
## The hub: the middle of the ring (between the carriageways in front of the station) and its
## two rows of bays, each [a shelter's point, the traffic's heading there, bays]. Bay 0 of a row
## has its front BAY_LEAD m past the shelter, the next BAY_GAP m behind it.
const HUB := Vector2(-1392.0, 652.0)
const HUB_ROWS := [[Vector2(-1392.7, 624.9), Vector2(-0.95, 0.31), 4], [Vector2(-1381.6, 680.6), Vector2(0.92, -0.39), 4]]
const BAY_LEAD := 10.0
const BAY_GAP := 20.0
## A ring bus stands this far right of its kerb lane's line: half a lane and a metre (at the kerb).
const BAY_PULL := 1.0
## The gatherings: from 22:30, every half hour, SLOTS of them (the last at 04:30); each lives
## LIFE s; a bus arrives within ARRIVE s and stands WAIT s; RING buses.
const SLOT_FIRST := 22.5
const SLOTS := 13
const LIFE := 420.0
const ARRIVE := 50.0
const WAIT := Vector2(120.0, 240.0)
const RING := Vector2i(5, 8)
## E23: the car this near the hub's middle with E23_BUSES standing.
const HUB_NEAR := 60.0
const E23_BUSES := 5
## The ring is made real while the view's focus is this near the hub (and taken away past
## HUB_BAND + 120 m).
const HUB_BAND := 330.0
## A bus driven in starts this far upstream of its bay (the first spot out of sight).
const UPSTREAM := [140.0, 200.0, 260.0, 320.0]
## E25: the car this near the hub when the racer leaves; the Palm's reach; the race's limit.
const RACE_START := 90.0
const PALM_REACH := 30.0
const RACE_MAX := 360.0
## Bus stops: a shelter this far right of a bus road's kerb lane line (m); the nearest STOPS_NEAR
## within STOP_RANGE of the view get figures; the day's hours; the stop bubble's reach and gaps.
const STOP_SIDE := Vector2(1.5, 10.0)
const STOP_EDGE_REACH := 18.0
const STOPS_NEAR := 4
const STOP_RANGE := 170.0
const DAY_FROM := 6.0
const DAY_TO := 22.0
const STOP_REACH := 14.0
const BUBBLE_GAP := 25.0
const BUBBLE_AGAIN := 90.0
## The horn: one honk per HORN_GAP s; walkers within STARTLE m; a called bus from CALL_REACH m,
## standing CALL_WAIT s pulled CALL_PULL m in; the car within CALL_NEAR m when it does (E24).
const HORN_GAP := 0.6
const STARTLE := 9.0
const CALL_REACH := 300.0
const CALL_WAIT := 8.0
const CALL_PULL := 0.9
const CALL_NEAR := 30.0
const CALL_MAX := 90.0
const BUBBLE := Color("#ffd23f")

var traffic: Node3D
var graph: LaneGraph
var map: Node3D
var walkers: Node3D
var dialogue: Node
var sfx: Node
var life: Node
var police: Node
var egg_book: Node
## Callables set by main.gd: the game clock ({hour, weekday}), the view's focus (Vector3), the
## vehicle ([position, km/h, flying]) and the eggs' probe state.
var clock: Callable
var focus: Callable
var vehicle: Callable
var probe: Callable
## --bus-log: a line for each gathering, ring bus, stop bubble, honk, call and race.
var log_on := false
## Time spent in this script since the bench last read it (µs).
var spent_usec := 0
## The bus stops: {at, yaw, e, s, key, side (Vector2 towards the road)}.
var stops: Array[Dictionary] = []
## The hub's bays: {e, s (front), lane, pull, at (Vector3 centre), yaw, east}.
var bays: Array[Dictionary] = []
## The gathering now: {key, plan [[arrive, wait]...], t0 (game s at the slot), forced, buses
## [{d, slot, state: "due" / "coming" / "parked" / "gone"}], bubble}.
var ring := {}
## The race to the Palm (E25): {d, slot, t0, flashes}.
var race := {}
## The called bus (E24): {d, slot, stop, t0}.
var request := {}
## Counters for the check and the log.
var honks := 0
var stop_bubbles := 0

var _t := 0.0
var _now := 0.0
var _tick_n := 0
var _last_honk := -100.0
var _last_bubble := -100.0
var _bubbled := {}
var _near: Array[int] = []
var _figures_sig := ""
var _stop_keys := {}
var _roots := {}
var _dist_cache := {}
var _palm := Vector2(-213.9, 238.5)
var _palm_node := -1
var _forced := false
var _shelter_mesh: Mesh


func setup(data: Dictionary) -> void:
	var p: Array = data.get("palm", [])
	if p.size() >= 2:
		_palm = Vector2(float(p[0]), float(p[1]))
	bays = hub_bays(graph)
	if data.has("shelters"):
		add_shelters(data["shelters"])
	if map != null and map.get("_shared") is Dictionary:
		_shelter_mesh = (map.get("_shared") as Dictionary).get("shelter")
	# The sectors in already (main.gd builds this after the first ones came in).
	var held := map.get_node_or_null("Sectors") if map != null else null
	if held != null:
		for r in held.get_children():
			if r is Node3D:
				on_sector_ready(r)
	if log_on:
		print("buses: %d bays at the hub, %d bus stops so far" % [bays.size(), stops.size()])


## --night-hub: a gathering now (its buses parked at once, wherever the view is).
func force() -> void:
	_forced = true


# --- the rules (static: check_buses.gd runs them) --------------------------------------------

## The N sign is on at `hour` (0-24).
static func sign_on(hour: float) -> bool:
	return hour >= SIGN_FROM or hour < SIGN_TO


## The gathering at `hour`: Vector2(slot, seconds since its start), slot -1 if none is on.
static func slot_at(hour: float) -> Vector2:
	var h := hour if hour >= 12.0 else hour + 24.0
	var rel := h - SLOT_FIRST
	if rel < 0.0:
		return Vector2(-1, 0)
	var k := floori(rel / 0.5)
	var age := (rel - k * 0.5) * 3600.0
	if k >= SLOTS or age >= LIFE:
		return Vector2(-1, age)
	return Vector2(k, age)


## A gathering's buses: [arrive s, stand s] each, 5-8 of them, seeded by the day and slot.
static func ring_plan(day: int, slot: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(day * 100 + slot) + 3517
	var n := rng.randi_range(RING.x, RING.y)
	var out: Array = []
	for i in n:
		out.append([rng.randf_range(0.0, ARRIVE), rng.randf_range(WAIT.x, WAIT.y)])
	return out


## How many of a plan's buses stand at the hub `age` s after its slot.
static func standing(plan: Array, age: float) -> int:
	var n := 0
	for b: Array in plan:
		if age >= float(b[0]) and age < float(b[0]) + float(b[1]):
			n += 1
	return n


## People waiting at stop `key` at `hour` by day: 1 or 2 (more often 2 at the rush hours).
static func stop_people(key: int, hour: float) -> int:
	if hour < DAY_FROM or hour >= DAY_TO:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key * 31 + int(hour))
	var rush := (hour >= 7.0 and hour < 9.5) or (hour >= 15.5 and hour < 18.5)
	return 2 if rng.randf() < (0.7 if rush else 0.35) else 1


## A honk at `now` is allowed `last` s after the last one.
static func horn_ok(now: float, last: float) -> bool:
	return now - last >= HORN_GAP


## E25: the car reached the Palm first and no trap flashed it since the race began.
static func race_won(car_first: bool, flashes_at_start: int, flashes_now: int) -> bool:
	return car_first and flashes_now == flashes_at_start


## E23: the car is at the ring with enough buses standing.
static func hub_moment(car_at: Vector2, flying: bool, standing_now: int) -> bool:
	return not flying and car_at.distance_to(HUB) <= HUB_NEAR and standing_now >= E23_BUSES


## The stop on a bus road for a shelter at `p`: {at, e, s, side, key} or {} (not beside a class
## 0-1 edge's kerb lane, on its right, STOP_SIDE m out).
static func stop_from(g: LaneGraph, p: Vector2) -> Dictionary:
	var best := {}
	var best_d := INF
	var seen := {}
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var key := LaneGraph.cell_key(p + Vector2(dx, dz) * LaneGraph.CELL * 0.5)
			if seen.has(key) or not g.grid.has(key):
				continue
			seen[key] = true
			for e: int in g.grid[key]:
				if g.e_class[e] > 1 or g.e_dk[e] >= 0 or g.e_tn[e] >= 0:
					continue
				var s := g.project(e, p)
				if s < g.e_s0[e] or s > g.e_s1[e]:
					continue
				var c := g.point_at(e, s, 0.0)
				var nrm := g.point_at(e, s, 1.0) - c
				var lat := (p - c).dot(nrm)
				var kerb := g.lane_offset(e, g.e_lanes[e] - 1)
				var out := lat - kerb
				var along := absf((p - c).dot(g.direction(e, s)))
				if out < STOP_SIDE.x or out > STOP_SIDE.y or along > 2.0:
					continue
				if out < best_d:
					best_d = out
					var lane_pt := g.point_at(e, s, kerb)
					best = {"at": p, "e": e, "s": clampf(s + 6.0, g.e_s0[e] + 8.0, g.e_s1[e] - 4.0),
							"side": (lane_pt - p).normalized(), "key": int(roundf(p.x)) * 100000 + int(roundf(p.y))}
	return best


## The hub's bays on graph `g` (HUB_ROWS), interleaved row by row: [{e, s, lane, pull, at, yaw,
## east}]. Empty if the rows are not on the map.
static func hub_bays(g: LaneGraph) -> Array[Dictionary]:
	var rows: Array = []
	for r: Array in HUB_ROWS:
		var p: Vector2 = r[0]
		var hit := g.snap(p, 25.0, r[1])
		var row: Array[Dictionary] = []
		if hit.is_empty():
			rows.append(row)
			continue
		var e: int = hit[0]
		var front := g.project(e, p) + BAY_LEAD
		var at := walk_back(g, e, minf(front, g.e_s1[e] - 4.0), 0.0)
		for k in int(r[2]):
			var spot := walk_back(g, at[0], at[1], BAY_GAP * k)
			if spot.is_empty():
				break
			var fe: int = spot[0]
			var fs: float = spot[1]
			var mid := walk_back(g, fe, fs, 6.0)
			if mid.is_empty():
				break
			var me: int = mid[0]
			var ms: float = mid[1]
			var lane := g.e_lanes[fe] - 1
			var pull: float = g.e_lw[fe] * 0.5 + BAY_PULL
			var off := g.lane_offset(me, g.e_lanes[me] - 1) + g.e_lw[me] * 0.5 + BAY_PULL
			var q := g.point_at(me, ms, off)
			var dir := g.direction(me, ms)
			row.append({"e": fe, "s": fs, "lane": lane, "pull": pull, "at": Vector3(q.x, 0.0, q.y),
					"yaw": atan2(-dir.x, -dir.y), "east": (r[1] as Vector2).x > 0.0})
		rows.append(row)
	var out: Array[Dictionary] = []
	var most := 0
	for row: Array in rows:
		most = maxi(most, row.size())
	for k in most:
		for row: Array in rows:
			if k < row.size():
				out.append(row[k])
	return out


## The point `back` m upstream of s on edge e, along the straightest way in: [e, s] or [].
static func walk_back(g: LaneGraph, e: int, s: float, back: float) -> Array:
	var left := back
	var guard := 0
	while s - left < g.e_s0[e]:
		left -= s - g.e_s0[e]
		var here := g.direction(e, g.e_s0[e])
		var best := -1
		var best_dot := 0.5
		for f: int in g.node_in[g.e_a[e]]:
			if f == g.e_reverse[e]:
				continue
			var dd := here.dot(g.direction(f, g.e_s1[f]))
			if dd > best_dot:
				best_dot = dd
				best = f
		guard += 1
		if best < 0 or guard > 20:
			return []
		e = best
		s = g.e_s1[e]
	return [e, s - left]


# --- the shelters -----------------------------------------------------------------------------

## Shelters as flat [x, z, yaw, ...] (the monolithic city's data, or a test's).
func add_shelters(list: Array) -> void:
	for i in range(0, list.size() - 2, 3):
		_add_stop(Vector2(float(list[i]), float(list[i + 1])))


## A sector came in (main.gd `_on_sector_ready`): its shelters become stops. From the sector's
## file where the game has it (the editor's runtime and --prebuilt paths: only its "shelters"
## list is read), else from the shelters' MultiMesh instances in the prebuilt sector (the
## exported game: shelters are not in the index; a one-off read of a few instances per sector).
func on_sector_ready(root: Node3D) -> void:
	if graph == null or _roots.has(root.name):
		return
	_roots[root.name] = true
	var n0 := stops.size()
	var name := str(root.name)
	var parts := name.split("_")
	var path := "res://map/sectors/%s_%s.json" % [parts[1], parts[2]] if parts.size() >= 3 else ""
	if path != "" and FileAccess.file_exists(path):
		add_shelters(shelters_in(FileAccess.get_file_as_string(path)))
	else:
		for n in root.find_children("*", "MultiMeshInstance3D", true, false):
			var mm := (n as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			if mm.mesh != _shelter_mesh and not mm.mesh.resource_path.ends_with("/shelter.res"):
				continue
			# The sector may not be in the tree yet: its own transforms, up to the root's.
			var xf := Transform3D.IDENTITY
			var up: Node = n
			while up != null:
				if up is Node3D:
					xf = (up as Node3D).transform * xf
				if up == root:
					break
				up = up.get_parent()
			for i in mm.instance_count:
				var o := xf * mm.get_instance_transform(i).origin
				_add_stop(Vector2(o.x, o.z))
	if log_on and stops.size() > n0:
		print("buses: sector %s: %d bus stops (%d in all)" % [name, stops.size() - n0, stops.size()])


## The "shelters" list of a sector file's text, without parsing the rest of it.
static func shelters_in(text: String) -> Array:
	var at := text.find("\"shelters\"")
	if at < 0:
		return []
	var open := text.find("[", at)
	var close := text.find("]", open)
	if open < 0 or close < 0:
		return []
	var v = JSON.parse_string(text.substr(open, close - open + 1))
	return v if v is Array else []


func _add_stop(p: Vector2) -> void:
	var key := int(roundf(p.x)) * 100000 + int(roundf(p.y))
	if _stop_keys.has(key):
		return
	_stop_keys[key] = true
	var st := stop_from(graph, p)
	if not st.is_empty():
		stops.append(st)


# --- the tick ---------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if traffic == null or graph == null:
		return
	_now += dt
	_t += dt
	if _t < TICK:
		return
	var t0 := Time.get_ticks_usec()
	tick(_t)
	_t = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func tick(_dt: float) -> void:
	_tick_n += 1
	var c: Dictionary = clock.call()
	var hour := float(c["hour"])
	traffic.night_sign = sign_on(hour)
	var v: Array = vehicle.call()
	var car3: Vector3 = v[0]
	var car := Vector2(car3.x, car3.z)
	var kmh := float(v[1])
	var flying := bool(v[2])
	var f3: Vector3 = focus.call()
	var view := Vector2(f3.x, f3.z)
	_hub_tick(hour, int(c["weekday"]), view, car, flying)
	_race_tick(car, flying)
	_call_tick(car)
	if _tick_n % 4 == 1:
		_pick_stops(view)
	if log_on and _tick_n % 40 == 0:
		print(summary())
	_stop_figures(hour)
	_stop_bubble(car, kmh, flying, hour)


# --- the hub ----------------------------------------------------------------------------------

func _hub_tick(hour: float, day: int, view: Vector2, car: Vector2, flying: bool) -> void:
	var sl := slot_at(hour)
	if _forced:
		_forced = false
		_end_ring()
		ring = {"key": -99, "plan": ring_plan(day, 99), "t0": _now, "forced": true, "buses": [], "bubble": false}
		for b: Array in ring["plan"]:
			b[0] = 0.0  # all in at once
		for i in ring["plan"].size():
			ring["buses"].append({"d": null, "slot": -1, "state": "due"})
		if log_on:
			print("buses: --night-hub: a gathering of %d now" % ring["plan"].size())
	elif sl.x >= 0 and (ring.is_empty() or int(ring["key"]) != day * 100 + int(sl.x)) and not bool(ring.get("forced", false)):
		_end_ring()
		ring = {"key": day * 100 + int(sl.x), "plan": ring_plan(day, int(sl.x)), "t0": _now - sl.y, "forced": false,
				"buses": [], "bubble": false}
		for i in ring["plan"].size():
			ring["buses"].append({"d": null, "slot": -1, "state": "due"})
		if log_on:
			print("buses: the %02d:%02d gathering at Centralny, %d buses (%.0f s in)" % [int(SLOT_FIRST + sl.x * 0.5) % 24,
					30 if fmod(SLOT_FIRST + sl.x * 0.5, 1.0) > 0.1 else 0, ring["plan"].size(), sl.y])
	if ring.is_empty() or bays.is_empty():
		return
	var age := _now - float(ring["t0"])
	if age >= LIFE + 30.0:
		_end_ring()
		return
	var near := view.distance_to(HUB) < HUB_BAND
	var far := view.distance_to(HUB) > HUB_BAND + 120.0
	var plan: Array = ring["plan"]
	var list: Array = ring["buses"]
	for i in list.size():
		if i >= bays.size():
			break
		var b: Dictionary = list[i]
		var arrive := float(plan[i][0])
		# A bus driven in stands its whole wait from when it is in.
		var leave := float(b.get("in", arrive)) + float(plan[i][1])
		var d: Traffic.Driver = b["d"]
		if d != null and not Traffic.same(d, Traffic.Kind.BUS, int(b["slot"])):
			d = null
			b["d"] = null
			if b["state"] in ["coming", "parked"]:
				b["state"] = "due"
		match str(b["state"]):
			"due":
				if age >= leave:
					b["state"] = "gone"
				elif age >= arrive and near:
					_bring(i, b, bool(ring["forced"]))
			"coming":
				if age >= arrive + float(plan[i][1]) + 120.0:
					_leave(i, b, car, flying)  # never got in (a jam): it gives up
				elif d.halting and absf(d.off - d.off_target) < 0.05:
					traffic.park(d, d.edge, d.s, d.pos, d.yaw)
					b["state"] = "parked"
					b["in"] = age
					if log_on:
						print("buses: ring bus %d in at its bay, %d standing" % [i, standing_now()])
			"parked":
				if age >= leave:
					_leave(i, b, car, flying)
				elif far and not d.visible:
					d.persistent = false
					traffic.remove(d)
					b["d"] = null
					b["state"] = "due"
	var n := standing_now()
	if hub_moment(car, flying, n):
		if not bool(ring["bubble"]):
			ring["bubble"] = true
			var at: Vector3 = bays[0]["at"]
			if dialogue != null:
				dialogue.say_ambient(func() -> Vector3: return at + Vector3(0, 3.6, 0), "", "bus_stop", "night", 4.0, BUBBLE, 2.2, true)
			if log_on:
				print("buses: the car at the ring, %d buses standing" % n)
		if egg_book != null and not egg_book.is_found("e23") and probe.is_valid():
			egg_book.fire("e23", probe.call())


## Ring buses parked at their bays now.
func standing_now() -> int:
	var n := 0
	if ring.is_empty():
		return 0
	for b: Dictionary in ring["buses"]:
		if b["state"] == "parked":
			n += 1
	return n


## A ring bus for bay i: an out-of-sight traffic bus taken over, or one from the pool; parked at
## the bay (out of sight, or a --night-hub gathering: `at_once`) or driven in from upstream.
func _bring(i: int, b: Dictionary, at_once: bool) -> void:
	var bay: Dictionary = bays[i]
	var at: Vector3 = bay["at"]
	at.y = map.ground_height(at.x, at.z) if map != null else 0.0
	var park: bool = at_once or not traffic.on_screen(at, 3.2)
	var e: int = bay["e"]
	var lane: int = bay["lane"]
	var s: float = bay["s"]
	var from := []
	if not park:
		for back: float in UPSTREAM:
			var up := walk_back(graph, e, s, back)
			if up.is_empty():
				break
			var ue: int = up[0]
			var us := clampf(float(up[1]), graph.e_s0[ue] + 2.0, graph.e_s1[ue] - 2.0)
			var q := graph.point_at(ue, us, graph.lane_offset(ue, graph.e_lanes[ue] - 1))
			if not traffic.on_screen(Vector3(q.x, at.y, q.y), 3.2) and traffic._lane_clear(ue, graph.e_lanes[ue] - 1, us, 16.0, q):
				from = [ue, graph.e_lanes[ue] - 1, us]
				break
		if from.is_empty():
			return  # no spot out of sight yet: next tick
	else:
		from = [e, lane, clampf(s - 6.0, graph.e_s0[e], graph.e_s1[e])]
	var d: Traffic.Driver = _recruit()
	if d != null:
		traffic.teleport(d, from[0], from[1], from[2])
	else:
		d = traffic.add_bus(from[0], from[1], from[2])
	if d == null:
		return
	d.tag = "hub"
	d.persistent = true
	b["d"] = d
	b["slot"] = d.slot
	if park:
		traffic.park(d, e, s, at, float(bay["yaw"]))
		d.persistent = true
		d.halting = true
		d.halt_e = e
		b["state"] = "parked"
	else:
		traffic.send_to_stop(d, e, s, _dist_to(graph.e_b[e]), INF, float(bay["pull"]))
		b["state"] = "coming"
	if log_on:
		print("buses: ring bus %d %s at bay %d (%.0f, %.0f)" % [i, "parked" if park else "driving in", i, at.x, at.z])


## A traffic bus out of sight and doing nothing for us, or null.
func _recruit() -> Traffic.Driver:
	for d: Traffic.Driver in traffic.buses():
		if d.tag == "" and not d.visible and not d.parked and not d.persistent and d.halt_e < 0:
			return d
	return null


## Ring bus i's stand is over: it pulls out and drives on (a bus of the eastbound row may race
## the car to the Palm: E25).
func _leave(i: int, b: Dictionary, car: Vector2, flying: bool) -> void:
	var d: Traffic.Driver = b["d"]
	b["state"] = "gone"
	if d == null:
		return
	var bay: Dictionary = bays[i]
	if d.parked:
		traffic.unpark(d, int(bay["e"]), int(bay["lane"]), float(bay["s"]) - d.length * 0.5)
		d.off = d.off_target + float(bay["pull"])
	d.halting = true
	traffic.let_go(d)
	if bool(bay["east"]) and race.is_empty() and not flying and car.distance_to(HUB) < RACE_START \
			and egg_book != null and not egg_book.is_found("e25"):
		_start_race(d)


func _end_ring() -> void:
	if ring.is_empty():
		return
	for b: Dictionary in ring["buses"]:
		var d: Traffic.Driver = b["d"]
		if d != null and Traffic.same(d, Traffic.Kind.BUS, int(b["slot"])) and d.tag == "hub":
			if d.parked and not d.visible:
				d.persistent = false
				traffic.remove(d)
			elif d.parked:
				var i: int = ring["buses"].find(b)
				_leave(i, b, Vector2.INF, true)
			else:
				traffic.let_go(d)
	ring = {}


## Shortest ways to node n (cached: the hub's bays and the Palm are fixed).
func _dist_to(n: int) -> PackedFloat32Array:
	if not _dist_cache.has(n):
		_dist_cache[n] = graph.distances_to(n)
	return _dist_cache[n]


# --- E25: the race to the Palm ----------------------------------------------------------------

func _start_race(d: Traffic.Driver) -> void:
	if _palm_node < 0:
		_palm_node = graph.nearest_node(_palm)
	if _palm_node < 0:
		return
	traffic.race_to(d, _palm_node, _dist_to(_palm_node))
	d.persistent = true
	d.tag = "race"
	race = {"d": d, "slot": d.slot, "t0": _now, "flashes": int(police.trap_flashes) if police != null else 0}
	if log_on:
		print("buses: a night bus leaves for the Palm (%.0f m): the race is on" % traffic.remaining(d))


func _race_tick(car: Vector2, flying: bool) -> void:
	if race.is_empty():
		return
	var d: Traffic.Driver = race["d"]
	var alive := Traffic.same(d, Traffic.Kind.BUS, int(race["slot"]))
	var bus_there := not alive or d.arrived or Vector2(d.pos.x, d.pos.z).distance_to(_palm) < PALM_REACH
	var car_there := not flying and car.distance_to(_palm) < PALM_REACH
	var flashes := int(police.trap_flashes) if police != null else 0
	if car_there or bus_there or _now - float(race["t0"]) > RACE_MAX:
		var won := race_won(car_there and not bus_there, int(race["flashes"]), flashes)
		if log_on:
			print("buses: the race to the Palm: %s (%.0f s, %d flashes)" % ["the car first" if won else
					("the bus first" if bus_there else ("flashed" if car_there else "over")), _now - float(race["t0"]),
					flashes - int(race["flashes"])])
		if won and egg_book != null and probe.is_valid():
			egg_book.fire("e25", probe.call())
		if alive and d.tag == "race":
			traffic.let_go(d)
		race = {}


# --- the horn and E24 -------------------------------------------------------------------------

## The player's horn (the HUD's horn, the B key). False if too soon after the last.
func honk() -> bool:
	if not horn_ok(_now, _last_honk):
		return false
	_last_honk = _now
	honks += 1
	var v: Array = vehicle.call()
	var car3: Vector3 = v[0]
	var car := Vector2(car3.x, car3.z)
	if sfx != null:
		sfx.horn_player()
	if life != null:
		life.horn(car3)
	var turned := 0
	if walkers != null:
		turned = walkers.startle(car, STARTLE)
	var st := _stop_at(car) if not bool(v[2]) and float(v[1]) < 1.0 else -1
	if log_on:
		print("buses: honk at %.0f, %.0f (%d walkers turn)%s" % [car.x, car.y, turned, ", at a stop" if st >= 0 else ""])
	if st >= 0 and request.is_empty():
		_call_bus(st, car3)
	return true


## The stop within STOP_REACH of p, or -1.
func _stop_at(p: Vector2) -> int:
	var best := -1
	var best_d := STOP_REACH
	for i in stops.size():
		var dd := p.distance_to(stops[i]["at"])
		if dd < best_d:
			best_d = dd
			best = i
	return best


## A bus for stop `i`: the nearest one in reach that can drive there, else one from the pool out
## of sight upstream; the request line over the car.
func _call_bus(i: int, car3: Vector3) -> void:
	var st: Dictionary = stops[i]
	var e: int = st["e"]
	var s: float = st["s"]
	var dist := graph.distances_to(graph.e_b[e], CALL_REACH * 2.0)
	var pick: Traffic.Driver = null
	var best := CALL_REACH * 1.6
	var at: Vector2 = st["at"]
	for d: Traffic.Driver in traffic.buses():
		if d.tag != "" or d.parked or d.halt_e >= 0 or d.in_conn:
			continue
		if Vector2(d.pos.x, d.pos.z).distance_to(at) > CALL_REACH:
			continue
		var cost := INF
		if d.edge == e:
			cost = s - d.s if d.s + d.length * 0.5 < s - 12.0 else INF
		elif dist[graph.e_b[d.edge]] < INF and dist[graph.e_a[e]] < INF:
			cost = graph.e_s1[d.edge] - d.s + dist[graph.e_b[d.edge]]
		if cost < best:
			best = cost
			pick = d
	if pick == null:
		for back: float in UPSTREAM:
			var up := walk_back(graph, e, s, back)
			if up.is_empty():
				break
			var ue: int = up[0]
			var us := clampf(float(up[1]), graph.e_s0[ue] + 2.0, graph.e_s1[ue] - 2.0)
			var q := graph.point_at(ue, us, graph.lane_offset(ue, graph.e_lanes[ue] - 1))
			if not traffic.on_screen(Vector3(q.x, car3.y, q.y), 3.2) and traffic._lane_clear(ue, graph.e_lanes[ue] - 1, us, 16.0, q):
				pick = traffic.add_bus(ue, graph.e_lanes[ue] - 1, us)
				if pick != null:
					pick.v = graph.e_speed[ue] * 0.6
				break
	if dialogue != null and dialogue.lines.has("bus_stop") and (dialogue.lines["bus_stop"] as Array).size() > 2:
		# vision.md's E24: the `bus_stop` request line (index 2, "Stoję na przystanku na żądanie").
		var l: Array = dialogue.lines["bus_stop"][2]
		if dialogue.bubbles != null:
			dialogue.bubbles.say_ambient(func() -> Vector3: return car3 + Vector3(0, 2.2, 0), "", l[0], l[1], 4.0, BUBBLE, 2.2)
	if pick == null:
		if log_on:
			print("buses: no bus can come to the stop at %.0f, %.0f" % [at.x, at.y])
		return
	traffic.send_to_stop(pick, e, s, dist, CALL_WAIT, CALL_PULL)
	pick.tag = "call"
	request = {"d": pick, "slot": pick.slot, "stop": i, "t0": _now}
	if log_on:
		print("buses: a bus %.0f m away comes to the stop" % Vector2(pick.pos.x, pick.pos.z).distance_to(at))


func _call_tick(car: Vector2) -> void:
	if request.is_empty():
		return
	var d: Traffic.Driver = request["d"]
	if not Traffic.same(d, Traffic.Kind.BUS, int(request["slot"])) or d.tag != "call":
		request = {}
		return
	var stop_at: Vector2 = stops[int(request["stop"])]["at"]
	if not d.halting and d.v < 0.3 and Vector2(d.pos.x, d.pos.z).distance_to(stop_at) < CALL_NEAR:
		# Held short of the stop's line (the car itself stands on it): it pulls in where it is.
		request["held"] = float(request.get("held", 0.0)) + TICK
		if float(request["held"]) >= 1.0:
			d.halting = true
			d.halt_wait = CALL_WAIT
	if d.halting:
		var at: Vector2 = stop_at
		if car.distance_to(at) < CALL_NEAR:
			if log_on:
				print("buses: the bus pulls in at the stop for the car")
			if egg_book != null and probe.is_valid():
				egg_book.fire("e24", probe.call())
		d.tag = "called"
		request = {}
	elif _now - float(request["t0"]) > CALL_MAX:
		traffic.let_go(d)
		request = {}


# --- the stops' people ------------------------------------------------------------------------

func _pick_stops(view: Vector2) -> void:
	_near.clear()
	var dists: Array = []
	for i in stops.size():
		var dd := view.distance_to(stops[i]["at"])
		if dd < STOP_RANGE:
			dists.append([dd, i])
	dists.sort()
	for k in mini(STOPS_NEAR, dists.size()):
		_near.append(int(dists[k][1]))


## How many wait at stop i now: by day 1-2, at night only at the hub's stops while the ring stands.
func people_at(i: int, hour: float) -> int:
	var st: Dictionary = stops[i]
	if hour >= DAY_FROM and hour < DAY_TO:
		return stop_people(int(st["key"]), hour)
	if (st["at"] as Vector2).distance_to(HUB) < 70.0 and standing_now() > 0:
		return 2 + int(st["key"]) % 2
	return 0


func _stop_figures(hour: float) -> void:
	if walkers == null:
		return
	var sig := ""
	var plan: Array = []
	var used := 0
	for i: int in _near:
		var n := mini(people_at(i, hour), Pedestrians.STOPS - used)
		if n > 0:
			plan.append([i, n])
			used += n
			sig += "%d:%d," % [i, n]
	if sig == _figures_sig:
		return
	_figures_sig = sig
	var slot := 0
	for p: Array in plan:
		var st: Dictionary = stops[int(p[0])]
		var at: Vector2 = st["at"]
		var side: Vector2 = st["side"]
		var along := Vector2(-side.y, side.x)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(st["key"])
		for k in int(p[1]):
			var q := at + side * rng.randf_range(0.9, 1.6) + along * (float(k) - 0.5 * (float(p[1]) - 1.0)) * 1.3
			var y: float = map.ground_height(q.x, q.y) if map != null else 0.0
			var shirt := Color(Pedestrians.SHIRTS[rng.randi() % Pedestrians.SHIRTS.size()])
			walkers.set_stop(slot, Vector3(q.x, y, q.y), atan2(-side.x, -side.y) + rng.randf_range(-0.5, 0.5), shirt, rng.randf())
			slot += 1
	for k in range(slot, Pedestrians.STOPS):
		walkers.clear_stop(k)


func _stop_bubble(car: Vector2, kmh: float, flying: bool, hour: float) -> void:
	if flying or kmh >= 1.0 or _now - _last_bubble < BUBBLE_GAP or dialogue == null:
		return
	for i: int in _near:
		var st: Dictionary = stops[i]
		var at: Vector2 = st["at"]
		if car.distance_to(at) > STOP_REACH or people_at(i, hour) == 0:
			continue
		if _now - float(_bubbled.get(i, -1000.0)) < BUBBLE_AGAIN:
			continue
		_bubbled[i] = _now
		_last_bubble = _now
		stop_bubbles += 1
		var side: Vector2 = st["side"]
		var q := at + side * 1.2
		var y: float = map.ground_height(q.x, q.y) if map != null else 0.0
		var night := not (hour >= DAY_FROM and hour < DAY_TO)
		dialogue.say_ambient(func() -> Vector3: return Vector3(q.x, y + 2.0, q.y), "", "bus_stop", "night" if night else "", 4.0, BUBBLE, 2.2, night)
		if log_on:
			print("buses: a bus_stop line at the stop at %.0f, %.0f" % [at.x, at.y])
		return


## --bus-log: a line on the state.
func summary() -> String:
	return "buses: %d stops known, %d near, ring %s (%d standing), race %s, call %s, honks %d" % [stops.size(), _near.size(),
			"none" if ring.is_empty() else str(ring["plan"].size()), standing_now(), "on" if not race.is_empty() else "off",
			"on" if not request.is_empty() else "off", honks]
