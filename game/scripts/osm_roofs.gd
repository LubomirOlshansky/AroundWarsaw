class_name OsmRoofs
extends RefCounted
## The roofs lane (docs/design/roofs.md, RF4): a pitched roof for a small, low OpenStreetMap
## building (one without a GUGiK LoD2 model, so map_builder's `_build_buildings` drew it as a
## prism with a flat lid). A convex footprint of up to nine corners gets a hip roof, or a gable
## roof when it is a plain rectangle with a clear long side; each corner is projected onto the
## ridge line, which is the footprint's least-area box's centre line (shortened at both ends for
## a hip). Pure geometry from the footprint, so it is the same on both city paths; the roof takes
## the place of the flat lid (no extra draw call, a few triangles more). The walls stop at the
## eave and the ridge stands where the flat lid stood, so the roof grid (helicopter landings,
## roof cassettes) is unchanged.

const MIN_AREA := 30.0       ## m², a smaller footprint is a shed or a kiosk: flat
const MAX_AREA := 520.0      ## m², a bigger one is a block or a hall: flat
const MIN_H := 3.5           ## m, lower than this there is no eave worth drawing
const MAX_H := 16.0          ## m, taller ones are blocks (flat) or LoD2's
const MIN_SIDE := 4.0        ## m, the box's short side: a narrower roof is a passage
const PITCH := 0.55          ## ridge height over half the span (about 29 degrees)
const MIN_RISE := 0.8
const MAX_RISE := 4.2
const MIN_EAVE := 2.4        ## m, the walls keep at least this much
const FLAT_KINDS := ["office", "commercial", "retail", "industrial", "warehouse", "service", "school",
		"hospital", "university", "college", "kindergarten", "hotel", "government", "public", "civic",
		"parking", "steps", "roof", "bridge", "stadium", "supermarket", "transportation", "train_station",
		"museum", "theatre", "church", "cathedral", "chapel", "construction", "greenhouse", "container"]


## The roof for a footprint `poly` (counter-clockwise in x/z) of a building `h` m tall of OSM
## kind `kind`, or an empty dictionary when it stays flat. Returns "rise" (how much of `h` the
## roof takes; the walls stop `rise` below the old lid), "roof" (triangles as flat arrays of
## three Vector3, y relative to the eave: 0 at the walls, `rise` at the ridge) and "gables"
## (vertical triangles closing a gable end, y relative to the eave).
static func shape(poly: PackedVector2Array, h: float, kind: String) -> Dictionary:
	if poly.size() < 4 or poly.size() > 9 or h < MIN_H or h > MAX_H or FLAT_KINDS.has(kind):
		return {}
	var area := absf(_area(poly))
	if area < MIN_AREA or area > MAX_AREA or not _convex(poly):
		return {}
	var box := _box(poly)
	var axis: Vector2 = box["axis"]
	var length: float = box["length"]
	var width: float = box["width"]
	if width < MIN_SIDE or length > width * 4.5:
		return {}
	var rise := clampf(width * 0.5 * PITCH, MIN_RISE, MAX_RISE)
	rise = minf(rise, h - MIN_EAVE)
	if rise < MIN_RISE * 0.5:
		return {}
	var centre: Vector2 = box["centre"]
	# A gable: a four-cornered footprint that is nearly its own box, long enough to have a ridge.
	var gable := poly.size() == 4 and area > length * width * 0.88 and length > width * 1.35
	var half := length * 0.5 if gable else maxf(0.0, length * 0.5 - width * 0.5 * 0.92)
	var ridge_a := centre + axis * half
	var ridge_b := centre - axis * half
	var along := ridge_a - ridge_b
	var roof: Array = []
	var gables: Array = []
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var rp := _on_ridge(p, ridge_a, ridge_b, along)
		var rq := _on_ridge(q, ridge_a, ridge_b, along)
		var vp := Vector3(p.x, 0.0, p.y)
		var vq := Vector3(q.x, 0.0, q.y)
		var hp := Vector3(rp.x, rise, rp.y)
		var hq := Vector3(rq.x, rise, rq.y)
		if rp.distance_to(rq) < 0.01:
			if gable:
				gables.append([vp, vq, hp])  # the end wall's triangle, standing on the eave
			else:
				roof.append([vp, vq, hp])
		else:
			roof.append([vp, vq, hq])
			roof.append([vp, hq, hp])
	return {"rise": rise, "roof": roof, "gables": gables}


## A corner's foot on the ridge segment (clamped to its ends).
static func _on_ridge(p: Vector2, a: Vector2, b: Vector2, along: Vector2) -> Vector2:
	var len2 := along.length_squared()
	if len2 < 0.0001:
		return a
	var t := clampf((p - b).dot(along) / len2, 0.0, 1.0)
	return b + along * t


## The least-area box along one of the footprint's own edges: "axis" (the long side's direction),
## "centre", "length" (long) and "width" (short).
static func _box(poly: PackedVector2Array) -> Dictionary:
	var best := {"area": INF}
	for i in poly.size():
		var e := poly[(i + 1) % poly.size()] - poly[i]
		if e.length() < 1.0:
			continue
		var d := e.normalized()
		var s := Vector2(-d.y, d.x)
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q in poly:
			var r := Vector2(q.dot(d), q.dot(s))
			lo = lo.min(r)
			hi = hi.max(r)
		var size := hi - lo
		if size.x * size.y < float(best["area"]):
			var mid := (lo + hi) * 0.5
			var c := d * mid.x + s * mid.y
			if size.x >= size.y:
				best = {"area": size.x * size.y, "axis": d, "centre": c, "length": size.x, "width": size.y}
			else:
				best = {"area": size.x * size.y, "axis": s, "centre": c, "length": size.y, "width": size.x}
	return best


static func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## Whether every turn of the outline goes the same way (a nearly straight corner counts).
static func _convex(poly: PackedVector2Array) -> bool:
	var sign_seen := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var c := poly[(i + 2) % poly.size()]
		var cross := (b - a).cross(c - b)
		if absf(cross) < 0.05:
			continue
		if sign_seen == 0.0:
			sign_seen = signf(cross)
		elif signf(cross) != sign_seen:
			return false
	return sign_seen != 0.0
