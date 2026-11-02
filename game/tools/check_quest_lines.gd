extends SceneTree
## The two quest lines (quest_lines.gd, G12): car quests hide while flying, heli-only quests always
## show; a flying player's calls turn into roof calls and a driver's roof calls into park calls
## (the street and river kinds stay); `prefer` never returns an empty list; a heli-only rescue
## takes the HELI colour and a rescue the car reaches the amber pickup; the ride start button's
## reach is wider than the stop ring (G10). G12 part 2, the ZADANIA lists: each tab lists only its
## line, requests first, then places nearest first, one per group (three cassettes), at most
## MAX_ROWS; the distance text and compass point; the pin is reached within PIN_REACH. Prints `check_quest_lines: OK`, exits 1 on a problem.
##   godot --headless --path game --script res://tools/check_quest_lines.gd

const Lines := preload("res://scripts/quest_lines.gd")
const Missions := preload("res://scripts/missions.gd")
const Rides := preload("res://scripts/rides.gd")
const StopAssist := preload("res://scripts/stop_assist.gd")

var _problems := 0


func _expect(what: String, ok: bool) -> void:
	if not ok:
		_problems += 1
		print("check_quest_lines: %s" % what)


func _initialize() -> void:
	_expect("car quests show while driving", Lines.shows(Lines.Line.CAR, false))
	_expect("car quests hide while flying", not Lines.shows(Lines.Line.CAR, true))
	_expect("heli quests show while flying", Lines.shows(Lines.Line.HELI, true))
	_expect("a taken heli quest still shows to a driver", Lines.shows(Lines.Line.HELI, false))
	_expect("heli-only mission is HELI", Lines.of_mission({"heli": true}) == Lines.Line.HELI)
	_expect("a car-reachable mission is CAR", Lines.of_mission({"heli": false}) == Lines.Line.CAR)
	for k in 4:
		var fly := Lines.kind_for(k, true)
		var drive := Lines.kind_for(k, false)
		_expect("flying never gets street or park (kind %d -> %d)" % [k, fly], fly == 1 or fly == 2)
		_expect("driving never gets a roof (kind %d -> %d)" % [k, drive], drive != 1)
	var a := {"heli": true}
	var b := {"heli": false}
	_expect("flying prefers heli places", Lines.prefer([a, b], true) == [a])
	_expect("driving prefers car places", Lines.prefer([a, b], false) == [b])
	_expect("an empty preferred half falls back to the list", Lines.prefer([a], false) == [a])
	_expect("heli colour differs from the pickup and the ride", Lines.HELI_COLOUR != Missions.PICKUP_COLOUR \
			and Lines.HELI_COLOUR != Rides.COLOUR)
	_expect("START RIDE reaches beyond the stop ring", Rides.START_REACH > StopAssist.RING)
	_lists()
	if _problems == 0:
		print("check_quest_lines: OK")
		quit(0)
	else:
		quit(1)


## G12 part 2: the lists' rules (quest_lines.gd `rows`, `far_text`, `pin_reached`).
func _lists() -> void:
	var c := Color.WHITE
	var e: Array = [
		Lines.entry("k1", "kebab", Lines.Line.CAR, "Kebab A", "Kebab A", Vector2(0, -900), c),
		Lines.entry("k2", "kebab", Lines.Line.CAR, "Kebab B", "Kebab B", Vector2(0, -300), c),
		Lines.entry("s1", "sloik", Lines.Line.CAR, "Słoiki", "Jars", Vector2(1500, 0), c),
		Lines.entry("ride", "ride", Lines.Line.CAR, "Podwózka", "Ride", Vector2.INF, c, "ride"),
		Lines.entry("g", "garage", Lines.Line.CAR, "Warsztat", "Garage", Vector2(-50, 0), c),
		Lines.entry("call", "call", Lines.Line.HELI, "Wezwanie", "Call", Vector2.INF, c, "call"),
	]
	for i in 5:
		e.append(Lines.entry("c%d" % i, "cassette", Lines.Line.HELI, "Kaseta", "Cassette", Vector2(100.0 * (i + 1), 0), c))
	var car := Lines.rows(e, Lines.Line.CAR, Vector2.ZERO)
	var ids := car.map(func(r: Dictionary) -> String: return str(r["id"]))
	_expect("car tab: requests first, then nearest, one kebab (%s)" % [ids], ids == ["ride", "g", "k2", "s1"])
	var heli := Lines.rows(e, Lines.Line.HELI, Vector2.ZERO)
	var hids := heli.map(func(r: Dictionary) -> String: return str(r["id"]))
	_expect("heli tab: the call, then three nearest cassettes (%s)" % [hids], hids == ["call", "c0", "c1", "c2"])
	_expect("no car quest on the heli tab", heli.all(func(r: Dictionary) -> bool: return int(r["line"]) == Lines.Line.HELI))
	_expect("at most MAX_ROWS rows", Lines.rows(e, Lines.Line.CAR, Vector2.ZERO, 2).size() == 2 and Lines.MAX_ROWS <= 4)
	_expect("a request has no distance", car[0]["far"] == ["", ""])
	_expect("300 m north reads '300 m płn.' / '300 m N' (%s)" % [car[2]["far"]], car[2]["far"] == ["300 m płn.", "300 m N"])
	_expect("1.5 km east reads '1,5 km wsch.' / '1.5 km E' (%s)" % [car[3]["far"]], car[3]["far"] == ["1,5 km wsch.", "1.5 km E"])
	_expect("south-west is 5", Lines.compass(Vector2.ZERO, Vector2(-10, 10)) == 5)
	_expect("the pin is reached within PIN_REACH", Lines.pin_reached(e[4], Vector2(-50 + Lines.PIN_REACH - 1.0, 0)))
	_expect("the pin is not reached farther", not Lines.pin_reached(e[4], Vector2(-50 + Lines.PIN_REACH + 5.0, 0)))
	_expect("a request is never 'reached'", not Lines.pin_reached(e[3], Vector2.ZERO))
	_expect("no pin is never reached", not Lines.pin_reached({}, Vector2.ZERO))
