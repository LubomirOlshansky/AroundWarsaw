extends SceneTree
## Loop 3b (docs/DEMO.md 4.5): can traffic and the player drive every lane without hitting
## anything? The city is every sector (loop 3c) built by the real map builder (or the prebuilt
## sector scenes with --prebuilt), the lanes are the real lane graph's.
##
##  1. Every lane of every lane-graph edge (between the junctions' trims, where cars drive
##     the lane itself; a metre short of a dead end), every STEP metres at the lane's own height
##     (lane_graph.gd `height`: its deck, its tunnel or the terrain): a car box (2.0 x 1.6 x 4.4 m)
##     and, on the roads buses drive (BUS_CLASS), a bus box
##     (2.6 x 3.2 x 12 m), placed like the vehicle (its axles half its length apart on the lane,
##     the body along the line between them; cut to the lane at an edge's ends, so a box doesn't
##     reach across the junction) and lifted LIFT off the road, are tested for
##     overlap with the static colliders (walls, parapets, guard rails, piers, retaining walls,
##     tunnel walls and portals, landmarks, barriers, solid props). Stepped overlap tests, not
##     cast_motion (it misses thin walls of the city's one big concave shape: BACKLOG "From
##     loop 10a"). The map's invisible edge walls are left out (traffic slides out under the
##     rim there: the last RIM metres).
##  2. The player's car on autopilot (as main.gd's: carried along the route, its height from
##     map.drive_height every frame like car.gd's, from the height it had) over ROUTES fixed
##     routes across the bridges and tunnels (both ways over each deck group and tunnel: its
##     longest edge each way, ~150 m on either side by the straightest way) at 24 m/s: every
##     frame whose height jumps
##     more than JUMP from the frame before.
##
## Prints each finding (with its --at=) and `check_drive: OK` when there is none, else the
## counts and exit 1. ~20 s (6 of it building the city).
##   godot --headless --path game --script res://tools/check_drive.gd [-- --prebuilt --verbose --dump=FILE --debug=X,Z --no-allow --routes=N]
## --verbose lists the routes, --dump writes every collision's contact points (an absolute path),
## --debug prints the autopilot's frames near a point. Loop 3e: --no-allow ignores
## tools/check_drive_allow.json (every finding counts: the before/after of a class), --routes=N
## drives N routes instead of ROUTES.

const MapBuilder := preload("res://scripts/map_builder.gd")
const SectorStreamer := preload("res://scripts/sector_streamer.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const MAP_PATH := "res://map/centrum.json"

const CAR := Vector3(2.0, 1.6, 4.4)
const BUS := Vector3(2.6, 3.2, 12.0)
const LIFT := 0.3          # the boxes' bottom over the lane's height
const STEP := 4.0          # metres between the sweep's samples
const RIM := 14.0          # samples this close to the map's edge are left out (the edge walls,
                           # 5 m in, and half a bus)
## Loop 3e: every structure both ways (the demo map's 55 deck groups and 10 tunnels: 98 routes,
## ~2 s); 20 before, which the tunnels alone filled. Map north: 61 deck groups and the SPOTS.
const ROUTES := 150
## Map north (2026-10-31): routes through every lane edge that passes within SPOT_REACH of these
## places too (both ways where the road has both), driven first: Rondo Radosława's ring and its
## approaches (Jana Pawła II from the old map's edge and up to its viaduct, Okopowa, Słomińskiego,
## Andersa's start), [x, z, what].
const SPOTS := [
	[-2833.0, -2238.0, "Rondo Radosława, the ring's north side"], [-2778.0, -2292.0, "Rondo Radosława, the ring's east side"],
	[-2833.0, -2346.0, "Rondo Radosława, the ring's south side"], [-2885.0, -2292.0, "Rondo Radosława, the ring's west side"],
	[-2768.0, -2180.0, "Jana Pawła II south of the ring"], [-2770.0, -2080.0, "Jana Pawła II at the old north edge"],
	[-2905.0, -2560.0, "Jana Pawła II north of the ring"], [-2900.0, -2180.0, "Okopowa"],
	[-2650.0, -2380.0, "Słomińskiego by Arkadia"], [-1880.0, -2560.0, "Andersa's start"],
]
const SPOT_REACH := 8.0
const ROUTE_REACH := 150.0 # each route runs this far on either side of its structure
const FRAME := 0.4         # metres per frame on the autopilot (24 m/s at 60 fps)
const JUMP := 0.3          # a height jump over this between two frames is a finding
const DEAD_END := 1.0      # a vehicle stops this short of a dead end's end
## The bus is swept on the roads buses drive (lane_graph.gd classes 0 and 1: main roads,
## links, tertiary): they spawn on main roads only and turn into a residential or living
## street with a 5 % weight (traffic.gd _choose_next), where a rigid 12 m box at OpenStreetMap's
## square corners says little; the car is swept everywhere.
const BUS_CLASS := 1

var map: Node3D
var graph: LaneGraph
var space: PhysicsDirectSpaceState3D
var prebuilt := false
var verbose := false
var _frames := 0
var _t0 := 0
var _query_car: PhysicsShapeQueryParameters3D
var _query_bus: PhysicsShapeQueryParameters3D
## --dump=FILE: every collision's contact points (kind edge lane s x z cx cy cz), for an overlay.
var dump_path := ""
## --debug=X,Z: print every autopilot frame within 6 m of that point (terrain, decks, height).
var debug_at := Vector2.INF
var _dump: PackedStringArray = []
## Loop 3d-1: tools/check_drive_allow.json, the places a finding is allowed (each with its reason:
## structures loop 3e builds, docs/DEMO.md 4.6): [kind ("lane" or "jump"), centre, radius].
var _allow: Array = []
var allowed := 0
## Loop 3e: --no-allow (count every finding) and --routes=N (more routes than ROUTES).
var no_allow := false
## --who: print the colliders each lane hit meets (parent/name), to see which piece a bus brushes.
var who := false
var routes_max := ROUTES


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--prebuilt":
			prebuilt = true
		elif a == "--verbose":
			verbose = true
		elif a.begins_with("--dump="):
			dump_path = a.trim_prefix("--dump=")
		elif a == "--no-allow":
			no_allow = true
		elif a == "--who":
			who = true
		elif a.begins_with("--routes="):
			routes_max = int(a.trim_prefix("--routes="))
		elif a.begins_with("--debug="):
			var xz := a.trim_prefix("--debug=").split(",")
			debug_at = Vector2(float(xz[0]), float(xz[1]))
	_t0 = Time.get_ticks_msec()
	var allow_path := ProjectSettings.globalize_path("res://").path_join("../tools/check_drive_allow.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(allow_path)) if FileAccess.file_exists(allow_path) else null
	if parsed is Dictionary and not no_allow:
		for a: Dictionary in parsed.get("allow", []):
			_allow.append([String(a["kind"]), Vector2(a["at"][0], a["at"][1]), float(a["r"])])
	# Loop 3c: the streamed city, every sector: the prebuilt sector scenes (--prebuilt) or the
	# sectors built from their files (the runtime path).
	map = SectorStreamer.open_whole(root, prebuilt)
	graph = LaneGraph.new(map.data["graph"], map)
	_query_car = _query(CAR)
	_query_bus = _query(BUS)
	print("check_drive: %s in %d ms" % ["the prebuilt sectors loaded" if prebuilt else "the sectors built", Time.get_ticks_msec() - _t0])


func _query(size: Vector3) -> PhysicsShapeQueryParameters3D:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = size
	q.shape = box
	q.collision_mask = 1
	return q


func _physics_process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _frames == 3:
		space = map.get_world_3d().direct_space_state
		var t := Time.get_ticks_msec()
		var sweep := _sweep()
		print("check_drive: sweep in %d ms" % (Time.get_ticks_msec() - t))
		t = Time.get_ticks_msec()
		var jumps := _routes()
		print("check_drive: routes in %d ms" % (Time.get_ticks_msec() - t))
		if not dump_path.is_empty():
			var f := FileAccess.open(dump_path, FileAccess.WRITE)
			f.store_string("\n".join(_dump) + "\n")
			f.close()
		var bad := sweep + jumps
		if allowed > 0:
			print("check_drive: %d findings allowed (tools/check_drive_allow.json)" % allowed)
		print("check_drive: %s" % ("OK" if bad == 0 else "%d FAILED (%d lane spots in collision, %d height jumps)" % [bad, sweep, jumps]))
		map.free()
		quit(0 if bad == 0 else 1)
	return false


## Loop 3d-1: whether a finding of this kind at p is in an allowed place.
func _allowed(kind: String, p: Vector2) -> bool:
	for a: Array in _allow:
		if a[0] == kind and p.distance_to(a[1]) <= float(a[2]):
			return true
	return false


# --- 1. every lane, a car and a bus ------------------------------------------------------

func _sweep() -> int:
	# Map north: the map's shape (map_builder.in_map: the bounds without the corner left outside).
	var samples := 0
	var lanes := 0
	var hits := {"car": [], "bus": []}
	for e in graph.e_a.size():
		var s0 := graph.e_s0[e]
		var s1 := graph.e_s1[e]
		# At a dead end (a street that stops at a gate or a wall) a vehicle stops a metre short.
		if _dead_end(graph.e_a[e], graph.e_reverse[e], true):
			s0 += DEAD_END
		if _dead_end(graph.e_b[e], graph.e_reverse[e], false):
			s1 -= DEAD_END
		if s1 - s0 < 0.5:
			continue
		for k in graph.e_lanes[e]:
			lanes += 1
			var off := graph.lane_offset(e, k)
			var s := s0
			while true:
				var p := graph.point_at(e, s, off)
				if map.in_map(p, -RIM):
					samples += 1
					var y := graph.height(e, s)
					for kind in (["car", "bus"] if graph.e_class[e] <= BUS_CLASS else ["car"]):
						var size: Vector3 = CAR if kind == "car" else BUS
						var q: PhysicsShapeQueryParameters3D = _query_car if kind == "car" else _query_bus
						# Placed like the vehicle: its axles (half its length apart) on the lane at
						# s -+ a quarter of its length, the body along the line between them; at an
						# edge's ends the box is cut to the lane (it doesn't reach across the
						# junction past the edge's end).
						var sa := maxf(s - size.z * 0.25, s0)
						var sb := minf(s + size.z * 0.25, s1)
						var a := graph.point_at(e, sa, off)
						var b := graph.point_at(e, sb, off)
						var dir := (b - a).normalized() if a.distance_to(b) > 0.01 else graph.direction(e, s)
						var mid := (a + b) * 0.5
						var ms := (sa + sb) * 0.5
						var front := minf(size.z * 0.5, s1 - ms)
						var rear := minf(size.z * 0.5, ms - s0)
						var length := maxf(front + rear, 1.0)
						var centre := mid + dir * (front - rear) * 0.5
						((q.shape as BoxShape3D)).size = Vector3(size.x, size.y, length)
						q.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.x, -dir.y)), Vector3(centre.x, y + LIFT + size.y * 0.5, centre.y))
						if not space.intersect_shape(q, 1).is_empty():
							if who:
								var names: Array = []
								for r in space.intersect_shape(q, 6):
									var co: Object = r["collider"]
									names.append("%s/%s" % [co.get_parent().name if co is Node and (co as Node).get_parent() != null else "?", (co as Node).name if co is Node else "?"])
								print("  WHO %s (%.1f, %.1f) edge %d: %s" % [kind, p.x, p.y, e, ", ".join(names)])
							if _allowed("lane", p):
								allowed += 1
								continue
							(hits[kind] as Array).append([p, e, k, s])
							if not dump_path.is_empty():
								for c in space.collide_shape(q, 4):
									_dump.append("%s %d %d %.1f %.2f %.2f %.2f %.2f %.2f" % [kind, e, k, s, p.x, p.y, c.x, c.y, c.z])
				if s >= s1:
					break
				s = minf(s + STEP, s1)
	print("check_drive: sweep: %d lanes, %d spots every %.0f m, %d car and %d bus boxes in collision" % [
			lanes, samples, STEP, (hits["car"] as Array).size(), (hits["bus"] as Array).size()])
	var total := 0
	for kind in ["car", "bus"]:
		total += (hits[kind] as Array).size()
		for place in _places(hits[kind]):
			var h: Array = place[0]
			var p: Vector2 = h[0]
			print("  FINDING %s at (%.0f, %.0f) x%d: %s lane %d at s=%.0f, height %.1f  [--at=%.0f,%.0f]" % [kind, p.x, p.y,
					place[1], graph.e_name[h[1]] if graph.e_name[h[1]] != "" else "edge %d" % h[1], h[2], h[3],
					graph.height(h[1], h[3]), p.x, p.y])
	return total


## True when node n is a dead end for edge e: nothing else leaves it (end) or enters it
## (start) but e's own reverse.
func _dead_end(n: int, rev: int, start: bool) -> bool:
	for f in (graph.node_in[n] if start else graph.node_out[n]):
		if f != rev:
			return false
	return true


## Hits within 25 m of each other are one place: [[first hit, count], ...].
func _places(list: Array) -> Array:
	var out: Array = []
	for h in list:
		var found := false
		for place in out:
			if (place[0][0] as Vector2).distance_to(h[0]) < 25.0:
				place[1] += 1
				found = true
				break
		if not found:
			out.append([h, 1])
	return out


# --- 2. the player's car over the bridges and tunnels -----------------------------------

func _routes() -> int:
	# One structure each: the longest edge of every tunnel, then of every deck group.
	# Both ways over each structure: its longest edge, and the longest running the other way.
	var best := {}
	for e in graph.e_a.size():
		var key := ""
		if graph.e_tn[e] >= 0:
			key = "tunnel %d" % graph.e_tn[e]
		elif graph.e_dk[e] >= 0:
			key = "deck %d" % graph.e_dk[e]
		else:
			continue
		if not best.has(key) or graph.e_len[e] > graph.e_len[best[key]]:
			best[key] = e
	for key: String in best.keys():
		var first: int = best[key]
		var d0 := graph.point_at(first, graph.e_len[first]) - graph.point_at(first, 0.0)
		var back := -1
		for e in graph.e_a.size():
			var k2 := ("tunnel %d" % graph.e_tn[e]) if graph.e_tn[e] >= 0 else (("deck %d" % graph.e_dk[e]) if graph.e_dk[e] >= 0 else "")
			if k2 != key or e == first:
				continue
			var d1 := graph.point_at(e, graph.e_len[e]) - graph.point_at(e, 0.0)
			if d1.dot(d0) < 0.0 and (back < 0 or graph.e_len[e] > graph.e_len[back]):
				back = e
		if back >= 0:
			best[key + " back"] = back
	var keys: Array = best.keys()
	keys.sort_custom(func(a: String, b: String) -> bool:
		return (a.begins_with("tunnel") and not b.begins_with("tunnel")) or \
				(a.begins_with("tunnel") == b.begins_with("tunnel") and graph.e_len[best[a]] > graph.e_len[best[b]]))
	# Map north: the SPOTS' edges first.
	var spot_keys: Array = []
	for spot: Array in SPOTS:
		var at := Vector2(float(spot[0]), float(spot[1]))
		for e in graph.e_a.size():
			var near := false
			var s := 0.0
			while s <= graph.e_len[e]:
				if graph.point_at(e, s).distance_to(at) < SPOT_REACH:
					near = true
					break
				s += 2.0
			if near:
				var k := "%s, edge %d" % [spot[2], e]
				best[k] = e
				spot_keys.append(k)
	keys = spot_keys + keys
	# Up to ROUTES: then through the longest structure edges no route has crossed yet.
	var paths := {}
	var used := {}
	for key in keys:
		var path := _route_through(best[key])
		paths[key] = path
		for e in path:
			used[e] = true
	var rest: Array = []
	for e in graph.e_a.size():
		if (graph.e_tn[e] >= 0 or graph.e_dk[e] >= 0) and not used.has(e):
			rest.append(e)
	rest.sort_custom(func(a: int, b: int) -> bool: return graph.e_len[a] > graph.e_len[b])
	for e: int in rest:
		if keys.size() >= routes_max:
			break
		if used.has(e):
			continue
		var key := "%s %d, edge %d" % ["tunnel" if graph.e_tn[e] >= 0 else "deck", graph.e_tn[e] if graph.e_tn[e] >= 0 else graph.e_dk[e], e]
		var path := _route_through(e)
		paths[key] = path
		keys.append(key)
		for f in path:
			used[f] = true
	# Still short of ROUTES (every structure edge is on a route): the multi-lane ones again on
	# their outermost lane.
	var lanes := {}
	for key: String in keys.duplicate():
		if keys.size() >= routes_max:
			break
		var path: Array[int] = paths[key]
		var e0: int = path[0]
		if graph.e_lanes[e0] > 1:
			keys.append(key + ", outer lane")
			paths[key + ", outer lane"] = path
			lanes[key + ", outer lane"] = graph.e_lanes[e0] - 1
	var routes := 0
	var jumps := 0
	var frames := 0
	for key in keys:
		if routes >= routes_max:
			break
		var path: Array[int] = paths[key]
		var r := _drive(path, lanes.get(key, 0))
		routes += 1
		frames += r[0]
		var kept: Array = []
		for j: Array in r[1]:
			if _allowed("jump", j[0]):
				allowed += 1
			else:
				kept.append(j)
		r[1] = kept
		jumps += (r[1] as Array).size()
		if verbose:
			print("  route %d (%s): %d edges, %d frames, %d jumps" % [routes, key, path.size(), r[0], (r[1] as Array).size()])
		for j: Array in r[1]:
			var p: Vector2 = j[0]
			print("  FINDING jump on route %d (%s) at (%.0f, %.0f): %.2f m in one frame (%.1f -> %.1f)  [--at=%.0f,%.0f]" % [
					routes, key, p.x, p.y, j[1], j[2], j[2] + j[1] * signf(j[3]), p.x, p.y])
	print("check_drive: autopilot: %d routes over the bridges and tunnels, %d frames at %.0f m/s, %d height jumps over %.1f m" % [
			routes, frames, FRAME * 60.0, jumps, JUMP])
	return jumps


## The edges of a route through edge e: back by the straightest way, e, then on.
func _route_through(e: int) -> Array[int]:
	var back: Array[int] = []
	var run := 0.0
	var cur := e
	while run < ROUTE_REACH:
		var prev := -1
		var turn := INF
		for g in graph.node_in[graph.e_a[cur]]:
			if g == graph.e_reverse[cur] or back.has(g) or g == e:
				continue
			var a := absf(graph.direction(g, graph.e_s1[g]).angle_to(graph.direction(cur, graph.e_s0[cur])))
			if a < turn:
				turn = a
				prev = g
		if prev < 0 or turn > 1.2:
			break
		back.append(prev)
		run += graph.e_len[prev]
		cur = prev
	back.reverse()
	var path: Array[int] = back.duplicate()
	path.append(e)
	run = 0.0
	cur = e
	while run < ROUTE_REACH:
		var nxt := -1
		var turn := INF
		for f in graph.node_out[graph.e_b[cur]]:
			if f == graph.e_reverse[cur] or path.has(f):
				continue
			var a := absf(graph.direction(cur, graph.e_s1[cur]).angle_to(graph.direction(f, graph.e_s0[f])))
			if a < turn:
				turn = a
				nxt = f
		if nxt < 0 or turn > 1.2:
			break
		path.append(nxt)
		run += graph.e_len[nxt]
		cur = nxt
	return path


## Drives a route from a lane of its first edge like main.gd's autopilot (lane to lane as
## traffic changes them at the junctions): [frames, [[p, jump, y, sign]]].
func _drive(path: Array[int], first_lane := 0) -> Array:
	var pts := PackedVector2Array()
	var lane := first_lane
	for i in path.size():
		var e: int = path[i]
		var off := graph.lane_offset(e, mini(lane, graph.e_lanes[e] - 1))
		var s := graph.e_s0[e]
		while s < graph.e_s1[e]:
			pts.append(graph.point_at(e, s, off))
			s += FRAME
		if i + 1 < path.size():
			var f: int = path[i + 1]
			var nl := graph.next_lane(e, mini(lane, graph.e_lanes[e] - 1), f)
			var c := graph.connector(e, mini(lane, graph.e_lanes[e] - 1), f, nl)
			var n := maxi(1, ceili(LaneGraph.bezier_length(c) / FRAME))
			for k in n:
				pts.append(LaneGraph.bezier(c, float(k) / n))
			lane = nl
	var jumps: Array = []
	if pts.is_empty():
		return [0, jumps]
	# The rim: a route starts and ends inside the map (past it a deck is cut off in the air).
	# Map north: the map's shape (map_builder.in_map: the bounds without the corner left outside).
	var keep := PackedVector2Array()
	for p in pts:
		if map.in_map(p, -RIM):
			keep.append(p)
	pts = keep
	if pts.is_empty():
		return [0, jumps]
	var y: float = map.drive_height(pts[0].x, pts[0].y, graph.height(path[0], graph.project(path[0], pts[0])))
	for p in pts:
		var ny: float = map.drive_height(p.x, p.y, y)
		if debug_at != Vector2.INF and p.distance_to(debug_at) < 6.0:
			print("debug: (%.1f, %.1f) from %.2f -> %.2f; terrain %.2f, decks %s, tunnel %.2f" % [p.x, p.y, y, ny,
					map.terrain_height(p.x, p.y), map._decks_at(p.x, p.y), map.tunnel_floor(p.x, p.y, y)])
		if absf(ny - y) > JUMP:
			jumps.append([p, absf(ny - y), y, ny - y])
		y = ny
	return [pts.size(), jumps]
