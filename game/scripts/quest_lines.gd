extends RefCounted
## Two quest lines (G12, 2026-11-02): CAR (kebab, Podwózka, couriers, races) and HELI (rescues only
## the helicopter reaches). F asked that flying shows helicopter quests and driving car quests, each
## with its own marker colour. The main line stays one path and is not touched here.
## A rescue the car can also reach (street, park, shore) is not heli-only: it stays on offer in
## both vehicles and keeps its amber pickup; only heli-only calls take the HELI colour.

enum Line { CAR, HELI }

## The marker colour of heli-only quests (a violet that neither the amber pickup, the teal ride
## nor the blue/green drop-offs use, colour-safe mode included).
const HELI_COLOUR := Color("#b48cff")


## The line of a rescue call (`heli` is the mission's flag).
static func of_mission(m: Dictionary) -> int:
	return Line.HELI if bool(m.get("heli", false)) else Line.CAR


## True when a quest of `line` shows its marker and arrow for a player who is `flying`: car quests
## stay out of the helicopter's way; heli quests are always shown once taken, so a driver who
## accepted one is still told where to go (and to press HELI).
static func shows(line: int, flying: bool) -> bool:
	return line == Line.HELI or not flying


## Which places a new rescue call may pick from, for a player who is `flying`: flying prefers the
## heli-only places, driving the ones the car reaches. Returns `list` itself when the preferred
## half is empty, so a call is never lost.
static func prefer(list: Array, flying: bool) -> Array:
	var keep := list.filter(func(p: Dictionary) -> bool: return bool(p.get("heli", false)) == flying)
	return keep if not keep.is_empty() else list


## The rescue kind a new call takes for a player who is `flying` (kinds as missions.gd `Kind`:
## 0 street, 1 roof, 2 river, 3 park): flying turns the street and park calls into roof calls
## (the helicopter's own), driving turns roof calls into park calls.
static func kind_for(kind: int, flying: bool) -> int:
	if flying and (kind == 0 or kind == 3):
		return 1
	if not flying and kind == 1:
		return 3
	return kind
