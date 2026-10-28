## Loop 2a: the car as it was before loop 2a (v0.9 / loop 1), kept only so
## tools/check_steering.gd can print before/after numbers (--legacy). Not in the export.
extends CharacterBody3D
## Arcade car: forward speed from throttle and brake, steering that needs
## speed, and lateral grip that lets the tail slide when braking hard.
## It can flash its headlights (the street-race challenge). When the city's
## lights are on (`lights`, set by the game), its head and tail lamps glow, a
## spotlight lights the road and the walls ahead, and soft cones lie on the road.

const Models := preload("res://scripts/models.gd")

## Hit something hard enough to notice, at `speed` m/s closing speed (traffic stops
## the car it was hit by; the słoiki run breaks jars).
signal bumped(collider: Object, speed: float)
## A hit worth a sound (v0.9, sfx.gd): fired where the haptics are, once per knock.
signal impact(collider: Object, speed: float)

@export var max_speed := 30.0        # m/s, about 108 km/h
@export var accel := 15.0
@export var brake_decel := 30.0
@export var reverse_speed := 7.0
@export var turn_rate := 2.6         # rad/s at full lock
@export var grip := 9.0
@export var drift_grip := 1.6

## Inputs, set every frame by the game. steer > 0 turns left.
var throttle := 0.0
var steer := 0.0
var braking := false
## Point-to-steer: when not zero, the car turns towards this world direction.
var target_dir := Vector3.ZERO

## Height of the road surface under a point for a car at height y; set by the game
## (terrain and bridge decks: a deck overhead is not the road).
var ground_height: Callable = func(_x: float, _z: float, _y: float) -> float: return 0.0
var vel := Vector3.ZERO
var forward_speed := 0.0
## Sideways speed in m/s; high when the tail slides (skid marks, the tyres' squeal).
var slip := 0.0
## 0..1, how wet the road is (weather.gd): a little less grip and braking in the rain.
var wet := 0.0
var _bump_cooldown := 0.0
var _sound_cooldown := 0.0
var _body: Node3D
var _headlights: Array[StandardMaterial3D] = []
var _tails: Array[StandardMaterial3D] = []
var _beams: Node3D
var _night_beams: MeshInstance3D
var _spot: SpotLight3D
var _flash := 0.0
## 0..1, how far the city's lights are on (time_of_day.gd); the game sets it every frame.
var lights := 0.0:
	set(value):
		var changed := (value > 0.001) != (lights > 0.001)
		lights = value
		if changed and is_node_ready():
			_apply_lights()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 4.0)
	shape.shape = box
	shape.position.y = 0.8
	add_child(shape)
	_body = _make_body()
	add_child(_body)
	_beams = _make_beams()
	_body.add_child(_beams)
	_night_beams = MeshInstance3D.new()
	_night_beams.mesh = Models.headlight_pools(2.05, 0.58, 15.0)
	_night_beams.material_override = Models.glow_material()
	_night_beams.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_night_beams)
	# One real light, the player's own: it catches walls, cars and trees ahead.
	_spot = SpotLight3D.new()
	_spot.light_color = Color("#ffe6b8")
	_spot.light_energy = 3.0
	_spot.spot_range = 34.0
	_spot.spot_angle = 34.0
	_spot.spot_attenuation = 0.8
	_spot.shadow_enabled = false
	_spot.position = Vector3(0, 1.0, -2.2)
	_spot.rotation.x = deg_to_rad(-14.0)
	_body.add_child(_spot)
	_apply_lights()


## Lamps, cones and the spotlight follow the city's lights.
func _apply_lights() -> void:
	var night := lights > 0.001
	# Emission stays enabled and only its energy changes, so no shader variant has
	# to compile when the lamps come on.
	for m in _headlights:
		m.emission_energy_multiplier = 4.0 if night or _beams.visible else 0.0
	for m in _tails:
		m.emission_energy_multiplier = 3.0 if night else 0.0
	_night_beams.visible = night
	_spot.visible = night


## Two quick flashes of the headlights.
func flash_lights() -> void:
	_flash = 0.55


func _process(dt: float) -> void:
	if _flash <= 0.0 and not _beams.visible:
		return
	_flash -= dt
	var on := _flash > 0.0 and (_flash > 0.38 or _flash < 0.2)
	_beams.visible = on
	for m in _headlights:
		m.emission_energy_multiplier = 4.0 if on or lights > 0.001 else 0.0


func _physics_process(dt: float) -> void:
	var fwd := _forward()
	var speed := vel.dot(fwd)

	var s := steer
	if target_dir != Vector3.ZERO:
		var want := target_dir
		if speed < -0.5:
			want = -want
		s = clampf(fwd.signed_angle_to(want, Vector3.UP) * 2.2, -1.0, 1.0)
	var authority := clampf(absf(speed) / 5.0, 0.0, 1.0) * (1.0 - 0.35 * clampf(absf(speed) / max_speed, 0.0, 1.0))
	rotate_y(s * turn_rate * authority * (1.0 if speed >= 0.0 else -1.0) * dt)

	fwd = _forward()
	speed = vel.dot(fwd)
	var lateral := vel - fwd * speed
	slip = lateral.length()

	if braking:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, brake_decel * (1.0 - 0.15 * wet) * dt)
		else:
			speed = move_toward(speed, -reverse_speed, accel * 0.6 * dt)
	elif throttle > 0.0:
		speed += accel * throttle * dt * (1.0 - 0.6 * clampf(speed / max_speed, 0.0, 1.0))
	else:
		speed = move_toward(speed, 0.0, 5.0 * dt)
	speed = minf(speed, max_speed)

	# Wet roads: the tail lets go a little sooner and slides a little longer.
	var g := (drift_grip if braking and speed > 10.0 else grip) * (1.0 - 0.22 * wet)
	lateral *= exp(-g * dt)
	vel = fwd * speed + lateral

	velocity = vel
	move_and_slide()
	if get_slide_collision_count() > 0:
		var lost := (vel - velocity).length()
		# Also the closing speed along the contact normal: moving bodies (traffic) push
		# the car out rather than stop it, so the speed lost alone misses those hits.
		var hit := get_slide_collision(0)
		lost = maxf(lost, -vel.dot(hit.get_normal()))
		if lost > 2.0:
			bumped.emit(hit.get_collider(), lost)
		vel = velocity * 0.92
		_bump_cooldown -= dt
		_sound_cooldown -= dt
		if lost > 2.5 and _sound_cooldown <= 0.0:
			impact.emit(hit.get_collider(), lost)
			_sound_cooldown = 0.35
		if lost > 4.0 and _bump_cooldown <= 0.0:
			# A short buzz on the phone for a real hit, not for scraping along a wall.
			Input.vibrate_handheld(clampi(int(lost * 6.0), 25, 90), clampf(lost / 15.0, 0.3, 1.0))
			_bump_cooldown = 0.35
	else:
		vel = velocity
		_bump_cooldown = 0.0
		_sound_cooldown = 0.0
	vel.y = 0.0
	global_position.y = ground_height.call(global_position.x, global_position.z, global_position.y)
	forward_speed = vel.dot(_forward())

	# Lean into turns and squat under braking, just for the look.
	var lean := clampf(lateral.dot(global_transform.basis.x) * 0.012, -0.08, 0.08)
	_body.rotation.z = lerpf(_body.rotation.z, lean, 1.0 - exp(-10.0 * dt))
	var pitch := 0.03 if braking and speed > 1.0 else (-0.02 if throttle > 0.0 else 0.0)
	_body.rotation.x = lerpf(_body.rotation.x, pitch, 1.0 - exp(-8.0 * dt))


func _forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()


func _make_body() -> Node3D:
	# A small retro hatchback with twin racing stripes, built from boxes so it
	# reads clearly at pixel scale. The front is -Z.
	var root := Node3D.new()
	var paint := Color("#d8432f")
	var stripe := Color("#f4efe4")
	var glass := Color("#2f3f52")
	var trim := Color("#3a3b3f")
	_box(root, Vector3(1.8, 0.55, 4.0), Vector3(0, 0.6, 0), paint)               # body
	_box(root, Vector3(1.74, 0.14, 1.05), Vector3(0, 0.93, -1.45), paint)        # bonnet
	_box(root, Vector3(1.6, 0.52, 2.15), Vector3(0, 1.12, 0.25), glass)          # cabin glass
	_box(root, Vector3(1.64, 0.09, 1.95), Vector3(0, 1.42, 0.3), paint)          # roof
	for x in [-0.22, 0.22]:
		_box(root, Vector3(0.18, 0.02, 1.06), Vector3(x, 1.01, -1.45), stripe)  # bonnet stripes
		_box(root, Vector3(0.18, 0.02, 1.96), Vector3(x, 1.475, 0.3), stripe)   # roof stripes
	for z in [-2.03, 2.03]:
		_box(root, Vector3(1.84, 0.18, 0.12), Vector3(0, 0.38, z), trim)        # bumpers
	for x in [-0.86, 0.86]:
		for z in [-1.25, 1.3]:
			_box(root, Vector3(0.32, 0.62, 0.66), Vector3(x, 0.31, z), Color("#1f1f21"))
	for x in [-0.58, 0.58]:
		var lamp := _box(root, Vector3(0.34, 0.16, 0.06), Vector3(x, 0.72, -2.01), Color("#fff3c4"))
		lamp.emission_enabled = true
		lamp.emission = Color("#fff8dc")
		lamp.emission_energy_multiplier = 0.0
		_headlights.append(lamp)
		var tail := _box(root, Vector3(0.34, 0.14, 0.06), Vector3(x, 0.74, 2.01), Color("#b3241f"))
		tail.emission_enabled = true
		tail.emission = Color("#ff2a1c")
		tail.emission_energy_multiplier = 0.0
		_tails.append(tail)
	return root


## Light thrown on the road ahead while flashing: two pale fans, drawn after the
## post-process pass (see heli.gd) like every see-through surface.
func _make_beams() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-0.58, 0.58]:
		var tip := Vector3(x, 0.12, -2.1)
		st.set_color(Color(1, 0.97, 0.8, 0.75))
		st.add_vertex(tip)
		st.set_color(Color(1, 0.97, 0.8, 0.0))
		st.add_vertex(Vector3(x + 1.3, 0.12, -9.5))
		st.set_color(Color(1, 0.97, 0.8, 0.0))
		st.add_vertex(Vector3(x - 1.3, 0.12, -9.5))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	mat.render_priority = 1
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	root.visible = false
	return root


func _box(parent: Node3D, size: Vector3, pos: Vector3, colour: Color) -> StandardMaterial3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.8
	mesh.material = mat
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mat
