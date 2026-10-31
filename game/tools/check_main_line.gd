extends SceneTree
## The main line (main_line.gd, docs/design/main-line.md): its step from the facts, without the map.
## Checks that:
## - during the guide the guide's target or arrow is the main line (chapter 1) and with neither the
##   step says "just drive" with no marker;
## - after the guide: a race for the next rung is the main line's target; an open rung points at its
##   rival's dot; a locked one asks for respect with no marker (the side quests are the way);
## - the final: respect first, then "at night" with no marker by day, the start by night, its race
##   in chapter 3; then the jobs left to the end card (Polish plurals), then done (no line);
## - every line is Polish and English, at most MAX_CHARS characters (the full map's goal card);
## - the pacing (the retune of 2026-10-31): race wins alone stop at rung 2, and the side quests'
##   respect the ladder needs in all (the final's threshold less six wins) is SIDE_MIN-SIDE_MAX.
##   godot --headless --path game --script res://tools/check_main_line.gd

const MainLine := preload("res://scripts/main_line.gd")
const Ladder := preload("res://scripts/ladder.gd")
const MAX_CHARS := 60
const SIDE_MIN := 150
const SIDE_MAX := 300

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _words(st: Dictionary) -> void:
	for k in ["pl", "en"]:
		var t := str(st[k])
		_expect(t.length() <= MAX_CHARS, "%s line too long (%d): %s" % [k, t.length(), t])
	_expect((str(st["pl"]) == "") == (str(st["en"]) == ""), "a line in one language only: %s" % [st])


func _step(f: Dictionary) -> Dictionary:
	var st := MainLine.step(f)
	_words(st)
	return st


func _initialize() -> void:
	var here := Vector2(10, 20)
	# Chapter 1: the guide.
	var st := _step({"guide": true, "target": here, "target_main": true})
	_expect(st["id"] == "guide_target" and st["chapter"] == 1 and st["at"] == here, "guide target: %s" % [st])
	st = _step({"guide": true, "guide_at": here, "guide_word": "KEBAB"})
	_expect(st["id"] == "guide_kebab" and st["at"] == here and str(st["pl"]).contains("KEBAB"), "guide arrow: %s" % [st])
	st = _step({"guide": true})
	_expect(st["id"] == "guide" and st["at"] == Vector2.INF, "guide idle: %s" % [st])
	# A side job during the guide is not passed as main by main.gd: target_main false.
	st = _step({"guide": true, "target": here, "target_main": false})
	_expect(st["id"] == "guide" and st["at"] == Vector2.INF, "guide with a side target: %s" % [st])
	# Chapter 2: the ladder.
	var rival := Vector2(-300, 50)
	st = _step({"next": 1, "open": true, "rival": "Słoik z Radomia", "rival_at": rival})
	_expect(st["id"] == "rival" and st["chapter"] == 2 and st["at"] == rival and str(st["en"]).contains("Słoik"), "open rung: %s" % [st])
	st = _step({"next": 2, "open": false, "respect": 180, "need": 220, "rival": "Bulwar Bartek", "rival_at": rival})
	_expect(st["id"] == "respect" and st["at"] == Vector2.INF and str(st["pl"]).contains("180/220"), "locked rung: %s" % [st])
	st = _step({"next": 2, "open": true, "rival": "Bulwar Bartek", "target": here, "target_main": true})
	_expect(st["id"] == "race" and st["at"] == here, "next rung's race: %s" % [st])
	st = _step({"next": 2, "open": true, "rival": "Bulwar Bartek", "rival_at": rival, "target": here, "target_main": false})
	_expect(st["id"] == "rival" and st["at"] == rival, "a side target keeps the rival's marker: %s" % [st])
	# Chapter 3: the final.
	st = _step({"next": Ladder.FINAL, "open": false, "respect": 700, "need": Ladder.FINAL_RESPECT})
	_expect(st["id"] == "respect" and st["chapter"] == 3 and st["at"] == Vector2.INF, "final locked: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": false, "final_at": here})
	_expect(st["id"] == "wait_night" and st["at"] == Vector2.INF, "final by day: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": true, "final_at": here})
	_expect(st["id"] == "final" and st["at"] == here, "final by night: %s" % [st])
	st = _step({"next": Ladder.FINAL, "open": true, "night": true, "target": rival, "target_main": true})
	_expect(st["id"] == "final_race" and st["at"] == rival, "final race: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 7, "end_jobs": 10})
	_expect(st["id"] == "jobs" and str(st["pl"]).contains("3 zlecenia") and str(st["en"]).contains("3 more jobs"), "jobs left: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 9, "end_jobs": 10})
	_expect(str(st["pl"]).contains("1 zlecenie") and str(st["en"]).contains("1 more job "), "one job left: %s" % [st])
	st = _step({"next": Ladder.FINAL + 1, "jobs": 12, "end_jobs": 10, "end_seen": true})
	_expect(st["id"] == "done" and st["pl"] == "" and st["at"] == Vector2.INF, "done: %s" % [st])
	for n: int in [1, 2, 4, 5, 12, 13, 22, 25]:
		var want := "zlecenie" if n == 1 else ("zlecenia" if n in [2, 4, 22] else "zleceń")
		_expect(MainLine.jobs_word(n) == want, "jobs_word(%d) = %s" % [n, MainLine.jobs_word(n)])
	# The pacing: wins alone (+100 each) open rungs 0 and 1 only.
	var respect := 0
	var stuck := -1
	for i in Ladder.RUNGS.size():
		if respect < Ladder.threshold(i):
			stuck = i
			break
		respect += 100
	_expect(stuck == 2, "race wins alone stop at rung %d (want 2)" % stuck)
	var side := Ladder.FINAL_RESPECT - 100 * Ladder.RUNGS.size()
	_expect(side >= SIDE_MIN and side <= SIDE_MAX, "side quests' respect to the final: %d (want %d-%d)" % [side, SIDE_MIN, SIDE_MAX])
	if _problems == 0:
		print("main_line: OK (side respect to the final %d)" % side)
		quit(0)
	else:
		print("main_line: %d problems" % _problems)
		quit(1)
