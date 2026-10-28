extends RefCounted
## Loop 2a: the driving controls, shared by the game (main.gd) and the replay test
## (tools/check_steering.gd), so the test drives exactly what the player drives.
##
## Three schemes (Settings → Controls, `--controls=`):
## - POINT (the default): point where you want to go. The stick points in screen space; the
##   follow camera holds still while the finger is down (or a direction key is held), so a
##   held direction stays put on screen and in the world, then eases round behind the car
##   0.6 s after the finger lifts. Gas comes from how far the stick is pushed (full from
##   three quarters out). Pointing well behind brakes, then turns (car.gd).
## - CLASSIC: steer + pedals. The stick's left / right steers (car-relative), GAS and
##   BRAKE / REVERSE are buttons on the right; the camera turns with the car.
## - FIXED: point where you want to go with the camera never turning (the v0.4 scheme).
## Keys follow the scheme: in POINT and FIXED, W A S D / arrows point in screen directions
## (like the helicopter); in CLASSIC, A / D steer, W is the gas and S the brake. Space
## brakes in every scheme.
##
## Before loop 2a the stick pointed in screen space while the follow camera kept turning
## towards the car's heading, so the world direction a held stick meant kept rotating
## with the car: holding the stick to one side made the car circle (check_steering.gd
## --legacy: 3.8 full circles in 10 s with the stick held right).

enum { POINT, CLASSIC, FIXED }
const NAMES := ["Point", "Classic", "Fixed"]
const KEYS := ["point", "classic", "fixed"]

## The stick, as a share of its radius: the dead zone, and where the gas is full (POINT).
const DEAD := 0.15
const FULL := 0.75
## CLASSIC: the left / right dead zone.
const STEER_DEAD := 0.08

## The default view height in metres while driving (was 110 before loop 2a): the car is
## ~58 px long side-on on an iPhone's 1170 lines instead of ~43, and still ~2.4 s of road
## ahead at 90 km/h (see README, Loop 2a).
const DEFAULT_SIZE := 80.0
## The view widens by this share at top speed.
const SPEED_ZOOM := 0.25
## How quickly the view's centre follows the car plus its lead (1/s).
const FOCUS_RATE := 6.0
## The view leads by this many seconds of the car's velocity, smoothed over LEAD_TAU so a
## turn swings it round gently, and by at most LEAD_MAX of the view height.
const LEAD_TIME := 0.5
const LEAD_TAU := 0.7
const LEAD_MAX := 0.2
## POINT: the camera waits this long after the finger lifts, then turns behind the car,
## easing in over RETURN_EASE seconds, at RETURN_RATE (1/s, once moving at 8 m/s).
const HOLD_DELAY := 0.6
const RETURN_EASE := 0.8
const RETURN_RATE := 1.0
## CLASSIC: the follow camera's rate (1/s at 8 m/s and over), as before loop 2a.
const FOLLOW_RATE := 2.2

var scheme := POINT
## True while the stick's finger is down or a direction key is held (POINT: the camera waits).
var held := false
var _since_release := 99.0
var _lead_vel := Vector3.ZERO


## Sets the car's controls from the stick (screen space, -1..1, y down; `stick_on` while its
## finger is down), the keys {left, right, up, down, brake}, the on-screen GAS and BRAKE
## pedals, and the camera's yaw in degrees (main.gd's cam_yaw).
func drive(car: Node, stick: Vector2, stick_on: bool, keys: Dictionary, gas: bool, brake: bool, cam_yaw: float,
		dt: float) -> void:
	var left: bool = keys.get("left", false)
	var right: bool = keys.get("right", false)
	var up: bool = keys.get("up", false)
	var down: bool = keys.get("down", false)
	var brake_key: bool = keys.get("brake", false)
	if scheme == CLASSIC:
		var s := float(left) - float(right)
		if stick_on and absf(stick.x) > STEER_DEAD:
			var u := clampf((absf(stick.x) - STEER_DEAD) / (1.0 - STEER_DEAD), 0.0, 1.0)
			# A gentle curve: fine corrections near the middle, full lock at the edge.
			s = -signf(stick.x) * u * (0.4 + 0.6 * u)
		car.target_dir = Vector3.ZERO
		car.steer = s
		car.throttle = 1.0 if gas or up else 0.0
		car.braking = brake or down or brake_key
		held = false
	else:
		var aim := Vector2.ZERO
		var amount := 0.0
		var length := stick.length()
		if stick_on and length > DEAD:
			aim = stick / length
			amount = clampf((length - DEAD) / (FULL - DEAD), 0.0, 1.0)
		else:
			var k := Vector2(float(right) - float(left), float(down) - float(up))
			if k != Vector2.ZERO:
				aim = k.normalized()
				amount = 1.0
		car.target_dir = screen_to_world(aim, cam_yaw) if aim != Vector2.ZERO else Vector3.ZERO
		car.throttle = amount
		car.steer = 0.0
		car.braking = brake or brake_key
		held = stick_on or aim != Vector2.ZERO
	_since_release = 0.0 if held else _since_release + dt


## Nothing held (the title screen, the helicopter, an autopilot): the camera may follow.
func release() -> void:
	held = false


## The follow camera's next yaw (degrees) for a car with `heading` (degrees, the car's
## rotation.y) at `speed` m/s. POINT holds still while held, waits HOLD_DELAY after the
## release, then eases round; CLASSIC turns with the car. Parked, it holds still.
func follow_yaw(cam_yaw: float, heading: float, speed: float, dt: float) -> float:
	var rate := FOLLOW_RATE * clampf(speed / 8.0, 0.0, 1.0)
	if scheme != CLASSIC:
		if held or _since_release < HOLD_DELAY:
			return cam_yaw
		# Off the gas the car soon slows down: keep turning round down to a crawl.
		rate = RETURN_RATE * smoothstep(HOLD_DELAY, HOLD_DELAY + RETURN_EASE, _since_release) \
				* clampf(speed / 3.0, 0.0, 1.0)
	return rad_to_deg(lerp_angle(deg_to_rad(cam_yaw), deg_to_rad(heading), 1.0 - exp(-rate * dt)))


## How far ahead of the car the view's centre sits: LEAD_TIME of the velocity smoothed over
## LEAD_TAU, at most LEAD_MAX of the view height `size`.
func lead(vel: Vector3, size: float, dt: float) -> Vector3:
	_lead_vel = _lead_vel.lerp(Vector3(vel.x, 0.0, vel.z), 1.0 - exp(-dt / LEAD_TAU))
	return (_lead_vel * LEAD_TIME).limit_length(size * LEAD_MAX)


## A placed or teleported car: the lead starts from its velocity.
func reset_lead(vel: Vector3) -> void:
	_lead_vel = Vector3(vel.x, 0.0, vel.z)


## A screen direction (x right, y down) as a world direction on the ground for a camera
## turned `yaw` degrees (main.gd's camera: pitch about x, then yaw about y).
static func screen_to_world(s: Vector2, yaw: float) -> Vector3:
	var y := deg_to_rad(yaw)
	var right := Vector3(cos(y), 0.0, -sin(y))
	var ahead := Vector3(-sin(y), 0.0, -cos(y))
	return right * s.x + ahead * -s.y


static func parse(v: String) -> int:
	var k := KEYS.find(v.to_lower())
	return k if k >= 0 else clampi(int(v), 0, NAMES.size() - 1)
