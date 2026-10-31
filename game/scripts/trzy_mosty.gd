extends RefCounted
## Loop 3h slice 3 (docs/DEMO.md 6.3, "Progression"): the route of the final race "Trzy mosty",
## worked out on the lane graph (rivals.gd runs the race; check_ladder.gd tests the route).
##
## From Rondo Daszyńskiego (Wola) east over Most Śląsko-Dąbrowski, back west over Most
## Świętokrzyski, east again over Most Poniatowskiego, to the stands of the National Stadium: the
## Vistula crossed three times. Each bridge is a checkpoint at the middle of its river span (the
## longest `br` edge of that name going the leg's way: about 500 m each), the ring between the two
## carriageways so either counts. Seba drives the legs on the lane graph: to each span's near end,
## then its far end (so his shortest path really takes that bridge), then to the stadium:
## `legs` (graph nodes, in order), seven in all.
##
## All map-free but the lane graph: `build` needs only the graph and the map data's pois.

## The bridges, in order: the lane graph's street name, the way across (+1 east, -1 west) and the
## names for the HUD; `hint`: the checkpoint's map point on the current map, without the graph
## (main.gd starts the city there for --trzy-mosty=N).
const BRIDGES := [
	{"road": "Most Śląsko-Dąbrowski", "dir": 1, "pl": "Most Śląsko-Dąbrowski", "en": "Śląsko-Dąbrowski Bridge", "hint": Vector2(-138.0, -1689.0)},
	{"road": "Most Świętokrzyski", "dir": -1, "pl": "Most Świętokrzyski", "en": "Świętokrzyski Bridge", "hint": Vector2(689.0, -864.0)},
	{"road": "Most Księcia Józefa Poniatowskiego", "dir": 1, "pl": "Most Poniatowskiego", "en": "Poniatowski Bridge", "hint": Vector2(1176.0, -219.0)},
]
## The start: the middle of this roundabout's nodes, then the nearest lane heading for the first
## bridge (the start marker on it, Seba waiting START_GAP m further on).
const START_ROAD := "Rondo Ignacego Daszyńskiego"
const START_GAP := 16.0
## The start's map point without the graph (main.gd's --trzy-mosty starts the city here, so its
## sectors are built first): the start lane's point on the current map.
const START_HINT := Vector2(-2647.0, 410.0)
## The finish: this stadium poi (map data `pois`, kind "stadium"), at its stands: the node of a
## named street within FINISH_REACH m of the poi that is nearest by road from the last bridge but
## at least FINISH_MIN m on (the last dash; the nearest node of all is a 1 km loop of ramps away).
const FINISH_POI := "PGE Narodowy"
const FINISH_REACH := 270.0
const FINISH_MIN := 400.0
## A checkpoint counts within this many metres of its ring (both carriageways are within ~12 m of
## it) and this many metres of its deck's height (no counting from a road under a viaduct).
const CHECK_RADIUS := 20.0
const CHECK_HEIGHT := 6.0

## Set by build(): the start marker ([edge, lane, s] on the lane, its point, the heading), Seba's
## spot ([edge, lane, s]), the checkpoints ({pl, en, pos: Vector3, edge}), the finish
## ({pos: Vector3, node}), Seba's legs (graph nodes) and an error ("" when it built).
var start_lane: Array = []
var start_pos := Vector3.ZERO
var start_yaw := 0.0
var seba_lane: Array = []
var checkpoints: Array[Dictionary] = []
var finish: Dictionary = {}
var legs := PackedInt32Array()
var error := ""


## Works the route out on `graph` (lane_graph.gd) with the map data `data` (its pois). False, and
## `error` says why, if a bridge, the start or the finish is missing.
func build(graph, data: Dictionary) -> bool:
	checkpoints.clear()
	legs = PackedInt32Array()
	error = ""
	# The start: the roundabout's middle.
	var sum := Vector2.ZERO
	var n := 0
	for e in graph.e_a.size():
		if graph.e_name[e] == START_ROAD:
			for m: int in [graph.e_a[e], graph.e_b[e]]:
				sum += graph.node_pos[m]
				n += 1
	if n == 0:
		error = "no %s in the lane graph" % START_ROAD
		return false
	var rondo := sum / n
	# The bridges' spans.
	for b: Dictionary in BRIDGES:
		var span := _span(graph, str(b["road"]), int(b["dir"]))
		if span < 0:
			error = "no span of %s going %s" % [b["road"], "east" if int(b["dir"]) > 0 else "west"]
			return false
		var mid: Vector2 = graph.point_at(span, graph.e_len[span] * 0.5)
		# Between the carriageways: the other way's span, if it is a separate edge.
		var back := _span(graph, str(b["road"]), -int(b["dir"]))
		if back >= 0 and back != graph.e_reverse[span]:
			mid = (mid + graph.point_at(back, graph.e_len[back] * 0.5)) * 0.5
		checkpoints.append({"pl": b["pl"], "en": b["en"], "edge": span,
				"pos": Vector3(mid.x, graph.height(span, graph.e_len[span] * 0.5), mid.y)})
		legs.append(graph.e_a[span])
		legs.append(graph.e_b[span])
	# The finish.
	var at := Vector2.INF
	for p: Dictionary in data.get("pois", []):
		if str(p.get("k", "")) == "stadium" and str(p.get("name", "")) == FINISH_POI:
			at = Vector2(float(p["x"]), float(p["z"]))
	if at == Vector2.INF:
		error = "no %s poi" % FINISH_POI
		return false
	var fn := _finish_node(graph, at, legs[legs.size() - 1])
	if fn < 0:
		error = "no street by %s" % FINISH_POI
		return false
	var fp: Vector2 = graph.node_pos[fn]
	var fy := 0.0
	if not graph.node_in[fn].is_empty():
		var ein: int = graph.node_in[fn][0]
		fy = graph.height(ein, graph.e_s1[ein])
	finish = {"node": fn, "pos": Vector3(fp.x, fy, fp.y)}
	legs.append(fn)
	# The start lane: near the roundabout, heading for the first bridge.
	var first: Vector3 = checkpoints[0]["pos"]
	var heading := (Vector2(first.x, first.z) - rondo).normalized()
	var hit: Array = graph.snap(rondo + heading * 40.0, 60.0, heading, true, true)
	if hit.is_empty():
		error = "no lane by %s" % START_ROAD
		return false
	var e: int = hit[0]
	var s := clampf(float(hit[2]), graph.e_s0[e] + 1.0, maxf(graph.e_s1[e] - START_GAP - 4.0, graph.e_s0[e] + 1.0))
	start_lane = [e, int(hit[1]), s]
	var q: Vector2 = graph.point_at(e, s, graph.lane_offset(e, int(hit[1])))
	start_pos = Vector3(q.x, graph.height(e, s), q.y)
	var dir: Vector2 = graph.direction(e, s)
	start_yaw = atan2(-dir.x, -dir.y)
	seba_lane = [e, int(hit[1]), minf(s + START_GAP, graph.e_s1[e] - 0.5)]
	return true


## The finish node by the stadium (see FINISH_REACH); -1 if none.
static func _finish_node(graph, at: Vector2, from: int) -> int:
	var dist: PackedFloat32Array = graph.distances_from(from)
	var best := -1
	var best_d := INF
	for n in graph.node_pos.size():
		if graph.node_scc[n] == 0 or graph.node_pos[n].distance_to(at) > FINISH_REACH:
			continue
		if dist[n] < FINISH_MIN or dist[n] >= best_d:
			continue
		var named := false
		for e: int in graph.node_in[n]:
			named = named or graph.e_name[e] != ""
		if named:
			best_d = dist[n]
			best = n
	return best


## The river span of bridge `road` going `dir` (+1 east, -1 west): the longest bridge edge of that
## name in the connected core whose ends go that way; -1 if none.
static func _span(graph, road: String, dir: int) -> int:
	var best := -1
	var best_len := 0.0
	for e in graph.e_a.size():
		if graph.e_name[e] != road or graph.e_bridge[e] != 1:
			continue
		var a: int = graph.e_a[e]
		var b: int = graph.e_b[e]
		if graph.node_scc[a] == 0 or graph.node_scc[b] == 0:
			continue
		if (graph.node_pos[b].x - graph.node_pos[a].x) * dir <= 0.0:
			continue
		if graph.e_len[e] > best_len:
			best_len = graph.e_len[e]
			best = e
	return best


## Checkpoint `i` is passed by a vehicle at `at`.
func passed(i: int, at: Vector3) -> bool:
	if i < 0 or i >= checkpoints.size():
		return false
	var c: Vector3 = checkpoints[i]["pos"]
	return Vector2(at.x - c.x, at.z - c.z).length() < CHECK_RADIUS and absf(at.y - c.y) < CHECK_HEIGHT
