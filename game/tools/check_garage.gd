extends SceneTree
## The garage loop (2026-10-31): Warsztat u Mirka's rules without the map (garage.gd,
## garage_card.gd's words, wallet.gd's [garage] section, car.gd `set_paint`, eggs E01 and E21).
##   - the paints: 8, ids unique, the factory red free and the default, black and green there
##     (the eggs need them), the gold one behind GOLD_EGGS egg cards, prices 150-400 zł;
##   - the rule: on / switch / buy / short / locked for each case; when it shows (`open_rule`);
##   - buying with enough money pays the price once and owns the paint; too little pays nothing;
##     switching to an owned paint (or the factory red) is free; the gold one opens at 5 eggs;
##   - a seeded walk of 200 taps (10 seeds): the złoty never go below 0, what was paid is the sum
##     of the prices of what was bought, nothing is bought twice;
##   - the save: paint and owned paints survive a save and a load (a scratch file);
##   - the car: `set_paint` recolours the body (its vertex colours), keeps its material and its
##     node count;
##   - Mirek's lines (dialogue.json "garage"): every tag the card asks for, Polish and English,
##     at most 70 characters;
##   - E01 (crowds.gd `door_egg` at Lusterko, egg_book.gd `fire` with its conditions: black, a
##     Friday or Saturday night, 23-06) and E21 (stop 2 s at Glon, green) fire on synthetic inputs,
##     not without their paint or time, and reward once (+50, +15).
## Prints `check_garage: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_garage.gd

const Garage := preload("res://scripts/garage.gd")
const Wallet := preload("res://scripts/wallet.gd")
const EggBook := preload("res://scripts/egg_book.gd")
const Crowds := preload("res://scripts/crowds.gd")
const Car := preload("res://scripts/car.gd")
const SCRATCH := "user://check_garage.cfg"
const TAGS := ["hello", "buy", "black", "green", "gold", "switch", "short", "locked"]

var problems: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	_check_paints()
	_check_rules()
	_check_buying()
	for seed_value in 10:
		_check_walk(seed_value + 1)
	_check_save()
	await _check_car()
	_check_lines()
	_check_eggs()
	if FileAccess.file_exists(SCRATCH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH))
	if problems.is_empty():
		print("check_garage: OK (%d paints, the rules, buying and switching, 10 seeded walks, the save, the car's paint, Mirek's %d tags, E01 and E21 once)" % [
				Garage.PAINTS.size(), TAGS.size()])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_garage: %d problems" % problems.size())
		quit(1)


func _wallet(zl := 0) -> Node:
	var w: Node = Wallet.new()
	w.persistent = false
	w.zl = zl
	root.add_child(w)
	return w


func _garage(w: Node, eggs := 0) -> Node:
	var g: Node = Garage.new()
	g.wallet = w
	g.eggs_found = func() -> int: return eggs
	return g


func _check_paints() -> void:
	var ids := {}
	for p: Dictionary in Garage.PAINTS:
		var id := str(p["id"])
		if ids.has(id):
			problems.append("paint %s twice" % id)
		ids[id] = true
		var name: Array = p["name"]
		if name.size() != 2 or str(name[0]) == "" or str(name[1]) == "":
			problems.append("paint %s: a name without Polish and English" % id)
		var price := int(p["price"])
		if id == Garage.DEFAULT or p.has("eggs"):
			if price != 0:
				problems.append("paint %s: %d zł (want free)" % [id, price])
		elif price < 150 or price > 400:
			problems.append("paint %s: %d zł (want 150-400)" % [id, price])
	if Garage.PAINTS.size() < 6 or Garage.PAINTS.size() > 8:
		problems.append("%d paints (want 6-8)" % Garage.PAINTS.size())
	for need in ["red", "black", "green", "gold"]:
		if not ids.has(need):
			problems.append("no %s paint" % need)
	if int(Garage.find("black")["price"]) != 300:
		problems.append("black costs %d zł (want 300)" % int(Garage.find("black")["price"]))
	if int(Garage.find("gold").get("eggs", 0)) != Garage.GOLD_EGGS:
		problems.append("gold wants %d eggs (want %d)" % [int(Garage.find("gold").get("eggs", 0)), Garage.GOLD_EGGS])


func _expect(what: String, got: Variant, want: Variant) -> void:
	if got != want:
		problems.append("%s: %s (want %s)" % [what, got, want])


func _check_rules() -> void:
	var owned := {"blue": 1}
	_expect("rule red on", Garage.rule("red", "red", 0, {}, 0), "on")
	_expect("rule red from blue", Garage.rule("red", "blue", 0, owned, 0), "switch")
	_expect("rule blue owned", Garage.rule("blue", "red", 0, owned, 0), "switch")
	_expect("rule black 300 zł", Garage.rule("black", "red", 300, {}, 0), "buy")
	_expect("rule black 299 zł", Garage.rule("black", "red", 299, {}, 0), "short")
	_expect("rule gold 4 eggs", Garage.rule("gold", "red", 9999, {}, 4), "locked")
	_expect("rule gold 5 eggs", Garage.rule("gold", "red", 0, {}, 5), "switch")
	_expect("rule nothing", Garage.rule("chrome", "red", 0, {}, 0), "")
	_expect("shown, nothing earned", Garage.open_rule({}, 0, {}), false)
	_expect("shown, a kebab done", Garage.open_rule({"kebab": 1}, 0, {}), true)
	_expect("shown, money", Garage.open_rule({}, 25, {}), true)
	_expect("shown, a paint bought, spent out", Garage.open_rule({}, 0, {"black": 1}), true)


func _check_buying() -> void:
	var w := _wallet(299)
	var g := _garage(w)
	_expect("buy black with 299 zł", g.choose("black"), "short")
	_expect("299 zł after", int(w.zl), 299)
	_expect("black owned after short", w.paints.has("black"), false)
	w.zl = 450
	_expect("buy black with 450 zł", g.choose("black"), "buy")
	_expect("zł after black", int(w.zl), 150)
	_expect("black owned", w.paints.has("black"), true)
	_expect("paint after buying", str(w.paint), "black")
	_expect("black again", g.choose("black"), "on")
	_expect("back to red", g.choose("red"), "switch")
	_expect("zł after red", int(w.zl), 150)
	_expect("back to black", g.choose("black"), "switch")
	_expect("zł after switching", int(w.zl), 150)
	_expect("gold with 4 eggs", g.choose("gold"), "locked")
	g.eggs_found = func() -> int: return 5
	_expect("gold with 5 eggs", g.choose("gold"), "switch")
	_expect("zł after gold", int(w.zl), 150)
	_expect("gold kept", w.paints.has("gold"), true)
	g.free()
	w.free()


## 200 seeded taps on random paints with random money coming in.
func _check_walk(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919
	var w := _wallet(0)
	var eggs := [0]
	var g := _garage(w)
	g.eggs_found = func() -> int: return eggs[0]
	var paid := 0
	var earned := 0
	var bought := {}
	for i in 200:
		if rng.randf() < 0.3:
			var pay := rng.randi_range(10, 120)
			w.zl += pay
			earned += pay
		if rng.randf() < 0.03:
			eggs[0] += 1
		var p: Dictionary = Garage.PAINTS[rng.randi() % Garage.PAINTS.size()]
		var id := str(p["id"])
		var before := int(w.zl)
		var r: String = g.choose(id)
		if r == "buy":
			if bought.has(id):
				problems.append("seed %d: %s bought twice" % [seed_value, id])
			bought[id] = true
			paid += int(p["price"])
			if before - int(w.zl) != int(p["price"]):
				problems.append("seed %d: %s took %d zł (price %d)" % [seed_value, id, before - int(w.zl), int(p["price"])])
		elif int(w.zl) != before:
			problems.append("seed %d: a %s tap on %s changed the wallet" % [seed_value, r, id])
		if int(w.zl) < 0:
			problems.append("seed %d: the wallet went to %d zł" % [seed_value, w.zl])
		if r in ["buy", "switch"] and str(w.paint) != id:
			problems.append("seed %d: %s chosen, %s on the car" % [seed_value, id, w.paint])
	if earned - paid != int(w.zl):
		problems.append("seed %d: earned %d, paid %d, left %d" % [seed_value, earned, paid, w.zl])
	g.free()
	w.free()


func _check_save() -> void:
	var w := _wallet(500)
	w.persistent = true
	w.path = SCRATCH
	var g := _garage(w)
	g.choose("green")
	g.choose("blue")
	w.save()
	var back := _wallet(0)
	back.persistent = true
	back.path = SCRATCH
	back.load_save()
	_expect("saved paint", str(back.paint), "blue")
	_expect("saved owned", back.paints.keys().size(), 2)
	_expect("saved zł", int(back.zl), 500 - 180 - 200)
	_expect("green kept", back.paints.has("green"), true)
	# An old save (no [garage] section): the factory red, nothing owned.
	var old := ConfigFile.new()
	old.set_value("wallet", "zl", 77)
	old.save(SCRATCH)
	var w2 := _wallet(0)
	w2.persistent = true
	w2.path = SCRATCH
	w2.load_save()
	_expect("old save's paint", str(w2.paint), "red")
	_expect("old save's zł", int(w2.zl), 77)
	_expect("old save's paints", w2.paints.size(), 0)
	g.free()
	for n in [w, back, w2]:
		n.free()


func _check_car() -> void:
	var car: CharacterBody3D = Car.new()
	root.add_child(car)
	await process_frame
	var body: MeshInstance3D = car.get("_body_mesh")
	if body == null:
		problems.append("car: no body mesh")
		car.free()
		return
	var mat := body.material_override
	var nodes := car.find_children("*", "", true, false).size()
	var w := _wallet(1000)
	var g := _garage(w)
	g.car = car
	g.choose("black")
	var black: Dictionary = Garage.find("black")
	if car.get("paint") != black["paint"]:
		problems.append("car: paint %s after black (want %s)" % [car.get("paint"), black["paint"]])
	if body.material_override != mat:
		problems.append("car: the body's material changed")
	if car.find_children("*", "", true, false).size() != nodes:
		problems.append("car: %d nodes after painting (was %d)" % [car.find_children("*", "", true, false).size(), nodes])
	var cols: PackedColorArray = (body.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var has_black := false
	var has_red := false
	for c in cols:
		has_black = has_black or c.is_equal_approx(black["paint"])
		has_red = has_red or c.is_equal_approx(Color("#d8432f"))
	if not has_black or has_red:
		problems.append("car: the body's colours after black: black %s, red %s" % [has_black, has_red])
	g.free()
	w.free()
	car.free()


func _check_lines() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue.json"))
	var group: Array = (d as Dictionary).get("garage", []) if d is Dictionary else []
	var seen := {}
	for l: Array in group:
		if l.size() < 2 or str(l[0]) == "" or str(l[1]) == "":
			problems.append("garage line without Polish and English: %s" % [l])
			continue
		if str(l[0]).length() > 70:
			problems.append("garage line over 70 characters: %s" % l[0])
		var only: Variant = (l[2] as Dictionary).get("only", "") if l.size() > 2 and l[2] is Dictionary else ""
		seen[str(only)] = true
	for t in TAGS:
		if not seen.has(t):
			problems.append("no garage line for '%s'" % t)


func _check_eggs() -> void:
	var w := _wallet(0)
	var book: EggBook = EggBook.new()
	book.wallet = w
	root.add_child(book)
	if not book.load_eggs():
		problems.append("eggs: no eggs.json")
		return
	for id in ["e01", "e21"]:
		if not id in book.reachable():
			problems.append("%s still waits" % id)
	# E01: the black car at Lusterko's door (crowds.gd), its night and hours (egg_book.gd).
	_expect("door egg, black at Lusterko", Crowds.door_egg("lusterko", "black"), "e01")
	_expect("door egg, red at Lusterko", Crowds.door_egg("lusterko", "red"), "")
	_expect("door egg, black at Smoła", Crowds.door_egg("smola", "black"), "")
	var night := {"pos": Vector3.ZERO, "kmh": 3.0, "look": "Night", "hour": 1.5, "weekday": 6, "paint": "black"}
	var tue := night.duplicate()
	tue["weekday"] = 3
	var early := night.duplicate()
	early["hour"] = 21.0
	early["weekday"] = 5
	var sun_night := night.duplicate()
	sun_night["weekday"] = 7  # Sunday 01:30 is Saturday's night
	var red := night.duplicate()
	red["paint"] = "red"
	_expect("E01 red", book.fire("e01", red), false)
	_expect("E01 Tuesday night", book.fire("e01", tue), false)
	_expect("E01 Friday 21:00", book.fire("e01", early), false)
	var r0 := int(w.respect)
	_expect("E01 Saturday's night, 01:30 Sunday", book.fire("e01", sun_night), true)
	_expect("E01 again", book.fire("e01", night), false)
	_expect("E01 respect", int(w.respect) - r0, 50)
	# E21: stop 2 s within 25 m of Glon, green.
	var e21: Dictionary = book.eggs[book.by_id["e21"]].duplicate(true)
	e21["at"] = Vector2(100.0, 200.0)
	var green := {"pos": Vector3(110.0, 0.0, 200.0), "kmh": 0.0, "flying": false, "paint": "green"}
	var not_green := green.duplicate()
	not_green["paint"] = "red"
	var mem := {}
	var fired := false
	for i in 8:
		if EggBook.step(e21, not_green, mem, 0.5):
			fired = true
	_expect("E21 red", fired, false)
	mem = {}
	var n := -1
	for i in 8:
		if EggBook.step(e21, green, mem, 0.5):
			n = i
			break
	_expect("E21 green, steps of 0.5 s to fire", n, 3)
	var r1 := int(w.respect)
	_expect("E21 recorded", book.record("e21"), true)
	_expect("E21 again", book.record("e21"), false)
	_expect("E21 respect", int(w.respect) - r1, 15)
	book.free()
	w.free()
