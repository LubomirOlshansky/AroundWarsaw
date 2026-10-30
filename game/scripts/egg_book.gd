extends Node
## Loop MW-6 (docs/design/vision.md section 8 and 4.7): the easter eggs as notebook cards. The 45
## cards of `data/eggs.json`: the five eggs of v0.65 (eggs.gd finds them, as before: `legacy`) and
## vision's 40. Each has a place (a notebook place, or one of eggs.gd's spots), a trigger, a line
## and a reward; the first find puts the card in the notebook (wallet.gd `eggs`: id -> the day),
## pays its respect, opens its PÓŁNOC FM track (radio.gd `unlock_track`), stamps its then card
## (tape.gd) and shows the note card. An egg whose trigger needs something not built yet (the
## crowds of MW-3/MW-4, the garage's paint, the night buses) has `waits`: its card is in the
## notebook as "?", and nothing finds it.
##
## The triggers (`step`, static, so check_eggs.gd runs them on synthetic inputs):
##   stop    the car stopped (< 1 km/h) within `within` m for `secs` s;
##   pass    the car within `within` m (at most `max_kmh` when given);
##   hover   the helicopter within `within` m, at least `min_alt` m over the ground, under
##           12 km/h, for `secs` s;
##   land    the helicopter set down (under 1.5 m, under 2 km/h) within `within` m on a roof at
##           least `roof` m over the street;
##   circle  the helicopter round the place once (360 degrees) between `r` [min, max] m;
##   lap     the car round the place once between `r` m, never over `max_kmh`;
##   street  the car along `share` of the named street's length (in 20 m pieces), never over
##           `max_kmh` on it (faster starts it again);
##   between the helicopter within `within` m of the line between two landmarks (`a`, `b`), in
##           its middle 70 %, at least `min_alt` m up;
##   tape    KASETA played at the then card `card` (tape.gd calls `tape_played`).
## Conditions on any trigger, by the game clock (time_of_day.gd `local_clock`): `night` (22-06),
## `after` (that hour to 06), `hours` [from, to] (may wrap midnight), `weekday` (1 Monday .. 7
## Sunday), `look` ("Dusk": the Dusk look, or Live with the sun within 6 degrees of the horizon),
## `summer` (June-August in Live; always without it: vision Open Question 5), `dry` (no rain),
## `date` ("fat_thursday", Live or --date), `station` (the tuned station's id), `roadworks` (the
## day's roadworks on that street: eggs.gd).
## Checked twice a second over a 200 m grid of the eggs (`CELL`): a check looks at the eggs of
## the one cell the vehicle is in; nothing runs per frame but a timer (and the --egg rig).

signal found(id: String)

const EGGS_PATH := "res://data/eggs.json"
const DIALOGUE_PATH := "res://data/dialogue.json"
const CHECK_EVERY := 0.5
const CELL := 200.0
const STOP_KMH := 1.0
const HOVER_KMH := 12.0
const LAND_ALT := 1.5
const LAND_KMH := 2.0
const STREET_PIECE := 20.0
const STREET_NEAR := 16.0
const EGG_COLOUR := Color("#ff4fd8")

## Every card: eggs.json's fields plus `at` (Vector2, map x, z; INF when it has no point), `n`
## (its number in the notebook, from 1) and, for a street egg, `pieces` (PackedVector2Array).
var eggs: Array[Dictionary] = []
var by_id := {}
## What a waiting egg waits for, by key (eggs.json `waits`).
var waits := {}
var wallet: Node
var hud: CanvasLayer
## radio.gd (unlock_track, next_locked, the tracks' titles).
var radio: Node
## tape.gd: stamps a then card (`stamp`).
var tape: Node
## Called at each check: a Dictionary (main.gd `_egg_state`): pos, kmh, flying, alt, roof, away,
## look, hour, weekday, month, live, sun, rain, station, date, roadworks.
var probe: Callable
var blip: Callable
## --egg-log: the trigger and the reward of each find, and the --egg rig's lines.
var log_on := false
var spent_usec := 0
var ready_ok := false
## dialogue.json's groups, for `line_ref`.
var _lines := {}
var _grid := {}
var _mem := {}
var _t := 0.0


## Reads eggs.json and dialogue.json (no map: the notebook page and the checks). False if missing.
func load_eggs() -> bool:
	if not FileAccess.file_exists(EGGS_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(EGGS_PATH))
	if not json is Dictionary:
		push_error("egg_book: %s does not parse" % EGGS_PATH)
		return false
	waits = json.get("waits", {})
	eggs.clear()
	by_id.clear()
	for e: Dictionary in json.get("eggs", []):
		var egg := e.duplicate(true)
		egg["at"] = Vector2.INF
		egg["n"] = eggs.size() + 1
		by_id[str(e["id"])] = eggs.size()
		eggs.append(egg)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUE_PATH)) if FileAccess.file_exists(DIALOGUE_PATH) else null
	_lines = d if d is Dictionary else {}
	if wallet != null:
		wallet.eggs_total = eggs.size()
	return true


## Puts each egg on the map: `places` (notebook.gd: id -> Vector2), `spots` (eggs.gd's spots: id
## -> Vector3), `data` (the map: roads for a street egg, landmarks for a `between` one). Builds the
## grid.
func setup(places: Dictionary, spots: Dictionary, data: Dictionary) -> bool:
	if eggs.is_empty() and not load_eggs():
		return false
	var marks := {}
	for l: Dictionary in data.get("landmarks", []):
		var n := str(l.get("name", ""))
		var pts: Array = l.get("p", [])
		if n == "" or pts.size() < 2 or marks.has(n):
			continue
		var c := Vector2.ZERO
		for i in range(0, pts.size() - 1, 2):
			c += Vector2(float(pts[i]), float(pts[i + 1]))
		marks[n] = c / float(pts.size() / 2)
	var placed := 0
	for e in eggs:
		var pid := str(e.get("place", ""))
		if places.has(pid):
			e["at"] = places[pid]
		elif spots.has(pid):
			var v: Vector3 = spots[pid]
			e["at"] = Vector2(v.x, v.z)
		var trig: Dictionary = e["trigger"]
		# `road`: the egg sits on that named road, at its point nearest the place (E09: the
		# bridge's deck; the place's own point is in the river).
		if trig.has("road") and e["at"] != Vector2.INF:
			e["at"] = nearest_on_road(data.get("roads", []), str(trig["road"]), e["at"])
		match str(trig.get("kind", "")):
			"street":
				e["pieces"] = street_pieces(data.get("roads", []), str(trig.get("street", "")))
			"between":
				if marks.has(str(trig.get("a", ""))) and marks.has(str(trig.get("b", ""))):
					e["a"] = marks[str(trig["a"])]
					e["b"] = marks[str(trig["b"])]
		placed += int(e["at"] != Vector2.INF)
	_build_grid()
	ready_ok = true
	print("eggs: %d cards (%d reachable now, %d waiting), %d placed" % [eggs.size(), reachable().size(),
			eggs.size() - reachable().size(), placed])
	return true


## The point of the named road's centre line nearest `p` (`p` itself if there is no such road).
static func nearest_on_road(roads: Array, road: String, p: Vector2) -> Vector2:
	var best := p
	var best_d := INF
	for r: Dictionary in roads:
		if str(r.get("name", "")) != road:
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 3, 2):
			var q := Geometry2D.get_closest_point_to_segment(p, Vector2(flat[i], flat[i + 1]), Vector2(flat[i + 2], flat[i + 3]))
			if q.distance_to(p) < best_d:
				best_d = q.distance_to(p)
				best = q
	return best


## The named street's centre line cut into STREET_PIECE m pieces (their middles).
static func street_pieces(roads: Array, street: String) -> PackedVector2Array:
	var out := PackedVector2Array()
	if street == "":
		return out
	for r: Dictionary in roads:
		if str(r.get("name", "")) != street:
			continue
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(flat[i], flat[i + 1])
			var b := Vector2(flat[i + 2], flat[i + 3])
			var n := maxi(1, roundi(a.distance_to(b) / STREET_PIECE))
			for k in n:
				var p := a.lerp(b, (k + 0.5) / n)
				# Two-way streets come as two lines a few metres apart: one piece for both.
				var dup := false
				for q in out:
					if q.distance_squared_to(p) < 64.0:
						dup = true
						break
				if not dup:
					out.append(p)
	return out


## The ids that can be found in today's game (no `waits`).
func reachable() -> Array[String]:
	var out: Array[String] = []
	for e in eggs:
		if not e.has("waits"):
			out.append(str(e["id"]))
	return out


## An egg's line [pl, en]: its own, or the dialogue line it names.
func line_of(e: Dictionary) -> Array:
	if e.has("line"):
		return e["line"]
	var ref: Array = e.get("line_ref", [])
	if ref.size() == 2 and _lines.has(str(ref[0])):
		var group: Array = _lines[str(ref[0])]
		var i := int(ref[1])
		if i >= 0 and i < group.size():
			return [str(group[i][0]), str(group[i][1])]
	return ["", ""]


## How far from its point an egg can fire (for the grid).
static func reach(e: Dictionary) -> float:
	var t: Dictionary = e["trigger"]
	var r: Array = t.get("r", [0, 0])
	return maxf(float(t.get("within", 30.0)), float(r[1]) if r.size() > 1 else 0.0) + 20.0


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


func _add_box(i: int, lo: Vector2, hi: Vector2) -> void:
	var a := _cell(lo)
	var b := _cell(hi)
	for x in range(a.x, b.x + 1):
		for z in range(a.y, b.y + 1):
			var key := Vector2i(x, z)
			if not _grid.has(key):
				_grid[key] = []
			if not i in _grid[key]:
				_grid[key].append(i)


func _build_grid() -> void:
	_grid.clear()
	for i in eggs.size():
		var e := eggs[i]
		var kind := str(e["trigger"].get("kind", ""))
		if e.has("waits") or kind in ["legacy", "tape", "waits"]:
			continue
		if kind == "street":
			for p: Vector2 in e.get("pieces", PackedVector2Array()):
				_add_box(i, p - Vector2.ONE * 30.0, p + Vector2.ONE * 30.0)
		elif kind == "between":
			if e.has("a"):
				var a: Vector2 = e["a"]
				var b: Vector2 = e["b"]
				var w := float(e["trigger"].get("within", 30.0)) + 10.0
				_add_box(i, Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * w, Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * w)
		elif e["at"] != Vector2.INF:
			var r := reach(e)
			_add_box(i, e["at"] - Vector2(r, r), e["at"] + Vector2(r, r))


# --- the checks --------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not ready_ok or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	var step_s := _t
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	tick(probe.call(), step_s)
	spent_usec += Time.get_ticks_usec() - t0


## One check on `s` (the probe's state), `dt` seconds after the last.
func tick(s: Dictionary, dt: float) -> void:
	if bool(s.get("away", false)):
		return
	var pos: Vector3 = s["pos"]
	var p := Vector2(pos.x, pos.z)
	var seen := {}
	for i: int in _grid.get(_cell(p), []):
		var e := eggs[i]
		var id := str(e["id"])
		seen[id] = true
		if is_found(id):
			continue
		if not _mem.has(id):
			_mem[id] = {}
		if step(e, s, _mem[id], dt):
			if log_on:
				print("egg: %s trigger %s met (%s)" % [id, e["trigger"].get("kind", ""), describe_state(s)])
			record(id)
	# An egg left behind starts again next time (a half lap, a half street).
	for id: String in _mem.keys():
		if not seen.has(id):
			_mem.erase(id)


## The game clock's conditions on trigger `t` for state `s`.
static func conditions(t: Dictionary, s: Dictionary) -> bool:
	var hour := float(s.get("hour", 14.0))
	if bool(t.get("night", false)) and not (hour >= 22.0 or hour < 6.0):
		return false
	if t.has("after") and not (hour >= float(t["after"]) or hour < 6.0):
		return false
	if t.has("hours"):
		var h: Array = t["hours"]
		var a := float(h[0])
		var b := float(h[1])
		if a <= b and not (hour >= a and hour < b):
			return false
		if a > b and not (hour >= a or hour < b):
			return false
	if t.has("weekday") and not int(s.get("weekday", 5)) in (t["weekday"] as Array).map(func(x: Variant) -> int: return int(x)):
		return false
	if t.has("look"):
		var look := str(s.get("look", "Day"))
		var ok := look == str(t["look"])
		if not ok and look == "Live" and str(t["look"]) == "Dusk":
			ok = absf(float(s.get("sun", 30.0))) <= 6.0
		if not ok:
			return false
	if bool(t.get("summer", false)) and bool(s.get("live", false)) and not int(s.get("month", 7)) in [6, 7, 8]:
		return false
	if bool(t.get("dry", false)) and bool(s.get("rain", false)):
		return false
	if t.has("date") and str(t["date"]) == "fat_thursday" and int(s.get("date", 0)) != fat_thursday(int(s.get("date", 0)) / 10000):
		return false
	if t.has("station") and str(s.get("station", "")) != str(t["station"]):
		return false
	if t.has("roadworks") and str(s.get("roadworks", "")) != str(t["roadworks"]):
		return false
	return true


## The trigger of egg `e` in state `s` (`mem`: the egg's own memory between checks, `dt` the
## seconds since the last check). True when it fires.
static func step(e: Dictionary, s: Dictionary, mem: Dictionary, dt: float) -> bool:
	var t: Dictionary = e["trigger"]
	var kind := str(t.get("kind", ""))
	if e.has("waits") or kind in ["waits", "legacy", "tape", ""]:
		return false
	var pos: Vector3 = s["pos"]
	var p := Vector2(pos.x, pos.z)
	var at: Vector2 = e.get("at", Vector2.INF)
	var flying := bool(s.get("flying", false))
	var kmh := float(s.get("kmh", 0.0))
	var alt := float(s.get("alt", 0.0))
	var d := p.distance_to(at) if at != Vector2.INF else INF
	var within := float(t.get("within", 30.0))
	var cond := conditions(t, s)
	match kind:
		"stop":
			if not flying and d <= within and kmh < STOP_KMH and cond:
				mem["still"] = float(mem.get("still", 0.0)) + dt
			else:
				mem["still"] = 0.0
			return float(mem["still"]) >= float(t.get("secs", 1.0)) - 0.001
		"pass":
			return not flying and d <= within and kmh <= float(t.get("max_kmh", 999.0)) and cond
		"hover":
			if flying and d <= within and alt >= float(t.get("min_alt", 0.0)) and kmh < HOVER_KMH and cond:
				mem["still"] = float(mem.get("still", 0.0)) + dt
			else:
				mem["still"] = 0.0
			return float(mem["still"]) >= float(t.get("secs", 1.0)) - 0.001
		"land":
			# `skids`: over whatever is under the helicopter (the roof), not over the street.
			return flying and d <= within and float(s.get("skids", alt)) < LAND_ALT and kmh < LAND_KMH \
					and float(s.get("roof", 0.0)) >= float(t.get("roof", 0.0)) and cond
		"circle", "lap":
			var r: Array = t.get("r", [0, 100])
			var ok := d >= float(r[0]) and d <= float(r[1]) and cond
			if kind == "circle":
				ok = ok and flying
			else:
				ok = ok and not flying and kmh <= float(t.get("max_kmh", 999.0))
			if not ok:
				mem.erase("angle")
				mem["sweep"] = 0.0
				return false
			var a := (p - at).angle()
			if mem.has("angle"):
				mem["sweep"] = float(mem.get("sweep", 0.0)) + wrapf(a - float(mem["angle"]), -PI, PI)
			mem["angle"] = a
			return absf(float(mem.get("sweep", 0.0))) >= TAU - 0.05
		"street":
			var pieces: PackedVector2Array = e.get("pieces", PackedVector2Array())
			if pieces.is_empty() or flying:
				return false
			var near := -1
			var best := STREET_NEAR * STREET_NEAR
			for k in pieces.size():
				var dd := p.distance_squared_to(pieces[k])
				if dd < best:
					best = dd
					near = k
			if near < 0:
				return false
			if kmh > float(t.get("max_kmh", 999.0)) or not cond:
				mem["pieces"] = {}
				return false
			if not mem.has("pieces"):
				mem["pieces"] = {}
			(mem["pieces"] as Dictionary)[near] = true
			return (mem["pieces"] as Dictionary).size() >= ceili(pieces.size() * float(t.get("share", 0.85)))
		"between":
			if not flying or not e.has("a") or alt < float(t.get("min_alt", 0.0)) or not cond:
				return false
			var a: Vector2 = e["a"]
			var b: Vector2 = e["b"]
			var ab := b - a
			var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)
			return k >= 0.15 and k <= 0.85 and p.distance_to(a + ab * k) <= within
	return false


## KASETA played at then card `card` (tape.gd): a `tape` egg on it fires (with its conditions).
func tape_played(card: String, s: Dictionary) -> void:
	for e in eggs:
		var t: Dictionary = e["trigger"]
		if str(t.get("kind", "")) == "tape" and str(t.get("card", "")) == card and not e.has("waits"):
			if conditions(t, s):
				record(str(e["id"]))
			elif log_on:
				print("egg: %s: KASETA at %s, but not its conditions (%s)" % [e["id"], card, describe_state(s)])


## Fat Thursday (Tłusty Czwartek) of `year` as yyyymmdd: 52 days before Easter Sunday.
static func fat_thursday(year: int) -> int:
	# The anonymous Gregorian computus (Meeus).
	var a := year % 19
	var b := year / 100
	var c := year % 100
	var d := b / 4
	var e := b % 4
	var f := (b + 8) / 25
	var g := (b - f + 1) / 3
	var h := (19 * a + b - d - g + 15) % 30
	var i := c / 4
	var k := c % 4
	var l := (32 + 2 * e + 2 * i - h - k) % 7
	var m := (a + 11 * h + 22 * l) / 451
	var month := (h + l - 7 * m + 114) / 31
	var day := ((h + l - 7 * m + 114) % 31) + 1
	var easter := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 12})
	var t := Time.get_datetime_dict_from_unix_time(easter - 52 * 86400)
	return int(t["year"]) * 10000 + int(t["month"]) * 100 + int(t["day"])


static func describe_state(s: Dictionary) -> String:
	var pos: Vector3 = s.get("pos", Vector3.ZERO)
	return "%s %02d:%02d day %d%s, %.0f km/h%s at %.0f, %.0f" % [s.get("look", "?"), int(s.get("hour", 0.0)),
			int(fmod(float(s.get("hour", 0.0)), 1.0) * 60.0), int(s.get("weekday", 0)),
			", rain" if bool(s.get("rain", false)) else "", float(s.get("kmh", 0.0)),
			", flying %.0f m up" % float(s.get("alt", 0.0)) if bool(s.get("flying", false)) else "", pos.x, pos.z]


# --- the record --------------------------------------------------------------------------

func is_found(id: String) -> bool:
	return wallet != null and wallet.eggs.has(id)


func found_total() -> int:
	var n := 0
	for e in eggs:
		n += int(is_found(str(e["id"])))
	return n


## The day an egg was found (yyyymmdd), 1 if before MW-6, 0 if not found.
func found_day(id: String) -> int:
	return int(wallet.eggs.get(id, 0)) if wallet != null else 0


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


## The reward of egg `e` in words, Polish and English: ["+20 ★ · PÓŁNOC FM: Sód", ...].
func reward_text(e: Dictionary) -> Array:
	var r: Dictionary = e.get("reward", {})
	var pl := PackedStringArray()
	var en := PackedStringArray()
	if int(r.get("respect", 0)) > 0:
		pl.append("+%d szacunku" % int(r["respect"]))
		en.append("+%d respect" % int(r["respect"]))
	if int(r.get("track", 0)) > 0:
		pl.append("utwór PÓŁNOC FM")
		en.append("a PÓŁNOC FM track")
	if str(r.get("then", "")) != "":
		pl.append("karta z kasety")
		en.append("a then card")
	if str(r.get("kadr", "")) != "":
		pl.append("nowy kadr")
		en.append("a new photo spot")
	return [" · ".join(pl), " · ".join(en)]


## An egg found for the first time: the save, its reward, the note card, the sound and the buzz.
## False if it was in the notebook already (or isn't an egg).
func record(id: String, date := 0) -> bool:
	if wallet == null or not by_id.has(id) or is_found(id):
		return false
	var e := eggs[by_id[id]]
	var day := date if date > 0 else today()
	wallet.find_egg(id, day)
	var r: Dictionary = e.get("reward", {})
	var extra := PackedStringArray()
	if int(r.get("respect", 0)) > 0 or int(r.get("zl", 0)) > 0:
		wallet.pay(int(r.get("zl", 0)), int(r.get("respect", 0)))
	var n := int(r.get("track", 0))
	if n > 0 and radio != null:
		var opened := n if radio.unlock_track(n, "egg %s" % id) else 0
		if opened == 0:
			# MW-6 default (Open Question): the egg's track was open already (E31's track 2 is
			# free from the start), so the egg opens the lowest locked one instead.
			var next: int = radio.next_locked()
			if next > 0 and radio.unlock_track(next, "egg %s (track %d was open)" % [id, n]):
				opened = next
		extra.append("track %d" % opened if opened > 0 else "track %d (all open)" % n)
	var then := str(r.get("then", ""))
	if then != "" and tape != null:
		tape.stamp(then, day)
		extra.append("then card %s" % then)
	if str(r.get("kadr", "")) != "":
		extra.append("kadr %s open" % r["kadr"])
	var name: Array = e["name"]
	print("egg: found %s %s (%d/%d): +%d respect%s" % [id, name[0], found_total(), eggs.size(), int(r.get("respect", 0)),
			(", " + ", ".join(extra)) if not extra.is_empty() else ""])
	if hud != null:
		var words := reward_text(e)
		hud.show_note("SEKRET %d/%d · EASTER EGG" % [found_total(), eggs.size()],
				"%s\n%s\n%s" % [name[0], name[1] if str(name[1]) != str(name[0]) else words[1], words[0]], EGG_COLOUR)
		hud.notebook_changed()
	if blip.is_valid():
		blip.call()
	Input.vibrate_handheld(30, 0.4)
	found.emit(id)
	return true


## --found-eggs=all|none|<id>,...: the record for a test run, in memory (no rewards; use with
## --nosave).
func preset(spec: String) -> void:
	if wallet == null:
		return
	for part in spec.split(",", false):
		if part == "none":
			wallet.eggs.clear()
		elif part == "all":
			for e in eggs:
				wallet.eggs[str(e["id"])] = today()
		elif part == "reachable":
			for id in reachable():
				wallet.eggs[id] = today()
		elif by_id.has(part):
			wallet.eggs[part] = today()
	print("egg: --found-eggs=%s: %d/%d in the notebook" % [spec, found_total(), eggs.size()])
