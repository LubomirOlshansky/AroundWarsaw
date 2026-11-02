extends RefCounted
## Zagłębie Kebabowe (docs/design/zaglebie-kebabowe.md; F, 2026-11-02): the cluster of kebab shops
## on Al. Solidarności by Kino Femina, with a craft-kebab spot, and the delivery quests that start
## from there. Data and rules only (no nodes): jobs.gd adds the five stands (`extra_pois`) and
## applies the orders' twists (`pay`, `fair`, `heat_slow`), storefronts.gd hangs the neon fascias
## (`VENUE_LL`, `FEMINA`), dialogue.json has the words (`kebab_vendor` tags `zag_*`, group `zaglebie`).
## Every name is our parody (brand_denylist.json carries the real ones); Kino Femina is a real place.
##
## The Szlak Szpili (the Skewer Trail): one delivery from each of the five shops pays a bonus once.
## Dialogue Manager: not used. The only choice is the craft shop's two-button job card (wait for
## the hand-carved kebab or take the plain one), the same card shape as every job's GO / NOT NOW;
## the rest is single vendor lines (`line()` bags), which the dialogue-scenes skill keeps in JSON.

const Notebook := preload("res://scripts/notebook.gd")

## Kino Femina, Al. Solidarności 115 (OSM / the cinema's address): its fascia sign. [lat, lon].
const FEMINA_ID := "zag_femina"
const FEMINA := [52.24205, 20.99459]
## The five shops, west to east along the south pavement of Al. Solidarności (their doors 10 m off
## the road's centre line). id, tag (the vendor's line tag and the stand's key), board (the name under
## KEBAB on the stand), lines (the neon fascia), tube colour, ll (the door, [lat, lon]), pay (the
## fare's multiplier), fair (the "fair time" multiplier: more is a more forgiving heat), min_road
## (shortest trip it will send, m), night (extra multiplier after dark).
const SHOPS := [
	{"id": "zag_krol", "tag": "zag_krol", "board": "KRÓL MAZOWSZA", "lines": ["KEBAB KRÓL", "MAZOWSZA"],
		"tube": Color(1.0, 0.72, 0.12), "ll": [52.24181, 20.99398], "pay": 1.25, "fair": 1.0, "min_road": 700.0, "night": 1.0,
		"set": "Zestaw Królewski"},
	{"id": "zag_stambul", "tag": "zag_stambul", "board": "STAMBUŁ 24", "lines": ["STAMBUŁ 24"],
		"tube": Color(0.1, 0.9, 1.0), "ll": [52.24194, 20.99434], "pay": 1.0, "fair": 1.0, "min_road": 0.0, "night": 1.25,
		"set": "Nocna Porcja"},
	{"id": "zag_pasza", "tag": "zag_pasza", "board": "DONER PASZA", "lines": ["DONER", "PASZA"],
		"tube": Color(1.0, 0.1, 0.4), "ll": [52.24214, 20.99495], "pay": 1.0, "fair": 0.8, "min_road": 0.0, "night": 1.0,
		"set": "Szybki Pasza"},
	{"id": "zag_erdal", "tag": "zag_erdal", "board": "U WUJKA ERDALA", "lines": ["U WUJKA", "ERDALA"],
		"tube": Color(0.2, 1.0, 0.45), "ll": [52.24225, 20.99529], "pay": 1.0, "fair": 1.0, "min_road": 0.0, "night": 1.0,
		"set": "Rodzinny", "tip": 2.0},
	{"id": "zag_rozen", "tag": "zag_rozen", "board": "ZAKWAS I ROŻEN", "lines": ["ZAKWAS", "I ROŻEN", "CRAFT KEBAB"],
		"tube": Color(1.0, 0.85, 0.35), "ll": [52.24235, 20.99559], "pay": 1.0, "fair": 1.0, "min_road": 0.0, "night": 1.0,
		"set": "Rzemieślniczy", "craft": true},
]
## The craft kebab: wait this long (s) for the hand-carved one; it pays CRAFT_PAY times and keeps its
## heat CRAFT_FAIR times longer. Taking the plain one pays as any shop.
const CRAFT_WAIT := 6.0
const CRAFT_PAY := 1.6
const CRAFT_FAIR := 1.5
## Szlak Szpili: the bonus once all five shops have delivered, and the save key (a comma list).
const TRAIL_ZL := 120
const TRAIL_RESPECT := 25
const KEEP_TRAIL := "zaglebie_trail"
const KEEP_SEEN := "zaglebie_seen"
## The welcome line plays once when the car comes this near Femina (m).
const WELCOME_R := 80.0
## Stand body: the generic kiosk's width, so jobs.gd `_kerb` leaves the same room.
const STAND_W := 6.0


## The shop with `tag` ({} when it is not one of ours).
static func shop(tag: String) -> Dictionary:
	for s: Dictionary in SHOPS:
		if s["tag"] == tag:
			return s
	return {}


static func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s: Dictionary in SHOPS:
		out.append(s["id"])
	return out


## The `kebab` pois jobs.gd adds to the map's own (same shape as the bake's: x, z, door, w), with the
## shop's tag; `origin` is centrum.json's [lat, lon].
static func extra_pois(origin: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in SHOPS:
		var ll: Array = s["ll"]
		var p := Notebook.project(origin, float(ll[0]), float(ll[1]))
		out.append({"k": "kebab", "x": p.x, "z": p.y, "door": [p.x, p.y], "w": STAND_W, "zag": s["tag"]})
	return out


## Femina's point on the map (m).
static func femina_at(origin: Array) -> Vector2:
	return Notebook.project(origin, float(FEMINA[0]), float(FEMINA[1]))


## The fare's multiplier for an order from `tag`'s shop: its own, the night's, and the craft kebab's
## `premium` (the player waited for it). 1.0 for any other stand.
static func pay(tag: String, night: bool, premium: bool) -> float:
	var s := shop(tag)
	if s.is_empty():
		return 1.0
	var m := float(s["pay"])
	if night:
		m *= float(s["night"])
	if premium:
		m *= CRAFT_PAY
	return m


## The order's fair time multiplier (a bigger one lets the kebab stay hot for longer).
static func fair(tag: String, premium: bool) -> float:
	var s := shop(tag)
	if s.is_empty():
		return 1.0
	return float(s["fair"]) * (CRAFT_FAIR if premium else 1.0)


## The tip's multiplier for a hot kebab (Wujek Erdal's family orders tip double).
static func tip(tag: String) -> float:
	var s := shop(tag)
	return float(s.get("tip", 1.0)) if not s.is_empty() else 1.0


## The trail as a list of shop ids from the save's string.
static func trail_done(saved: String) -> PackedStringArray:
	var out := PackedStringArray()
	for id in saved.split(",", false):
		if not out.has(id):
			out.append(id)
	return out


## Adds `tag`'s shop to the trail; returns [the new saved string, true when this completes the trail].
static func trail_add(saved: String, tag: String) -> Array:
	var done := trail_done(saved)
	var was_all := done.size() >= SHOPS.size()
	if not shop(tag).is_empty() and not done.has(tag):
		done.append(tag)
	var all := true
	for s: Dictionary in SHOPS:
		if not done.has(s["tag"]):
			all = false
	return [",".join(done), all and not was_all]

