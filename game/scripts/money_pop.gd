extends Node3D
## v1.0 juice (loop 3i leftovers, 2026-11-01): money pops. A payment (wallet.gd `changed` with a
## positive `gained`) floats up over the vehicle as "+54 zł": a gold label that pops in, rises
## about three metres following the vehicle and fades in 1.5 s. Bigger pay, bigger label (a
## 20 zł tip to a 200 zł job). The HUD's wallet still flashes the same sum; this is the same
## feedback where the eye is, on the road.
##
## Four Label3D in a ring (a new pop takes a free one, else the oldest), billboards drawn over
## the buildings without a depth test, unshaded, so no shader or material of ours: at most four
## text draws while pops live and none, and no script, the rest of the time (`set_process`).
## A pop that comes while another is young starts higher so the two never sit on each other.
## Calm mode (access.gd `calm`): no pop-in and no rise, the label just sits above the vehicle
## and fades.

const Access := preload("res://scripts/access.gd")

const POPS := 4
## Seconds a pop lives.
const LIFE := 1.5
## Metres a pop rises, and the height it starts at over the vehicle's origin.
const RISE := 3.0
const START_UP := 6.0
## A pop younger than this (s) pushes the next one up by STACK_UP metres.
const STACK_AGE := 0.6
const STACK_UP := 1.3
## Font size (px of the label's atlas) for the smallest and the largest pay, and the pay at
## which it is largest.
const SIZE_MIN := 56
const SIZE_MAX := 104
const BIG_PAY := 200
const GOLD := Color("#ffe27a")
const OUTLINE := Color("#1b1206")

## The vehicle's position now (main.gd `_vehicle_position`).
var anchor: Callable
## Pops shown so far (the check reads it).
var shown := 0

var _labels: Array[Label3D] = []
var _age := PackedFloat32Array()
var _up := PackedFloat32Array()
var _next := 0


func _ready() -> void:
	for k in POPS:
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.shaded = false
		l.no_depth_test = true
		l.double_sided = false
		l.fixed_size = false
		l.pixel_size = 0.034
		l.outline_size = 22
		l.outline_modulate = OUTLINE
		l.modulate = GOLD
		l.render_priority = 5
		l.outline_render_priority = 4
		l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		l.visible = false
		add_child(l)
		_labels.append(l)
	_age.resize(POPS)
	_age.fill(LIFE)
	_up.resize(POPS)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_process(false)


## The label's text for a payment: "+54 zł", thousands with a space ("+1 250 zł").
static func text_for(amount: int) -> String:
	var digits := str(amount)
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += " "
		out += digits[i]
	return "+%s zł" % out


## The font size for a payment (px), growing with it up to BIG_PAY.
static func size_for(amount: int) -> int:
	return roundi(lerpf(SIZE_MIN, SIZE_MAX, clampf(float(amount) / BIG_PAY, 0.0, 1.0)))


## Shows a pop for `amount` złoty over the vehicle; nothing for a payment of 0 or less.
func pop(amount: int) -> void:
	if amount <= 0:
		return
	var slot := -1
	var oldest := 0
	var stack := 0.0
	for k in POPS:
		if _age[k] >= LIFE and slot < 0:
			slot = k
		if _age[k] > _age[oldest]:
			oldest = k
		if _age[k] < STACK_AGE:
			stack = maxf(stack, _up[k] + STACK_UP)
	if slot < 0:
		slot = oldest
	var l := _labels[slot]
	l.text = text_for(amount)
	l.font_size = size_for(amount)
	_age[slot] = 0.0
	_up[slot] = stack
	shown += 1
	_place(slot)
	l.visible = true
	set_process(true)


func _process(dt: float) -> void:
	var live := false
	for k in POPS:
		if _age[k] >= LIFE:
			continue
		_age[k] += dt
		if _age[k] >= LIFE:
			_labels[k].visible = false
			continue
		live = true
		_place(k)
	if not live:
		set_process(false)


## Puts pop `k` where its age says: over the vehicle, risen, scaled and faded.
func _place(k: int) -> void:
	var l := _labels[k]
	var t := clampf(_age[k] / LIFE, 0.0, 1.0)
	var base: Vector3 = anchor.call() if anchor.is_valid() else global_position
	var calm := Access.calm
	var rise := 0.0 if calm else RISE * (1.0 - (1.0 - t) * (1.0 - t))
	l.global_position = base + Vector3(0.0, START_UP + _up[k] + rise, 0.0)
	var grow := 1.0
	if not calm and _age[k] < 0.18:
		# Pop in: from 55% up to 115% and back to 100%.
		var u := _age[k] / 0.18
		grow = lerpf(0.55, 1.15, u) if u < 0.7 else lerpf(1.15, 1.0, (u - 0.7) / 0.3)
	l.scale = Vector3.ONE * grow
	var a := 1.0 if t < 0.55 else 1.0 - (t - 0.55) / 0.45
	l.modulate = Color(GOLD, a)
	l.outline_modulate = Color(OUTLINE, a)
