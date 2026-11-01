extends SceneTree
## The two quest lines (quest_lines.gd, G12): car quests hide while flying, heli-only quests always
## show; a flying player's calls turn into roof calls and a driver's roof calls into park calls
## (the street and river kinds stay); `prefer` never returns an empty list; a heli-only rescue
## takes the HELI colour and a rescue the car reaches the amber pickup; the ride start button's
## reach is wider than the stop ring (G10). Prints `check_quest_lines: OK`, exits 1 on a problem.
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
	if _problems == 0:
		print("check_quest_lines: OK")
		quit(0)
	else:
		quit(1)
