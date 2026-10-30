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
## Loop 3d-1: everything it writes is derived and not committed (tools/setup_map.sh makes it on a
## fresh clone). It ends by writing map/sectors/city.stamp: the split's digest (sectors/split.stamp)
## and the SHA-256 of every input in CITY_INPUTS, so tools/check_map_data.py tells stale prebuilt
## sectors by content, not by file times.

const MapBuilder := preload("res://scripts/map_builder.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
const Proxies := preload("res://scripts/sector_proxies.gd")
const IndexPack := preload("res://scripts/index_pack.gd")
const SHARED := "res://map/shared/"
## index.json's keys only the map builder reads (the game's systems never do).
const BUILDER_ONLY := ["site_parts", "kerbs", "medians", "islands", "shore", "fills", "aprons", "lod2_cuts",
		"lod2_open", "towers", "garages", "dips"]

## Loop 3d-1: what the prebuilt sectors are built from besides the split (index.json and the
## sector files, covered by split.stamp's digest): the baked maps and the scripts the builder
## runs (shaders are referenced by path and need no rebuild). tools/check_map_data.py
## CITY_INPUTS is the same list.
const CITY_INPUTS := ["map/lod2.bin", "map/terrain.json", "map/ao.bin", "map/lights.bin", "map/water.bin",
		"scripts/map_builder.gd", "scripts/chunked_surface.gd", "scripts/neon_signs.gd", "scripts/landmarks.gd",
		"scripts/sector_proxies.gd", "scripts/models.gd", "scripts/pixel_font.gd", "scripts/index_pack.gd",
		"tools/bake_city.gd"]


## Set at the end of _bake: a script error (a builder that doesn't compile) ends _bake early
## with its default return value, 0, which reads as OK; without this the bake reported OK in
## 49 ms having written nothing (found merging loop 3c).
var _finished := false


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var err := _bake()
	if err == OK and not _finished:
		push_error("bake_city: the bake stopped on a script error (see above); nothing complete was written")
		err = FAILED
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
		if m.get_surface_count() == 0:
			continue  # an empty sector's proxy has no surface
		proxy_tris = maxi(proxy_tris, m.surface_get_array_index_len(0) / 3)
	proxies.free()
	if err != OK:
		map.free()
		return err
	# The exported game keeps only the game's part of the index: what the builder alone reads (its
	# derived grids are in the map node by now) stays in index.json for the runtime path.
	var game_data: Dictionary = map.index_data.duplicate()
	for k in BUILDER_ONLY:
		game_data.erase(k)
	# The memory loop: saved with its coordinates packed (scripts/index_pack.gd).
	IndexPack.pack(game_data)
	map.index_data = game_data
	_own(map, map)
	var packed_index := PackedScene.new()
	err = packed_index.pack(map)
	if err == OK:
		err = ResourceSaver.save(packed_index, "res://map/index.res", ResourceSaver.FLAG_COMPRESS)
	map.free()
	print("bake_city: %d sector scenes %.1f MB, index.res %.1f MB, proxies.scn %.2f MB (at most %d triangles a sector)" % [
			keys.size(), total / 1048576.0, FileAccess.get_file_as_bytes("res://map/index.res").size() / 1048576.0,
			FileAccess.get_file_as_bytes("res://map/proxies.scn").size() / 1048576.0, proxy_tris])
	if err == OK:
		err = _write_stamp()
	_finished = true
	return err


## Loop 3d-1: map/sectors/city.stamp (see CITY_INPUTS).
func _write_stamp() -> Error:
	var split: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/sectors/split.stamp"))
	var inputs := {}
	for p: String in CITY_INPUTS:
		inputs[p] = FileAccess.get_sha256("res://" + p) if FileAccess.file_exists("res://" + p) else ""
	var stamp := {"split": (split as Dictionary).get("digest", "") if split is Dictionary else "", "inputs": inputs}
	var f := FileAccess.open("res://map/sectors/city.stamp", FileAccess.WRITE)
	if f == null:
		push_error("bake_city: can't write map/sectors/city.stamp")
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(stamp, " ", true))
	f.close()
	return OK


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
	var ao: Texture2D = flat.get_shader_parameter("ao_map")
	var light: Texture2D = map.light_texture
	_detach_maps(map, shared)
	var items := [
		["ao_map", ao],
		["light_map", light],
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


## The web's first download (2026-10-30): the AO and lamp-light maps are put on their materials
## when the city opens (map_builder.gd attach_maps), not saved inside them, so an export can carry
## either form: the RG8 .res (phones, desktops) or the same texels as one zstd stream in
## map/shared/<name>.zst (the web: 11.1 MB instead of 18.8, in the download and in the browser's
## memory, which holds the whole pack). This records which materials read each map, clears it
## from them and from the map, and writes the .zst; the .res files are saved as before.
func _detach_maps(map: Node3D, shared: Dictionary) -> void:
	var flat: ShaderMaterial = map.flat_material
	var materials: Array[ShaderMaterial] = [flat]
	for m: Variant in [map.building_material, map.leaf_material] + shared.values():
		if m is ShaderMaterial and not materials.has(m):
			materials.append(m)
	var maps := {}
	for pair: Array in [["ao_map", flat.get_shader_parameter("ao_map")], ["light_map", map.light_texture]]:
		var tex: Texture2D = pair[1]
		if tex == null:
			continue
		var users: Array[ShaderMaterial] = []
		for m in materials:
			if m.get_shader_parameter(pair[0]) == tex:
				users.append(m)
				m.set_shader_parameter(pair[0], null)
		maps[pair[0]] = {"materials": users}
		var img := tex.get_image()
		img.convert(Image.FORMAT_RG8)
		var head := PackedByteArray()
		head.resize(8)
		head.encode_u32(0, img.get_width())
		head.encode_u32(4, img.get_height())
		var f := FileAccess.open(SHARED + String(pair[0]) + ".zst", FileAccess.WRITE)
		f.store_buffer(head + img.get_data().compress(FileAccess.COMPRESSION_ZSTD))
		var size := f.get_length()
		f.close()
		print("bake_city: %s attached at start (%d materials; %s.zst %.1f MB)" % [pair[0], users.size(), pair[0], size / 1048576.0])
	map.map_maps = maps
	map.light_texture = null


func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_own(child, owner)


func _count(node: Node) -> int:
	var n := node.get_child_count()
	for c in node.get_children():
		n += _count(c)
	return n
