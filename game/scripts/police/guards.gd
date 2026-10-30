extends Node
## Loop 3g-2 (police, part two; docs/design/police.md section 5.6): the city guards ("Straż
## Miejska"). police.gd makes one and calls `frame` every frame and `tick` right after its 5 Hz
## perception pass. Guards never call the police and never chase: nothing here starts, raises or
## counts anything in police.gd's state machine, and nothing touches the złoty.
##
## - The guards on foot stand at the posts of data/police_guards.json (pedestrian-zone gates and
##   squares), two a post, shown while the player is near (fixed people in the pedestrians'
##   MultiMesh after the speed traps' officers: +0 draw calls); each has a small beehave tree
##   (guard_unit.gd), the six nearest ticked at 5 Hz.
## - In a pedestrian zone the car is held to 20 km/h (main.gd, car.gd `zone_cap`: loop 3d-1) and
##   the pill says so (F's asks, 2026-10-30: only with Settings → JAZDA's zone switch on, off by
##   default; off, no pill, whistle, run or car following); the nearest guard within 60 m whistles and says a `guard` line (at most once
##   a zone a minute), runs after the car at 5 m/s for 3 s, gives up ("run"), walks back. The
##   guards' car, if it is out near the Old Town, follows at 25 km/h with its amber beacon for
##   15 s, then turns away.
## - Stopping by a guard (within 10 m, under 1 m/s, 1.5 s) opens the guard conversation
##   (police.dialogue `guard_stop`: a zone line, a reply, a caution in the joke notebook).
## - The clamp ("blokada"): the car stopped on a footway for 20 s with a guard within 30 m: the
##   guard walks over, says the clamp line, writes for 10 s (the countdown pill); still there,
##   the clamp goes on (a yellow box on the front wheel, the car held) with a card and one button,
##   Przepraszam · Sorry: a tap or 10 s takes it off. It costs nothing.

const GuardUnit := preload("res://scripts/police/guard_unit.gd")
const Models := preload("res://scripts/models.gd")
const POSTS_PATH := "res://data/police_guards.json"

## The pedestrians' fixed slots the guards take (0-2 the day's trap officers, 3 the first
## contact's officer), and how many guards are shown at once.
const SLOT0 := 4
const SHOWN := 8
## Posts this near the player are staffed (out of sight), and let go this far.
const STAFF := 300.0
const UNSTAFF := 360.0
## The trees ticked: the nearest this many within this reach.
const TICKED := 6
const TICK_REACH := 150.0
## The whistle (police.md 5.6): a guard within this reach of the car in a zone, once a zone a minute.
const WHISTLE_REACH := 60.0
const ZONE_GAP := 60.0
const MOVING := 1.5
## The log's top speed in a zone counts from this many seconds in (the cap takes the gas away;
## a car coming in faster coasts down to it).
const ZONE_SETTLE := 3.0
const RUN_TIME := 3.0
## The talk: within TALK_REACH under TALK_SPEED for TALK_HOLD s; that guard waits TALK_GAP after.
const TALK_REACH := 10.0
const TALK_SPEED := 1.0
const TALK_HOLD := 1.5
const TALK_GAP := 60.0
## The clamp: parked CLAMP_PARK s on a footway with a guard within CLAMP_REACH; CLAMP_COUNT s of
## countdown; on for CLAMP_ON s at most (or until the tap). The car must move CLAMP_MOVE m before
## another count starts.
const CLAMP_REACH := 30.0
const CLAMP_PARK := 20.0
const CLAMP_COUNT := 10.0
const CLAMP_ON := 10.0
const CLAMP_STILL := 0.5
const CLAMP_MOVE := 3.0
## The guards' car: out while the player is within CAR_NEAR of a post, gone beyond CAR_FAR (out of
## sight); follows within CAR_REACH of the car at CAR_TOP for CAR_FOLLOW s.
const CAR_NEAR := 500.0
const CAR_FAR := 800.0
const CAR_REACH := 400.0
const CAR_TOP := 25.0 / 3.6
const CAR_FOLLOW := 15.0
const CAR_REPLAN := 1.0
## The look (police.md section 9): a mustard jacket; trousers from the people's palette (the dark
## red of the spec needs a palette entry in actor.gdshader: the near-black one stands in).
const SHIRT := Color("#e3b33a")
const TROUSERS := 0.3
const COLOUR := Color("#e3b33a")
const SPEAKER := "Strażnik Henio"

var police: Node
var guards: Array = []
## The zone the car is in now ("" outside), from main.gd through police.gd.
var zone := ""
## F's asks (2026-10-30): the zones' cap is on (Settings → JAZDA, off by default). Off: no zone
## pill and no whistle, run or guards' car following; the guards still stand at their posts and
## the clamp keeps its rule (stopped 20 s in a zone or on a footway by a guard).
var zone_cap := false
## The clamp: "" (none), "count" (the countdown), "on".
var clamp := ""
var clamp_t := 0.0
var park_t := 0.0
var _park_at := Vector2.INF
var _moved := true
var _clamp_guard = null
var _clamp_box: MeshInstance3D
var _whistled := {}
var _runs := {}
var _talk_t := 0.0
var _talk_guard = null
var _was_zone := ""
var _zone_top := 0.0
var _zone_t := 0.0
var _car_unit = null
var _car_t := 0.0
var _car_follow := 0.0
var _car_plan := 0.0
var _car_try := 0.0
var _free_slots: Array[int] = []
var _sorry_at := -1.0


func setup(p: Node) -> void:
	police = p
	for i in SHOWN:
		_free_slots.append(SLOT0 + SHOWN - 1 - i)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(POSTS_PATH))
	if not parsed is Dictionary:
		push_error("guards: can't read %s" % POSTS_PATH)
		return
	var outside := PackedStringArray()
	for row: Dictionary in parsed["posts"]:
		var id := String(row["id"])
		var facing := -deg_to_rad(float(row.get("heading", 0.0)))
		var k := 0
		for at: Array in row["at"]:
			var g := GuardUnit.new("%s_%d" % [id, k], String(row.get("tag", "")), Vector2(at[0], at[1]), facing)
			k += 1
			g.build()
			add_child(g)
			guards.append(g)
			if police.ped_zones != null and police.ped_zones.at(at[0], at[1]) == "":
				outside.append(g.post)
	police._log("guards: %d at %d posts%s" % [guards.size(), (parsed["posts"] as Array).size(),
			(" (outside a zone: %s)" % ", ".join(outside)) if not outside.is_empty() else ""])


func _glog(text: String) -> void:
	if police.log_on:
		print("guard: %s (frame %d, %.1f s)" % [text, police._frame, police.clock])


## The car is held: the clamp is on.
func holds() -> bool:
	return clamp == "on"


## The pill while nothing police-side is showing: the clamp's countdown, or the zone's cap.
func pill() -> Array:
	if clamp == "count":
		var left := maxi(0, ceili(CLAMP_COUNT - clamp_t))
		return ["BLOKADA ZA 0:%02d" % left, "CLAMP IN 0:%02d" % left]
	if zone != "" and zone_cap and not police.flying:
		return ["STREFA PIESZA · 20 KM/H", "PEDESTRIAN ZONE · 20 KM/H"]
	return []


# --- every frame ---------------------------------------------------------------------------

func frame(dt: float) -> void:
	var p := _car2()
	for g in guards:
		g.talk_wait -= dt
		if g.slot >= 0:
			g.car_at = p
			g.step(dt)
			_draw(g)
	if zone != "" and not police.flying:
		_zone_t += dt
		if _zone_t > ZONE_SETTLE:
			var v: Vector3 = police.car.vel
			_zone_top = maxf(_zone_top, Vector2(v.x, v.z).length())
	for g in _runs.keys():
		_runs[g] -= dt
		if _runs[g] <= 0.0:
			_runs.erase(g)
			g.set_role("post")
			_say(g, "run", true)
			_glog("gave up (post %s, %.0f m from the car)" % [g.post, g.pos.distance_to(p)])
	_clamp_frame(dt)
	_talk_frame(dt)


func _car2() -> Vector2:
	var c: Vector3 = police.car.global_position
	return Vector2(c.x, c.z)


func _draw(g) -> void:
	if police.walkers == null:
		return
	var y: float = police.map.ground_height(g.pos.x, g.pos.y)
	police.walkers.set_fixed(g.slot, Vector3(g.pos.x, y, g.pos.y), g.yaw, SHIRT, TROUSERS)


# --- 5 times a second ------------------------------------------------------------------------

func tick() -> void:
	var p := _car2()
	var near: Array = []
	for g in guards:
		g.dist = g.pos.distance_to(p)
		if g.slot < 0 and g.dist < STAFF and _free_slots.size() > 0 and (police.clock < 1.0 or not _seen(g.home)):
			g.slot = _free_slots.pop_back()
			g.pos = g.home
			g.yaw = g.face
			g.set_role("post")
			_draw(g)
		elif g.slot >= 0 and g.dist > UNSTAFF and not _seen(g.pos) and g.role() == "post":
			if police.walkers != null:
				police.walkers.clear_fixed(g.slot)
			_free_slots.append(g.slot)
			g.slot = -1
		if g.slot >= 0 and g.dist < TICK_REACH:
			near.append(g)
	near.sort_custom(func(a, b) -> bool: return a.dist < b.dist)
	for k in mini(near.size(), TICKED):
		near[k].tick()
	_zone_tick(p)
	_car_tick(p)


func _seen(at: Vector2) -> bool:
	return police.traffic.on_screen(Vector3(at.x, police.map.ground_height(at.x, at.y), at.y), 1.8)


func _nearest(p: Vector2, reach: float, staffed_only := true):
	var best = null
	for g in guards:
		if staffed_only and g.slot < 0:
			continue
		var d: float = g.pos.distance_to(p)
		if d < reach and (best == null or d < best.pos.distance_to(p)):
			best = g
	return best


## The zone: entering, the whistle, the guard's run and the guards' car following.
func _zone_tick(p: Vector2) -> void:
	var z := zone if not police.flying else ""
	if z != _was_zone:
		_zone_t = 0.0
		if z != "":
			_zone_top = 0.0
			_glog("zone %s entered at %d km/h" % [z, roundi(police.car.vel.length() * 3.6)])
		else:
			_glog("zone %s left (top speed in it after the first %.0f s: %d km/h)" % [_was_zone, ZONE_SETTLE, roundi(_zone_top * 3.6)])
		_was_zone = z
	if z == "" or not zone_cap or police.car.vel.length() < MOVING or clamp != "":
		return
	if police.clock - float(_whistled.get(z, -1.0e9)) < ZONE_GAP:
		return
	var g = _nearest(p, WHISTLE_REACH)
	if g == null or g.role() != "post":
		return
	_whistled[z] = police.clock
	police.sfx_cue("whistle")
	_say(g, g.tag, true)
	g.set_role("run")
	_runs[g] = RUN_TIME
	_glog("whistle (post %s, %.0f m, %d km/h)" % [g.post, g.dist, roundi(police.car.vel.length() * 3.6)])
	_car_on()


func _say(g, tag: String, prefer: bool) -> void:
	if police.dialogue == null:
		return
	var anchor := func() -> Vector3:
		if g.slot < 0:
			return Vector3.INF
		return Vector3(g.pos.x, police.map.ground_height(g.pos.x, g.pos.y) + 2.2, g.pos.y)
	var l: Array = police.dialogue.say(anchor, SPEAKER, "guard", tag, 3.2, COLOUR, 0.0, prefer)
	if not l.is_empty():
		_glog("line guard/%s: %s" % [tag, l[0]])


# --- the guards' car ---------------------------------------------------------------------------

func _car_tick(p: Vector2) -> void:
	if _car_unit != null and _car_unit.driver == null:
		_car_unit = null
	var near_post := INF
	for g in guards:
		near_post = minf(near_post, g.home.distance_to(p))
	if _car_unit == null:
		_car_try -= police.TICK
		if near_post < CAR_NEAR and _car_try <= 0.0 and not police.flying:
			_car_try = 2.0
			_spawn_car(p)
		return
	var d = _car_unit.driver
	if near_post > CAR_FAR and not police.traffic.on_screen(d.pos, 2.0):
		police.traffic.remove(d)
		_car_unit = null
		return
	if _car_follow > 0.0:
		_car_follow -= police.TICK
		_car_plan -= police.TICK
		if _car_follow <= 0.0:
			_car_unit.set_role("guard")
			_glog("guard car turned away")
		elif _car_plan <= 0.0:
			_car_plan = CAR_REPLAN
			var hit: Array = police.graph.snap(p, 80.0)
			if not hit.is_empty() and not d.parked:
				var node: int = police.graph.e_b[hit[0]]
				d.goal = police.graph.node_pos[node]
				police.traffic.race_to(d, node, police.graph.distances_to(node, police.MAX_COST))


## The guards' car joins a whistle when it is out near the car.
func _car_on() -> void:
	if _car_unit == null or _car_unit.driver == null:
		return
	var d = _car_unit.driver
	var away := Vector2(d.pos.x, d.pos.z).distance_to(_car2())
	if away > CAR_REACH:
		return
	_car_follow = CAR_FOLLOW
	_car_plan = 0.0
	_car_unit.set_role("guard_follow")
	_glog("guard car following (%.0f m away, at most %d km/h, 15 s)" % [away, roundi(CAR_TOP * 3.6)])


## Out of sight on a road 150-300 m from the player, round the Old Town.
func _spawn_car(p: Vector2) -> void:
	var graph = police.graph
	for k in 8:
		var a := TAU * (k + randf()) / 8.0
		var q := p + Vector2(cos(a), sin(a)) * randf_range(150.0, 300.0)
		var hit: Array = graph.snap(q, 40.0)
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var s: float = clampf(hit[2], graph.e_s0[e] + 2.0, graph.e_s1[e] - 4.0)
		var at: Vector2 = graph.point_at(e, s)
		if police.traffic.on_screen(Vector3(at.x, graph.height(e, s), at.y), 2.0):
			continue
		var d = police.traffic.add_police(e, hit[1], s, 1)
		if d == null:
			return
		var u = police._bind(d, "guard")
		if u == null:
			police.traffic.remove(d)
			return
		d.v = graph.e_speed[e] * 0.5
		_car_unit = u
		_glog("guard car out (unit %d) at %d,%d" % [u.number, roundi(at.x), roundi(at.y)])
		return


# --- the talk ----------------------------------------------------------------------------------

func _talk_frame(dt: float) -> void:
	if police.car.vel.length() >= TALK_SPEED or not police.calm() or police.flying or clamp != "" or police._rescue_on():
		_talk_t = 0.0
		_talk_guard = null
		return
	var p := _car2()
	var g = _nearest(p, TALK_REACH)
	if g == null or g.talk_wait > 0.0 or police.car.vel.length() >= TALK_SPEED:
		_talk_t = 0.0
		_talk_guard = null
		return
	if g != _talk_guard:
		_talk_guard = g
		_talk_t = 0.0
	_talk_t += dt
	if _talk_t >= TALK_HOLD:
		_talk_t = 0.0
		_talk_guard = null
		_runs.erase(g)
		g.set_role("talk")
		_glog("talk (post %s, %.1f m)" % [g.post, g.pos.distance_to(p)])
		police.guard_talk(g)


## police.gd: the guard conversation ended.
func talk_done(g) -> void:
	if g != null:
		g.set_role("post")
		g.talk_wait = TALK_GAP
	park_t = 0.0


# --- the clamp ---------------------------------------------------------------------------------

func _clamp_frame(dt: float) -> void:
	var p := _car2()
	var speed: float = police.car.vel.length()
	if _park_at != Vector2.INF and p.distance_to(_park_at) > CLAMP_MOVE:
		_moved = true
	match clamp:
		"":
			if speed > CLAMP_STILL or not _moved or police.flying or not police.calm():
				park_t = 0.0
				return
			var g = _nearest(p, CLAMP_REACH)
			# (The footway lookup only for a car stopped by a guard: it scans the nearby ways.)
			if g == null or not (zone != "" or (police.walkers != null and police.walkers.on_footway(p))):
				park_t = 0.0
				return
			if park_t == 0.0:
				_park_at = p
			park_t += dt
			if park_t >= CLAMP_PARK:
				_clamp_count(g)
		"count":
			clamp_t += dt
			if speed > MOVING or p.distance_to(_park_at) > CLAMP_MOVE or not police.calm() or police.flying:
				_glog("clamp countdown dropped (drove off after %.1f s)" % clamp_t)
				_clamp_end()
				return
			if clamp_t >= CLAMP_COUNT:
				_clamp_on()
		"on":
			clamp_t += dt
			if _sorry_at >= 0.0 and police.clock >= _sorry_at:
				_sorry_at = -1.0
				_glog("sorry tapped (test)")
				sorry()
				return
			var left := maxi(0, ceili(CLAMP_ON - clamp_t))
			_clamp_card(left)
			if clamp_t >= CLAMP_ON:
				_off("10 s")


## --clamp: parked by a guard at frame 60, the countdown starts at once (with "sorry": the tap
## comes 1 s after the clamp goes on).
func test_clamp(tap: bool) -> void:
	var g = _nearest(_car2(), CLAMP_REACH, false)
	if g == null:
		_glog("no guard within %d m for the clamp test" % roundi(CLAMP_REACH))
		return
	_park_at = _car2()
	_moved = true
	if tap:
		_sorry_at = INF
	_clamp_count(g)


func _clamp_count(g) -> void:
	clamp = "count"
	clamp_t = 0.0
	park_t = 0.0
	_clamp_guard = g
	_runs.erase(g)
	g.set_role("clamp")
	_say(g, "clamp", true)
	police.sfx_cue("scribble")
	_glog("clamp countdown (post %s, %.0f m, parked %.0f s)" % [g.post, g.dist, CLAMP_PARK])


func _clamp_on() -> void:
	clamp = "on"
	clamp_t = 0.0
	police.sfx_cue("clank")
	_box(true)
	_clamp_card(ceili(CLAMP_ON))
	police.hud.show_panel(police._balloon, true)
	police.hud.set_pedals_hidden(true)
	if _sorry_at == INF:
		_sorry_at = police.clock + 1.0
	_glog("clamp on (%.1f s after the countdown began)" % CLAMP_COUNT)


func _clamp_card(left: int) -> void:
	police._balloon.show_line(SPEAKER, "BLOKADA NA KOLE · ZDEJMUJĘ ZA 0:%02d" % left, "WHEEL CLAMP ON · OFF IN 0:%02d" % left,
			[["Przepraszam", "Sorry", ""]])


## The card's tap or its button: the clamp comes off at once.
func sorry() -> void:
	if clamp == "on":
		_off("sorry, %.1f s on" % clamp_t)


func _off(why: String) -> void:
	police.sfx_cue("clank")
	_glog("clamp off (%s)" % why)
	_clamp_end()


func _clamp_end() -> void:
	if clamp == "on":
		police.hud.show_panel(police._balloon, false)
		police.hud.set_pedals_hidden(false)
	_box(false)
	clamp = ""
	clamp_t = 0.0
	park_t = 0.0
	_moved = false
	_sorry_at = -1.0
	if _clamp_guard != null:
		# Said its piece: no talk on the way back to the post.
		_clamp_guard.set_role("post")
		_clamp_guard.talk_wait = TALK_GAP
		_clamp_guard = null


## The clamp: a yellow 0.3 m box on the front left wheel (the people's material; shown only
## while a clamp is on, no shadow).
func _box(on: bool) -> void:
	var car: Node3D = police.car
	if on and _clamp_box == null:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Models.box(st, Vector3.ZERO, Vector3(0.18, 0.34, 0.34), Color("#f2c418"))
		Models.box(st, Vector3(0.0, 0.0, 0.0), Vector3(0.24, 0.08, 0.5), Color("#2a2622"))
		_clamp_box = MeshInstance3D.new()
		_clamp_box.name = "Clamp"
		_clamp_box.mesh = st.commit()
		_clamp_box.material_override = Models.material()
		_clamp_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_clamp_box.position = Vector3(-0.92, 0.32, -1.15)
		car.add_child(_clamp_box)
	if _clamp_box != null:
		_clamp_box.visible = on
