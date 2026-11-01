extends Node3D
## Packs (docs/design/packs.md, F's ask 2026-11-01): the city's sporty and caffeinated crowds.
##  - **Running clubs**: three parody clubs (`RUN_CLUBS`: TEMPO NA KAWĘ, KILOMETRY I KRUASANY,
##    NOGI Z MORDORU), 20-28 runners each in rows of three in the club's colour, out and back on a
##    footway route (A* over the footways and crossings between the club's points, Crowds.build_routes)
##    at ~3 m/s, in their hours (mornings, lunch, evenings; the Day look's Friday 14:00 has two);
##    KOLKA (city_life.gd, Wednesdays 19:00) stays the boulevards' own club.
##  - **Cycling packs**: two parody packs (`RIDE_CLUBS`: KARBONOWE KOLANA, WATY I LATTE), 10-14
##    road riders two abreast on carbon road bikes (our own shapes: `roadie_mesh`), out and back on
##    the cycle paths at ~7 m/s, gear meme lines (WĄWÓZ, CEGŁA and SPECJAŁ bikes, the GARNEK watch,
##    the SZPAN app: parodies, docs/design/packs.md).
##  - **Coffee raves**: at the COFFEECHAIR cafés (Storefronts.CAFES), one a weekday (08:00-15:00,
##    14 dancers) and two at weekends (09:00-15:00, 24): a DJ booth on the pavement (a table, two
##    speakers, a lit KAWOWY RAVE board and a string of party lights), DJ Espresso behind it,
##    dancers bobbing round it (the legs' swing on, a bounce and a sway at 120 bpm).
##  - Lines (`run_club`, `peleton`, `coffee_rave` in data/dialogue.json): a pack or rave on screen
##    near the view speaks every 25-45 s; the car close behind a pack gets the `car` lines, a slow
##    car at a rave the DJ's `dj` lines; a club's name as a toast the first time the car meets it.
## Drawing: the runners one MultiMesh (the pedestrians' person mesh, a faster stride), the riders
## one (roadie_mesh, a four-shape family on the actor material), the dancers one, a booth mesh per
## rave venue shown only while it is on and near: +1 to +3 draw calls only near a pack or a rave,
## nothing far from them. No sun shadow, no collision (like the dawn crowd). The logic ticks at
## 2 Hz; the packs move at 15 Hz and the dancers at 10 Hz only while near the view. The rules are
## static functions (check_packs.gd runs them on synthetic clocks and the real map).

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Storefronts := preload("res://scripts/storefronts.gd")
const Crowds := preload("res://scripts/crowds.gd")
const CityLife := preload("res://scripts/city_life.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const TICK := 0.5
const MOVE_TICK := 1.0 / 15.0
const DANCE_TICK := 0.1
## A pack or a rave has figures drawn only while the view's focus is this near it (m).
const ACTIVE_R := 420.0
## Lines: a pack or rave within LINE_VIEW of the view's focus and on screen speaks every LINE_GAP s;
## the car within CAR_NEAR of a pack's tail (on the ground) gets a `car` line.
const LINE_VIEW := 140.0
const LINE_GAP := Vector2(25.0, 45.0)
const CAR_NEAR := 12.0
const RAVE_CAR := 25.0
const RAVE_KMH := 15.0
## The toast's reach: the car this near a pack's member the first time this session.
const MEET_R := 30.0
const FORCE_R := 300.0
## The formation: runners three abreast ROW_RUN m apart, riders two abreast ROW_RIDE m apart.
const ROW_RUN := 1.15
const ROW_RIDE := 2.0
const COLS_RUN := [-0.75, 0.0, 0.75]
const COLS_RIDE := [-0.42, 0.42]
## The runners' legs swing faster than a walker's (actor.gdshader `walk`), the dancers' slower.
const RUN_STRIDE := 0.3
const DANCE_STRIDE := 0.1
## The dance: beats a second (120 bpm), the bounce (m) and the sway (rad).
const BEAT := 2.0
const BOUNCE := 0.13
const SWAY := 0.55
## A rave: dancers on a weekday and at a weekend, the strip along the pavement they dance in (m).
const RAVE_WEEK := 14
const RAVE_WEEKEND := 24
const RAVE_HALF := 7.5
const RAVE_HOURS_WEEK := [8.0, 15.0]
const RAVE_HOURS_WEEKEND := [9.0, 15.0]
## The parody clubs (docs/design/packs.md). `via`: [lat, lon] points the route joins (out and back);
## `hours`: "week" (Mon-Fri), "weekend" (Sat-Sun) and "all" windows [from, to); `max` people; `v` m/s.
const RUN_CLUBS := {
	"tempo_na_kawe": {"name": "TEMPO NA KAWĘ", "gloss": "PACE FOR COFFEE", "colour": "#ff6b4a", "max": 24, "v": 3.0,
			"via": [[52.2196, 21.0170], [52.2288, 21.0222], [52.2365, 21.0175]],
			"hours": {"week": [[6.5, 9.5], [17.5, 21.0]], "weekend": [[8.0, 11.0]]}},
	"kilometry_kruasany": {"name": "KILOMETRY I KRUASANY", "gloss": "KILOMETRES AND CROISSANTS", "colour": "#b48cff", "max": 20, "v": 2.8,
			"via": [[52.2419, 21.0285], [52.2510, 21.0150]],
			"hours": {"all": [[7.0, 10.0], [12.0, 14.5], [18.0, 21.0]]}},
	"nogi_z_mordoru": {"name": "NOGI Z MORDORU", "gloss": "LEGS FROM MORDOR", "colour": "#3fa7ff", "max": 28, "v": 3.2,
			"via": [[52.2310, 21.0085], [52.2405, 21.0080], [52.2405, 21.0185]],
			"hours": {"week": [[12.0, 14.5], [17.0, 20.5]], "weekend": [[9.0, 11.0]]}},
}
const RIDE_CLUBS := {
	"karbonowe_kolana": {"name": "KARBONOWE KOLANA", "gloss": "CARBON KNEES", "colour": "#e8e4d8", "max": 12, "v": 7.0,
			"via": [[52.2370, 21.0370], [52.2500, 21.0190]],
			"hours": {"week": [[13.0, 16.0], [17.5, 20.0]], "weekend": [[7.0, 11.0]]}},
	"waty_i_latte": {"name": "WATY I LATTE", "gloss": "WATTS AND LATTES", "colour": "#e0b23a", "max": 10, "v": 6.5,
			"via": [[52.2330, 20.9985], [52.2196, 21.0170]],
			"hours": {"all": [[11.0, 16.0]], "weekend": [[8.0, 11.0]]}},
}
## The kit's other colours (a club's colour on most, these on the rest).
const KIT := ["#1c2230", "#f2efe8", "#2b2c2f", "#d8432f", "#3b8f5a", "#5aa9c9"]
const DANCE := ["#ff5fa2", "#ffd23f", "#4ae0c0", "#9b6bff", "#f2efe8", "#ff8a3c", "#5aa9c9", "#e57aa0"]
const DJ_SHIRT := Color("#141416")
const BUBBLE := Color("#ffb86b")
const RAVE_BUBBLE := Color("#ff7ad1")

## The view's focus, -> Vector3.
var focus: Callable
## The game clock, -> {hour, weekday}.
var clock: Callable
## The vehicle, -> [position, km/h, flying].
var vehicle: Callable
## Is a world point on screen (traffic.gd on_screen), -> bool; unset: always.
var on_screen: Callable
var map: Node3D
var dialogue: Node
var hud: CanvasLayer
## --crowd= scale (the Low tier halves it).
var amount := 1.0
## --packs-log: each minute's summary and every event.
var log_on := false
## --packs-now: every club and every café's rave on whatever the clock says (shots, checks); with
## `force_near` set (the car's start), each pack whose loop passes within FORCE_R of it is timed to
## run past it a few seconds in.
var force := false
var force_near := Vector2.INF
var spent_usec := 0
var lines_said := 0
var meets := 0
## Clubs: {id, kind ("run" or "ride"), name, gloss, colour, max, v, hours, via (Vector2s), phase,
## route: {pts, h, cum, len} or {}, n, on, near, lat, back, shirt, tr, pos (PackedVector3Array),
## yaw, line_t, met}.
var clubs: Array[Dictionary] = []
## Raves: {id, at (booth Vector3), yaw, face (Vector2, the booth's front), slots, n, on, near, booth, line_t}.
var raves: Array[Dictionary] = []
var t := 0.0

var _rng := RandomNumberGenerator.new()
var _tick_t := 0.0
var _move_t := 0.0
var _dance_t := 0.0
var _log_t := 0.0
var _hour := 14.0
var _weekday := 5
var _route_task := -1
var _route_out: Array = []
var _run_mm: MultiMesh
var _run_mmi: MultiMeshInstance3D
var _run_buf := PackedFloat32Array()
var _ride_mm: MultiMesh
var _ride_mmi: MultiMeshInstance3D
var _ride_buf := PackedFloat32Array()
var _dance_mm: MultiMesh
var _dance_mmi: MultiMeshInstance3D
var _dance_buf := PackedFloat32Array()


# --- the rules (static: check_packs.gd) ----------------------------------------------------

## Is `hour` inside one of a club's windows on `weekday` (1 Monday .. 7 Sunday)?
static func club_on(hours: Dictionary, hour: float, weekday: int) -> bool:
	var wins: Array = (hours.get("all", []) as Array) + (hours.get("weekend" if weekday >= 6 else "week", []) as Array)
	for w: Array in wins:
		if hour >= float(w[0]) and hour < float(w[1]):
			return true
	return false


## How many run with a club now (0 outside its hours; `k` the --crowd scale).
static func club_count(spec: Dictionary, hour: float, weekday: int, k := 1.0, forced := false) -> int:
	if not forced and not club_on(spec["hours"], hour, weekday):
		return 0
	return roundi(int(spec["max"]) * k)


## Today's rave cafés (Storefronts.CAFES' ids in order): one on a weekday, two at a weekend.
static func rave_venues(weekday: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in Storefronts.CAFES:
		ids.append(id)
	var out: Array[String] = []
	if weekday >= 6:
		out.append(ids[weekday % ids.size()])
		out.append(ids[(weekday + 2) % ids.size()])
	else:
		out.append(ids[(weekday - 1) % ids.size()])
	return out


## Dancers at a rave café now (0 when it isn't today's or outside the hours; `forced`: every café,
## any hour).
static func rave_count(id: String, hour: float, weekday: int, k := 1.0, forced := false) -> int:
	if not forced and not id in rave_venues(weekday):
		return 0
	var hrs: Array = RAVE_HOURS_WEEKEND if weekday >= 6 else RAVE_HOURS_WEEK
	if not forced and (hour < float(hrs[0]) or hour >= float(hrs[1])):
		return 0
	return roundi((RAVE_WEEKEND if weekday >= 6 else RAVE_WEEK) * k)


## A pack's head along its loop `secs` seconds in (the loop is out and back, so it never turns).
static func head_at(length: float, v: float, phase: float, secs: float) -> float:
	return fposmod(phase + v * secs, maxf(length, 0.001))


## Member `j`'s place in the formation: [metres behind the head, metres to the side].
static func slot_of(kind: String, j: int) -> Vector2:
	var cols: Array = COLS_RUN if kind == "run" else COLS_RIDE
	var gap := ROW_RUN if kind == "run" else ROW_RIDE
	return Vector2((j / cols.size()) * gap, float(cols[j % cols.size()]))


## The club's loop (pure: a worker thread runs it; check_packs.gd too): legs between its `via`
## points over `paths` ([PackedVector2Array, deck, cost per metre] each), then the way back (the
## same points reversed), so a pack runs out and back without turning in place. The map's
## footways meet their crossings mid-segment as often as at a shared corner, so any two corners of
## different paths within JOIN m are joined (JOIN_FAR m when a leg isn't found). {pts, dk} or {}
## when no leg is found.
const JOIN := 4.0
const JOIN_FAR := 7.0
static func build_loop(paths: Array, via: Array) -> Dictionary:
	var g := build_graph(paths, JOIN)
	var pts := PackedVector2Array()
	var dk := PackedInt32Array()
	var far := {}
	for i in via.size() - 1:
		var leg := graph_route(g, via[i], via[i + 1])
		if leg.is_empty():
			if far.is_empty():
				far = build_graph(paths, JOIN_FAR)
			leg = graph_route(far, via[i], via[i + 1])
		if leg.is_empty():
			continue
		var pos: PackedVector2Array = leg["pos"]
		var dks: PackedInt32Array = leg["dks"]
		for n: int in leg["nodes"]:
			if not pts.is_empty() and pts[pts.size() - 1].distance_to(pos[n]) < 0.05:
				continue
			pts.append(pos[n])
			dk.append(dks[n])
	if pts.size() < 2:
		return {}
	for k in range(pts.size() - 2, -1, -1):
		pts.append(pts[k])
		dk.append(dk[k])
	return {"pts": pts, "dk": dk}


## The paths' graph (pure): {pos, dks, cost (per node: the dearest path through it), adj}; corners
## shared by position (0.5 m), and any two corners within `join` m joined.
static func build_graph(paths: Array, join: float) -> Dictionary:
	var key_of := {}
	var pos := PackedVector2Array()
	var dks := PackedInt32Array()
	var cost := PackedFloat32Array()
	var adj: Array[PackedInt32Array] = []
	for path: Array in paths:
		var pp: PackedVector2Array = path[0]
		var c := float(path[2]) if path.size() > 2 else 1.0
		var prev := -1
		for i in pp.size():
			var key := Vector2i(roundi(pp[i].x * 2.0), roundi(pp[i].y * 2.0))
			var n: int
			if key_of.has(key):
				n = key_of[key]
				cost[n] = minf(cost[n], c)
			else:
				n = pos.size()
				key_of[key] = n
				pos.append(pp[i])
				dks.append(int(path[1]))
				cost.append(c)
				adj.append(PackedInt32Array())
			if prev >= 0 and prev != n and not n in adj[prev]:
				adj[prev].append(n)
				adj[n].append(prev)
			prev = n
	var grid := {}
	for i in pos.size():
		var cell := Vector2i(floori(pos[i].x / join), floori(pos[i].y / join))
		if not grid.has(cell):
			grid[cell] = PackedInt32Array()
		var arr: PackedInt32Array = grid[cell]
		arr.append(i)
		grid[cell] = arr
	for i in pos.size():
		var cell := Vector2i(floori(pos[i].x / join), floori(pos[i].y / join))
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				for j: int in grid.get(cell + Vector2i(dx, dz), PackedInt32Array()):
					if j > i and pos[i].distance_to(pos[j]) < join and not j in adj[i]:
						adj[i].append(j)
						adj[j].append(i)
	# The connected parts (a corner's part id), so a route's ends are picked on one part.
	var comp := PackedInt32Array()
	comp.resize(pos.size())
	comp.fill(-1)
	var parts := 0
	for i in pos.size():
		if comp[i] >= 0:
			continue
		var stack := PackedInt32Array([i])
		comp[i] = parts
		while not stack.is_empty():
			var u := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			for v in adj[u]:
				if comp[v] < 0:
					comp[v] = parts
					stack.append(v)
		parts += 1
	return {"pos": pos, "dks": dks, "cost": cost, "adj": adj, "comp": comp}


## A* over a graph from the corner nearest `a` to the one nearest `b` (each within 80 m), the cost
## a metre the dearer of an edge's two corners: {nodes, pos, dks} or {}.
static func graph_route(g: Dictionary, a: Vector2, b: Vector2) -> Dictionary:
	var pos: PackedVector2Array = g["pos"]
	var adj: Array[PackedInt32Array] = g["adj"]
	var cost: PackedFloat32Array = g["cost"]
	var comp: PackedInt32Array = g["comp"]
	# The corners within 80 m of each end, nearest first; the nearest pair on one connected part.
	var ca: Array = []
	var cb: Array = []
	for i in pos.size():
		if adj[i].is_empty():
			continue
		var d1 := pos[i].distance_to(a)
		if d1 < 80.0:
			ca.append([d1, i])
		var d2 := pos[i].distance_to(b)
		if d2 < 80.0:
			cb.append([d2, i])
	ca.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	cb.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var na := -1
	var nb := -1
	var best := INF
	for x: Array in ca:
		if float(x[0]) >= best:
			break
		for y: Array in cb:
			if comp[int(x[1])] == comp[int(y[1])]:
				if float(x[0]) + float(y[0]) < best:
					best = float(x[0]) + float(y[0])
					na = int(x[1])
					nb = int(y[1])
				break
	if na < 0 or nb < 0 or na == nb:
		return {}
	var n := pos.size()
	var gs := PackedFloat32Array()
	gs.resize(n)
	gs.fill(INF)
	var came := PackedInt32Array()
	came.resize(n)
	came.fill(-1)
	var done := PackedByteArray()
	done.resize(n)
	var hf := PackedFloat32Array()
	var hn := PackedInt32Array()
	gs[na] = 0.0
	Crowds._push(hf, hn, pos[na].distance_to(pos[nb]), na)
	while not hn.is_empty():
		var u := Crowds._pop(hf, hn)
		if done[u] == 1:
			continue
		done[u] = 1
		if u == nb:
			break
		for v in adj[u]:
			if done[v] == 1:
				continue
			var nd := gs[u] + pos[u].distance_to(pos[v]) * maxf(cost[u], cost[v])
			if nd < gs[v]:
				gs[v] = nd
				came[v] = u
				Crowds._push(hf, hn, nd + pos[v].distance_to(pos[nb]), v)
	if came[nb] < 0:
		return {}
	var nodes := PackedInt32Array()
	var c := nb
	while c >= 0:
		nodes.append(c)
		c = came[c]
	nodes.reverse()
	return {"nodes": nodes, "pos": pos, "dks": g["dks"]}


## The paths a club's routes may use (pure): footways and crossings for runners; for riders the
## cycle paths and their crossings at cost 1 and the footways at RIDE_FOOT a metre (the map's cycle
## paths don't all join up), kept when a point is inside the via points' box grown by 400 m.
const RIDE_FOOT := 2.5
static func paths_for(data_paths: Array, kind: String, via: Array) -> Array:
	var box := Rect2(via[0], Vector2.ZERO)
	for p: Vector2 in via:
		box = box.expand(p)
	box = box.grow(400.0)
	var out: Array = []
	for p: Dictionary in data_paths:
		var k := str(p.get("k", ""))
		var c := 1.0
		if k in ["foot", "zebra"]:
			c = 1.0 if kind == "run" else RIDE_FOOT
		elif k in ["cycle", "cyclecross"]:
			if kind == "run":
				continue
		else:
			continue
		var flat: Array = p["p"]
		var n := flat.size() / 2
		if n < 2:
			continue
		var pts := PackedVector2Array()
		var inside := false
		for i in n:
			var q := Vector2(float(flat[i * 2]), float(flat[i * 2 + 1]))
			pts.append(q)
			inside = inside or box.has_point(q)
		if inside:
			out.append([pts, int(p.get("dk", -1)), c])
	return out


# --- setup ---------------------------------------------------------------------------------

## The clubs and raves from the map data (`paths`, `origin`) and the storefronts' venues (their
## `road` and `bld` points, for the cafés' pavements; may be empty). Routes are found in a worker
## thread; the raves' slots now.
func setup(data: Dictionary, venues: Array = [], seed_value := 2611) -> void:
	_rng.seed = seed_value
	var origin: Array = data.get("origin", [52.234, 21.024])
	for kind in ["run", "ride"]:
		var specs: Dictionary = RUN_CLUBS if kind == "run" else RIDE_CLUBS
		for id: String in specs:
			var spec: Dictionary = specs[id]
			var via: Array = []
			for ll: Array in spec["via"]:
				via.append(Notebook.project(origin, float(ll[0]), float(ll[1])))
			clubs.append(_new_club(id, kind, spec, via))
	var jobs: Array = []
	var all_paths: Array = data.get("paths", [])
	for c in clubs:
		jobs.append([paths_for(all_paths, c["kind"], c["via"]), c["via"]])
	_route_out = [null]
	var out := _route_out
	_route_task = WorkerThreadPool.add_task(func() -> void: out[0] = _find_loops(jobs), false, "pack routes")
	_setup_raves(data, venues, origin)
	_build_drawing()
	print("packs: %d running clubs, %d cycling packs, %d rave cafés, routes being found, amount %.2f" % [
			RUN_CLUBS.size(), RIDE_CLUBS.size(), raves.size(), amount])


func _new_club(id: String, kind: String, spec: Dictionary, via: Array) -> Dictionary:
	var cap := ceili(int(spec["max"]) * maxf(amount, 1.0))
	var lat := PackedFloat32Array()
	var back := PackedFloat32Array()
	var shirt := PackedColorArray()
	var tr := PackedFloat32Array()
	var colour := Color(str(spec["colour"]))
	for j in cap:
		var sl := slot_of(kind, j)
		back.append(sl.x + _rng.randf_range(-0.25, 0.25))
		lat.append(sl.y + _rng.randf_range(-0.12, 0.12))
		shirt.append(colour if _rng.randf() < 0.7 else Color(KIT[_rng.randi() % KIT.size()]))
		tr.append(_rng.randf() * 0.99 if kind == "run" else float(_rng.randi() % 2))
	var pos := PackedVector3Array()
	pos.resize(cap)
	var yaw := PackedFloat32Array()
	yaw.resize(cap)
	return {"id": id, "kind": kind, "name": spec["name"], "gloss": spec["gloss"], "colour": colour, "max": int(spec["max"]),
			"v": float(spec["v"]), "hours": spec["hours"], "via": via, "phase": _rng.randf_range(0.0, 5000.0), "route": {},
			"n": 0, "on": false, "near": false, "lat": lat, "back": back, "shirt": shirt, "tr": tr, "pos": pos, "yaw": yaw,
			"line_t": _rng.randf_range(4.0, 10.0), "met": false, "cap": cap}


## The worker's job: each club's loop ([paths, via] each).
static func _find_loops(jobs: Array) -> Array:
	var out: Array = []
	for j: Array in jobs:
		out.append(build_loop(j[0], j[1]))
	return out


func _finish_routes() -> void:
	var found: Variant = _route_out[0] if not _route_out.is_empty() else null
	var raw: Array = found if found is Array else []
	for i in mini(raw.size(), clubs.size()):
		var r: Dictionary = raw[i]
		if r.is_empty():
			continue
		var pts: PackedVector2Array = r["pts"]
		var dk: PackedInt32Array = r["dk"]
		var h := PackedFloat32Array()
		var cum := PackedFloat32Array()
		var run := 0.0
		for k in pts.size():
			if k > 0:
				run += pts[k].distance_to(pts[k - 1])
			cum.append(run)
			h.append(map.deck_height(dk[k], pts[k].x, pts[k].y) if map != null else 0.0)
		clubs[i]["route"] = {"pts": pts, "h": h, "cum": cum, "len": run}
		if force and force_near != Vector2.INF:
			var best := INF
			var bs := 0.0
			for k in pts.size() / 2:
				var d := pts[k].distance_to(force_near)
				if d < best:
					best = d
					bs = cum[k]
			if best < FORCE_R:
				# The head 10 m short of the nearest point now: the pack streams past it from ~4 s in.
				clubs[i]["phase"] = bs - 10.0 - float(clubs[i]["v"]) * t
	if log_on:
		var lens := PackedStringArray()
		for c in clubs:
			lens.append("%s %s" % [c["id"], "%.0f m" % float(c["route"]["len"]) if not (c["route"] as Dictionary).is_empty() else "none"])
		print("packs: routes %s" % ", ".join(lens))


## A booth per rave café: on the pavement nearest the café's front (the storefront's `bld` and
## `road`, else the café's own point), facing the street; the dancers' slots along the pavement.
func _setup_raves(data: Dictionary, venues: Array, origin: Array) -> void:
	var by_id := {}
	for v: Dictionary in venues:
		by_id[str(v.get("id", ""))] = v
	var foot: Array = []
	var cafe_pts: Array = []
	for id: String in Storefronts.CAFES:
		var ll: Array = Storefronts.CAFES[id]
		cafe_pts.append(Notebook.project(origin, float(ll[0]), float(ll[1])))
	for p: Dictionary in data.get("paths", []):
		if str(p.get("k", "")) != "foot" or int(p.get("dk", -1)) >= 0:
			continue
		var flat: Array = p["p"]
		if flat.size() < 4:
			continue
		var q0 := Vector2(float(flat[0]), float(flat[1]))
		var near := false
		for c: Vector2 in cafe_pts:
			if q0.distance_to(c) < 400.0:
				near = true
				break
		if near:
			var pts := PackedVector2Array()
			for i in flat.size() / 2:
				pts.append(Vector2(float(flat[i * 2]), float(flat[i * 2 + 1])))
			foot.append([pts, float(p.get("w", 2.5))])
	var i := 0
	for id: String in Storefronts.CAFES:
		var at: Vector2 = cafe_pts[i]
		i += 1
		var bld := at
		var road := Vector2.INF
		if by_id.has(id) and by_id[id].get("bld", Vector2.INF) != Vector2.INF:
			bld = by_id[id]["bld"]
			road = by_id[id]["road"]
		var hit := _nearest_foot(foot, bld.lerp(road, 0.35) if road != Vector2.INF else bld, 70.0)
		if hit.is_empty():
			continue
		var q: Vector2 = hit[0]
		var along: Vector2 = hit[1]
		var w := clampf(float(hit[2]), 2.0, 6.0)
		var to_bld := bld - q
		var side := Vector2(-along.y, along.x)
		if side.dot(to_bld) < 0.0:
			side = -side  # `side` points at the café
		# The booth by the café's wall half a pavement in, its front to the street.
		var booth2 := q + side * maxf(w * 0.5 - 0.6, 0.0)
		var face := -side
		var slots: Array = []
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var tries := 0
		while slots.size() < ceili(RAVE_WEEKEND * maxf(amount, 1.0)) and tries < 400:
			tries += 1
			var a := rng.randf_range(-RAVE_HALF, RAVE_HALF)
			var c := rng.randf_range(-w * 0.5 + 0.35, w * 0.5 - 0.35)
			var p := q + along * a + side * c
			if p.distance_to(booth2) < 1.6:
				continue
			var ok := true
			for s: Array in slots:
				if (s[0] as Vector2).distance_to(p) < 0.62:
					ok = false
					break
			if not ok:
				continue
			var to_booth := booth2 - p
			slots.append([p, atan2(-to_booth.x, -to_booth.y) + rng.randf_range(-0.6, 0.6), rng.randf() * TAU,
					Color(DANCE[rng.randi() % DANCE.size()]), rng.randf() * 0.99])
		var g := _ground(booth2)
		var dj2 := booth2 + side * 0.55
		raves.append({"id": id, "at": g, "yaw": atan2(face.x, face.y), "face": face, "dj": _ground(dj2), "dj_yaw": atan2(-face.x, -face.y),
				"slots": slots.map(func(s: Array) -> Array: return [_ground(s[0]), s[1], s[2], s[3], s[4]]),
				"n": 0, "on": false, "near": false, "booth": null, "line_t": _rng.randf_range(4.0, 10.0), "met": false})


## The pavement point nearest `p` within `reach`: [point, direction along, width] or [].
static func _nearest_foot(foot: Array, p: Vector2, reach: float) -> Array:
	var best: Array = []
	var bd := reach
	for f: Array in foot:
		var pts: PackedVector2Array = f[0]
		for j in pts.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, pts[j], pts[j + 1])
			var d := q.distance_to(p)
			if d < bd and pts[j].distance_to(pts[j + 1]) > 0.5:
				bd = d
				best = [q, (pts[j + 1] - pts[j]).normalized(), float(f[1])]
	return best


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, map.deck_height(-1, p.x, p.y) if map != null else 0.0, p.y)


# --- drawing -------------------------------------------------------------------------------

## The road riders on carbon road bikes, facing -z, in a four-shape family (CityLife.family_mesh:
## the jersey is the instance colour): a road bike with a round helmet, a time-trial bike with a
## disc wheel and an aero helmet, each twice (the family has four).
static func roadie_mesh() -> ArrayMesh:
	var tyre := [Models.TYRE, Models.FIXED]
	var carbon := [Color("#16171b"), Models.FIXED]
	var rim := [Color("#c9ccd1"), Models.FIXED]
	var skin := [Color("#e2b48c"), Models.FIXED]
	var helmet := [Color("#f2efe8"), Models.FIXED]
	var jersey := [Color.WHITE, Models.PAINT]
	var shorts := [Color("#151518"), Models.FIXED]
	var shoe := [Color("#f2efe8"), Models.FIXED]
	var parts := [tyre, tyre, carbon, carbon, carbon, rim, skin, helmet, jersey, jersey, shorts, shorts, shoe, shoe]
	var wf := [Vector3(0, 0.34, -0.52), Vector3(0.035, 0.68, 0.68)]
	var wr := [Vector3(0, 0.34, 0.52), Vector3(0.035, 0.68, 0.68)]
	var frame := [Vector3(0, 0.6, 0.0), Vector3(0.045, 0.05, 0.96)]
	var bar := [Vector3(0, 0.93, -0.5), Vector3(0.4, 0.05, 0.08)]
	var seat := [Vector3(0, 0.92, 0.3), Vector3(0.1, 0.05, 0.22)]
	var hub := [Vector3(0, 0.34, -0.52), Vector3(0.05, 0.12, 0.12)]
	var head := [Vector3(0, 1.36, -0.4), Vector3(0.22, 0.22, 0.24)]
	var lid := [Vector3(0, 1.49, -0.37), Vector3(0.27, 0.1, 0.36)]
	var torso := [Vector3(0, 1.17, -0.06), Vector3(0.38, 0.28, 0.66)]
	var arms := [Vector3(0, 1.04, -0.42), Vector3(0.46, 0.26, 0.12)]
	var leg_l := [Vector3(-0.1, 0.72, 0.16), Vector3(0.13, 0.46, 0.16)]
	var leg_r := [Vector3(0.1, 0.62, 0.1), Vector3(0.13, 0.46, 0.16)]
	var shoe_l := [Vector3(-0.1, 0.48, 0.1), Vector3(0.1, 0.07, 0.24)]
	var shoe_r := [Vector3(0.1, 0.38, 0.02), Vector3(0.1, 0.07, 0.24)]
	var road := [wf, wr, frame, bar, seat, hub, head, lid, torso, arms, leg_l, leg_r, shoe_l, shoe_r]
	var disc := [Vector3(0, 0.34, 0.52), Vector3(0.07, 0.68, 0.68)]
	var aero := [Vector3(0, 1.47, -0.28), Vector3(0.25, 0.13, 0.56)]
	var tt := [wf, disc, frame, [Vector3(0, 0.95, -0.62), Vector3(0.24, 0.05, 0.3)], seat, hub, head, aero, torso,
			[Vector3(0, 1.08, -0.5), Vector3(0.3, 0.12, 0.3)], leg_l, leg_r, shoe_l, shoe_r]
	return CityLife.family_mesh(parts, [road, tt, road, tt])


## The rave's booth, facing +z (the street): a table on trestles with two decks and a laptop, two
## speakers, a lit KAWOWY RAVE board on two posts and a string of party lights (actor.gdshader's
## LIT_SIGN glows at night). One mesh on the actor material.
static func booth_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color("#c9a46b")
	var black := Color("#18181b")
	var grey := Color("#5a5d63")
	Models.box(st, Vector3(0, 0.93, 0), Vector3(1.7, 0.06, 0.7), wood)
	for x in [-0.7, 0.7]:
		Models.box(st, Vector3(x, 0.45, 0), Vector3(0.06, 0.9, 0.6), wood)
	Models.box(st, Vector3(0, 0.55, 0.36), Vector3(1.7, 0.7, 0.02), Color("#f2efe8"))
	for x in [-0.42, 0.42]:
		Models.box(st, Vector3(x, 1.0, 0), Vector3(0.42, 0.08, 0.34), black)
		Models.box(st, Vector3(x, 1.05, 0), Vector3(0.22, 0.02, 0.22), grey)
	Models.box(st, Vector3(0, 1.08, -0.12), Vector3(0.3, 0.2, 0.02), Color("#c9ccd1"))
	for x in [-1.25, 1.25]:
		Models.box(st, Vector3(x, 0.6, 0), Vector3(0.5, 1.2, 0.45), black)
		Models.box(st, Vector3(x, 0.45, 0.23), Vector3(0.3, 0.3, 0.02), grey)
		Models.box(st, Vector3(x, 0.92, 0.23), Vector3(0.16, 0.16, 0.02), grey)
	# The board: dark, the words in warm cream (lit at night), on two posts behind the table.
	var px := 0.07
	var text := "KAWOWY RAVE"
	var bw := (PixelFont.width(text) + 6) * px
	var bh := (PixelFont.LINE + 3) * px
	var y0 := 2.55
	Models.box(st, Vector3(0, y0, -0.45), Vector3(bw, bh, 0.06), Color("#231a2e"))
	var lw := PixelFont.width(text) * px
	PixelFont.add_quads(st, text, Vector3(-lw * 0.5, y0 + bh * 0.5 - 1.5 * px, -0.41), Vector3.RIGHT, Vector3.DOWN, px,
			Color("#ffe2a8"), Models.LIT_SIGN)
	for x in [-bw * 0.5 + 0.06, bw * 0.5 - 0.06]:
		Models.box(st, Vector3(x, (y0 - bh * 0.5) * 0.5, -0.45), Vector3(0.07, y0 - bh * 0.5, 0.07), grey)
	# The party lights: a sagging string of bulbs from the posts outwards.
	var bulbs := ["#ff5fa2", "#ffd23f", "#4ae0c0", "#9b6bff", "#ff8a3c"]
	for k in 13:
		var f := float(k) / 12.0
		var x := lerpf(-bw * 0.5 - 1.2, bw * 0.5 + 1.2, f)
		var y := y0 - bh * 0.5 - 0.1 - sin(f * PI) * 0.35
		Models.box(st, Vector3(x, y, -0.45), Vector3(0.09, 0.11, 0.09), Color(bulbs[k % bulbs.size()]), Models.LIT_SIGN)
	return st.commit()


func _build_drawing() -> void:
	var run_cap := 0
	var ride_cap := 0
	for c in clubs:
		if c["kind"] == "run":
			run_cap += int(c["cap"])
		else:
			ride_cap += int(c["cap"])
	var dance_cap := 0
	for r in raves:
		dance_cap += (r["slots"] as Array).size() + 1
	var person := Models.person_mesh()
	var run_mat := Models.material().duplicate() as ShaderMaterial
	run_mat.set_shader_parameter("walk", RUN_STRIDE)
	var dance_mat := Models.material().duplicate() as ShaderMaterial
	dance_mat.set_shader_parameter("walk", DANCE_STRIDE)
	_run_mm = _new_mm(person, maxi(run_cap, 1))
	_run_mmi = _new_mmi(_run_mm, "RunClubs", run_mat)
	_run_buf.resize(maxi(run_cap, 1) * 16)
	_run_buf.fill(0.0)
	_ride_mm = _new_mm(roadie_mesh(), maxi(ride_cap, 1))
	_ride_mmi = _new_mmi(_ride_mm, "CyclingPacks", Models.material())
	_ride_buf.resize(maxi(ride_cap, 1) * 16)
	_ride_buf.fill(0.0)
	_dance_mm = _new_mm(person, maxi(dance_cap, 1))
	_dance_mmi = _new_mmi(_dance_mm, "CoffeeRaves", dance_mat)
	_dance_buf.resize(maxi(dance_cap, 1) * 16)
	_dance_buf.fill(0.0)
	var bm := booth_mesh()
	for r in raves:
		var mi := MeshInstance3D.new()
		mi.name = "RaveBooth_%s" % r["id"]
		mi.mesh = bm
		mi.material_override = Models.material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = r["at"]
		mi.rotation.y = float(r["yaw"])
		mi.visible = false
		add_child(mi)
		r["booth"] = mi


func _new_mm(mesh: Mesh, cap: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = cap
	mm.visible_instance_count = 0
	return mm


func _new_mmi(mm: MultiMesh, n: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.visible = false
	add_child(mmi)
	return mmi


# --- the logic -----------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or not clock.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	_tick_t += dt
	if _route_task >= 0 and WorkerThreadPool.is_task_completed(_route_task):
		WorkerThreadPool.wait_for_task_completion(_route_task)
		_route_task = -1
		_finish_routes()
	if _tick_t >= TICK:
		var step := _tick_t
		_tick_t = 0.0
		tick(step)
	_move_t += dt
	if _move_t >= MOVE_TICK:
		_move_t = 0.0
		move_packs()
	_dance_t += dt
	if _dance_t >= DANCE_TICK:
		_dance_t = 0.0
		dance()
	spent_usec += Time.get_ticks_usec() - t0


## One tick of the logic: who is out, who is near the view, the lines and the toasts.
func tick(step: float) -> void:
	var now: Dictionary = clock.call()
	_hour = float(now["hour"])
	_weekday = int(now["weekday"])
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye := Vector2(eye3.x, eye3.z)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var vp: Vector3 = veh[0]
	var car2 := Vector2(vp.x, vp.z) if vp != Vector3.INF and not bool(veh[2]) else Vector2.INF
	for c in clubs:
		var spec: Dictionary = (RUN_CLUBS if c["kind"] == "run" else RIDE_CLUBS)[c["id"]]
		var n := mini(club_count(spec, _hour, _weekday, amount, force), int(c["cap"]))
		var route: Dictionary = c["route"]
		if route.is_empty():
			n = 0
		var on := n > 0
		if on != bool(c["on"]) and log_on:
			print("packs: %s %s (%d)" % [c["name"], "sets off" if on else "goes home", n])
		c["on"] = on
		c["n"] = n
		c["near"] = on and _club_near(c, eye)
		if bool(c["near"]):
			_club_talk(c, step, eye, car2)
	for r in raves:
		var n := mini(rave_count(str(r["id"]), _hour, _weekday, amount, force), (r["slots"] as Array).size())
		var on := n > 0
		if on != bool(r["on"]) and log_on:
			var a: Vector3 = r["at"]
			print("packs: the coffee rave at %s %s (%d dancers, booth at %.0f, %.0f)" % [r["id"], "starts" if on else "packs up", n, a.x, a.z])
		r["on"] = on
		r["n"] = n
		var near := on and eye.distance_to(Vector2((r["at"] as Vector3).x, (r["at"] as Vector3).z)) < ACTIVE_R
		if near != bool(r["near"]):
			r["near"] = near
			(r["booth"] as MeshInstance3D).visible = near
		if near:
			_rave_talk(r, step, eye, car2, float(veh[1]))
	if log_on:
		_log_t -= step
		if _log_t <= 0.0:
			_log_t = 60.0
			print("packs: %s" % summary())


## "14:00 day 5 · runs tempo_na_kawe 0, ... · rides ... · raves coffeechair_hoza 14 · lines 3".
func summary() -> String:
	var runs := PackedStringArray()
	var rides := PackedStringArray()
	for c in clubs:
		var s := "%s %d" % [c["id"], c["n"]]
		var route: Dictionary = c["route"]
		if route.is_empty():
			s += " (no route)"
		elif bool(c["on"]):
			var p := _route_point(route, head_at(float(route["len"]), float(c["v"]), float(c["phase"]), t))
			s += " @%.0f,%.0f" % [p.x, p.z]
		(runs if c["kind"] == "run" else rides).append(s)
	var rv := PackedStringArray()
	for r in raves:
		if bool(r["on"]):
			rv.append("%s %d" % [r["id"], r["n"]])
	return "%02d:%02d day %d · runs %s · rides %s · raves %s · lines %d · meets %d" % [int(_hour), int(fmod(_hour, 1.0) * 60.0),
			_weekday, ", ".join(runs), ", ".join(rides), ", ".join(rv) if not rv.is_empty() else "none", lines_said, meets]


## Is any of the pack within ACTIVE_R of the view (its head or its tail, the pack is ≤ 30 m long)?
func _club_near(c: Dictionary, eye: Vector2) -> bool:
	var route: Dictionary = c["route"]
	var head := head_at(float(route["len"]), float(c["v"]), float(c["phase"]), t)
	var p := _route_point(route, head)
	return Vector2(p.x, p.z).distance_to(eye) < ACTIVE_R


## A point `s` metres along a route (wrapping), with the heading as w: Vector4(x, y, z, yaw).
static func route_pose(route: Dictionary, s: float, lat := 0.0) -> Vector4:
	var cum: PackedFloat32Array = route["cum"]
	var pts: PackedVector2Array = route["pts"]
	var h: PackedFloat32Array = route["h"]
	var length := float(route["len"])
	var ss := fposmod(s, maxf(length, 0.001))
	var k := clampi(cum.bsearch(ss, true) - 1, 0, cum.size() - 2)
	var seg := maxf(cum[k + 1] - cum[k], 0.001)
	var f := clampf((ss - cum[k]) / seg, 0.0, 1.0)
	var dir := (pts[k + 1] - pts[k]) / seg
	var q := pts[k].lerp(pts[k + 1], f) + Vector2(-dir.y, dir.x) * lat
	return Vector4(q.x, lerpf(h[k], h[k + 1], f), q.y, atan2(-dir.x, -dir.y))


static func _route_point(route: Dictionary, s: float) -> Vector3:
	var p := route_pose(route, s)
	return Vector3(p.x, p.y, p.z)


## Every member's place now into the club's `pos` and `yaw`.
func _place_club(c: Dictionary) -> void:
	var route: Dictionary = c["route"]
	if route.is_empty():
		return
	var head := head_at(float(route["len"]), float(c["v"]), float(c["phase"]), t)
	var pos: PackedVector3Array = c["pos"]
	var yaw: PackedFloat32Array = c["yaw"]
	var lat: PackedFloat32Array = c["lat"]
	var back: PackedFloat32Array = c["back"]
	var run: bool = c["kind"] == "run"
	for j in int(c["n"]):
		var ps := route_pose(route, head - back[j], lat[j])
		# A runner's bounce in the stride.
		var y := ps.y + (absf(sin(t * 9.0 + j * 1.7)) * 0.06 if run else 0.0)
		pos[j] = Vector3(ps.x, y, ps.z)
		yaw[j] = ps.w
	c["pos"] = pos
	c["yaw"] = yaw


## The packs' figures, 15 times a second while near the view.
func move_packs() -> void:
	var nr := 0
	var nd := 0
	var rbox := AABB()
	var dbox := AABB()
	for c in clubs:
		if not bool(c["near"]):
			continue
		_place_club(c)
		var run: bool = c["kind"] == "run"
		var pos: PackedVector3Array = c["pos"]
		var yaw: PackedFloat32Array = c["yaw"]
		var shirt: PackedColorArray = c["shirt"]
		var tr: PackedFloat32Array = c["tr"]
		for j in int(c["n"]):
			if run:
				if nr >= _run_mm.instance_count:
					break
				Crowds.put(_run_buf, nr, pos[j], yaw[j], Crowds.STAND, shirt[j], tr[j])
				rbox = AABB(pos[j], Vector3.ZERO) if nr == 0 else rbox.expand(pos[j])
				nr += 1
			else:
				if nd >= _ride_mm.instance_count:
					break
				CityLife.put(_ride_buf, nd, pos[j], yaw[j], Vector3.ONE, shirt[j], tr[j])
				dbox = AABB(pos[j], Vector3.ZERO) if nd == 0 else dbox.expand(pos[j])
				nd += 1
	_send(_run_mm, _run_mmi, _run_buf, nr, rbox)
	_send(_ride_mm, _ride_mmi, _ride_buf, nd, dbox)


## The dancers, 10 times a second at the raves near the view: a bounce on the beat and a sway.
func dance() -> void:
	var n := 0
	var box := AABB()
	for r in raves:
		if not bool(r["near"]):
			continue
		var slots: Array = r["slots"]
		var dj: Vector3 = r["dj"]
		if n < _dance_mm.instance_count:
			Crowds.put(_dance_buf, n, dj + Vector3(0, absf(sin(t * BEAT * PI)) * 0.05, 0), float(r["dj_yaw"]) + sin(t * 1.3) * 0.25,
					Crowds.BROAD, DJ_SHIRT, 0.2)
			box = AABB(dj, Vector3.ZERO) if n == 0 else box.expand(dj)
			n += 1
		for k in mini(int(r["n"]), slots.size()):
			if n >= _dance_mm.instance_count:
				break
			var s: Array = slots[k]
			var ph := float(s[2])
			var at: Vector3 = s[0]
			var bounce := absf(sin(t * BEAT * PI + ph)) * BOUNCE
			Crowds.put(_dance_buf, n, at + Vector3(0, bounce, 0), float(s[1]) + sin(t * BEAT * 0.5 * PI + ph) * SWAY, Crowds.STAND, s[3], s[4])
			box = box.expand(at)
			n += 1
	_send(_dance_mm, _dance_mmi, _dance_buf, n, box)


func _send(mm: MultiMesh, mmi: MultiMeshInstance3D, buf: PackedFloat32Array, n: int, box: AABB) -> void:
	mm.visible_instance_count = n
	if n > 0:
		InstanceBuffers.send(mm.get_rid(), buf)
		mm.custom_aabb = box.grow(1.5).expand(box.end + Vector3(0, 2.8, 0))
	if mmi.visible != (n > 0):
		mmi.visible = n > 0


## A pack's lines: the car close behind it (`car`), else a member's line now and then while it is
## on screen near the view; the club's name as a toast the first time the car meets it.
func _club_talk(c: Dictionary, step: float, eye: Vector2, car2: Vector2) -> void:
	var pos: PackedVector3Array = c["pos"]
	var n := int(c["n"])
	if n == 0:
		return
	var head: Vector3 = pos[0]
	var tail: Vector3 = pos[n - 1]
	var group := "run_club" if c["kind"] == "run" else "peleton"
	if car2 != Vector2.INF and not bool(c["met"]):
		var d := minf(car2.distance_to(Vector2(head.x, head.z)), car2.distance_to(Vector2(tail.x, tail.z)))
		if d < MEET_R:
			c["met"] = true
			meets += 1
			if hud != null and hud.has_method("toast"):
				var what := "Klub biegowy" if c["kind"] == "run" else "Peleton"
				var gloss := "Running club" if c["kind"] == "run" else "Cycling pack"
				hud.toast("%s %s" % [what, c["name"]], "%s: %s" % [gloss, c["gloss"]])
			if log_on:
				print("packs: the car meets %s (%.0f m)" % [c["name"], d])
	c["line_t"] = float(c["line_t"]) - step
	if float(c["line_t"]) > 0.0:
		return
	var close := car2 != Vector2.INF and car2.distance_to(Vector2(tail.x, tail.z)) < CAR_NEAR
	var seen: bool = eye.distance_to(Vector2(head.x, head.z)) < LINE_VIEW and (not on_screen.is_valid() or on_screen.call(head, 2.0))
	if not close and not seen:
		return
	c["line_t"] = _rng.randf_range(LINE_GAP.x, LINE_GAP.y)
	var j := (n - 1) if close else _rng.randi() % mini(n, 6)
	_say(func() -> Vector3: return (c["pos"] as PackedVector3Array)[mini(j, int(c["n"]) - 1)] + Vector3(0, 2.0, 0) if int(c["n"]) > 0 else Vector3.INF,
			"", group, "car" if close else "", BUBBLE, close)


## A rave's lines: the DJ to a slow car near the booth (`dj`), else a dancer now and then on screen.
func _rave_talk(r: Dictionary, step: float, eye: Vector2, car2: Vector2, kmh: float) -> void:
	var at: Vector3 = r["at"]
	var a2 := Vector2(at.x, at.z)
	if car2 != Vector2.INF and not bool(r["met"]) and car2.distance_to(a2) < MEET_R:
		r["met"] = true
		meets += 1
		if hud != null and hud.has_method("toast"):
			hud.toast("Kawowy rave przed COFFEECHAIR", "A coffee rave outside COFFEECHAIR")
	r["line_t"] = float(r["line_t"]) - step
	if float(r["line_t"]) > 0.0 or int(r["n"]) == 0:
		return
	var slow := car2 != Vector2.INF and car2.distance_to(a2) < RAVE_CAR and kmh < RAVE_KMH
	var seen: bool = eye.distance_to(a2) < LINE_VIEW and (not on_screen.is_valid() or on_screen.call(at, 2.0))
	if not slow and not seen:
		return
	r["line_t"] = _rng.randf_range(LINE_GAP.x, LINE_GAP.y)
	if slow and _rng.randf() < 0.6:
		var dj: Vector3 = r["dj"]
		_say(func() -> Vector3: return dj + Vector3(0, 2.2, 0), "DJ Espresso", "coffee_rave", "dj", RAVE_BUBBLE, true)
	else:
		var slots: Array = r["slots"]
		var p: Vector3 = slots[_rng.randi() % mini(int(r["n"]), slots.size())][0]
		_say(func() -> Vector3: return p + Vector3(0, 2.1, 0), "", "coffee_rave", "", RAVE_BUBBLE)


func _say(anchor: Callable, speaker: String, group: String, tag: String, accent: Color, prefer := false) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.say(anchor, speaker, group, tag, 4.0, accent, 2.2, prefer or tag != "")
	if not l.is_empty():
		lines_said += 1
		if log_on:
			print("packs: line %s/%s: %s" % [group, tag, l[0]])


## The pack or rave nearest a point (for --packs-now shots and the log): [kind, id, Vector3] or [].
func nearest_to(p: Vector2) -> Array:
	var best: Array = []
	var bd := INF
	for c in clubs:
		if (c["route"] as Dictionary).is_empty():
			continue
		var q := _route_point(c["route"], head_at(float(c["route"]["len"]), float(c["v"]), float(c["phase"]), t))
		var d := Vector2(q.x, q.z).distance_to(p)
		if d < bd:
			bd = d
			best = [c["kind"], c["id"], q]
	for r in raves:
		var a: Vector3 = r["at"]
		var d := Vector2(a.x, a.z).distance_to(p)
		if d < bd:
			bd = d
			best = ["rave", r["id"], a]
	return best


func _exit_tree() -> void:
	if _route_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_route_task)
		_route_task = -1
