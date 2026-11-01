extends SceneTree
## The gamepad loop (2026-11-01): Xbox, PlayStation and MFi controllers (gamepad.gd), with
## synthetic joypad events (no controller and no map needed; CI too).
##   P1 install() adds the stick, gas and brake actions once (a second call adds nothing);
##   P2 the left stick: a push reads in screen space (y down), a rest inside the dead zone is zero;
##   P3 RT is gas, LT or B is brake, the helicopter's climb is RT - LT;
##   P4 the pad drives through drive_controls.gd: POINT points up the screen with full gas,
##      CLASSIC steers right and RT gives gas, LT brakes;
##   P5 every button in gamepad.gd BUTTONS has a job in main.gd `_pad_command`, a release or an
##      axis is no command; B, Start and Back close a card, A doesn't;
##   P6 the title: A / Start continue, Y is NOWA GRA, B does nothing; on the question A is TAK and
##      B is NIE;
##   P7 the pad used last hides the touch pedals (in_use), a touch takes over again, a stick at
##      rest doesn't count;
##   P8 the menus' ui_accept / ui_cancel / ui_up..ui_right carry the pad (A, B, the D-pad).
##   godot --headless --path game --script res://tools/check_gamepad.gd

const Gamepad := preload("res://scripts/gamepad.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const Title := preload("res://scripts/title.gd")

var fails: Array[String] = []


func _initialize() -> void:
	# P1
	Gamepad.install()
	var counts := {}
	for a: String in Gamepad.STICK_ACTIONS.keys() + [Gamepad.GAS, Gamepad.BRAKE]:
		if not InputMap.has_action(a):
			fails.append("P1 no action %s" % a)
		else:
			counts[a] = InputMap.action_get_events(a).size()
	Gamepad.install()
	for a: String in counts:
		if InputMap.action_get_events(a).size() != counts[a]:
			fails.append("P1 a second install() added events to %s" % a)

	# P2
	_axis(JOY_AXIS_LEFT_X, 1.0)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	var s := Gamepad.stick()
	if s.distance_to(Vector2(1, 0)) > 0.05:
		fails.append("P2 the stick pushed right read %s" % s)
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_axis(JOY_AXIS_LEFT_Y, -1.0)
	s = Gamepad.stick()
	if s.distance_to(Vector2(0, -1)) > 0.05:
		fails.append("P2 the stick pushed up read %s (screen space: y down)" % s)
	_axis(JOY_AXIS_LEFT_X, 0.12)
	_axis(JOY_AXIS_LEFT_Y, -0.1)
	if Gamepad.stick() != Vector2.ZERO:
		fails.append("P2 a stick resting at (0.12, -0.1) read %s, not zero" % Gamepad.stick())
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_axis(JOY_AXIS_LEFT_Y, 0.0)

	# P3
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.8)
	if not Gamepad.gas() or Gamepad.brake():
		fails.append("P3 RT at 0.8: gas %s, brake %s" % [Gamepad.gas(), Gamepad.brake()])
	if absf(Gamepad.climb() - 0.8) > 0.25:
		fails.append("P3 RT at 0.8 climbs %.2f" % Gamepad.climb())
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.1)
	if Gamepad.gas():
		fails.append("P3 RT resting at 0.1 is gas")
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	if not Gamepad.brake() or Gamepad.climb() > -0.9:
		fails.append("P3 LT full: brake %s, climb %.2f" % [Gamepad.brake(), Gamepad.climb()])
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	_button(JOY_BUTTON_B, true)
	if not Gamepad.brake():
		fails.append("P3 B is not brake")
	_button(JOY_BUTTON_B, false)
	if Gamepad.brake():
		fails.append("P3 brake held after B was let go")

	# P4
	var car := _fake_car()
	var c := Controls.new()
	c.scheme = Controls.POINT
	_axis(JOY_AXIS_LEFT_Y, -1.0)
	c.drive(car, Gamepad.stick(), Gamepad.stick() != Vector2.ZERO, {}, Gamepad.gas(), Gamepad.brake(), 0.0, 1.0 / 60.0)
	var ahead := Controls.screen_to_world(Vector2(0, -1), 0.0)
	if car.target_dir.distance_to(ahead) > 0.05 or car.throttle < 0.99 or not c.held:
		fails.append("P4 POINT, stick up: dir %s (want %s), throttle %.2f, held %s" % [car.target_dir, ahead, car.throttle, c.held])
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	c.scheme = Controls.CLASSIC
	_axis(JOY_AXIS_LEFT_X, 1.0)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	c.drive(car, Gamepad.stick(), Gamepad.stick() != Vector2.ZERO, {}, Gamepad.gas(), Gamepad.brake(), 0.0, 1.0 / 60.0)
	if car.steer > -0.9 or car.throttle < 0.99 or car.braking:
		fails.append("P4 CLASSIC, stick right + RT: steer %.2f, throttle %.2f, braking %s" % [car.steer, car.throttle, car.braking])
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	c.drive(car, Gamepad.stick(), Gamepad.stick() != Vector2.ZERO, {}, Gamepad.gas(), Gamepad.brake(), 0.0, 1.0 / 60.0)
	if not car.braking or car.throttle > 0.0 or car.steer != 0.0:
		fails.append("P4 CLASSIC, LT: braking %s, throttle %.2f, steer %.2f" % [car.braking, car.throttle, car.steer])
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	car.free()

	# P5
	var main_text := FileAccess.get_file_as_string("res://scripts/main.gd")
	var body := main_text.substr(main_text.find("func _pad_command("))
	body = body.substr(0, body.find("\nfunc ", 10))
	for button: int in Gamepad.BUTTONS:
		var what: String = Gamepad.BUTTONS[button]
		if Gamepad.command(_press(button, true)) != what:
			fails.append("P5 button %d is not '%s'" % [button, what])
		if not body.contains('"%s":' % what):
			fails.append("P5 main.gd _pad_command has no '%s'" % what)
		if Gamepad.command(_press(button, false)) != "":
			fails.append("P5 releasing button %d is a command" % button)
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 1.0
	if Gamepad.command(motion) != "" or Gamepad.command(InputEventKey.new()) != "":
		fails.append("P5 an axis or a key is a command")
	for button: int in [JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_BACK]:
		if not Gamepad.closes(_press(button, true)):
			fails.append("P5 button %d doesn't close a card" % button)
	if Gamepad.closes(_press(JOY_BUTTON_A, true)) or Gamepad.closes(_press(JOY_BUTTON_B, false)):
		fails.append("P5 A, or letting go of B, closes a card")

	# P6
	var picks := [
		[JOY_BUTTON_A, false, KEY_ENTER], [JOY_BUTTON_START, false, KEY_ENTER], [JOY_BUTTON_Y, false, KEY_N],
		[JOY_BUTTON_B, false, KEY_NONE], [JOY_BUTTON_X, false, KEY_NONE],
		[JOY_BUTTON_A, true, KEY_Y], [JOY_BUTTON_B, true, KEY_ESCAPE], [JOY_BUTTON_Y, true, KEY_NONE],
	]
	for p: Array in picks:
		var got := Title.pad_key(p[0], p[1])
		if got != p[2]:
			fails.append("P6 title: button %d (question %s) is key %d, want %d" % [p[0], p[1], got, p[2]])

	# P7
	Gamepad.note(_press(JOY_BUTTON_A, true))
	if not Gamepad.in_use():
		fails.append("P7 a pad button doesn't put the pad in use")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	Gamepad.note(touch)
	if Gamepad.in_use():
		fails.append("P7 a touch after the pad leaves the pad in use")
	var rest := InputEventJoypadMotion.new()
	rest.axis = JOY_AXIS_LEFT_X
	rest.axis_value = 0.05
	Gamepad.note(rest)
	if Gamepad.in_use():
		fails.append("P7 a stick at rest (0.05) put the pad in use")
	var hud_text := FileAccess.get_file_as_string("res://scripts/hud.gd")
	if not hud_text.contains("if pad_mode and event is InputEventScreenTouch"):
		fails.append("P7 hud.gd _input no longer gives the pedals back on a touch")

	# P8
	var want := {"ui_accept": JOY_BUTTON_A, "ui_cancel": JOY_BUTTON_B, "ui_up": JOY_BUTTON_DPAD_UP,
			"ui_down": JOY_BUTTON_DPAD_DOWN, "ui_left": JOY_BUTTON_DPAD_LEFT, "ui_right": JOY_BUTTON_DPAD_RIGHT}
	for action: String in want:
		var found := false
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == want[action]:
				found = true
		if not found:
			fails.append("P8 %s has no pad button %d" % [action, want[action]])

	print("gamepad: %d buttons, stick dead zone %.2f, trigger %.2f" % [Gamepad.BUTTONS.size(), Gamepad.DEAD, Gamepad.TRIGGER])
	for f in fails:
		print("  FAIL ", f)
	print("check_gamepad: %s" % ("OK" if fails.is_empty() else "FAIL (%d)" % fails.size()))
	quit(0 if fails.is_empty() else 1)


func _axis(axis: JoyAxis, value: float) -> void:
	var m := InputEventJoypadMotion.new()
	m.device = 0
	m.axis = axis
	m.axis_value = value
	Input.parse_input_event(m)
	Input.flush_buffered_events()


func _button(button: JoyButton, pressed: bool) -> void:
	Input.parse_input_event(_press(button, pressed))
	Input.flush_buffered_events()


func _press(button: int, pressed: bool) -> InputEventJoypadButton:
	var b := InputEventJoypadButton.new()
	b.device = 0
	b.button_index = button as JoyButton
	b.pressed = pressed
	return b


## Only what drive_controls.gd sets.
func _fake_car() -> Node:
	var src := GDScript.new()
	src.source_code = "extends Node\nvar target_dir := Vector3.ZERO\nvar steer := 0.0\nvar throttle := 0.0\nvar braking := false\n"
	src.reload()
	var n := Node.new()
	n.set_script(src)
	return n
