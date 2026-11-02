extends SceneTree
## Kibice (docs/design/city-life-satire.md 7): scripts/fans.gd's rules, layout and drawing, headless,
## from the committed map data (map/centrum.json: roads, buildings, footways) and data/dialogue.json:
##   1. the match evenings on synthetic clocks (Wednesday, Saturday and Sunday evenings out; a
##      Friday afternoon, a Monday and the small hours home) and --fans-now;
##   2. the chant's jump (never below the ground, at most JUMP), the smoke sticks' cycles (each lit
##      SMOKE_ON of SMOKE_CYCLE s, one of a group's two lit most of the time) and the puffs (rising,
##      growing then shrinking);
##   3. the real map: every group finds its pavement within SNAP m of its anchor and room for all
##      its fans, a drummer, two smoke holders and a kid; no fan on a road (ROAD_CLEAR from its edge)
##      or inside a building, every fan within 260 m of the stadium, none closer than GAP to another;
##   4. the meshes' budgets (the props family ≤ 1,000 vertices, a puff ≤ 150, the kit ≤ 20,000);
##   5. the lines: the groups and their tags, ≤ 70 characters in Polish, English on each, no real
##      brand (data/brand_denylist.json), no club named and nothing about rival fans or a fight;
##   6. a node on the real map with --fans-now: nothing drawn far from the stadium, every fan drawn
##      near it with the kit shown, a chant raising the scarves, the horn starting a chant and a
##      `honk` line, lines in a minute, the moves' cost.
## Prints "check_fans: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_fans.gd [-- --verbose]

const Fans := preload("res://scripts/fans.gd")


## A stand-in for the map: flat ground.
class FakeMap extends Node3D:
	func deck_height(_dk: int, _x: float, _z: float) -> float:
		return 0.0


## Records the lines asked for.
class FakeDialogue extends Node:
	var said: Array = []

	func say_ambient(_anchor: Variant, speaker: String, group: String, tag := "", _s := 4.0, _a := Color.WHITE, _h := 2.6, _p := false) -> Array:
		said.append([speaker, group, tag])
		return ["x", "x"]


var problems: Array[String] = []
var verbose := false
var now := {"hour": 18.0, "weekday": 6}
var eye := Vector3.ZERO


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _expect(ok: bool, what: String) -> void:
	if not ok:
		problems.append(what)


func _run() -> void:
	await process_frame
	var digest := PackedStringArray()
	_check_hours(digest)
	_check_motion()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	_check_layout(data, digest)
	_check_meshes(digest)
	_check_lines(digest)
	_check_node(data, digest)
	if problems.is_empty():
		print("check_fans: OK (%s)" % "; ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("check_fans: %s" % p)
		quit(1)


# 1. -------------------------------------------------------------------------------------------

func _check_hours(digest: PackedStringArray) -> void:
	var on := [[3, 18.0], [3, 21.0], [6, 15.5], [6, 20.0], [7, 14.0], [7, 19.9]]
	var off := [[1, 18.0], [2, 19.0], [4, 18.0], [5, 14.0], [5, 20.0], [3, 12.0], [3, 21.5], [6, 1.5], [6, 22.0], [7, 21.0]]
	for c: Array in on:
		_expect(Fans.match_on(float(c[1]), int(c[0])), "no match on day %d at %.1f" % [c[0], c[1]])
	for c: Array in off:
		_expect(not Fans.match_on(float(c[1]), int(c[0])), "a match on day %d at %.1f" % [c[0], c[1]])
	_expect(Fans.group_count(24, 14.0, 5) == 0, "fans out on the Day look's Friday 14:00")
	_expect(Fans.group_count(24, 14.0, 5, 1.0, true) == 24, "--fans-now: not all out")
	_expect(Fans.group_count(24, 18.0, 6, 0.5) == 12, "--crowd=0.5 doesn't halve a group")
	var hours := 0.0
	for d in range(1, 8):
		for k in 96:
			hours += 0.25 if Fans.match_on(k * 0.25, d) else 0.0
	_expect(hours >= 15.0 and hours <= 20.0, "%.1f match hours a week (want 15-20)" % hours)
	digest.append("%.1f match hours a week" % hours)


# 2. -------------------------------------------------------------------------------------------

func _check_motion() -> void:
	var top := 0.0
	for i in 400:
		var y := Fans.jump_at(i * 0.0173, -1.0 + (i % 21) * 0.1)
		_expect(y >= 0.0, "a jump below the ground")
		top = maxf(top, y)
	_expect(top <= Fans.JUMP + 0.001 and top > Fans.JUMP * 0.8, "the jump peaks at %.2f m" % top)
	for ph: float in [0.0, 13.0, 60.0]:
		var lit := [0, 0]
		var any := 0
		for i in 750:
			var s := i * 0.1
			var a := Fans.smoke_lit(s, 0, ph)
			var b := Fans.smoke_lit(s, 1, ph)
			lit[0] += 1 if a else 0
			lit[1] += 1 if b else 0
			any += 1 if a or b else 0
		for k in 2:
			var share := float(lit[k]) / 750.0
			_expect(absf(share - Fans.SMOKE_ON / Fans.SMOKE_CYCLE) < 0.02, "stick %d lit %.0f%% of a cycle" % [k, share * 100.0])
		_expect(any >= 700, "both of a group's sticks out %.0f%% of the time" % (100.0 - any / 7.5))
	var a0: Array = Fans.puff_at(0.05, 0)
	var a1: Array = Fans.puff_at(0.5, 0)
	var a2: Array = Fans.puff_at(0.95, 0)
	_expect((a1[0] as Vector3).y > (a0[0] as Vector3).y and (a2[0] as Vector3).y > (a1[0] as Vector3).y, "the puffs don't rise")
	_expect(float(a1[1]) > float(a0[1]) and float(a1[1]) > float(a2[1]), "a puff doesn't grow and then shrink")
	_expect(float(a1[1]) <= Fans.PUFF_SIZE + 0.25, "a puff of %.2f m" % float(a1[1]))


# 3. -------------------------------------------------------------------------------------------

func _check_layout(data: Dictionary, digest: PackedStringArray) -> void:
	var obs := Fans.obstacles(data, Fans.STADIUM, 330.0)
	var foot := Fans.pavements(data, Fans.STADIUM, 330.0)
	_expect((obs[0] as Array).size() > 5 and (obs[1] as Array).size() > 3 and foot.size() > 10,
			"the stadium's surroundings: %d roads, %d buildings, %d footways" % [(obs[0] as Array).size(), (obs[1] as Array).size(), foot.size()])
	var sizes := PackedStringArray()
	for id: String in Fans.GROUPS:
		var spec: Dictionary = Fans.GROUPS[id]
		var n := int(spec["n"])
		var lay := Fans.layout(spec["at"], n, foot, obs[0], obs[1], hash(id))
		_expect(not lay.is_empty(), "%s: no pavement within %.0f m of its anchor" % [id, Fans.SNAP])
		if lay.is_empty():
			continue
		var slots: Array = lay["slots"]
		_expect(slots.size() >= n, "%s: room for %d of %d fans" % [id, slots.size(), n])
		var roles := {}
		for s: Array in slots:
			var p: Vector2 = s[0]
			roles[s[1]] = int(roles.get(s[1], 0)) + 1
			_expect(Fans.clear_at(p, obs[0], obs[1]), "%s: a fan at %.1f, %.1f on a road or in a building" % [id, p.x, p.y])
			_expect(p.distance_to(Fans.STADIUM) < 260.0, "%s: a fan %.0f m from the stadium" % [id, p.distance_to(Fans.STADIUM)])
			for o: Array in slots:
				if o != s and (o[0] as Vector2).distance_to(p) < Fans.GAP - 0.01:
					_expect(false, "%s: two fans %.2f m apart" % [id, (o[0] as Vector2).distance_to(p)])
					break
		_expect(int(roles.get("drum", 0)) == 1, "%s: %d drummers" % [id, int(roles.get("drum", 0))])
		_expect(int(roles.get("smoke", 0)) == 2, "%s: %d smoke holders" % [id, int(roles.get("smoke", 0))])
		_expect(int(roles.get("kid", 0)) == 1, "%s: %d kids" % [id, int(roles.get("kid", 0))])
		var face: Vector2 = lay["face"]
		var ban: Vector2 = lay["banner"]
		_expect((ban - (lay["at"] as Vector2)).dot(face) < 0.0, "%s: the banner isn't behind the fans" % id)
		_expect(Fans.clear_at(ban, obs[0], obs[1]), "%s: the banner on a road or in a building" % id)
		sizes.append("%s %d (%.0f m deep)" % [id, slots.size(), float(lay["back"])])
		if verbose:
			print("  %s at %.0f, %.0f facing %.2f, %.2f: %s" % [id, (lay["at"] as Vector2).x, (lay["at"] as Vector2).y, face.x, face.y, roles])
	digest.append("groups " + ", ".join(sizes))


# 4. -------------------------------------------------------------------------------------------

func _check_meshes(digest: PackedStringArray) -> void:
	var props := Fans.props_mesh()
	var pv := (props.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(props.get_surface_count() == 1 and pv <= 1000, "the props: %d surfaces, %d vertices" % [props.get_surface_count(), pv])
	var puff := Fans.puff_mesh()
	var uv := (puff.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(uv <= 150, "a puff of %d vertices" % uv)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Fans.kit_mesh(st, 4.0, 7.0, Fans.GROUPS["brama"]["banner"], [[Vector3(-5, 0, 1), "drum"], [Vector3(2, 2.25, 0), "smoke"]])
	var kit := st.commit()
	var kv := (kit.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_expect(kv <= 20000 / 3, "one group's kit of %d vertices" % kv)
	digest.append("props %d, puff %d, kit %d vertices" % [pv, uv, kv])


# 5. -------------------------------------------------------------------------------------------

func _check_lines(digest: PackedStringArray) -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var deny: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/brand_denylist.json"))
	var names: Array = (deny["names"] as Array) + (deny["rejected"] as Array)
	# Colours only: no club named, nothing about rivals, no fight words (whole words, lower case).
	var never := ["legia", "legii", "legią", "polonia", "widzew", "lech", "wisła", "cracovia", "jagiellonia", "zgoda", "ustawka",
			"kibol", "kibole", "chuligan", "chuligani", "bić", "bijemy", "wróg", "wrogów", "kosa", "petarda", "raca w ręku",
			"hooligan", "fight", "enemy", "rivals"]
	var want := {"kibice": {"": 10, "chant": 5, "honk": 3, "car": 4, "kid": 3}, "police_kibice": {"": 5}}
	var all_text := ""
	var total := 0
	for g: String in want:
		_expect(d.has(g), "dialogue.json has no '%s'" % g)
		var counts := {}
		for l: Array in d.get(g, []):
			var tag := ""
			if l.size() > 2:
				tag = str((l[2] as Dictionary).get("only", ""))
			counts[tag] = int(counts.get(tag, 0)) + 1
			_expect(str(l[0]).length() <= 70, "%s: a Polish line of %d characters" % [g, str(l[0]).length()])
			_expect(str(l[1]) != "", "%s: a line without English" % g)
			all_text += " " + str(l[0]).to_lower() + " " + str(l[1]).to_lower()
			total += 1
		for tag: String in want[g]:
			_expect(int(counts.get(tag, 0)) >= int(want[g][tag]), "%s has %d '%s' lines (want %d)" % [g, int(counts.get(tag, 0)), tag, want[g][tag]])
	for spec: Dictionary in Fans.GROUPS.values():
		for s: String in spec["banner"]:
			all_text += " " + s.to_lower()
	var rx := RegEx.new()
	for n: String in names + never:
		rx.compile("(^|[^\\p{L}])" + n.replace(".", "\\.") + "($|[^\\p{L}])")
		_expect(rx.search(all_text) == null, "a fans' line or banner says '%s'" % n)
	digest.append("%d lines" % total)


# 6. -------------------------------------------------------------------------------------------

func _check_node(data: Dictionary, digest: PackedStringArray) -> void:
	var map := FakeMap.new()
	root.add_child(map)
	var dlg := FakeDialogue.new()
	root.add_child(dlg)
	var f := Fans.new()
	f.map = map
	f.dialogue = dlg
	f.force = true
	f.clock = func() -> Dictionary: return now
	f.focus = func() -> Vector3: return eye
	f.vehicle = func() -> Array: return [Vector3.INF, 0.0, false]
	root.add_child(f)
	f.setup(data)
	_expect(f.groups.size() == Fans.GROUPS.size(), "%d of %d groups set up" % [f.groups.size(), Fans.GROUPS.size()])
	# Far: nothing.
	eye = Vector3(-3000, 0, -3000)
	f.tick(0.5)
	f.move(0.1)
	_expect(not f._fan_mmi.visible and not f._kit.visible and not f._puff_mmi.visible, "fans drawn 4 km from the stadium")
	# Near: every fan, the kit, some smoke.
	eye = Vector3(Fans.STADIUM.x, 0, Fans.STADIUM.y - 100.0)
	f.tick(0.5)
	f.move(0.1)
	var want := 0
	for g: Dictionary in f.groups:
		want += int(g["n"])
	_expect(f.near and f._kit.visible and f._fan_mm.visible_instance_count == want,
			"near the stadium: %d fans drawn (want %d), kit %s" % [f._fan_mm.visible_instance_count, want, f._kit.visible])
	_expect(f._puff_mm.visible_instance_count >= Fans.PUFFS, "no smoke near the stadium (%d puffs)" % f._puff_mm.visible_instance_count)
	# A chant: the scarves go up (a raised prop sits higher than a neck one).
	var g0: Dictionary = f.groups[0]
	g0["chant"] = 0.0
	g0["next"] = 0.0
	f.tick(0.5)
	_expect(float(g0["chant"]) > 0.0, "a group's timer ran out and it didn't sing")
	f.t += 0.11
	f.move(0.1)
	# The horn by a quiet group starts it singing, with a `honk` line.
	var g1: Dictionary = f.groups[1]
	g1["chant"] = 0.0
	g1["next"] = 99.0
	g1["honk_t"] = 0.0
	var before := dlg.said.size()
	var a1: Vector2 = g1["at"]
	f.honk(Vector3(a1.x, 0, a1.y + 5.0))
	_expect(float(g1["chant"]) > 0.0, "the horn by the %s group didn't start a chant" % g1["id"])
	var honked := false
	for i in range(before, dlg.said.size()):
		honked = honked or dlg.said[i][2] == "honk"
	_expect(honked, "no honk line after the horn")
	# Lines in a minute at the gate.
	before = dlg.said.size()
	eye = Vector3((g0["at"] as Vector2).x, 0, (g0["at"] as Vector2).y)
	for i in 120:
		f.t += 0.5
		f.tick(0.5)
	_expect(dlg.said.size() - before >= 2, "the gate's fans said %d lines in a minute" % (dlg.said.size() - before))
	# The cost: the moves with every group near.
	var t0 := Time.get_ticks_usec()
	for i in 200:
		f.t += 0.1
		f.move(0.1)
	var us := float(Time.get_ticks_usec() - t0) / 200.0
	_expect(us < 2500.0, "a move costs %.0f µs" % us)
	digest.append("node: %d fans near, %d puffs, a move %.0f µs" % [want, f._puff_mm.visible_instance_count, us])
	f.queue_free()
