extends RefCounted
## v1.0 juice (2026-11-01): every buzz in the game ends up here (access.gd `Access.buzz` calls
## buzz(), which keeps Settings' Vibration switch, access.gd `vibration`), so the phone's
## vibration has one floor that the hand can actually feel and one place that keeps iOS's haptic
## engine running.
##
## Why buzzes "didn't work" on the iPhone: Godot 4.7.2's iOS template plays every
## Input.vibrate_handheld as one Core Haptics *continuous* event (apple_embedded.mm
## vibrate_haptic_engine) and then logs `Could not vibrate using haptic engine: %@` every time,
## success or not: the `(null)` in the device log is "no error", not a failure. What did go
## wrong is the strength: most calls asked for 25-40 ms at intensity 0.3-0.5, and a continuous
## event that short and soft is close to nothing on a Taptic Engine (Android's motors too).
## The engine also shuts itself down when idle and is stopped while the app is in the
## background; it restarts on its own, but inside the frame of the next buzz (the first
## rescue call's hitch, sweep 2). So here: a floor of FLOOR_MS / FLOOR_AMP on every buzz, a
## short gap between buzzes, and warm() (start without waiting) at load, on resume and every
## KEEP_WARM seconds while the car is driving (main.gd calls tick()).
##
## Static, no node. Game code calls Access.buzz(ms, strength); car.gd calls knock().

const Access := preload("res://scripts/access.gd")

## The shortest and softest buzz a hand notices on both phones (iPhone 11 / 16 Pro Max's Taptic
## Engine as a continuous event; Android's amplitude is this × 255).
const FLOOR_MS := 45
const FLOOR_AMP := 0.55
## The longest buzz (a hard crash, a lost race): longer reads as a phone call.
const CEIL_MS := 220
## Buzzes closer than this are merged into the stronger one (a crash and its scrape, a job's
## pay and its toast in one frame).
const GAP_USEC := 70000
## While driving, the engine is started again this often (it shuts down after a few idle
## seconds; starting a running engine costs nothing).
const KEEP_WARM := 6.0

## How many buzzes went to the platform (the bench and check_haptics read it).
static var count := 0
## The last buzz that went out (ms, amplitude), for checks and the log.
static var last_ms := 0
static var last_amp := 0.0
static var _last_usec := -GAP_USEC
static var _last_end_usec := 0
static var _warm_in := 0.0


## A buzz of about `duration_ms` at `amplitude` (0..1), raised to the floor, capped, and
## dropped when another one is still playing and this one is no stronger.
static func buzz(duration_ms: int, amplitude: float = 0.6) -> void:
	if not Access.vibration:
		return
	var ms := clampi(duration_ms, FLOOR_MS, CEIL_MS)
	var amp := clampf(amplitude, FLOOR_AMP, 1.0)
	var now := Time.get_ticks_usec()
	if now - _last_usec < GAP_USEC and amp <= last_amp:
		return
	if now < _last_end_usec and amp <= last_amp:
		return
	_last_usec = now
	_last_end_usec = now + ms * 1000
	last_ms = ms
	last_amp = amp
	count += 1
	Input.vibrate_handheld(ms, amp)
	_warm_in = KEEP_WARM


## A knock of the car at `speed` m/s lost or closing (car.gd): a tap for a bump, a thud for a
## crash. Below 4 m/s nothing (scraping along a wall).
static func knock(speed: float) -> void:
	if speed < 4.0:
		return
	var s := clampf((speed - 4.0) / 14.0, 0.0, 1.0)
	buzz(int(lerpf(50.0, 160.0, s)), lerpf(0.6, 1.0, s))


## Starts the iOS haptic engine without waiting (the template's bound start_haptic_engine,
## startWithCompletionHandler); builds it first if it isn't yet (behind the loading screen at
## load). Elsewhere it does nothing. True when it ran.
static func warm() -> bool:
	_warm_in = KEEP_WARM
	if not Access.vibration:
		return false
	for n: String in ["AppleEmbedded", "iOS"]:
		if Engine.has_singleton(n):
			var ios := Engine.get_singleton(n)
			if ios.has_method("start_haptic_engine"):
				ios.call("start_haptic_engine")
				return true
	return false


## Once a frame from main.gd: keeps the engine warm while the car drives, so a crash's buzz
## doesn't start it inside its own frame.
static func tick(dt: float, driving: bool) -> void:
	if not driving:
		return
	_warm_in -= dt
	if _warm_in <= 0.0:
		warm()
