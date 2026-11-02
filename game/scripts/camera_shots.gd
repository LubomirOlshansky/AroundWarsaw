extends Node
## Camera loop: the cinematic moments, on Phantom Camera (game/addons/phantom_camera; Ramokz,
## MIT, v0.11.0.3): a fly-in from over the city down to the car when the title screen goes, and
## a short look at a new rescue or delivery target and back. Any touch, click or key skips a
## moment (a 0.3 s blend back to the car). main.gd starts them, never in test runs.
##
## How Phantom Camera is used: main.gd's Camera3D gets a PhantomCameraHost in MANUAL mode (it
## moves the camera only when main.gd calls frame(), so the pixel-grid snap and the far plane can
## follow it in the same frame), and three PhantomCamera3D nodes: FOLLOW (priority 10), which
## main.gd puts where its follow camera wants to be every frame of a moment; SHOT (the target's
## view) and MID (a wider view halfway, so a long look travels over the city instead of whipping
## through it). Raising a node's priority makes the host tween the camera to it (position, turn,
## and the orthographic size from its Camera3DResource) with that node's tween (duration,
## transition, ease); lowering it tweens back to the next highest. The shots keep the follow
## camera's turn, so the stick means the same direction on screen during a moment.
## Between moments the host isn't run at all (main.gd moves the camera itself): no cost.

const Lang := preload("res://scripts/lang.gd")
const PCamHost := preload("res://addons/phantom_camera/scripts/phantom_camera_host/phantom_camera_host.gd")
const PCam := preload("res://addons/phantom_camera/scripts/phantom_camera/phantom_camera_3d.gd")
const PCamTween := preload("res://addons/phantom_camera/scripts/resources/tween_resource.gd")
const PCamCamera := preload("res://addons/phantom_camera/scripts/resources/camera_3d_resource.gd")

## The fly-in: from FLY_SIZE m tall, its centre FLY_AHEAD m along the car's way (looking down
## the street), down to the follow view in FLY_TIME s (eased in and out).
const FLY_TIME := 2.6
const FLY_SIZE := 200.0
const FLY_AHEAD := 90.0
## The look at a target: OUT_TIME s there (split over MID when it is far), HOLD_TIME s on it,
## BACK_TIME s back; the target's view is TARGET_SIZE m tall (or as tall as framing the car and
## the target together needs, when they fit within MAX_SIZE); MID is at most MAX_SIZE.
const OUT_TIME := 1.2
const HOLD_TIME := 0.7
const BACK_TIME := 1.0
const TARGET_SIZE := 110.0
const MAX_SIZE := 220.0
## A target nearer than this (m) gets no look; the margin round a framing (m on screen).
const NEAR := 40.0
const MARGIN := 18.0
## A touch skips: back to the car in SKIP_TIME s. Not in the first SKIP_GRACE s: the tap that
## dismissed the title screen comes again as the click Godot makes from it.
const SKIP_TIME := 0.3
const SKIP_GRACE := 0.25
## The opening flyover (first launch only, docs/design/opening-flyover.md): OPEN_TIME s from a
## wide view of the Palace of Culture, round it and the museum, down to the car's follow view,
## one eased curve through OPEN_KEYS (a ground point x/z, its height above the car's ground, the
## view's size in m, the turn from the follow camera's in degrees, the pitch). The last key is the
## follow camera itself, so the hand-off has no cut. The caption (WARSZAWA, the place) is up from
## CAPTION_IN to CAPTION_OUT s.
const OPEN_TIME := 7.5
const OPEN_KEYS: Array[Dictionary] = [
	{"at": Vector2(-1214.0, 247.0), "up": 95.0, "size": 420.0, "turn": 115.0, "pitch": -38.0},
	{"at": Vector2(-1095.0, 165.0), "up": 30.0, "size": 230.0, "turn": 40.0, "pitch": -33.0},
]
const CAPTION_IN := 0.6
const CAPTION_OUT := 5.4
const CAPTION_FADE := 0.6

enum { IDLE, FLY, OUT_MID, OUT, HOLD, BACK_MID, HOME, OPEN }

## A moment ended (done, skipped or stopped): its name ("fly-in", "look", "opening").
signal ended(what: String)

var host: Node
var follow_pcam: Node3D
var shot_pcam: Node3D
var mid_pcam: Node3D
var state := IDLE
## What is playing, for the log: "fly-in", "look".
var moment := ""
var _leg := 0.0
var _leg_time := 0.0
## Skipped already (a touch comes as a touch and as the mouse click Godot makes from it).
var _skipped := false
## Seconds since the moment was asked for.
var _age := 0.0
var _frames := 0
var _pending: Callable
var _target := Vector3.ZERO
var _car := Vector3.ZERO
var _yaw := 0.0
var _pitch := -30.0
var _aspect := 2.0
var _follow_size := 80.0


## The host under `cam` (main.gd's camera) and the three views in `world`.
func setup(cam: Camera3D, world: Node3D) -> void:
	host = PCamHost.new()
	host.interpolation_mode = PCamHost.InterpolationMode.MANUAL
	cam.add_child(host)
	follow_pcam = _make_pcam("CameraFollow", 10, world)
	shot_pcam = _make_pcam("CameraShot", 0, world)
	mid_pcam = _make_pcam("CameraMid", 0, world)


func _make_pcam(node_name: String, priority: int, world: Node3D) -> Node3D:
	var p: Node3D = PCam.new()
	p.name = node_name
	var res: Resource = PCamCamera.new()
	res.projection = PCamCamera.ProjectionType.ORTHOGONAL
	res.size = 80.0
	res.near = 1.0
	res.far = 1400.0
	p.camera_3d_resource = res
	p.tween_resource = PCamTween.new()
	p.tween_resource.duration = 0.0
	p.tween_on_load = false
	p.priority = priority
	p.inactive_update_mode = PCam.InactiveUpdateMode.NEVER
	world.add_child(p)
	# The host runs the active node's logic itself (MANUAL); nothing else needs their frames.
	p.set_process(false)
	p.set_physics_process(false)
	return p


## True while a moment moves the camera (main.gd then lets frame() place it).
func playing() -> bool:
	return state != IDLE or _pending.is_valid()


## The fly-in, from over the city down to the follow view. `focus` is the car, `ahead` the way it
## faces (on the ground), `yaw` / `pitch` the follow camera's (degrees), `size` its view.
func fly_in(focus: Vector3, ahead: Vector3, yaw: float, pitch: float, size: float) -> void:
	_age = 0.0
	_pending = func() -> void:
		_yaw = yaw
		_pitch = pitch
		moment = "fly-in"
		_follow_size = size
		# The camera starts up there (the title screen still covers it), then tweens home.
		var cam: Camera3D = host.get_parent()
		_place(shot_pcam, focus + Vector3(ahead.x, 0.0, ahead.z).normalized() * FLY_AHEAD, FLY_SIZE)
		cam.global_transform = shot_pcam.global_transform
		cam.size = FLY_SIZE
		_jump_to_shot()
		_go_home(FLY_TIME, PCamTween.TransitionType.CUBIC, PCamTween.EaseType.EASE_IN_OUT)
		state = FLY
		print("camera: fly-in, %.0f m → %.0f m in %.1f s" % [FLY_SIZE, size, FLY_TIME])


## The opening flyover: the keys above, then the follow view of the car at `car`. `yaw` and
## `pitch` are the follow camera's (degrees). The camera starts on the first key at once (the
## title screen, if any, still covers it). `caption` (PL, EN) is shown on the way.
func opening(car: Vector3, yaw: float, pitch: float, caption: PackedStringArray = PackedStringArray()) -> void:
	_age = 0.0
	_car = car
	_yaw = yaw
	_pitch = pitch
	_pending = func() -> void:
		moment = "opening"
		state = OPEN
		_leg = 0.0
		_leg_time = OPEN_TIME
		var cam: Camera3D = host.get_parent()
		var v := open_view(0.0, _car.y, _yaw, follow_pcam.global_transform, _follow_size)
		cam.global_transform = v["xf"]
		cam.size = v["size"]
		if caption.size() >= 1:
			_make_caption(caption)
		print("camera: opening, %.0f m over the Palace → the car in %.1f s" % [v["size"], OPEN_TIME])


## A look at a new target and back: `car` and `target` on the ground, the follow camera's `yaw`,
## `pitch` and view `size`, the screen's `aspect` (width / height).
func look_at_target(car: Vector3, target: Vector3, yaw: float, pitch: float, size: float, aspect: float) -> void:
	if playing():
		return
	_car = car
	_target = target
	_yaw = yaw
	_pitch = pitch
	_aspect = aspect
	_follow_size = size
	_age = 0.0
	_pending = func() -> void:
		moment = "look"
		var b := _basis()
		var off := _target - _car
		var r := absf(off.dot(b.x))
		var u := absf(off.dot(b.y))
		# Both in one view if they fit, else the target alone, reached over a wider view halfway.
		var both := maxf(maxf(u + 2.0 * MARGIN, (r + 2.0 * MARGIN) / _aspect), _follow_size)
		if both <= MAX_SIZE:
			_place(shot_pcam, (_car + _target) * 0.5, both)
			_go(shot_pcam, OUT_TIME, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_IN_OUT)
			state = OUT
			_leg_time = OUT_TIME
			print("camera: look at the target %.0f m away, both in a %.0f m view" % [off.length(), both])
		else:
			_place(mid_pcam, (_car + _target) * 0.5, MAX_SIZE)
			_place(shot_pcam, _target, TARGET_SIZE)
			_go(mid_pcam, OUT_TIME * 0.5, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_IN)
			state = OUT_MID
			_leg_time = OUT_TIME * 0.5
			print("camera: look at the target %.0f m away, over a %.0f m view halfway" % [off.length(), MAX_SIZE])
		_leg = 0.0


## The west-sectors fix (2026-11-01): the views look_at_target will pass through, [centre, size
## (m tall)] from the car's to the target's (the car's, MID's when it goes over one, the shot's),
## by the same rule, so the streamer can load what each will show before the look starts.
static func look_keys(car: Vector3, target: Vector3, yaw: float, pitch: float, size: float, aspect: float) -> Array:
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0))
	var off := target - car
	var r := absf(off.dot(b.x))
	var u := absf(off.dot(b.y))
	var both := maxf(maxf(u + 2.0 * MARGIN, (r + 2.0 * MARGIN) / aspect), size)
	if both <= MAX_SIZE:
		return [[car, size], [(car + target) * 0.5, both]]
	return [[car, size], [(car + target) * 0.5, MAX_SIZE], [target, TARGET_SIZE]]


## Any touch, click or key: back to the car at once (a SKIP_TIME blend).
func skip() -> void:
	if _age < SKIP_GRACE:
		return
	if _pending.is_valid():
		_pending = Callable()
		ended.emit("skipped before it began")
		return
	if state == IDLE or _skipped:
		return
	_skipped = true
	_caption_out()
	print("camera: %s skipped" % moment)
	# Whatever was tweening, a fresh tween from where the camera is now: SHOT is put exactly
	# there and made the view at once, then FOLLOW is tweened to.
	var cam: Camera3D = host.get_parent()
	shot_pcam.global_transform = cam.global_transform
	shot_pcam.set_size(cam.size)
	_jump_to_shot()
	_go_home(SKIP_TIME, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_OUT)


## Stop a moment at once (a cut back to the car): the BENCH button's run.
func stop() -> void:
	if _pending.is_valid():
		_pending = Callable()
		ended.emit("stopped before it began")
	if state == IDLE:
		return
	_go_home(0.0, PCamTween.TransitionType.LINEAR, PCamTween.EaseType.EASE_IN_OUT)
	state = IDLE
	print("camera: %s stopped" % moment)
	_caption_free()
	var what := moment
	moment = ""
	_skipped = false
	ended.emit(what)


## One frame of a moment: FOLLOW goes where the follow camera wants to be (`follow_xf`, view
## `follow_size`), then the host moves the camera. False when no moment is playing (main.gd
## places the camera itself).
func frame(follow_xf: Transform3D, follow_size: float, dt: float) -> bool:
	_frames += 1
	_age += dt
	if _pending.is_valid():
		# The host finds its views after its first frame: start then.
		if _frames < 3:
			return false
		var start := _pending
		_pending = Callable()
		follow_pcam.global_transform = follow_xf
		follow_pcam.set_size(follow_size)
		start.call()
	if state == IDLE:
		return false
	_follow_size = follow_size
	follow_pcam.global_transform = follow_xf
	follow_pcam.set_size(follow_size)
	if state == OPEN:
		_open_frame(follow_xf, follow_size, dt)
		return true
	host.process(dt)
	_leg += dt
	if _leg >= _leg_time:
		_next()
	return true


## The next leg when one ends.
func _next() -> void:
	_leg = 0.0
	match state:
		FLY, HOME:
			state = IDLE
			print("camera: %s done" % moment)
			_caption_free()
			var what := moment
			moment = ""
			_skipped = false
			ended.emit(what)
		OUT_MID:
			_go(shot_pcam, OUT_TIME * 0.5, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_OUT)
			state = OUT
			_leg_time = OUT_TIME * 0.5
		OUT:
			state = HOLD
			_leg_time = HOLD_TIME
		HOLD:
			if mid_pcam.priority > 0:
				# Back over the wider view, halfway to wherever the car is now: lowering SHOT
				# makes MID (the highest left) the view, with MID's tween.
				_place(mid_pcam, (_car_now() + _target) * 0.5, MAX_SIZE)
				mid_pcam.tween_resource.duration = BACK_TIME * 0.5
				mid_pcam.tween_resource.transition = PCamTween.TransitionType.SINE
				mid_pcam.tween_resource.ease = PCamTween.EaseType.EASE_IN
				shot_pcam.priority = 0
				state = BACK_MID
				_leg_time = BACK_TIME * 0.5
			else:
				_go_home(BACK_TIME, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_IN_OUT)
		BACK_MID:
			_go_home(BACK_TIME * 0.5, PCamTween.TransitionType.SINE, PCamTween.EaseType.EASE_OUT)


## Where the car is now (FOLLOW's view centre on the ground is close enough: it leads the car a
## little).
func _car_now() -> Vector3:
	var b := _basis()
	return follow_pcam.global_position - b.z * _distance(_follow_size)


## Make `pcam` the view, tweened over `time` s.
func _go(pcam: Node3D, time: float, transition: int, ease: int) -> void:
	pcam.tween_resource.duration = time
	pcam.tween_resource.transition = transition
	pcam.tween_resource.ease = ease
	var top := 30 if pcam == shot_pcam else 20
	_raise(pcam, top)


func _raise(pcam: Node3D, priority: int) -> void:
	if pcam.priority == priority:
		# Already the view: drop and raise it again to start its tween afresh.
		pcam.priority = 0
	pcam.priority = priority


## SHOT, wherever it is, becomes the view at once (no tween): the camera is already there.
func _jump_to_shot() -> void:
	mid_pcam.priority = 0
	_go(shot_pcam, 0.0, PCamTween.TransitionType.LINEAR, PCamTween.EaseType.EASE_IN_OUT)


## Back to FOLLOW (the car), tweened over `time` s.
func _go_home(time: float, transition: int, ease: int) -> void:
	follow_pcam.tween_resource.duration = time
	follow_pcam.tween_resource.transition = transition
	follow_pcam.tween_resource.ease = ease
	mid_pcam.priority = 0
	shot_pcam.priority = 0
	state = HOME
	_leg = 0.0
	_leg_time = time


## Put a view with its centre at `focus` (on the ground), `size` m tall, turned like the follow
## camera.
func _place(pcam: Node3D, focus: Vector3, size: float) -> void:
	var b := _basis()
	pcam.global_transform = Transform3D(b, focus + b.z * _distance(size))
	pcam.set_size(size)


func _basis() -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(_pitch), deg_to_rad(_yaw), 0.0))


## The camera's distance from its centre for a view `size` m tall (main.gd's rule).
static func _distance(size: float) -> float:
	return maxf(500.0, size * 1.6)


# --- the opening flyover -----------------------------------------------------------------------

## The flyover's view at `e` (0..1 of OPEN_TIME) for a car on ground height `ground`, the follow
## camera's `yaw` at the start, and the follow view now (`follow_xf`, `follow_size`): one eased
## parameter over the whole flight, a Catmull-Rom curve through the keys and the follow view (so it
## never stops halfway), the size eased in log space (a zoom that feels even). At e = 1 it is the
## follow view itself. Static and pure: check_opening.gd samples it without a scene.
static func open_view(e: float, ground: float, yaw: float, follow_xf: Transform3D, follow_size: float) -> Dictionary:
	e = clampf(e, 0.0, 1.0)
	var u := e * e * e * (e * (e * 6.0 - 15.0) + 10.0)  # smootherstep: still at both ends
	var keys: Array[Dictionary] = []
	for k: Dictionary in OPEN_KEYS:
		var at: Vector2 = k["at"]
		keys.append({"focus": Vector3(at.x, ground + float(k["up"]), at.y), "size": float(k["size"]),
				"yaw": yaw + float(k["turn"]), "pitch": float(k["pitch"])})
	var euler := follow_xf.basis.get_euler()
	keys.append({"focus": follow_xf.origin - follow_xf.basis.z * _distance(follow_size),
			"size": follow_size, "yaw": _near_angle(rad_to_deg(euler.y), yaw), "pitch": rad_to_deg(euler.x)})
	var n := keys.size() - 1
	var f := u * n
	var seg := mini(int(f), n - 1)
	var t := f - seg
	var k0: Dictionary = keys[maxi(seg - 1, 0)]
	var k1: Dictionary = keys[seg]
	var k2: Dictionary = keys[seg + 1]
	var k3: Dictionary = keys[mini(seg + 2, n)]
	var focus := _cr3(k0["focus"], k1["focus"], k2["focus"], k3["focus"], t)
	var size := exp(_cr(log(k0["size"]), log(k1["size"]), log(k2["size"]), log(k3["size"]), t))
	var turn := _cr(k0["yaw"], k1["yaw"], k2["yaw"], k3["yaw"], t)
	var pitch := _cr(k0["pitch"], k1["pitch"], k2["pitch"], k3["pitch"], t)
	return {"xf": _view(focus, size, turn, pitch), "size": size, "focus": focus}


## One frame of the flyover (the camera is placed here, not by the host).
func _open_frame(follow_xf: Transform3D, follow_size: float, dt: float) -> void:
	_leg += dt
	var v := open_view(_leg / OPEN_TIME, _car.y, _yaw, follow_xf, follow_size)
	var cam: Camera3D = host.get_parent()
	cam.size = v["size"]
	cam.global_transform = v["xf"]
	_caption_frame()
	if _leg >= OPEN_TIME:
		# Home: the follow view itself; FOLLOW is the host's view already (nothing else raised).
		cam.global_transform = follow_xf
		cam.size = follow_size
		state = IDLE
		print("camera: opening done")
		_caption_free()
		moment = ""
		_skipped = false
		ended.emit("opening")


## A view centred on `focus`, `size` m tall, turned `yaw` and tipped `pitch` (degrees).
static func _view(focus: Vector3, size: float, yaw: float, pitch: float) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0))
	return Transform3D(b, focus + b.z * _distance(size))


## `a` (degrees) moved by whole turns to within 180° of `near`.
static func _near_angle(a: float, near: float) -> float:
	return near + wrapf(a - near, -180.0, 180.0)


static func _cr(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
			+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


static func _cr3(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	return Vector3(_cr(p0.x, p1.x, p2.x, p3.x, t), _cr(p0.y, p1.y, p2.y, p3.y, t), _cr(p0.z, p1.z, p2.z, p3.z, t))


# --- the caption -------------------------------------------------------------------------------

var _caption: CanvasLayer
var _caption_box: VBoxContainer


## WARSZAWA in big letters at the lower left, the place in Polish and English under it.
func _make_caption(lines: PackedStringArray) -> void:
	_caption_free()
	_caption = CanvasLayer.new()
	_caption.layer = 5
	add_child(_caption)
	var h := get_viewport().get_visible_rect().size.y
	_caption_box = VBoxContainer.new()
	_caption_box.add_theme_constant_override("separation", int(h * 0.004))
	_caption_box.position = Vector2(h * 0.07, h * 0.66)
	_caption_box.modulate.a = 0.0
	_caption.add_child(_caption_box)
	var big := FontVariation.new()
	big.base_font = ThemeDB.fallback_font
	big.variation_embolden = 1.1
	big.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	big.spacing_glyph = int(h * 0.006)
	_caption_box.add_child(_caption_label(Lang.pick("WARSZAWA", "WARSAW"), big, h * 0.095, Color.WHITE))
	var colours := [Color("#ffd23f"), Color("#c9c2d8")]
	if lines.size() >= 1:
		# One language: the place in Polish or in English (lang.gd).
		var shown := Lang.pick(lines[0], lines[1] if lines.size() > 1 else "")
		_caption_box.add_child(_caption_label(shown, ThemeDB.fallback_font, h * 0.05, colours[0]))


func _caption_label(text: String, font: Font, px: float, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", int(px))
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color("#1a0626"))
	l.add_theme_constant_override("outline_size", maxi(int(px * 0.22), 3))
	return l


## The caption's fade in and out by the flight's clock (or its fade out after a skip).
func _caption_frame() -> void:
	if _caption_box == null:
		return
	var a := clampf((_leg - CAPTION_IN) / CAPTION_FADE, 0.0, 1.0) * clampf((CAPTION_OUT - _leg) / CAPTION_FADE, 0.0, 1.0)
	_caption_box.modulate.a = a


## A skip: the caption goes with a quick fade.
func _caption_out() -> void:
	if _caption_box == null:
		return
	var tw := _caption_box.create_tween()
	tw.tween_property(_caption_box, "modulate:a", 0.0, SKIP_TIME)


func _caption_free() -> void:
	if _caption != null:
		_caption.queue_free()
	_caption = null
	_caption_box = null
