extends Node3D
## Pedestrians: tiny people walking the footways near the camera, one MultiMesh
## (shirt and trousers colours per person, legs swing in actor.gdshader). They
## appear and vanish out of view like the traffic, walk along a footway, carry on
## into a footway that joins it, or turn back at a dead end.

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const MAX := 60
## Loop 3g-1: people who stand still at a spot (the speed traps' officers), in the same MultiMesh
## after the walkers (police.md section 12: +0 draw calls). Loop 3g-2: slots 0-2 the day's trap
## officers, 3 the first contact's officer, 4-11 the city guards (police/guards.gd).
const FIXED := 12
## Loop MW-4: guests (city_life.gd: the dog walkers, runners, Kolka, the Hyrax loop, the dog's
## photographers) after the fixed people, written by their owner (`set_guest`): +0 draw calls.
const GUESTS := 48
## The night-buses loop: people waiting at the bus stops (buses.gd `set_stop`), after the guests:
## +0 draw calls.
const STOPS := 8
## The crash scenes (crash_scenes.gd `set_scene`): the people at a crash, after the stop figures:
## the two drivers, the officer, the paramedic and the onlookers filming. +0 draw calls.
const SCENE := 7
const CELL := 48.0
const MARGIN := 20.0
const SHIRTS := ["#d8432f", "#2f6fb5", "#e0b23a", "#3b8f5a", "#f2efe8", "#7a4fa8", "#e57aa0", "#2b2c2f", "#c96b2c", "#5aa9c9", "#9c2f3a", "#e8e4d8"]

var map: Node3D
var cam: Camera3D
var traffic: Node3D
## Quality (v0.9): at most this many people (High: MAX).
var limit := MAX
## How long the last update took, for --bench.
var last_usec := 0

var _pts := PackedVector2Array()
var _cum := PackedFloat32Array()
var _first := PackedInt32Array()
var _count := PackedInt32Array()
var _len := PackedFloat32Array()
var _width := PackedFloat32Array()
## The bridge deck a footway is on (-1: the ground).
var _deck := PackedInt32Array()
## Loop 2b: a deck footway's height every DECK_STEP metres along it (filled on first use):
## asking the deck solver per walker per frame cost ~1 ms on a bridge.
var _deck_h: Array[PackedFloat32Array] = []
const DECK_STEP := 4.0
## Footways meeting each end: per path, [paths joining the start], [paths joining the end].
var _joins_start: Array[PackedInt32Array] = []
var _joins_end: Array[PackedInt32Array] = []
var _grid := {}
## Loop 10a: the stretch of each footway people walk, `_lo` to `_hi` metres along it: a
## footway that runs into the water at an end (a beach path down to the river) stops a metre
## short of it and people turn back there; one that crosses water in between (a pond, a
## fountain) nobody walks (`_hi` < 0). Worked out the first time someone could walk it
## (`_looked`; every half metre along it: too slow for all 5,000 at the start).
var _lo := PackedFloat32Array()
var _hi := PackedFloat32Array()
var _looked := PackedByteArray()

## Walkers, struct of arrays.
var _path := PackedInt32Array()
var _s := PackedFloat32Array()
var _dir := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _off := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _alive := PackedByteArray()
var _pos := PackedVector3Array()
var _alive_count := 0
var _filled := false
var _mm: MultiMesh
var _buf := PackedFloat32Array()
## Loop MW-4: the guests handed over by take_guests, merged into _buf before the next send.
var _guest_buf := PackedFloat32Array()
var _guests_new := false
## The night-buses loop: the stop figures' instances (STOPS × 16), the buffer's tail.
var _stop_buf := PackedFloat32Array()
var _stops_new := false
## The crash scenes: the scene's people (SCENE × 16), after the stop figures.
var _scene_buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func setup(map_node: Node3D, camera: Camera3D, traffic_node: Node3D, data: Dictionary) -> void:
	map = map_node
	cam = camera
	traffic = traffic_node
	_rng.seed = 1611
	var water: Array[PackedVector2Array] = []
	for a in data.get("areas", []):
		if a["k"] == "water":
			water.append(_poly(a["p"]))
	var ends := {}
	for p in data.get("paths", []):
		if p["k"] != "foot":
			continue
		var line := _poly(p["p"])
		if line.size() < 2:
			continue
		# Footways in the river (mapped across it, not on a bridge deck): nobody walks there.
		var dk := int(p.get("dk", -1))
		var mid := line[line.size() / 2]
		var wet := false
		for w in water:
			if dk < 0 and Geometry2D.is_point_in_polygon(mid, w):
				wet = true
				break
		if wet:
			continue
		var i := _first.size()
		_first.append(_pts.size())
		_count.append(line.size())
		var run := 0.0
		for k in line.size():
			if k > 0:
				run += line[k].distance_to(line[k - 1])
			_pts.append(line[k])
			_cum.append(run)
		_len.append(run)
		_width.append(float(p["w"]))
		_deck.append(dk)
		_deck_h.append(PackedFloat32Array())
		_joins_start.append(PackedInt32Array())
		_joins_end.append(PackedInt32Array())
		for k in [0, line.size() - 1]:
			var key := Vector2i(roundi(line[k].x), roundi(line[k].y))
			if not ends.has(key):
				ends[key] = []
			ends[key].append(i * 2 + (0 if k == 0 else 1))
		var s := 0.0
		while s <= run:
			var key := _cell(_at(i, s))
			if not _grid.has(key):
				_grid[key] = PackedInt32Array()
			if _grid[key].is_empty() or _grid[key][_grid[key].size() - 1] != i:
				_grid[key].append(i)
			s += CELL * 0.5
	for key in ends:
		var list: Array = ends[key]
		for a in list:
			for b in list:
				if a / 2 != b / 2:
					(_joins_start if a % 2 == 0 else _joins_end)[a / 2].append(b)
	_lo.resize(_first.size())
	_hi.resize(_first.size())
	_looked.resize(_first.size())
	_looked.fill(0)
	_path.resize(MAX)
	_s.resize(MAX)
	_dir.resize(MAX)
	_speed.resize(MAX)
	_off.resize(MAX)
	_phase.resize(MAX)
	_alive.resize(MAX)
	_alive.fill(0)
	_pos.resize(MAX)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	InstanceBuffers.prepare(_mm)
	_mm.mesh = Models.person_mesh()
	_mm.instance_count = MAX + FIXED + GUESTS + STOPS + SCENE
	# Loop MW-4: the whole demo map (the guests stand at Plac Zbawiciela, z 1600, and beyond).
	_mm.custom_aabb = AABB(Vector3(-6000, -300, -6000), Vector3(12000, 900, 12000))
	_buf.resize((MAX + FIXED + GUESTS + STOPS + SCENE) * 16)
	_buf.fill(0.0)
	_stop_buf.resize(STOPS * 16)
	_stop_buf.fill(0.0)
	_scene_buf.resize(SCENE * 16)
	_scene_buf.fill(0.0)
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.16)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mmi)


## Loop 10a: nobody walks footway i: it crosses the water at ground level between its ends,
## or what is left of it out of the water is under 4 m (a point a metre or more past the
## water's edge counts as water: map_builder.shore_distance).
func is_wet(i: int) -> bool:
	_look(i)
	return _hi[i] < 0.0


## Loop 10a: works out footway i's walkable stretch [_lo, _hi] (see `_lo`).
func _look(i: int) -> void:
	if _looked[i] == 1:
		return
	_looked[i] = 1
	_lo[i] = 0.0
	_hi[i] = _len[i]
	if _deck[i] >= 0:
		return
	var first := -1.0
	var last := -1.0
	var dry_between := false
	var s := 0.0
	while s <= _len[i] + 0.25:
		var q := _at(i, minf(s, _len[i]))
		if map.shore_distance(q.x, q.y) >= 1.0:
			if first < 0.0:
				first = s
			elif s - last > 0.75:
				dry_between = true
			last = s
		s += 0.5
	if first < 0.0:
		return
	var head := first <= 0.25
	var tail := last >= _len[i] - 0.25
	if dry_between or (head and tail) or (not head and not tail):
		_hi[i] = -1.0  # through the water, or in it at both ends
		return
	if head:
		_lo[i] = last + 1.0
	else:
		_hi[i] = first - 1.0
	if _hi[i] - _lo[i] < 4.0:
		_hi[i] = -1.0


## Loop 10a: someone can step onto footway i at its start (or end): that end is walkable.
func _enterable(i: int, at_start: bool) -> bool:
	_look(i)
	return _hi[i] >= 0.0 and (_lo[i] <= 0.0 if at_start else _hi[i] >= _len[i])


func _poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[k], flat[k + 1]))
	return out


func _cell(p: Vector2) -> int:
	return (floori(p.x / CELL) + 512) * 1024 + floori(p.y / CELL) + 512


func _at(i: int, s: float, off := 0.0) -> Vector2:
	var k := _first[i]
	var last := k + _count[i] - 2
	while k < last and _cum[k + 1] < s:
		k += 1
	var a := _pts[k]
	var b := _pts[k + 1]
	var seg := _cum[k + 1] - _cum[k]
	var dir := (b - a).normalized()
	return a.lerp(b, clampf((s - _cum[k]) / seg, 0.0, 1.0) if seg > 0.0001 else 0.0) + Vector2(-dir.y, dir.x) * off


## Loop 2b: how many people walk now (the bench).
func alive_count() -> int:
	return _alive_count


## Loop 3g-1: puts fixed person `i` (0..FIXED-1) at `at` facing `yaw` (radians, like a car's),
## in a `shirt` and trousers from the palette (`trousers` 0..1: actor.gdshader TROUSERS).
func set_fixed(i: int, at: Vector3, yaw: float, shirt: Color, trousers: float) -> void:
	var b := (MAX + i) * 16
	var c := cos(yaw)
	var s := sin(yaw)
	_buf[b] = c
	_buf[b + 1] = 0.0
	_buf[b + 2] = s
	_buf[b + 3] = at.x
	_buf[b + 4] = 0.0
	_buf[b + 5] = 1.0
	_buf[b + 6] = 0.0
	_buf[b + 7] = at.y
	_buf[b + 8] = -s
	_buf[b + 9] = 0.0
	_buf[b + 10] = c
	_buf[b + 11] = at.z
	_buf[b + 12] = shirt.r
	_buf[b + 13] = shirt.g
	_buf[b + 14] = shirt.b
	_buf[b + 15] = trousers


## Loop 3g-2 (the clamp, police.md 5.6): a footway runs under `p` (within its half width + 1 m).
func on_footway(p: Vector2) -> bool:
	for dx in [-1, 0, 1]:
		for dz in [-1, 0, 1]:
			var list = _grid.get(_cell(p + Vector2(dx, dz) * CELL * 0.5))
			if list == null:
				continue
			for i: int in list:
				var k := _first[i]
				for j in _count[i] - 1:
					var a := _pts[k + j]
					var b := _pts[k + j + 1]
					var q := Geometry2D.get_closest_point_to_segment(p, a, b)
					if q.distance_to(p) < _width[i] * 0.5 + 1.0:
						return true
	return false


func clear_fixed(i: int) -> void:
	for k in 12:
		_buf[(MAX + i) * 16 + k] = 0.0


## Loop MW-4: guest `i` (0..GUESTS-1) at `at` facing `yaw` (as set_fixed); it walks as the rest
## do (the legs swing).
func set_guest(i: int, at: Vector3, yaw: float, shirt: Color, trousers: float) -> void:
	set_fixed(FIXED + i, at, yaw, shirt, trousers)


func clear_guest(i: int) -> void:
	clear_fixed(FIXED + i)


## Loop MW-4 (the cost cut): all the guests at once, `buf` in this buffer's layout (GUESTS × 16
## floats, as set_fixed writes them), put in before the next send; city_life.gd's writes.
func take_guests(buf: PackedFloat32Array) -> void:
	_guest_buf = buf
	_guests_new = true


## The night-buses loop: stop figure `i` (0..STOPS-1) at `at` facing `yaw` (as set_fixed).
func set_stop(i: int, at: Vector3, yaw: float, shirt: Color, trousers: float) -> void:
	var b := i * 16
	var c := cos(yaw)
	var s := sin(yaw)
	var row := PackedFloat32Array([c, 0.0, s, at.x, 0.0, 1.0, 0.0, at.y, -s, 0.0, c, at.z, shirt.r, shirt.g, shirt.b, trousers])
	for k in 16:
		_stop_buf[b + k] = row[k]
	_stops_new = true


func clear_stop(i: int) -> void:
	for k in 12:
		_stop_buf[i * 16 + k] = 0.0
	_stops_new = true


## The crash scenes: scene person `i` (0..SCENE-1) at `at` facing `yaw` (as set_fixed).
func set_scene(i: int, at: Vector3, yaw: float, shirt: Color, trousers: float) -> void:
	var c := cos(yaw)
	var s := sin(yaw)
	var row := PackedFloat32Array([c, 0.0, s, at.x, 0.0, 1.0, 0.0, at.y, -s, 0.0, c, at.z, shirt.r, shirt.g, shirt.b, trousers])
	for k in 16:
		_scene_buf[i * 16 + k] = row[k]
	_stops_new = true


func clear_scene(i: int) -> void:
	for k in 12:
		_scene_buf[i * 16 + k] = 0.0
	_stops_new = true


## The night-buses loop (the player's horn): walkers within `r` m of `at` walking towards it turn
## round. Returns how many did.
func startle(at: Vector2, r: float) -> int:
	var n := 0
	for k in MAX:
		if _alive[k] == 0:
			continue
		var q := Vector2(_pos[k].x, _pos[k].z)
		if q.distance_squared_to(at) > r * r:
			continue
		var i := _path[k]
		var ahead := _at(i, clampf(_s[k] + _dir[k], _lo[i], _hi[i]))
		if ahead.distance_squared_to(at) < q.distance_squared_to(at):
			_dir[k] = -_dir[k]
			n += 1
	return n


func _process(dt: float) -> void:
	if dt <= 0.0 or _first.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	# Use the traffic's view of the ground (centre, axes, half size).
	var centre: Vector2 = traffic.view_centre
	var right: Vector2 = traffic.view_right
	var ahead: Vector2 = traffic.view_ahead
	var half: Vector2 = traffic.view_half + Vector2.ONE * MARGIN
	# Tiny people mean nothing in a wide view; fewer of them there.
	var target := limit if cam.size < 160.0 else int(limit * 0.5)
	for n in MAX:
		if _alive[n] == 0:
			continue
		var q := Vector2(_pos[n].x, _pos[n].z) - centre
		var far := absf(q.dot(right)) > half.x + 25.0 or absf(q.dot(ahead)) > half.y + 25.0
		if (far or _alive_count > target) and not traffic.on_screen(_pos[n], 1.8):
			_kill(n)
	var tries := 300 if not _filled else 6
	for k in tries:
		if _alive_count >= target:
			break
		_try_spawn(centre, right, ahead, half, not _filled)
	_filled = true
	for n in MAX:
		if _alive[n] == 1:
			_walk(n, dt)
	if _guests_new or _stops_new:
		# The guests are the buffer's tail, then the stop figures: cut them off, append theirs
		# (native copies).
		if _guest_buf.size() != GUESTS * 16:
			_guest_buf.resize(GUESTS * 16)
		_guests_new = false
		_stops_new = false
		_buf.resize((MAX + FIXED) * 16)
		_buf.append_array(_guest_buf)
		_buf.append_array(_stop_buf)
		_buf.append_array(_scene_buf)
	InstanceBuffers.send(_mm.get_rid(), _buf)
	last_usec = Time.get_ticks_usec() - t0


## The ground under a walker at `s` along footway `i` (at `q`): the terrain, or the deck's
## height from samples along the footway (bridge decks rise and fall slowly).
func _height(i: int, s: float, q: Vector2) -> float:
	if _deck[i] < 0:
		return map.deck_height(-1, q.x, q.y)
	var h := _deck_h[i]
	if h.is_empty():
		var n := maxi(2, ceili(_len[i] / DECK_STEP) + 1)
		h.resize(n)
		for k in n:
			var at := _at(i, _len[i] * k / (n - 1))
			h[k] = map.deck_height(_deck[i], at.x, at.y)
		_deck_h[i] = h
	var f := clampf(s / maxf(_len[i], 0.001), 0.0, 1.0) * (h.size() - 1)
	var k0 := mini(floori(f), h.size() - 2)
	return lerpf(h[k0], h[k0 + 1], f - k0)


func _try_spawn(centre: Vector2, right: Vector2, ahead: Vector2, half: Vector2, anywhere: bool) -> void:
	var l := Vector2(_rng.randf_range(-half.x, half.x), _rng.randf_range(-half.y, half.y))
	var p := centre + right * l.x + ahead * l.y
	var list = _grid.get(_cell(p))
	if list == null:
		return
	var i: int = list[_rng.randi() % list.size()]
	if is_wet(i):
		return
	var s := _rng.randf_range(_lo[i], _hi[i])
	var off := _rng.randf_range(-0.3, 0.3) * _width[i]
	var q := _at(i, s, off)
	var y := _height(i, s, q)
	if not anywhere and traffic.on_screen(Vector3(q.x, y, q.y), 1.8):
		return
	var lq := q - centre
	if absf(lq.dot(right)) > half.x or absf(lq.dot(ahead)) > half.y:
		return
	var n := _alive.find(0)
	if n < 0:
		return
	_alive[n] = 1
	_alive_count += 1
	_path[n] = i
	_s[n] = s
	_dir[n] = 1.0 if _rng.randf() < 0.5 else -1.0
	_speed[n] = _rng.randf_range(1.0, 1.6)
	_off[n] = off
	_phase[n] = _rng.randf() * TAU
	_pos[n] = Vector3(q.x, y, q.y)
	var shirt := Color(SHIRTS[_rng.randi() % SHIRTS.size()])
	var b := n * 16
	_buf[b + 12] = shirt.r
	_buf[b + 13] = shirt.g
	_buf[b + 14] = shirt.b
	_buf[b + 15] = _rng.randf() * 0.99


func _kill(n: int) -> void:
	_alive[n] = 0
	_alive_count -= 1
	for k in 12:
		_buf[n * 16 + k] = 0.0


func _walk(n: int, dt: float) -> void:
	var i := _path[n]
	var s := _s[n] + _dir[n] * _speed[n] * dt
	if s < _lo[i] or s > _hi[i]:
		# Carry on into a footway that joins here, else turn back (loop 10a: also a metre
		# short of the water).
		var end := (s < _lo[i] and _lo[i] <= 0.0) or (s > _hi[i] and _hi[i] >= _len[i])
		var joins := (_joins_start[i] if s < _lo[i] else _joins_end[i]) if end else PackedInt32Array()
		var j := joins[_rng.randi() % joins.size()] if not joins.is_empty() else -1
		if j >= 0 and _enterable(j / 2, j % 2 == 0):
			i = j / 2
			_path[n] = i
			_dir[n] = 1.0 if j % 2 == 0 else -1.0
			s = 0.0 if j % 2 == 0 else _len[i]
		else:
			_dir[n] = -_dir[n]
			s = clampf(s, _lo[i], _hi[i])
	_s[n] = s
	var q := _at(i, s, _off[n])
	_phase[n] += dt * 9.0
	var y := _height(i, s, q) + absf(sin(_phase[n])) * 0.05
	var step := Vector2(q.x - _pos[n].x, q.y - _pos[n].z)
	var yaw := atan2(-step.x, -step.y) if step.length_squared() > 0.000001 else 0.0
	_pos[n] = Vector3(q.x, y, q.y)
	var c := cos(yaw)
	var sn := sin(yaw)
	var b := n * 16
	_buf[b] = c
	_buf[b + 1] = 0.0
	_buf[b + 2] = sn
	_buf[b + 3] = q.x
	_buf[b + 4] = 0.0
	_buf[b + 5] = 1.0
	_buf[b + 6] = 0.0
	_buf[b + 7] = y
	_buf[b + 8] = -sn
	_buf[b + 9] = 0.0
	_buf[b + 10] = c
	_buf[b + 11] = q.y
