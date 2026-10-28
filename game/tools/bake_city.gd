extends SceneTree
## Builds the city once and saves it as res://map/city.scn, so the exported game
## loads it directly instead of generating every mesh on the phone.
## Run with a real renderer (not --headless, which drops MultiMesh and texture data):
##   godot --path game --resolution 320x180 --script res://tools/bake_city.gd

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	var building_mat := ShaderMaterial.new()
	building_mat.shader = load("res://shaders/building.gdshader")
	var flat_mat := ShaderMaterial.new()
	flat_mat.shader = load("res://shaders/ground.gdshader")
	var map: Node3D = load("res://scripts/map_builder.gd").new()
	map.name = "City"
	map.build("res://map/centrum.json", building_mat, flat_mat)
	_own(map, map)
	var packed := PackedScene.new()
	var err := packed.pack(map)
	if err == OK:
		err = ResourceSaver.save(packed, "res://map/city.scn", ResourceSaver.FLAG_COMPRESS)
	print("city.scn: ", error_string(err), " in %d ms" % (Time.get_ticks_msec() - t0))
	map.free()
	quit(0 if err == OK else 1)


func _own(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_own(child, owner)
