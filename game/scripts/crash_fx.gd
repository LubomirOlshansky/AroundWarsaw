extends Node3D
## v1.0 juice (2026-11-01): sparks and dust when the player's car hits something (car.gd
## `crashed`) and a thin trail of sparks while it scrapes along a wall or a barrier at speed
## (car.gd `scraped`). Built like the splash (splash.gd): small boxes in two MultiMeshes with
## the actors' material, so no new shader to compile; the sparks are a lamp part (they glow at
## dusk and night, warm white over the bloom), the dust a paint part tinted per puff. Each pool
## is a ring: a new spark takes the oldest slot, so a long scrape never grows the buffer. Both
## are written with one buffer upload a frame while anything lives and hidden (no draw call,
## no script) the rest of the time; no shadow. Two draw calls for about a second after a hit.
##
## Sparks fly out of the wall (along the contact normal), carry some of the car's speed along
## it, fall, bounce once off the road and die in 0.25-0.6 s, drawn as short streaks along
## their velocity. Dust rises slowly from the contact, grows and sinks back in about a second.

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")

const SPARKS := 72
const DUST := 28
const GRAVITY := 18.0
## How far from the anchor (the last hit) a particle may be drawn (custom AABB, metres).
const REACH := 16.0
## A spark's thickness (m) at birth; its length grows with its speed.
const SPARK_W := 0.36
const SPARK_COLOUR := Color("#ffb43c")
const DUST_COLOURS := [Color("#b9ad97"), Color("#a69d8d"), Color("#cbbfa9"), Color("#9a9180")]

## Hits so far (checks and the bench read them).
var bursts := 0
## Sparks thrown so far (scrapes included).
var sparks_thrown := 0

var _sparks: MultiMeshInstance3D
var _dust: MultiMeshInstance3D
var _sp_pos := PackedVector3Array()
var _sp_vel := PackedVector3Array()
var _sp_age := PackedFloat32Array()
var _sp_life := PackedFloat32Array()
var _sp_floor := PackedFloat32Array()
var _sp_next := 0
var _du_pos := PackedVector3Array()
var _du_vel := PackedVector3Array()
var _du_age := PackedFloat32Array()
var _du_life := PackedFloat32Array()
var _du_size := PackedFloat32Array()
var _du_next := 0
var _sp_buf := PackedFloat32Array()
var _du_buf := PackedFloat32Array()
var _live := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_sparks = _pool(SPARKS, SPARK_COLOUR, Models.HEAD_LAMP)
	_dust = _pool(DUST, Color.WHITE, Models.PAINT)
	_sp_pos.resize(SPARKS)
	_sp_vel.resize(SPARKS)
	_sp_age.resize(SPARKS)
	_sp_life.resize(SPARKS)
	_sp_floor.resize(SPARKS)
	_sp_age.fill(1.0)
	_sp_life.fill(0.0)
	_du_pos.resize(DUST)
	_du_vel.resize(DUST)
	_du_age.resize(DUST)
	_du_life.resize(DUST)
	_du_size.resize(DUST)
	_du_age.fill(1.0)
	_du_life.fill(0.0)
	_sp_buf.resize(SPARKS * 16)
	_du_buf.resize(DUST * 16)
	_rng.seed = 1944
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_hide()


func _pool(n: int, colour: Color, part: float) -> MultiMeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(st, Vector3.ZERO, Vector3.ONE, colour, part)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = st.commit()
	mm.instance_count = n
	mm.custom_aabb = AABB(Vector3(-REACH, -4.0, -REACH), Vector3(2.0 * REACH, 12.0, 2.0 * REACH))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Models.material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mmi)
	return mmi


## A hit at `at` (world), the contact normal `normal` (out of what was hit), the car moving
## `car_vel` before it, `speed` m/s lost or closing, the road at `ground_y`. `metal`: a car, a
## tram, a barrier or a post (more sparks, less dust) rather than a wall or a kerb.
func crash(at: Vector3, normal: Vector3, car_vel: Vector3, speed: float, ground_y: float, metal: bool) -> void:
	if speed < 3.0:
		return
	_anchor(at)
	bursts += 1
	var s := clampf((speed - 3.0) / 15.0, 0.0, 1.0)
	var sparks := int(lerpf(6.0, 36.0, s) * (1.0 if metal else 0.6)) if speed > 5.0 else 0
	var dust := int(lerpf(5.0, 18.0, s) * (0.5 if metal else 1.0))
	var n := _flat(normal)
	var along := car_vel - n * car_vel.dot(n)
	along.y = 0.0
	for i in sparks:
		_spark(at, n, along, lerpf(0.6, 1.0, s), ground_y)
	for i in dust:
		var k := _du_next
		_du_next = (_du_next + 1) % DUST
		var side := n.cross(Vector3.UP)
		_du_pos[k] = at + side * _rng.randf_range(-0.9, 0.9) + Vector3(0.0, _rng.randf_range(-0.2, 0.3), 0.0)
		_du_pos[k].y = maxf(_du_pos[k].y, ground_y + 0.15)
		_du_vel[k] = n * _rng.randf_range(0.4, 1.8) + along * _rng.randf_range(0.05, 0.2) \
				+ side * _rng.randf_range(-0.8, 0.8) + Vector3.UP * _rng.randf_range(0.5, 1.6)
		_du_age[k] = 0.0
		_du_life[k] = _rng.randf_range(0.8, 1.4) * lerpf(0.8, 1.2, s)
		_du_size[k] = _rng.randf_range(0.35, 0.7) * lerpf(0.8, 1.3, s)
		var c: Color = DUST_COLOURS[_rng.randi() % DUST_COLOURS.size()]
		var b := k * 16
		_du_buf[b + 12] = c.r
		_du_buf[b + 13] = c.g
		_du_buf[b + 14] = c.b
		_du_buf[b + 15] = 0.0
		_live = maxf(_live, _du_life[k])
	_show()


## Scraping along something fixed at `speed` m/s (car.gd, a few times a second): two or three
## sparks from the contact, thrown back along the wall.
func scrape(at: Vector3, normal: Vector3, car_vel: Vector3, speed: float, ground_y: float) -> void:
	if speed < 6.0:
		return
	_anchor(at)
	var n := _flat(normal)
	var along := car_vel - n * car_vel.dot(n)
	along.y = 0.0
	for i in 2 + int(speed > 14.0):
		_spark(at, n * 0.4, along, 0.55, ground_y)
	_show()


func _spark(at: Vector3, n: Vector3, along: Vector3, power: float, ground_y: float) -> void:
	var k := _sp_next
	_sp_next = (_sp_next + 1) % SPARKS
	var spread := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
	_sp_pos[k] = at + Vector3(0.0, _rng.randf_range(-0.1, 0.2), 0.0)
	_sp_vel[k] = (n * _rng.randf_range(2.0, 6.0) + spread * 3.5 + Vector3.UP * _rng.randf_range(3.0, 7.0)) * power \
			+ along * _rng.randf_range(0.25, 0.75)
	_sp_age[k] = 0.0
	_sp_life[k] = _rng.randf_range(0.35, 0.75)
	_sp_floor[k] = ground_y + 0.05
	_live = maxf(_live, _sp_life[k])
	sparks_thrown += 1


## Moves the pool's origin to the newest hit, carrying the live particles' world positions
## (they are kept in world space; only the drawing is relative to the node).
func _anchor(at: Vector3) -> void:
	global_position = Vector3(at.x, at.y, at.z)


func _flat(normal: Vector3) -> Vector3:
	var n := Vector3(normal.x, 0.0, normal.z)
	return n.normalized() if n.length() > 0.01 else Vector3.BACK


func _show() -> void:
	if not _sparks.visible:
		_sparks.visible = true
		_dust.visible = true
	set_process(true)


func _hide() -> void:
	_sparks.visible = false
	_dust.visible = false
	set_process(false)


func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	_live -= dt
	if _live <= 0.0:
		_hide()
		return
	var origin := global_position
	for k in SPARKS:
		var b := k * 16
		if _sp_age[k] >= _sp_life[k]:
			_zero(_sp_buf, b)
			continue
		_sp_age[k] += dt
		var v := _sp_vel[k]
		v.y -= GRAVITY * dt
		var p := _sp_pos[k] + v * dt
		if p.y < _sp_floor[k]:
			# One bounce off the road, most of the energy gone.
			p.y = _sp_floor[k]
			v = Vector3(v.x * 0.55, absf(v.y) * 0.3, v.z * 0.55)
		_sp_pos[k] = p
		_sp_vel[k] = v
		var fade := 1.0 - _sp_age[k] / _sp_life[k]
		if fade <= 0.0 or (p - origin).length() > REACH:
			_zero(_sp_buf, b)
			continue
		var speed := v.length()
		# Sized for the game's camera (a game pixel is ~0.15-0.3 m): a spark is 1-2 pixels thick.
		var w := SPARK_W * (0.5 + 0.5 * fade)
		var l := clampf(speed * 0.12, 0.4, 1.6) * (0.4 + 0.6 * fade)
		_streak(_sp_buf, b, p - origin, v / maxf(speed, 0.001), w, l)
	for k in DUST:
		var b := k * 16
		if _du_age[k] >= _du_life[k]:
			_zero(_du_buf, b)
			continue
		_du_age[k] += dt
		var t := _du_age[k] / _du_life[k]
		var v := _du_vel[k] * exp(-2.2 * dt)
		v.y -= 0.6 * dt
		_du_vel[k] = v
		_du_pos[k] += v * dt
		# Grows quickly, then shrinks away over its last 40 %.
		var size := _du_size[k] * (0.55 + 0.9 * (1.0 - exp(-5.0 * t))) * clampf((1.0 - t) / 0.4, 0.0, 1.0)
		var p := _du_pos[k] - origin
		_box(_du_buf, b, p, size, float(k) * 1.3 + t * 0.8)
	InstanceBuffers.send(_sparks.multimesh.get_rid(), _sp_buf)
	InstanceBuffers.send(_dust.multimesh.get_rid(), _du_buf)


func _zero(buf: PackedFloat32Array, b: int) -> void:
	for j in 12:
		buf[b + j] = 0.0


## A streak at `p` along unit `d`, `w` thick and `l` long.
func _streak(buf: PackedFloat32Array, b: int, p: Vector3, d: Vector3, w: float, l: float) -> void:
	var side := d.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.01 else Vector3.RIGHT
	var up := side.cross(d)
	var x := side * w
	var y := up * w
	var z := d * l
	buf[b] = x.x
	buf[b + 1] = y.x
	buf[b + 2] = z.x
	buf[b + 3] = p.x
	buf[b + 4] = x.y
	buf[b + 5] = y.y
	buf[b + 6] = z.y
	buf[b + 7] = p.y
	buf[b + 8] = x.z
	buf[b + 9] = y.z
	buf[b + 10] = z.z
	buf[b + 11] = p.z


## A cube `s` on a side at `p`, turned `yaw` about the vertical.
func _box(buf: PackedFloat32Array, b: int, p: Vector3, s: float, yaw: float) -> void:
	var c := cos(yaw) * s
	var n := sin(yaw) * s
	buf[b] = c
	buf[b + 1] = 0.0
	buf[b + 2] = n
	buf[b + 3] = p.x
	buf[b + 4] = 0.0
	buf[b + 5] = s * 0.8
	buf[b + 6] = 0.0
	buf[b + 7] = p.y
	buf[b + 8] = -n
	buf[b + 9] = 0.0
	buf[b + 10] = c
	buf[b + 11] = p.z
