extends SceneTree
## Mesh quality of every hand-built landmark (loop 0.1 + 0.2 of the landmarks plan, 2026-10-31):
## each site is built alone through `landmarks.gd` (a stub map with flat ground, the same way
## `check_sites.gd` does it, from the committed `map/centrum.json` only, so it runs in CI) and
## its triangles are examined, the defects a judge looking at a shot misses:
##   - triangle BUDGET per site (every site that emits triangles must have one: a new site
##     without an entry fails, so detail never goes in without a limit);
##   - draw calls: every triangle carries a landmark material code (UV2.x >= 2), so a site is
##     part of the city's one building surface and adds no draw call of its own;
##   - ZFIGHT: same-facing triangles on one plane (within 2 cm) that overlap by more than
##     0.01 m^2 flicker when the camera moves;
##   - DEGENERATE: zero-area triangles (< 1e-5 m^2) and BADNORMAL: triangles whose declared
##     normal disagrees with their geometry (|cos| < 0.5), which light wrongly;
##   - FLOAT: connected parts (welded to 5 cm) that touch neither the ground (y <= 0.2) nor the
##     box of a part that does (grown 10 cm): detail hanging in the air.
## The defects that exist today are a ratchet in KNOWN (counts per site and kind): the check
## fails when a count goes ABOVE it, and says so when it went below (lower the number). New
## defects fail at once. Not checked (the art-director judges them): parts inside parts, T gaps.
## Prints a line per site, then `check_mesh_quality: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_mesh_quality.gd

const Landmarks := preload("res://scripts/landmarks.gd")
## Triangles a site may hold: measured on 2026-10-31 plus about 20 % (raise on purpose only).
const BUDGET := {
	"aleksander": 1460,
	"brama_uw": 550,
	"bristol": 400,
	"karmelici": 450,
	"kordegarda": 560,
	"mickiewicz": 340,
	"potocki": 200,
	"arkadia": 1440,
	"blekitny": 910,
	"bridge": 110,
	"buw": 2900,
	"central": 340,
	"centralna": 1650,
	"chalubinskiego8": 1520,
	"cosmopolitan": 110,
	"dom_partii_extras": 100,
	"rynek": 3100,
	"syrenka": 480,
	"dtc": 1730,
	"europejski": 480,
	"flaga": 170,
	"forest": 130,
	"gpy": 250,
	"gaulle": 880,
	"grob": 340,
	"grzybowska63": 500,
	"gwardii": 1450,
	"hub_b": 100,
	"hub_c": 90,
	"ilmet": 180,
	"jp2_21": 280,
	"kopernik": 1720,
	"lim": 300,
	"lucka": 470,
	"marszalkowska94": 490,
	"mariensztat": 660,
	"mennica": 650,
	"mf": 1870,
	"mirowska": 1750,
	"msn": 500,
	"norblin": 1480,
	"browary": 3600,
	"koszyki": 1370,
	"elektrownia": 1950,
	"metropolitan": 3100,
	"muzeum": 840,
	"palace": 3900,
	"pawilony": 2100,
	"plater49": 140,
	"platinum_a": 80,
	"platinum_b": 80,
	"poniatowski": 380,
	"prezydencki": 1050,
	"q22": 960,
	"rondo1": 630,
	"rotunda": 1380,
	"skyliner": 400,
	"skysawa": 170,
	"slabs": 270,
	"spektrum": 990,
	"spire": 1290,
	"tr": 500,
	"tower75": 220,
	"cepelia": 900,
	"zodiak": 600,
	"ochota": 1420,
	"powisle": 1770,
	"stadion_pkp": 1900,
	"srodmiescie": 580,
	"stadium": 4750,
	"swieto": 240,
	"teatr": 600,
	"sw_krzyz": 1100,
	"sejm": 1400,
	"staszic": 360,
	"zamek": 340,
	"tarasy": 5700,
	"trojca": 2300,
	"unit": 1160,
	"varso": 1680,
	"wcf": 190,
	"wszystkich": 950,
	"wizytki": 690,
	"sw_anna": 620,
	"widok": 450,
	"pzu": 900,
	"jm": 900,
	"wiktoria": 230,
	"wtt": 1640,
	"zacheta": 720,
	"zlota44": 500,
	"zygmunt": 280,
}
## Known defects per site: {"zfight": n, "degenerate": n, "badnormal": n, "float": n}.
const KNOWN := {}
const ZFIGHT_AREA := 0.01
const ZFIGHT_PLANE := 0.02
const ZFIGHT_WINDOW := 0.3  ## coarse sort window; _coplanar decides
const DEGENERATE_AREA := 1.0e-5
const WELD := 20.0  ## vertices closer than 1/WELD m are one
const TOUCH := 0.1
const GROUND := 0.2

var problems: Array[String] = []
var notes: Array[String] = []


class StubMap:
	const ROOF_CELL := 4.0
	var _roof_x0 := 0.0
	var _roof_z0 := 0.0
	var _roof_nx := 0
	var _roof_nz := 0
	var _wall_faces := PackedVector3Array()

	func terrain_height(_x: float, _z: float) -> float:
		return 0.0

	func ground_height(_x: float, _z: float) -> float:
		return 0.0

	func tunnel_floor_under(_x: float, _z: float) -> float:
		return NAN

	func _roof_triangle(_a: Vector3, _b: Vector3, _c: Vector3, _is_roof: bool, _col := Color(0, 0, 0, 0)) -> void:
		pass


class Recorder:
	var pos := PackedVector3Array()
	var norms := PackedVector3Array()
	var codes := PackedFloat32Array()
	var _uv2 := Vector2.ZERO
	var _n := Vector3.UP

	func set_color(_c: Color) -> void:
		pass

	func set_normal(n: Vector3) -> void:
		_n = n

	func set_uv(_uv: Vector2) -> void:
		pass

	func set_uv2(uv2: Vector2) -> void:
		_uv2 = uv2

	func add_vertex(p: Vector3) -> void:
		pos.append(p)
		norms.append(_n)
		codes.append(_uv2.x)


func _initialize() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	if not data is Dictionary:
		print("check_mesh_quality: 1 problem\n  map/centrum.json missing or unreadable")
		quit(1)
		return
	var map := StubMap.new()
	var bounds: Array = data.get("bounds", [-3200.0, -2200.0, 3200.0, 2200.0])
	map._roof_x0 = float(bounds[0])
	map._roof_z0 = float(bounds[1])
	map._roof_nx = ceili((float(bounds[2]) - float(bounds[0])) / map.ROOF_CELL)
	map._roof_nz = ceili((float(bounds[3]) - float(bounds[1])) / map.ROOF_CELL)
	var marks = Landmarks.new(map, data)
	var keys: Array[String] = []
	for s: Dictionary in marks.sites:
		keys.append(s["key"])
	keys.sort()
	var measured := {}
	for key in keys:
		var rec := Recorder.new()
		marks.build(rec, Rect2(), key)
		var tris := rec.pos.size() / 3
		if tris == 0:
			continue  # a skin site: it builds nothing of its own
		var found := _examine(key, rec)
		measured[key] = found
		_judge(key, found)
	for key: String in BUDGET:
		if not measured.has(key):
			problems.append("%s: has a budget but builds nothing (site gone?)" % key)
	for n in notes:
		print("  note: " + n)
	if problems.is_empty():
		print("check_mesh_quality: OK (%d sites)" % measured.size())
		quit(0)
	else:
		print("check_mesh_quality: %d problems" % problems.size())
		for p in problems:
			print("  " + p)
		quit(1)


func _judge(key: String, f: Dictionary) -> void:
	var tris: int = f["tris"]
	var known: Dictionary = KNOWN.get(key, {})
	print("check_mesh_quality: %-16s %5d tris (budget %s)  zfight %d  degenerate %d  badnormal %d  float %d  plain %d" % [
			key, tris, str(BUDGET.get(key, "NONE")), f["zfight"], f["degenerate"], f["badnormal"], f["float"], f["plain"]])
	if not BUDGET.has(key):
		problems.append("%s: %d triangles and no BUDGET entry (add one)" % [key, tris])
	elif tris > int(BUDGET[key]):
		problems.append("%s: %d triangles (budget %d)" % [key, tris, BUDGET[key]])
	if f["plain"] > 0:
		problems.append("%s: %d triangles without a landmark material code (a draw call of its own)" % [key, f["plain"]])
	for kind: String in ["zfight", "degenerate", "badnormal", "float"]:
		var allowed := int(known.get(kind, 0))
		if f[kind] > allowed:
			problems.append("%s: %d %s (known %d)%s" % [key, f[kind], kind, allowed, _where(f, kind)])
		elif f[kind] < allowed:
			notes.append("%s: %s is down to %d (KNOWN says %d): lower it" % [key, kind, f[kind], allowed])


func _where(f: Dictionary, kind: String) -> String:
	var at: Array = f["at_" + kind]
	if at.is_empty():
		return ""
	var parts: Array[String] = []
	for v in at.slice(0, 3):
		parts.append("(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z])
	return " e.g. at " + ", ".join(parts)


func _examine(key: String, rec: Recorder) -> Dictionary:
	var tris := rec.pos.size() / 3
	var out := {"tris": tris, "zfight": 0, "degenerate": 0, "badnormal": 0, "float": 0, "plain": 0,
			"at_zfight": [], "at_degenerate": [], "at_badnormal": [], "at_float": []}
	var gn: Array[Vector3] = []  # geometric normal per triangle (zero for a degenerate one)
	var live: Array[int] = []
	for t in tris:
		var a := rec.pos[t * 3]
		var b := rec.pos[t * 3 + 1]
		var c := rec.pos[t * 3 + 2]
		if rec.codes[t * 3] < 2.0:
			out["plain"] += 1
		var cr := (b - a).cross(c - a)
		var area := cr.length() * 0.5
		if area < DEGENERATE_AREA:
			out["degenerate"] += 1
			out["at_degenerate"].append(a)
			gn.append(Vector3.ZERO)
			continue
		var n := cr.normalized()
		gn.append(n)
		live.append(t)
		var declared := rec.norms[t * 3]
		if declared.length() > 0.001 and absf(n.dot(declared.normalized())) < 0.5:
			out["badnormal"] += 1
			out["at_badnormal"].append(a)
	_zfight(rec, gn, live, out)
	_floating(rec, live, out)
	return out


func _zfight(rec: Recorder, gn: Array[Vector3], live: Array[int], out: Dictionary) -> void:
	# Buckets of near-equal plane normals (up to sign); inside one, triangles sorted by plane
	# distance are compared while their planes lie within ZFIGHT_PLANE.
	var buckets := {}
	# Plane distances are measured from the site's own centre: with positions 1500 m from the
	# origin, a 1e-5 difference between two near-equal normals alone shifts a distance by 1.5 cm.
	var origin := Vector3.ZERO
	if not live.is_empty():
		var lo := rec.pos[live[0] * 3]
		var hi := lo
		for t in live:
			for k in 3:
				lo = lo.min(rec.pos[t * 3 + k])
				hi = hi.max(rec.pos[t * 3 + k])
		origin = (lo + hi) * 0.5
	for t in live:
		var n := gn[t]
		var s := 1.0
		if n.x < -0.01 or (absf(n.x) <= 0.01 and (n.y < -0.01 or (absf(n.y) <= 0.01 and n.z < 0.0))):
			s = -1.0
		var cn := n * s
		var key := Vector3i(roundi(cn.x * 25.0), roundi(cn.y * 25.0), roundi(cn.z * 25.0))
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append([(rec.pos[t * 3] - origin).dot(cn), t, s])
	for key: Vector3i in buckets:
		var list: Array = buckets[key]
		if list.size() < 2:
			continue
		list.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		for i in list.size():
			for j in range(i + 1, list.size()):
				if list[j][0] - list[i][0] > ZFIGHT_WINDOW:
					break
				if list[i][2] != list[j][2] and gn[list[i][1]].dot(gn[list[j][1]]) < 0.0:
					# opposite facing: back to back, culled, no fight
					if (list[i][2] * list[j][2]) < 0.0:
						continue
				if not _coplanar(rec, list[i][1], list[j][1], gn[list[i][1]], gn[list[j][1]]):
					continue
				if _overlap(rec, list[i][1], list[j][1], gn[list[i][1]]) > ZFIGHT_AREA:
					out["zfight"] += 1
					out["at_zfight"].append(rec.pos[list[i][1] * 3])


## The exact test behind the sorted window: every vertex of each triangle within ZFIGHT_PLANE
## of the other's plane.
func _coplanar(rec: Recorder, ta: int, tb: int, na: Vector3, nb: Vector3) -> bool:
	for k in 3:
		if absf((rec.pos[tb * 3 + k] - rec.pos[ta * 3]).dot(na)) > ZFIGHT_PLANE:
			return false
		if absf((rec.pos[ta * 3 + k] - rec.pos[tb * 3]).dot(nb)) > ZFIGHT_PLANE:
			return false
	return true


func _overlap(rec: Recorder, ta: int, tb: int, n: Vector3) -> float:
	if gn_dot_sign(rec, ta, tb) < 0.0:
		return 0.0  # facing opposite ways: only one is drawn
	var ax := absf(n.x)
	var ay := absf(n.y)
	var az := absf(n.z)
	var drop := 0 if (ax >= ay and ax >= az) else (1 if ay >= az else 2)
	var pa := _flat(rec, ta, drop)
	var pb := _flat(rec, tb, drop)
	var box_a := Rect2(pa[0], Vector2.ZERO).expand(pa[1]).expand(pa[2])
	var box_b := Rect2(pb[0], Vector2.ZERO).expand(pb[1]).expand(pb[2])
	if not box_a.intersects(box_b):
		return 0.0
	var area := 0.0
	for poly in Geometry2D.intersect_polygons(pa, pb):
		area += _poly_area(poly)
	return area


func gn_dot_sign(rec: Recorder, ta: int, tb: int) -> float:
	var na := (rec.pos[ta * 3 + 1] - rec.pos[ta * 3]).cross(rec.pos[ta * 3 + 2] - rec.pos[ta * 3])
	var nb := (rec.pos[tb * 3 + 1] - rec.pos[tb * 3]).cross(rec.pos[tb * 3 + 2] - rec.pos[tb * 3])
	return na.dot(nb)


func _flat(rec: Recorder, t: int, drop: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 3:
		var v := rec.pos[t * 3 + k]
		match drop:
			0:
				p.append(Vector2(v.y, v.z))
			1:
				p.append(Vector2(v.x, v.z))
			_:
				p.append(Vector2(v.x, v.y))
	return p


func _poly_area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var q := p[(i + 1) % p.size()]
		a += p[i].x * q.y - q.x * p[i].y
	return absf(a) * 0.5


func _floating(rec: Recorder, live: Array[int], out: Dictionary) -> void:
	# Union-find over welded vertices.
	var parent := {}
	var find := func(k: Vector3i) -> Vector3i:
		var r := k
		while parent[r] != r:
			parent[r] = parent[parent[r]]
			r = parent[r]
		return r
	var kv := func(v: Vector3) -> Vector3i:
		return Vector3i(roundi(v.x * WELD), roundi(v.y * WELD), roundi(v.z * WELD))
	for t in live:
		var ks: Array[Vector3i] = []
		for k in 3:
			var key: Vector3i = kv.call(rec.pos[t * 3 + k])
			if not parent.has(key):
				parent[key] = key
			ks.append(key)
		for k in [1, 2]:
			var ra: Vector3i = find.call(ks[0])
			var rb: Vector3i = find.call(ks[k])
			if ra != rb:
				parent[ra] = rb
	var boxes := {}
	for t in live:
		var root: Vector3i = find.call(kv.call(rec.pos[t * 3]))
		var bb: AABB
		if boxes.has(root):
			bb = boxes[root]
		else:
			bb = AABB(rec.pos[t * 3], Vector3.ZERO)
		for k in 3:
			bb = bb.expand(rec.pos[t * 3 + k])
		boxes[root] = bb
	var roots: Array = boxes.keys()
	var supported := {}
	for r in roots:
		if (boxes[r] as AABB).position.y <= GROUND:
			supported[r] = true
	var grew := true
	while grew:
		grew = false
		for r in roots:
			if supported.has(r):
				continue
			for s in supported:
				if (boxes[s] as AABB).grow(TOUCH).intersects(boxes[r]):
					supported[r] = true
					grew = true
					break
	for r in roots:
		if not supported.has(r):
			out["float"] += 1
			out["at_float"].append((boxes[r] as AABB).position)
