extends SceneTree
## Loop 3h slice 4: the guided first 10 minutes (first10.gd), without the map. Checks that:
## - the beats are 6.2's ten in order, each window holds its 6.2 time and the windows follow on;
## - `guide_due` only on a fresh save (a job, złoty, a rung or a finished guide: never);
## - three players played on a synthetic clock through `decide` and `met` (the director's rules)
##   with a toy city (a delivery takes 75 s, a race 60 s, a rescue 90 s, ...): an ordinary player
##   (touches at once, orders at 0:35) gets every beat inside its window, the stand's arrow and the
##   race fired, the order met; a wanderer (never touches, never orders, says no to Halina) still
##   gets the finger at 4 s, the arrow at 10 s, Halina at RACE_LATEST, the trap armed at
##   TRAP_LATEST, the call at RESCUE_LATEST, the helicopter at HELI_LATEST, the tape and Powiśle
##   arrows, no garage without earnings and the guide's end at GUIDE_END; a player busy with a job
##   from 3:40 to 5:30 gets the call only after it (beats wait); the replay's scripted order fires
##   at ORDER_AT; a helicopter-only call unlocks the helicopter at once; `judge` flags a late, a
##   missing and an early-fired beat;
## - the first race's rubber band (rivals.gd `first_band`) in a 1-D race of 800 m: an ordinary
##   player (34 km/h on average) wins by 0.5 to 4 s, a fast one wins, a slow one (22 km/h) loses
##   by little or wins by little, one who stops for a minute loses; Halina's plain ladder pace
##   would have beaten the ordinary player (the band is needed);
## - the words (the director's, Halina's, the end card's) in Polish and English, each line at most
##   70 characters (the card's at most 100), the repo's name as README has it.
##   godot --headless --path game --script res://tools/check_first10.gd

const First10 := preload("res://scripts/first10.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Ladder := preload("res://scripts/ladder.gd")
const Wallet := preload("res://scripts/wallet.gd")
const STEP := 0.2

var _problems := 0
var _summary: Array[String] = []


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _initialize() -> void:
	_data()
	_due()
	_ordinary()
	_wanderer()
	_busy()
	_scripted()
	_judge()
	_band()
	_words()
	if _problems == 0:
		print("first10: OK (%s)" % ", ".join(_summary))
		quit(0)
	else:
		print("check_first10: %d problem(s)" % _problems)
		quit(1)


func _data() -> void:
	var want := ["finger", "stand", "order", "race", "trap", "rescue", "heli", "tape", "powisle", "garage"]
	_expect(First10.BEATS == want, "the beats: %s" % [First10.BEATS])
	# DEMO.md 6.2's times (the helicopter comes with the rescue, about a minute after the call).
	var times := {"finger": 5.0, "stand": 15.0, "order": 30.0, "race": 90.0, "trap": 180.0, "rescue": 240.0,
			"heli": 300.0, "tape": 360.0, "powisle": 480.0, "garage": 600.0}
	var last := 0.0
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		_expect(w.x <= times[id] and times[id] <= w.y, "%s's window %s holds 6.2's %.0f s" % [id, w, times[id]])
		_expect(w.x >= last - 120.0 and w.x < w.y, "%s's window %s follows on" % [id, w])
		last = w.x
	_summary.append("10 beats")


func _fresh() -> Wallet:
	var w := Wallet.new()
	w.persistent = false
	return w


func _due() -> void:
	var w := _fresh()
	_expect(First10.guide_due(w), "a fresh save gets the guide")
	w.intro["finger"] = 20261031
	_expect(First10.guide_due(w), "a save with only the finger seen gets the guide again")
	w.intro["done"] = 20261031
	_expect(not First10.guide_due(w), "a finished guide never comes back")
	w.intro.clear()
	w.jobs["kebab"] = 1
	_expect(not First10.guide_due(w), "a job done: no guide")
	w.jobs.clear()
	w.jobs["race"] = 1
	w.zl = 60
	_expect(not First10.guide_due(w), "złoty in hand: no guide")
	w.zl = 0
	w.jobs.clear()
	w.ladder["halina"] = 20261031
	_expect(not First10.guide_due(w), "a rung beaten: no guide")
	_expect(not First10.guide_due(null), "no wallet: no guide")
	w.free()
	_summary.append("fresh saves only")


## A toy city for `decide` and `met`: the player's plan and how long things take.
class Toy:
	var t := 0.0
	var input_at := INF
	var order_at := INF       # pulls into the stand (or the director's scripted order)
	var deliver_s := 75.0
	var says_no := false      # declines Halina
	var job_from := INF       # an extra job of the player's own
	var job_to := INF
	var tape_after := 50.0    # after the tape's arrow, the tape is played (INF: never)
	var scripted := false
	var heli_call_at := INF
	var rescue_ok := true
	# the state
	var ordered := false
	var delivered_t := -1.0
	var busy_until := -1.0
	var calling_until := -1.0
	var raced := false
	var race_end := INF
	var trap := false
	var rang := false
	var rang_at := INF
	var rescued := false
	var rescue_end := INF
	var tape := false
	var tape_at := INF
	var powisle := false
	var garage := false
	var garage_at := INF
	var earned := false

	func facts() -> Dictionary:
		var busy := t < busy_until or (t >= job_from and t < job_to) or t < calling_until
		return {"input": t >= input_at, "free": not busy, "ordered": ordered, "delivered_t": delivered_t,
				"raced": raced, "calling": t < calling_until, "race_next": 0.0, "trap": trap, "rang": rang,
				"rescued": rescued, "heli_call": t >= heli_call_at and not rescued, "tape": tape,
				"powisle": powisle, "garage": garage, "earned": earned, "scripted": scripted}

	## The world moves on by itself.
	func step() -> void:
		if not ordered and t >= order_at:
			ordered = true
			busy_until = t + deliver_s
		if ordered and delivered_t < 0.0 and t >= busy_until:
			delivered_t = t
			earned = true
		if race_end != INF and t >= race_end and not raced:
			raced = true
			earned = true
		if raced and not trap and t >= race_end + 6.0:
			trap = true  # police.gd arms it FIRST_DELAY s after the race
		if not rang and t >= rang_at:
			rang = true
			busy_until = t + 90.0
			rescue_end = t + 90.0
		if rang and not rescued and t >= rescue_end and rescue_ok:
			rescued = true
			earned = true
		if not tape and t >= tape_at:
			tape = true
			powisle = true  # the boulevards are in Powiśle
		if not garage and t >= garage_at:
			garage = true

	## The director fired `id`: what follows in the toy.
	func on_fire(id: String) -> void:
		match id:
			"order":
				order_at = t
			"race":
				calling_until = t + (20.0 if says_no else 8.0)
				if not says_no:
					race_end = t + 8.0 + 60.0
					busy_until = race_end
			"rescue":
				rang_at = t + 12.0
			"tape":
				tape_at = t + tape_after
			"garage":
				garage_at = t + 0.3


## Plays `toy` for `seconds` through the director's rules: [fired (id -> s), how (id -> way)].
func _play(toy: Toy, seconds: float) -> Array:
	var done := {}
	var ways := {}
	while toy.t < seconds:
		toy.step()
		var f := toy.facts()
		if not done.has("done"):
			for id in First10.met(f):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "met"
			for id in First10.decide(toy.t, f, done):
				if not done.has(id):
					done[id] = toy.t
					ways[id] = "fired"
					toy.on_fire(id)
		toy.t += STEP
	return [done, ways]


func _at(done: Dictionary, id: String) -> float:
	return float(done.get(id, -1.0))


func _ordinary() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the ordinary player: %s" % [bad])
	_expect(ways.get("finger") == "met" and _at(done, "finger") < 2.0, "a touch at 1 s: no finger (%s)" % ways.get("finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the stand's arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(ways.get("order") == "met" and absf(_at(done, "order") - 35.0) < 0.3, "the order met at 35 s: %.1f" % _at(done, "order"))
	_expect(ways.get("race") == "fired" and absf(_at(done, "race") - (110.0 + First10.RACE_AFTER)) < 0.5,
			"Halina %.0f s after the delivery: %.1f" % [First10.RACE_AFTER, _at(done, "race")])
	_expect(ways.get("trap") == "met", "the trap armed by the race, not the fallback: %s" % ways.get("trap"))
	_expect(ways.get("rescue") == "fired" and absf(_at(done, "rescue") - First10.RESCUE_AT) < 0.3, "the call let through at 3:45: %.1f" % _at(done, "rescue"))
	_expect(ways.get("heli") == "fired" and _at(done, "heli") > _at(done, "rescue") + 90.0, "the helicopter after the rescue: %.1f" % _at(done, "heli"))
	_expect(ways.get("powisle") == "met", "Powiśle discovered at the boulevards: %s" % ways.get("powisle"))
	_expect(ways.get("garage") == "fired" and absf(_at(done, "garage") - First10.GARAGE_AT) < 0.3, "the garage at 9:30: %.1f" % _at(done, "garage"))
	_expect(done.has("done") and _at(done, "done") < First10.GARAGE_AT + 2.0, "the guide ends at the garage: %.1f" % _at(done, "done"))
	_summary.append("ordinary %s" % _line(done))


func _wanderer() -> void:
	var toy := Toy.new()
	toy.says_no = true
	toy.tape_after = INF
	toy.rescue_ok = false
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("finger") == "fired" and absf(_at(done, "finger") - First10.FINGER_IDLE) < 0.3, "the finger at 4 s: %.1f" % _at(done, "finger"))
	_expect(ways.get("stand") == "fired" and absf(_at(done, "stand") - First10.STAND_AT) < 0.3, "the arrow at 10 s: %.1f" % _at(done, "stand"))
	_expect(not done.has("order"), "no order without the player (or the replay)")
	_expect(ways.get("race") == "fired" and absf(_at(done, "race") - First10.RACE_LATEST) < 0.3, "Halina at the fallback: %.1f" % _at(done, "race"))
	_expect(ways.get("trap") == "fired" and absf(_at(done, "trap") - First10.TRAP_LATEST) < 0.3, "the trap armed at its fallback: %.1f" % _at(done, "trap"))
	_expect(ways.get("rescue") == "fired" and absf(_at(done, "rescue") - First10.RESCUE_LATEST) < 0.3, "the call at its fallback: %.1f" % _at(done, "rescue"))
	_expect(ways.get("heli") == "fired" and absf(_at(done, "heli") - First10.HELI_LATEST) < 0.3, "the helicopter at its fallback: %.1f" % _at(done, "heli"))
	_expect(ways.get("tape") == "fired" and _at(done, "tape") >= First10.HELI_LATEST, "the tape's arrow after the helicopter: %.1f" % _at(done, "tape"))
	_expect(ways.get("powisle") == "fired" and _at(done, "powisle") >= First10.POWISLE_AT, "the Powiśle arrow: %.1f" % _at(done, "powisle"))
	_expect(not done.has("garage"), "no earnings: no garage (%.1f)" % _at(done, "garage"))
	_expect(absf(_at(done, "done") - First10.GUIDE_END) < 0.3, "the guide ends at GUIDE_END: %.1f" % _at(done, "done"))
	_summary.append("wanderer %s" % _line(done))


func _busy() -> void:
	var toy := Toy.new()
	toy.input_at = 1.0
	toy.order_at = 35.0
	toy.job_from = 220.0
	toy.job_to = 330.0
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	_expect(_at(done, "rescue") >= 330.0 - 0.01 and _at(done, "rescue") < 331.0, "the call waits for the job (220-330 s): %.1f" % _at(done, "rescue"))
	_summary.append("busy: the call at %.0f s" % _at(done, "rescue"))


func _scripted() -> void:
	var toy := Toy.new()
	toy.scripted = true
	var r := _play(toy, 1000.0)
	var done: Dictionary = r[0]
	var ways: Dictionary = r[1]
	_expect(ways.get("order") == "fired" and absf(_at(done, "order") - First10.ORDER_AT) < 0.3, "the replay's order at 15 s: %.1f" % _at(done, "order"))
	var bad := First10.judge(done, ways)
	_expect(bad.is_empty(), "the replay toy (no touch, the order scripted): %s" % [bad])
	var heli := Toy.new()
	heli.input_at = 1.0
	heli.heli_call_at = 100.0
	var h: Dictionary = _play(heli, 200.0)[0]
	_expect(absf(_at(h, "heli") - 100.0) < 0.3, "a helicopter-only call unlocks it at once: %.1f" % _at(h, "heli"))
	_summary.append("replay toy OK")


func _judge() -> void:
	var done := {}
	var ways := {}
	for id: String in First10.BEATS:
		var w: Vector2 = First10.WINDOWS[id]
		done[id] = (w.x + w.y) * 0.5
		ways[id] = "fired"
	_expect(First10.judge(done, ways).is_empty(), "every beat mid-window passes")
	done["race"] = 260.0
	done["tape"] = 100.0
	done.erase("garage")
	var bad := First10.judge(done, ways)
	_expect(bad.size() == 3, "late race, early tape, missing garage: %s" % [bad])
	ways["tape"] = "met"
	_expect(First10.judge(done, ways).size() == 2, "a tape met early is fine")


## A 1-D race of `road` m: the player at `speed` m/s (stopping `stop` s at the half), Halina from
## 12 m behind at factor × 13.9 m/s (a 50 km/h street), her factor from `band` every 0.2 s (her
## acceleration ~2 m/s²). Returns the player's lead at the finish in seconds (< 0: she won).
func _race(speed: float, band: bool, stop := 0.0, road := 800.0, pace := Rivals.FIRST_PACE) -> float:
	var me := road
	var her := road + 12.0
	var v := 0.0
	var dt := 0.05
	var t := 0.0
	var k := 0.0
	var factor := pace
	var stopped := 0.0
	while me > 0.0 and her > 0.0 and t < 900.0:
		k += dt
		if k >= 0.2:
			k = 0.0
			factor = Rivals.first_band(her, me) if band else pace
		var want := factor * 13.9
		v = move_toward(v, want, 2.0 * dt)
		her -= v * dt
		if stop > 0.0 and me < road * 0.5 and stopped < stop:
			stopped += dt
		else:
			me -= speed * dt
		t += dt
	if me <= 0.0:
		return maxf(her, 0.0) / maxf(v, 0.1)
	return -maxf(me, 0.0) / speed


func _band() -> void:
	_expect(absf(Rivals.first_band(500.0, 475.0) - Rivals.FIRST_PACE) < 0.001, "on the gap: her pace")
	_expect(Rivals.first_band(600.0, 400.0) == Rivals.FIRST_MAX, "far behind: she hurries")
	_expect(Rivals.first_band(400.0, 450.0) == Rivals.FIRST_MIN, "ahead: she waits")
	_expect(Rivals.first_band(100.0, 95.0) < Rivals.FIRST_MIN, "the last stretch, the player close: she lifts off")
	_expect(Rivals.first_band(300.0, 600.0) == Rivals.FIRST_PACE, "the player far behind: her plain pace")
	var ordinary := _race(9.5, true)
	var fast := _race(14.0, true)
	var slow := _race(6.0, true)
	var stops := _race(9.5, true, 60.0)
	var plain := _race(9.5, false, 0.0, 800.0, Ladder.pace(0).x)
	_expect(ordinary >= 0.5 and ordinary <= 4.0, "an ordinary player (34 km/h) wins by 0.5-4 s: %.1f s" % ordinary)
	_expect(fast > 0.0, "a fast player wins: %.1f s" % fast)
	_expect(absf(slow) <= 6.0, "a slow player (22 km/h) is within a few seconds: %.1f s" % slow)
	_expect(stops < 0.0, "a player who stops for a minute loses: %.1f s" % stops)
	_expect(plain < 0.0, "Halina's plain ladder pace beats the ordinary player: %.1f s" % plain)
	_summary.append("first race: ordinary +%.1f s, fast +%.1f s, slow %+.1f s, a stop %.0f s, unbanded %.0f s" % [ordinary, fast, slow, stops, plain])


func _words() -> void:
	var lines: Array = []
	for k in First10.LINES:
		lines.append(First10.LINES[k])
	for k in Rivals.FIRST_LINES:
		lines.append(Rivals.FIRST_LINES[k])
	for l: Array in lines:
		_expect(l.size() == 2 and str(l[0]) != "" and str(l[1]) != "" and str(l[0]) != str(l[1]), "Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 70, "at most 70 characters: %s (%d)" % [x, str(x).length()])
	for l: Array in [First10.END_TITLE, First10.END_BODY, First10.END_FREE]:
		_expect(l.size() == 2 and str(l[0]) != str(l[1]), "the end card in Polish and English: %s" % [l])
		for x in l:
			_expect(str(x).length() <= 100, "an end card line at most 100 characters: %s" % x)
	var w := First10.end_words()
	_expect(w.size() == 4 and First10.REPO in w[1], "the repo's name on the card (the shared line under the Polish)")
	_expect("OpenStreetMap" in w[1] and "GUGiK" in w[1] and "MIT" in w[1], "the credits on the card (the shared line)")
	var readme := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../README.md").simplify_path())
	if readme != "":
		_expect(("https://" + First10.REPO) in readme, "README names %s" % First10.REPO)
	_expect(First10.END_BUTTON.get_slice("|", 0) == "JEDŹ DALEJ" and First10.END_BUTTON.get_slice("|", 1) == "FREE ROAM", "the button: %s" % First10.END_BUTTON)
	_summary.append("words")


func _line(done: Dictionary) -> String:
	var parts := PackedStringArray()
	for id: String in First10.BEATS:
		parts.append("%s %s" % [id.substr(0, 2), str(roundi(_at(done, id))) if done.has(id) else "-"])
	return " ".join(parts)
