extends SceneTree
## The edge roadworks in the prebuilt city, the one the phone loads (2026-11-05, F: "make sure"):
##   P1 the closures have their meshes. The bake keeps only the colliders (edge_roadworks.gd), so
##      until the streamer rebuilt them the phone had invisible barriers.
##   P2 the real car (car.gd, gas held) rammed head on into every closure at RAM_SPEED, faster than
##      a tuned car with its nitro, never goes through the barriers and never leaves the map. A car
##      thrown aside by a kerb or a wall on the way can pass a narrow closure's end or, at Andersa,
##      ride a higher deck over it: those end at the edge wall and are counted, not failed.
## Prints `check_edge_prebuilt: OK (...)` (exit 0) or the problems (exit 1).
##   godot --headless --path game --fixed-fps 60 --script res://tools/check_edge_prebuilt.gd

const SectorStreamer := preload("res://scripts/sector_streamer.gd")
const EdgeRoadworks := preload("res://scripts/edge_roadworks.gd")
const Car := preload("res://scripts/car.gd")

## m/s.
const RAM_SPEED := 42.0
## How far before the barrier line a run starts (m), and how long it lasts (s).
const RUN_UP := 26.0
const RUN_TIME := 1.6
## A car's middle this far past the barrier line (m) has gone through it (the box is 0.9 m deep).
const PAST := 0.6
## The barriers' collider is this tall (m); the edge wall stands 5 m in, a car past 4 m has left the map.
const BOX_TOP := 3.0
const WALL_IN := 4.0
## Frames to wait for the worker thread's meshes.
const MESH_WAIT := 1200

var map: Node3D
var car: CharacterBody3D
var list: Array = []
var problems: Array[String] = []
var _frames := 0
var _pieces := 0
var _i := -1
var _t := 0
var _xf := Transform3D.IDENTITY
var _past := -INF
var _where := Vector3.ZERO
var _out := false
var _inside := false
var _round := 0


func _initialize() -> void:
	map = SectorStreamer.open_whole(root, true)
	list = EdgeRoadworks.closures(map)


func _count_pieces() -> int:
	var n := 0
	var works := map.get_node_or_null("EdgeRoadworks")
	if works != null:
		for c in works.get_children():
			if c is MeshInstance3D:
				n += 1
	return n


func _next() -> bool:
	if car != null:
		car.free()
		car = null
	_i += 1
	if _i >= list.size():
		return false
	var c: Dictionary = list[_i]
	_xf = EdgeRoadworks.frame(c)
	var start := _xf * Vector3(0.0, 0.0, -RUN_UP)
	var dir := _xf.basis.z.normalized()
	car = Car.new()
	car.ground_height = map.drive_height
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel
	root.add_child(car)
	car.global_position = Vector3(start.x, maxf(start.y, map.ground_height(start.x, start.z)) + 0.2, start.z)
	car.rotation.y = atan2(-dir.x, -dir.z)
	car.vel = dir * RAM_SPEED
	car.forward_speed = RAM_SPEED
	car.throttle = 1.0
	_t = 0
	_past = -INF
	_out = false
	_inside = false
	return true


func _physics_process(dt: float) -> bool:
	_frames += 1
	if _i < 0:
		_pieces = _count_pieces()
		if _pieces == 0 and _frames < MESH_WAIT:
			return false
		if _pieces == 0:
			problems.append("P1 the prebuilt city's closures have no meshes (invisible barriers)")
		_next()
		return false
	_t += 1
	var p := car.global_position
	# A slanted road's run-up can start outside the wall: only a car that was inside can leave.
	var inside: bool = map.in_map(Vector2(p.x, p.z), -WALL_IN)
	_out = _out or (_inside and not inside)
	_inside = _inside or inside
	var l := _xf.affine_inverse() * car.global_position
	if l.z > _past:
		_past = l.z
		_where = l
	if _t * dt < RUN_TIME:
		return false
	var c: Dictionary = list[_i]
	var tag := "closure %d %s at (%.0f, %.0f)" % [_i, c["name"], (c["at"] as Vector2).x, (c["at"] as Vector2).y]
	if _out:
		problems.append("P2 %s: the car left the map" % tag)
	if _past > PAST:
		if absf(_where.x) <= float(c["half"]) and _where.y < BOX_TOP:
			problems.append("P2 %s: the car went through, %.1f m past the line" % [tag, _past])
		else:
			_round += 1
			print("  %s: past the line %.1f m across (half %.1f), %.1f m up, stopped by the edge wall" % [tag, _where.x, c["half"], _where.y])
	if _next():
		return false
	for s in problems.slice(0, 30):
		print("  " + s)
	if problems.is_empty():
		print("check_edge_prebuilt: OK (%d pieces of roadworks, %d closures rammed at %.0f m/s, %d past the end or over)" % [_count_pieces(), list.size(), RAM_SPEED, _round])
	else:
		print("check_edge_prebuilt: %d problems" % problems.size())
	quit(1 if not problems.is_empty() else 0)
	return false
