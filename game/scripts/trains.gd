extends Node3D
## Trains on the city's railway (T1 of docs/design/railway.md): suburban units, the city line and
## long-distance trains on the baked rail tracks (OpenStreetMap `rails`, drawn by map_builder as
## ballast and rails). The tracks have no direction, so every piece is used both ways; pieces
## join where their ends meet and the line runs on smoothly. A train comes in where the railway
## enters the map (its edge, or one of the cross-city tunnel's mouths: the tunnel itself is not in
## the map), runs through at city speed, stops at the platforms it serves (Ochota, Powiśle,
## Stadion; the long-distance trains run through), and slides out under the next edge or into the
## next tunnel mouth; a while later another comes in somewhere. Only one train holds a stretch of
## track at a time, so trains never meet head on. Each car is an AnimatableBody3D (the player's car
## bounces off them, as off the trams); cars far from the view are hidden.

const Models := preload("res://scripts/models.gd")

## Cars are CAR m long with GAP m between them.
const CAR := 20.0
const GAP := 0.8
const CRUISE := 16.0          # 58 km/h: the cross-city line's speed through the centre
const ACCEL := 0.7
const DECEL := 0.9
const DWELL := 18.0
const HEIGHT_STEP := 8.0
## How many trains at most at once, and the wait (s) before a train that left comes back in.
const COUNT := 5
const RESPAWN := Vector2(8.0, 30.0)
## Track pieces join where their ends lie within LINK m and the line turns by under MAX_TURN rad.
const LINK := 0.8
const MAX_TURN := 0.55
## An end of the track this near the map's bounds is a way in and out; so is one near a tunnel
## mouth (the cross-city tunnel west of Ochota's cutting and under Powiśle's upper pavilion).
const EDGE := 45.0
const PORTALS := [Vector2(-1924.0, 800.0), Vector2(176.0, 80.0)]
const PORTAL_R := 40.0
## A platform within this distance of a track (its centre from the track's line) is a stop.
const PLATFORM_NEAR := 9.0
## A train this close to the end of its piece holds the next one.
const COMMIT := 80.0
## A train that has waited this long for its way to clear, out of sight, gives up and leaves.
const GIVE_UP := 45.0

## The kinds, all our own liveries (parody names in docs/design/railway.md section 4; the names on
## the sides are left for a later pass).
const KINDS := [
	{"name": "KOLEJE MAZOWE", "cars": 4, "body": "#f1f0ea", "band": "#2f8a45", "door": "#f0c22c", "roof": "#9a9d9f", "stops": true, "share": 0.5},
	{"name": "SKiM", "cars": 3, "body": "#d3262c", "band": "#f0c22c", "door": "#f0c22c", "roof": "#8a8d90", "stops": true, "share": 0.3},
	{"name": "INTERSZYBKO", "cars": 6, "body": "#b9c0c7", "band": "#1f3e78", "door": "#4a5058", "roof": "#6f7377", "stops": false, "share": 0.2},
]


class Train:
	var kind := 0
	var n_cars := 4
	var active := false
	var wait := 0.0           # inactive: seconds until it comes in; active: seconds stuck
	## Directed pieces it is on, oldest first; the last one holds the head.
	var trail := PackedInt32Array()
	var s := 0.0
	var v := 0.0
	var next := -1
	var dwell := 0.0
	var served := -1
	var cars: Array[AnimatableBody3D] = []
	var pos := Vector3.ZERO
	var dir := Vector2.UP
	var rear := Vector2.ZERO
	var exits := 0
	var stops_made := 0


var map: Node3D
var player_pos := Vector3.ZERO
var player_on_road := true
var trains: Array[Train] = []
## The view centre and reach (main.gd sets them from the traffic's view each frame).
var view_at := Vector2.ZERO
var view_reach := 700.0
## How long the last update took, for --bench.
var last_usec := 0
## For check_trains.gd: the stops made, [platform index, kind] per stop, and the most trains that
## ever held one physical track piece at once.
var stop_log: Array[Vector2i] = []
var most_on_a_piece := 0

# Directed pieces: 2 i runs along rail i as mapped, 2 i + 1 against it.
var _pts: Array[PackedVector2Array] = []
var _cum: Array[PackedFloat32Array] = []
var _len := PackedFloat32Array()
var _deck := PackedInt32Array()
var _succ: Array[PackedInt32Array] = []
var _pred: Array[PackedInt32Array] = []
var _sink := PackedByteArray()
var _sources := PackedInt32Array()
## Per directed piece, flat [s, platform index] of its stops, by s.
var _halts: Array[PackedFloat32Array] = []
var _heights: Array[PackedFloat32Array] = []
var _platforms: Array[Vector2] = []
var _bounds := Rect2()
var _rng := RandomNumberGenerator.new()


func setup(map_node: Node3D, data: Dictionary) -> void:
	map = map_node
	_rng.seed = 1955
	var b: Array = data.get("bounds", [-1e6, -1e6, 1e6, 1e6])
	_bounds = Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	for r in data.get("rails", []):
		var flat: Array = r["p"]
		var p := PackedVector2Array()
		for i in range(0, flat.size() - 1, 2):
			var q := Vector2(flat[i], flat[i + 1])
			if p.is_empty() or q.distance_to(p[p.size() - 1]) > 0.01:
				p.append(q)
		if p.size() < 2:
			continue
		var back := p.duplicate()
		back.reverse()
		for way: PackedVector2Array in [p, back]:
			_add_piece(way, int(r.get("dk", -1)))
	_link()
	for plat in data.get("platforms", []):
		var flat: Array = plat["p"]
		var c := Vector2.ZERO
		for k in range(0, flat.size() - 1, 2):
			c += Vector2(flat[k], flat[k + 1])
		_platforms.append(c / (flat.size() / 2.0))
	_find_halts()
	_make_trains()


func _add_piece(p: PackedVector2Array, deck: int) -> void:
	var c := PackedFloat32Array()
	var run := 0.0
	for i in p.size():
		if i > 0:
			run += p[i].distance_to(p[i - 1])
		c.append(run)
	_pts.append(p)
	_cum.append(c)
	_len.append(run)
	_deck.append(deck)
	_succ.append(PackedInt32Array())
	_pred.append(PackedInt32Array())
	_halts.append(PackedFloat32Array())
	_heights.append(PackedFloat32Array())


## Joins the pieces, finds the ways in and out, and drops every turn that leads only into a
## siding (a train must always reach a way out).
func _link() -> void:
	var n := _pts.size()
	var starts := {}
	for j in n:
		var key := _cell(_pts[j][0])
		if not starts.has(key):
			starts[key] = PackedInt32Array()
		starts[key].append(j)
	for i in n:
		var end := _pts[i][_pts[i].size() - 1]
		var out := _dir(i, _len[i])
		var cell := _cell(end)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				for j: int in starts.get(cell + Vector2i(dx, dz), PackedInt32Array()):
					if j == (i ^ 1) or _pts[j][0].distance_to(end) > LINK:
						continue
					if absf(out.angle_to(_dir(j, 0.0))) < MAX_TURN:
						_succ[i].append(j)
	_sink.resize(n)
	for i in n:
		_sink[i] = 1 if _succ[i].is_empty() and _is_way_out(_pts[i][_pts[i].size() - 1]) else 0
	# Which pieces lead to a way out (repeat until nothing changes).
	var good := _sink.duplicate()
	var changed := true
	while changed:
		changed = false
		for i in n:
			if good[i] == 0:
				for j in _succ[i]:
					if good[j] == 1:
						good[i] = 1
						changed = true
						break
	for i in n:
		var keep := PackedInt32Array()
		for j in _succ[i]:
			if good[j] == 1:
				keep.append(j)
		_succ[i] = keep
		for j in keep:
			_pred[j].append(i)
	for i in n:
		if good[i] == 1 and _pred[i].is_empty() and _is_way_out(_pts[i][0]) and _route_length(i) > 300.0:
			_sources.append(i)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))


func _is_way_out(p: Vector2) -> bool:
	if p.x < _bounds.position.x + EDGE or p.y < _bounds.position.y + EDGE or p.x > _bounds.end.x - EDGE or p.y > _bounds.end.y - EDGE:
		return true
	for q: Vector2 in PORTALS:
		if p.distance_to(q) < PORTAL_R:
			return true
	return false


## How far a train coming in on piece i runs (always the straightest way) before it leaves.
func _route_length(i: int) -> float:
	var total := 0.0
	var seen := {}
	while i >= 0 and not seen.has(i) and total < 5000.0:
		seen[i] = true
		total += _len[i]
		i = _straightest(i, false)
	return total


func _dir(i: int, s: float) -> Vector2:
	var p := _pts[i]
	var k := _seek(i, s)
	return (p[k + 1] - p[k]).normalized()


func _seek(i: int, s: float) -> int:
	var c := _cum[i]
	var k := 0
	while k < c.size() - 2 and c[k + 1] < s:
		k += 1
	return k


## A point s along piece i; beyond either end it carries on in a straight line.
func _point(i: int, s: float) -> Vector2:
	var p := _pts[i]
	if s <= 0.0:
		return p[0] + _dir(i, 0.0) * s
	if s >= _len[i]:
		return p[p.size() - 1] + _dir(i, _len[i]) * (s - _len[i])
	var k := _seek(i, s)
	var c := _cum[i]
	var seg := c[k + 1] - c[k]
	return p[k].lerp(p[k + 1], (s - c[k]) / seg if seg > 0.0001 else 0.0)


## The rails' height (on their bridge deck, or the ground), sampled once per piece.
func _height(i: int, s: float) -> float:
	if map == null:
		return 0.0
	var h := _heights[i]
	if h.is_empty():
		var n := ceili(_len[i] / HEIGHT_STEP) + 2
		h.resize(n)
		for k in n:
			var q := _point(i, minf(k * HEIGHT_STEP, _len[i]))
			h[k] = map.deck_height(_deck[i], q.x, q.y)
		_heights[i] = h
	var f := clampf(s / HEIGHT_STEP, 0.0, h.size() - 1.0001)
	return lerpf(h[int(f)], h[int(f) + 1], f - int(f))


## (s along piece i of the point nearest p, distance to it).
func _project(i: int, p: Vector2) -> Vector2:
	var best := Vector2(0.0, INF)
	var pts := _pts[i]
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.0001:
			continue
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best.y:
			best = Vector2(_cum[i][k] + t * sqrt(l2), d)
	return best


## A platform beside a track is a stop on it, both ways; the train's middle stops at the
## platform's middle (the head is placed half a train on, for each kind, in _move).
func _find_halts() -> void:
	for k in _platforms.size():
		for i in _pts.size():
			if _len[i] < 30.0:
				continue
			var near := _project(i, _platforms[k])
			if near.y < PLATFORM_NEAR and near.x > 1.0 and near.x < _len[i] - 1.0:
				_halts[i].append_array(PackedFloat32Array([near.x, k]))
	for i in _halts.size():
		var rows := []
		for k in range(0, _halts[i].size(), 2):
			rows.append(Vector2(_halts[i][k], _halts[i][k + 1]))
		rows.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var out := PackedFloat32Array()
		for r: Vector2 in rows:
			out.append_array(PackedFloat32Array([r.x, r.y]))
		_halts[i] = out


func _make_trains() -> void:
	if _sources.is_empty():
		return
	var meshes := []
	for kind: Dictionary in KINDS:
		meshes.append([car_mesh(kind, true), car_mesh(kind, false)])
	var most := 0
	for kind: Dictionary in KINDS:
		most = maxi(most, int(kind["cars"]))
	for n in COUNT:
		var t := Train.new()
		t.kind = _pick_kind()
		for k in most:
			var body := AnimatableBody3D.new()
			body.sync_to_physics = false
			body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			var mi := MeshInstance3D.new()
			mi.material_override = Models.material()
			body.add_child(mi)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.9, 4.2, CAR)
			shape.shape = box
			shape.position.y = 2.2
			body.add_child(shape)
			body.visible = false
			body.collision_layer = 0
			add_child(body)
			t.cars.append(body)
		_dress(t, meshes)
		# Spread the first arrivals out: a couple on the map at once, the rest a little later.
		t.wait = n * 6.0
		trains.append(t)
	for n in mini(2, trains.size()):
		_enter(trains[n], meshes)
	set_meta("meshes", meshes)


func _pick_kind() -> int:
	var r := _rng.randf()
	for k in KINDS.size():
		r -= float(KINDS[k]["share"])
		if r <= 0.0:
			return k
	return 0


## Gives train t its kind's car meshes (a cab at each end, the cars between plain).
func _dress(t: Train, meshes: Array) -> void:
	t.n_cars = int(KINDS[t.kind]["cars"])
	for k in t.cars.size():
		var mi := t.cars[k].get_child(0) as MeshInstance3D
		var end := k == 0 or k == t.n_cars - 1
		mi.mesh = meshes[t.kind][0 if end else 1]
		mi.rotation.y = PI if k == t.n_cars - 1 and k > 0 else 0.0


## Brings train t in on a way in whose first stretch is free; false if none is.
func _enter(t: Train, meshes: Array) -> bool:
	var order := Array(_sources)
	order.shuffle()
	for i: int in order:
		if _held(i, t):
			continue
		t.kind = _pick_kind()
		_dress(t, meshes)
		t.trail = PackedInt32Array([i])
		t.s = 0.0
		t.v = CRUISE * 0.8
		t.next = _straightest(i, true)
		t.served = -1
		t.dwell = 0.0
		t.wait = 0.0
		t.active = true
		return true
	return false


## Whether any other active train holds the physical track under directed piece i.
func _held(i: int, by: Train) -> bool:
	var phys := i >> 1
	for o in trains:
		if o == by or not o.active:
			continue
		for j in o.trail:
			if j >> 1 == phys:
				return true
		# Its next piece too once it is close to it (committed): two trains a long way off
		# would otherwise each hold the stretch between them for the other.
		if o.next >= 0 and o.next >> 1 == phys and not o.trail.is_empty() and _len[_head(o)] - o.s < COMMIT:
			return true
	return false


## The next piece after i: the straightest way on (a little variety where two are nearly as
## straight), or -1 at a way out.
func _straightest(i: int, vary: bool) -> int:
	var options := _succ[i]
	if options.is_empty():
		return -1
	var out := _dir(i, _len[i])
	var best := -1
	var best_turn := INF
	for j in options:
		var turn := absf(out.angle_to(_dir(j, 0.0)))
		if vary:
			turn += _rng.randf() * 0.06
		if turn < best_turn:
			best_turn = turn
			best = j
	return best


## --train=X,Z: an idle train onto the track nearest p, its middle there, rolling on.
func place_near(p: Vector2) -> bool:
	var best := -1
	var best_s := 0.0
	var best_d := INF
	for i in _pts.size():
		if _len[i] < 60.0 or _succ[i].is_empty() and _sink[i] == 0:
			continue
		var near := _project(i, p)
		if near.y < best_d:
			best_d = near.y
			best = i
			best_s = near.x
	if best < 0:
		return false
	for t in trains:
		if t.active:
			continue
		var s := clampf(best_s + length_of(t) * 0.5, 1.0, _len[best] - 1.0)
		t.trail = PackedInt32Array([best])
		var back := s
		while back < length_of(t) + 5.0 and not _pred[t.trail[0]].is_empty():
			var prev := _pred[t.trail[0]][0]
			t.trail.insert(0, prev)
			back += _len[prev]
		t.s = s
		t.v = CRUISE * 0.5
		t.next = _straightest(best, true)
		t.served = -1
		t.active = true
		return true
	return false


func length_of(t: Train) -> float:
	return t.n_cars * CAR + (t.n_cars - 1) * GAP


func _process(dt: float) -> void:
	step(dt)


## One update (check_trains.gd calls it directly, with no map and no view).
func step(dt: float) -> void:
	if dt <= 0.0 or trains.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	var meshes: Array = get_meta("meshes", [])
	for t in trains:
		if not t.active:
			t.wait -= dt
			if t.wait <= 0.0 and not _enter(t, meshes):
				t.wait = 3.0
			continue
		var head := _head(t)
		t.dir = _dir(head, clampf(t.s, 0.0, _len[head]))
		t.rear = _back_point(t, length_of(t))
	for t in trains:
		if t.active:
			_move(t, dt)
	# Bookkeeping for the check: the most trains on one physical piece.
	var count := {}
	for t in trains:
		if not t.active:
			continue
		var mine := {}
		for j in t.trail:
			mine[j >> 1] = true
		for k in mine:
			count[k] = count.get(k, 0) + 1
			most_on_a_piece = maxi(most_on_a_piece, count[k])
	for t in trains:
		if not t.active:
			continue
		var head := _back_point(t, 0.0)
		if map == null:
			t.pos = Vector3(head.x, 0.0, head.y)
		elif head.distance_to(view_at) < view_reach + length_of(t):
			_pose(t)
		else:
			t.pos = Vector3(head.x, t.pos.y, head.y)
			_hide(t)
	last_usec = Time.get_ticks_usec() - t0


func _head(t: Train) -> int:
	return t.trail[t.trail.size() - 1]


func _move(t: Train, dt: float) -> void:
	var head := _head(t)
	var gap := INF
	var half := length_of(t) * 0.5
	# The next stop on this piece or the next one.
	if bool(KINDS[t.kind]["stops"]):
		for pass_ in 2:
			var piece := head if pass_ == 0 else t.next
			if piece < 0 or gap < INF:
				break
			var offset := 0.0 if pass_ == 0 else _len[head] - t.s
			var halts := _halts[piece]
			for k in range(0, halts.size(), 2):
				var at := halts[k] + half
				var ahead := at - (t.s if pass_ == 0 else 0.0) + offset
				if ahead < -0.5 or int(halts[k + 1]) == t.served:
					continue
				gap = ahead
				if ahead < 0.8 and t.v < 0.3:
					t.dwell += dt
					if t.dwell > DWELL:
						t.served = int(halts[k + 1])
						t.dwell = 0.0
						t.stops_made += 1
						stop_log.append(Vector2i(t.served, t.kind))
				break
	# The way on: wait at the end of this piece while another train holds the next one.
	if t.next >= 0 and _held(t.next, t):
		gap = minf(gap, _len[head] - t.s - 2.0)
		if t.v < 0.2:
			t.wait += dt
			if t.wait > GIVE_UP and not _in_sight(t):
				_leave(t)
				return
	else:
		t.wait = 0.0
	# The player's car on the rails ahead.
	if player_on_road and map != null:
		var here := Vector2(t.pos.x, t.pos.z)
		var rel := Vector2(player_pos.x, player_pos.z) - here
		var along := rel.dot(t.dir)
		if along > 0.0 and along < 70.0 and absf(rel.cross(t.dir)) < 2.8 and absf(player_pos.y - t.pos.y) < 3.0:
			gap = minf(gap, along - 6.0)
	var want := CRUISE
	if gap < INF:
		want = minf(want, sqrt(maxf(gap - 0.3, 0.0) * 2.0 * DECEL))
	if t.v < want:
		t.v = minf(want, t.v + ACCEL * dt)
	else:
		t.v = maxf(want, t.v - DECEL * 3.0 * dt)
	t.s += t.v * dt
	if t.s >= _len[head]:
		if t.next >= 0 and not _held(t.next, t):
			t.s -= _len[head]
			t.trail.append(t.next)
			t.next = _straightest(t.next, true)
			var behind := 0.0
			for k in t.trail.size() - 1:
				behind += _len[t.trail[k]]
			while t.trail.size() > 2 and behind - _len[t.trail[0]] > length_of(t) + 5.0:
				behind -= _len[t.trail[0]]
				t.trail.remove_at(0)
		elif t.next < 0 and t.s > _len[head] + length_of(t) + 2.0:
			_leave(t)
		elif t.next >= 0:
			t.s = _len[head]
			t.v = 0.0


## Off the map or into the tunnel: gone, and back in a while somewhere.
func _leave(t: Train) -> void:
	t.active = false
	t.exits += 1
	t.trail = PackedInt32Array()
	t.next = -1
	t.wait = _rng.randf_range(RESPAWN.x, RESPAWN.y)
	_hide(t)


func _hide(t: Train) -> void:
	for body in t.cars:
		body.visible = false
		body.collision_layer = 0


func _in_sight(t: Train) -> bool:
	if map == null:
		return false
	for back in [0.0, length_of(t) * 0.5, length_of(t)]:
		if _back_point(t, back).distance_to(view_at) < view_reach:
			return true
	return false


## The point `back` m behind the head along the trail.
func _back_point(t: Train, back: float) -> Vector2:
	var k := t.trail.size() - 1
	var s := t.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[t.trail[k]]
	return _point(t.trail[k], s)


func _back_height(t: Train, back: float) -> float:
	var k := t.trail.size() - 1
	var s := t.s - back
	while s < 0.0 and k > 0:
		k -= 1
		s += _len[t.trail[k]]
	return _height(t.trail[k], clampf(s, 0.0, _len[t.trail[k]]))


## Places the cars along the rails; parts past a way out (or before a way in) are cut off, so a
## train slides out under the map's edge or into the tunnel's mouth.
func _pose(t: Train) -> void:
	var head := _head(t)
	var lo := t.s - _len[head] if t.next < 0 else -INF
	var hi := INF
	if _pred[t.trail[0]].is_empty():
		hi = t.s
		for k in t.trail.size() - 1:
			hi += _len[t.trail[k]]
	for k in t.cars.size():
		var body := t.cars[k]
		var f := k * (CAR + GAP)
		var b0 := maxf(f, lo)
		var b1 := minf(f + CAR, hi)
		if k >= t.n_cars or b1 - b0 < 0.3:
			body.visible = false
			body.collision_layer = 0
			continue
		var front := _back_point(t, b0)
		var rear := _back_point(t, b1)
		var y := (_back_height(t, b0) + _back_height(t, b1)) * 0.5
		var mid := (front + rear) * 0.5
		var d := front - rear
		body.visible = true
		body.global_transform = Transform3D(Basis(Vector3.UP, atan2(-d.x, -d.y)), Vector3(mid.x, y + 0.15, mid.y))
		(body.get_child(0) as Node3D).scale.z = (b1 - b0) / CAR
		var near := Vector2(mid.x - player_pos.x, mid.y - player_pos.z).length_squared() < 90.0 * 90.0
		body.collision_layer = 1 if near and player_on_road else 0
		if k == 0:
			t.pos = Vector3(front.x, y, front.y)


## One car of a kind (front at -Z): bogies, a dark skirt, the body in its colour with a band
## under the windows, a lit window band and the doors on both sides, a grey roof; a cab car has
## the driver's windscreen and lamps at its front and a pantograph.
static func car_mesh(kind: Dictionary, cab: bool) -> ArrayMesh:
	var st := Models._begin()
	var body := Color(kind["body"])
	var band := Color(kind["band"])
	var door := Color(kind["door"])
	var roof := Color(kind["roof"])
	var dark := Color("#232528")
	var hl := CAR * 0.5
	var w := 2.9
	# Bogies and the skirt.
	for z in [-hl + 3.2, hl - 3.2]:
		Models.box(st, Vector3(0.0, 0.55, z), Vector3(2.4, 0.7, 2.8), dark)
	Models.box(st, Vector3(0.0, 1.1, 0.0), Vector3(w - 0.1, 0.5, CAR - 0.4), dark)
	# The body, the band, the roof.
	var nose := 1.2 if cab else 0.0
	Models.box(st, Vector3(0.0, 2.6, nose * 0.5), Vector3(w, 2.5, CAR - nose), body)
	Models.box(st, Vector3(0.0, 1.95, nose * 0.5), Vector3(w + 0.04, 0.35, CAR - nose - 0.2), band)
	Models.box(st, Vector3(0.0, 2.98, nose * 0.5), Vector3(w + 0.03, 0.85, CAR - nose - 1.0), Models.GLASS, Models.LIT_WINDOW)
	Models.box(st, Vector3(0.0, 3.98, nose * 0.5), Vector3(w - 0.3, 0.3, CAR - nose - 0.4), roof)
	# Two doors a side.
	for z in [-hl * 0.5 + nose * 0.5, hl * 0.5]:
		Models.box(st, Vector3(0.0, 2.45, z), Vector3(w + 0.06, 2.3, 1.4), door)
	if cab:
		# The nose: a lower, sloped-looking front in two steps, the windscreen, the lamps.
		Models.box(st, Vector3(0.0, 2.2, -hl + nose * 0.5), Vector3(w - 0.1, 1.7, nose), body)
		Models.box(st, Vector3(0.0, 1.95, -hl + nose * 0.5), Vector3(w - 0.06, 0.35, nose - 0.1), band)
		Models.box(st, Vector3(0.0, 3.35, -hl + nose + 0.05), Vector3(w - 0.3, 0.9, 0.12), Models.GLASS)
		Models.box(st, Vector3(0.0, 3.12, -hl + nose * 0.75), Vector3(w - 0.3, 0.12, nose * 0.5), body.darkened(0.1))
		for x in [-0.95, 0.95]:
			Models.box(st, Vector3(x, 1.6, -hl - 0.02), Vector3(0.35, 0.2, 0.06), Models.HEADLIGHT, Models.HEAD_LAMP)
		# The pantograph, folded down over the cab end.
		Models.box(st, Vector3(0.0, 4.2, -hl + 5.0), Vector3(1.6, 0.1, 0.5), dark)
		Models.box(st, Vector3(0.0, 4.45, -hl + 5.6), Vector3(0.1, 0.5, 1.4), dark)
		Models.box(st, Vector3(0.0, 4.72, -hl + 6.2), Vector3(1.4, 0.06, 0.15), dark)
	return st.commit()
