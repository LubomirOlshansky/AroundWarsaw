extends SceneTree
## Monuments and plaques (monuments.gd, tools/bake_monuments.py): the baked file loads, every kind is
## known and builds as one surface, the count is within its limit, and a 512 m cell with the park
## pieces and the monuments together stays within park_details' triangle budget. The placement
## against the map is tools/check_monuments.py (step `monuments`). No map needed (CI too).
##   godot --headless --path game --script res://tools/check_monuments.gd

const Monuments := preload("res://scripts/monuments.gd")
const ParkDetails := preload("res://scripts/park_details.gd")
const MAX_TRIS_CELL := 60000

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _tris(kind: String, monument: bool) -> int:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if monument:
		Monuments.add_item(st, kind, Transform3D.IDENTITY, "#4a4f46")
	else:
		ParkDetails.add_item(st, kind, Transform3D.IDENTITY, "#c8282a")
	var mesh := st.commit()
	_expect(mesh != null and mesh.get_surface_count() == 1, "%s is not one surface" % kind)
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3


func _init() -> void:
	var items := Monuments.load_items()
	_expect(items.size() > 0, "monuments.json has no items")
	_expect(items.size() <= Monuments.MAX_ITEMS, "%d items, over %d" % [items.size(), Monuments.MAX_ITEMS])
	var per_kind := {}
	for kind: String in Monuments.KINDS:
		per_kind[kind] = _tris(kind, true)
	var park_kinds: Array = ParkDetails.WATER_KINDS + ParkDetails.PLAY_KINDS + ParkDetails.LIFE_KINDS
	var park_tris := {}
	for kind: String in park_kinds:
		park_tris[kind] = _tris(kind, false)
	var cells := {}
	var counts := {}
	for item: Array in items:
		_expect(item.size() == 6, "item %s is not [kind, x, z, yaw, colour, name]" % [item])
		_expect(Monuments.known(item[0]), "unknown kind %s" % item[0])
		counts[item[0]] = int(counts.get(item[0], 0)) + 1
		var key := Vector2i(int(floorf(float(item[1]) / ParkDetails.CELL)), int(floorf(float(item[2]) / ParkDetails.CELL)))
		cells[key] = int(cells.get(key, 0)) + int(per_kind.get(item[0], 0))
	for item: Array in ParkDetails.load_items():
		var key := Vector2i(int(floorf(float(item[1]) / ParkDetails.CELL)), int(floorf(float(item[2]) / ParkDetails.CELL)))
		cells[key] = int(cells.get(key, 0)) + int(park_tris.get(item[0], 0))
	var max_tris := 0
	for key: Vector2i in cells:
		max_tris = maxi(max_tris, int(cells[key]))
		_expect(int(cells[key]) <= MAX_TRIS_CELL, "cell %s has %d triangles, over %d" % [key, cells[key], MAX_TRIS_CELL])
	print("monuments: %d items %s, %d cells, busiest cell %d triangles (with the park pieces)" % [items.size(), counts, cells.size(), max_tris])
	if _problems > 0:
		print("monuments: FAIL (%d)" % _problems)
		quit(1)
	else:
		print("monuments: OK")
		quit(0)
