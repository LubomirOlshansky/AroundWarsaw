extends MultiMeshInstance3D
## Loop 10a: the splash when the car rolls into the water: a burst of droplets thrown up and
## forward, and a ring of foam spreading on the water round the car, for LIFE seconds. Small
## boxes in one MultiMesh with the actors' material (no new shader to compile), written with
## one buffer upload a frame while it plays; hidden (no draw call, no script) the rest of the
## time; no shadow.

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const DROPS := 56
const FOAM := 22
const LIFE := 1.3
const GRAVITY := 15.0
const SPRAY := Color("#f4fbff")
const SPRAY_BLUE := Color("#bfe0f2")
const FOAM_COLOUR := Color("#e9f3f6")

## Seconds since the last burst.
var _t := LIFE
var _start := PackedVector3Array()
var _vel := PackedVector3Array()
var _size := PackedFloat32Array()
var _buf := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(st, Vector3.ZERO, Vector3.ONE, Color.WHITE, Models.PAINT)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = st.commit()
	mm.instance_count = DROPS + FOAM
	mm.custom_aabb = AABB(Vector3(-12, -2, -12), Vector3(24, 12, 24))
	multimesh = mm
	material_override = Models.material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_start.resize(DROPS + FOAM)
	_vel.resize(DROPS + FOAM)
	_size.resize(DROPS + FOAM)
	_buf.resize((DROPS + FOAM) * 16)
	_rng.seed = 1997
	visible = false
	set_process(false)


## A splash at `at` (on the water's surface) for a car going `speed` m/s along `heading`.
func burst(at: Vector3, speed: float, heading: Vector3) -> void:
	global_position = at
	_t = 0.0
	var strength := clampf(speed / 18.0, 0.45, 1.0)
	var fwd := Vector3(heading.x, 0.0, heading.z).normalized() if heading.length() > 0.01 else Vector3.FORWARD
	var side := fwd.cross(Vector3.UP)
	for i in DROPS:
		# From round the car's nose and sides, up and outwards, more of them forwards.
		var a := _rng.randf() * TAU
		var out := Vector3(cos(a), 0.0, sin(a))
		_start[i] = fwd * _rng.randf_range(-1.0, 2.2) + side * _rng.randf_range(-1.1, 1.1) + Vector3.UP * 0.2
		_vel[i] = (out * _rng.randf_range(2.0, 5.5) + fwd * _rng.randf_range(0.5, 4.5)) * strength \
				+ Vector3.UP * _rng.randf_range(4.0, 9.0) * strength
		_size[i] = _rng.randf_range(0.22, 0.4)
		var tint := SPRAY if _rng.randf() < 0.65 else SPRAY_BLUE
		_set_custom(i, tint)
	for k in FOAM:
		var i := DROPS + k
		var a := TAU * k / FOAM + _rng.randf_range(-0.12, 0.12)
		_start[i] = Vector3(cos(a), 0.0, sin(a))
		_vel[i] = Vector3(_rng.randf_range(2.5, 4.0) * strength, 0.0, 0.0)
		_size[i] = _rng.randf_range(1.0, 1.5)
		_set_custom(i, FOAM_COLOUR)
	visible = true
	set_process(true)
	_process(0.0)


func _set_custom(i: int, c: Color) -> void:
	var b := i * 16
	_buf[b + 12] = c.r
	_buf[b + 13] = c.g
	_buf[b + 14] = c.b
	_buf[b + 15] = 0.0


func _process(dt: float) -> void:
	_t += dt
	if _t >= LIFE:
		visible = false
		set_process(false)
		return
	var t := _t
	var fade := 1.0 - t / LIFE
	for i in DROPS:
		var p := _start[i] + _vel[i] * t + Vector3.DOWN * (0.5 * GRAVITY * t * t)
		var s := _size[i] * (0.6 + 0.4 * fade)
		if p.y < -0.1:
			s = 0.0  # back in the water
		_write(i, p, Vector3(s, s, s), 0.0)
	for k in FOAM:
		var i := DROPS + k
		var dir := _start[i]
		# Out from the car's sides and slowing: 1.6 m to ~4.5 m from the middle.
		var r := 1.6 + _vel[i].x * (1.0 - exp(-2.2 * t)) / 2.2 * 1.4
		var w := _size[i] * fade
		_write(i, dir * r + Vector3.UP * 0.06, Vector3(w, 0.06, 0.32 * fade + 0.05), atan2(dir.x, dir.z))
	InstanceBuffers.send(multimesh.get_rid(), _buf)


## Instance i at local `p`, scaled by `s`, turned `yaw` about the vertical.
func _write(i: int, p: Vector3, s: Vector3, yaw: float) -> void:
	var c := cos(yaw)
	var n := sin(yaw)
	var b := i * 16
	_buf[b] = c * s.x
	_buf[b + 1] = 0.0
	_buf[b + 2] = n * s.z
	_buf[b + 3] = p.x
	_buf[b + 4] = 0.0
	_buf[b + 5] = s.y
	_buf[b + 6] = 0.0
	_buf[b + 7] = p.y
	_buf[b + 8] = -n * s.x
	_buf[b + 9] = 0.0
	_buf[b + 10] = c * s.z
	_buf[b + 11] = p.z
