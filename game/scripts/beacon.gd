extends Node3D
## A mission marker: a ring on the ground showing where to stop, a tall column of
## light that reads from across the map, and a tiny person (waving for help, or
## standing and waiting at the hospital).

const COLUMN_HEIGHT := 170.0

var waving := true
var _ring: MeshInstance3D
var _ring_radius := 0.0
var _ring_mat: StandardMaterial3D
var _column: MeshInstance3D
var _column_mat: StandardMaterial3D
var _person: Node3D
var _arm: Node3D
var _colour := Color.WHITE
var _t := 0.0


## Builds the parts once; `shirt` colours the person.
func setup(colour: Color, shirt: Color) -> void:
	_colour = colour
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.albedo_color = colour
	_ring = MeshInstance3D.new()
	_ring.material_override = _ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)

	_column_mat = StandardMaterial3D.new()
	_column_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_column_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_column_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_column_mat.vertex_color_use_as_albedo = true
	_column_mat.albedo_color = colour
	# After the post-process quad, which repaints the screen from a copy taken
	# before the transparent pass (see heli.gd).
	_column_mat.render_priority = 1
	_column = MeshInstance3D.new()
	_column.mesh = _column_mesh()
	_column.material_override = _column_mat
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_column)

	_person = _make_person(shirt)
	add_child(_person)
	visible = false


## Changes the ring and column colour (one beacon serves both side jobs).
func recolour(colour: Color) -> void:
	_colour = colour
	_ring_mat.albedo_color = colour
	_column_mat.albedo_color = colour


## Shows the marker at a spot; `radius` is the ring the vehicle has to stop in.
func place(at: Vector3, radius: float, column := true, person := true) -> void:
	global_position = at
	if radius != _ring_radius:
		_ring_radius = radius
		_ring.mesh = _ring_mesh(radius)
	_ring.visible = column
	_column.visible = column
	_person.visible = person
	visible = true


func _process(dt: float) -> void:
	if not visible:
		return
	_t += dt
	_column_mat.albedo_color = Color(_colour, 0.7 + 0.3 * sin(_t * 4.0))
	if waving:
		_arm.rotation.z = -0.25 + 0.55 * sin(_t * 9.0)
	else:
		_arm.rotation.z = -2.95  # hanging down at the side


## A flat ring 0.6 m wide, lifted a little so the ground layers don't cover it.
func _ring_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var o0 := Vector3(cos(a0), 0.0, sin(a0))
		var o1 := Vector3(cos(a1), 0.0, sin(a1))
		var y := Vector3(0, 0.4, 0)
		# Clockwise seen from above (Godot's front faces).
		for v in [o0 * radius, o1 * radius, o0 * (radius - 0.6), o1 * radius, o1 * (radius - 0.6), o0 * (radius - 0.6)]:
			st.add_vertex(v + y)
	return st.commit()


## A six-sided column of light, fading out towards the top.
func _column_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 1.1
	for i in 6:
		var a := Vector3(cos(TAU * i / 6.0) * r, 0.0, sin(TAU * i / 6.0) * r)
		var b := Vector3(cos(TAU * (i + 1) / 6.0) * r, 0.0, sin(TAU * (i + 1) / 6.0) * r)
		var up := Vector3(0, COLUMN_HEIGHT, 0)
		var low := Color(1, 1, 1, 0.75)
		var high := Color(1, 1, 1, 0.0)
		for v in [[a, low], [b, low], [b + up, high], [a, low], [b + up, high], [a + up, high]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
	return st.commit()


## A person about 2.5 m tall (a little over life size so it reads at pixel scale),
## with one arm on a shoulder pivot for waving.
func _make_person(shirt: Color) -> Node3D:
	var root := Node3D.new()
	var skin := Color("#e7b98f")
	var trousers := Color("#2d3442")
	for x in [-0.12, 0.12]:
		_box(root, Vector3(0.18, 0.95, 0.24), Vector3(x, 0.48, 0), trousers)
	_box(root, Vector3(0.5, 0.7, 0.3), Vector3(0, 1.3, 0), shirt)
	_box(root, Vector3(0.3, 0.32, 0.3), Vector3(0, 1.84, 0), skin)
	_box(root, Vector3(0.13, 0.66, 0.14), Vector3(-0.32, 1.28, 0), shirt)
	_arm = Node3D.new()
	_arm.position = Vector3(0.3, 1.58, 0)
	root.add_child(_arm)
	_box(_arm, Vector3(0.13, 0.66, 0.14), Vector3(0.0, 0.3, 0), shirt)
	_box(_arm, Vector3(0.13, 0.13, 0.14), Vector3(0.0, 0.66, 0), skin)
	root.scale = Vector3.ONE * 1.35
	return root


func _box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.9
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
