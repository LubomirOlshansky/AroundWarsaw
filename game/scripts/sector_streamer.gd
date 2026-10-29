extends Node
## Loop 3c: the city in 512 m sectors, streamed round the camera (docs/DEMO.md 2.4).
##
## The map node (map_builder.gd) is the global index: heights, decks, tunnels, the water test,
## the roof and picking grids, the kerbs the car feels, the game's data (prebuilt: loaded from
## map/index.res; runtime: set up from map/index.json). Under it, `Sectors` holds the sectors
## in full detail and `Proxies` one low-detail mesh per sector (sector_proxies.gd).
##
## Which sectors are in full detail: the 3 x 3 round the focus's sector (the car's physics
## needs its colliders), the next row once the focus comes within 192 m of its sector's edge,
## and every sector the camera's view needs: its box, from its lowest ground to its tallest
## roof and grown by 128 m, meets the camera's frustum (a tower two sectors off can stand in
## the view). A sector goes again once it is 256 m past that reach (hysteresis) and out of
## the view grown by 256 m.
##
## Loading never stalls the frame: one sector at a time, a worker thread loads and instantiates
## its scene (prebuilt: map/sectors/s_<i>_<j>.scn) or builds it from its file (the runtime,
## editor path: map/sectors/<i>_<j>.json, map_builder.gd build_sector). The main thread then
## adds its nodes a few a frame under a hidden root, spending at most BUDGET_USEC; the root
## shows (and the proxy hides) once every node is in. A sector the car stands in that isn't
## in yet (a jump: a tow, a race start) loads at once.
##
## --sectors=all loads every sector at the start and keeps them (the old behaviour, pixel
## diffs); --stream-log prints every load and unload with its frame and main-thread ms, and (loop
## G0+) each worker load: its load and instantiate ms and the slowest frame while it ran, split
## into the frame's phases (process after the streamer, draw, to the next physics frame, physics).

const MapBuilder := preload("res://scripts/map_builder.gd")
const Proxies := preload("res://scripts/sector_proxies.gd")
const INDEX_SCENE := "res://map/index.res"
const INDEX_JSON := "res://map/index.json"
const PROXY_SCENE := "res://map/proxies.scn"
const SECTOR := MapBuilder.SECTOR
## The focus's 3 x 3, and the next row within 192 m of its sector's edge (a square round the
## focus this far out); a sector stays loaded until it is KEEP_REACH out.
const LOAD_REACH := SECTOR + 192.0
const KEEP_REACH := LOAD_REACH + 256.0
## At the start, the sectors within this much of the start go in at once (what the view there
## shows); the rest of the ring streams in over the first seconds.
const START_REACH := 320.0
## The view's boxes are grown this much to load, and this much to keep; a sector farther than
## VIEW_RANGE from the focus is never in view (the camera's far plane, a tower's height).
const VIEW_GROW := 128.0
const VIEW_KEEP := 256.0
const VIEW_RANGE := 1800.0
## The car's physics needs every sector within this of it in (a wall or parapet across a border).
const CAR_REACH := 40.0
## The frames at the start the frame-time numbers leave out (shaders compiling on first sight).
const WARM_UP := 120
## Main-thread time a frame for adding sector nodes (microseconds).
const BUDGET_USEC := 3000

## A sector's root got its nodes (before they go into the tree, and again once all are in):
## main.gd gives them the time of day, the quality's shadows, the fine detail and --exp.
signal sector_ready(root: Node3D)

enum { QUEUED, WANTED, LOADING, ADDING, IN }

var map: Node3D
var prebuilt := false
var load_all := false
## --sectors=proxies: only the sectors the car needs, the rest as proxies (to look at them).
var proxies_only := false
var log := false
var keys: Array[Vector2i] = []
var _sectors: Node3D
var _proxies: Node3D
var _proxy := {}   # key -> MeshInstance3D
## key -> {"s": state, "root", "queue": nodes still to add, "t0": usec it was wanted, "ms": main-thread ms}
var _state := {}
## The worker: a thread per sector (joined when it is done, so nothing it made lingers at the
## end the way a pool thread's would), its sector and the root it made.
var _thread: Thread
var _task_key := Vector2i.ZERO
var _task_root: Node3D
## --stream-log (loop G0+): when the worker started, loaded and instantiated (usec), and each
## update's start in the meantime, to name the slowest frame during a load and what it overlapped.
var _task_t := PackedInt64Array([0, 0, 0])
var _task_ticks := PackedInt64Array()
## The same frames' phases (usec stamps of frame_pre_draw, frame_post_draw, the first physics_frame
## after it, process_frame): where the time of a slow one went.
var _task_phases: Array[PackedInt64Array] = []
var _stamps := PackedInt64Array([0, 0, 0, 0])
var frame := 0
## Per frame: the main thread's streaming time (usec) and the frame's own (usec, wall clock).
var stream_usec := PackedInt32Array()
var frame_usec := PackedInt32Array()
## The same, only for the frames that loaded, added or unloaded something (0 for the others).
var busy_usec := PackedInt32Array()
var _worked := false
## What adding a node of each class cost lately (usec, a slowly falling maximum).
var _add_cost := {}
var _last_tick := 0
## Frames where the car's sector or a sector the view needs wasn't in yet, and the forced loads.
var missing_frames := 0
var forced := 0
var loads := 0
var unloads := 0
var _view_planes: Array[Plane] = []
## Loop G0+: each streamed sector's main-thread ms (the forced and start-up loads apart), and per
## kind of step (a node class added, the hand-over, the finish, an unload) its count, total and
## worst usec, for the soak's result.
var sector_ms := PackedFloat32Array()
var _kinds := {}


## Opens the city: the index, the proxies and the sectors round `at` (in full, before the first
## frame; the spawn when `at` is INF). Returns the game's data (index.json's).
func open(world: Node3D, use_prebuilt: bool, building_mat: ShaderMaterial, flat_mat: ShaderMaterial, at: Vector3) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	prebuilt = use_prebuilt and ResourceLoader.exists(INDEX_SCENE)
	if prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
	else:
		map = MapBuilder.new()
		var index: Variant = JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON))
		if not index is Dictionary:
			push_error("sectors: no %s (run tools/bake_sectors.py)" % INDEX_JSON)
			return {}
		map.setup_streamed(index, building_mat, flat_mat)
	map.name = "City"
	world.add_child(map)
	for k: Array in map.index_data["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	var t_index := Time.get_ticks_msec() - t0
	if not prebuilt:
		# The runtime path: every sector's cells of the roof and picking grids first (missions,
		# eggs and the helicopter read them over the whole map at the start).
		for key in keys:
			map.build_sector(key, true).free()
		map.measure_sectors()
	var t_roofs := Time.get_ticks_msec() - t0 - t_index
	_sectors = Node3D.new()
	_sectors.name = "Sectors"
	# Loop G0+: the city stands still, so its nodes take no physics interpolation (as the people's
	# and the pigeons' MultiMeshes already didn't). With it on (the project's setting), adding a
	# MultiMesh node cost the main thread 14 ms on average on the iPhone 11 (37 ms at worst; the
	# Mac 1.4 ms), a sector 188 ms spread over its frames, every load frame over the 3 ms budget;
	# off, 0.002 ms and 0.35 ms a sector. Every sector, the proxies and what they hold inherit this;
	# nothing in them moves on the physics tick.
	_sectors.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	map.add_child(_sectors)
	var t_proxies := Time.get_ticks_msec()
	# The runtime path takes the baked proxies too when there are any (they only show while a
	# sector loads: an older bake's shapes for a moment do no harm); else it makes them (~1 s).
	if ResourceLoader.exists(PROXY_SCENE):
		_proxies = (load(PROXY_SCENE) as PackedScene).instantiate()
	else:
		_proxies = Proxies.build_all(map, keys)
	t_proxies = Time.get_ticks_msec() - t_proxies
	_proxies.name = "Proxies"
	_proxies.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	map.add_child(_proxies)
	for c in _proxies.get_children():
		_proxy[_key_of(c.name)] = c
	for key in keys:
		_state[key] = {"s": QUEUED}
	if at == Vector3.INF:
		var spawn: Dictionary = map.index_data.get("spawn", {})
		at = Vector3(float(spawn.get("x", 0.0)), 0.0, float(spawn.get("z", 0.0)))
	var start := 0
	var t_start := Time.get_ticks_msec()
	for key in keys:
		if load_all or (_in_reach(key, at, CAR_REACH if proxies_only else START_REACH) or key == MapBuilder.sector_of(at.x, at.z)):
			_load_now(key)
			start += 1
	print("sectors: %s city, %d sectors of %d m; index %d ms%s, proxies %d ms, %d sectors in full at the start in %d ms" % [
			"prebuilt" if prebuilt else "runtime", keys.size(), SECTOR, t_index,
			("" if prebuilt else ", roof pass %d ms" % t_roofs), t_proxies, start, Time.get_ticks_msec() - t_start])
	_last_tick = Time.get_ticks_usec()
	return map.index_data


## The whole streamed city at once, for the checks that sweep the map (check_drive, check_water,
## check_landmarks): the index and every sector under `parent`, prebuilt (map/index.res and the
## sector scenes) or built from the files (the runtime path). `data` is set to the game's data.
static func open_whole(parent: Node, use_prebuilt: bool) -> Node3D:
	var map: Node3D
	var keys: Array[Vector2i] = []
	if use_prebuilt:
		map = (load(INDEX_SCENE) as PackedScene).instantiate()
		parent.add_child(map)
	else:
		map = MapBuilder.new()
		parent.add_child(map)
		map.setup_streamed(JSON.parse_string(FileAccess.get_file_as_string(INDEX_JSON)), ShaderMaterial.new(), ShaderMaterial.new())
	map.data = map.index_data
	for k: Array in map.index_data["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	for key in keys:
		var root: Node3D
		if use_prebuilt:
			root = (load("res://map/sectors/%s.scn" % MapBuilder.sector_name(key)) as PackedScene).instantiate()
		else:
			root = map.build_sector(key)
		map.add_child(root)
	if not use_prebuilt:
		map.measure_sectors()
	return map


## Quitting: the worker's load or build ends before the map it reads goes, and what is not in
## the tree (its result, the nodes still queued) is freed.
func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	if _task_root != null:
		_task_root.free()
		_task_root = null
	for key in keys:
		for c: Node in _state[key].get("queue", []):
			c.free()
		_state[key]["queue"] = []


## Every frame (main.gd, after the camera moved): what to load, add, unload. `focus` is the
## camera's focus, `car` where the car (or helicopter) is.
func update(focus: Vector3, car: Vector3, cam: Camera3D) -> void:
	var t0 := Time.get_ticks_usec()
	frame_usec.append(t0 - _last_tick)
	_last_tick = t0
	frame += 1
	if log:
		if _thread != null:
			_task_ticks.append(t0)
			_task_phases.append(_stamps.duplicate())
		_stamps.fill(0)
	_worked = false
	if load_all:
		stream_usec.append(0)
		busy_usec.append(0)
		return
	_view_planes = cam.get_frustum() if cam != null else []
	var car_key := MapBuilder.sector_of(car.x, car.z)
	var missing := false
	# The car's own sector must be in, and any within CAR_REACH of it (their colliders): load them
	# now if a jump put the car somewhere new.
	for key in keys:
		if _state[key]["s"] != IN and (key == car_key or _in_reach(key, car, CAR_REACH)):
			missing = true
			forced += 1
			_load_now(key)
	if proxies_only:
		stream_usec.append(Time.get_ticks_usec() - t0)
		busy_usec.append(stream_usec[-1] if _worked else 0)
		return
	for key in keys:
		var st: Dictionary = _state[key]
		# The view tests from the widest grow in (a sector far off is out of every one).
		var keep_view := _in_reach(key, focus, VIEW_RANGE) and _in_view(key, VIEW_KEEP)
		var want_view := keep_view and _in_view(key, VIEW_GROW)
		var want := want_view or _in_reach(key, focus, LOAD_REACH)
		if want and st["s"] == QUEUED:
			_state[key] = {"s": WANTED, "t0": Time.get_ticks_usec(), "ms": 0.0}
		elif not want and st["s"] != QUEUED and not keep_view and not _in_reach(key, focus, KEEP_REACH):
			_unload(key)
		elif want_view and st["s"] != IN and _in_view(key, 0.0):
			missing = true
	if missing:
		missing_frames += 1
	var t1 := Time.get_ticks_usec()
	# One step a frame: a finished sector handed over (its state applied, its nodes queued), or
	# its queued nodes added within the budget.
	if not _poll_worker(focus):
		_add_nodes(t0)
	var t2 := Time.get_ticks_usec()
	stream_usec.append(t2 - t0)
	busy_usec.append(t2 - t0 if _worked else 0)
	if log and t2 - t0 > BUDGET_USEC:
		print("stream: frame %d took %.2f ms (the tests %.2f, loading and adding %.2f)" % [frame, (t2 - t0) / 1000.0,
				(t1 - t0) / 1000.0, (t2 - t1) / 1000.0])


## Loads and adds every sector the view needs now (blocking): before a screenshot.
func finish_view(focus: Vector3, cam: Camera3D) -> void:
	_view_planes = cam.get_frustum()
	for key in keys:
		if _state[key]["s"] != IN and (_in_reach(key, focus, LOAD_REACH) or _in_view(key, VIEW_GROW)):
			_load_now(key)


## Sectors in full detail now.
func loaded() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for key in keys:
		if _state[key]["s"] == IN:
			out.append(key)
	return out


## The streaming numbers (tools/check_streaming.gd reads them): frames, loads, unloads, the
## main thread's streaming ms a frame (max, 99th percentile over all frames and over the frames
## that streamed), the slowest frame that streamed (ms), missing frames, forced loads.
func stats() -> Dictionary:
	var busy := []
	var worst := 0
	var worst_frame := -1
	var slow := 0
	var slow_busy := 0
	for i in stream_usec.size():
		# A frame's own time is measured at the next update; the first WARM_UP frames (the first
		# sight of every shader) are left out of the frame times.
		var ft := frame_usec[i + 1] if i + 1 < frame_usec.size() and i >= WARM_UP else 0
		if ft > 33333:
			slow += 1
		if i < busy_usec.size() and busy_usec[i] > 0:
			busy.append(busy_usec[i])
			if ft > 33333:
				slow_busy += 1
			if ft > worst:
				worst = ft
				worst_frame = i + 1
	busy.sort()
	var all := Array(stream_usec)
	all.sort()
	var over_budget := 0
	for us in stream_usec:
		if us > BUDGET_USEC:
			over_budget += 1
	# The frames over 33 ms past the warm-up: frame, its ms, the streaming ms in it (0: none).
	var slow_list := []
	for i in range(WARM_UP, frame_usec.size() - 1):
		if frame_usec[i + 1] > 33333 and slow_list.size() < 60:
			slow_list.append([i + 1, snappedf(frame_usec[i + 1] / 1000.0, 0.1),
					snappedf(busy_usec[i] / 1000.0, 0.01) if i < busy_usec.size() else 0.0])
	var per_sector := Array(sector_ms)
	per_sector.sort()
	var kinds := {}
	for k: String in _kinds:
		var v: Array = _kinds[k]
		kinds[k] = {"n": v[0], "total_ms": snappedf(v[1] / 1000.0, 0.01), "max_ms": snappedf(v[2] / 1000.0, 0.01)}
	return {"frames": frame, "loads": loads, "unloads": unloads,
			"max_ms": all[-1] / 1000.0 if not all.is_empty() else 0.0,
			"p99_ms": all[mini(all.size() - 1, int(all.size() * 0.99))] / 1000.0 if not all.is_empty() else 0.0,
			"busy_frames": busy.size(),
			"busy_p99_ms": busy[mini(busy.size() - 1, int(busy.size() * 0.99))] / 1000.0 if not busy.is_empty() else 0.0,
			"slowest_busy_frame_ms": worst / 1000.0, "slowest_busy_frame": worst_frame,
			"frames_over_33ms": slow, "frames_over_33ms_streaming": slow_busy,
			"missing_frames": missing_frames, "forced": forced,
			"frames_over_budget": over_budget, "slow_frames": slow_list,
			"sector_ms": {"n": per_sector.size(),
				"median": per_sector[per_sector.size() / 2] if not per_sector.is_empty() else 0.0,
				"p99": per_sector[mini(per_sector.size() - 1, int(per_sector.size() * 0.99))] if not per_sector.is_empty() else 0.0,
				"max": per_sector[-1] if not per_sector.is_empty() else 0.0},
			"kinds": kinds}


## The streaming numbers for a log line.
func summary() -> String:
	var st := stats()
	return "%d frames, %d loads, %d unloads, streaming %.2f ms max, %.2f ms p99 over all frames, %.2f ms p99 over the %d frames that streamed, slowest frame that streamed %.1f ms (frame %d), %d frames over 33 ms (%d of them streaming), %d frames missing a needed sector, %d forced loads" % [
			st["frames"], st["loads"], st["unloads"], st["max_ms"], st["p99_ms"], st["busy_p99_ms"], st["busy_frames"],
			st["slowest_busy_frame_ms"], st["slowest_busy_frame"], st["frames_over_33ms"], st["frames_over_33ms_streaming"],
			st["missing_frames"], st["forced"]]


# --- loading -----------------------------------------------------------------------------

## The worker: hands its finished sector to the adding queue, then starts on the wanted sector
## nearest the focus.
func _poll_worker(focus: Vector3) -> bool:
	var handed := false
	if _thread != null:
		if _thread.is_alive():
			return false
		_thread.wait_to_finish()
		_thread = null
		var root := _task_root
		_task_root = null
		if log:
			_log_task()
		if _state[_task_key]["s"] == LOADING and root != null:
			_start_adding(_task_key, root)
			handed = true
		elif root != null:
			root.free()
	# The next load starts once every sector handed over is in (the loader's uploads and the main
	# thread's adds don't then compete for the renderer).
	for key in keys:
		if _state[key]["s"] == ADDING:
			return handed
	var best := Vector2i.ZERO
	var best_d := INF
	for key in keys:
		if _state[key]["s"] == WANTED:
			var d := (Vector2(key) + Vector2(0.5, 0.5)).distance_squared_to(Vector2(focus.x, focus.z) / SECTOR)
			if d < best_d:
				best_d = d
				best = key
	if best_d < INF:
		_state[best]["s"] = LOADING
		_task_key = best
		_task_ticks.clear()
		_task_ticks.append(Time.get_ticks_usec())
		_task_phases.clear()
		if log and not RenderingServer.frame_post_draw.is_connected(_on_post_draw):
			RenderingServer.frame_pre_draw.connect(_on_pre_draw)
			RenderingServer.frame_post_draw.connect(_on_post_draw)
			get_tree().physics_frame.connect(_on_physics_frame)
			get_tree().process_frame.connect(_on_process_frame)
		_thread = Thread.new()
		_thread.start(_make.bind(best), Thread.PRIORITY_LOW)
	return handed


## On the worker (or the main thread when it can't wait): one sector's root, not in the tree.
func _make(key: Vector2i) -> void:
	_task_t[0] = Time.get_ticks_usec()
	if prebuilt:
		var scene := ResourceLoader.load(_scene_path(key), "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
		_task_t[1] = Time.get_ticks_usec()
		_task_root = scene.instantiate() as Node3D if scene != null else null
		_task_t[2] = Time.get_ticks_usec()
	else:
		_task_root = map.build_sector(key, false, false)


## --stream-log: the worker's load and instantiate times, and the slowest frame (update to update)
## while it ran: what part of the worker's run it overlapped.
func _log_task() -> void:
	var t := _task_ticks
	t.append(Time.get_ticks_usec())
	var worst := 0
	var at := 0
	for i in range(1, t.size()):
		if t[i] - t[i - 1] > worst:
			worst = t[i] - t[i - 1]
			at = i
	var part := "-"
	if at > 0:
		var a := t[at - 1]
		var b := t[at]
		part = "instantiate" if b > _task_t[1] and a < _task_t[2] else ("load" if b > _task_t[0] and a < _task_t[1] else "after")
		if part == "instantiate" and a < _task_t[1]:
			part = "load end + instantiate"
	# The slow interval's phases: the rest of the process after the streamer, the draw, from the draw
	# to the next physics frame (frame pacing, events), physics, the process up to the streamer.
	var split := "-"
	if at > 0 and at - 1 < _task_phases.size():
		var ph := _task_phases[at - 1]
		if ph[0] > 0 and ph[1] > 0 and ph[3] > 0:
			var phys := ph[2] if ph[2] > 0 else ph[3]
			split = "process after %.1f, draw %.1f, to physics %.1f, physics %.1f, process before %.1f" % [
					(ph[0] - t[at - 1]) / 1000.0, (ph[1] - ph[0]) / 1000.0, (phys - ph[1]) / 1000.0,
					(ph[3] - phys) / 1000.0, (t[at] - ph[3]) / 1000.0]
	print("stream: frame %d worker %s: load %.1f ms, instantiate %.1f ms, %d frames; slowest frame %.1f ms (overlapping the %s; %s)" % [
			frame, MapBuilder.sector_name(_task_key), (_task_t[1] - _task_t[0]) / 1000.0, (_task_t[2] - _task_t[1]) / 1000.0,
			t.size() - 1, worst / 1000.0, part, split])


func _on_pre_draw() -> void:
	_stamps[0] = Time.get_ticks_usec()


func _on_post_draw() -> void:
	_stamps[1] = Time.get_ticks_usec()


func _on_physics_frame() -> void:
	if _stamps[2] == 0 and _stamps[1] > 0:
		_stamps[2] = Time.get_ticks_usec()


func _on_process_frame() -> void:
	_stamps[3] = Time.get_ticks_usec()


## Waits for the worker and keeps what it made when it is still wanted.
func _drop_task() -> void:
	if _thread == null:
		return
	_thread.wait_to_finish()
	_thread = null
	if _task_root != null:
		if _state.has(_task_key) and _state[_task_key]["s"] == LOADING:
			_start_adding(_task_key, _task_root)
		else:
			_task_root.free()
	_task_root = null


## main.gd's state goes onto the new nodes, then they wait in a queue, the root (hidden) in the
## tree.
func _start_adding(key: Vector2i, root: Node3D) -> void:
	var t := Time.get_ticks_usec()
	_worked = true
	root.visible = false
	sector_ready.emit(root)
	var queue: Array[Node] = []
	for c in root.get_children():
		root.remove_child(c)
		_drop_owner(c)
		queue.append(c)
	# Colliders first: the car may be about to need them.
	queue.sort_custom(func(a: Node, b: Node) -> bool: return a is StaticBody3D and not b is StaticBody3D)
	_sectors.add_child(root)
	var st: Dictionary = _state[key]
	st["s"] = ADDING
	st["root"] = root
	st["queue"] = queue
	st["ms"] = float(st.get("ms", 0.0)) + (Time.get_ticks_usec() - t) / 1000.0
	_count_kind("(hand-over)", Time.get_ticks_usec() - t)


func _count_kind(kind: String, us: int) -> void:
	var k: Array = _kinds.get(kind, [0, 0, 0])
	k[0] += 1
	k[1] += us
	k[2] = maxi(k[2], us)
	_kinds[kind] = k


## A scene's nodes leave their owner (its root) before going back in one by one.
static func _drop_owner(node: Node) -> void:
	node.owner = null
	for c in node.get_children():
		_drop_owner(c)


## Adds queued nodes until the frame's budget is spent; a finished sector shows.
func _add_nodes(t0: int) -> void:
	for key in keys:
		var st: Dictionary = _state[key]
		if st["s"] != ADDING:
			continue
		var queue: Array = st["queue"]
		var root: Node3D = st["root"]
		var added := 0
		while not queue.is_empty():
			var node: Node = queue.front()
			# The next node goes in only if what that kind cost lately still fits the budget
			# (a MultiMesh costs far more than a mesh); one always goes in, so nothing waits forever.
			var expect: int = _add_cost.get(node.get_class(), 200)
			if added > 0 and Time.get_ticks_usec() - t0 + expect > BUDGET_USEC:
				return
			var t := Time.get_ticks_usec()
			queue.pop_front()
			_worked = true
			root.add_child(node)
			added += 1
			var us := Time.get_ticks_usec() - t
			_add_cost[node.get_class()] = maxi(us, int(_add_cost.get(node.get_class(), 0) * 0.9))
			_count_kind(node.get_class(), us)
			var ms := us / 1000.0
			if log and ms > 1.0:
				print("stream: frame %d adding %s's %s %s took %.2f ms" % [frame, root.name, node.get_class(), node.name, ms])
			st["ms"] = float(st["ms"]) + ms
			if ms > float(st.get("worst", 0.0)):
				st["worst"] = ms
				st["worst_node"] = node.get_class()
		var t1 := Time.get_ticks_usec()
		_finish(key)
		var fin := Time.get_ticks_usec() - t1
		_count_kind("(finish)", fin)
		st["ms"] = float(st["ms"]) + fin / 1000.0
		sector_ms.append(float(st["ms"]))


func _finish(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	var root: Node3D = st["root"]
	root.visible = true
	if _proxy.has(key):
		(_proxy[key] as MeshInstance3D).visible = false
	st["s"] = IN
	loads += 1
	sector_ready.emit(root)
	if log:
		print("stream: frame %d in %s, %.2f ms on the main thread (slowest node %.2f: %s), %.0f ms after it was wanted" % [
				frame, root.name, float(st["ms"]), float(st.get("worst", 0.0)), st.get("worst_node", "-"),
				(Time.get_ticks_usec() - int(st.get("t0", Time.get_ticks_usec()))) / 1000.0])


## Loads (or builds) and adds a sector at once (the start, a jump, a screenshot).
func _load_now(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	if st["s"] == IN:
		return
	var t := Time.get_ticks_usec()
	_worked = true
	if st["s"] != ADDING:
		_drop_task()  # the worker's sector (this one or another) goes into its queue
		if _state[key]["s"] != ADDING:
			_state[key] = {"s": LOADING, "t0": int(st.get("t0", t)), "ms": 0.0}
			_make(key)
			var root := _task_root
			_task_root = null
			if root == null:
				push_error("sectors: can't load %s" % MapBuilder.sector_name(key))
				_state[key] = {"s": QUEUED}
				return
			_start_adding(key, root)
	var queue: Array = _state[key]["queue"]
	var parent: Node3D = _state[key]["root"]
	while not queue.is_empty():
		parent.add_child(queue.pop_front())
	_state[key]["ms"] = (Time.get_ticks_usec() - t) / 1000.0
	_finish(key)


func _unload(key: Vector2i) -> void:
	var st: Dictionary = _state[key]
	if st["s"] == LOADING:
		return  # the worker finishes it; it goes in, then out
	if st["s"] == WANTED:
		_state[key] = {"s": QUEUED}
		return
	var root: Node3D = st.get("root")
	if root != null:
		_worked = true
		var t := Time.get_ticks_usec()
		for c: Node in st.get("queue", []):
			c.free()
		root.queue_free()
		_count_kind("(unload)", Time.get_ticks_usec() - t)
	_state[key] = {"s": QUEUED}
	if _proxy.has(key):
		(_proxy[key] as MeshInstance3D).visible = true
	unloads += 1
	if log:
		print("stream: frame %d out %s" % [frame, MapBuilder.sector_name(key)])


# --- which sectors ------------------------------------------------------------------------

## Whether the sector's square meets the square of half-size `reach` round `p`.
func _in_reach(key: Vector2i, p: Vector3, reach: float) -> bool:
	var x0 := key.x * SECTOR
	var z0 := key.y * SECTOR
	return p.x + reach > x0 and p.x - reach < x0 + SECTOR and p.z + reach > z0 and p.z - reach < z0 + SECTOR


## Whether the sector's box (its ground to its tallest roof, grown by `grow` metres round)
## meets the camera's frustum.
func _in_view(key: Vector2i, grow: float) -> bool:
	if _view_planes.is_empty():
		return false
	var h: Vector2 = map.sector_heights.get(key, Vector2(-30.0, 120.0))
	var lo := Vector3(key.x * SECTOR - grow, h.x, key.y * SECTOR - grow)
	var hi := Vector3((key.x + 1) * SECTOR + grow, h.y, (key.y + 1) * SECTOR + grow)
	for plane in _view_planes:
		var out := true
		for c in 8:
			var p := Vector3(hi.x if c & 1 else lo.x, hi.y if c & 2 else lo.y, hi.z if c & 4 else lo.z)
			if not plane.is_point_over(p):
				out = false
				break
		if out:
			return false
	return true


func _scene_path(key: Vector2i) -> String:
	return "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)


static func _key_of(node_name: String) -> Vector2i:
	var parts := node_name.trim_prefix("p_").split("_")
	return Vector2i(int(parts[0]), int(parts[1]))
