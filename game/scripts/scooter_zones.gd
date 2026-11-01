extends RefCounted
## Trend follow-up (docs/design/trends-2025-26.md): the 12 km/h e-scooter streets of Warsaw's rules
## of 3 June 2026: Złota, Zgody, Bracka and Plac Centralny. Four discs on the map (centres
## *guess*, from the street names; radius 70 m). The rule is for scooters, so the car is not
## capped; main.gd shows the zone's toast on entering one (once per minute), and the Leżaks lie
## about in them as everywhere. Names are the streets', the joke is the sign's (dialogue.json).

const Notebook := preload("res://scripts/notebook.gd")

const RADIUS := 70.0
## Seconds between two toasts for the same disc.
const COOLDOWN := 60.0
const ZONES := {
	"zlota": [52.2315, 21.0043, "Złota", "Golden Street"],
	"zgody": [52.2349, 21.0207, "Zgody", "Zgoda Street"],
	"bracka": [52.2312, 21.0200, "Bracka", "Bracka Street"],
	"plac_centralny": [52.2284, 21.0036, "Plac Centralny", "Central Square"],
}

var _centres := {}


func _init(origin := [52.234, 21.024]) -> void:
	for id: String in ZONES:
		var z: Array = ZONES[id]
		_centres[id] = Notebook.project(origin, float(z[0]), float(z[1]))


## The zone id at (x, z), or "" outside all four.
func at(x: float, z: float) -> String:
	var p := Vector2(x, z)
	for id: String in _centres:
		if p.distance_to(_centres[id]) <= RADIUS:
			return id
	return ""


## The toast for entering zone `id`: [Polish, English].
static func toast_for(id: String) -> Array:
	var z: Array = ZONES[id]
	return ["Strefa 12 km/h: %s. Hulajnogi zwalniają, ty też możesz." % z[2],
			"12 km/h zone: %s. Scooters slow down; you can too." % z[3]]
