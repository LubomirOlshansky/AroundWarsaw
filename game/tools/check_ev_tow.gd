extends SceneTree
## Dead electric cars (scripts/ev_tow.gd, F's ask 2026-11-06): their rules headless, from the
## committed map data (map/centrum.json: the lane graph) and data/dialogue.json; seeded:
##   1. the meshes: the TESŁO, its hazards, the rope and the charger one surface each (one draw
##      call apiece), the car within its SIZE box;
##   2. the lines: Bartek's `ev_tow` tags (hello, hook, carry 12+, swing, drop, stranger), the
##      stranded drivers' `ev_stranded` (8+), KEBAB FM's `ev` lines naming {street} in both
##      languages; Polish and English, bubbles under 90 characters, no real brand (the denylist
##      holds "tesla" and friends);
##   3. the rope: a car let go beside a still hook swings and settles straight under it at the
##      rope's length, never further; the loaded helicopter speeding up drags it behind and it hangs back
##      down when the hook stops; a floor under the hook holds the car up (resting);
##   4. the hooking and the pay: within reach, low and slow hooks; too far, too high, inside the
##      roof or too fast doesn't; a quick carry adds the bonus, a stranger tips less;
##   5. the real lane graph: every charger found by its place (bay within 200 m, totem off the
##      carriageway); pick_charger gives one at least 600 m away when there is one; Bartek's car
##      found from 40 seeded places at 450-1050 m on edges the traffic can go round.
## Prints "check_ev_tow: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_ev_tow.gd [-- --verbose]

const EvTow := preload("res://scripts/ev_tow.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Heli := preload("res://scripts/heli.gd")
const BUBBLE := 90


class FakeMap extends Node3D:
	func ground_height(_x: float, _z: float) -> float:
		return 0.0
	func terrain_height(_x: float, _z: float) -> float:
		return 0.0
	func deck_height(_g: int, _x: float, _z: float) -> float:
		return 0.0
	func tunnel_height(_t: int, _x: float, _z: float) -> float:
		return 0.0
	func roof_height(_x: float, _z: float) -> float:
		return -1000.0


var problems: Array[String] = []
var verbose := false


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_meshes(digest)
	_check_lines(digest)
	_check_rope(digest)
	_check_rules(digest)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var map := FakeMap.new()
	root.add_child(map)
	var g := LaneGraph.new(data["graph"], map)
	_check_map(g, map, digest)
	if problems.is_empty():
		print("check_ev_tow: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_ev_tow: %d problems" % problems.size())
		quit(1)


func _check_meshes(digest: PackedStringArray) -> void:
	var tris := 0
	for row: Array in [["car", EvTow.car_mesh()], ["hazards", EvTow.hazard_mesh()], ["rope", EvTow.rope_mesh()], ["charger", EvTow.charger_mesh()]]:
		var m: ArrayMesh = row[1]
		if m.get_surface_count() != 1:
			problems.append("%s: %d surfaces (want 1)" % [row[0], m.get_surface_count()])
		tris += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	var box := EvTow.car_mesh().get_aabb()
	var want := EvTow.SIZE
	if box.size.x > want.x + 0.05 or box.size.z > want.z + 0.1 or box.size.y > want.y + 0.05 or box.position.y < -0.01:
		problems.append("car mesh %s is outside its SIZE %s" % [box.size, want])
	digest.append("4 meshes, %d triangles, car %.2f×%.2f×%.2f m" % [tris, box.size.x, box.size.y, box.size.z])


func _check_lines(digest: PackedStringArray) -> void:
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var banned: Array = []
	for k in ["names", "rejected"]:
		banned.append_array(deny.get(k, []))
	if not "tesla" in banned:
		problems.append("brand_denylist: 'tesla' missing")
	var by_tag := {}
	for l: Array in all.get("ev_tow", []):
		var only: String = (l[2] as Dictionary).get("only", "") if l.size() > 2 else ""
		by_tag[only] = int(by_tag.get(only, 0)) + 1
		_line_ok("ev_tow", l, banned)
	for tag: String in ["hello", "hook", "carry", "swing", "drop", "stranger"]:
		var want := 12 if tag == "carry" else 1
		if int(by_tag.get(tag, 0)) < want:
			problems.append("ev_tow: %d lines tagged %s (want %d+)" % [int(by_tag.get(tag, 0)), tag, want])
	if by_tag.has(""):
		problems.append("ev_tow: %d lines without a tag" % by_tag[""])
	var stranded: Array = all.get("ev_stranded", [])
	for l: Array in stranded:
		_line_ok("ev_stranded", l, banned)
	if stranded.size() < 8:
		problems.append("ev_stranded: %d lines (want 8+)" % stranded.size())
	var radio := 0
	for l: Array in all.get("radio_host", []):
		if l.size() > 2 and (l[2] as Dictionary).get("only", "") == "ev":
			radio += 1
			if not String(l[0]).contains("{street}") or not String(l[1]).contains("{street}"):
				problems.append("radio ev line without {street}: %s" % l[0])
			_line_ok("radio_host", l, banned, 200)
	if radio < 2:
		problems.append("radio_host: %d ev lines (want 2+)" % radio)
	# The name on the cards, too.
	for text: String in [EvTow.NAME, EvTow.MODEL, EvTow.CALLER]:
		_line_ok("names", [text, text], banned)
	digest.append("lines %s, stranded %d, radio %d" % [by_tag, stranded.size(), radio])


func _line_ok(group: String, l: Array, banned: Array, most := BUBBLE) -> void:
	if l.size() < 2 or String(l[0]).strip_edges() == "" or String(l[1]).strip_edges() == "":
		problems.append("%s: a line without its Polish or English: %s" % [group, l])
		return
	if String(l[0]).length() >= most:
		problems.append("%s: %d characters (under %d): %s" % [group, String(l[0]).length(), most, l[0]])
	for text: String in [String(l[0]).to_lower(), String(l[1]).to_lower()]:
		for b in banned:
			var rx := RegEx.create_from_string("(^|[^\\p{L}])" + _escape(String(b)) + "($|[^\\p{L}])")
			if rx.search(text) != null:
				problems.append("%s: a real brand (%s): %s" % [group, b, l[0]])


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += "\\" + c if c in ".+*?^$()[]{}|\\" else c
	return out


func _check_rope(digest: PackedStringArray) -> void:
	var dt := 1.0 / 60.0
	var anchor := Vector3(0, 50, 0)
	# Let go 6 m to the side, level with the hook minus 8 m: it swings and settles under it.
	var p := Vector3(6, 42, 0)
	var v := Vector3.ZERO
	var longest := 0.0
	for i in 60 * 30:
		var r := EvTow.swing_step(p, v, anchor, Vector3.ZERO, EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
		longest = maxf(longest, p.distance_to(anchor))
	if longest > EvTow.ROPE + 0.01:
		problems.append("rope stretched to %.2f m (rope %.1f)" % [longest, EvTow.ROPE])
	if Vector2(p.x, p.z).length() > 0.3 or absf(p.y - (anchor.y - EvTow.ROPE)) > 0.1:
		problems.append("after 30 s the car hangs at %s, not under the hook at %.1f m" % [p, EvTow.ROPE])
	# The helicopter speeding up to its loaded top speed for 8 s: the car trails behind (swings back), then hangs down again.
	var trail := 0.0
	var a := anchor
	var sp := 0.0
	var top := Heli.MAX_SPEED * (1.0 - Heli.LOAD_SLOW)
	for i in 60 * 8:
		# heli.gd's easing with the sling on.
		sp = lerpf(sp, top, 1.0 - exp(-1.3 * (1.0 - Heli.LOAD_EASE) * dt))
		a += Vector3(sp * dt, 0, 0)
		var r := EvTow.swing_step(p, v, a, Vector3(sp, 0, 0), EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
		trail = maxf(trail, EvTow.swing_angle(p, a))
	if trail < 0.15 or trail > 0.9:
		problems.append("the loaded helicopter swings the car %.2f rad (want 0.15-0.9: it trails, it doesn't fly level)" % trail)
	for i in 60 * 40:
		var r := EvTow.swing_step(p, v, a, Vector3.ZERO, EvTow.ROPE, dt, -100.0)
		p = r[0]
		v = r[1]
	if EvTow.swing_angle(p, a) > 0.05:
		problems.append("40 s after the hook stops the car still swings %.2f rad" % EvTow.swing_angle(p, a))
	# A floor 4 m under the hook: the car rests on it, its roof SIZE.y above.
	var floor_y := a.y - 4.0 - EvTow.SIZE.y
	var resting := false
	for i in 60 * 3:
		var r := EvTow.swing_step(p, v, a, Vector3.ZERO, EvTow.ROPE, dt, floor_y)
		p = r[0]
		v = r[1]
		resting = r[2]
	if not resting or p.y < floor_y + EvTow.SIZE.y - 0.01:
		problems.append("the car went through the floor (%.2f, floor %.2f) or isn't resting" % [p.y - EvTow.SIZE.y, floor_y])
	digest.append("rope ≤ %.2f m, swings %.2f rad at full speed, settles, rests on a floor" % [longest, trail])


func _check_rules(digest: PackedStringArray) -> void:
	if not EvTow.can_hook(3.0, 6.0, 2.0):
		problems.append("can_hook: 3 m off, 6 m above, 2 m/s doesn't hook")
	for row: Array in [[EvTow.HOOK_R + 1.0, 6.0, 2.0, "too far"], [3.0, EvTow.ROPE + 3.0, 2.0, "too high"],
			[3.0, 0.0, 2.0, "inside the roof"], [3.0, 6.0, EvTow.HOOK_SPEED + 2.0, "too fast"]]:
		if EvTow.can_hook(row[0], row[1], row[2]):
			problems.append("can_hook: hooks when %s" % row[3])
	var quick: Array = EvTow.pay(false, 60.0)
	var slow: Array = EvTow.pay(false, EvTow.QUICK + 30.0)
	var tip: Array = EvTow.pay(true, 60.0)
	if int(quick[0]) != EvTow.PAY + EvTow.BONUS or int(slow[0]) != EvTow.PAY or int(slow[2]) != 0:
		problems.append("pay: quick %s, slow %s" % [quick, slow])
	if int(tip[0]) >= int(slow[0]) or int(tip[1]) >= int(slow[1]):
		problems.append("a stranger's tip %s is not less than Bartek's %s" % [tip, slow])
	var list := [{"at": Vector3(100, 0, 0)}, {"at": Vector3(900, 0, 0)}, {"at": Vector3(2000, 0, 0)}]
	if EvTow.pick_charger(list, Vector2.ZERO, 600.0) != 1 or EvTow.pick_charger(list, Vector2.ZERO, 600.0, true) != 0 \
			or EvTow.pick_charger(list, Vector2.ZERO, 5000.0) != 2:
		problems.append("pick_charger: wrong choices")
	digest.append("hook and pay rules, Bartek %d-%d zł, tip %d zł" % [slow[0], quick[0], tip[0]])


func _check_map(g: LaneGraph, map: Node3D, digest: PackedStringArray) -> void:
	var found := EvTow.find_chargers(g, map)
	if found.size() != EvTow.CHARGERS.size():
		problems.append("chargers: %d of %d found" % [found.size(), EvTow.CHARGERS.size()])
	for c: Dictionary in found:
		var place: Vector2 = Vector2.INF
		for d: Dictionary in EvTow.CHARGERS:
			if d["id"] == c["id"]:
				place = d["at"]
		var bay := Vector2(c["at"].x, c["at"].z)
		if bay.distance_to(place) > 200.0:
			problems.append("charger %s: bay %.0f m from its place" % [c["id"], bay.distance_to(place)])
		var side := Vector2(c["side"].x, c["side"].z)
		var e: int = c["e"]
		var half := absf(g.lane_offset(e, int(c["lane"]))) + g.e_lw[e] * 0.5
		if side.distance_to(g.point_at(e, float(c["s"]))) < half:
			problems.append("charger %s: its totem stands on the carriageway" % c["id"])
		if verbose:
			print("  charger %s at %d,%d (%s)" % [c["id"], roundi(bay.x), roundi(bay.y), g.e_name[e]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	var ok := 0
	var far := 0
	for i in 40:
		var from := Vector2(rng.randf_range(-2400.0, 900.0), rng.randf_range(-1500.0, 1500.0))
		var spot := EvTow.pick_car_spot(g, from, EvTow.CAR_FROM, EvTow.CAR_TO, rng)
		if spot.is_empty():
			continue
		ok += 1
		var e: int = spot["e"]
		if not EvTow.fits(g, e) or int(spot["lane"]) != g.e_lanes[e] - 1:
			problems.append("car spot on edge %d lane %d doesn't fit" % [e, spot["lane"]])
		var p: Array = EvTow.pose(g, spot)
		var d := from.distance_to(Vector2(p[0].x, p[0].z))
		if d < EvTow.CAR_FROM - 80.0 or d > EvTow.CAR_TO + 80.0:
			problems.append("car spot %.0f m away (want %.0f-%.0f)" % [d, EvTow.CAR_FROM, EvTow.CAR_TO])
		if not found.is_empty():
			var k := EvTow.pick_charger(found, Vector2(p[0].x, p[0].z), 600.0)
			if Vector2(p[0].x, p[0].z).distance_to(Vector2(found[k]["at"].x, found[k]["at"].z)) >= 600.0:
				far += 1
	if ok < 34:
		problems.append("Bartek's car placed from only %d of 40 places" % ok)
	digest.append("%d chargers, car spots %d/40 (charger 600 m+ away for %d)" % [found.size(), ok, far])
