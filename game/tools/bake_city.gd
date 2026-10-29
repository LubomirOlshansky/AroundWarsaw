extends SceneTree
## Builds the city once, sector by sector (loop 3c), so the exported game streams it instead of
## generating every mesh on the phone:
##   map/sectors/s_<i>_<j>.scn   each 512 m sector in full detail (map_builder.gd build_sector)
##   map/proxies.scn             one low-detail mesh per sector (sector_proxies.gd)
##   map/index.res               the global index: the map node with its heights, decks, tunnels,
##                               water test, roof and picking grids, kerbs, the game's data
##   map/shared/*.res            the materials, textures and meshes every sector shares (saved
##                               once; the sector scenes refer to them by path)
## Reads map/index.json and map/sectors/<i>_<j>.json (tools/bake_sectors.py), and checks the
## landmark sites found from the index's `site_parts` against the whole map's (centrum.json).
## Run with a real renderer (not --headless, which drops MultiMesh and texture data):
##   godot --path game --resolution 320x180 --script res://tools/bake_city.gd

const MapBuilder := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Proxies := preload("res://scripts/sector_proxies.gd")
const SHARED := "res://map/shared/"


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var err := _bake()
	print("bake_city: %s in %d ms" % [error_string(err), Time.get_ticks_msec() - t0])
	quit(0 if err == OK else 1)


func _bake() -> Error:
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	if not index is Dictionary:
		push_error("bake_city: no map/index.json: run tools/bake_sectors.py first")
		return ERR_FILE_NOT_FOUND
	var building_mat := ShaderMaterial.new()
	building_mat.shader = load("res://shaders/building.gdshader")
	var flat_mat := ShaderMaterial.new()
	flat_mat.shader = load("res://shaders/ground.gdshader")
	var map: Node3D = MapBuilder.new()
	map.name = "City"
	map.setup_streamed(index, building_mat, flat_mat)
	if not _same_sites(map):
		map.free()
		return ERR_INVALID_DATA
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHARED))
	var err := _save_shared(map)
	if err != OK:
		map.free()
		return err
	for f in DirAccess.get_files_at("res://map/sectors/"):
		if f.ends_with(".scn"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("res://map/sectors/" + f))
	var keys: Array[Vector2i] = []
	for k: Array in index["sectors"]["keys"]:
		keys.append(Vector2i(int(k[0]), int(k[1])))
	var total := 0
	for key in keys:
		var t := Time.get_ticks_msec()
		var root: Node3D = map.build_sector(key)
		_own(root, root)
		var packed := PackedScene.new()
		err = packed.pack(root)
		var path := "res://map/sectors/%s.scn" % MapBuilder.sector_name(key)
		if err == OK:
			err = ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS)
		var size := FileAccess.get_file_as_bytes(path).size() if err == OK else 0
		total += size
		print("  %s: %d nodes, %.2f MB, %d ms" % [path.get_file(), _count(root), size / 1048576.0, Time.get_ticks_msec() - t])
		root.free()
		if err != OK:
			push_error("bake_city: %s: %s" % [path, error_string(err)])
			map.free()
			return err
	map.measure_sectors()
	var proxies := Proxies.build_all(map, keys)
	_own(proxies, proxies)
	var packed_proxies := PackedScene.new()
	err = packed_proxies.pack(proxies)
	if err == OK:
		err = ResourceSaver.save(packed_proxies, "res://map/proxies.scn", ResourceSaver.FLAG_COMPRESS)
	var proxy_tris := 0
	for c in proxies.get_children():
		var m := (c as MeshInstance3D).mesh
		proxy_tris = maxi(proxy_tris, m.surface_get_array_index_len(0) / 3)
	proxies.free()
	if err != OK:
		map.free()
		return err
	_own(map, map)
	var packed_index := PackedScene.new()
	err = packed_index.pack(map)
	if err == OK:
		err = ResourceSaver.save(packed_index, "res://map/index.res", ResourceSaver.FLAG_COMPRESS)
	map.free()
	print("bake_city: %d sector scenes %.1f MB, index.res %.1f MB, proxies.scn %.2f MB (at most %d triangles a sector)" % [
			keys.size(), total / 1048576.0, FileAccess.get_file_as_bytes("res://map/index.res").size() / 1048576.0,
			FileAccess.get_file_as_bytes("res://map/proxies.scn").size() / 1048576.0, proxy_tris])
	return err


## The landmark sites found from the index's `site_parts` must be the whole map's (a landmark
## searching where tools/bake_sectors.py SITE_NAMES / SITE_AREAS don't look fails here).
func _same_sites(map: Node3D) -> bool:
	var whole: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/centrum.json"))
	var full = Landmarks.new(map, whole)
	var mine: Array = map.get("_marks").sites
	var ok: bool = full.sites.size() == mine.size()
	for k in mini(full.sites.size(), mine.size()):
		if var_to_str(full.sites[k]) != var_to_str(mine[k]):
			ok = false
			push_error("bake_city: landmark site %s differs from the whole map's (tools/bake_sectors.py SITE_NAMES / SITE_AREAS)" % full.sites[k]["key"])
	if ok:
		print("bake_city: %d landmark sites, the same as the whole map's" % mine.size())
	return ok


## Saves what the sectors share once under map/shared/, so every sector scene refers to the
## same materials, textures and meshes (one copy in memory, per-frame updates reach them all).
func _save_shared(map: Node3D) -> Error:
	var shared: Dictionary = map.get("_shared")
	var flat: ShaderMaterial = map.flat_material
	var items := [
		["ao_map", flat.get_shader_parameter("ao_map")],
		["light_map", map.light_texture],
		["surface_map", map.water_texture],
		["ground", flat],
		["building", map.building_material],
		["leaves", map.leaf_material],
	]
	for name: String in shared:
		items.append([name, shared[name]])
	for item: Array in items:
		var res: Resource = item[1]
		if res == null:
			continue
		var path: String = SHARED + String(item[0]) + ".res"
		var err := ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
		if err != OK:
			push_error("bake_city: %s: %s" % [path, error_string(err)])
			return err
		# From now on the scenes saved refer to it by this path instead of carrying a copy.
		res.take_over_path(path)
	return OK


func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_own(child, owner)


func _count(node: Node) -> int:
	var n := node.get_child_count()
	for c in node.get_children():
		n += _count(c)
	return n
