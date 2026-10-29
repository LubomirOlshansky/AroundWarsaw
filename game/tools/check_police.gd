extends SceneTree
## Loop 3g-1: the police without the city (docs/design/police.md section 15, P11 and P12).
##
## P11, lines and flow: every group and tag police.gd and game/dialogue/police.dialogue use has a
## line in game/data/dialogue.json (the tagged one where it must win); every line has its Polish
## and its English; Polish speech bubbles are at most 70 characters, reply buttons 28; the
## .dialogue file compiles in Dialogue Manager with its two cues, and every `talk.say` in it names
## a group that exists.
##
## P12, the state machine: police.gd driven with synthetic inputs (a straight two-way road, a
## stand-in car, traffic and HUD; Dialogue Manager and dialogue.gd for real; no rendering), at
## 60 steps a second: the first minute gives nothing, the start grace warns but never chases;
## two strikes in 45 s start koguty 1 and a faded one doesn't; the caps end chases at 30 / 40 /
## 45 s; no level rises in a cap's last 10 s; 120 m away searches and 8 s later escapes (+15
## respect, once), 4 s in a hiding spot, and a unit within 50 m brings the chase back; stopping by
## a chaser pulls over in 1.5 s and the conversation ends in a caution in under 10 s; the
## cooldown warns but doesn't chase, and a ram chases anyway; the helicopter ends a chase. In
## every case the złoty never change (the stand-in wallet fails on any write but respect and the
## notebook) and police.gd's source never writes them; chases started = chases ended.
##
## Prints a line per case, then `check_police: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_police.gd [-- --verbose]

const Police := preload("res://scripts/police.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const DIALOGUE_JSON := "res://data/dialogue.json"
const FLOW := "res://dialogue/police.dialogue"
const SOURCES := ["res://scripts/police.gd", "res://scripts/police/police_unit.gd", "res://scripts/police/police_talk.gd",
		"res://scripts/police/police_balloon.gd", "res://scripts/police/police_tree.gd"]
const BUBBLE := 70
const REPLY := 28
const DT := 1.0 / 60.0

## Every [group, tag, prefer] police.gd and the conversation ask for (police.md section 6).
const USED := [
	["police_warn", "speed", true], ["police_warn", "red", true], ["police_warn", "bump", true],
	["police_chase", "start", true], ["police_chase", "backup", true], ["police_chase", "roadblock", true],
	["police_chase", "", false],
	["police_lost", "escaped", true], ["police_lost", "shift", true], ["police_lost", "heli", true],
	["police_stop", "routine", true], ["police_stop", "roosters", true], ["police_stop", "trap", true],
	["police_stop", "kebab", true], ["police_stop", "sloik", true], ["police_stop", "", false],
	["police_reply", "", false], ["police_reply", "trap", true], ["police_reply", "kebab", true],
	["police_caution", "police", false], ["police_caution", "fifth", true],
	["radio_host", "traps", true],
]

var problems: Array[String] = []
var verbose := false


# --- stand-ins -------------------------------------------------------------------------------

class FakeDriver extends RefCounted:
	var active := true
	var kind := 4
	var slot := 0
	var pos := Vector3.ZERO
	var yaw := 0.0
	var length := 4.7
	var size := Vector3(1.85, 1.62, 4.7)
	var parked := false
	var held := false
	var lights := false
	var chase := false
	var v_cap := 0.0
	var keep_gap := 2.4
	var goal := Vector2.INF
	var route := PackedFloat32Array()
	var finish := -1
	var arrived := false
	var edge := 0
	var lane := 0
	var s := 0.0
	var off := 0.0
	var v := 0.0
	var clip := 1.0
	var in_conn := false
	var persistent := false
	var patrol := false
	var accel_factor := 1.0
	var squeeze := 0.0
	var ghost := false
	var core_only := false


class FakeTraffic extends Node3D:
	signal police_spawned(d)
	signal police_released(d)
	signal bumped_police(d, speed: float)
	var police_target := 0
	var police_min_dist := 0.0
	var patrol_wait := 0.0
	var cars: Array = []
	var graph
	func on_screen(_p: Vector3, _h: float) -> bool:
		return true
	func add_police(e: int, lane: int, s: float, _shape := 0):
		var d := FakeDriver.new()
		d.edge = e
		d.lane = lane
		d.s = s
		d.persistent = true
		var q: Vector2 = graph.point_at(e, s, graph.lane_offset(e, lane))
		d.pos = Vector3(q.x, 0.0, q.y)
		d.off = graph.lane_offset(e, lane)
		cars.append(d)
		return d
	func add_ghost(e: int, lane: int, s: float):
		var d = add_police(e, lane, s)
		d.ghost = true
		return d
	func remove(d) -> void:
		if d.active:
			d.active = false
			cars.erase(d)
			police_released.emit(d)
	func park(d, e: int, s: float, at: Vector3, yaw: float, _block := -1) -> void:
		d.parked = true
		d.edge = e
		d.s = s
		d.pos = at
		d.yaw = yaw
	func unpark(d, e: int, lane: int, s: float) -> void:
		d.parked = false
		d.edge = e
		d.lane = lane
		d.s = s
	func set_lights(d, on: bool) -> void:
		d.lights = on
	func race_to(d, finish: int, dist: PackedFloat32Array) -> void:
		d.route = dist
		d.finish = finish
	func stop_racing(d) -> void:
		d.route = PackedFloat32Array()


class FakeMap extends Node3D:
	var hide_at := Vector2.INF
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0
	func ground_height(x: float, z: float) -> float:
		return 6.0 if hide_at != Vector2.INF and Vector2(x, z).distance_to(hide_at) < 30.0 else 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func in_tunnel(_x: float, _z: float, _y: float) -> bool:
		return false


class FakeCar extends CharacterBody3D:
	var vel := Vector3.ZERO
	var throttle := 0.0
	var steer := 0.0
	var braking := false
	var parked := false
	var target_dir := Vector3.ZERO


class FakeHud extends CanvasLayer:
	var pt := 1.0
	var toasts: Array = []
	func add_panel(c: Control, _spot: String) -> void:
		add_child(c)
	func show_panel(_c: Control, _on: bool) -> void:
		pass
	func toast(pl: String, en := "") -> void:
		toasts.append([pl, en])
	func set_koguty(_lit: int, _mode: int) -> void:
		pass
	func police_pill(_pl: String, _en: String) -> void:
		pass
	func police_fx(_b: float, _c: PackedVector2Array, _l: Vector2) -> void:
		pass
	func set_police_marks(_c: PackedVector2Array, _t: PackedVector2Array) -> void:
		pass
	func set_pedals_hidden(_on: bool) -> void:
		pass


class FakeBubbles extends Control:
	func say(_anchor: Variant, _speaker: String, _line: String, _sub := "", _s := 4.0, _a := Color.WHITE, _h := 2.6) -> void:
		pass


## The wallet: respect and the joke notebook may change; any other write is a problem.
class FakeWallet extends Node:
	signal changed(zl: int, respect: int, gained: int)
	var zl := 120
	var respect := 0
	var cautions_today := 0
	var cautions_day := 0
	var escapes_total := 0
	var forbidden := 0
	func pay(_amount: int, _gain := 0, _kind := "") -> void:
		forbidden += 1
	func add_respect(gain: int) -> void:
		respect += gain
	func add_caution(today: int) -> int:
		if cautions_day != today:
			cautions_day = today
			cautions_today = 0
		cautions_today += 1
		return cautions_today
	func cautions_on(today: int) -> int:
		return cautions_today if cautions_day == today else 0
	func add_escape() -> void:
		escapes_total += 1


class FakeRadio extends Node:
	signal station_changed(i: int, s: Dictionary)
	var station := 0
	var duck_db := 0.0
	var said: Array = []
	func announce(text: String, sub := "") -> void:
		said.append([text, sub])


class FakeSfx extends Node3D:
	func police_siren(_at: Vector3) -> void:
		pass
	func police_cue(_kind: String) -> void:
		pass


# --- the run ---------------------------------------------------------------------------------

func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	_lines()
	_flow()
	_sources()
	await _machine()
	if problems.is_empty():
		print("check_police: OK (P11 lines and flow, P12 the state machine: %d cases)" % _cases)
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_police: %d problems" % problems.size())
		quit(1)


func _lines() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_JSON))
	if not data is Dictionary:
		problems.append("dialogue.json doesn't parse")
		return
	var d := Dialogue.new()
	d.lines = {}
	for k in data:
		if not String(k).begins_with("_"):
			d.lines[k] = data[k]
	var count := 0
	for g: String in ["police_warn", "police_chase", "police_lost", "police_stop", "police_reply", "police_caution"]:
		for l: Array in d.lines.get(g, []):
			count += 1
			if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
				problems.append("P11 %s: a line without its Polish or English: %s" % [g, l])
				continue
			var limit := REPLY if g == "police_reply" else BUBBLE
			if String(l[0]).length() > limit:
				problems.append("P11 %s: %d characters (at most %d): %s" % [g, String(l[0]).length(), limit, l[0]])
	for u: Array in USED:
		var group: String = u[0]
		var tag: String = u[1]
		var all: Array = d.lines.get(group, [])
		var tagged := all.filter(func(l: Array) -> bool: return d.notes(l).get("only", null) == tag)
		var untagged := all.filter(func(l: Array) -> bool: return not d.notes(l).has("only"))
		if tag != "" and u[2] and tagged.is_empty():
			problems.append("P11 no %s line for the tag \"%s\"" % [group, tag])
		elif tag == "" and untagged.is_empty():
			problems.append("P11 no untagged %s line" % group)
	var host := (d.lines.get("radio_host", []) as Array).filter(func(l: Array) -> bool: return d.notes(l).get("only", null) == "traps")
	if not host.is_empty() and not (String(host[0][0]).contains("{pl}") and String(host[0][1]).contains("{en}")):
		problems.append("P11 the radio host's traps line lacks {pl} / {en}")
	d.free()
	print("P11 lines: %d police lines in 6 groups, %d groups and tags used" % [count, USED.size()])


func _flow() -> void:
	var text := FileAccess.get_file_as_string(FLOW)
	var result = DMCompiler.compile_string(text, "")
	if not result.errors.is_empty():
		for e in result.errors:
			problems.append("P11 police.dialogue line %d: %s" % [e.line_number + 1, DMConstants.get_error_message(e.error)])
	for cue in ["pull_over", "caution"]:
		if not result.cues.has(cue):
			problems.append("P11 police.dialogue has no cue ~ %s" % cue)
	var re := RegEx.create_from_string("talk\\.say\\(\"([a-z_]+)\"")
	var groups := {}
	for m in re.search_all(text):
		groups[m.get_string(1)] = true
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_JSON))
	for g in groups:
		if not data.has(g):
			problems.append("P11 police.dialogue says from \"%s\", which dialogue.json doesn't have" % g)
	print("P11 flow: police.dialogue compiles (%d cues), says from %s" % [result.cues.size(), ", ".join(groups.keys())])


## Nothing in the police's code writes the złoty.
func _sources() -> void:
	var re := RegEx.create_from_string("wallet\\.pay\\(|\\bzl\\s*[-+*/]?=[^=]|\\.zl\\s*[-+*/]?=[^=]")
	for path: String in SOURCES:
		var text := FileAccess.get_file_as_string(path)
		var n := 0
		for line in text.split("\n"):
			n += 1
			if not line.strip_edges().begins_with("#") and re.search(line) != null:
				problems.append("P12 %s:%d writes the wallet: %s" % [path.get_file(), n, line.strip_edges()])
	print("P12 sources: no złoty written in %d files" % SOURCES.size())


# --- the state machine -----------------------------------------------------------------------

var _cases := 0
var _world: Node3D
var p
var car: FakeCar
var traffic: FakeTraffic
var wallet: FakeWallet
var hud: FakeHud
var map: FakeMap
var _log: Array[String] = []


## A fresh police on a straight two-way road 2 km long (x 0..2000 at z 0), the car at x 500.
func _fresh(now := false) -> void:
	if _world != null:
		_world.free()
	_world = Node3D.new()
	root.add_child(_world)
	map = FakeMap.new()
	_world.add_child(map)
	var g := {"nodes": [0.0, 0.0, 2000.0, 0.0], "scc": [1, 1], "ctrl": [], "poles": [], "portals": [],
			"edges": [{"a": 0, "b": 1, "p": [0.0, 0.0, 2000.0, 0.0], "k": "primary", "n": 2, "lw": 3.25, "o": 1.6,
				"v": 13.9, "s0": 1.0, "s1": 1999.0, "name": "Testowa"},
			{"a": 1, "b": 0, "p": [2000.0, 0.0, 0.0, 0.0], "k": "primary", "n": 2, "lw": 3.25, "o": 1.6,
				"v": 13.9, "s0": 1.0, "s1": 1999.0, "name": "Testowa"}]}
	var graph := LaneGraph.new(g, map)
	traffic = FakeTraffic.new()
	traffic.graph = graph
	_world.add_child(traffic)
	car = FakeCar.new()
	_world.add_child(car)
	car.global_position = Vector3(500.0, 0.0, 6.5)
	car.rotation.y = -PI * 0.5
	hud = FakeHud.new()
	_world.add_child(hud)
	var bubbles := FakeBubbles.new()
	hud.add_child(bubbles)
	var dialogue := Dialogue.new()
	dialogue.bubbles = bubbles
	_world.add_child(dialogue)
	wallet = FakeWallet.new()
	_world.add_child(wallet)
	var radio := FakeRadio.new()
	_world.add_child(radio)
	var sfx := FakeSfx.new()
	_world.add_child(sfx)
	p = Police.new()
	p.opts = {"now": now, "traffic_level": 0, "log": false}
	_world.add_child(p)
	var nodes := {"map": map, "graph": graph, "traffic": traffic, "car": car, "hud": hud, "bubbles": bubbles,
			"dialogue": dialogue, "wallet": wallet, "radio": radio, "sfx": sfx, "opts": p.opts}
	p.setup(nodes, {}, _world)


## A patrol car at x (on the car's road, facing west, towards the car at x 500): a unit.
func _patrol(x: float):
	var d = traffic.add_police(0, 0, x)
	d.pos = Vector3(x, 0.0, 6.5)
	d.yaw = PI * 0.5
	d.persistent = false
	d.patrol = true
	traffic.police_spawned.emit(d)
	return p._unit_of.get(d)


func _steps(seconds: float, each := Callable()) -> void:
	for k in roundi(seconds / DT):
		if each.is_valid():
			each.call()
		p._step(DT)
	await process_frame


## A case: `ok` with a description, or a problem.
func _case(name: String, ok: bool, detail: String) -> void:
	_cases += 1
	if not ok:
		problems.append("P12 %s: %s" % [name, detail])
	elif verbose:
		print("  ok  %s: %s" % [name, detail])


func _machine() -> void:
	# The first minute: nothing; then the start grace: warnings, never a chase.
	_fresh()
	var u = _patrol(560.0)
	p.clock = 30.0
	p._offence("speed", u)
	_case("first minute", p.strikes == 0 and p.phase == Police.Phase.CALM, "strikes %d" % p.strikes)
	p.clock = 90.0
	p._offence("speed", u)
	u.warn_wait = 0.0
	p._offence("red", u)
	_case("start grace", p.strikes == 2 and p.phase == Police.Phase.CALM, "2 strikes at 90 s, phase %s" % Police.PHASES[p.phase])
	# Two strikes within 45 s: koguty 1; a strike fades after 45 s.
	_fresh()
	u = _patrol(560.0)
	p.clock = 200.0
	p._offence("speed", u)
	await _steps(46.0)
	u.warn_wait = 0.0
	p._offence("red", u)
	_case("strike fades", p.phase == Police.Phase.CALM and p.strikes == 1, "a second offence 46 s later: %s, strikes %d" % [Police.PHASES[p.phase], p.strikes])
	await _steps(20.0)
	u.warn_wait = 0.0
	p._offence("speed", u)
	_case("two strikes", p.phase == Police.Phase.CHASE and p.level == 1, "two within 45 s: %s L%d" % [Police.PHASES[p.phase], p.level])
	# The caps: the chaser stays 30 m behind, in sight, the car moving: end of shift at the cap.
	for lvl in [1, 2, 3]:
		_fresh(true)
		u = _patrol(470.0)
		car.vel = Vector3(4.0, 0.0, 0.0)
		p._start_chase(lvl, u, "check")
		var at := {"t0": p.clock, "ended": -1.0}
		var keep := func() -> void:
			if u.driver != null:
				u.driver.pos = car.global_position - Vector3(30.0, 0.0, 0.0)
			if at["ended"] < 0.0 and p.phase == Police.Phase.CALM:
				at["ended"] = p.clock - at["t0"]
		await _steps(50.0, keep)
		var cap: float = Police.CAPS[lvl - 1]
		var ended: float = at["ended"]
		_case("cap L%d" % lvl, ended > 0.0 and absf(ended - cap) < 0.1, "end of shift after %.2f s (cap %.0f)" % [ended, cap])
	# No level rises in the last 10 s of the cap; a ram raises once per 10 s before that.
	_fresh(true)
	u = _patrol(470.0)
	car.vel = Vector3(4.0, 0.0, 0.0)
	p._start_chase(1, u, "check")
	await _steps(5.0, func() -> void: u.driver.pos = car.global_position - Vector3(30.0, 0.0, 0.0))
	p._offence("ram", u)
	var raised: int = p.level
	p._offence("ram", u)
	_case("ram raises once in 10 s", raised == 2 and p.level == 2, "two rams at 5 s: L%d" % p.level)
	await _steps(30.0, func() -> void: u.driver.pos = car.global_position - Vector3(30.0, 0.0, 0.0))
	p._offence("ram", u)
	_case("no rise in the last 10 s", p.level == 2, "a ram at 35 s of a 40 s cap: L%d" % p.level)
	# Escape: 130 m from the chaser searches at once, escapes 8 s later (+15 respect, once).
	_fresh(true)
	u = _patrol(470.0)
	p._start_chase(1, u, "check")
	u.driver.pos = car.global_position - Vector3(130.0, 0.0, 0.0)
	await _steps(0.25)
	var searched: bool = p.phase == Police.Phase.SEARCH
	var e1 := {"t": p.clock, "esc": -1.0}
	await _steps(9.0, func() -> void:
		if u.driver != null:
			u.driver.pos = car.global_position - Vector3(130.0, 0.0, 0.0)
		if e1["esc"] < 0.0 and p.phase == Police.Phase.CALM:
			e1["esc"] = p.clock - e1["t"])
	var esc: float = e1["esc"]
	_case("escape", searched and absf(esc - Police.SEARCH) < 0.3 and wallet.respect == Police.ESCAPE_RESPECT,
			"search at 130 m, escaped %.2f s later, respect %d" % [esc, wallet.respect])
	# Out of sight for 4 s searches too; a hiding spot (under a deck) escapes after 4 s.
	_fresh(true)
	u = _patrol(470.0)
	p._start_chase(1, u, "check")
	map.hide_at = Vector2(500.0, 6.5)
	var h := {"t": p.clock, "hid": -1.0}
	await _steps(10.0, func() -> void:
		if u.driver != null:
			u.driver.pos = car.global_position - Vector3(60.0, 0.0, 0.0)
		if h["hid"] < 0.0 and p.phase == Police.Phase.CALM:
			h["hid"] = p.clock - h["t"])
	var hid: float = h["hid"]
	_case("hiding spot", absf(hid - (Police.UNSEEN + Police.SEARCH_HIDDEN)) < 0.4,
			"under a deck: escaped after %.2f s (4 s unseen + 4 s)" % hid)
	# Seen again within 50 m during the search: back to the chase.
	_fresh(true)
	u = _patrol(470.0)
	p._start_chase(1, u, "check")
	u.driver.pos = car.global_position - Vector3(130.0, 0.0, 0.0)
	await _steps(2.0)
	u.driver.pos = car.global_position - Vector3(30.0, 0.0, 0.0)
	await _steps(0.5)
	_case("seen again", p.phase == Police.Phase.CHASE, "a unit 30 m away in the search: %s" % Police.PHASES[p.phase])
	# Pulled over: stopped 12 m before a chaser for 1.5 s; the conversation ends in a caution
	# in under 10 s, then the cooldown: warnings only, but a ram chases.
	_fresh(true)
	p.now = false
	p.grace_over = true
	u = _patrol(470.0)
	p._start_chase(1, u, "check")
	car.vel = Vector3.ZERO
	u.driver.pos = car.global_position - Vector3(17.0, 0.0, 0.0)
	var pk := {"t": p.clock, "pulled": -1.0, "talked": -1.0}
	await _steps(12.0, func() -> void:
		if pk["pulled"] < 0.0 and p.phase == Police.Phase.PULLOVER:
			pk["pulled"] = p.clock - pk["t"]
		if pk["pulled"] > 0.0 and pk["talked"] < 0.0 and p.phase == Police.Phase.CALM:
			pk["talked"] = p.clock - pk["t"] - pk["pulled"])
	var pulled: float = pk["pulled"]
	var talked: float = pk["talked"]
	_case("pull-over", absf(pulled - Police.PULL_HOLD) < 0.25 and talked > 0.0 and talked < 10.0 and wallet.cautions_today == 1,
			"pulled over %.2f s after stopping, caution %.1f s later (n=%d)" % [pulled, talked, wallet.cautions_today])
	_case("cooldown", p.cooldown > 170.0, "cooldown %.0f s" % p.cooldown)
	var u2 = _patrol(560.0)
	p._offence("speed", u2)
	u2.warn_wait = 0.0
	p._offence("red", u2)
	_case("cooldown warns", p.phase == Police.Phase.CALM and p.strikes == 2, "2 strikes in the cooldown: %s" % Police.PHASES[p.phase])
	p._offence("ram", u2)
	_case("cooldown ram", p.phase == Police.Phase.CHASE, "a ram in the cooldown: %s" % Police.PHASES[p.phase])
	# The helicopter ends a chase (no bonus).
	var before: int = wallet.respect
	p.flying = true
	await _steps(0.1)
	p.flying = false
	_case("helicopter", p.phase == Police.Phase.CALM and wallet.respect == before, "took off: %s, respect %d" % [Police.PHASES[p.phase], wallet.respect])
	# Every case: the złoty untouched; every chase that started ended.
	_case("wallet", wallet.zl == 120 and wallet.forbidden == 0, "%d zł, %d forbidden writes" % [wallet.zl, wallet.forbidden])
	_case("starts = ends", p.chases_started == p.chases_ended, "%d started, %d ended" % [p.chases_started, p.chases_ended])
	_world.free()
	print("P12 state machine: %d cases" % _cases)
