extends CharacterBody3D
## Arcade car: forward speed from throttle and brake, steering that needs a little
## speed, and lateral grip that lets the tail slide when braking hard.
## It can flash its headlights (the street-race challenge). When the city's
## lights are on (`lights`, set by the game), its head and tail lamps glow, a
## spotlight lights the road and the walls ahead, and soft cones lie on the road.
##
## Loop 2a (the feel on a phone, measured by tools/check_steering.gd): the most it turns
## depends on speed (sharp when slow, calm when fast: full-lock radius ~2.5 m at 20 km/h,
## ~8.5 m at 50, ~23 m at 90; it was 2.3 / 6.4 / 11.5 m, a 4 g swerve at speed); it pivots
## a little from a standstill with the gas on; the steering is smoothed over 0.08 s;
## point-to-steer (target_dir) turns at a rate set by the heading error with a touch of
## yaw damping, so it settles on the direction without overshooting, and pointing well
## behind at speed brakes first and then turns; a big turn holds the speed (off the gas)
## until it is done; pointing into a wall it is touching, it follows the wall instead. The gas sets a target speed (a light push cruises slowly). Walls: the car keeps what slides along them (was 8 % lost every
## frame of contact), a glancing hit turns it along the wall, a head-on one pushes it back a
## little, and if it is pinned (touching something fixed, getting nowhere, with the gas or
## brake on) for 1.5 s it is turned out of the wall; pinned again soon after, `stuck` asks
## the game to put it on a free spot. Queued against a traffic car is not pinned (until the
## driving-feel loop's CAR_PUSH_TIME, below).
##
## The driving-feel loop (2026-10-30, "the car sticks to everything"): a front corner that
## clips something small (a post, a bench, a parked or traffic car's corner) slips the car
## sideways past it with most of its speed (`_corner_slip`) instead of stopping it dead; held
## against a car or tram for CAR_PUSH_TIME with the gas on, it steers round it like a wall (and
## is turned out after UNSTICK_TIME, never sent to a free spot for it); a kerb takes 3 % of the
## speed (was 8 %) once per KERB_GAP however many kerb lines it crosses (an island is two), and
## the raised ground drags at 0.25/s (was 0.6).
##
## Loop 10a: in the water (the river, a pond: `water_at`, the map's test) it splashes once
## (`splashed`), takes no gas or steering, slows hard and settles a little, bobbing, until the
## game tows it out (`leave_water`).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const Models := preload("res://scripts/models.gd")

## Hit something hard enough to notice, at `speed` m/s closing speed (traffic stops
## the car it was hit by; the słoiki run breaks jars).
signal bumped(collider: Object, speed: float)
## A hit worth a sound (v0.9, sfx.gd): fired where the haptics are, once per knock.
signal impact(collider: Object, speed: float)
## Loop 2a: pinned twice within a few seconds; the game moves the car to a free spot.
signal stuck
## Loop 10a: rolled into the water, at `speed` m/s (once; the game splashes and tows it out).
signal splashed(speed: float)

@export var max_speed := 30.0        # m/s, about 108 km/h
@export var accel := 15.0
@export var brake_decel := 30.0
@export var reverse_speed := 7.0
@export var grip := 9.0
@export var drift_grip := 1.6
## Steering (loop 2a): the most the car turns (rad/s) is turn_cap when slow and
## turn_pull / speed + turn_floor at speed (turn_pull is the sideways pull, m/s²).
@export var turn_cap := 2.3
@export var turn_pull := 18.0
@export var turn_floor := 0.35
## Turning from a standstill with the gas fully on (rad/s); it needs ~2 m/s for full lock.
@export var pivot := 1.5
## Steering input smoothing (s).
@export var steer_time := 0.08
## Point-to-steer: heading error (rad) to yaw rate (rad/s), and the yaw damping.
@export var point_gain := 6.0
@export var yaw_damping := 0.4
## Pointing more than this far off the nose at more than BRAKE_TURN_SPEED: brake first.
const BRAKE_TURN_ANGLE := deg_to_rad(110.0)
const BRAKE_TURN_SPEED := 5.0
## Pointing more than this far off the nose: hold the speed (above a crawl) until it has turned.
const TURN_HOLD_ANGLE := deg_to_rad(30.0)
const TURN_CRAWL := 6.0
## Walls: scraping friction (1/s), how fast a glancing hit turns the car along the wall
## (rad/s), the push back off a head-on hit (share of the speed lost, at most 1.2 m/s),
## and how long it may sit pinned before it is turned out (s).
const SCRAPE := 1.2
const WALL_TURN := 3.0
const WALL_PUSH := 0.12
const UNSTICK_TIME := 1.5
## The driving-feel loop: corner slip. A touch this near a front corner (m in from the side)
## sidesteps the car past the thing it clipped at up to SLIP_RATE m/s, keeping SLIP_KEEP of
## its speed; the bump it reports is SLIP_HIT of a full one (traffic, jars, ride stars).
const SLIP_REACH := 0.6
const SLIP_RATE := 7.0
const SLIP_KEEP := 0.96
const SLIP_HIT := 0.35
## Pushing into a car or a tram (not fixed) this long with the gas on and going nowhere: steer
## round it as round a wall.
const CAR_PUSH_TIME := 0.35
## Loop 10a: in the water it loses speed at this rate (1/s: from 91 km/h it stops within
## ~6 m) and settles this far (m) into it.
const WATER_DRAG := 4.0
const SINK := 0.45
## Loop 3b-2: kerbs you feel. Hopping a kerb keeps KERB_JOLT of the speed and bounces the body
## KERB_BOUNCE m; rolling over an island or a grass median loses KERB_DRAG of the speed per
## second (map_builder.kerb_feel says where; drive_height lifts the car onto them).
const KERB_JOLT := 0.97
const KERB_BOUNCE := 0.07
const KERB_DRAG := 0.25
## The driving-feel loop: kerbs crossed within this long of the last jolt (s) are felt as one.
const KERB_GAP := 0.5
## The look loop (2026-10-28): how strongly the paint and the roof and bonnet stripes light
## from within at night (actor.gdshader's hero part; share of their own colour), so the
## car reads at least 30 luma over the road under it (it was 20-50 darker).
const HERO_PAINT := 1.4
const HERO_STRIPE := 0.3

## Inputs, set every frame by the game. steer > 0 turns left. throttle 0..1 is the
## share of top speed to drive at (1: flat out).
var throttle := 0.0
var steer := 0.0
var braking := false
## Loop 2b: the game has parked the car (the title screen, the player flying): it holds
## still on the brake (a held brake at a standstill would reverse it into whatever is
## behind) and never counts as pinned. A player holding BRAKE to reverse is not parked.
var parked := false
## Point-to-steer: when not zero, the car turns towards this world direction.
var target_dir := Vector3.ZERO
## What the car does this step (loop 2a): the brakes are on (the button, or pointing well
## behind at speed: skids and the tyres' squeal read this), the smoothed steering, and
## the yaw rate (rad/s, + is left).
var brakes_on := false
var steer_now := 0.0
var yaw_rate := 0.0
## How many times it has been turned out of a wall (check_steering.gd counts them).
var unsticks := 0
## Loop 10a: whether a car at (x, z, height) is in the water (the game sets map.in_water). A
## car with its collision off (the testing autopilots glide through walls) or parked never
## splashes.
var water_at: Callable = func(_x: float, _z: float, _y: float) -> bool: return false
## Loop 3b-2: what the ground does to the car on its way from one spot to the next (the game sets
## map.kerb_feel): x the raise under the new spot (an island, a median), y 1 if it crossed a kerb.
var kerb_feel: Callable = func(_from: Vector2, _to: Vector2, _y: float) -> Vector2: return Vector2.ZERO
var _last_xz := Vector2.INF
var _bounce := 0.0
## Loop 10a: in the water, waiting for the tow; how long it has been in.
var in_water := false
var _sink := 0.0

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
var _turn_side := 0.0
var _contact := 0.0
## Seconds left of the last touch of something fixed (a wall, a kiosk, a parked car), not a
## moving car or tram: only those can pin the car (a queue at a red light is not "stuck").
var _fixed_contact := 0.0
var _wall_normal := Vector3.ZERO
## The walls touched since the car was last pinned somewhere new (a corner's two walls).
var _wall_normals := PackedVector3Array()
## Which way along a wall it follows when pointed straight into it (+1 / -1; 0: not chosen).
var _wall_side := 0.0
## The driving-feel loop: how long it has pushed into a car or tram going nowhere (s).
var _car_push := 0.0
## The driving-feel loop: seconds since the last kerb jolt.
var _kerb_wait := KERB_GAP
var _pinned := 0.0
var _pin_at := Vector2.ZERO
var _last_unstick := -100.0
var _clock := 0.0
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
	# The look loop: the player's cone a little stronger and longer than traffic's.
	_night_beams.mesh = Models.headlight_pools(2.05, 0.58, 17.0, true, 0.52)
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
	var t0 := Time.get_ticks_usec()
	_step(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _step(dt: float) -> void:
	_clock += dt
	if in_water:
		_float(dt)
		return
	var fwd := _forward()
	var speed := vel.dot(fwd)
	var gas := clampf(throttle, 0.0, 1.0)
	# The speed the gas asks for (a share of top speed); a big point-to-steer turn caps it.
	var top := max_speed * gas
	var brake_now := braking
	var turn := max_turn(absf(speed), gas)
	# Moving backwards the car turns the other way for the same steering.
	var backwards := -1.0 if speed < -0.3 else 1.0

	var s := steer
	if target_dir != Vector3.ZERO:
		var want := target_dir
		# Reversing (the brake held at a standstill or going back): the tail goes where you point.
		if braking and speed < 0.5:
			want = -want
		# Touching a wall and pointing into it: follow the wall the way the stick leans
		# (straight into it: the way the nose leans) instead of pushing against it. A car or
		# tram only once the car has pushed into it for CAR_PUSH_TIME (a touch in a queue
		# doesn't send it round; holding the gas against one does).
		if _contact > 0.0 and (_fixed_contact > 0.0 or _car_push > CAR_PUSH_TIME) and _wall_normal != Vector3.ZERO:
			var into_wall := want.dot(_wall_normal)
			if into_wall < -0.05:
				var along := want - _wall_normal * into_wall
				if along.length() < 0.25:
					# Picked once per touch: nose-on, the choice would flip every frame.
					var t := _wall_normal.cross(Vector3.UP)
					if _wall_side == 0.0:
						_wall_side = 1.0 if t.dot(fwd * backwards) >= 0.0 else -1.0
					along = t * _wall_side
				want = along.normalized()
		var err := fwd.signed_angle_to(want, Vector3.UP)
		# Pointing straight back: keep turning the way it started, never flip-flop at ±180°.
		if absf(err) > 2.8 and _turn_side != 0.0 and signf(err) != _turn_side:
			err = _turn_side * (TAU - absf(err))
		if absf(err) > 0.2:
			_turn_side = signf(err)
		# A yaw rate from the error, damped by the rate it already turns at: it settles
		# on the direction without swinging past it.
		var rate := err * point_gain - yaw_rate * yaw_damping
		s = clampf(rate / maxf(turn, 0.05), -1.0, 1.0) * backwards
		if not braking:
			var off := absf(err)
			if off > BRAKE_TURN_ANGLE and speed > BRAKE_TURN_SPEED:
				# Well behind at speed: brake first (the tail may slide round), then turn.
				brake_now = true
				gas = 0.0
			elif off > TURN_HOLD_ANGLE and gas > 0.0:
				# A big turn: no faster than now (off the gas), so the turn stays tight;
				# from a crawl it still pulls away briskly.
				top = minf(top, maxf(speed, TURN_CRAWL))
	else:
		_turn_side = 0.0
	steer_now = lerpf(steer_now, clampf(s, -1.0, 1.0), 1.0 - exp(-dt / steer_time))
	var yaw := steer_now * max_turn(absf(speed), maxf(gas, throttle)) * backwards
	rotate_y(yaw * dt)
	yaw_rate = yaw

	fwd = _forward()
	speed = vel.dot(fwd)
	var lateral := vel - fwd * speed
	slip = lateral.length()

	if brake_now:
		if speed > 0.5:
			speed = move_toward(speed, 0.0, brake_decel * (1.0 - 0.15 * wet) * dt)
		elif parked:
			speed = move_toward(speed, 0.0, brake_decel * dt)
		else:
			speed = move_toward(speed, -reverse_speed, accel * 0.6 * dt)
	elif gas > 0.0:
		# The gas sets a speed to drive at; a light push accelerates gently.
		if speed < top:
			speed = minf(top, speed + accel * (0.35 + 0.65 * gas) * dt * (1.0 - 0.6 * clampf(speed / max_speed, 0.0, 1.0)))
		else:
			speed = move_toward(speed, top, 4.0 * dt)
	else:
		speed = move_toward(speed, 0.0, 5.0 * dt)
	speed = minf(speed, max_speed)
	brakes_on = brake_now

	# Wet roads: the tail lets go a little sooner and slides a little longer.
	var g := (drift_grip if brake_now and speed > 10.0 else grip) * (1.0 - 0.22 * wet)
	lateral *= exp(-g * dt)
	vel = fwd * speed + lateral

	velocity = vel
	move_and_slide()
	var hits := get_slide_collision_count()
	var slipped := hits > 0 and _corner_slip(speed, dt)
	if hits > 0:
		var lost := (vel - velocity).length()
		# Also the closing speed along the contact normal: moving bodies (traffic) push
		# the car out rather than stop it, so the speed lost alone misses those hits.
		var hit := get_slide_collision(0)
		lost = maxf(lost, -vel.dot(hit.get_normal()))
		if slipped:
			# A clipped corner is a knock, felt once (it slips past over a few frames).
			lost = lost * SLIP_HIT if _contact <= 0.0 else 0.0
		if lost > 2.0:
			bumped.emit(hit.get_collider(), lost)
		_bump_cooldown -= dt
		_sound_cooldown -= dt
		if lost > 2.5 and _sound_cooldown <= 0.0:
			impact.emit(hit.get_collider(), lost)
			_sound_cooldown = 0.35
		if lost > 4.0 and _bump_cooldown <= 0.0:
			# A short buzz on the phone for a real hit, not for scraping along a wall.
			Input.vibrate_handheld(clampi(int(lost * 6.0), 25, 90), clampf(lost / 15.0, 0.3, 1.0))
			_bump_cooldown = 0.35
		var n := Vector3.ZERO
		var slid := vel
		var fixed := false
		for k in hits:
			if get_slide_collision(k).get_collider() is StaticBody3D:
				_fixed_contact = 0.25
				fixed = true
			var nk := get_slide_collision(k).get_normal()
			nk.y = 0.0
			n += nk
			# move_and_slide (floating) slides the motion but leaves the velocity pointing into
			# the wall: take the part going into each contact out of it.
			if nk.length() > 0.01:
				nk = nk.normalized()
				var known := false
				for w in _wall_normals:
					known = known or w.dot(nk) > 0.9
				if not known and _wall_normals.size() < 6:
					_wall_normals.append(nk)
				var into_k := slid.dot(nk)
				if into_k < 0.0:
					slid -= nk * into_k
		var first := _contact <= 0.0
		if n.length() > 0.01:
			n = n.normalized()
			_wall_normal = n
		# Against a car or a tram (nothing fixed), trying to go on and getting nowhere.
		if not fixed and not parked and (gas > 0.1 or target_dir != Vector3.ZERO) and absf(speed) < 2.0:
			_car_push += dt
		elif fixed:
			_car_push = 0.0
		# What slides along the wall is kept, less a little scrape (loop 2a; it lost 8 % a frame).
		vel = slid * exp(-SCRAPE * dt)
		if slipped:
			# Slipping past a clipped corner: it keeps its speed (the next frames carry it past).
			vel = fwd * speed * (SLIP_KEEP if first else 1.0) + lateral
			n = Vector3.ZERO
			_wall_normal = Vector3.ZERO
		if n != Vector3.ZERO:
			var f := _forward()
			var into := -f.dot(n)
			var along := f - n * f.dot(n)
			if into > 0.05 and into < 0.9 and along.length() > 0.05 and speed > 0.0:
				# A glancing hit: turn the nose along the wall so it slides on.
				var a := f.signed_angle_to(along.normalized(), Vector3.UP)
				rotate_y(clampf(a, -WALL_TURN * dt, WALL_TURN * dt))
			if first and lost > 1.0:
				# A small push back off the wall (out of corners too).
				vel += n * minf(lost * WALL_PUSH, 1.2)
		_contact = 0.25
	else:
		vel = velocity
		_bump_cooldown = 0.0
		_sound_cooldown = 0.0
		_contact -= dt
		if _contact <= 0.0:
			_wall_side = 0.0
			_car_push = 0.0
	vel.y = 0.0
	global_position.y = ground_height.call(global_position.x, global_position.z, global_position.y)
	_feel_kerbs(dt)
	forward_speed = vel.dot(_forward())
	_fixed_contact -= dt
	if not parked and collision_mask != 0 and water_at.call(global_position.x, global_position.z, global_position.y):
		in_water = true
		_sink = 0.0
		_pinned = 0.0
		splashed.emit(vel.length())
		return

	# Pinned: touching something fixed with the gas or the brake on, and getting nowhere (under
	# a metre from where it was pinned, however much it jiggles between a wall and a car).
	# Nosing into the car ahead in a queue doesn't count: traffic moves on by itself. A car
	# the game has parked (loop 2b) is never "trying".
	var trying := not parked and (gas > 0.1 or brake_now or target_dir != Vector3.ZERO)
	var here := Vector2(global_position.x, global_position.z)
	if _contact > 0.0 and (_fixed_contact > 0.0 or _car_push > CAR_PUSH_TIME) and trying:
		if _pinned <= 0.0 or here.distance_to(_pin_at) > 1.0:
			_pin_at = here
			_pinned = dt
			_wall_normals.clear()
			if _wall_normal != Vector3.ZERO:
				_wall_normals.append(_wall_normal)
		else:
			_pinned += dt
		if _pinned >= UNSTICK_TIME:
			_unstick()
	else:
		_pinned = 0.0
		if _contact <= 0.0:
			_wall_normals.clear()

	# Lean into turns and squat under braking, just for the look.
	var lean := clampf(lateral.dot(global_transform.basis.x) * 0.012, -0.08, 0.08)
	_body.rotation.z = lerpf(_body.rotation.z, lean, 1.0 - exp(-10.0 * dt))
	var pitch := 0.03 if brake_now and speed > 1.0 else (-0.02 if gas > 0.0 else 0.0)
	_body.rotation.x = lerpf(_body.rotation.x, pitch, 1.0 - exp(-8.0 * dt))


## Loop 3b-2: a kerb hopped takes a little speed and bounces the body; an island or a median
## under the car drags like rough ground. Not for a car with its collision off (the testing
## autopilots) or parked.
func _feel_kerbs(dt: float) -> void:
	var here := Vector2(global_position.x, global_position.z)
	_kerb_wait += dt
	# (A jump of more than 5 m is a tow or a landing, not a drive.)
	if collision_mask != 0 and not parked and _last_xz != Vector2.INF and here != _last_xz and here.distance_to(_last_xz) < 5.0:
		var feel: Vector2 = kerb_feel.call(_last_xz, here, global_position.y)
		if feel.y > 0.0 and vel.length() > 1.5 and _kerb_wait >= KERB_GAP:
			vel *= KERB_JOLT
			_bounce = KERB_BOUNCE
			_kerb_wait = 0.0
		if feel.x > 0.0:
			vel *= exp(-KERB_DRAG * dt)
	_last_xz = here
	if _bounce > 0.0 or _body.position.y != 0.0:
		_bounce = maxf(_bounce - dt * 0.6, 0.0)
		_body.position.y = _bounce


## Loop 10a: in the water: no engine, no grip, no steering; it glides to a stop, settles
## SINK metres nose first and bobs.
func _float(dt: float) -> void:
	vel *= exp(-WATER_DRAG * dt)
	vel.y = 0.0
	velocity = vel
	move_and_slide()
	vel = Vector3(velocity.x, 0.0, velocity.z)
	global_position.y = ground_height.call(global_position.x, global_position.z, global_position.y)
	forward_speed = vel.dot(_forward())
	slip = 0.0
	brakes_on = false
	steer_now = 0.0
	yaw_rate = 0.0
	_sink += dt
	var settle := SINK * (1.0 - exp(-5.0 * _sink))
	_body.position.y = -settle + sin(_sink * 7.0) * 0.04 * minf(_sink * 2.0, 1.0)
	_body.rotation.x = lerpf(_body.rotation.x, -0.09, 1.0 - exp(-6.0 * dt))
	_body.rotation.z = lerpf(_body.rotation.z, sin(_sink * 4.5) * 0.03, 1.0 - exp(-6.0 * dt))


## Loop 10a: the tow has put the car back on dry land (the game moves it first).
func leave_water() -> void:
	in_water = false
	_sink = 0.0
	_body.position.y = 0.0
	_bounce = 0.0
	_last_xz = Vector2.INF
	_body.rotation = Vector3.ZERO
	vel = Vector3.ZERO
	forward_speed = 0.0
	steer_now = 0.0
	_pinned = 0.0
	_contact = 0.0
	_fixed_contact = 0.0
	_wall_normals.clear()
	_car_push = 0.0


## The most the car turns (rad/s) at `v` m/s: turn_cap when slow, turn_pull / v + turn_floor
## at speed; under 2 m/s it fades out, except for a little pivot with the gas on.
func max_turn(v: float, gas := 0.0) -> float:
	var w := minf(turn_cap, turn_pull / maxf(v, 0.1) + turn_floor)
	var roll := clampf(v / 2.0, 0.0, 1.0)
	return maxf(w * roll, pivot * gas * (1.0 - roll))


## Pinned against a wall: turn the car out of it (towards where the player wants to go,
## or along the wall), step it 0.5 m off and send it off at walking pace. Pinned again
## within 5 s, ask the game for a free spot (`stuck`).
func _unstick() -> void:
	_pinned = 0.0
	unsticks += 1
	# Out of everything touched while pinned (both walls of a corner).
	var n := Vector3.ZERO
	for w in _wall_normals:
		n += w
	n = n.normalized() if n.length() > 0.1 else (_wall_normal if _wall_normal != Vector3.ZERO else -_forward())
	# The way it moves: forwards, or backwards while reversing (the tail goes where you point).
	var reverse := braking and forward_speed < 0.5
	var moving := _forward() * (-1.0 if reverse else 1.0)
	var want := target_dir if target_dir != Vector3.ZERO else moving
	var t := n.cross(Vector3.UP).normalized()
	var best := n
	var best_score := -INF
	for c: Vector3 in [n, (n + t).normalized(), (n - t).normalized(), t, -t]:
		# Only ways out: none may lead into a wall it is touching (in a corner, along one
		# wall is into the other).
		var blocked := false
		for w in _wall_normals:
			if c.dot(w) < -0.1:
				blocked = true
		if blocked:
			continue
		var score := c.dot(want) + 0.1 * c.dot(moving)
		if score > best_score:
			best_score = score
			best = c
	global_position += n * 0.5
	var face := -best if reverse else best
	rotation.y = atan2(-face.x, -face.z)
	vel = best * 3.0
	forward_speed = vel.dot(_forward())
	steer_now = 0.0
	print("car: pinned %.1f s, turned out of the wall at %.0f, %.0f (heading %03.0f°)" % [UNSTICK_TIME,
			global_position.x, global_position.z, fposmod(rad_to_deg(atan2(face.x, -face.z)), 360.0)])
	# Turned out from between cars (nothing fixed): never sent to a free spot for it.
	if _fixed_contact <= 0.0:
		return
	if _clock - _last_unstick < 5.0:
		stuck.emit()
	_last_unstick = _clock


## The driving-feel loop: every touch this step is at one front corner (Godot reports the car's
## own corner) and the way on is open within SLIP_REACH to the other side (`test_move` from the
## side-stepped spot, the smallest step that clears): step the car sideways that way (at most
## SLIP_RATE m/s) and say so; the caller keeps its speed. A touch along the flank, both corners
## at once, a face met at an angle (the glancing hit turns along it) or no way past don't slip.
func _corner_slip(speed: float, dt: float) -> bool:
	if speed < 1.0 or parked:
		return false
	var f := _forward()
	var right := f.cross(Vector3.UP)
	var half := Vector2(0.9, 2.0)  # the collision box's half width and half length
	var side := 0.0
	for k in get_slide_collision_count():
		var hit := get_slide_collision(k)
		var rel := hit.get_position() - global_position
		var lat := rel.dot(right)
		var n := hit.get_normal()
		# Met nose on (within ~37°): a wall met at an angle is the glancing hit's to turn along.
		if rel.dot(f) < half.y - 0.8 or absf(lat) < half.x - SLIP_REACH or Vector2(n.x, n.z).normalized().dot(Vector2(f.x, f.z)) > -0.8:
			return false
		var s := -signf(lat)
		if side != 0.0 and s != side:
			return false
		side = s
	if side == 0.0:
		return false
	var away := right * side
	for need: float in [0.15, 0.3, 0.45, SLIP_REACH]:
		if not test_move(global_transform.translated(away * need), f * 0.6):
			move_and_collide(away * minf(need, SLIP_RATE * dt))
			return true
	return false


func _forward() -> Vector3:
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()


func _make_body() -> Node3D:
	# A small retro hatchback with twin racing stripes. The front is -Z. Loop 2b: one mesh
	# with vertex colours (one draw call; it was 14 boxes, 14 materials) and each lamp pair
	# one more (their glow). The look loop (2026-10-28): the body is drawn with the actors'
	# material (actor.gdshader, no new shader) as its hero part: at night the paint and the
	# stripes light from within (HERO_PAINT, HERO_STRIPE), so the car is never darker than
	# the road; the stripes are a game pixel wider (0.18 -> 0.3 m) and the tail lamps wrap
	# over the rear deck, so the camera above sees them. Loop 2c (car models): the shape
	# comes from models.gd (player_meshes(): a lofted body with a sloped bonnet and
	# windscreen, a glasshouse narrower at the roof, side windows with pillars, eight-sided
	# wheels in dark arches with light hub caps, black bumpers, a roof spoiler, round head
	# lamps), the stripes running over the nose, bonnet, roof and tailgate; still 3 meshes.
	var root := Node3D.new()
	var paint := Color("#d8432f")
	var stripe := Color("#f4efe4")
	var meshes := Models.player_meshes(Models.fin(paint, Models.HERO, HERO_PAINT),
			Models.fin(stripe, Models.HERO, HERO_STRIPE))
	_part(root, meshes[0], Models.material(), true)
	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = Color("#fff3c4")
	lamp.roughness = 0.8
	lamp.emission_enabled = true
	lamp.emission = Color("#fff8dc")
	lamp.emission_energy_multiplier = 0.0
	_headlights.append(lamp)
	_part(root, meshes[1], lamp, false)
	var tail := StandardMaterial3D.new()
	tail.albedo_color = Color("#b3241f")
	tail.roughness = 0.8
	tail.emission_enabled = true
	tail.emission = Color("#ff2a1c")
	tail.emission_energy_multiplier = 0.0
	_tails.append(tail)
	_part(root, meshes[2], tail, false)
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


## One part of the body: a mesh with its material (loop 2b: the body casts the sun's shadow,
## the lamps don't).
func _part(parent: Node3D, mesh: ArrayMesh, mat: Material, shadows: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
