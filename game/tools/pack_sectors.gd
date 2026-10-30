extends SceneTree
## The web loop 2 (2026-10-30): each prebuilt sector scene as a pack of its own for the web build,
## which downloads them as the car needs them (scripts/sector_packs.gd) instead of carrying all
## 108 in its pack. tools/export_web.sh runs it before the export:
##
##   godot --headless --path game --script res://tools/pack_sectors.gd -- <out dir>
##
## Writes <out dir>/sectors/s_<i>_<j>.<hash>.pck (the hash, from the scene's bytes, keeps a cached
## pack from an older build out; loop 3d-2b: with the sector's pieces, map/sectors/s_<i>_<j>/*.res,
## its meshes, MultiMeshes and collider patches the scene refers to) and res://map/web_sectors.json ({"packs": {name: path},
## "spawn": the map's spawn}), which the web preset puts in the game's pack.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("usage: godot --headless --path game --script res://tools/pack_sectors.gd -- <out dir>")
		quit(2)
		return
	var out := args[0].path_join("sectors")
	DirAccess.make_dir_recursive_absolute(out)
	for old in DirAccess.get_files_at(out):
		DirAccess.remove_absolute(out.path_join(old))
	var packs := {}
	var total := 0
	for file in DirAccess.get_files_at("res://map/sectors"):
		if not (file.begins_with("s_") and file.ends_with(".scn")):
			continue
		var res_path := "res://map/sectors/" + file
		var source := ProjectSettings.globalize_path(res_path)
		var name := file.get_basename()
		var rel := "sectors/%s.%s.pck" % [name, FileAccess.get_sha256(source).substr(0, 10)]
		var packer := PCKPacker.new()
		var ok := packer.pck_start(args[0].path_join(rel)) == OK and packer.add_file(res_path, source) == OK
		var pieces := "res://map/sectors/%s/" % name
		if ok and DirAccess.dir_exists_absolute(pieces):
			for piece in DirAccess.get_files_at(pieces):
				ok = ok and packer.add_file(pieces + piece, ProjectSettings.globalize_path(pieces + piece)) == OK
		if not ok or packer.flush() != OK:
			printerr("pack_sectors: can't pack %s" % file)
			quit(1)
			return
		packs[name] = rel
		total += FileAccess.get_file_as_bytes(args[0].path_join(rel)).size()
	var index: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://map/index.json"))
	var spawn: Dictionary = index.get("spawn", {}) if index is Dictionary else {}
	var f := FileAccess.open("res://map/web_sectors.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"packs": packs, "spawn": spawn}))
	f.close()
	print("pack_sectors: %d sector packs, %.1f MB, in %s" % [packs.size(), total / 1e6, out])
	quit(0 if not packs.is_empty() else 1)
