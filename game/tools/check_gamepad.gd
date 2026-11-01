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
##   P8 the menus' ui_accept / ui_cancel / ui_up..ui_right carry the pad (A, B, the D-pad);
## The follow-ups (2026-11-01), on a real HUD in the root window, events through Input:
##   P9 Settings opened by the pad focuses the open tab with the ring; RB moves to the next tab;
##      a focused volume bar steps 0.1 on the D-pad's right and left; B closes; opened after a
##      touch nothing takes focus;
##   P10 the notebook page's cursor moves to the nearest target each way, A opens a card, B (and
##       WRÓĆ) comes back to the card it left, nothing that way gives the focus back;
##   P11 the garage card opened by the pad focuses the paint worn; B closes it;
##   P12 the full map: the pad's hint, the stick pans east, RT zooms in, A held on the cross
##       teleports there, a pan cancels the hold.
##   godot --headless --path game --script res://tools/check_gamepad.gd

const Gamepad := preload("res://scripts/gamepad.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const Title := preload("res://scripts/title.gd")
const Hud := preload("res://scripts/hud.gd")
const NotebookPage := preload("res://scripts/notebook_page.gd")
const Garage := preload("res://scripts/garage.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Dialogue := preload("res://scripts/dialogue.gd")

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

	_ui()


func _ui() -> void:
	await process_frame
	var hud: CanvasLayer = Hud.new()
	root.add_child(hud)
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	await process_frame
	var state := {"controls": 0, "follow": true, "traffic": 2, "quality": 0, "auto": "Medium", "master": 1.0, "music": 0.5,
			"effects": 1.0, "perf": 0, "fps": 0, "style": 0, "vhs": 0, "weather": 0, "time": 0}

	# P9
	var panel: Control = hud.settings_panel
	Gamepad.note(_press(JOY_BUTTON_START, true))
	hud.open_settings(state)
	await process_frame
	var tabs: Array = panel.get("_tabs")
	var owner := root.gui_get_focus_owner()
	if owner != tabs[panel.get("_tab")] or not (owner as Button).has_theme_stylebox_override("focus"):
		fails.append("P9 Settings by the pad: the focus is on %s, not the open tab" % owner)
	var tab0: int = panel.get("_tab")
	_button(JOY_BUTTON_RIGHT_SHOULDER, true)
	_button(JOY_BUTTON_RIGHT_SHOULDER, false)
	await process_frame
	if panel.get("_tab") != wrapi(tab0 + 1, 0, panel.TABS.size()) or root.gui_get_focus_owner() != tabs[panel.get("_tab")]:
		fails.append("P9 RB: tab %d -> %d, focus %s" % [tab0, panel.get("_tab"), root.gui_get_focus_owner()])
	panel.set_tab(3)  # DŹWIĘK, the volumes
	await process_frame
	var bar: Control = (panel.get("_bars") as Dictionary)["music"]
	var got := []
	var on_change := func(key: String, v: Variant) -> void: got.append([key, v])
	panel.changed.connect(on_change)
	bar.grab_focus()
	_button(JOY_BUTTON_DPAD_RIGHT, true)
	_button(JOY_BUTTON_DPAD_RIGHT, false)
	await process_frame
	if got.is_empty() or not is_equal_approx(float(got[-1][1]), 0.6) or root.gui_get_focus_owner() != bar:
		fails.append("P9 the music bar at 0.5, D-pad right: %s, focus %s" % [got, root.gui_get_focus_owner()])
	_button(JOY_BUTTON_DPAD_LEFT, true)
	_button(JOY_BUTTON_DPAD_LEFT, false)
	await process_frame
	if got.size() < 2 or not is_equal_approx(float(got[-1][1]), 0.5):
		fails.append("P9 the music bar, D-pad left: %s" % [got])
	panel.changed.disconnect(on_change)
	_button(JOY_BUTTON_B, true)
	_button(JOY_BUTTON_B, false)
	await process_frame
	if panel.visible or root.gui_get_focus_owner() != null:
		fails.append("P9 B left Settings open (%s) or the focus on %s" % [panel.visible, root.gui_get_focus_owner()])
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	Gamepad.note(touch)
	hud.open_settings(state)
	await process_frame
	if root.gui_get_focus_owner() != null or (tabs[0] as Button).focus_mode != Control.FOCUS_NONE or bar.focus_mode != Control.FOCUS_NONE:
		fails.append("P9 Settings by a touch after the pad: focus %s, tab focus mode %d" % [root.gui_get_focus_owner(), (tabs[0] as Button).focus_mode])
	panel.close()

	# P10 (the cursor's rules on a page with synthetic targets: two chapters, a card under them)
	var nb: Control = NotebookPage.new()
	nb.set("_hits", [[Rect2(0, 0, 40, 40), "chapter", 0], [Rect2(50, 0, 40, 40), "chapter", 1],
			[Rect2(0, 60, 90, 40), "card", "lusterko"]])
	if NotebookPage.hit_key(nb.cursor_hit()) != "chapter:0":
		fails.append("P10 the cursor doesn't start on the first target")
	if not nb.move_cursor(Vector2.RIGHT) or nb.cursor != "chapter:1":
		fails.append("P10 right: cursor %s" % nb.cursor)
	if not nb.move_cursor(Vector2.DOWN) or nb.cursor != "card:lusterko":
		fails.append("P10 down: cursor %s" % nb.cursor)
	if nb.move_cursor(Vector2.DOWN):
		fails.append("P10 down from the bottom took the press (the focus should move on)")
	nb.activate(nb.cursor_hit())
	if nb.card != "lusterko":
		fails.append("P10 A on a card left card '%s'" % nb.card)
	nb.set("_hits", [[Rect2(0, 0, 40, 40), "chapter", 0], [Rect2(0, 60, 76, 44), "back", ""]])
	if str(nb.cursor_hit()[1]) != "back":
		fails.append("P10 on an open card the cursor isn't on WRÓĆ")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	if not nb.call("_pad_input", cancel) or nb.card != "" or nb.cursor != "card:lusterko":
		fails.append("P10 B on a card: card '%s', cursor %s" % [nb.card, nb.cursor])
	if nb.call("_pad_input", cancel):
		fails.append("P10 B on the grid was taken (Settings should close)")
	nb.free()

	# P11
	var w: Node = Wallet.new()
	w.persistent = false
	w.zl = 500
	root.add_child(w)
	var d: Node = Dialogue.new()
	root.add_child(d)
	var g: Node = Garage.new()
	g.wallet = w
	g.hud = hud
	g.dialogue = d
	g.eggs_found = func() -> int: return 0
	root.add_child(g)
	Gamepad.note(_press(JOY_BUTTON_A, true))
	g.open_card()
	await process_frame
	var worn: Button = (g.card.get("_swatches") as Dictionary).get(g.current())
	if root.gui_get_focus_owner() != worn:
		fails.append("P11 the garage by the pad: focus %s, not the paint worn (%s)" % [root.gui_get_focus_owner(), g.current()])
	var shut := [0]
	g.card.closed.connect(func() -> void: shut[0] += 1)
	_button(JOY_BUTTON_B, true)
	_button(JOY_BUTTON_B, false)
	await process_frame
	if shut[0] != 1:
		fails.append("P11 B closed the garage card %d times" % shut[0])

	# P12
	Gamepad.note(_press(JOY_BUTTON_BACK, true))
	hud.open_full_map(Vector2(10.0, 20.0), 0.0, PackedVector2Array())
	await process_frame
	var fm: Control = hud.full_map
	var hint: PanelContainer = fm.get("_hint")
	if not ((hint.get_child(0).get_child(1) as Label).text.contains("Hold A")):
		fails.append("P12 the full map's hint doesn't speak of the pad")
	var c0: Vector2 = fm.centre
	_axis(JOY_AXIS_LEFT_X, 1.0)
	fm._process(0.5)
	_axis(JOY_AXIS_LEFT_X, 0.0)
	if fm.centre.x <= c0.x + 1.0 or absf(fm.centre.y - c0.y) > 0.5:
		fails.append("P12 the stick right panned %s -> %s" % [c0, fm.centre])
	var ppm0: float = fm.ppm
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	fm._process(0.3)
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	if fm.ppm <= ppm0:
		fails.append("P12 RT didn't zoom in (%.3f -> %.3f px/m)" % [ppm0, fm.ppm])
	fm._input(_press(JOY_BUTTON_A, true))
	if fm.get("_hold_index") != fm.PAD_HOLD:
		fails.append("P12 A didn't start the hold")
	_axis(JOY_AXIS_LEFT_Y, 1.0)
	fm._process(0.05)
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	if fm.get("_hold_index") >= 0:
		fails.append("P12 a pan didn't cancel A's hold")
	fm._input(_press(JOY_BUTTON_A, false))
	var jumped := []
	fm.teleport.connect(func(p: Vector2) -> void: jumped.append(p))
	var want: Vector2 = fm.to_map(fm.get_viewport().get_visible_rect().size * 0.5)
	fm._input(_press(JOY_BUTTON_A, true))
	for i in 8:
		fm._process(0.1)
	if jumped.size() != 1 or jumped[0].distance_to(want) > 1.0 or fm.visible:
		fails.append("P12 A held: teleports %s (want one at %s), map open %s" % [jumped, want, fm.visible])
	fm._input(_press(JOY_BUTTON_A, false))
	_finish()


func _finish() -> void:
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
