extends RefCounted
## Gamepad loop (2026-11-01, F asked "can it work with the pad?"): Xbox, PlayStation and MFi
## controllers through Godot's joypad input (SDL's mapping on the Mac and Linux, the Game
## Controller framework on iOS: the same button indices for all three). Touch and the keys stay
## as they were; the pad is a third way in, read next to them in main.gd `_read_input`.
##
## Driving follows the scheme (drive_controls.gd), like the touch stick:
##   left stick   POINT / FIXED: point the way (pushed further = more gas); CLASSIC: steer
##   RT           gas (CLASSIC); the helicopter climbs
##   LT or B      brake / reverse; the helicopter sinks (LT)
## Buttons (one press, `command`), named after the keys they stand for:
##   A primary (M)     X secondary (K)     Y car / helicopter (H)
##   LB / RB turn the view (Q / E)          R3 follow camera (C)     L3 horn (B)
##   D-pad up / down zoom in / out (= / -)  D-pad right radio (R)     D-pad left flash lights (L)
##   Back / Share / View: the full map      Start / Options / Menu: Settings (Esc)
## Menus: Godot's own ui_up..ui_right carry the D-pad and the left stick; `install` adds A to
## ui_accept and B to ui_cancel. The settings card and the full map close on B, Start and Back.
##
## Pure functions over InputEvents and an action strength table so game/tools/check_gamepad.gd
## can drive them with synthetic events (no controller in CI).

## The left stick's dead zone (a share of its throw; worn sticks rest up to ~0.15 off centre).
const DEAD := 0.2
## A trigger counts as pressed past this share of its travel.
const TRIGGER := 0.3

## The actions this adds to the InputMap (`install`), and what each is bound to.
const STICK_ACTIONS := {
	"pad_left": [JOY_AXIS_LEFT_X, -1.0],
	"pad_right": [JOY_AXIS_LEFT_X, 1.0],
	"pad_up": [JOY_AXIS_LEFT_Y, -1.0],
	"pad_down": [JOY_AXIS_LEFT_Y, 1.0],
}
const GAS := "pad_gas"
const BRAKE := "pad_brake"

## One press, one command (main.gd `_pad_command`).
const BUTTONS := {
	JOY_BUTTON_A: "primary",
	JOY_BUTTON_X: "secondary",
	JOY_BUTTON_Y: "vehicle",
	JOY_BUTTON_LEFT_SHOULDER: "rotate_left",
	JOY_BUTTON_RIGHT_SHOULDER: "rotate_right",
	JOY_BUTTON_RIGHT_STICK: "follow",
	JOY_BUTTON_LEFT_STICK: "horn",
	JOY_BUTTON_DPAD_UP: "zoom_in",
	JOY_BUTTON_DPAD_DOWN: "zoom_out",
	JOY_BUTTON_DPAD_RIGHT: "radio",
	JOY_BUTTON_DPAD_LEFT: "flash",
	JOY_BUTTON_BACK: "map",
	JOY_BUTTON_START: "settings",
}

## The order of the last joypad event and the last touch / key / click (0: none yet; a counter,
## not the clock, so two in the same millisecond still have an order). `in_use` compares them.
static var _seq := 0
static var last_pad := 0
static var last_other := 0


## Adds the pad's actions once (main.gd `_ready`; the check calls it too). Device -1: any pad.
static func install() -> void:
	for action: String in STICK_ACTIONS:
		_add(action, DEAD, _axis(STICK_ACTIONS[action][0], STICK_ACTIONS[action][1]))
	_add(GAS, TRIGGER, _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	_add(BRAKE, TRIGGER, _axis(JOY_AXIS_TRIGGER_LEFT, 1.0))
	var b := InputEventJoypadButton.new()
	b.device = -1
	b.button_index = JOY_BUTTON_B
	InputMap.action_add_event(BRAKE, b)
	# Godot's ui_accept / ui_cancel carry no pad button out of the box (the D-pad is in ui_up..):
	# A presses the focused button, B backs out (the garage card, the settings card).
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)


static func _add_button(action: String, button: JoyButton) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return
	var b := InputEventJoypadButton.new()
	b.device = -1
	b.button_index = button
	InputMap.action_add_event(action, b)


static func _add(action: String, dead: float, event: InputEvent) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, dead)
	InputMap.action_add_event(action, event)


static func _axis(axis: JoyAxis, dir: float) -> InputEventJoypadMotion:
	var m := InputEventJoypadMotion.new()
	m.device = -1
	m.axis = axis
	m.axis_value = dir
	return m


## The left stick in screen space (-1..1, x right, y down, like hud.gd's `stick`), dead zone
## taken out and rescaled so the throw past it still reaches 1.
static func stick() -> Vector2:
	return Input.get_vector("pad_left", "pad_right", "pad_up", "pad_down")


static func gas() -> bool:
	return Input.is_action_pressed(GAS)


static func brake() -> bool:
	return Input.is_action_pressed(BRAKE)


## The helicopter's height: RT up, LT down (-1..1, analogue).
static func climb() -> float:
	return Input.get_action_strength(GAS) - Input.get_action_strength(BRAKE)


## The command a joypad button press stands for ("" for anything else: a release, an axis, a
## touch, a key, a button with no job).
static func command(event: InputEvent) -> String:
	var b := event as InputEventJoypadButton
	if b == null or not b.pressed:
		return ""
	return BUTTONS.get(b.button_index, "")


## Whether `event` closes a card (the settings card, the full map): B or Start.
static func closes(event: InputEvent) -> bool:
	var b := event as InputEventJoypadButton
	return b != null and b.pressed and b.button_index in [JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK]


## Keeps track of which came last, the pad or a touch / key / click (main.gd `_input` calls it
## for every event). A stick resting inside its dead zone doesn't count.
static func note(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > DEAD):
		_seq += 1
		last_pad = _seq
	elif event is InputEventScreenTouch or event is InputEventKey or event is InputEventMouseButton:
		_seq += 1
		last_other = _seq


## True when the pad was used last: the HUD hides the touch pedals and shows the pad's words.
static func in_use() -> bool:
	return last_pad > last_other
