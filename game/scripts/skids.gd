extends MultiMeshInstance3D
## Tyre marks: dark quads stamped under the rear wheels while the car slides or
## brakes hard, kept in a ring buffer so old marks give way to new ones.

const MAX_MARKS := 1600

var car: CharacterBody3D
var ground_height: Callable
var _next := 0
var _last: Array[Vector3] = [Vector3.INF, Vector3.INF]


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(-0.14, 0, -0.35), Vector3(0.14, 0, -0.35), Vector3(0.14, 0, 0.35), Vector3(-0.14, 0, 0.35)]
	# Clockwise seen from above (Godot's front faces); UV.x is the ground shader's depth bias.
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(Color("#2f3135"))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.45, 7.0))
		st.add_vertex(corners[k])
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = st.commit()
	multimesh.instance_count = MAX_MARKS
	multimesh.visible_instance_count = 0


func _process(_dt: float) -> void:
	var sliding: bool = car.slip > 3.0 or (car.brakes_on and car.forward_speed > 8.0)
	if not sliding:
		_last = [Vector3.INF, Vector3.INF]
		return
	var heading := Basis(Vector3.UP, car.rotation.y)
	for w in 2:
		var p: Vector3 = car.global_transform * Vector3(-0.78 if w == 0 else 0.78, 0.0, 1.3)
		if _last[w] != Vector3.INF and p.distance_to(_last[w]) < 0.45:
			continue
		p.y = ground_height.call(p.x, p.z) + 0.02
		multimesh.set_instance_transform(_next, Transform3D(heading, p))
		_next = (_next + 1) % MAX_MARKS
		multimesh.visible_instance_count = mini(multimesh.visible_instance_count + 1, MAX_MARKS)
		_last[w] = p
