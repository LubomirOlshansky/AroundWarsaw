extends Node
## Loop 3h slice 2 (docs/DEMO.md 6.3, checklist F4): the 20 Syrenki, small mermaid figurines by
## the kerb round the demo's districts, from `data/syrenki.json`.
##
## - **Where.** Each has an anchor (a notebook place, or a lat/lon `near`). `place_all` finds the
##   nearest ground-level street of the lane graph within REACH of it (FAR_REACH if none; no tunnel, no deck) and
##   stands the figurine on the kerb side towards the anchor: past the outer lane's edge and a
##   couple of metres more, never in a lane; a car on that street passes within a few metres.
##   Deterministic (no random). Height from the terrain.
## - **The prop.** ONE MultiMesh for all 20 (one draw call): props.gd `mermaid()` scaled to a
##   figurine FIGURE_HEIGHT tall, the actors' material, no shadow, no collision. A found one is
##   hidden (a zero-scale transform), at load too.
## - **The find.** Five times a second (`CHECK_EVERY`, a timer: nothing runs per frame) the
##   vehicle is compared with the figurines not found yet: closer than `near` metres on the
##   ground plane (and, flying, less than FLY_REACH m up). The first find: kept in the save
##   (wallet.gd `syrenki`: id -> day), +`respect`, the card "SYRENKA n/20 · MERMAID", the blip and
##   a short buzz. A count that reaches a reward's `at` gives it once (the count only grows): złoty
##   and respect, and a paint (garage.gd: derived from the count, `syrenki` on the paint) with its
##   own card, which waits for the first card to end (hud.show_note shows one at a time).
## - **Completion.** Each is listed under its district (districts.gd `add_syrenka`), so it counts
##   in the district's % on the full map.
## Cost: the 5 Hz look (`spent_usec`: the bench's "syrenki" line).

const Districts := preload("res://scripts/districts.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Notebook := preload("res://scripts/notebook.gd")
const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

const DATA_PATH := "res://data/syrenki.json"
const PLACES_PATH := "res://data/places.json"
## Seconds between two looks (5 Hz).
const CHECK_EVERY := 0.2
## The street may be this far (m) from the anchor.
const REACH := 150.0
## Where a big anchor (the Palace's block, the stadium) has no street within REACH: the street may
## be this far (m) instead. Anything placed further than 80 m from its anchor is listed in the report.
const FAR_REACH := 260.0
## The figurine's height (m), plinth included: props.gd's mermaid is about 5.3 m with its plinth;
## at 1.7 m she was the size of a walker and did not read from the camera (slice 2's shots).
const FIGURE_HEIGHT := 3.0
## The marker over her: a cyan "diamond" (a cube stood on its corner, Models LIT_SIGN in the
## card's colour, so it glows at night), MARKER_SIZE m across, its centre MARKER_UP m up.
const MARKER_SIZE := 0.9
const MARKER_UP := 4.0
## Flying: found when less than this many metres above the figurine.
const FLY_REACH := 20.0
## Metres from the outer lane's edge to the figurine, and the least from a lane's centre to it
## (half a lane and a kerb).
const KERB_GAP := 2.0
const KERB_CLEAR := 1.0
## The card's colour (the Syrenki's own: a sea teal, not the eggs' or the notebook's).
const COLOUR := Color("#5ad1e6")
## Seconds a card stays (hud.gd's _note_left 5.5) plus a beat: the reward card waits this long.
const CARD_TIME := 5.8
## The map's origin, for the map-free projection (districts.gd does the same).
const ORIGIN := [52.234, 21.024]

## One per Syrenka: syrenki.json's fields plus `anchor` (Vector2, map metres), `pos` (Vector2,
## INF until placed), `y`, `lane` ([edge, lane, s] of the lane that passes it) and `gap` (m from
## the anchor).
var entries: Array[Dictionary] = []
var by_id := {}
var rewards: Array = []
## The pickup radius (m) and the respect for a find.
var near := 7.0
var respect := 5
var wallet: Node
var hud: CanvasLayer
## districts.gd: each Syrenka is listed under its district (null: not).
var districts: Node
## The 3D world inside the game's SubViewport (main.gd `world`): the figurines go there, not
## under this node, or they would render in no viewport the camera sees (null in the checks).
var world: Node3D
## The vehicle now: [position (Vector3), km/h, flying, altitude, away] (notebook.gd's probe).
var probe: Callable
var blip: Callable
var log_on := false
## Microseconds spent in the looks since the start (the bench's "syrenki" line).
var spent_usec := 0
var ready_ok := false
var _mm: MultiMesh
var _node: MultiMeshInstance3D
var _t := 0.0
## Cards waiting for the one on screen to end: [title, body] and the seconds to the next.
var _queue: Array[PackedStringArray] = []
var _wait := 0.0


## Reads syrenki.json (no map). `points`: place id -> its map point (Vector2; notebook.gd's
## resolved `at`); a place missing there takes places.json's `near` hint projected with the map's
## origin (the map-free way). Lists each under its district. False if the file is missing or does
## not parse.
func load_data(points := {}) -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not json is Dictionary:
		push_error("syrenki: %s does not parse" % DATA_PATH)
		return false
	near = float(json.get("near", near))
	respect = int(json.get("respect", respect))
	rewards = json.get("rewards", [])
	var hints := _place_hints()
	entries.clear()
	by_id.clear()
	for s: Dictionary in json.get("syrenki", []):
		var e := s.duplicate(true)
		var anchor := Vector2.INF
		if s.has("place"):
			var id := str(s["place"])
			if points.has(id) and points[id] != Vector2.INF:
				anchor = points[id]
			elif hints.has(id):
				anchor = hints[id]
		elif s.has("near"):
			var n: Array = s["near"]
			anchor = Notebook.project(ORIGIN, float(n[0]), float(n[1]))
		e["anchor"] = anchor
		e["pos"] = Vector2.INF
		e["y"] = 0.0
		e["lane"] = []
		e["gap"] = INF
		by_id[str(s["id"])] = entries.size()
		entries.append(e)
		if districts != null:
			districts.add_syrenka(str(s["id"]), str(s.get("district", "")))
	ready_ok = true
	return true


## Place id -> its `near` hint projected (map metres), from places.json.
func _place_hints() -> Dictionary:
	var out := {}
	var places: Variant = JSON.parse_string(FileAccess.get_file_as_string(PLACES_PATH)) if FileAccess.file_exists(PLACES_PATH) else null
	if places is Dictionary:
		for p: Dictionary in places.get("places", []):
			var n: Array = p.get("near", [])
			if n.size() == 2:
				out[str(p["id"])] = Notebook.project(ORIGIN, float(n[0]), float(n[1]))
	return out


# --- placing ---------------------------------------------------------------------------------

## Puts every figurine on the kerb of the street nearest its anchor and builds the one MultiMesh
## (needs the map for the ground and the lane graph for the streets). Returns how many were placed.
func place_all(map: Node3D, graph) -> int:
	var placed := 0
	for e in entries:
		var anchor: Vector2 = e["anchor"]
		if anchor == Vector2.INF or graph == null:
			continue
		var spot := kerb_spot(graph, anchor)
		if spot.is_empty():
			spot = kerb_spot(graph, anchor, FAR_REACH)
		if spot.is_empty():
			push_warning("syrenki: %s: no street within %.0f m of the anchor %s (nearest of any kind: %.0f m)" % [e["id"], FAR_REACH, anchor, _nearest_any(graph, anchor)])
			continue
		var pos: Vector2 = spot["pos"]
		e["pos"] = pos
		e["y"] = map.ground_height(pos.x, pos.y) if map != null else 0.0
		e["lane"] = spot["lane"]
		e["face"] = spot["face"]
		e["gap"] = pos.distance_to(anchor)
		placed += 1
	_build_multimesh()
	if log_on:
		for e in entries:
			var p: Vector2 = e["pos"]
			print("syrenki: %s at %.1f, %.1f, %.1f m from its anchor, %.1f m from a lane%s" % [e["id"], p.x, p.y,
					float(e["gap"]), lane_distance(graph, p), " (found)" if is_found(str(e["id"])) else ""])
		print("syrenki: %d/%d placed, %d found" % [placed, entries.size(), found_count()])
	return placed


## The kerb spot for anchor `a`: {pos: Vector2, face: Vector2 (towards the street's centre),
## lane: [edge, lane, s]}, or {} if no ground-level street is within `reach_max`.
func kerb_spot(graph, a: Vector2, reach_max := REACH) -> Dictionary:
	var best_e := -1
	var best_d := reach_max
	var best_c := Vector2.ZERO
	var best_dir := Vector2.ZERO
	var seen := {}
	var steps := int(ceil(reach_max / (graph.CELL * 0.5)))
	for dx in range(-steps, steps + 1):
		for dz in range(-steps, steps + 1):
			var key: int = graph.cell_key(a + Vector2(dx, dz) * graph.CELL * 0.5)
			if seen.has(key) or not graph.grid.has(key):
				continue
			seen[key] = true
			for edge: int in graph.grid[key]:
				if graph.e_tn[edge] >= 0 or graph.e_dk[edge] >= 0 or graph.e_bridge[edge] == 1:
					continue
				var i0: int = graph.e_first[edge]
				for k in graph.e_count[edge] - 1:
					var p0: Vector2 = graph.pts[i0 + k]
					var ab: Vector2 = graph.pts[i0 + k + 1] - p0
					var l2 := ab.length_squared()
					if l2 < 0.0001:
						continue
					var q := p0 + ab * clampf((a - p0).dot(ab) / l2, 0.0, 1.0)
					var d := a.distance_to(q)
					# Ties go to the lower edge id, so the result never depends on the grid's order.
					if d < best_d or (d == best_d and edge < best_e):
						best_d = d
						best_e = edge
						best_c = q
						best_dir = ab.normalized()
	if best_e < 0:
		return {}
	var side := Vector2(-best_dir.y, best_dir.x)
	var sgn := 1.0 if (a - best_c).dot(side) >= 0.0 else -1.0
	var reach := 0.0
	for k in graph.e_lanes[best_e]:
		reach = maxf(reach, absf(graph.lane_offset(best_e, k)))
	var half: float = graph.e_lw[best_e] * 0.5
	var off := reach + half + KERB_GAP
	var pos := best_c + side * sgn * off
	var lane: Array = []
	# Out of every lane (the other direction's too): a metre more until a lane centre is half a
	# lane and a kerb away.
	for i in 12:
		lane = graph.snap(pos, 20.0)
		if lane.is_empty():
			break
		var q: Vector2 = graph.point_at(lane[0], lane[2], graph.lane_offset(lane[0], lane[1]))
		if q.distance_to(pos) >= half + KERB_CLEAR:
			break
		off += 1.0
		pos = best_c + side * sgn * off
	if lane.is_empty():
		lane = graph.snap(pos, 40.0)
	return {"pos": pos, "face": (best_c - pos).normalized(), "lane": lane}


## Metres from `a` to the nearest edge of any kind (tunnels and decks too), for the warning.
func _nearest_any(graph, a: Vector2) -> float:
	var best := INF
	for edge in graph.e_a.size():
		var i0: int = graph.e_first[edge]
		for k in graph.e_count[edge] - 1:
			var p0: Vector2 = graph.pts[i0 + k]
			var ab: Vector2 = graph.pts[i0 + k + 1] - p0
			var l2 := ab.length_squared()
			if l2 > 0.0001:
				best = minf(best, a.distance_to(p0 + ab * clampf((a - p0).dot(ab) / l2, 0.0, 1.0)))
	return best


## Metres from point `p` to the nearest lane centre-line point of the lane graph (INF: none near).
func lane_distance(graph, p: Vector2) -> float:
	if graph == null or p == Vector2.INF:
		return INF
	var hit: Array = graph.snap(p, 40.0)
	if hit.is_empty():
		return INF
	return (graph.point_at(hit[0], hit[2], graph.lane_offset(hit[0], hit[1])) as Vector2).distance_to(p)


func _build_multimesh() -> void:
	var mesh := figurine_mesh()
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.mesh = mesh
	InstanceBuffers.prepare(_mm)
	_mm.instance_count = entries.size()
	for i in entries.size():
		_set_instance(i)
	InstanceBuffers.whiten(_mm)
	if _node != null:
		_node.queue_free()
	_node = MultiMeshInstance3D.new()
	_node.name = "SyrenkiFigurines"
	_node.multimesh = _mm
	_node.material_override = Models.material()
	_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if world != null:
		world.add_child(_node)
	else:
		add_child(_node)


## The figurine and its marker as ONE mesh (one MultiMesh, one draw call): props.gd's mermaid
## scaled to FIGURE_HEIGHT with her foot at 0, and a cyan diamond floating over her (a cube
## stood on a corner), so a Syrenka reads from the follow camera by day and glows by night.
static func figurine_mesh() -> ArrayMesh:
	var statue := Props.mermaid()
	var box := statue.get_aabb()
	var k := FIGURE_HEIGHT / maxf(box.size.y, 0.01)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(statue, 0, Transform3D(Basis.from_scale(Vector3(k, k, k)), Vector3(0.0, -box.position.y * k, 0.0)))
	var cube := SurfaceTool.new()
	cube.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(cube, Vector3.ZERO, Vector3.ONE * MARKER_SIZE, COLOUR, Models.LIT_SIGN)
	var tilt := Basis(Vector3.RIGHT, atan(1.0 / sqrt(2.0))) * Basis(Vector3.FORWARD, PI * 0.25)
	st.append_from(cube.commit(), 0, Transform3D(tilt, Vector3(0.0, MARKER_UP, 0.0)))
	return st.commit()


## Instance `i`: the figurine on the kerb facing the street, or a zero-scale point when found
## (or not placed).
func _set_instance(i: int) -> void:
	if _mm == null:
		return
	var e: Dictionary = entries[i]
	var pos: Vector2 = e["pos"]
	if pos == Vector2.INF or is_found(str(e["id"])):
		_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		return
	var face: Vector2 = e.get("face", Vector2(0.0, -1.0))
	# The mermaid looks down -Z (eggs.gd): turn her to face the street.
	var yaw := atan2(-face.x, -face.y)
	var basis := Basis(Vector3.UP, yaw)
	_mm.set_instance_transform(i, Transform3D(basis, Vector3(pos.x, float(e["y"]), pos.y)))


## The car's spot for --syrenka=: [position, yaw] on the lane that passes figurine `i`, `back`
## metres before it (the figurine ahead on the kerb), or [].
func drive_in(graph, i: int, back := 25.0) -> Array:
	if i < 0 or i >= entries.size() or graph == null:
		return []
	var lane: Array = entries[i]["lane"]
	if lane.is_empty():
		return []
	var edge: int = lane[0]
	var s := clampf(float(lane[2]) - back, graph.e_s0[edge], graph.e_s1[edge])
	var q: Vector2 = graph.point_at(edge, s, graph.lane_offset(edge, lane[1]))
	var d: Vector2 = graph.direction(edge, s)
	return [Vector3(q.x, graph.height(edge, s), q.y), atan2(-d.x, -d.y)]


## The index of `spec` (an id or a 1-based number), or -1.
func index_of(spec: String) -> int:
	if by_id.has(spec):
		return by_id[spec]
	if spec.is_valid_int():
		var n := spec.to_int()
		if n >= 1 and n <= entries.size():
			return n - 1
	return -1


# --- the find --------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not ready_ok or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var s: Array = probe.call()
	tick(s[0] as Vector3, bool(s[2]), float(s[3]), bool(s[4]))
	spent_usec += Time.get_ticks_usec() - t0


## One look with the vehicle at `at` (`flying`, `altitude` above the ground; `away`: the title
## screen or TEST · BENCH: nothing happens). Also runs the waiting card's clock.
func tick(at: Vector3, flying := false, altitude := 0.0, away := false) -> void:
	if away or wallet == null:
		return
	_step_queue()
	var p := Vector2(at.x, at.z)
	var r2 := near * near
	for e in entries:
		var pos: Vector2 = e["pos"]
		if pos == Vector2.INF or p.distance_squared_to(pos) >= r2 or wallet.syrenki.has(e["id"]):
			continue
		if flying and altitude >= FLY_REACH:
			continue
		collect(str(e["id"]))


## Syrenka `id` found: false if it was found already (or is unknown). The save, the respect, the
## card, the blip and the buzz, then a reward if the count reached one.
func collect(id: String, date := 0) -> bool:
	if wallet == null or not by_id.has(id) or wallet.syrenki.has(id):
		return false
	var e: Dictionary = entries[by_id[id]]
	wallet.syrenki[id] = date if date > 0 else Districts.today()
	wallet.add_respect(respect)  # saves
	var count := found_count()
	var name: Array = e.get("name", ["", ""])
	var line: Array = e.get("line", ["", ""])
	_note("SYRENKA %d/%d · MERMAID" % [count, entries.size()], "%s\n%s\n%s" % [name[0], line[0], line[1]])
	if blip.is_valid():
		blip.call()
	Input.vibrate_handheld(40, 0.4)
	_set_instance(by_id[id])
	if log_on:
		print("syrenki: found %s (%d/%d), +%d respect" % [id, count, entries.size(), respect])
	for r: Dictionary in rewards:
		if int(r.get("at", -1)) == count:
			_reward(r, count)
	return true


## Reward `r` (given once: it is derived from the count, which only grows): złoty and respect;
## a paint opens by itself (garage.gd `rule` reads the count). Its card follows the find's.
func _reward(r: Dictionary, count: int) -> void:
	var zl := int(r.get("zl", 0))
	var gain := int(r.get("respect", 0))
	if zl > 0:
		wallet.pay(zl, gain)  # saves
	elif gain > 0:
		wallet.add_respect(gain)
	var text: Array = r.get("text", ["", ""])
	_note("SYRENKI %d/%d · NAGRODA · REWARD" % [count, entries.size()], "%s\n%s" % [text[0], text[1]])
	if log_on:
		print("syrenki: reward at %d: %d zł, %d respect%s" % [count, zl, gain, ", paint " + str(r["paint"]) if r.has("paint") else ""])


## Shows a card now, or after the one on screen (hud.show_note replaces what is there).
func _note(title: String, body: String) -> void:
	if hud == null:
		return
	if _wait <= 0.0 and _queue.is_empty():
		hud.show_note(title, body, COLOUR)
		_wait = CARD_TIME
	else:
		_queue.append(PackedStringArray([title, body]))


func _step_queue() -> void:
	if _wait > 0.0:
		_wait -= CHECK_EVERY
	if _wait <= 0.0 and not _queue.is_empty() and hud != null:
		var n: PackedStringArray = _queue.pop_front()
		hud.show_note(n[0], n[1], COLOUR)
		_wait = CARD_TIME


func is_found(id: String) -> bool:
	return wallet != null and wallet.syrenki.has(id)


func found_count() -> int:
	return wallet.syrenki.size() if wallet != null else 0


## --syrenki=all|none|<n>|<id>,...: the record for a test run, in memory (no cards, no rewards;
## use with --nosave). `n`: the first n.
func preset(spec: String) -> void:
	if wallet == null:
		return
	for part in spec.split(",", false):
		if part == "none":
			wallet.syrenki.clear()
		elif part == "all":
			for e in entries:
				wallet.syrenki[e["id"]] = Districts.today()
		elif part.is_valid_int():
			for i in mini(part.to_int(), entries.size()):
				wallet.syrenki[entries[i]["id"]] = Districts.today()
		elif by_id.has(part):
			wallet.syrenki[part] = Districts.today()
	for i in entries.size():
		_set_instance(i)
	print("syrenki: --syrenki=%s: %d/%d found" % [spec, found_count(), entries.size()])
