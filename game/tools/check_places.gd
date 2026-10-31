extends SceneTree
## Loop MW-1 (docs/design/vision.md 4.1): MOJA WARSZAWA's places and the notebook's rules,
## headless, from the committed map data (map/centrum.json; index.json if that is missing) and
## data/places.json:
##   - every place has its name, fact and joke in Polish and English, each Polish line at most
##     70 characters (the "NOWY WPIS · <name>" toast too), 8 places in each of the 9 chapters
##     (map north: up to 10),
##     unique ids;
##   - its `near` hint is inside the demo box and where notebook.gd puts it is inside the map;
##   - nothing the notebook shows (names, fact, joke, the card's address and hours line, the
##     toast) holds a name from data/brand_denylist.json (`names` and `rejected`, as a whole
##     word or phrase, lower case);
##   - reachable: a lane of the lane graph or a footway within its radius + 10 m. The `near`
##     hints are rough (about ±150 m) until the bake resolves the places, so the ones that fail
##     are listed and counted (a WARN line), not failed;
##   - the finding rules on synthetic inputs: ≤ 30 km/h inside the radius finds, faster or
##     outside doesn't, the stop of 1 s, the helicopter under 60 m within its reach, the 2 Hz
##     tick through the grid, and a chapter complete paying +50 zł and +30 respect once.
## Prints `check_places: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_places.gd [-- --verbose]

const Notebook := preload("res://scripts/notebook.gd")
const NotebookPage := preload("res://scripts/notebook_page.gd")
const Wallet := preload("res://scripts/wallet.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
## The demo box (places.json `_about`): south, west, north, east.
const BOX := [52.2183, 20.9780, 52.2525, 21.0500]
## Map north (2026-10-31; docs/DEMO.md 2.1): the strip on the box's west side up to Arkadia
## (bake_osm.py BBOX_NORTH: east to 20.99897).
const BOX_NORTH := [52.2525, 20.9780, 52.2591, 20.99897]
const MAX_PL := 70
const REACH_SLACK := 10.0
const SEG_CELL := 50.0

var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var path := "res://map/centrum.json"
	if not FileAccess.file_exists(path):
		path = "res://map/index.json"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		print("check_places: no map data (%s)" % path)
		quit(1)
		return
	var book: Notebook = Notebook.new()
	root.add_child(book)
	if not book.setup(data, verbose):
		print("check_places: no data/places.json")
		quit(1)
		return
	_check_text(book)
	var bounds: Array = data["bounds"]
	# Map north: the map's shape (map_builder.gd in_map), not the bounding box.
	var shape: Node3D = MapBuilder.new()
	shape.bounds = Rect2(bounds[0], bounds[1], float(bounds[2]) - float(bounds[0]), float(bounds[3]) - float(bounds[1]))
	for o: Array in data.get("outside", []):
		shape.outside.append(Rect2(o[0], o[1], float(o[2]) - float(o[0]), float(o[3]) - float(o[1])))
	var segs := _segments(data)
	var unreachable := PackedStringArray()
	var by_source := {}
	for place in book.places:
		var id := str(place["id"])
		var near: Array = place["near"]
		var lat := float(near[0])
		var lon := float(near[1])
		var in_box := lat >= BOX[0] and lat <= BOX[2] and lon >= BOX[1] and lon <= BOX[3]
		var in_north := lat >= BOX_NORTH[0] and lat <= BOX_NORTH[2] and lon >= BOX_NORTH[1] and lon <= BOX_NORTH[3]
		if not in_box and not in_north:
			problems.append("%s: the hint %.4f, %.4f is outside the demo box and map north" % [id, lat, lon])
		var at: Vector2 = place["at"]
		if not shape.in_map(at):
			problems.append("%s: placed at %.0f, %.0f, outside the map" % [id, at.x, at.y])
		by_source[place["source"]] = int(by_source.get(place["source"], 0)) + 1
		var d := _nearest(segs, at)
		var need := float(place.get("radius", 25.0)) + REACH_SLACK
		if d > need:
			unreachable.append("%s %.0f m (r %d, %s)" % [id, d, int(place.get("radius", 25)), place["source"]])
		elif verbose:
			print("  %s reachable: %.1f m (need %.0f)" % [id, d, need])
	var rules := _check_rules(book)
	book.free()
	shape.free()
	if not unreachable.is_empty():
		print("places: WARN %d of %d places have no lane or footway within radius + 10 m (rough `near` hints): %s" % [
				unreachable.size(), book_count(data), ", ".join(unreachable)])
	if problems.is_empty():
		print("check_places: OK (%d places, %s; reachable %d/%d; %d rule cases)" % [book_count(data), by_source,
				book_count(data) - unreachable.size(), book_count(data), rules])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_places: %d problems" % problems.size())
		quit(1)


func book_count(_data: Dictionary) -> int:
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Notebook.PLACES_PATH))
	return (json["places"] as Array).size()


# --- the words -----------------------------------------------------------------------------

func _check_text(book: Notebook) -> void:
	var deny := _denylist()
	var ids := {}
	var per := {}
	for place in book.places:
		var id := str(place["id"])
		if ids.has(id):
			problems.append("%s: the id is used twice" % id)
		ids[id] = true
		per[place["chapter"]] = int(per.get(place["chapter"], 0)) + 1
		var pairs := [[place.get("name_pl", ""), place.get("name_en", "")], place.get("fact", []), place.get("joke", [])]
		for k in pairs.size():
			var pair: Array = pairs[k]
			if pair.size() < 2 or str(pair[0]).strip_edges() == "" or str(pair[1]).strip_edges() == "":
				problems.append("%s: %s has no Polish or no English" % [id, ["name", "fact", "joke"][k]])
				continue
			if str(pair[0]).length() > MAX_PL:
				problems.append("%s: the Polish %s is %d characters (max %d)" % [id, ["name", "fact", "joke"][k], str(pair[0]).length(), MAX_PL])
		var toast := "NOWY WPIS · %s" % place.get("name_pl", "")
		if toast.length() > MAX_PL:
			problems.append("%s: the toast '%s' is over %d characters" % [id, toast, MAX_PL])
		var shown := [str(place.get("name_pl", "")), str(place.get("name_en", "")), toast]
		for pair: Array in [place.get("fact", []), place.get("joke", [])]:
			for line in pair:
				shown.append(str(line))
		shown.append_array(NotebookPage.meta_lines(place, 20261030))
		for text: String in shown:
			var hit := _deny_hit(text, deny)
			if hit != "":
				problems.append("%s: '%s' shows '%s' (brand_denylist.json)" % [id, text, hit])
	if book.chapters.size() != 9:
		problems.append("%d chapters (9 expected)" % book.chapters.size())
	for c: Dictionary in book.chapters:
		var n := int(per.get(c["id"], 0))
		if n < Notebook.PER_CHAPTER or n > Notebook.MAX_PER_CHAPTER:
			problems.append("chapter %s has %d places (%d to %d expected)" % [c["id"], n, Notebook.PER_CHAPTER, Notebook.MAX_PER_CHAPTER])
		if str(c.get("name_pl", "")) == "" or str(c.get("name_en", "")) == "":
			problems.append("chapter %s has no Polish or no English name" % c["id"])


func _denylist() -> Array[String]:
	var out: Array[String] = []
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	if not json is Dictionary:
		problems.append("data/brand_denylist.json is missing or does not parse")
		return out
	for key in ["names", "rejected"]:
		for n in json.get(key, []):
			out.append(str(n).to_lower())
	return out


## The denylisted name `text` holds as a whole word or phrase (lower case), or "".
static func _deny_hit(text: String, deny: Array[String]) -> String:
	var low := text.to_lower()
	for n in deny:
		var from := 0
		while true:
			var i := low.find(n, from)
			if i < 0:
				break
			var before := low[i - 1] if i > 0 else " "
			var after := low[i + n.length()] if i + n.length() < low.length() else " "
			if not _wordy(before) and not _wordy(after):
				return n
			from = i + 1
	return ""


static func _wordy(c: String) -> bool:
	return c.to_upper() != c.to_lower() or c.is_valid_int()


# --- reachability --------------------------------------------------------------------------

## The lanes (the lane graph's edges) and footways as segments in SEG_CELL m cells.
func _segments(data: Dictionary) -> Dictionary:
	var grid := {}
	var lines: Array = []
	var graph: Dictionary = data.get("graph", {})
	for e: Dictionary in graph.get("edges", []):
		lines.append(e["p"])
	for p: Dictionary in data.get("paths", []):
		if str(p.get("k", "")) in ["foot", "zebra"]:
			lines.append(p["p"])
	for flat: Array in lines:
		for i in range(0, flat.size() - 3, 2):
			var a := Vector2(float(flat[i]), float(flat[i + 1]))
			var b := Vector2(float(flat[i + 2]), float(flat[i + 3]))
			var lo := Vector2i(floori(minf(a.x, b.x) / SEG_CELL), floori(minf(a.y, b.y) / SEG_CELL))
			var hi := Vector2i(floori(maxf(a.x, b.x) / SEG_CELL), floori(maxf(a.y, b.y) / SEG_CELL))
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					var key := Vector2i(x, z)
					if not grid.has(key):
						grid[key] = []
					grid[key].append([a, b])
	return grid


func _nearest(grid: Dictionary, p: Vector2) -> float:
	var best := INF
	var c := Vector2i(floori(p.x / SEG_CELL), floori(p.y / SEG_CELL))
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			for s: Array in grid.get(c + Vector2i(dx, dz), []):
				best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, s[0], s[1])))
	return best


# --- the rules -----------------------------------------------------------------------------

func _expect(what: String, got: Variant, want: Variant) -> void:
	if got != want:
		problems.append("rule: %s: got %s, want %s" % [what, got, want])


func _check_rules(book: Notebook) -> int:
	var n := 0
	# The rule itself: (dist, km/h, stopped s, flying, altitude, radius, heli radius).
	var cases := [
		["slow pass inside", [20.0, 25.0, 0.0, false, 0.0, 25.0, 0.0], true],
		["30 km/h exactly", [20.0, 30.0, 0.0, false, 0.0, 25.0, 0.0], true],
		["too fast inside", [20.0, 45.0, 0.0, false, 0.0, 25.0, 0.0], false],
		["slow but outside", [26.0, 10.0, 0.0, false, 0.0, 25.0, 0.0], false],
		["stopped 1 s inside", [24.0, 40.0, 1.0, false, 0.0, 25.0, 0.0], true],
		["stopped 0.5 s", [24.0, 40.0, 0.5, false, 0.0, 25.0, 0.0], false],
		["square radius 40", [38.0, 20.0, 0.0, false, 0.0, 40.0, 0.0], true],
		["heli low within 60", [55.0, 120.0, 0.0, true, 40.0, 25.0, 0.0], true],
		["heli too high", [20.0, 0.0, 0.0, true, 70.0, 25.0, 0.0], false],
		["heli outside 60", [65.0, 0.0, 0.0, true, 30.0, 25.0, 0.0], false],
		["heli own radius", [70.0, 0.0, 0.0, true, 30.0, 25.0, 80.0], true],
	]
	for c: Array in cases:
		var a: Array = c[1]
		_expect(c[0], Notebook.finds(a[0], a[1], a[2], a[3], a[4], a[5], a[6]), c[2])
		n += 1
	# Through the grid and the wallet: a real Wallet that saves nothing.
	var wallet: Wallet = Wallet.new()
	wallet.persistent = false
	root.add_child(wallet)
	book.wallet = wallet
	var first: Dictionary = book.chapter_places(0)[0]
	var at: Vector2 = first["at"]
	var id := str(first["id"])
	var pos := Vector3(at.x + 10.0, 0.0, at.y)
	book.tick(pos, 50.0, false, 0.0, false, 0.5)
	_expect("tick at 50 km/h finds", book.is_found(id), false)
	book.tick(pos, 20.0, false, 0.0, true, 0.5)
	_expect("tick away (title, bench) finds", book.is_found(id), false)
	book.tick(Vector3(at.x + 200.0, 0.0, at.y), 0.0, false, 0.0, false, 0.5)
	_expect("tick 200 m away finds", book.is_found(id), false)
	book.tick(pos, 20.0, false, 0.0, false, 0.5)
	_expect("tick at 20 km/h finds", book.is_found(id), true)
	_expect("a card pays 5 respect", wallet.respect, Notebook.CARD_RESPECT)
	_expect("a card pays no złoty", wallet.zl, 0)
	_expect("found again", book.record(id), false)
	_expect("the date is kept", int(wallet.notes[id]) > 20260000, true)
	var second: Dictionary = book.chapter_places(1)[0]
	var at2: Vector2 = second["at"]
	book.tick(Vector3(at2.x, 0.0, at2.y + 50.0), 150.0, true, 70.0, false, 0.5)
	_expect("heli at 70 m finds", book.is_found(str(second["id"])), false)
	book.tick(Vector3(at2.x, 0.0, at2.y + 50.0), 150.0, true, 40.0, false, 0.5)
	_expect("heli at 40 m, 50 m off finds", book.is_found(str(second["id"])), true)
	n += 8
	# A chapter complete: +50 zł and +30 respect, once.
	wallet.notes.clear()
	wallet.chapters_done.clear()
	wallet.zl = 0
	wallet.respect = 0
	var list := book.chapter_places(0)
	for k in list.size():
		book.record(str(list[k]["id"]))
		if k == list.size() - 2:
			_expect("7/8: no chapter pay yet", wallet.zl, 0)
	_expect("chapter complete: złoty", wallet.zl, Notebook.CHAPTER_ZL)
	_expect("chapter complete: respect", wallet.respect, Notebook.CARD_RESPECT * list.size() + Notebook.CHAPTER_RESPECT)
	_expect("chapter recorded", wallet.chapters_done.has(str(book.chapters[0]["id"])), true)
	wallet.notes.clear()
	for p: Dictionary in list:
		book.record(str(p["id"]))
	_expect("chapter pays once", wallet.zl, Notebook.CHAPTER_ZL)
	_expect("found counts", book.found_in(0), list.size())
	# --found presets.
	book.preset("none")
	_expect("--found=none", book.found_total(), 0)
	book.preset("2:3")
	_expect("--found=2:3", book.found_in(1), 3)
	book.preset("all")
	_expect("--found=all", book.found_total(), book.places.size())
	n += 8
	wallet.free()
	return n
