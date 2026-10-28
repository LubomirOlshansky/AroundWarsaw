extends Node3D
## Pedestrians: tiny people walking the footways near the camera, one MultiMesh
## (shirt and trousers colours per person, legs swing in actor.gdshader). They
## appear and vanish out of view like the traffic, walk along a footway, carry on
## into a footway that joins it, or turn back at a dead end.

const Models := preload("res://scripts/models.gd")

const MAX := 60
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
	_mm.mesh = Models.person_mesh()
	_mm.instance_count = MAX
	_mm.custom_aabb = AABB(Vector3(-2500, -200, -1500), Vector3(5000, 600, 3000))
	_buf.resize(MAX * 16)
	_buf.fill(0.0)
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.16)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mmi)


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
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buf)
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
	var s := _rng.randf_range(0.0, _len[i])
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
	if s < 0.0 or s > _len[i]:
		# Carry on into a footway that joins here, else turn back.
		var joins := _joins_start[i] if s < 0.0 else _joins_end[i]
		if not joins.is_empty():
			var j := joins[_rng.randi() % joins.size()]
			i = j / 2
			_path[n] = i
			_dir[n] = 1.0 if j % 2 == 0 else -1.0
			s = 0.0 if j % 2 == 0 else _len[i]
		else:
			_dir[n] = -_dir[n]
			s = clampf(s, 0.0, _len[i])
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
