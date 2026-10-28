extends Node3D
## AI traffic on the lane graph: cars, taxis, vans and city buses drawn with one
## MultiMesh per kind, plus the rivals' cars (their own nodes) and an invisible
## "ghost" driver the autopilot uses. Cars follow their lane at the road's speed,
## pick a random way on at junctions, keep their distance (a simple intelligent
## driver model), stop for red lights and for the player's car.
##
## Cars only exist in a band around the view: they appear and vanish where the
## camera can't see them, so the count stays near a target set by how much road
## is in view. Near the player a small pool of kinematic bodies gives the closest
## cars collision; a car the player hits stops for a moment.
##
## Loop 2c (car models): each kind's MultiMesh draws a family of shapes (models.gd TRAFFIC and
## traffic_mesh(): cars are hatches, saloons, estates and SUVs; taxis the city taxi and
## Podwózka, the app taxi; vans panel and box vans), the shape picked per car and written in
## the instance's custom alpha, with its own size and paints. Each MultiMesh draws only up to
## its highest slot in use (visible_instance_count), not its whole pool.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const LaneGraph := preload("res://scripts/lane_graph.gd")
const Models := preload("res://scripts/models.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

enum Kind { CAR, TAXI, VAN, BUS, NODE }
const POOL := [112, 16, 16, 8]
## Each kind's longest shape (m), for the headlight pools. The shapes, their sizes and paints
## are models.gd TRAFFIC (loop 2c; red stays the player's, orange the jobs': the look loop).
const LENGTH := [4.65, 4.6, 5.4, 12.0]
## Cars per lane-metre in view, by road class (main, tertiary, residential, living street).
const DENSITY := [1.0 / 20.0, 1.0 / 34.0, 1.0 / 90.0, 1.0 / 180.0]
const MAX_CARS := 140
## Spawn band beyond the view edge, in metres, and the spacing of spawn slots in it.
const MARGIN := 45.0
const SLOT := 8.0
## Intelligent driver model: comfortable acceleration and braking, time gap, standstill gap.
const ACCEL := 2.2
const DECEL := 3.5
const HEADWAY := 1.1
const MIN_GAP := 2.2
## Kinematic bodies for the cars nearest the player.
const BODIES := 12
const BODY_RANGE := 40.0
## Pole lamps: red, amber, green.
const LAMP_ON := [Color("#ff3b2f"), Color("#ffb21e"), Color("#43ff6e")]
const LAMP_OFF := Color("#2a2c2e")
## Their halos at night (linear colour, alpha = brightness).
const HALO := [Color(1.0, 0.08, 0.04, 0.9), Color(1.0, 0.45, 0.02, 0.85), Color(0.1, 1.0, 0.3, 0.8)]


class Driver:
	var active := false
	var kind := 0
	var slot := -1
	## Rivals: their own car model, never despawned.
	var node: Node3D
	var persistent := false
	## The autopilot: not drawn, not in any lane (others see the player's car
	## instead), ignores lights and crossing cars but follows the car ahead.
	var ghost := false
	var length := 4.2
	var size := Vector3(1.8, 1.5, 4.2)
	var paint := Color.WHITE
	## Loop 2c: which of its kind's shapes it is (models.gd TRAFFIC; the instance's custom alpha).
	var shape := 0
	var edge := -1
	var lane := 0
	var s := 0.0
	var seg := 0
	var off := 0.0
	var off_target := 0.0
	var next_edge := -1
	var next_lane := 0
	var next_reg := -1
	var reg := -1
	## Position in the registered lane; negative of the lane start on the way in.
	var ls := 0.0
	var in_conn := false
	var cu := 0.0
	var conn := PackedVector2Array()
	var conn_len := 1.0
	var conn_y0 := 0.0
	var conn_y1 := 0.0
	var v_turn := 10.0
	var v := 0.0
	var speed_factor := 1.0
	var accel_factor := 1.0
	var stun := 0.0
	var held := false
	var still := 0.0
	## Seconds stuck behind the player's car.
	var blocked := 0.0
	var squeeze := 0.0
	var pos := Vector3.ZERO
	var yaw := 0.0
	var clip := 1.0
	var visible := false
	## Time not yet driven (cars out of sight update every other frame).
	var pending := 0.0
	## Racing: distances to the finish for every node (empty = wander).
	var route := PackedFloat32Array()
	var finish := -1
	var arrived := false
	var run_red := false
	## Stay inside the strongly connected core (rivals), so they never leave the map.
	var core_only := false
	## A car crossing our path in a junction box: gap to it and its speed.
	var cross_gap := INF
	var cross_v := 0.0
	## Waiting on crossing cars for long (a knot of cars yielding in a ring) makes
	## a car ignore them for a moment.
	var cross_wait := 0.0
	var cross_ignore := 0.0
	## A tram is in its path (it waits; the tram doesn't wait for it).
	var sees_tram := false


signal bumped_driver(d: Driver)
## A car has been held up behind the player's stopped car for a while (it may shout).
signal blocked_by_player(d: Driver)

var graph: LaneGraph
var map: Node3D
var cam: Camera3D
## Quality (v0.9) × the Traffic setting (loop 2a): scales how many cars fill the view
## (1 = High, Busy). A change applies at once: the view's car count is worked out again.
var density := 1.0:
	set(value):
		density = value
		_target_at = Vector2.INF
## Spawning cars; rivals and the ghost drive even when this is off.
var spawning := true
## Set by the game every frame.
var player_pos := Vector3.ZERO
var player_vel := Vector3.ZERO
var player_on_road := true
## How long the last update took, for --bench.
var last_usec := 0
var visible_count := 0

var _active: Array[Driver] = []
var _free: Array[Driver] = []
var _lane_cars: Array = []
var _mm: Array[MultiMesh] = []
## Headlight pools for each kind, drawn from the same instance buffer (night only).
var _beam_mm: Array[MultiMesh] = []
var _beam_mmi: Array[MultiMeshInstance3D] = []
var _buf: Array[PackedFloat32Array] = []
var _free_slots: Array[PackedInt32Array] = []
var _counts := PackedInt32Array([0, 0, 0, 0])
## Loop 2c: instances each MultiMesh draws (its highest slot in use + 1), and this frame's.
var _drawn := PackedInt32Array([0, 0, 0, 0])
var _top := PackedInt32Array([0, 0, 0, 0])
var _bodies: Array[AnimatableBody3D] = []
var _body_driver: Array = []
var _rng := RandomNumberGenerator.new()
## Loop 2c: picks the shapes, apart from _rng so where and what kind of car spawns is as before.
var _looks := RandomNumberGenerator.new()
var _tick := 0
## Cars in or near a junction box this frame (see _junction_conflicts); the
## trams read it too.
var junction_cars: Array[Driver] = []
## The trams (trams.gd), set by the game: cars give way to them.
var trams: Node3D
var _tram_at := PackedVector2Array()
var _tram_axis := PackedVector2Array()
## Spawn slots around the view: edge, position, running total of their weight.
var _slot_e := PackedInt32Array()
var _slot_s := PackedFloat32Array()
var _slot_sum := PackedFloat32Array()
var _target := 40
var _target_at := Vector2.INF
var _target_size := 0.0
var _filled := false
var _view := Rect2()
## The ground in view, kept by _update_view(): centre, right and ahead axes, half size (m).
var view_centre := Vector2.ZERO
var view_right := Vector2.RIGHT
var view_ahead := Vector2.UP
var view_half := Vector2.ONE
var _lamps: MultiMesh
## Soft halos round the lit signal lamps (night only).
var _halos: MultiMesh
var _lamp_state := PackedInt32Array()
## Controller*2+group -> lamp instance indices (first of three per pole).
var _lamp_slots := {}


func setup(lane_graph: LaneGraph, map_node: Node3D, camera: Camera3D, data: Dictionary) -> void:
	graph = lane_graph
	map = map_node
	cam = camera
	_rng.seed = 2026
	_looks.seed = 2027
	_lane_cars.resize(graph.lane_count)
	for i in graph.lane_count:
		_lane_cars[i] = []
	for i in MAX_CARS + 8:
		_free.append(Driver.new())
	for k in 4:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = Models.traffic_mesh(k)
		mm.instance_count = POOL[k]
		mm.visible_instance_count = 0
		# Instances move all over the map; never cull the whole set.
		mm.custom_aabb = AABB(Vector3(-2500, -200, -1500), Vector3(5000, 600, 3000))
		var buf := PackedFloat32Array()
		buf.resize(POOL[k] * 16)
		buf.fill(0.0)
		mm.buffer = buf
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(mmi)
		_mm.append(mm)
		_buf.append(buf)
		var beam := MultiMesh.new()
		beam.transform_format = MultiMesh.TRANSFORM_3D
		beam.use_custom_data = true
		beam.mesh = Models.headlight_pools(LENGTH[k] * 0.5, 0.85 if k == Kind.BUS else 0.6, 15.0 if k == Kind.BUS else 13.0)
		beam.instance_count = POOL[k]
		beam.visible_instance_count = 0
		beam.custom_aabb = mm.custom_aabb
		beam.buffer = buf
		var bmi := MultiMeshInstance3D.new()
		bmi.multimesh = beam
		bmi.material_override = Models.glow_material()
		bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		bmi.visible = false
		bmi.add_to_group("night_lights")
		add_child(bmi)
		_beam_mm.append(beam)
		_beam_mmi.append(bmi)
		var slots := PackedInt32Array()
		for i in range(POOL[k] - 1, -1, -1):
			slots.append(i)
		_free_slots.append(slots)
	for i in BODIES:
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		body.collision_layer = 0
		body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		var shape := CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		body.add_child(shape)
		add_child(body)
		_bodies.append(body)
		_body_driver.append(null)
	_build_lamps(data.get("signals", []))


# --- the frame ------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or graph == null:
		return
	var t0 := Time.get_ticks_usec()
	graph.clock += dt
	_update_lamps()
	_update_view()
	if spawning:
		_manage()
	_junction_conflicts()
	var i := 0
	visible_count = 0
	_tick += 1
	while i < _active.size():
		var d := _active[i]
		d.pending += dt
		# Out of sight, half the updates are plenty (and halve the cost there).
		if not d.visible and d.node == null and not d.ghost and (i + _tick) % 2 == 0:
			i += 1
			continue
		_drive(d, d.pending)
		d.pending = 0.0
		if not d.active:
			continue  # released; the last driver took its place
		if d.visible:
			visible_count += 1
		i += 1
	_write()
	last_usec = Time.get_ticks_usec() - t0


func _physics_process(_dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_bodies_step(_dt)
	spent_usec += Time.get_ticks_usec() - t0


func _bodies_step(_dt: float) -> void:
	# The cars nearest the player get a body each, so the player's car bumps them.
	var used := 0
	var p := Vector2(player_pos.x, player_pos.z)
	if player_on_road:
		for d in _active:
			if used >= BODIES:
				break
			if d.ghost or Vector2(d.pos.x, d.pos.z).distance_squared_to(p) > BODY_RANGE * BODY_RANGE:
				continue
			var body := _bodies[used]
			var box: BoxShape3D = (body.get_child(0) as CollisionShape3D).shape
			if box.size != d.size:
				box.size = d.size
			body.collision_layer = 1
			body.global_transform = Transform3D(Basis(Vector3.UP, d.yaw), d.pos + Vector3(0, d.size.y * 0.5 + 0.1, 0))
			_body_driver[used] = d
			used += 1
	for k in range(used, BODIES):
		if _body_driver[k] != null:
			_bodies[k].collision_layer = 0
			_bodies[k].global_position = Vector3(0, -500 - k * 10, 0)
			_body_driver[k] = null


## The player's car hit something; if it was one of ours, that car stops a moment.
func on_player_bump(collider: Object, _speed := 0.0) -> void:
	# Walls, kiosks and statues are static bodies: not one of ours (and a typed
	# array's find() refuses another type).
	if not collider is AnimatableBody3D:
		return
	var k := _bodies.find(collider)
	if k >= 0 and _body_driver[k] != null:
		var d: Driver = _body_driver[k]
		d.stun = 2.5
		bumped_driver.emit(d)


# --- spawning ---------------------------------------------------------------------

## The ground under the view: its centre, the camera's right and ahead axes on the
## ground, and half its size; the viewport rectangle for the on-screen test.
func _update_view() -> void:
	var b := cam.global_transform.basis
	var o := cam.global_position
	var f := -b.z
	var t := (player_pos.y - o.y) / minf(f.y, -0.05)
	var c := o + f * t
	view_centre = Vector2(c.x, c.z)
	view_right = Vector2(b.x.x, b.x.z).normalized()
	view_ahead = Vector2(f.x, f.z).normalized()
	var vp := cam.get_viewport().get_visible_rect().size
	view_half = Vector2(cam.size * vp.x / maxf(vp.y, 1.0) * 0.5, cam.size * 0.5 / maxf(-f.y, 0.2))
	_view = Rect2(Vector2.ZERO, vp).grow(vp.y * 0.06)


func on_screen(p: Vector3, height: float) -> bool:
	return _view.has_point(cam.unproject_position(p)) or _view.has_point(cam.unproject_position(p + Vector3(0, height, 0)))


## View coordinates of a ground point: metres right of and ahead of the view centre.
func _local(p: Vector2) -> Vector2:
	var q := p - view_centre
	return Vector2(q.dot(view_right), q.dot(view_ahead))


func _manage() -> void:
	if _target_at.distance_to(view_centre) > 16.0 or absf(_target_size - cam.size) > 4.0:
		_target_at = view_centre
		_target_size = cam.size
		_target = _count_target()
	var far := view_half + Vector2.ONE * (MARGIN + 30.0)
	var i := 0
	while i < _active.size():
		var d := _active[i]
		i += 1
		if d.persistent or d.ghost or d.visible:
			continue
		var l := _local(Vector2(d.pos.x, d.pos.z))
		var gone := absf(l.x) > far.x or absf(l.y) > far.y
		# Too many (zoomed in): thin out the cars just outside the view first.
		if not gone and _counts_total() > _target + 6:
			gone = absf(l.x) > view_half.x + 12.0 or absf(l.y) > view_half.y + 12.0
		# Stuck out of sight for a long time (a jam that will never clear).
		if gone or d.still > 45.0:
			_release(d)
			i -= 1
	var tries := 600 if not _filled else 30
	var made := 0
	for k in tries:
		if _counts_total() >= _target or made >= (200 if not _filled else 4):
			break
		if _try_spawn(not _filled):
			made += 1
	_filled = true


func _counts_total() -> int:
	return _counts[0] + _counts[1] + _counts[2] + _counts[3]


## Spawn slots every 8 m along the lanes inside the band around the view, each
## weighted by how much traffic its road should carry; their total weight is how
## many cars the view should hold.
func _count_target() -> int:
	var reach := view_half + Vector2.ONE * MARGIN
	var corner := (view_right * reach.x).abs() + (view_ahead * reach.y).abs()
	var lo := view_centre - corner
	var hi := view_centre + corner
	var cell := LaneGraph.CELL
	var seen := {}
	_slot_e.clear()
	_slot_s.clear()
	_slot_sum.clear()
	var total := 0.0
	var z := lo.y
	while z <= hi.y + cell:
		var x := lo.x
		while x <= hi.x + cell:
			for e in graph.grid.get(LaneGraph.cell_key(Vector2(x, z)), PackedInt32Array()):
				if seen.has(e):
					continue
				seen[e] = true
				var w: float = graph.e_lanes[e] * DENSITY[graph.e_class[e]] * SLOT
				var at := graph.e_s0[e] + 4.0
				while at < graph.e_s1[e] - 6.0:
					var l := _local(graph.point_at(e, at))
					if absf(l.x) <= reach.x and absf(l.y) <= reach.y:
						total += w
						_slot_e.append(e)
						_slot_s.append(at)
						_slot_sum.append(total)
					at += SLOT
			x += cell
		z += cell
	return clampi(int(total * density), 6, MAX_CARS)


func _try_spawn(anywhere: bool) -> bool:
	if _slot_e.is_empty():
		return false
	# A slot near the view, more likely the more traffic its road should carry.
	var k := mini(_slot_sum.bsearch(_rng.randf() * _slot_sum[_slot_sum.size() - 1]), _slot_e.size() - 1)
	var e := _slot_e[k]
	var cls := graph.e_class[e]
	var lane := _rng.randi() % graph.e_lanes[e]
	var s := clampf(_slot_s[k] + _rng.randf_range(-SLOT, SLOT) * 0.5, graph.e_s0[e] + 4.0, graph.e_s1[e] - 6.0)
	var q := graph.point_at(e, s, graph.lane_offset(e, lane))
	var kind := Kind.CAR
	var r := _rng.randf()
	if cls == 0 and lane == graph.e_lanes[e] - 1 and r < 0.07:
		kind = Kind.BUS
	elif r < 0.17:
		kind = Kind.VAN
	elif r < 0.27 and cls <= 1:
		kind = Kind.TAXI
	if _free_slots[kind].is_empty():
		kind = Kind.CAR
		if _free_slots[kind].is_empty():
			return false
	var y := graph.height(e, s)
	var shapes: Array = Models.TRAFFIC[kind]
	var shape := 0
	var pick := _looks.randf()
	while shape < shapes.size() - 1 and pick >= float(shapes[shape]["share"]):
		pick -= float(shapes[shape]["share"])
		shape += 1
	var look: Dictionary = shapes[shape]
	var size: Vector3 = look["size"]
	if not anywhere and on_screen(Vector3(q.x, y, q.y), size.y):
		return false
	var lane_id: int = graph.e_lane0[e] + lane
	for o in _lane_cars[lane_id]:
		if absf((o as Driver).ls - s) < size.z + 12.0:
			return false
	if Vector2(player_pos.x, player_pos.z).distance_to(q) < 14.0:
		return false
	# Lanes of different roads meet at junctions: keep clear of every car, not just this lane's.
	for o in _active:
		if Vector2(o.pos.x, o.pos.z).distance_squared_to(q) < 100.0 + o.length * o.length:
			return false
	var d: Driver = _free.pop_back()
	d.kind = kind
	d.slot = _free_slots[kind][_free_slots[kind].size() - 1]
	_free_slots[kind].resize(_free_slots[kind].size() - 1)
	_counts[kind] += 1
	d.size = size
	d.length = size.z
	d.shape = shape
	var paints: Array = look["paint"]
	d.paint = Color(paints[_rng.randi() % paints.size()])
	d.speed_factor = _rng.randf_range(0.85, 1.08) * (0.85 if kind == Kind.BUS else 1.0)
	d.accel_factor = 0.7 if kind == Kind.BUS else _rng.randf_range(0.85, 1.15)
	d.persistent = false
	d.ghost = false
	d.node = null
	d.core_only = false
	_start(d, e, lane, s)
	d.v = graph.e_speed[e] * 0.6
	return true


## Puts a driver on a lane and into the active list.
func _start(d: Driver, e: int, lane: int, s: float) -> void:
	d.active = true
	d.reg = -1
	d.next_reg = -1
	d.stun = 0.0
	d.held = false
	d.still = 0.0
	d.blocked = 0.0
	d.squeeze = 0.0
	d.clip = 1.0
	d.pending = 0.0
	d.arrived = false
	d.route = PackedFloat32Array()
	d.finish = -1
	d.run_red = false
	_enter_edge(d, e, lane, s)
	var p := graph.point_at(e, s, d.off)
	d.pos = Vector3(p.x, graph.height(e, s), p.y)
	var dir := graph.direction(e, s)
	d.yaw = atan2(-dir.x, -dir.y)
	d.visible = d.ghost == false and on_screen(d.pos, d.size.y)
	_active.append(d)


func _release(d: Driver) -> void:
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = -1
	d.active = false
	if d.kind < Kind.NODE and d.slot >= 0:
		var base := d.slot * 16
		for k in 12:
			_buf[d.kind][base + k] = 0.0
		_free_slots[d.kind].append(d.slot)
		_counts[d.kind] -= 1
		d.slot = -1
	var at := _active.find(d)
	if at >= 0:
		_active[at] = _active[_active.size() - 1]
		_active.resize(_active.size() - 1)
	if not d.persistent and not d.ghost:
		_free.append(d)


# --- rivals and the autopilot ------------------------------------------------------

## A persistent driver that draws itself with `node` (a rival's car).
func add_node_driver(node: Node3D, size: Vector3, e: int, lane: int, s: float) -> Driver:
	var d := Driver.new()
	d.kind = Kind.NODE
	d.node = node
	d.persistent = true
	d.core_only = true
	d.size = size
	d.length = size.z
	d.speed_factor = 1.08
	d.accel_factor = 1.3
	node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_start(d, e, lane, s)
	return d


## The autopilot's invisible driver; the game puts the player's car where it is.
func add_ghost(e: int, lane: int, s: float) -> Driver:
	var d := Driver.new()
	d.kind = Kind.NODE
	d.ghost = true
	d.persistent = true
	d.core_only = true
	d.size = Vector3(1.8, 1.5, 4.0)
	d.length = 4.0
	_start(d, e, lane, s)
	return d


func remove(d: Driver) -> void:
	if d.active:
		_release(d)


## Moves a driver to a lane position at once (and its node, if any).
func teleport(d: Driver, e: int, lane: int, s: float) -> void:
	if d.active:
		_release(d)
	_start(d, e, lane, s)
	d.v = 0.0
	_place(d)


## Starts racing to graph node `finish`: the driver follows the shortest path.
func race_to(d: Driver, finish: int, dist: PackedFloat32Array) -> void:
	d.route = dist
	d.finish = finish
	d.arrived = false
	if not d.in_conn:
		_choose_next(d)


func stop_racing(d: Driver) -> void:
	d.route = PackedFloat32Array()
	d.finish = -1
	d.arrived = false
	d.run_red = false
	if not d.in_conn:
		_choose_next(d)


## Driving distance left to the race finish.
func remaining(d: Driver) -> float:
	if d.route.is_empty():
		return INF
	if d.in_conn:
		return (d.conn_len - d.cu) + graph.remaining(d.route, d.next_edge, graph.e_s0[d.next_edge])
	return graph.remaining(d.route, d.edge, d.s)


func drivers() -> Array[Driver]:
	return _active


# --- driving ------------------------------------------------------------------------

## Lanes keep cars apart along a lane, but junction curves from different
## approaches cross each other. Cars in a junction box (or about to enter one)
## check each other: a car straight ahead in our path is a leader. When two cars
## are each in the other's path, the one already further in goes first, so they
## never wait for each other.
func _junction_conflicts() -> void:
	junction_cars.clear()
	for d in _active:
		d.cross_gap = INF
		d.sees_tram = false
		if not d.ghost and (d.in_conn or graph.e_s1[d.edge] - d.s < 14.0):
			junction_cars.append(d)
	if trams != null:
		_give_way_to_trams()
	for a in junction_cars.size():
		var p := junction_cars[a]
		var pf := Vector2(-sin(p.yaw), -cos(p.yaw))
		for b in range(a + 1, junction_cars.size()):
			var q := junction_cars[b]
			var rel := Vector2(q.pos.x - p.pos.x, q.pos.z - p.pos.z)
			if rel.length_squared() > 196.0 or q.reg == p.reg:
				continue
			var qf := Vector2(-sin(q.yaw), -cos(q.yaw))
			var p_sees := rel.dot(pf) > 0.0 and absf(rel.cross(pf)) < 1.9
			var q_sees := -rel.dot(qf) > 0.0 and absf(rel.cross(qf)) < 1.9
			if p_sees and q_sees:
				# Both in each other's way: the one deeper into the junction goes.
				if p.in_conn and (not q.in_conn or p.cu / p.conn_len > q.cu / q.conn_len):
					p_sees = false
				else:
					q_sees = false
			if p_sees:
				var g := rel.dot(pf) - (p.length + q.length) * 0.5
				if g < p.cross_gap:
					p.cross_gap = g
					p.cross_v = maxf(0.0, qf.dot(pf) * q.v)
			elif q_sees:
				var g := -rel.dot(qf) - (p.length + q.length) * 0.5
				if g < q.cross_gap:
					q.cross_gap = g
					q.cross_v = maxf(0.0, pf.dot(qf) * p.v)


func _enter_edge(d: Driver, e: int, lane: int, s: float) -> void:
	d.edge = e
	d.lane = lane
	d.s = s
	d.seg = graph.e_first[e]
	d.in_conn = false
	d.off = graph.lane_offset(e, lane)
	d.off_target = d.off
	_register(d, graph.e_lane0[e] + lane)
	d.ls = s
	_choose_next(d)


func _register(d: Driver, lane_id: int) -> void:
	if d.ghost:
		return
	if d.reg >= 0:
		_lane_cars[d.reg].erase(d)
	d.reg = lane_id
	_lane_cars[lane_id].append(d)


## Picks the edge after this one: by the race route, or at random with a liking
## for bigger roads and going straight; a U-turn only at a dead end.
func _choose_next(d: Driver) -> void:
	var e := d.edge
	var outs := graph.node_out[graph.e_b[e]]
	var rev := graph.e_reverse[e]
	var here := graph.direction(e, graph.e_s1[e])
	var best := -1
	if not d.route.is_empty():
		var best_d := INF
		for f in outs:
			var cost: float = graph.e_len[f] + d.route[graph.e_b[f]] + (60.0 if f == rev else 0.0)
			if cost < best_d:
				best_d = cost
				best = f
	else:
		var total := 0.0
		var weights := PackedFloat32Array()
		for f in outs:
			var w := 0.0
			if f != rev and not (d.core_only and graph.node_scc[graph.e_b[f]] == 0):
				w = [3.0, 2.0, 1.0, 0.35][graph.e_class[f]]
				if d.kind == Kind.BUS and graph.e_class[f] >= 2:
					w *= 0.05
				if absf(here.angle_to(graph.direction(f, graph.e_s0[f]))) < 0.5:
					w *= 1.6
			weights.append(w)
			total += w
		if total > 0.0:
			var r := _rng.randf() * total
			for k in outs.size():
				r -= weights[k]
				if r <= 0.0 and weights[k] > 0.0:
					best = outs[k]
					break
		elif rev >= 0:
			best = rev
	if best < 0:
		d.next_edge = -1
		d.next_reg = -1
		return
	d.next_edge = best
	d.next_lane = graph.next_lane(e, d.lane, best)
	d.conn = graph.connector(e, d.lane, best, d.next_lane)
	d.conn_len = LaneGraph.bezier_length(d.conn)
	d.conn_y0 = graph.height(e, graph.e_s1[e])
	d.conn_y1 = graph.height(best, graph.e_s0[best])
	var turn := absf(here.angle_to(graph.direction(best, graph.e_s0[best])))
	d.v_turn = 3.5 if best == rev else lerpf(16.0, 5.5, clampf(turn / 1.6, 0.0, 1.0))
	d.next_reg = graph.e_lane0[best] + d.next_lane
	# A racing rival chances some reds.
	d.run_red = not d.route.is_empty() and _rng.randf() < 0.6


func _drive(d: Driver, dt: float) -> void:
	var e := d.edge
	var v0 := graph.e_speed[e] * d.speed_factor
	if d.in_conn:
		v0 = minf(v0, d.v_turn)
	elif d.next_edge >= 0:
		v0 = minf(v0, sqrt(d.v_turn * d.v_turn + 2.0 * DECEL * 0.6 * maxf(graph.e_s1[e] - d.s, 0.0)))
	var gap := INF
	var lead_v := 0.0
	# The lane it is in (or curving into); the ghost reads lanes without being in them.
	var lane_id: int = d.next_reg if d.in_conn else graph.e_lane0[e] + d.lane
	if d.squeeze <= 0.0:
		for o in _lane_cars[lane_id]:
			if o != d and o.ls > d.ls:
				var g: float = o.ls - d.ls - (o.length + d.length) * 0.5
				if g < gap:
					gap = g
					lead_v = o.v
		if not d.in_conn and d.next_reg >= 0:
			var base: float = graph.e_s1[e] - d.s + d.conn_len - graph.e_s0[d.next_edge]
			for o in _lane_cars[d.next_reg]:
				if o != d:
					var g: float = base + o.ls - (o.length + d.length) * 0.5
					if g < gap:
						gap = g
						lead_v = o.v
	var leader_gap := gap
	var player_gap := INF
	if not d.ghost:
		var cross := d.cross_gap < gap and d.squeeze <= 0.0 and d.cross_ignore <= 0.0
		if cross:
			gap = d.cross_gap
			lead_v = d.cross_v
		if not d.in_conn:
			var stop := _red_ahead(d)
			if stop < gap:
				gap = stop
				lead_v = 0.0
		if player_on_road:
			var rel := Vector2(player_pos.x - d.pos.x, player_pos.z - d.pos.z)
			if rel.length_squared() < 900.0:
				var fwd := Vector2(-sin(d.yaw), -cos(d.yaw))
				var along := rel.dot(fwd)
				if along > 0.0 and absf(rel.cross(fwd)) < 2.3:
					var g := along - d.length * 0.5 - 2.4
					player_gap = g
					if g < gap:
						gap = g
						lead_v = maxf(0.0, Vector2(player_vel.x, player_vel.z).dot(fwd))
		if cross and gap == d.cross_gap and d.v < 0.3 and not d.sees_tram:
			d.cross_wait += dt
			if d.cross_wait > 8.0:
				d.cross_ignore = 3.0
				d.cross_wait = 0.0
		else:
			d.cross_wait = 0.0
		d.cross_ignore -= dt
	if not d.route.is_empty():
		_overtake(d, leader_gap, dt)
	elif not d.ghost and player_gap < 10.0 and player_gap <= gap + 0.01 and d.v < 0.5:
		# The player's car stands in the lane: go round it when the next lane is free.
		var was := d.blocked
		d.blocked += dt
		# Held up for 2 s, and every 10 s after that: the driver loses patience.
		if floori((d.blocked + 8.0) / 10.0) != floori((was + 8.0) / 10.0):
			blocked_by_player.emit(d)
		if d.blocked > 2.5 and _change_lane(d, 14.0):
			d.blocked = 0.0
	d.off = move_toward(d.off, d.off_target, 2.5 * dt)
	if d.held or d.stun > 0.0 or d.arrived:
		gap = minf(gap, 0.0)
		lead_v = 0.0
		d.stun -= dt

	var ratio := minf(d.v / maxf(v0, 0.1), 2.0)
	var a := ACCEL * d.accel_factor * (1.0 - ratio * ratio * ratio * ratio)
	if gap < INF:
		var star := MIN_GAP + maxf(0.0, d.v * HEADWAY + d.v * (d.v - lead_v) / (2.0 * sqrt(ACCEL * DECEL)))
		var q := star / maxf(gap, 0.05)
		a -= ACCEL * q * q
	d.v = maxf(0.0, d.v + maxf(a, -10.0) * dt)
	if gap < 0.2:
		d.v = minf(d.v, lead_v * 0.5)
	if d.route.is_empty() and not d.held:
		d.still = d.still + dt if d.v < 0.3 else 0.0

	var step := d.v * dt
	if d.in_conn:
		d.cu += step
		if d.cu >= d.conn_len:
			_enter_edge(d, d.next_edge, d.next_lane, graph.e_s0[d.next_edge] + d.cu - d.conn_len)
			e = d.edge
		else:
			d.ls = graph.e_s0[d.next_edge] - (d.conn_len - d.cu)
	else:
		d.s += step
		# Checked before the junction curve: a fast car can cross the last metres in a frame.
		if not d.route.is_empty() and graph.e_b[e] == d.finish and d.s >= graph.e_s1[e] - 3.0:
			d.arrived = true
		if d.s >= graph.e_s1[e]:
			if d.next_edge >= 0:
				d.in_conn = true
				d.cu = d.s - graph.e_s1[e]
				_register(d, d.next_reg)
				d.ls = graph.e_s0[d.next_edge] - (d.conn_len - d.cu)
			elif d.s >= graph.e_len[e] + d.length * 0.5:
				# Off the edge of the map.
				if d.persistent:
					if not _through_portal(d):
						teleport(d, e, d.lane, graph.e_s0[e])
				else:
					_release(d)
				return
		else:
			d.ls = d.s
	_place(d)


## A persistent driver (a rival, the autopilot) that drove off the map comes back in
## through an off-map link: the one towards its race finish, else any. False if the
## road has none.
func _through_portal(d: Driver) -> bool:
	var links := graph.e_portals[d.edge]
	if links.is_empty():
		return false
	var best := -1
	var best_cost := INF
	for i in links:
		var to := graph.portal_to[i]
		var cost := graph.portal_cost[i] + (graph.e_len[to] + d.route[graph.e_b[to]] if not d.route.is_empty() else _rng.randf() * 100.0)
		if cost < best_cost:
			best_cost = cost
			best = to
	if best < 0:
		return false
	var route := d.route
	var finish := d.finish
	var run_red := d.run_red
	teleport(d, best, mini(d.lane, graph.e_lanes[best] - 1), graph.e_s0[best])
	if not route.is_empty():
		race_to(d, finish, route)
		d.run_red = run_red
	return true


## A racer stuck behind slower traffic moves to a freer lane of the same road. If
## there is none it waits, and after a while slips through, but only out of sight.
func _overtake(d: Driver, leader_gap: float, dt: float) -> void:
	d.squeeze -= dt
	if leader_gap > 14.0 or d.in_conn or graph.e_s1[d.edge] - d.s < 18.0:
		d.still = 0.0
		return
	if _change_lane(d, leader_gap + 10.0):
		return
	if d.v < 1.0:
		d.still += dt
		if d.still > 6.0 and not d.visible:
			d.squeeze = 2.5
			d.still = 0.0


## Moves to the neighbouring lane with the most room ahead (more than `room`
## metres, nobody alongside), if the road has one. The car slides across.
func _change_lane(d: Driver, room_needed: float) -> bool:
	var e := d.edge
	if d.in_conn or graph.e_s1[e] - d.s < 18.0:
		return false
	var best := -1
	var best_room := room_needed
	for k in [d.lane - 1, d.lane + 1]:
		if k < 0 or k >= graph.e_lanes[e]:
			continue
		var room := 60.0
		for o in _lane_cars[graph.e_lane0[e] + k]:
			if o != d and o.ls > d.ls - (o.length + d.length) * 0.5 - 4.0:
				room = minf(room, o.ls - d.ls - (o.length + d.length) * 0.5)
		if room > best_room:
			best_room = room
			best = k
	if best < 0:
		return false
	d.lane = best
	if not d.ghost:
		_register(d, graph.e_lane0[e] + best)
	d.off_target = graph.lane_offset(e, best)
	_choose_next(d)
	return true


## Cars at a junction give way to a tram in their path: each tram car is checked
## at its front, middle and back.
func _give_way_to_trams() -> void:
	# Each visible tram car once: centre and axis (gathered first; reading node
	# transforms inside the loop below would cost far more than the maths).
	_tram_at.clear()
	_tram_axis.clear()
	for tram in trams.trams:
		for body in tram.cars:
			if body.visible:
				var t: Transform3D = body.global_transform
				_tram_at.append(Vector2(t.origin.x, t.origin.z))
				_tram_axis.append(Vector2(t.basis.z.x, t.basis.z.z).normalized())
	for d in junction_cars:
		var f := Vector2(-sin(d.yaw), -cos(d.yaw))
		var at := Vector2(d.pos.x, d.pos.z)
		for c in _tram_at.size():
			var rel := _tram_at[c] - at
			if rel.length_squared() > 900.0:
				continue
			var axis := _tram_axis[c]
			if absf(axis.dot(f)) > 0.8:
				continue  # running alongside the track, not across it
			for k in [-4.8, 0.0, 4.8]:
				var q: Vector2 = rel + axis * k
				var along := q.dot(f)
				if along > 0.0 and along < 22.0 and absf(q.cross(f)) < 2.1:
					var g := along - d.length * 0.5 - 1.6
					if g < d.cross_gap:
						d.cross_gap = g
						d.cross_v = 0.0
					d.sees_tram = true


## Gap to the first stop line ahead that shows red (or amber the car can stop for).
func _red_ahead(d: Driver) -> float:
	var stops := graph.e_stops[d.edge]
	var front := d.s + d.length * 0.5
	for k in range(0, stops.size(), 3):
		var at := stops[k]
		if at < front - 0.2:
			continue
		var state := graph.light(int(stops[k + 1]), int(stops[k + 2]))
		if state == LaneGraph.GREEN or d.run_red:
			return INF
		var g := at - front - 0.5
		if state == LaneGraph.AMBER and g < d.v * d.v / (2.0 * DECEL):
			return INF  # too close to stop: go through on amber
		return g
	return INF


## World position and heading from the lane (or the junction curve); the heading
## follows the motion, so cars swing smoothly through bends.
func _place(d: Driver) -> void:
	var p: Vector2
	var y: float
	var e := d.edge
	d.clip = 1.0
	if d.in_conn:
		var t := d.cu / d.conn_len
		p = LaneGraph.bezier(d.conn, t)
		y = lerpf(d.conn_y0, d.conn_y1, t)
	else:
		var length := graph.e_len[e]
		var s := minf(d.s, length)
		d.seg = graph.seek(e, s, d.seg)
		p = graph.point(e, s, d.off, d.seg)
		y = graph.height(e, s)
		if d.s > length - d.length * 0.5 and d.next_edge < 0:
			# Leaving the map: slide out under the edge of the diorama.
			var dir := graph.direction(e, length)
			p += dir * (d.s - length)
			d.clip = clampf((length - d.s + d.length * 0.5) / d.length, 0.0, 1.0)
	var moved := Vector2(p.x - d.pos.x, p.y - d.pos.z)
	if moved.length_squared() > 0.000001:
		d.yaw = lerp_angle(d.yaw, atan2(-moved.x, -moved.y), 0.35)
	d.pos = Vector3(p.x, y, p.y)
	if not d.ghost:
		d.visible = on_screen(d.pos, d.size.y)
	if d.node != null:
		d.node.global_transform = Transform3D(Basis(Vector3.UP, d.yaw), d.pos)


func _write() -> void:
	for d in _active:
		if d.kind >= Kind.NODE or d.slot < 0:
			continue
		var buf := _buf[d.kind]
		var b := d.slot * 16
		var c := cos(d.yaw)
		var s := sin(d.yaw)
		var z := d.clip
		var o := d.pos
		if z < 1.0:
			# Keep the rear where it is while the front disappears.
			o -= Vector3(-s, 0.0, -c) * (1.0 - z) * d.length * 0.5
		buf[b] = c
		buf[b + 1] = 0.0
		buf[b + 2] = s * z
		buf[b + 3] = o.x
		buf[b + 4] = 0.0
		buf[b + 5] = 1.0
		buf[b + 6] = 0.0
		buf[b + 7] = o.y
		buf[b + 8] = -s
		buf[b + 9] = 0.0
		buf[b + 10] = c * z
		buf[b + 11] = o.z
		buf[b + 12] = d.paint.r
		buf[b + 13] = d.paint.g
		buf[b + 14] = d.paint.b
		buf[b + 15] = float(d.shape)
		_top[d.kind] = maxi(_top[d.kind], d.slot + 1)
	for k in 4:
		# Loop 2c: draw only up to the highest slot in use (a freed slot is the next one taken,
		# so this stays near the most cars of the kind at once; the pools are 112 / 16 / 16 / 8).
		if _top[k] != _drawn[k]:
			_drawn[k] = _top[k]
			_mm[k].visible_instance_count = _top[k]
			_beam_mm[k].visible_instance_count = _top[k]
		_top[k] = 0
		RenderingServer.multimesh_set_buffer(_mm[k].get_rid(), _buf[k])
		if _beam_mmi[k].visible:
			RenderingServer.multimesh_set_buffer(_beam_mm[k].get_rid(), _buf[k])


# --- traffic-light lamps --------------------------------------------------------------

## A lamp box through each signal head's red, amber and green lights, coloured by
## its junction's controller. It shows on both faces of the head, so the light
## reads from wherever the camera looks.
func _build_lamps(signals: Array) -> void:
	var poles := graph.poles
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.28, 0.36)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	_lamps = MultiMesh.new()
	_lamps.transform_format = MultiMesh.TRANSFORM_3D
	_lamps.use_colors = true
	_lamps.mesh = mesh
	var spots: Array[Transform3D] = []
	for i in range(0, mini(signals.size() / 3, poles.size() / 2)):
		var c := poles[i * 2]
		if c < 0:
			continue
		var x := float(signals[i * 3])
		var z := float(signals[i * 3 + 1])
		var t := Transform3D(Basis(Vector3.UP, float(signals[i * 3 + 2])), Vector3(x, map.terrain_height(x, z), z))
		var key := c * 2 + poles[i * 2 + 1]
		if not _lamp_slots.has(key):
			_lamp_slots[key] = PackedInt32Array()
		_lamp_slots[key].append(spots.size())
		for y in [3.65, 3.35, 3.05]:
			spots.append(t * Transform3D(Basis(), Vector3(0, y, 0.2)))
	_lamps.instance_count = spots.size()
	var box := AABB()
	for k in spots.size():
		_lamps.set_instance_transform(k, spots[k])
		_lamps.set_instance_color(k, LAMP_OFF)
		box = AABB(spots[k].origin, Vector3.ZERO) if k == 0 else box.expand(spots[k].origin)
	_lamps.custom_aabb = box.grow(2.0)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _lamps
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# Halos: the same spots, a billboard each, coloured like the lamp (black when off).
	_halos = MultiMesh.new()
	_halos.transform_format = MultiMesh.TRANSFORM_3D
	_halos.use_colors = true
	_halos.mesh = MapBuilder.halo_quad(1.5)
	_halos.instance_count = spots.size()
	for k in spots.size():
		_halos.set_instance_transform(k, spots[k])
		_halos.set_instance_color(k, Color.BLACK)
	_halos.custom_aabb = _lamps.custom_aabb
	var glow := ShaderMaterial.new()
	glow.shader = load("res://shaders/glow.gdshader")
	glow.set_shader_parameter("billboard", true)
	glow.set_shader_parameter("radial", true)
	glow.set_shader_parameter("lift", 0.6)
	glow.render_priority = 1
	var hmi := MultiMeshInstance3D.new()
	hmi.multimesh = _halos
	hmi.material_override = glow
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hmi.visible = false
	hmi.add_to_group("night_lights")
	add_child(hmi)
	_lamp_state.resize(graph.ctrl_pos.size() * 2)
	_lamp_state.fill(-1)


func _update_lamps() -> void:
	for key in _lamp_slots:
		var state := graph.light(key / 2, key % 2)
		if state == _lamp_state[key]:
			continue
		_lamp_state[key] = state
		var red := state == LaneGraph.RED or state == LaneGraph.RED_AMBER
		var amber := state == LaneGraph.AMBER or state == LaneGraph.RED_AMBER
		var green := state == LaneGraph.GREEN
		for first in _lamp_slots[key]:
			_lamps.set_instance_color(first, LAMP_ON[0] if red else LAMP_OFF)
			_lamps.set_instance_color(first + 1, LAMP_ON[1] if amber else LAMP_OFF)
			_lamps.set_instance_color(first + 2, LAMP_ON[2] if green else LAMP_OFF)
			_halos.set_instance_color(first, HALO[0] if red else Color.BLACK)
			_halos.set_instance_color(first + 1, HALO[1] if amber else Color.BLACK)
			_halos.set_instance_color(first + 2, HALO[2] if green else Color.BLACK)
