extends SceneTree
## The museum and Plac Piłsudskiego loop (2026-10-31): the landmarks built in code at Muzeum
## Narodowe and on Plac Piłsudskiego's edges, checked headless from the committed map data alone
## (map/centrum.json; no terrain, LoD2 or sectors needed, so it runs in CI too):
##   - each site is found (muzeum, europejski, grob), and the museum is a model now, not a skin;
##   - what each replaces is dropped (the museum's OpenStreetMap outline, the LoD2 model's centre
##     in its forecourt, Hotel Europejski's outline, the Tomb's tiny 3D parts) and what stands
##     next to it is kept (the museum's garages, the papal cross, the Metropolitan's parts);
##   - built alone (`landmarks.gd`, a stub map with flat ground), its triangles are within
##     BUDGET, every one carries a landmark material code (UV2.x >= 2: the city's one building
##     material, so no draw call of its own), lies within the site's box + SITE_REACH (so a
##     sector that builds the site keeps all of it), and it adds car walls and tap cells;
##   - its info card has a name and Polish and English lines of at most 70 characters.
## Prints a line per site, then `check_sites: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_sites.gd

const Landmarks := preload("res://scripts/landmarks.gd")
const Chunked := preload("res://scripts/chunked_surface.gd")
## Triangles a site may hold (the museum and Plac loop's own models).
const BUDGET := {"muzeum": 2500, "europejski": 1500, "grob": 600}
const MAX_LINE := 70

var problems: Array[String] = []


## A stand-in for map_builder.gd: flat ground, the roof grid's frame, the car walls.
class StubMap:
	const ROOF_CELL := 4.0
	var _roof_x0 := 0.0
	var _roof_z0 := 0.0
	var _roof_nx := 0
	var _roof_nz := 0
	var _wall_faces := PackedVector3Array()
	var roof_tris := 0

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func _roof_triangle(_a: Vector3, _b: Vector3, _c: Vector3, _is_roof: bool, _col := Color(0, 0, 0, 0)) -> void:
		roof_tris += 1


## A stand-in for the city's building surface: keeps what the landmark emits.
class Recorder:
	var pos := PackedVector3Array()
	var codes := PackedFloat32Array()
	var _uv2 := Vector2.ZERO

	func set_color(_c: Color) -> void:
		pass

	func set_normal(_n: Vector3) -> void:
		pass

	func set_uv(_uv: Vector2) -> void:
		pass

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		pos.append(p)
		codes.append(_uv2.x)


func _initialize() -> void:
	var text := FileAccess.get_file_as_string("res://map/centrum.json")
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		print("check_sites: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := StubMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	_check_zones(marks, data)
	for key: String in BUDGET:
		_check_site(marks, map, key)
	if problems.is_empty():
		print("check_sites: OK")
		quit(0)
	else:
		print("check_sites: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


func _centre(flat: Array) -> Vector2:
	var c := Vector2.ZERO
	for i in range(0, flat.size() - 1, 2):
		c += Vector2(flat[i], flat[i + 1])
	return c / maxf(flat.size() / 2, 1)


func _check_zones(marks, data: Dictionary) -> void:
	for s: Dictionary in marks.sites:
		if s["key"] == "muzeum" and s.has("skin"):
			problems.append("muzeum: still a skin site, not a model")
	var dropped := 0
	var kept := 0
	for bld: Dictionary in data["buildings"]:
		var c := _centre(bld["p"])
		var name := str(bld.get("name", ""))
		# The museum (its outline round the courtyards), Hotel Europejski, the Tomb's parts.
		var want_drop := (Rect2(-60, 170, 215, 135).has_point(c) and (bld["p"] as Array).size() > 40) \
				or name == "Hotel Europejski" \
				or (Rect2(-871.0, -776.0, 11.0, 15.0).has_point(c) and float(bld["h"]) < 7.0)
		var want_keep := (name == "Krzyż Papieski") or (str(bld.get("kind", "")) == "garage" and Rect2(80, 260, 40, 25).has_point(c)) \
				or (str(bld["c"]) == "#9cafb3" and Rect2(-870, -1000, 130, 120).has_point(c))
		if want_drop:
			dropped += 1
			if marks.keeps_building(bld):
				problems.append("%s at %s is still drawn under a landmark" % [name if name != "" else "a building", c.round()])
		elif want_keep:
			kept += 1
			if not marks.keeps_building(bld):
				problems.append("%s at %s is dropped, but stands outside the landmarks" % [name if name != "" else str(bld.get("kind", "")), c.round()])
	# The museum's LoD2 model is one run round its courtyards: its box's centre is in one.
	if not marks.replaces(Vector2(47.5, 237.5)):
		problems.append("muzeum: a model centred in its east courtyard (the LoD2 run) would stay")
	if dropped < 3 or kept < 3:
		problems.append("the zone test found %d buildings to drop and %d to keep (map changed?)" % [dropped, kept])
	print("check_sites: zones: %d buildings dropped under the sites, %d neighbours kept" % [dropped, kept])


func _check_site(marks, map: StubMap, key: String) -> void:
	var k := -1
	for i in marks.sites.size():
		if marks.sites[i]["key"] == key:
			k = i
	if k < 0:
		problems.append("%s: site not found" % key)
		return
	var s: Dictionary = marks.sites[k]
	var rec := Recorder.new()
	marks.st = rec
	marks._pick.resize(map._roof_nx * map._roof_nz)
	marks._pick.fill(0)
	marks._id = k + 1
	var walls0 := map._wall_faces.size()
	match key:
		"muzeum":
			marks._build_muzeum(s)
		"europejski":
			marks._build_europejski(s)
		"grob":
			marks._build_grob(s)
	marks._id = 0
	var tris := rec.pos.size() / 3
	var reach: Rect2 = (s["box"] as Rect2).grow(Landmarks.SITE_REACH)
	var outside := 0
	var plain := 0
	var tiles := {}
	for t in tris:
		var c := (rec.pos[t * 3] + rec.pos[t * 3 + 1] + rec.pos[t * 3 + 2]) / 3.0
		if not reach.has_point(Vector2(c.x, c.z)):
			outside += 1
		if rec.codes[t * 3] < 2.0:
			plain += 1
		tiles[Chunked.tile_of(c)] = true
	var cells := 0
	for b in marks._pick:
		if b == k + 1:
			cells += 1
	var walls := (map._wall_faces.size() - walls0) / 6
	print("check_sites: %-10s %5d triangles (budget %d), %d tiles of the city mesh, %d car walls, %d tap cells" % [
			key, tris, BUDGET[key], tiles.size(), walls, cells])
	if tris == 0 or tris > BUDGET[key]:
		problems.append("%s: %d triangles (budget %d)" % [key, tris, BUDGET[key]])
	if outside > 0:
		problems.append("%s: %d triangles outside its box + SITE_REACH (a sector would cut them)" % [key, outside])
	if plain > 0:
		problems.append("%s: %d triangles without a landmark material code" % [key, plain])
	if walls < 4:
		problems.append("%s: no car walls" % key)
	if cells < 4:
		problems.append("%s: only %d tap cells" % [key, cells])
	var card: Array = Landmarks.INFO.get(key, [])
	if card.size() != 3 or str(card[0]) == "":
		problems.append("%s: no info card" % key)
	else:
		for line: String in [card[1], card[2]]:
			if line == "" or line.length() > MAX_LINE:
				problems.append("%s: card line of %d characters: %s" % [key, line.length(), line])
