extends RefCounted
## Collects triangles with the same calls as a SurfaceTool, but files each one
## into a square tile by its centre. The city then becomes many small meshes,
## and the renderer skips the tiles that are off screen.
##
## Loop 2b: 256 m tiles (were 128 m). The Mobile renderer draws every mesh with its own
## draw call (no automatic instancing there), and on the iPhone the draw calls, not the
## triangles, set the frame time: a quarter as many tiles costs a few more triangles off
## screen, which the phone's GPU doesn't notice. `add_arrays` files ready-made triangles
## (the LoD2 buildings) into a tile, so they share its mesh and draw call.
##
## Loop 3c: while one 512 m sector is built (map_builder.gd build_sector), `only` holds its
## 2 x 2 tiles and every triangle filed elsewhere is dropped: a feature crossing a border is
## built whole in both sectors, and each keeps the triangles whose centre lies in it.

const TILE := 256.0

## Loop 3c: the tile keys kept (empty: all of them); `none` keeps nothing (the roof pass).
var only := Rect2i()
var none := false

var _tools := {}  # Vector2i -> SurfaceTool
var _extra := {}  # Vector2i -> Array of mesh arrays added whole
var vertex_count := 0
var _colour := Color.WHITE
var _normal := Vector3.UP
var _uv := Vector2.ZERO
var _uv2 := Vector2.ZERO
var _count := 0
var _v: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _c: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var _n: Array[Vector3] = [Vector3.UP, Vector3.UP, Vector3.UP]
var _u: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var _u2: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]


func begin(_primitive: int) -> void:
	pass


func set_color(colour: Color) -> void:
	_colour = colour


func set_normal(normal: Vector3) -> void:
	_normal = normal


func set_uv(uv: Vector2) -> void:
	_uv = uv


func set_uv2(uv2: Vector2) -> void:
	_uv2 = uv2


func add_vertex(vertex: Vector3) -> void:
	_v[_count] = vertex
	_c[_count] = _colour
	_n[_count] = _normal
	_u[_count] = _uv
	_u2[_count] = _uv2
	_count += 1
	if _count < 3:
		return
	_count = 0
	var centre := (_v[0] + _v[1] + _v[2]) / 3.0
	var key := Vector2i(floori(centre.x / TILE), floori(centre.z / TILE))
	if none or (only.has_area() and not only.has_point(key)):
		return
	vertex_count += 3
	var st: SurfaceTool = _tools.get(key)
	if st == null:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_tools[key] = st
	for k in 3:
		st.set_color(_c[k])
		st.set_normal(_n[k])
		st.set_uv(_u[k])
		st.set_uv2(_u2[k])
		st.add_vertex(_v[k])


## Non-indexed triangles with the same attributes this tool writes (vertex, normal, colour,
## UV, UV2), for the tile `key`.
func add_arrays(key: Vector2i, arrays: Array) -> void:
	if none or (only.has_area() and not only.has_point(key)):
		return
	vertex_count += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	if not _extra.has(key):
		_extra[key] = []
	(_extra[key] as Array).append(arrays)


static func tile_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.z / TILE))


func meshes() -> Array[ArrayMesh]:
	var out: Array[ArrayMesh] = []
	var keys := _tools.keys()
	for key in _extra:
		if not _tools.has(key):
			keys.append(key)
	for key in keys:
		var arrays := []
		if _tools.has(key):
			arrays = (_tools[key] as SurfaceTool).commit_to_arrays()
		for more: Array in _extra.get(key, []):
			if arrays.is_empty():
				arrays = more.duplicate()
				continue
			for a in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
				arrays[a] = arrays[a] + more[a]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		out.append(mesh)
	return out
