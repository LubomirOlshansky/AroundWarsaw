extends SceneTree
## Park details (park_details.gd, tools/bake_park_details.py): the baked file loads, every kind is
## known and builds as one surface, a 512 m cell stays within the triangle budget and the count
## within its limits. The placement against the map is tools/check_park_details.py (step
## `parkdetails`). No map needed (CI too).
##   godot --headless --path game --script res://tools/check_park_details.gd

const ParkDetails := preload("res://scripts/park_details.gd")
const MAX_TRIS_CELL := 60000

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _init() -> void:
	var items := ParkDetails.load_items()
	_expect(items.size() > 0, "park_details.json has no items")
	_expect(items.size() <= ParkDetails.MAX_ITEMS, "%d items, over %d" % [items.size(), ParkDetails.MAX_ITEMS])
	var kinds: Array = ParkDetails.WATER_KINDS + ParkDetails.PLAY_KINDS + ParkDetails.LIFE_KINDS
	var per_kind := {}
	for kind: String in kinds:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		ParkDetails.add_item(st, kind, Transform3D.IDENTITY, "#c8282a")
		var mesh := st.commit()
		_expect(mesh != null and mesh.get_surface_count() == 1, "%s is not one surface" % kind)
		if mesh != null and mesh.get_surface_count() > 0:
			per_kind[kind] = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
	var worst := {}
	for item: Array in items:
		_expect(ParkDetails.known(item[0]), "unknown kind %s" % item[0])
		var key := Vector2i(int(floorf(float(item[1]) / ParkDetails.CELL)), int(floorf(float(item[2]) / ParkDetails.CELL)))
		worst[key] = int(worst.get(key, 0)) + int(per_kind.get(item[0], 0))
	var max_tris := 0
	for key: Vector2i in worst:
		max_tris = maxi(max_tris, int(worst[key]))
		_expect(int(worst[key]) <= MAX_TRIS_CELL, "cell %s has %d triangles, over %d" % [key, worst[key], MAX_TRIS_CELL])
	print("park_details: %d items, %d cells, busiest cell %d triangles" % [items.size(), worst.size(), max_tris])
	if _problems > 0:
		print("park_details: FAIL (%d)" % _problems)
		quit(1)
	else:
		print("park_details: OK")
		quit(0)
