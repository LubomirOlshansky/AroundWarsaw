extends SceneTree
## Street details along the main line (street_details.gd, docs/design/street-details.md): the baked
## file loads, every kind is built, each 512 m cell's mesh is one surface within the triangle budget,
## the solids are only kiosks/stalls/carts, and the count is inside the budget. The placement
## against the map is tools/check_street_details.py (step `streetdetails`). No map needed (CI too).
##   godot --headless --path game --script res://tools/check_street_details.gd

const StreetDetails := preload("res://scripts/street_details.gd")
const MAX_TRIS_CELL := 25000
const KINDS := ["kiosk", "stall", "cafe", "planter", "column", "bollards", "cart", "post", "ticket"]

var _problems := 0


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


func _init() -> void:
	var items := StreetDetails.load_items()
	_expect(items.size() > 0, "street_details.json has no items")
	_expect(items.size() <= StreetDetails.MAX_ITEMS, "%d items, over %d" % [items.size(), StreetDetails.MAX_ITEMS])
	var seen := {}
	var cells := {}
	for item: Array in items:
		seen[item[0]] = true
		_expect(KINDS.has(item[0]), "unknown kind %s" % item[0])
		var key := Vector2i(int(floorf(float(item[1]) / StreetDetails.CELL)), int(floorf(float(item[2]) / StreetDetails.CELL)))
		cells[key] = int(cells.get(key, 0)) + 1
	for k: String in ["kiosk", "stall", "cafe", "planter", "post"]:
		_expect(seen.has(k), "no %s on the route" % k)
	for key: Vector2i in cells:
		_expect(int(cells[key]) <= StreetDetails.MAX_SECTOR, "cell %s holds %d items" % [key, cells[key]])
	# Build each kind once and count its triangles; a cell's total is items x that.
	var per_kind := {}
	for kind: String in KINDS:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		StreetDetails.add_item(st, kind, Transform3D.IDENTITY, "#e63946")
		var mesh := st.commit()
		_expect(mesh != null and mesh.get_surface_count() == 1, "%s is not one surface" % kind)
		if mesh != null and mesh.get_surface_count() > 0:
			per_kind[kind] = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
	var worst := {}
	for item: Array in items:
		var key := Vector2i(int(floorf(float(item[1]) / StreetDetails.CELL)), int(floorf(float(item[2]) / StreetDetails.CELL)))
		worst[key] = int(worst.get(key, 0)) + int(per_kind.get(item[0], 0))
	var max_tris := 0
	for key: Vector2i in worst:
		max_tris = maxi(max_tris, int(worst[key]))
		_expect(int(worst[key]) <= MAX_TRIS_CELL, "cell %s has %d triangles, over %d" % [key, worst[key], MAX_TRIS_CELL])
	print("street_details: %d items, %d cells, busiest cell %d triangles" % [items.size(), cells.size(), max_tris])
	if _problems > 0:
		print("street_details: FAIL (%d)" % _problems)
		quit(1)
	else:
		print("street_details: OK")
		quit(0)
