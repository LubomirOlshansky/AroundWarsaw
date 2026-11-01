extends SceneTree
## The railway's trains (T1 of docs/design/railway.md, scripts/trains.gd), headless, from the
## committed map data (map/centrum.json: the rail tracks and the platforms), seeded:
##   1. the track graph: ways in and out at the map's edges and the tunnel's mouths (at least one
##      at each mouth), every piece kept leads to a way out;
##   2. the cars: one surface each on the one actor material, at most 400 triangles a car;
##   3. 40 simulated minutes at 10 updates a second: trains come in, run and leave (at least 6
##      exits), stop at Ochota, Powiśle and Stadion, the long-distance kind never stops, and no
##      two trains ever hold one track piece at once.
## Prints "check_trains: OK (...)" or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_trains.gd

const Trains := preload("res://scripts/trains.gd")

## The stations whose platforms must see a stop (their OSM building's centre).
const STATIONS := {"Ochota": Vector2(-2313.0, 929.0), "Powiśle": Vector2(290.0, 25.0), "Stadion": Vector2(1391.0, -1328.0)}
const MINUTES := 40.0
const DT := 0.1

var problems: Array[String] = []


func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var digest := PackedStringArray()
	var t: Trains = Trains.new()
	t.setup(null, data)
	_check_graph(t, digest)
	_check_look(digest)
	_check_run(t, data, digest)
	t.free()
	if problems.is_empty():
		print("check_trains: OK (%s)" % " · ".join(digest))
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_trains: %d problems" % problems.size())
		quit(1)


func _check_graph(t: Trains, digest: PackedStringArray) -> void:
	var sources: PackedInt32Array = t._sources
	var sinks := 0
	for i in t._sink.size():
		sinks += t._sink[i]
	if sources.size() < 4 or sinks < 4:
		problems.append("only %d ways in and %d out" % [sources.size(), sinks])
	for q: Vector2 in Trains.PORTALS:
		var found := false
		for i in sources:
			found = found or t._pts[i][0].distance_to(q) < Trains.PORTAL_R
		if not found:
			problems.append("no way in at the tunnel mouth %s" % q)
	digest.append("%d pieces, %d ways in, %d out" % [t._pts.size(), sources.size(), sinks])


func _check_look(digest: PackedStringArray) -> void:
	var most := 0
	for kind: Dictionary in Trains.KINDS:
		for cab in [true, false]:
			var m := Trains.car_mesh(kind, cab)
			if m.get_surface_count() != 1:
				problems.append("%s car has %d surfaces" % [kind["name"], m.get_surface_count()])
			var tris := m.surface_get_array_len(0) / 3
			most = maxi(most, tris)
	if most > 400:
		problems.append("a car has %d triangles (budget 400)" % most)
	digest.append("cars up to %d tris" % most)


func _check_run(t: Trains, data: Dictionary, digest: PackedStringArray) -> void:
	var steps := int(MINUTES * 60.0 / DT)
	var moved := 0.0
	var last := {}
	for n in steps:
		t.step(DT)
		for tr in t.trains:
			if tr.active:
				var p := Vector2(tr.pos.x, tr.pos.z)
				if last.has(tr) and last[tr].distance_to(p) < 50.0:
					moved += last[tr].distance_to(p)
				last[tr] = p
			else:
				last.erase(tr)
	var exits := 0
	for tr in t.trains:
		exits += tr.exits
	if exits < 6:
		problems.append("only %d trains left the map in %d minutes" % [exits, int(MINUTES)])
	if moved < 20000.0:
		problems.append("the trains ran only %d m in all" % int(moved))
	if t.most_on_a_piece > 1:
		problems.append("%d trains held one track piece at once" % t.most_on_a_piece)
	var seen := {}
	for e: Vector2i in t.stop_log:
		if not bool(Trains.KINDS[e.y]["stops"]):
			problems.append("a %s train stopped at a platform" % Trains.KINDS[e.y]["name"])
		var at: Vector2 = t._platforms[e.x]
		for name: String in STATIONS:
			if at.distance_to(STATIONS[name]) < 250.0:
				seen[name] = seen.get(name, 0) + 1
	for name: String in STATIONS:
		if not seen.has(name):
			problems.append("no train stopped at %s" % name)
	digest.append("%d min: %d exits, %.0f km run, stops %s" % [int(MINUTES), exits, moved / 1000.0, str(seen)])
