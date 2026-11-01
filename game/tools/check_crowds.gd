extends SceneTree
## Loop MW-3 (docs/design/vision.md 3.1-3.3, 4.5): the night and the river's crowds
## (scripts/crowds.gd), headless, from the committed map data (map/centrum.json, like
## check_places and check_city_sounds) and data/places.json; seeded, no clock of its own:
##   1. the city clock: the Dawn look (Świt) and --clock= on the fixed looks' "always Friday";
##   2. the queue formula (max_len × hour curve × weekday) on synthetic clocks and weekdays,
##      Lusterko's Sunday morning, --crowd=2 and the Low tier's half, the caps;
##   3. the steps curve (hour × month × rain, the sunset's 1.0), the guitarist, Plac Zbawiciela's
##      summer Fri/Sat crowd, the police's hours, the dawn crowd's window and count (20-40);
##   4. the sites at their places (five queues on a footway within 40 m, the steps, Plan C);
##   5. the door: a rejection every 30-60 s while a queue of 4+ is on screen (none off screen or
##      with a short queue; each a `club_door` reject line); the car at the door's `car` line once
##      a club a night, never fast or flying (the garage loop: painted black, `car_black` instead,
##      and no egg asked at Smoła's door);
##   6. the dawn crowd's routes over the real footways (A*), and on a synthetic grid; its walkers
##      (30 at 05:45 in the Dawn look, none on a Live Wednesday, none at 09:00) on their routes;
##   7. the levels the eggs read, and the eggs E03 E04 E10 E14 E15 firing on synthetic inputs
##      only with their crowd (E15 on its third different day), each reward once;
##   8. the tick's cost;
##   9. F's asks (2026-10-30): Level 26 stands on the tower (its place inside a building part of
##      100 m or more in the map data), its door queue on a footway, the roof ring on a synthetic
##      tower (every ray on the facade or at most a cell outside it, one height).
## Prints "check_crowds: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_crowds.gd [-- --verbose]

const Crowds := preload("res://scripts/crowds.gd")
const Notebook := preload("res://scripts/notebook.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Wallet := preload("res://scripts/wallet.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")


## A stand-in for dialogue.gd: records each line asked for.
class FakeDialogue extends Node:
	var said: Array = []

	func say(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false) -> Array:
		said.append([speaker, group, tag])
		return ["…", "…"]

	func count(group: String, tag: String) -> int:
		var n := 0
		for l: Array in said:
			n += int(l[1] == group and l[2] == tag)
		return n


var problems: Array[String] = []
var verbose := false
## The synthetic world the crowds see.
var now := {"hour": 1.0, "weekday": 6}
var cal := {"live": false, "month": 7, "date": 0, "look": "Night", "rain": false, "sunset": 19.5}
var eye := Vector3.ZERO
var veh: Array = [Vector3.INF, 0.0, false]
var seen := true


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	_check_clock()
	_check_rules()
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		path = "res://map/index.json"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not data is Dictionary or not book.setup(data):
		print("check_crowds: PROBLEM (no map data or places.json)")
		quit(1)
		return
	var dlg := FakeDialogue.new()
	root.add_child(dlg)
	var c: Crowds = _make(book.places, data, dlg, 1.0)
	_check_sites(c)
	_check_level26(c, book, data)
	_check_door(c, dlg)
	var cost := _check_dawn(c, data)
	_check_grid_routes()
	_check_eggs(c, book)
	var n_sites := c.sites.size()
	c.queue_free()
	book.queue_free()
	dlg.queue_free()
	await process_frame
	if problems.is_empty():
		print("check_crowds: OK (clock and Dawn, queues on synthetic clocks, steps, Plan C, police, dawn window; %d sites; door %d rejections in 300 s; dawn routes %d; walkers 30; eggs E03 E04 E10 E14 E15; tick %.1f µs)" % [
				n_sites, _rejections, _routes, cost])
		quit(0)
	else:
		for p in problems:
			print("  problem: ", p)
		print("check_crowds: %d problems" % problems.size())
		quit(1)


var _rejections := 0
var _routes := 0


func _make(places: Array, data: Dictionary, dlg: Node, amount: float) -> Crowds:
	var c := Crowds.new()
	c.amount = amount
	c.dialogue = dlg
	c.clock = func() -> Dictionary: return now
	c.calendar = func() -> Dictionary: return cal
	c.focus = func() -> Vector3: return eye
	c.vehicle = func() -> Array: return veh
	c.on_screen = func(_p: Vector3, _h: float) -> bool: return seen
	c.log_on = verbose
	root.add_child(c)
	c.set_process(false)
	c.setup(places, data)
	return c


# 1. -------------------------------------------------------------------------------------------

func _check_clock() -> void:
	_expect(TimeOfDay.NAMES.size() == 5 and TimeOfDay.NAMES[TimeOfDay.DAWN] == "Dawn", "the looks: %s (want Dawn after Live)" % [TimeOfDay.NAMES])
	_expect(TimeOfDay.parse("dawn") == TimeOfDay.DAWN, "--time=dawn parses to %d" % TimeOfDay.parse("dawn"))
	for row: Array in [["Dawn", -1.0, 5.75, 6], ["Night", 1.0, 1.0, 6], ["Night", 23.0, 23.0, 5], ["Day", 13.0, 13.0, 5],
			["Night", -1.0, 1.5, 6], ["Dusk", -1.0, 19.5, 5]]:
		var lc := TimeOfDay.look_clock(row[0], 0.0, row[1])
		_expect(absf(float(lc["hour"]) - float(row[2])) < 0.001 and int(lc["weekday"]) == int(row[3]),
				"%s --clock %s: %s (want %s, day %d)" % [row[0], row[1], lc, row[2], row[3]])
	var later := TimeOfDay.look_clock("Night", 0.5, 1.0)
	_expect(absf(float(later["hour"]) - 1.5) < 0.001, "the clock runs on: %s" % later)


# 2-3. -----------------------------------------------------------------------------------------

func _check_rules() -> void:
	# [max, curve, hour, weekday (calendar), want]
	var rows: Array = [
		[24, "club", 1.0, 6, 24],    # Smoła, Friday's night at 01:00
		[24, "club", 0.0, 6, 14],    # 00:00: 0.6
		[24, "club", 22.0, 5, 2],    # Friday 22:00: 0.1
		[24, "club", 6.0, 6, 0],     # 06:00: closed
		[24, "club", 1.0, 1, 7],     # Monday 01:00 = Sunday's night: 0.3
		[24, "club", 1.0, 3, 5],     # Wednesday 01:00 = Tuesday's night: 0.2
		[24, "club", 1.0, 5, 14],    # Friday 01:00 = Thursday's night: 0.6
		[16, "club", 23.0, 5, 5],    # Jasna 0 at 23:00 on Friday: 0.3
		[24, "after", 1.0, 6, 10],   # Lusterko 01:00: 0.4
		[24, "after", 4.0, 6, 24],   # Lusterko 04:00: 1.0
		[24, "after", 7.0, 7, 19],   # Lusterko Sunday 07:00: 0.8 × 1.0
		[24, "after", 10.0, 7, 12],  # Lusterko Sunday 10:00: 0.5 (Sunday only)
		[24, "after", 10.0, 6, 0],   # ... and not on a Saturday
		[24, "after", 12.0, 7, 0],
		[16, "roof", 0.0, 6, 16],    # Level 26 at midnight
		[16, "roof", 4.0, 6, 0],
	]
	for r: Array in rows:
		var got := Crowds.queue_len(int(r[0]), str(r[1]), float(r[2]), int(r[3]))
		_expect(got == int(r[4]), "queue %d %s at %.2f day %d: %d (want %d)" % [r[0], r[1], r[2], r[3], got, r[4]])
	_expect(Crowds.queue_len(24, "club", 1.0, 6, 2.0) == 48, "--crowd=2 doubles Smoła's 24")
	_expect(Crowds.queue_len(24, "club", 1.0, 6, 0.5) == 12, "the Low tier halves Smoła's 24")
	# Never past max_len × amount at any hour or day.
	for curve in ["club", "after", "roof"]:
		for d in range(1, 8):
			for h in 48:
				var n := Crowds.queue_len(24, curve, h * 0.5, d)
				if n < 0 or n > 24:
					problems.append("queue %s at %.1f day %d: %d (0-24)" % [curve, h * 0.5, d, n])
	# The steps: hour × month × rain, sunset 1.0.
	var steps: Array = [[19.5, 7, false, 80], [14.0, 7, false, 24], [10.0, 7, false, 8], [23.0, 7, false, 56], [1.0, 7, false, 24],
			[3.0, 7, false, 4], [19.5, 7, true, 8], [19.5, 11, false, 4], [19.5, 5, false, 56], [19.5, 4, false, 24], [18.0, 7, false, 48]]
	for r: Array in steps:
		var got := Crowds.steps_count(float(r[0]), int(r[1]), bool(r[2]), 19.5)
		_expect(got == int(r[3]), "steps at %.1f month %d rain %s: %d (want %d)" % [r[0], r[1], r[2], got, r[3]])
	_expect(Crowds.steps_count(21.0, 7, false, 21.0) == 80, "Live's sunset at 21:00: the steps full")
	var prev := 0.0
	for k in 8:
		var v := Crowds.steps_curve(18.0 + k * 0.25, 19.75)
		_expect(v >= prev - 0.0001, "the steps fill towards the sunset (%.2f at %.2f)" % [v, 18.0 + k * 0.25])
		prev = v
	for h in 48:
		var n := Crowds.steps_count(h * 0.5, 7, false, 19.5, 2.0)
		_expect(n <= 160, "steps doubled at %.1f: %d (≤ 160)" % [h * 0.5, n])
	_expect(Crowds.guitar_on(24, 19.5) and not Crowds.guitar_on(6, 19.5) and not Crowds.guitar_on(24, 10.0), "the guitarist's rule")
	# Plac Zbawiciela: Fri/Sat nights in summer.
	_expect(roundi(40 * Crowds.plan_c_level(23.0, 5, 7, false)) == 40, "Plan C Friday 23:00: 40")
	_expect(roundi(40 * Crowds.plan_c_level(1.0, 6, 7, false)) == 28, "Plan C Saturday 01:00 (Friday's night): 28")
	_expect(Crowds.plan_c_level(23.0, 3, 7, false) == 0.0, "Plan C on a Wednesday: none")
	_expect(Crowds.plan_c_level(3.0, 6, 7, false) == 0.0, "Plan C at 03:00: none")
	_expect(Crowds.plan_c_level(23.0, 5, 11, false) == 0.0, "Plan C in November: none")
	# The police by the clubs: Fri/Sat nights 00-08.
	for r: Array in [[1.0, 6, true], [7.5, 7, true], [1.0, 1, false], [9.0, 6, false], [23.0, 5, false], [1.0, 5, false]]:
		_expect(Crowds.police_time(float(r[0]), int(r[1])) == bool(r[2]), "police at %.1f day %d: want %s" % [r[0], r[1], r[2]])
	# The dawn crowd: Sat/Sun 05-09 in Live, or the Dawn look.
	for r: Array in [[5.75, 6, false, "Dawn", true], [5.75, 6, true, "Live", true], [8.9, 7, true, "Live", true],
			[5.75, 3, true, "Live", false], [9.0, 6, false, "Dawn", false], [4.9, 6, false, "Dawn", false], [6.0, 6, false, "Night", false]]:
		_expect(Crowds.dawn_time(float(r[0]), int(r[1]), bool(r[2]), str(r[3])) == bool(r[4]), "dawn at %s: want %s" % [r, r[4]])
	for h in 8:
		var n := Crowds.dawn_count(5.0 + h * 0.5)
		_expect(n >= 20 and n <= 40, "dawn walkers at %.1f: %d (20-40)" % [5.0 + h * 0.5, n])
	_expect(Crowds.dawn_count(5.75) == 30, "dawn walkers at 05:45: %d (want 30)" % Crowds.dawn_count(5.75))
	_expect(Crowds.car_at_door(6.0, 8.0, false) and not Crowds.car_at_door(9.0, 5.0, false) and not Crowds.car_at_door(4.0, 12.0, false)
			and not Crowds.car_at_door(2.0, 0.0, true), "the car at the door: within 8 m under 10 km/h, on the ground")


# 9. -------------------------------------------------------------------------------------------

func _check_level26(c: Crowds, book: Notebook, data: Dictionary) -> void:
	var at := Vector2.INF
	for p: Dictionary in book.places:
		if str(p["id"]) == Crowds.ROOF_ID:
			at = p["at"]
	var tall := 0.0
	for b: Dictionary in data.get("buildings", []):
		var flat: Array = b.get("p", [])
		var poly := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			poly.append(Vector2(float(flat[k]), float(flat[k + 1])))
		if poly.size() >= 3 and Geometry2D.is_point_in_polygon(at, poly):
			tall = maxf(tall, float(b.get("h", 0.0)))
	# The prebuilt index has no buildings (they live in the sectors): then only the rest.
	if data.has("buildings"):
		_expect(tall >= 100.0, "Level 26 at %s stands in no building of 100 m or more (tallest %.0f m)" % [at, tall])
	var door: Dictionary = c.sites[c.by_id[Crowds.ROOF_DOOR_ID]] if c.by_id.has(Crowds.ROOF_DOOR_ID) else {}
	_expect(not door.is_empty() and door["kind"] == "queue" and int(door["max"]) == Crowds.ROOF_DOOR_MAX
			and (door["at"] as Vector2) == at, "Level 26's door queue: %s" % door.get("kind", "missing"))
	# A synthetic tower: a 30 × 20 m box 112 m tall with a 116 m crown, on a 4 m grid.
	var roof := func(x: float, z: float) -> float:
		var i := floori(x / 4.0)
		var j := floori(z / 4.0)
		if i < -4 or i > 3 or j < -3 or j > 2:
			return -1000.0
		return 116.0 if absi(i) <= 1 and absi(j) <= 1 else 112.0
	var ring := Crowds.roof_ring(Vector2(0.4, 0.3), 116.0, roof, Crowds.RING_RAYS)
	var bad := 0
	for e: Array in ring:
		var p: Vector2 = e[0]
		# On the box's edge or outside it, never more than a cell (4 m) out.
		var out := maxf(absf(p.x + 0.0) - 16.0, absf(p.y) - 12.0)
		if out < -0.01 or out > 4.5 or float(e[2]) < 110.0:
			bad += 1
	_expect(ring.size() == Crowds.RING_RAYS and bad == 0, "the roof ring on a synthetic tower: %d rays, %d off the facade" % [ring.size(), bad])
	if verbose:
		print("  Level 26 at (%.0f, %.0f) in a %.0f m building part; its door queue from %s; ring %d rays" % [at.x, at.y, tall,
				door.get("door", Vector2.INF), ring.size()])


# 4. -------------------------------------------------------------------------------------------

func _check_sites(c: Crowds) -> void:
	# Trend follow-up: PISTACJA's line, its Friday drop and its site on a footway.
	_expect(Crowds.pistacja_queue(9.0, 5)[0] == 0 and Crowds.pistacja_queue(22.5, 5)[0] == 0, "PISTACJA: a line outside 10-22")
	_expect(Crowds.pistacja_queue(12.0, 2) == [Crowds.PISTACJA_BASE, "queue"], "PISTACJA: a Tuesday noon line %s" % [Crowds.pistacja_queue(12.0, 2)])
	_expect(Crowds.pistacja_queue(17.5, 5) == [Crowds.PISTACJA_MAX, "drop"], "PISTACJA: the Friday drop %s" % [Crowds.pistacja_queue(17.5, 5)])
	_expect(not Crowds.pistacja_drop(17.5, 4) and not Crowds.pistacja_drop(18.5, 5) and Crowds.pistacja_drop(16.0, 5), "PISTACJA: the drop's window")
	_expect(Crowds.padel_queue(18.0, 2) == [Crowds.PADEL_MAX, "padel"] and Crowds.padel_queue(10.0, 6)[0] == 10 and Crowds.padel_queue(3.0, 6)[0] == 0
			and Crowds.padel_queue(14.0, 2)[0] == 3, "PADELNIA: its line by hour")
	# The food hype (gaulle-and-food-hype.md G3, G4): KUKŁA's line is never under 8 while open,
	# HOTEL PIURE's lift line to LUŹNO is an evening one, past midnight counted from the evening.
	_expect(Crowds.kukla_queue(8.5, 2)[0] == 0 and Crowds.kukla_queue(21.5, 2)[0] == 0, "KUKŁA: a line outside 9-21")
	_expect(Crowds.kukla_queue(13.0, 3) == [Crowds.KUKLA_MAX, "kolejka"] and Crowds.kukla_queue(16.0, 7)[0] == Crowds.KUKLA_MAX
			and Crowds.kukla_queue(16.0, 2)[0] == 14 and Crowds.kukla_queue(9.5, 2)[0] == 8, "KUKŁA: its line by hour")
	# F, 2026-11-01: KROWA 2.0, the milk bar in Norblin, and the chill yards.
	_expect(Crowds.milk_queue(7.5, 2)[0] == 0 and Crowds.milk_queue(18.5, 2)[0] == 0 and Crowds.milk_queue(13.0, 3) == [Crowds.MILK_MAX, "kolejka"]
			and Crowds.milk_queue(10.0, 3)[0] == 10 and Crowds.milk_queue(13.0, 7)[0] < Crowds.MILK_MAX, "KROWA 2.0: its line by hour")
	_expect(Crowds.chill_level(19.0, 7, false) == 1.0 and Crowds.chill_level(8.0, 7, false) == 0.0
			and Crowds.chill_level(19.0, 1, false) > 0.3 and Crowds.chill_level(19.0, 7, true) < 0.2, "chill yards: evening full, morning empty, winter a third, rain few")
	_expect(Crowds.piure_queue(17.0, 5)[0] == 0 and Crowds.piure_queue(20.0, 2) == [10, "timber"]
			and Crowds.piure_queue(20.0, 5)[0] == Crowds.PIURE_MAX and Crowds.piure_queue(0.5, 7)[0] == Crowds.PIURE_MAX
			and Crowds.piure_queue(0.5, 1)[0] == 10 and Crowds.piure_queue(1.5, 6)[0] == 0, "HOTEL PIURE: its line by hour")
	for vid: String in Crowds.KUKLA + [Crowds.PIURE_ID]:
		_expect(c.by_id.has(vid), "no crowd at %s" % vid)
	_expect(c.by_id.has(Crowds.PADEL_ID), "no crowd at PADELNIA")
	_expect(c.by_id.has(Crowds.PISTACJA_ID), "no crowd at PISTACJA")
	if c.by_id.has(Crowds.PISTACJA_ID):
		var ps: Dictionary = c.sites[c.by_id[Crowds.PISTACJA_ID]]
		_expect(not c.nearest_foot(ps["at"], Crowds.FOOT_REACH).is_empty(), "PISTACJA: no footway within %.0f m" % Crowds.FOOT_REACH)
		_expect(ps.has("door") and ps.has("line") and (ps["line"] as PackedVector2Array).size() >= Crowds.PISTACJA_MAX + 1,
				"PISTACJA: a line of %d spots for %d" % [(ps["line"] as PackedVector2Array).size() if ps.has("line") else 0, Crowds.PISTACJA_MAX])
	for id in ["lusterko", "smola", "jasna_0", "lombard", "milosc_hipoteczna", "schodki_kopernik", "plan_c", "level_26", Crowds.ROOF_DOOR_ID]:
		_expect(c.by_id.has(id), "no crowd at %s" % id)
	for s in c.sites:
		if s["kind"] != "queue":
			continue
		var line: PackedVector2Array = s["line"]
		_expect(line.size() >= int(s["max"]) + 1, "%s: a line of %d spots for %d" % [s["id"], line.size(), s["max"]])
		var hit := c.nearest_foot(s["at"], Crowds.FOOT_REACH)
		_expect(not hit.is_empty(), "%s: no footway within %.0f m" % [s["id"], Crowds.FOOT_REACH])
		for k in range(1, mini(line.size(), 25)):
			var gap := line[k].distance_to(line[k - 1])
			if absf(gap - Crowds.QUEUE_GAP) > 0.05 and gap > 0.01:
				# A corner in the footway shortens one gap: allow down to half.
				if gap < Crowds.QUEUE_GAP * 0.5 or gap > Crowds.QUEUE_GAP + 0.05:
					problems.append("%s: spot %d is %.2f m from the last (0.7)" % [s["id"], k, gap])
		if verbose:
			print("  %s: door %s, %.1f m from the place, line of %d" % [s["id"], s["door"], (s["door"] as Vector2).distance_to(s["at"]), line.size()])
	var steps: Dictionary = c.sites[c.by_id["schodki_kopernik"]]
	_expect((steps["slots"] as Array).size() >= Crowds.STEPS_MAX, "the steps: %d slots for 80" % (steps["slots"] as Array).size())
	var sq: Dictionary = c.sites[c.by_id["plan_c"]]
	_expect((sq["slots"] as Array).size() >= Crowds.PLAN_C_MAX, "Plan C: %d slots for 40" % (sq["slots"] as Array).size())


# 5. -------------------------------------------------------------------------------------------

func _run_ticks(c: Crowds, seconds: float) -> void:
	var n := int(seconds / Crowds.TICK)
	for i in n:
		c.t += Crowds.TICK
		c.tick(Crowds.TICK)


func _check_door(c: Crowds, dlg: FakeDialogue) -> void:
	var smola: Dictionary = c.sites[c.by_id["smola"]]
	var door: Vector2 = smola["door"]
	eye = Vector3(door.x, 0.0, door.y)
	now = {"hour": 1.0, "weekday": 6}
	cal["look"] = "Night"
	seen = true
	c.refresh()
	c.tick(Crowds.TICK)
	_expect(int(smola["n"]) == 24, "Smoła's queue at Friday's 01:00: %d (want 24)" % int(smola["n"]))
	_expect(bool(smola["active"]) and (smola["inst"] as Array).size() >= 25, "Smoła's figures: %d (24 + the bouncer)" % (smola["inst"] as Array).size())
	# The first rejection within 60 s, then one every 30-60 s.
	var r0 := int(smola.get("rejected", 0))
	var first := -1.0
	var t0 := c.t
	for i in 600:
		c.t += Crowds.TICK
		c.tick(Crowds.TICK)
		if int(smola.get("rejected", 0)) > r0 and first < 0.0:
			first = c.t - t0
	var n := int(smola.get("rejected", 0)) - r0
	_rejections = n
	_expect(first > 0.0 and first <= 60.0 + Crowds.TICK, "the first rejection after %.1f s (≤ 60)" % first)
	_expect(n >= 4 and n <= 11, "%d rejections in 300 s (one every 30-60 s)" % n)
	_expect(dlg.count("club_door", "reject") >= n and dlg.count("club_door", "reject") == c.rejections, "%d reject lines for %d rejections" % [dlg.count("club_door", "reject"), n])
	_expect(int(smola["n"]) <= 24, "the queue grew past 24")
	# Off screen: none. A short queue: none.
	seen = false
	var r1 := c.rejections
	_run_ticks(c, 120.0)
	_expect(c.rejections == r1, "rejections off screen: %d" % (c.rejections - r1))
	seen = true
	now = {"hour": 22.0, "weekday": 5}
	c.refresh()
	_run_ticks(c, 1.0)
	var r2 := c.rejections
	_run_ticks(c, 120.0)
	_expect(int(smola["n"]) == 2 and c.rejections == r2, "a queue of %d at 22:00: %d rejections (want 2, none)" % [int(smola["n"]), c.rejections - r2])
	# The car at the door: once a club a night.
	now = {"hour": 1.0, "weekday": 6}
	c.refresh()
	_run_ticks(c, 1.0)
	var lines0 := dlg.count("club_door", "car")
	veh = [Vector3(door.x + 3.0, 0.0, door.y), 25.0, false]
	_run_ticks(c, 2.0)
	_expect(dlg.count("club_door", "car") == lines0, "the car line at 25 km/h")
	veh = [Vector3(door.x + 3.0, 0.0, door.y), 0.0, true]
	_run_ticks(c, 2.0)
	_expect(dlg.count("club_door", "car") == lines0, "the car line for the helicopter")
	veh = [Vector3(door.x + 3.0, 0.0, door.y), 6.0, false]
	_run_ticks(c, 10.0)
	_expect(dlg.count("club_door", "car") == lines0 + 1, "the car at the door: %d lines (want 1)" % (dlg.count("club_door", "car") - lines0))
	now = {"hour": 1.0, "weekday": 7}
	_run_ticks(c, 2.0)
	_expect(dlg.count("club_door", "car") == lines0 + 2, "the next night: the car line again")
	# The garage loop: painted black, the next night: the `car_black` line instead; no egg at Smoła.
	var eggs_asked: Array[String] = []
	c.paint = func() -> String: return "black"
	c.egg = func(id: String) -> bool:
		eggs_asked.append(id)
		return true
	var black0 := dlg.count("club_door", "car_black")
	now = {"hour": 1.0, "weekday": 1}
	_run_ticks(c, 45.0)
	_expect(dlg.count("club_door", "car_black") == black0 + 1 and dlg.count("club_door", "car") == lines0 + 2,
			"the black car: %d car_black lines (want 1), %d car lines (want none)" % [dlg.count("club_door", "car_black") - black0,
			dlg.count("club_door", "car") - lines0 - 2])
	_expect(eggs_asked.is_empty(), "an egg asked at Smoła's door: %s" % [eggs_asked])
	c.paint = Callable()
	c.egg = Callable()
	veh = [Vector3.INF, 0.0, false]
	now = {"hour": 1.0, "weekday": 7}
	_run_ticks(c, 2.0)
	# The police by Smoła (no police node: the officer alone), and their level.
	_expect(c.police_on and c.levels.get("police_club", 0.0) == 1.0 and smola["officer"] != Vector3.INF, "the police by Smoła at Saturday's 01:00")
	now = {"hour": 14.0, "weekday": 6}
	_run_ticks(c, 1.0)
	_expect(not c.police_on and smola["officer"] == Vector3.INF, "the police gone by day")


# 6. -------------------------------------------------------------------------------------------

func _check_dawn(c: Crowds, _data: Dictionary) -> float:
	var paths: Array = []
	for f in c.get("_foot"):
		paths.append([f["pts"], int(f["dk"])])
	var rin: Dictionary = c.get("_route_in")
	var t0 := Time.get_ticks_msec()
	var found: Array = Crowds.build_routes(paths, rin["from"], rin["to"])
	var ms := Time.get_ticks_msec() - t0
	_routes = found.size()
	_expect(found.size() >= (rin["from"] as Array).size() * 3, "dawn routes: %d of %d (clubs × ends)" % [found.size(), (rin["from"] as Array).size() * (rin["to"] as Array).size()])
	for r: Dictionary in found:
		var pts: PackedVector2Array = r["pts"]
		var l := 0.0
		for i in pts.size() - 1:
			l += pts[i].distance_to(pts[i + 1])
			if pts[i].distance_to(pts[i + 1]) > 300.0:
				problems.append("route %s→%s jumps %.0f m" % [r["from"], r["to"], pts[i].distance_to(pts[i + 1])])
				break
		var straight := pts[0].distance_to(pts[pts.size() - 1])
		if l > straight * 2.5 + 200.0 or l > 3000.0:
			problems.append("route %s→%s: %.0f m for %.0f m straight" % [r["from"], r["to"], l, straight])
	if verbose:
		print("  %d dawn routes in %d ms (%d footways)" % [found.size(), ms, paths.size()])
	c.set("_route_out", [found])
	c.call("_finish_routes")
	var lusterko: Dictionary = c.sites[c.by_id["lusterko"]]
	var at: Vector2 = lusterko["door"]
	eye = Vector3(at.x, 0.0, at.y)
	now = {"hour": 5.75, "weekday": 6}
	cal = {"live": false, "month": 7, "date": 0, "look": "Dawn", "rain": false, "sunset": 19.5}
	c.refresh()
	var us := Time.get_ticks_usec()
	_run_ticks(c, 30.0)
	var cost := float(Time.get_ticks_usec() - us) / (30.0 / Crowds.TICK)
	_expect(c.dawn_on and c.walkers.size() == 30, "the dawn crowd at 05:45 in the Dawn look: %d walkers (want 30)" % c.walkers.size())
	_expect(c.levels.get("dawn", 0.0) == 1.0, "the dawn level for the eggs")
	for i in c.walkers.size():
		var p := c.walker_pos(i)
		var r: Dictionary = c.routes[int(c.walkers[i]["r"])]
		var near := INF
		var pts: PackedVector2Array = r["pts"]
		for k in pts.size() - 1:
			near = minf(near, Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), pts[k], pts[k + 1]).distance_to(Vector2(p.x, p.z)))
		if near > 1.5:
			problems.append("walker %d is %.1f m off its route" % [i, near])
	# They move: 10 s later, most are elsewhere.
	var before: Array = []
	for i in c.walkers.size():
		before.append(c.walker_pos(i))
	_run_ticks(c, 10.0)
	var moved := 0
	for i in mini(before.size(), c.walkers.size()):
		moved += int((before[i] as Vector3).distance_to(c.walker_pos(i)) > 3.0)
	_expect(moved >= 20, "the dawn crowd walks: %d of %d moved 3+ m in 10 s" % [moved, c.walkers.size()])
	now = {"hour": 9.0, "weekday": 6}
	_run_ticks(c, 1.0)
	_expect(not c.dawn_on and c.walkers.is_empty(), "the dawn crowd at 09:00: %d" % c.walkers.size())
	cal = {"live": true, "month": 7, "date": 20270630, "look": "Live", "rain": false, "sunset": 21.0}
	now = {"hour": 6.0, "weekday": 3}
	_run_ticks(c, 1.0)
	_expect(not c.dawn_on, "the dawn crowd on a Live Wednesday")
	now = {"hour": 6.0, "weekday": 7}
	_run_ticks(c, 1.0)
	_expect(c.dawn_on and c.walkers.size() == 40, "the dawn crowd on a Live Sunday at 06:00: %d (want 40)" % c.walkers.size())
	return cost


func _check_grid_routes() -> void:
	# A 6 × 6 grid of 50 m footways, its middle crossing missing: the way round it.
	var paths: Array = []
	for i in 6:
		for j in 5:
			paths.append([PackedVector2Array([Vector2(i * 50.0, j * 50.0), Vector2(i * 50.0, (j + 1) * 50.0)]), -1])
			if not (j == 2 and i == 2):
				paths.append([PackedVector2Array([Vector2(j * 50.0, i * 50.0), Vector2((j + 1) * 50.0, i * 50.0)]), -1])
	var r: Array = Crowds.build_routes(paths, [["a", Vector2(0, 0)]], [["b", Vector2(250, 250)], ["c", Vector2(400, 400)]])
	_expect(r.size() == 1, "grid: %d routes (want 1: the far end is 141 m off)" % r.size())
	if r.size() == 1:
		var pts: PackedVector2Array = r[0]["pts"]
		var l := 0.0
		for i in pts.size() - 1:
			l += pts[i].distance_to(pts[i + 1])
		_expect(absf(l - 500.0) < 0.1, "grid: the route is %.1f m (want 500, the Manhattan way)" % l)


# 7. -------------------------------------------------------------------------------------------

func _check_eggs(c: Crowds, nb: Notebook) -> void:
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	var book: EggBook = EggBook.new()
	book.wallet = wallet
	root.add_child(book)
	if not book.load_eggs():
		problems.append("no eggs.json")
		return
	var places := {}
	for p: Dictionary in nb.places:
		places[str(p["id"])] = p["at"]
	# The palm is one of eggs.gd's spots (the map's own point).
	var palm_xz: Vector2 = (c.get("_route_in")["to"] as Array).filter(func(e: Array) -> bool: return e[0] == "palma")[0][1]
	book.setup(places, {"palma": Vector3(palm_xz.x, 0.0, palm_xz.y)}, {})
	for id in ["e03", "e04", "e15"]:
		_expect(not book.eggs[book.by_id[id]].has("waits"), "%s still waits" % id)
	# The garage loop woke E01: an event at Lusterko's door (crowds.gd `door_egg`, check_garage).
	_expect(str(book.eggs[book.by_id["e01"]]["trigger"]["kind"]) == "event" and not book.eggs[book.by_id["e01"]].has("waits"), "e01 is the garage loop's event")
	for id in ["e23", "e24", "e25"]:
		_expect(str(book.eggs[book.by_id[id]]["trigger"]["kind"]) == "event" and not book.eggs[book.by_id[id]].has("waits"), "%s is the night-buses loop's event" % id)
	# [egg, state additions, the crowd levels it wants, the levels that aren't enough]
	var cases: Array = [
		["e03", {"look": "Dawn", "hour": 5.75, "weekday": 6}, {"dawn": 1.0}, {"dawn": 0.0}],
		["e04", {"look": "Night", "hour": 1.0, "weekday": 6}, {"police_club": 1.0}, {}],
		["e10", {"look": "Night", "hour": 23.5, "weekday": 5}, {"plan_c": 1.0}, {}],
		["e14", {"look": "Dusk", "hour": 19.5, "weekday": 5}, {"steps": 1.0}, {"steps": 0.7}],
	]
	for row: Array in cases:
		var e: Dictionary = book.eggs[book.by_id[row[0]]]
		var s := _state(e, row[1], row[2])
		var bad := _state(e, row[1], row[3])
		var fired_bad := false
		var mem := {}
		for i in 40:
			fired_bad = fired_bad or EggBook.step(e, _lap(e, bad, i), mem, 0.5)
		_expect(not fired_bad, "%s fired without its crowd" % row[0])
		var fired := false
		mem = {}
		for i in 300:
			if EggBook.step(e, _lap(e, s, i), mem, 0.5):
				fired = true
				break
		_expect(fired, "%s never fired with its crowd" % row[0])
	# E15: the guitarist on three different days; the card on the third, paid once.
	var e15: Dictionary = book.eggs[book.by_id["e15"]]
	var before := wallet.respect
	for day in [20270703, 20270704, 20270704, 20270710]:
		var s := _state(e15, {"look": "Dusk", "hour": 19.5, "weekday": 6, "live": true, "date": day, "month": 7}, {"guitar": 1.0})
		for i in 10:
			book.tick(s, 0.5)
		var days := book.days_met("e15")
		if day == 20270704:
			_expect(not book.is_found("e15") and days == 2, "e15 after the second day: found %s, %d days" % [book.is_found("e15"), days])
	_expect(book.is_found("e15") and wallet.respect - before == 30, "e15 on the third day: found %s, +%d respect (want 30)" % [book.is_found("e15"), wallet.respect - before])
	var mid := wallet.respect
	book.record("e15")
	_expect(wallet.respect == mid, "e15 paid twice")
	# E03 through tick with the real crowds' levels: found once, +20.
	var palm: Vector2 = palm_xz
	var s3 := {"pos": Vector3(palm.x + 5.0, 0.0, palm.y), "kmh": 0.0, "flying": false, "look": "Dawn", "hour": 5.75, "weekday": 6,
			"live": false, "month": 7, "rain": false, "station": "", "date": 0, "roadworks": "", "crowds": c.levels.duplicate()}
	s3["crowds"]["dawn"] = 1.0
	var r0 := wallet.respect
	for i in 10:
		book.tick(s3, 0.5)
	_expect(book.is_found("e03") and wallet.respect - r0 == 20, "e03 by the palm at dawn: found %s, +%d (want 20)" % [book.is_found("e03"), wallet.respect - r0])
	for i in 10:
		book.tick(s3, 0.5)
	_expect(wallet.respect - r0 == 20, "e03 paid twice")
	book.queue_free()
	wallet.queue_free()


## A state for egg `e`'s trigger at its place, with `extra` and the crowd levels `crowds`.
static func _state(e: Dictionary, extra: Dictionary, crowds: Dictionary) -> Dictionary:
	var at: Vector2 = e["at"]
	var s := {"pos": Vector3(at.x + 3.0, 0.0, at.y), "kmh": 0.0, "flying": false, "alt": 0.0, "roof": 0.0, "look": "Day",
			"hour": 14.0, "weekday": 5, "month": 7, "live": false, "sun": 30.0, "rain": false, "station": "", "date": 0,
			"roadworks": "", "crowds": crowds}
	for k in extra:
		s[k] = extra[k]
	return s


## The state at step `i` of the egg's motion (a lap round its place for a `lap` trigger).
static func _lap(e: Dictionary, s: Dictionary, i: int) -> Dictionary:
	var t: Dictionary = e["trigger"]
	if str(t.get("kind", "")) != "lap":
		return s
	var r: Array = t["r"]
	var mid := (float(r[0]) + float(r[1])) * 0.5
	var at: Vector2 = e["at"]
	var p := at + Vector2(cos(i * 0.12), sin(i * 0.12)) * mid
	var out := s.duplicate()
	out["pos"] = Vector3(p.x, 0.0, p.y)
	out["kmh"] = 15.0
	return out
