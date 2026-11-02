extends Node
## Loop 3h slice 1 (docs/DEMO.md 2.3, 6.2's "Powiśle discovered" beat, 6.3's progression;
## checklist G3): the demo's districts, from `data/districts.json` (polygons in map metres, in
## priority order: a point belongs to the first district with an area that holds it).
##
## - **Discovery.** Three times a second (`CHECK_EVERY`, a timer: nothing runs per frame) the
##   vehicle's district is looked up (≤ 9 bounding boxes, then the one or two polygons whose box
##   holds the point). The first time it enters a district: the "discovered" card (Polish above,
##   English below: "Odkryto: Powiśle" / "Powiśle discovered" and the district's line), +10
##   respect, the blip and a short buzz, kept in the save (wallet.gd `districts`, save v2). The
##   district the game starts in is discovered quietly (no card: DEMO A2, nothing between the
##   first tap and driving).
## - **The "?" marks.** In each discovered district, its first MARKS places not in the notebook
##   yet (nearest its label first) show as "?" on the minimap and the full map (notebook.gd
##   `extra_marks`; never their names). A place found makes room for the next.
## - **Completion** (`completion`): the notebook's places, the eggs (those that can be found: an
##   egg card with `waits` is left out) and the Syrenki found in the district, plus the jobs done
##   there up to its `jobs_goal` (wallet.gd `district_jobs`, counted where the job pays), over the
##   same things in all. The Syrenki are a hook for a later slice: `add_syrenka` lists one; there
##   are none yet, so they count 0 of 0.
## - **On the map**: the full map tints the districts not discovered yet, writes each
##   discovered district's name and % at its `label`, and lists them all in a card (full_map.gd
##   `set_districts`, fed by `view`).

## A district was discovered for the first time (its id); `card` false when quietly.
signal discovered(id: String, card: bool)

const Lang := preload("res://scripts/lang.gd")
const Access := preload("res://scripts/access.gd")
const DATA_PATH := "res://data/districts.json"
const PLACES_PATH := "res://data/places.json"
const EGGS_PATH := "res://data/eggs.json"
## Seconds between two district checks (3 Hz).
const CHECK_EVERY := 0.33
## "?" marks per discovered district.
const MARKS := 3
## Respect for a district discovered (*guess*: a notebook card gives 5, an egg 10).
const DISCOVER_RESPECT := 10
## The card's title colour: the full map's accent (never the collectibles' gold or the jobs').
const CARD_COLOUR := Color("#ffd23f")

## The districts in priority order: districts.json's fields plus `polys`
## (Array[PackedVector2Array]), `boxes` (Array[Rect2], one per polygon), `shapes` (the polygons
## less the earlier districts': what the full map fogs) and `at` (the label, Vector2), and the
## things that count towards completion: `places`, `eggs`, `syrenki` (Arrays of ids).
var districts: Array[Dictionary] = []
var by_id := {}
## The wallet (wallet.gd): `districts`, `district_jobs`, `notes`, `eggs`, `syrenki`.
var wallet: Node
var hud: CanvasLayer
## Place id -> its map point (Vector2; notebook.gd's resolved `at`, or the `near` hint
## projected when there is no map), for the "?" marks; ordered per district by `_order`.
var place_at := {}
## The vehicle now: [position (Vector3), km/h, flying, altitude, away] (notebook.gd's probe).
var probe: Callable
var blip: Callable
var log_on := false
## Microseconds spent in the checks since the start (the bench's "districts" line).
var spent_usec := 0
var ready_ok := false
## The district the vehicle is in now ("" outside them all).
var current := ""
## The first check discovers quietly (the start's own district).
var quiet_first := true
## --district=<id>: show that district's card at the first check (a screenshot aid).
var force_card := ""
var _t := 0.0
var _checked := false
## District id -> its places' ids, nearest the label first (the "?" marks' order).
var _order := {}


## Reads districts.json, places.json and eggs.json (no map). False if districts.json is missing
## or does not parse.
func load_data() -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not json is Dictionary:
		push_error("districts: %s does not parse" % DATA_PATH)
		return false
	districts.clear()
	by_id.clear()
	for d: Dictionary in json.get("districts", []):
		var district := d.duplicate(true)
		var polys: Array[PackedVector2Array] = []
		var boxes: Array[Rect2] = []
		for flat: Array in d.get("areas", []):
			var poly := PackedVector2Array()
			for i in range(0, flat.size() - 1, 2):
				poly.append(Vector2(float(flat[i]), float(flat[i + 1])))
			polys.append(poly)
			var box := Rect2(poly[0], Vector2.ZERO)
			for q in poly:
				box = box.expand(q)
			boxes.append(box)
		district["polys"] = polys
		district["boxes"] = boxes
		var label: Array = d.get("label", [0, 0])
		district["at"] = Vector2(float(label[0]), float(label[1]))
		district["places"] = []
		district["eggs"] = []
		district["syrenki"] = []
		by_id[str(d["id"])] = districts.size()
		districts.append(district)
	_cut_shapes()
	_load_ties()
	return true


## Each district's own `shapes`: its areas less every earlier district's (the priority order), so
## they never overlap (the full map's fog). The data keeps them free of holes (check_districts.gd
## checks that the shapes tile the map's bounds).
func _cut_shapes() -> void:
	var earlier: Array[PackedVector2Array] = []
	for d in districts:
		var mine: Array[PackedVector2Array] = []
		var polys: Array[PackedVector2Array] = d["polys"]
		for poly in polys:
			var parts: Array[PackedVector2Array] = [poly]
			for e in earlier:
				var next: Array[PackedVector2Array] = []
				for part in parts:
					next.append_array(Geometry2D.clip_polygons(part, e))
				parts = next
			mine.append_array(parts)
		d["shapes"] = mine
		earlier.append_array(polys)


## The places and eggs of each district (their `district` fields); an egg that waits for
## something not built yet does not count.
func _load_ties() -> void:
	var places: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_PATH)) if FileAccess.file_exists(PLACES_PATH) else null
	if places is Dictionary:
		for p: Dictionary in places.get("places", []):
			var d := str(p.get("district", ""))
			if by_id.has(d):
				(districts[by_id[d]]["places"] as Array).append(str(p["id"]))
	var eggs: Variant = JSON.parse_string(FileAccess.get_file_as_string(EGGS_PATH)) if FileAccess.file_exists(EGGS_PATH) else null
	if eggs is Dictionary:
		for e: Dictionary in eggs.get("eggs", []):
			var d := str(e.get("district", ""))
			if by_id.has(d) and not e.has("waits"):
				(districts[by_id[d]]["eggs"] as Array).append(str(e["id"]))


## Loads the data and takes the places' map points (`points`: place id -> Vector2; notebook.gd's
## `at`, INF where unresolved). False without the data.
func setup(points: Dictionary) -> bool:
	if not load_data():
		return false
	place_at = points
	for d in districts:
		var ids: Array = Array(d["places"]).filter(func(id: String) -> bool:
				return place_at.has(id) and place_at[id] != Vector2.INF)
		var at: Vector2 = d["at"]
		ids.sort_custom(func(a: String, b: String) -> bool:
				return (place_at[a] as Vector2).distance_squared_to(at) < (place_at[b] as Vector2).distance_squared_to(at))
		_order[str(d["id"])] = PackedStringArray(ids)
	ready_ok = true
	# Discovered before save v2 (a v1 save): the districts of every place or egg already found,
	# quietly (the player has been there; no cards for old news).
	if wallet != null:
		for d in districts:
			var id := str(d["id"])
			if wallet.districts.has(id):
				continue
			for p in d["places"]:
				if wallet.notes.has(p):
					wallet.districts[id] = int(wallet.notes[p])
					break
			if wallet.districts.has(id):
				continue
			for e in d["eggs"]:
				if wallet.eggs.has(e):
					wallet.districts[id] = int(wallet.eggs[e])
					break
	return true


## Lists a Syrenka (the later slice's collectible) under district `district`; it then counts
## towards that district's completion (found when the wallet's `syrenki` holds its id).
func add_syrenka(id: String, district: String) -> void:
	if by_id.has(district):
		var list: Array = districts[by_id[district]]["syrenki"]
		if not list.has(id):
			list.append(id)


# --- where ----------------------------------------------------------------------------------

## The district at map point `p` ("" outside them all): the first whose area holds it.
func district_at(p: Vector2) -> String:
	for d in districts:
		var boxes: Array[Rect2] = d["boxes"]
		var polys: Array[PackedVector2Array] = d["polys"]
		for i in polys.size():
			if boxes[i].has_point(p) and Geometry2D.is_point_in_polygon(p, polys[i]):
				return str(d["id"])
	return ""


func _process(dt: float) -> void:
	if not ready_ok or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var s: Array = probe.call()
	tick(Vector2((s[0] as Vector3).x, (s[0] as Vector3).z), bool(s[4]))
	spent_usec += Time.get_ticks_usec() - t0


## One check at map point `p` (`away`: the title screen or TEST · BENCH: nothing happens).
func tick(p: Vector2, away := false) -> void:
	if away:
		return
	var id := district_at(p)
	if id != current:
		current = id
		if wallet != null:
			wallet.district = id
		if log_on:
			print("districts: in %s at %.0f, %.0f" % [id if id != "" else "(none)", p.x, p.y])
	var quiet := quiet_first and not _checked
	_checked = true
	if force_card != "" and by_id.has(force_card):
		var forced := force_card
		force_card = ""
		show_card(forced)
	if id != "" and not is_discovered(id):
		discover(id, not quiet)


# --- the record -----------------------------------------------------------------------------

func is_discovered(id: String) -> bool:
	return wallet != null and wallet.districts.has(id)


## District `id` discovered: the save (and +10 respect, the card, the blip and the buzz unless
## `card` is false). False if it was discovered already.
func discover(id: String, card := true, date := 0) -> bool:
	if wallet == null or not by_id.has(id) or is_discovered(id):
		return false
	wallet.districts[id] = date if date > 0 else today()
	if card:
		wallet.pay(0, DISCOVER_RESPECT)  # saves
		show_card(id)
	else:
		wallet.save()
	if log_on:
		print("districts: discovered %s (%s), %d%%" % [id, "card" if card else "quietly", percent(id)])
	discovered.emit(id, card)
	return true


## The "discovered" card (the note card under the wallet): the Polish title, the English, the
## district's line and the "?" marks waiting on the map.
func show_card(id: String) -> void:
	var t := card_text(id)
	if log_on:
		print("districts: card \"%s\" (%d%%)" % [t[0], percent(id)])
	if hud != null:
		hud.show_note(t[0], t[1], CARD_COLOUR)
	if blip.is_valid():
		blip.call()
	Access.buzz(40, 0.4)


## [title, body] of district `id`'s card.
func card_text(id: String) -> PackedStringArray:
	var d: Dictionary = districts[by_id[id]]
	var line: Array = d.get("line", ["", ""])
	var marks := mini(MARKS, (_order.get(id, PackedStringArray()) as PackedStringArray).size())
	var body := Lang.pick(str(line[0]), str(line[1]))
	if marks > 0:
		body += Lang.pick("\n%d × ? na mapie", "\n%d × ? on the map") % marks
	return PackedStringArray([Lang.pick("Odkryto: %s", "Discovered: %s") % Lang.pick(d["name_pl"], d["name_en"]), body])


static func today() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


## [found, total] towards district `id`'s completion: places + eggs + Syrenki found, plus the
## jobs done there up to its goal.
func progress(id: String) -> Vector2i:
	if not by_id.has(id):
		return Vector2i.ZERO
	var d: Dictionary = districts[by_id[id]]
	var goal := int(d.get("jobs_goal", 0))
	var found := 0
	var total := goal
	if wallet != null:
		found = mini(int(wallet.district_jobs.get(id, 0)), goal)
	for pair: Array in [["places", "notes"], ["eggs", "eggs"], ["syrenki", "syrenki"]]:
		var ids: Array = d[pair[0]]
		total += ids.size()
		if wallet != null:
			var record: Dictionary = wallet.get(pair[1])
			for k in ids:
				if record.has(k):
					found += 1
	return Vector2i(found, total)


## District `id`'s completion, 0..1.
func completion(id: String) -> float:
	var p := progress(id)
	return float(p.x) / float(p.y) if p.y > 0 else 0.0


## District `id`'s completion in whole per cent (rounded down: 100 only when all is done).
func percent(id: String) -> int:
	var p := progress(id)
	return (p.x * 100) / p.y if p.y > 0 else 0


## Every district together, in whole per cent.
func percent_total() -> int:
	var f := 0
	var t := 0
	for d in districts:
		var p := progress(str(d["id"]))
		f += p.x
		t += p.y
	return (f * 100) / t if t > 0 else 0


## The "?" marks (map points): in each discovered district, its first MARKS places not in the
## notebook yet. At most 9 × 3 points (notebook.gd asks twice a second).
func marks() -> PackedVector2Array:
	var out := PackedVector2Array()
	if wallet == null:
		return out
	for d in districts:
		var id := str(d["id"])
		if not wallet.districts.has(id):
			continue
		var n := 0
		for p in _order.get(id, PackedStringArray()):
			if n >= MARKS:
				break
			if not wallet.notes.has(p):
				out.append(place_at[p])
				n += 1
	return out


## For the full map (full_map.gd `set_districts`): each district's names, label point, polygons,
## whether discovered and its per cent.
func view() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in districts:
		var id := str(d["id"])
		out.append({"id": id, "name_pl": d["name_pl"], "name_en": d["name_en"], "at": d["at"],
				"polys": d["shapes"], "found": is_discovered(id), "pct": percent(id), "hero": bool(d.get("hero", false))})
	return out


## --districts=all|none|<id>[:jobs],...: the record for a test run, in memory (no cards, no
## rewards; use with --nosave). `:jobs` sets the jobs done there.
func preset(spec: String) -> void:
	if wallet == null:
		return
	for part in spec.split(",", false):
		var bits := part.split(":")
		if bits[0] == "none":
			wallet.districts.clear()
			wallet.district_jobs.clear()
			continue
		for d in districts:
			var id := str(d["id"])
			if bits[0] == "all" or bits[0] == id:
				wallet.districts[id] = today()
				if bits.size() > 1:
					wallet.district_jobs[id] = int(bits[1])
	print("districts: --districts=%s: %d/%d discovered, %d%% in all" % [spec, wallet.districts.size(), districts.size(), percent_total()])


## One line for the log: each district's per cent (discovered ones only).
func summary() -> String:
	var bits := PackedStringArray()
	for d in districts:
		var id := str(d["id"])
		if is_discovered(id):
			bits.append("%s %d%%" % [id, percent(id)])
	return "%d/%d discovered (%s), %d%% in all" % [wallet.districts.size() if wallet != null else 0, districts.size(),
			", ".join(bits), percent_total()]
