extends RefCounted
## Street races R3 (docs/design/street-races.md, F 2026-11-05: "they go only by the roads, never
## the skróty"): the racers' shortcuts. game/data/race_cuts.json (tools/race_cuts.py) lists straight
## cuts between two junctions across a plaza, a forecourt, a car park, a lawn or a wide pavement,
## checked for a clear 2.8 m corridor and level ground. Here they are snapped to the lane graph's
## nodes and handed out by knowledge: a rival knowing `share` of them gets each cut whose hash
## (cut, rival) falls under it, the same ones every race (Zbyszek knows all, Słoik none).
##
## A cut is driven both ways, and joins the far junction's roads only where the cut doesn't turn
## more than EXIT_TURN off the road's way (worked out once, at load: `exits`). `links(share, seed)`
## gives the racer's table (traffic.gd Driver.cuts: {node: [edge on, metres, ...]}) and the
## routing's extra links (lane_graph.gd distances_to's `extra_in`: {node: [from, cost, ...]}: the
## cut, a metre of it costing COST metres of road, plus the edge on and GAIN, the metres it must save), so the
## race's distances, the gap and the band count exactly the shortcuts the rival takes, and a
## racer never circles a cut it can't drive.

const PATH := "res://data/race_cuts.json"
## A cut's end must lie this close to a graph node (a re-bake that moves junctions further drops
## the cut; check_race_cuts.gd fails when many do).
const SNAP := 4.0
## A metre across a plaza (kerbs, people, a slower line) is worth this much road in the routing.
const COST := 1.15
## The most a cut may turn into the road it joins (rad).
const EXIT_TURN := 1.75
## A cut is taken only when it saves this many metres (traffic.gd best_cut, through `cost`).
const GAIN := 12.0

var a := PackedInt32Array()
var b := PackedInt32Array()
var length := PackedFloat32Array()
## Per cut, the edges it may join: a -> b in exits_ab, b -> a in exits_ba.
var exits_ab: Array[PackedInt32Array] = []
var exits_ba: Array[PackedInt32Array] = []
## Cuts in the file whose ends found no node.
var missed := 0
var total := 0
var _graph


## Reads the file and snaps every cut to the graph (an exact match first: the file is made from
## the same centrum.json; else the nearest node within SNAP).
func load_cuts(graph, path := PATH) -> void:
	a.clear()
	b.clear()
	length.clear()
	exits_ab.clear()
	exits_ba.clear()
	missed = 0
	total = 0
	_graph = graph
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("race cuts: %s does not parse" % path)
		return
	var exact := {}
	for n in graph.node_pos.size():
		var p: Vector2 = graph.node_pos[n]
		exact[Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))] = n
	for c: Array in parsed.get("cuts", []):
		total += 1
		var na := _node(graph, exact, Vector2(c[0], c[1]))
		var nb := _node(graph, exact, Vector2(c[2], c[3]))
		if na < 0 or nb < 0 or na == nb:
			missed += 1
			continue
		a.append(na)
		b.append(nb)
		length.append(graph.node_pos[na].distance_to(graph.node_pos[nb]))
		exits_ab.append(_exits(graph, na, nb))
		exits_ba.append(_exits(graph, nb, na))


## The roads out of `to` a cut from `from` may join (open, turning at most EXIT_TURN).
static func _exits(graph, from: int, to: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var chord: Vector2 = (graph.node_pos[to] - graph.node_pos[from]).normalized()
	for g: int in graph.node_out[to]:
		if graph.e_shut[g] < INF:
			continue
		if absf(chord.angle_to(graph.direction(g, graph.e_s0[g]))) <= EXIT_TURN:
			out.append(g)
	return out


func _node(graph, exact: Dictionary, p: Vector2) -> int:
	var key := Vector2i(roundi(p.x * 10.0), roundi(p.y * 10.0))
	if exact.has(key):
		return int(exact[key])
	var n: int = graph.nearest_node(p)
	if n >= 0 and graph.node_pos[n].distance_to(p) <= SNAP:
		return n
	return -1


## Whether a rival knowing `share` of the cuts (0-1), seeded by `seed` (its name), knows cut i.
static func knows(i: int, share: float, seed: int) -> bool:
	if share <= 0.0:
		return false
	if share >= 1.0:
		return true
	return posmod(hash(Vector2i(i, seed)), 1000) < int(share * 1000.0)


## The racer's cuts {node: PackedFloat32Array [edge on, metres, ...]} and the routing's links into
## each node {node: PackedFloat32Array [from, cost, ...]}, as [table, extra_in].
func links(share: float, seed: int) -> Array:
	var table := {}
	var extra := {}
	for i in a.size():
		if not knows(i, share, seed):
			continue
		for way in 2:
			var from := a[i] if way == 0 else b[i]
			var exits: PackedInt32Array = exits_ab[i] if way == 0 else exits_ba[i]
			for g in exits:
				if not table.has(from):
					table[from] = PackedFloat32Array()
				table[from].append_array(PackedFloat32Array([g, length[i]]))
				var end: int = _end_of(g)
				if not extra.has(end):
					extra[end] = PackedFloat32Array()
				extra[end].append_array(PackedFloat32Array([from, cost(length[i], _len_of(g))]))
	return [table, extra]


## What a cut of `metres` then `edge_len` m of road costs in the routing.
static func cost(metres: float, edge_len: float) -> float:
	return metres * COST + edge_len + GAIN


func _end_of(g: int) -> int:
	return _graph.e_b[g]


func _len_of(g: int) -> float:
	return _graph.e_len[g]
