extends SceneTree
## Vertex count of the built city (static meshes, plus MultiMesh instances x their mesh),
## to keep an eye on the budget:
##   godot --path game --resolution 320x180 --script res://tools/count_vertices.gd


func _initialize() -> void:
	var map: Node3D = load("res://scripts/map_builder.gd").new()
	root.add_child(map)
	var t0 := Time.get_ticks_msec()
	map.build("res://map/centrum.json", ShaderMaterial.new(), ShaderMaterial.new())
	var ms := Time.get_ticks_msec() - t0
	var flat := 0
	var instanced := 0
	var stack: Array[Node] = [map]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
				flat += _vertices((c as MeshInstance3D).mesh)
			elif c is MultiMeshInstance3D:
				var mm := (c as MultiMeshInstance3D).multimesh
				instanced += mm.instance_count * _vertices(mm.mesh)
	print("vertices: meshes %d, instances %d, total %d · built in %d ms" % [flat, instanced, flat + instanced, ms])
	map.free()
	quit()


func _vertices(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n
