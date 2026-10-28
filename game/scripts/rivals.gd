extends Node
## Named rival drivers cruising the city in their own cars, and street races
## against them. Pull up close behind a rival while both of you are moving and a
## FLASH LIGHTS button appears (key L). Flash, and the rival names a finish at a
## real place in the map, counts down 3-2-1 and races there along the shortest
## path on the lane graph, chancing some red lights. Take any route you like. The
## race shows a beacon, the edge arrow, the distance and who is in front; a card
## and a trash-talk bubble end it. A win pays the rival's stake in złoty and
## respect (wallet.gd). Only one activity at a time: no race while a rescue
## mission or a side job runs, and rescue calls wait while a race is on.
##
## All characters are made up; the jokes are about the city, not about anyone.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Models := preload("res://scripts/models.gd")
const Beacon := preload("res://scripts/beacon.gd")

const CHALLENGE_RANGE := 15.0
const FINISH_RADIUS := 16.0
const RACE_COLOUR := Color("#ff4fd8")
const WIN_COLOUR := Color("#56d68a")
const LOSE_COLOUR := Color("#e2574c")

## Each rival: name, tag colour, car style (models.gd), box size, and lines as
## [Polish, English]. Challenges carry the finish: {pl} / {en}.
const RIVALS := [
	{"name": "Seba z Pragi", "colour": Color("#b45cff"), "style": 0, "size": Vector3(1.9, 1.3, 4.4), "stake": 150,
		"about": "lowered purple coupe, tracksuit, Praga born and bred",
		"approach": ["Co tak siedzisz mi na zderzaku? Mrugnij, jak masz odwagę.", "Why are you on my bumper? Flash your lights if you dare."],
		"challenge": [["Ej, kierowniku, ścigamy się {pl}?", "Hey boss, race you {en}?"],
			["Mordo, {pl}. Kto ostatni, ten stawia kebaba.", "Buddy, {en}. Last one there buys the kebab."]],
		"win": [["Na Pradze się tak jeździ, mordo!", "That's how we drive in Praga, buddy!"],
			["Spoko, następnym razem dam ci fory. Może.", "Chill, next time I'll give you a head start. Maybe."]],
		"lose": [["Ej no, gołąb mi wleciał na maskę!", "Come on, a pigeon landed on my bonnet!"],
			["Szacun. Ale po naszej stronie Wisły byś mnie nie dogonił.", "Respect. But on our side of the Vistula you'd never catch me."]]},
	{"name": "Mordor Mike", "colour": Color("#9fc2e8"), "style": 1, "size": Vector3(1.9, 1.9, 4.7), "stake": 300,
		"about": "office guy from Mordor on Domaniewska, races like it's a deadline",
		"approach": ["Sorry, mam call. Ale jak mrugniesz, to wchodzę w to.", "Sorry, I'm on a call. But flash me and I'm in."],
		"challenge": [["Szybki sprint {pl}? Mam okienko między spotkaniami.", "Quick sprint {en}? I've got a gap between meetings."],
			["Zróbmy z tego deliverable: {pl}, ASAP.", "Let's make it a deliverable: {en}, ASAP."]],
		"win": [["Target dowieziony. Wpisuję to sobie do OKR-ów.", "Target delivered. That goes in my OKRs."],
			["Wyślę ci podsumowanie mailem. Szef w kopii.", "I'll email you a summary. My boss in CC."]],
		"lose": [["Na Domaniewskiej nauczyłem się stać w korku, nie jeździć.", "Domaniewska taught me to sit in traffic, not to drive."],
			["Okej, wrzucam to na retro. Lesson learned.", "Okay, that goes in the retro. Lesson learned."]]},
	{"name": "Pani Halina", "colour": Color("#86d3b0"), "style": 2, "size": Vector3(1.6, 1.9, 3.4), "stake": 60,
		"about": "a pensioner who drives far too fast, late for the bazaar",
		"approach": ["Synku, nie siedź mi tak na ogonie, babcia się spieszy!", "Sonny, don't tailgate me, Granny's in a hurry!"],
		"challenge": [["Spieszę się {pl}. Dogonisz babcię?", "I'm in a hurry {en}. Can you catch Granny?"],
			["Promocja na ogórki się kończy! Jedziemy {pl}!", "The pickle sale is ending! We're going {en}!"]],
		"win": [["W moich czasach to się jeździło, a nie wlokło!", "In my day we drove, we didn't crawl!"],
			["Zjedz coś, synku, bo blady jesteś i wolny.", "Eat something, sonny, you're pale and slow."]],
		"lose": [["Ech, to przez te nowe progi zwalniające.", "Oh, it's those new speed bumps."],
			["Dobry chłopak. Masz tu pierogi na drogę.", "Good boy. Here, have some pierogi for the road."]]},
	{"name": "Słoik z Radomia", "colour": Color("#ffb05a"), "style": 3, "size": Vector3(2.0, 3.0, 5.2), "stake": 90,
		"about": "a newcomer from Radom with his mum's jars in the van",
		"approach": ["Przepraszam, którędy na Rondo Dmowskiego? Kręcę się od rana.", "Sorry, which way to Rondo Dmowskiego? I've been going round since morning."],
		"challenge": [["W Radomiu nikt by się nie ścigał. Ale dobra: {pl}!", "Nobody races back in Radom. But fine: {en}!"],
			["Mam w bagażniku słoiki od mamy. Ostrożnie, ale szybko: {pl}!", "Mum's jars are in the back. Carefully, but fast: {en}!"]],
		"win": [["Słoik też potrafi! Mama będzie dumna.", "A słoik can do it too! Mum will be proud."],
			["Warszawka myśli, że zna skróty. A ja mam nawigację i bigos.", "You Warsaw lot think you know the shortcuts. I've got a satnav and bigos."]],
		"lose": [["Zgubiłem się na Rondzie Dmowskiego. Trzy razy.", "I got lost on Rondo Dmowskiego. Three times."],
			["Dobra, wracam na weekend do Radomia odpocząć.", "Fine, I'm off to Radom for the weekend to recover."]]},
	{"name": "Taksiarz Zbyszek", "colour": Color("#f3c72b"), "style": 4, "size": Vector3(1.9, 1.9, 4.8), "stake": 200,
		"about": "a taxi driver since 1987 who knows every shortcut",
		"approach": ["Kurs, szefie? Bo jak nie, to ja nie trąbię, tylko jadę.", "Need a ride, chief? If not, I don't honk, I drive."],
		"challenge": [["Kurs {pl}? Na liczniku czy na wyścigi?", "A fare {en}? On the meter, or racing?"],
			["Znam każdy skrót od osiemdziesiątego siódmego. Jedziemy {pl}!", "I've known every shortcut since '87. Let's go {en}!"]],
		"win": [["Należy się: zero złotych i lekcja jazdy.", "That'll be zero złoty and a driving lesson."],
			["Marszałkowską znowu rozkopali, a ja i tak pierwszy.", "They've dug up Marszałkowska again, and I'm still first."]],
		"lose": [["Pierwszy raz od lat ktoś mnie przegonił. Szacunek.", "First time in years someone beat me. Respect."],
			["Gdyby nie korek na Moście Poniatowskiego, byłoby inaczej.", "If not for the jam on Poniatowski Bridge, it'd be a different story."]]},
	{"name": "Bulwar Bartek", "colour": Color("#7cff3a"), "style": 5, "size": Vector3(1.8, 1.9, 3.9), "stake": 120,
		"about": "a party guy from the Vistula boulevards with a speaker on the roof",
		"approach": ["Słyszysz ten bas? Mrugnij, to podkręcę.", "Hear that bass? Flash me and I'll turn it up."],
		"challenge": [["Impreza na bulwarach się zaczyna! Ścigamy się {pl}?", "The party on the boulevards is starting! Race you {en}?"],
			["Najlepszy widok na Warszawę jest z Pałacu, bo nie widać Pałacu. Jedziemy {pl}!", "The best view of Warsaw is from the Palace, because you can't see the Palace. Let's go {en}!"]],
		"win": [["Bas siedzi, wynik siedzi!", "The bass hits, and so does the result!"],
			["Wygrałem, a gołębie z Placu Defilad biły brawo.", "I won, and the pigeons on Plac Defilad applauded."]],
		"lose": [["Muzyka była za głośno, nie słyszałem startu.", "The music was too loud, I didn't hear the start."],
			["Dobra, dobra. Rewanż nad Wisłą, o wschodzie słońca.", "Fine, fine. Rematch by the Vistula, at sunrise."]]},
]

## Race finishes at real places. `find`: a landmark outline, a road name (the
## middle of its nodes), a road's east end, or a point of interest.
const FINISHES := [
	{"name": "Pałac Kultury i Nauki", "pl": "do Pałacu", "en": "to the Palace", "landmark": "Pałac Kultury i Nauki"},
	{"name": "Rondo Dmowskiego", "pl": "na Rondo Dmowskiego", "en": "to Rondo Dmowskiego", "road": "Rondo Romana Dmowskiego"},
	{"name": "Stadion Narodowy", "pl": "pod Narodowy", "en": "to the National Stadium", "poi": "stadium"},
	{"name": "Most Poniatowskiego, east end", "pl": "na koniec Mostu Poniatowskiego", "en": "to the far end of Poniatowski Bridge", "road_east": "Most Księcia Józefa Poniatowskiego"},
	{"name": "Rondo de Gaulle'a (the Palm)", "pl": "pod Palmę", "en": "to the Palm", "road": "Rondo Generała Charles'a de Gaulle'a"},
	{"name": "Plac Trzech Krzyży", "pl": "na Plac Trzech Krzyży", "en": "to Plac Trzech Krzyży", "road": "Plac Trzech Krzyży"},
	{"name": "Centrum Nauki Kopernik", "pl": "pod Kopernika", "en": "to the Copernicus Science Centre", "landmark": "Centrum Nauki Kopernik"},
	{"name": "Złote Tarasy", "pl": "pod Złote Tarasy", "en": "to Złote Tarasy", "landmark": "Złote Tarasy"},
	{"name": "Rondo ONZ", "pl": "na Rondo ONZ", "en": "to Rondo ONZ", "road": "Rondo ONZ"},
	{"name": "Varso Tower", "pl": "pod Varso", "en": "to Varso Tower", "landmark": "Varso Tower"},
	{"name": "Dworzec Powiśle", "pl": "pod Dworzec Powiśle", "en": "to Powiśle station", "landmark": "Dworzec PKP Powiśle"},
]

enum State { CRUISE, PROMPT, CHALLENGE, COUNTDOWN, RACE, RESULT }

var graph: LaneGraph
var traffic: Traffic
var hud: CanvasLayer
var bubbles: Control
var missions: Node
var map: Node3D
var car: CharacterBody3D
var state := State.CRUISE
## Rival in the current prompt or race.
var rival := -1
## The wallet (złoty and respect, saved); a win pays the stake and +100 respect.
var wallet: Node
## The side jobs (jobs.gd): no challenges while one runs.
var jobs: Node
## Testing (--autopilot): the player's car follows a ghost driver in races, and
## tails `tail` (a rival index) before one.
var autopilot := false
var tail := -1
## Set by the game each frame.
var flying := false

var _drivers: Array = []
var _nodes: Array[Node3D] = []
var _cooldown := PackedFloat32Array()
var _said := PackedFloat32Array()
var _finishes: Array[Dictionary] = []
var _finish: Dictionary = {}
var _dist := PackedFloat32Array()
## Finish node -> driving distances to it from every node (computed once each).
var _dist_to := {}
var _t := 0.0
var _race_time := 0.0
var _races := 0
var _lost_sight := 0.0
var _player_left := 0.0
var _rival_left := 0.0
var _rank_timer := 0.0
var _beacon: Node3D
var _ghost = null
var _rng := RandomNumberGenerator.new()


func setup(lane_graph: LaneGraph, traffic_node: Traffic, hud_layer: CanvasLayer, bubble_layer: Control,
		mission_node: Node, map_node: Node3D, world: Node3D, player_car: CharacterBody3D, data: Dictionary) -> void:
	graph = lane_graph
	traffic = traffic_node
	hud = hud_layer
	bubbles = bubble_layer
	missions = mission_node
	map = map_node
	car = player_car
	_rng.seed = 7
	_find_finishes(data)
	_beacon = Beacon.new()
	world.add_child(_beacon)
	_beacon.setup(RACE_COLOUR, Color("#2b2c2f"))
	_beacon.waving = true
	_cooldown.resize(RIVALS.size())
	_said.resize(RIVALS.size())
	_said.fill(-100.0)
	var spawn := Vector2(car.global_position.x, car.global_position.z)
	var taken := PackedVector2Array([spawn])
	for i in RIVALS.size():
		var r: Dictionary = RIVALS[i]
		var node := Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = Models.rival_mesh(r["style"])
		mi.material_override = Models.material()
		node.add_child(mi)
		if r["style"] == 0:
			# Seba's neon underglow.
			var glow := MeshInstance3D.new()
			var slab := BoxMesh.new()
			slab.size = Vector3(2.1, 0.05, 4.5)
			glow.mesh = slab
			var neon := StandardMaterial3D.new()
			neon.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			neon.albedo_color = Color("#38f6ff")
			glow.material_override = neon
			glow.position.y = 0.09
			glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(glow)
			# At night it spills onto the road.
			var spill := MeshInstance3D.new()
			spill.mesh = _underglow_pool()
			spill.material_override = Models.glow_material()
			spill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spill.visible = false
			spill.add_to_group("night_lights")
			node.add_child(spill)
		# Headlights and tail lights on the road at night.
		var beams := MeshInstance3D.new()
		beams.mesh = Models.headlight_pools((r["size"] as Vector3).z * 0.5)
		beams.material_override = Models.glow_material()
		beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beams.visible = false
		beams.add_to_group("night_lights")
		node.add_child(beams)
		world.add_child(node)
		_nodes.append(node)
		# The first rival cruises near the start so the race is easy to find.
		var spot := _spot(spawn, 140.0, 320.0) if i == 0 else _spot_apart(taken)
		taken.append(graph.point_at(spot[0], spot[2]))
		var d = traffic.add_node_driver(node, r["size"], spot[0], spot[1], spot[2])
		_drivers.append(d)
	hud.challenge_pressed.connect(flash)
	hud.card_pressed.connect(_on_card)
	hud.abort_pressed.connect(func():
		if state == State.RACE or state == State.COUNTDOWN:
			_finish_race(false, "You gave up."))
	traffic.bumped_driver.connect(_on_bumped)


## Seba's underglow on the road: a cyan oval round the car.
func _underglow_pool() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for k in n:
		var a0 := TAU * k / n
		var a1 := TAU * (k + 1) / n
		for v in [[Vector3(0, 0.1, 0), 0.5], [Vector3(cos(a0) * 2.4, 0.1, sin(a0) * 3.6), 0.0], [Vector3(cos(a1) * 2.4, 0.1, sin(a1) * 3.6), 0.0]]:
			st.set_color(Color(0.1, 0.85, 1.0, v[1]))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	return st.commit()


## A lane on a main road between `lo` and `hi` metres from p: [edge, lane, s].
func _spot(p: Vector2, lo: float, hi: float) -> Array:
	for attempt in 400:
		var e := _rng.randi() % graph.e_a.size()
		if graph.e_class[e] > 1 or graph.node_scc[graph.e_a[e]] == 0 or graph.node_scc[graph.e_b[e]] == 0:
			continue
		if graph.e_s1[e] - graph.e_s0[e] < 20.0:
			continue
		var s := _rng.randf_range(graph.e_s0[e] + 5.0, graph.e_s1[e] - 5.0)
		var d := graph.point_at(e, s).distance_to(p)
		if d >= lo and d <= hi:
			return [e, _rng.randi() % graph.e_lanes[e], s]
	return _spot(p, 0.0, 1e9)


func _spot_apart(taken: PackedVector2Array) -> Array:
	var best: Array = []
	var best_d := -1.0
	for attempt in 30:
		var cand := _spot(Vector2.ZERO, 0.0, 1e9)
		var near := INF
		for q in taken:
			near = minf(near, graph.point_at(cand[0], cand[2]).distance_to(q))
		if near > best_d:
			best_d = near
			best = cand
	return best


func _find_finishes(data: Dictionary) -> void:
	for f in FINISHES:
		var target := Vector2.INF
		var node := -1
		if f.has("landmark"):
			var sum := Vector2.ZERO
			var n := 0
			for l in data.get("landmarks", []):
				if l["name"] == f["landmark"]:
					var flat: Array = l["p"]
					for k in range(0, flat.size() - 1, 2):
						sum += Vector2(flat[k], flat[k + 1])
						n += 1
			if n > 0:
				target = sum / n
		elif f.has("poi"):
			for p in data.get("pois", []):
				if p["k"] == f["poi"]:
					target = Vector2(p["x"], p["z"])
		else:
			var key: String = f.get("road", f.get("road_east", ""))
			var sum := Vector2.ZERO
			var n := 0
			var east := -INF
			for e in graph.e_a.size():
				if graph.e_name[e] != key:
					continue
				for m in [graph.e_a[e], graph.e_b[e]]:
					if graph.node_scc[m] == 0:
						continue
					sum += graph.node_pos[m]
					n += 1
					if f.has("road_east") and graph.node_pos[m].x > east:
						east = graph.node_pos[m].x
						node = m
			if n > 0 and not f.has("road_east"):
				target = sum / n
		if node < 0 and target != Vector2.INF:
			node = graph.nearest_node(target)
		if node < 0:
			continue
		var p := graph.node_pos[node]
		var entry: Dictionary = f.duplicate()
		entry["node"] = node
		entry["pos"] = Vector3(p.x, map.ground_height(p.x, p.y), p.y)
		_finishes.append(entry)


# --- the flow ------------------------------------------------------------------------

func racing() -> bool:
	return state == State.CHALLENGE or state == State.COUNTDOWN or state == State.RACE


## A race or its result card is up (other activities wait).
func busy() -> bool:
	return state != State.CRUISE and state != State.PROMPT


func has_target() -> bool:
	return state == State.COUNTDOWN or state == State.RACE


func target_position() -> Vector3:
	return _finish["pos"]


func target_colour() -> Color:
	return RACE_COLOUR


## The L key / FLASH LIGHTS button: challenge the rival in front.
func flash() -> void:
	if state != State.PROMPT:
		return
	car.flash_lights()
	start_race(rival)


## Challenges rival i at once (also the --race flag): they name a finish, count
## down and go.
func start_race(i: int) -> void:
	rival = i
	var d = _drivers[i]
	var t0 := Time.get_ticks_usec()
	_finish = _pick_finish(d)
	_dist = _distances(_finish["node"])
	print("race: %s to %s, %d m by road (picked in %.1f ms)" % [RIVALS[i]["name"], _finish["name"],
			roundi(graph.remaining(_dist, d.edge, d.s)), (Time.get_ticks_usec() - t0) / 1000.0])
	_races += 1
	state = State.CHALLENGE
	_t = 0.0
	hud.hide_challenge()
	missions.close()
	missions.paused = true
	hud.hide_pill()
	hud.hide_card()
	d.held = true
	var r: Dictionary = RIVALS[i]
	var line: Array = r["challenge"][_rng.randi() % 2]
	_say(i, String(line[0]).format(_finish), String(line[1]).format(_finish), 3.0)
	hud.show_banner("RACE " + String(_finish["en"]).to_upper(), RACE_COLOUR)


## A finish 600-1800 m away by road (one-way streets can make a near place a long
## drive) and not right next door; failing that, the one nearest to 1.2 km.
func _pick_finish(d) -> Dictionary:
	var from := Vector2(d.pos.x, d.pos.z)
	var fits: Array[Dictionary] = []
	var nearest: Dictionary = _finishes[0]
	var nearest_off := INF
	for f in _finishes:
		var route := graph.remaining(_distances(f["node"]), d.edge, d.s)
		var far := Vector2(f["pos"].x, f["pos"].z).distance_to(from)
		if route >= 600.0 and route <= 1800.0 and far >= 350.0:
			fits.append(f)
		if absf(route - 1200.0) < nearest_off:
			nearest_off = absf(route - 1200.0)
			nearest = f
	if fits.is_empty():
		return nearest
	return fits[(_races * 7 + rival * 3) % fits.size()]


func _distances(node: int) -> PackedFloat32Array:
	if not _dist_to.has(node):
		_dist_to[node] = graph.distances_to(node)
	return _dist_to[node]


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	if graph == null:
		return
	_t += dt
	for i in _cooldown.size():
		_cooldown[i] = maxf(0.0, _cooldown[i] - dt)
	_update_tags()
	match state:
		State.CRUISE:
			_look_for_challenge()
		State.PROMPT:
			if not _can_challenge(rival):
				_lost_sight += dt
				if _lost_sight > 1.2:
					state = State.CRUISE
					hud.hide_challenge()
			else:
				_lost_sight = 0.0
		State.CHALLENGE:
			if _t > 2.6:
				state = State.COUNTDOWN
				_t = 0.0
				_beacon.place(_finish["pos"], FINISH_RADIUS - 4.0)
				if autopilot:
					_start_ghost()
		State.COUNTDOWN:
			var n := 3 - int(_t)
			hud.show_banner(str(n) if n > 0 else "GO!", Color.WHITE if n > 0 else WIN_COLOUR)
			_show_status()
			if _t >= 3.0:
				_go()
		State.RACE:
			_race_time += dt
			if _t > 1.0:
				hud.hide_banner()
			_track(dt)


func _look_for_challenge() -> void:
	if flying or missions.has_target() or (jobs != null and jobs.busy()):
		return
	for i in _drivers.size():
		if _cooldown[i] <= 0.0 and _can_challenge(i):
			rival = i
			state = State.PROMPT
			_lost_sight = 0.0
			var r: Dictionary = RIVALS[i]
			hud.show_challenge("FLASH LIGHTS · RACE %s  (L)" % r["name"].to_upper(), r["colour"])
			if _t - _said[i] > 40.0:
				_say(i, r["approach"][0], r["approach"][1], 3.5)
			return


## Close behind the rival (within 15 m, roughly in its lane), both moving.
func _can_challenge(i: int) -> bool:
	if flying or missions.has_target() or (jobs != null and jobs.busy()):
		return false
	var d = _drivers[i]
	var rel := Vector2(d.pos.x - car.global_position.x, d.pos.z - car.global_position.z)
	if rel.length() > CHALLENGE_RANGE or car.vel.length() < 2.0 or d.v < 1.0:
		return false
	var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
	return rel.dot(fwd) > 0.0 and absf(rel.cross(fwd)) < 4.0


func _go() -> void:
	state = State.RACE
	_t = 0.0
	_race_time = 0.0
	_rank_timer = 0.0
	var d = _drivers[rival]
	d.held = false
	d.speed_factor = 1.45
	d.accel_factor = 1.7
	traffic.race_to(d, _finish["node"], _dist)
	if _ghost != null:
		_ghost.held = false
	Input.vibrate_handheld(80, 0.7)


## Who is in front and the race status; the finish decides it.
func _track(dt: float) -> void:
	var d = _drivers[rival]
	var at := car.global_position
	var to_finish := Vector2(at.x, at.z).distance_to(Vector2(_finish["pos"].x, _finish["pos"].z))
	if to_finish < FINISH_RADIUS and not flying:
		_finish_race(true, "")
		return
	if d.arrived:
		_finish_race(false, "")
		return
	_rank_timer -= dt
	if _rank_timer <= 0.0:
		_rank_timer = 0.2
		_rival_left = traffic.remaining(d)
		_player_left = _player_remaining()
	_show_status()


## The player's driving distance to the finish: from the nearest lane (either
## direction of the road), or the straight line if the car is off the roads.
func _player_remaining() -> float:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var hit := graph.snap(p, 25.0)
	if hit.is_empty():
		return p.distance_to(Vector2(_finish["pos"].x, _finish["pos"].z)) * 1.3
	var e: int = hit[0]
	var s: float = hit[2]
	var best := graph.remaining(_dist, e, s)
	var rev := graph.e_reverse[e]
	if rev >= 0:
		best = minf(best, graph.remaining(_dist, rev, graph.e_len[e] - s) + 25.0)
	return best


func _show_status() -> void:
	var r: Dictionary = RIVALS[rival]
	var first := _player_left <= _rival_left
	var gap := absf(_rival_left - _player_left)
	var at := car.global_position
	var metres := roundi(Vector2(at.x, at.z).distance_to(Vector2(_finish["pos"].x, _finish["pos"].z)))
	var hint := "Get ready…"
	if state == State.RACE:
		hint = "%s is %d m %s" % [r["name"], roundi(gap), "behind" if first else "ahead"]
	hud.show_status("RACE vs %s → %s" % [r["name"], _finish["name"]], _clock(_race_time), "%d m" % metres,
			hint, 0.0, RACE_COLOUR, ("1ST" if first else "2ND") if state == State.RACE else "")


func _finish_race(won: bool, why: String) -> void:
	state = State.RESULT
	hud.hide_banner()
	hud.hide_status()
	_beacon.visible = false
	var d = _drivers[rival]
	traffic.stop_racing(d)
	d.held = false
	d.speed_factor = 1.08
	d.accel_factor = 1.3
	_cooldown[rival] = 25.0
	if _ghost != null:
		traffic.remove(_ghost)
		_ghost = null
	var r: Dictionary = RIVALS[rival]
	# The rival talks back: a grudging line when they lose, a gloat when they win.
	var line: Array = r["lose" if won else "win"][_rng.randi() % 2]
	_say(rival, line[0], line[1], 5.0)
	var who: String = r["name"]
	print("race %s: %s to %s in %.1f s" % ["won" if won else "lost", who, _finish["name"], _race_time])
	if won:
		var stake: int = r["stake"]
		var record := ""
		if wallet != null:
			var key := "race:%s" % _finish["name"]
			var best: float = wallet.best_time(key)
			if wallet.record(key, _race_time):
				record = " · new best!" if best > 0.0 else ""
			else:
				record = " · best %s" % _clock(best)
			wallet.pay(stake, 100, "race")
		var total := ("\nWallet %s · respect %d" % [_money(wallet.zl), wallet.respect]) if wallet != null else ""
		hud.show_card("WIN · 1ST", "You beat %s to %s in %s%s.\n„%s”\n%s\n+%d zł (the stake) · respect +100%s" % [
				who, _finish["name"], _clock(_race_time), record, line[0], line[1], stake, total],
				PackedStringArray(["OK"]), WIN_COLOUR)
		Input.vibrate_handheld(150, 0.9)
	else:
		var short := roundi(_player_remaining())
		var reason := why if why != "" else "%s got to %s first. You were %d m short after %s." % [who, _finish["name"], short, _clock(_race_time)]
		hud.show_card("LOSE · 2ND", "%s\n„%s”\n%s" % [reason, line[0], line[1]],
				PackedStringArray(["OK"]), LOSE_COLOUR)


func _on_card(_index: int) -> void:
	if state != State.RESULT:
		return
	state = State.CRUISE
	hud.hide_card()
	missions.paused = false
	missions.close()


## Bumped mid-race (or just bumped): the rival complains.
func _on_bumped(d) -> void:
	var i := _drivers.find(d)
	if i < 0 or bubbles.is_talking(_nodes[i]):
		return
	_say(i, "Ej! Uważaj na lakier!", "Hey! Mind the paint!", 2.0)


func _say(i: int, pl: String, en: String, seconds: float) -> void:
	var r: Dictionary = RIVALS[i]
	bubbles.say(_nodes[i], r["name"], pl, en, seconds, r["colour"], float(r["size"].y) + 1.0)
	_said[i] = _t


## Name tags over rivals near the player, and their dots on the minimap.
func _update_tags() -> void:
	var p := car.global_position
	var dots := PackedVector2Array()
	var colours := PackedColorArray()
	for i in _drivers.size():
		var d = _drivers[i]
		var r: Dictionary = RIVALS[i]
		var near: bool = d.pos.distance_to(p) < 90.0 or (i == rival and state != State.CRUISE)
		if near:
			bubbles.tag(_nodes[i], r["name"], r["colour"], float(r["size"].y) + 0.9)
		else:
			bubbles.untag(_nodes[i])
		dots.append(Vector2(d.pos.x, d.pos.z))
		colours.append(r["colour"])
	hud.set_minimap_dots(dots, colours)


# --- testing aids ------------------------------------------------------------------

## --rival=n: puts rival i just ahead of the player's car on its lane.
## Returns false if no lane is near the car.
func put_ahead(i: int, gap := 14.0) -> bool:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		hit = graph.snap(p, 120.0, Vector2.ZERO, true)
	if hit.is_empty():
		return false
	var e: int = hit[0]
	var lane: int = hit[1]
	var s := clampf(hit[2], graph.e_s0[e] + 2.0, maxf(graph.e_s1[e] - gap - 6.0, graph.e_s0[e] + 2.0))
	traffic.teleport(_drivers[i], e, lane, s + gap)
	var q := graph.point_at(e, s, graph.lane_offset(e, lane))
	var dir := graph.direction(e, s)
	car.global_position = Vector3(q.x, graph.height(e, s), q.y)
	car.rotation.y = atan2(-dir.x, -dir.y)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	return true


## The autopilot drives the player's car (returns true while it does): along the
## race route on a ghost driver, or 9 m behind the rival it is told to tail.
func drive_player() -> bool:
	if _ghost != null and (state == State.COUNTDOWN or state == State.RACE):
		_follow(_ghost.pos, _ghost.yaw, _ghost.v)
		return true
	if tail >= 0 and (state == State.CRUISE or state == State.PROMPT):
		var d = _drivers[tail]
		var fwd := Vector3(-sin(d.yaw), 0.0, -cos(d.yaw))
		_follow(d.pos - fwd * 9.0, d.yaw, maxf(d.v, 3.0))
		return true
	return false


func _start_ghost() -> void:
	var p := Vector2(car.global_position.x, car.global_position.z)
	var heading := Vector2(-sin(car.rotation.y), -cos(car.rotation.y))
	var hit := graph.snap(p, 40.0, heading, true)
	if hit.is_empty():
		return
	_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	_ghost.held = true
	_ghost.speed_factor = 1.8
	_ghost.accel_factor = 2.2
	traffic.race_to(_ghost, _finish["node"], _dist)


func _follow(at: Vector3, yaw: float, speed: float) -> void:
	car.collision_mask = 0
	car.global_position = at
	car.rotation.y = yaw
	car.vel = Vector3(-sin(yaw), 0.0, -cos(yaw)) * speed
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return digits + out + " zł"


static func _clock(seconds: float) -> String:
	var tenths := maxi(0, int(seconds * 10.0))
	return "%d:%02d.%d" % [tenths / 600, (tenths / 10) % 60, tenths % 10]
