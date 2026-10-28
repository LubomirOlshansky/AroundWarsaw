extends CanvasLayer
## On-screen controls at full resolution, above the pixel-art view:
## a floating stick on the left (point-to-steer), a brake on the right (or
## climb and sink pads in the helicopter), vehicle, style and camera buttons at
## the top, the rescue-mission card and status (shared with street races), an
## arrow to the mission target, the race challenge button and big countdown
## banner, rival dots on the minimap, and the map attribution. TIME, RADIO and VHS
## sit left of the top buttons (or under them on a narrow screen), and a
## now-playing ticker slides in at the bottom left when the radio changes (or the
## host talks). Under the minimap: the wallet (złoty and respect) and a small note
## card (an easter egg found). The status panel can show a kebab's steam (heat) or
## the słoiki run's jars; side-job places blink on the minimap. v0.9: a RAIN toggle
## beside VHS (same short toggle, so the row grows by one small button), and a
## performance overlay (hidden; a three-finger tap or P shows it) with a QUALITY button.
## Loop 2a: a gear in the top left corner opens the settings panel (settings_panel.gd);
## the on-screen driving controls follow the control scheme: Point and Fixed keep the
## floating stick and BRAKE; Classic has a floating left / right steering strip on the
## left and GAS (bottom right) and BRAKE beside it (a thumb can slide between them).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const SettingsPanel := preload("res://scripts/settings_panel.gd")
## drive_controls.gd's schemes (POINT, CLASSIC, FIXED).
const CLASSIC := 1

signal style_pressed
signal rotate_pressed(direction: int)
signal camera_pressed
signal zoom_pressed(direction: int)   # +1 out, -1 in
signal pinched(ratio: float)          # finger distance now / before
signal vehicle_pressed
signal card_pressed(index: int)       # a button on the mission card
signal pill_pressed                   # the collapsed RESCUE CALLS button
signal abort_pressed                  # the ✕ on the mission status
signal challenge_pressed              # FLASH LIGHTS: challenge the rival in front
signal time_pressed                   # TIME: day, dusk, night
signal radio_pressed                  # RADIO: next station or off
signal vhs_pressed                    # VHS: the tape overlay on or off
signal tapped(at: Vector2)            # a short tap on the city, not on a control (v0.8: landmarks)
signal weather_pressed                # RAIN: rain on or off (v0.9)
signal quality_pressed                # QUALITY on the performance overlay: Low, Medium, High
signal perf_gesture                   # three fingers down at once: the performance overlay
signal settings_pressed               # loop 2a: the gear
signal bench_pressed                  # loop 2b: TEST on the performance overlay

var stick := Vector2.ZERO   # -1..1 in screen space, x right, y down
var brake := false
## Loop 2a: the GAS pedal (Classic), and the control scheme the pads are drawn for.
var gas := false
var scheme := 0
var settings_panel: Control
var _gear: Button
var _gas_index := -1
## Helicopter height pads: +1 held climbs, -1 sinks.
var climb := 0.0
var flying := false
var ui := 1.0

var _info: Label
var _style_button: Button
var _camera_button: Button
var _vehicle_button: Button
var _pad: Control
var _climb_index := -1
## Mission card (calls and results), the status panel while a mission runs, and
## the small button that stands in for the card when it's put away.
var _card: PanelContainer
var _card_title: Label
var _card_body: Label
var _card_buttons: HBoxContainer
## The side jobs' cards sit at the bottom centre, clear of the speech bubbles over
## the stand or the door; the others at the top centre under the buttons.
var _card_bottom := false
var _panel_top := 66.0
var _status: PanelContainer
var _status_title: Label
var _status_clock: Label
var _status_hint: Label
var _status_bar: ColorRect
var _status_track: Control
var _status_badge: Label
## Street races: the challenge button and a big banner (countdown, GO!).
var _challenge: Button
var _banner: Label
var _overlay: Control
var _pill: Button
var _toast: Label
var _toast_left := 0.0
## Loop 10a: a toast's English gloss, smaller, under its Polish line.
var _toast_gloss: Label
## TIME / RADIO / VHS, and the main top bar they sit beside.
var _bar: HBoxContainer
var _extras: HBoxContainer
var _time_button: Button
var _radio_button: Button
var _vhs_button: Button
var _rain_button: Button
var _extras_below := false
## The performance overlay (top left, under the info text) and its QUALITY button.
var _perf: PanelContainer
var _perf_label: Label
var _quality_button: Button
## Loop 2b: the bench's result card (built when first shown) and the text COPY puts on the
## clipboard.
var _bench_card: PanelContainer
var _bench_label: Label
var _bench_copy: Button
var _bench_text := ""
## Fingers on the screen now (the three-finger tap).
var _fingers := {}
## The now-playing ticker: a panel that slides in, holds, and slides out.
var _ticker: PanelContainer
var _ticker_label: Label
var _ticker_style: StyleBoxFlat
var _ticker_left := 0.0
var _ticker_hold := 4.5
var _ticker_sub: Label
## The wallet under the minimap, a "+54 zł" that floats up from it, and the note card.
var _wallet: Control
var _wallet_zl := 0
var _wallet_respect := 0
var _wallet_gain := 0
var _wallet_flash := 0.0
var _note: PanelContainer
var _note_title: Label
var _note_body: Label
var _note_style: StyleBoxFlat
var _note_left := 0.0
## v0.8: the landmark info card (same look as the note card, in its place), and the
## touches that may turn out to be taps: index -> [start position, start time in ms].
var _info_card: PanelContainer
var _info_title: Label
var _info_pl: Label
var _info_en: Label
var _info_left := 0.0
var _taps := {}
## The status panel's picture row: a kebab's steam or the słoiki run's jars.
var _status_icons: Control
var _icons := {}
## Side-job places on the minimap (kebab stands, the station), blinking.
var _mini_pois := PackedVector2Array()
var _mini_poi_colours := PackedColorArray()
## Mission target: its point on screen (the arrow) and on the minimap.
var _target_visible := false
var _target_at := Vector2.ZERO
var _target_label := ""
var _target_colour := Color.WHITE
var _mini_target := Vector2.INF
var _mini_target_colour := Color.WHITE
var _mini_dots := PackedVector2Array()
var _mini_dot_colours := PackedColorArray()
var _mini_car := Vector2.ZERO
var _mini_yaw := 0.0
var _stick_index := -1
var _stick_origin := Vector2.ZERO
var _stick_point := Vector2.ZERO
var _brake_index := -1
## Touches that are neither the stick nor the brake; two of them make a pinch.
var _free_touches := {}
var _pinch_distance := 0.0
var _marker := Vector2.ZERO
var _marker_visible := false
## Minimap: north-up data drawn once, then turned and moved so the camera's view is up.
## Loop 2b: every street, park and pond is built once into one 2D mesh (the same triangles
## draw_polyline and draw_colored_polygon made), drawn with one call and cut to the circle
## by a small shader. It was each of them drawn on its own under a clip, every frame: 6,500
## of the frame's 6,800 draw calls, the iPhone's 16 fps.
const MINI_SCALE := 0.2   # minimap pixels per metre, before the UI scale
const MINI_CLIP := "shader_type canvas_item;\nuniform vec2 centre;\nuniform float radius;\nvoid fragment() {\n\tif (distance(FRAGCOORD.xy, centre) > radius) {\n\t\tdiscard;\n\t}\n}\n"
var _minimap: Control
var _mini_content: Node2D
var _mini_mesh: ArrayMesh
var _mini_clip: ShaderMaterial
var _mini_overlay: Control
var _mini_radius := 72.0
var _car_dir := Vector2.UP
var _north := Vector2.UP
## Space kept clear of the Dynamic Island and rounded corners in landscape.
var _inset_left := 0.0
var _inset_right := 0.0


func _ready() -> void:
	ui = clampf(get_viewport().get_visible_rect().size.y / 720.0, 1.0, 3.0)
	if OS.has_feature("mobile"):
		var screen := DisplayServer.screen_get_size()
		var safe := DisplayServer.get_display_safe_area()
		var k := get_viewport().get_visible_rect().size.x / float(maxi(screen.x, 1))
		_inset_left = safe.position.x * k
		_inset_right = (screen.x - safe.end.x) * k

	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	# Loop 2a: the gear (settings) in the top left corner, its touch area out to the corner.
	_gear = Button.new()
	_gear.focus_mode = Control.FOCUS_NONE
	_gear.flat = true
	_gear.position = Vector2(_inset_left, 0)
	_gear.size = Vector2((16 + 54 + 6) * ui, 68 * ui)
	_gear.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_gear.draw.connect(_draw_gear)
	_gear.pressed.connect(func(): settings_pressed.emit())
	add_child(_gear)

	_info = Label.new()
	_info.position = Vector2((16 + 54 + 14) * ui + _inset_left, 12 * ui)
	_info.add_theme_font_size_override("font_size", int(17 * ui))
	_info.add_theme_color_override("font_color", Color("#fbf7ee"))
	_info.add_theme_color_override("font_outline_color", Color("#2a2622"))
	_info.add_theme_constant_override("outline_size", int(5 * ui))
	add_child(_info)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	bar.add_theme_constant_override("separation", int(8 * ui))
	bar.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bar.position = Vector2(-16 * ui - _inset_right, 12 * ui)
	add_child(bar)
	_bar = bar
	_vehicle_button = _button(bar, "HELI")
	_vehicle_button.pressed.connect(func(): vehicle_pressed.emit())
	_style_button = _button(bar, "STYLE")
	_style_button.pressed.connect(func(): style_pressed.emit())
	_camera_button = _button(bar, "CAM")
	_camera_button.pressed.connect(func(): camera_pressed.emit())
	_button(bar, "<").pressed.connect(func(): rotate_pressed.emit(-1))
	_button(bar, ">").pressed.connect(func(): rotate_pressed.emit(1))
	_button(bar, "−").pressed.connect(func(): zoom_pressed.emit(1))
	_button(bar, "+").pressed.connect(func(): zoom_pressed.emit(-1))

	_extras = HBoxContainer.new()
	_extras.add_theme_constant_override("separation", int(8 * ui))
	add_child(_extras)
	_time_button = _button(_extras, "TIME: Day")
	_time_button.pressed.connect(func(): time_pressed.emit())
	_radio_button = _button(_extras, "RADIO: OFF")
	_radio_button.pressed.connect(func(): radio_pressed.emit())
	_vhs_button = _button(_extras, "VHS")
	_vhs_button.toggle_mode = true
	_vhs_button.pressed.connect(func(): vhs_pressed.emit())
	_rain_button = _button(_extras, "RAIN")
	_rain_button.toggle_mode = true
	_rain_button.pressed.connect(func(): weather_pressed.emit())
	bar.resized.connect(_place_extras)
	_extras.resized.connect(_place_extras)
	get_viewport().size_changed.connect(_place_extras)

	var credit := Label.new()
	credit.text = "© OpenStreetMap contributors · 3D buildings, aerial photo, terrain: GUGiK"
	credit.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	credit.grow_horizontal = Control.GROW_DIRECTION_BOTH
	credit.grow_vertical = Control.GROW_DIRECTION_BEGIN
	credit.position.y -= 6 * ui
	credit.add_theme_font_size_override("font_size", int(11 * ui))
	credit.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	credit.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	credit.add_theme_constant_override("outline_size", int(3 * ui))
	add_child(credit)

	_toast = _label(17, Color("#fbf7ee"))
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.position.y -= 34 * ui
	_toast.visible = false
	add_child(_toast)
	_toast_gloss = _label(13, Color("#c9c2d8"))
	_toast_gloss.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_gloss.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_gloss.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_gloss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_gloss.position.y -= 34 * ui
	_toast_gloss.visible = false
	add_child(_toast_gloss)
	_build_ticker()
	_build_mission_panels()
	_build_wallet()
	_build_perf()
	settings_panel = SettingsPanel.new()
	settings_panel.ui = ui
	settings_panel.inset_left = _inset_left
	settings_panel.inset_right = _inset_right
	add_child(settings_panel)
	_place_extras.call_deferred()


## TIME / RADIO / VHS go just left of the top buttons when they fit beside the
## info text, else in a second row under them (right-aligned).
func _place_extras() -> void:
	if _extras == null or _bar == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var gap := 8 * ui
	var w := _extras.get_combined_minimum_size().x
	var bar_left := screen.x - 16 * ui - _inset_right - _bar.get_combined_minimum_size().x
	# Room for "NOCNA WARSZAWA · prototype" (~250 px at 1.0) whatever the info says now.
	var info_right := _info.position.x + maxf(_info.get_combined_minimum_size().x, 262 * ui)
	_extras.size = _extras.get_combined_minimum_size()
	if bar_left - gap - w > info_right + gap:
		_extras_below = false
		_extras.position = Vector2(bar_left - gap - w, 12 * ui)
	else:
		_extras_below = true
		_extras.position = Vector2(screen.x - 16 * ui - _inset_right - w, 12 * ui + 44 * ui + gap)
	# The mission panels move down a row when the buttons take it.
	var panel_top := (66 + (52 if _extras_below else 0)) * ui
	if _status != null:
		_status.offset_top = panel_top
	if _card != null:
		_panel_top = panel_top / ui
		if not _card_bottom:
			_card.offset_top = panel_top
			_card.offset_bottom = panel_top
	if _pill != null:
		_pill.offset_top = panel_top


func set_time_name(time_name: String) -> void:
	_time_button.text = "TIME: " + time_name
	_place_extras.call_deferred()


func set_radio_name(station_name: String) -> void:
	_radio_button.text = "RADIO: " + station_name
	_place_extras.call_deferred()


func set_vhs(on: bool) -> void:
	_vhs_button.set_pressed_no_signal(on)


func set_weather(raining: bool) -> void:
	_rain_button.set_pressed_no_signal(raining)


## The performance overlay: a dark panel with small monospace lines and the QUALITY
## button under them, top left beside the minimap.
func _build_perf() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.78)
	style.set_corner_radius_all(int(6 * ui))
	style.set_content_margin_all(8 * ui)
	_perf = PanelContainer.new()
	_perf.add_theme_stylebox_override("panel", style)
	# Right of the minimap (16 + 144 px wide), level with its top.
	_perf.position = Vector2((16 + 144 + 12) * ui + _inset_left, 70 * ui)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(6 * ui))
	_perf.add_child(rows)
	_perf_label = _label(13, Color("#d8f5d0"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_perf_label.add_theme_font_override("font", mono)
	rows.add_child(_perf_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", int(8 * ui))
	rows.add_child(buttons)
	_quality_button = _button(buttons, "QUALITY: High")
	_quality_button.pressed.connect(func(): quality_pressed.emit())
	# Loop 2b: a minute on the bench route, then the result card (main.gd).
	_button(buttons, "TEST · BENCH").pressed.connect(func(): bench_pressed.emit())
	_perf.visible = false
	add_child(_perf)


func show_perf(on: bool) -> void:
	_perf.visible = on


func set_perf(text: String) -> void:
	_perf_label.text = text


func perf_visible() -> bool:
	return _perf.visible


## Loop 2b: the bench's result: a card in the middle with the numbers (monospace, the same
## text as the clipboard's), KOPIUJ · COPY and ZAMKNIJ · CLOSE, sized in points like the
## settings panel (44 pt buttons).
func show_bench_card(text: String) -> void:
	_bench_text = text
	if _bench_card == null:
		_build_bench_card()
	_bench_label.text = text
	_bench_copy.get_child(0).get_child(0).text = "KOPIUJ"
	_bench_card.visible = true
	_fit_bench_card.call_deferred()


func hide_bench_card() -> void:
	if _bench_card != null:
		_bench_card.visible = false


func bench_card_visible() -> bool:
	return _bench_card != null and _bench_card.visible


func _points() -> float:
	var h := get_viewport().get_visible_rect().size.y
	var pt := h / 390.0
	if OS.has_feature("mobile"):
		pt = maxf(DisplayServer.screen_get_scale(), 1.0)
	return pt


func _build_bench_card() -> void:
	var pt := _points()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.95)
	style.set_corner_radius_all(int(10 * pt))
	style.set_content_margin_all(12 * pt)
	style.border_width_left = int(3 * pt)
	style.border_color = Color("#5fd4ff")
	_bench_card = PanelContainer.new()
	_bench_card.add_theme_stylebox_override("panel", style)
	_bench_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(8 * pt))
	_bench_card.add_child(rows)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", int(10 * pt))
	rows.add_child(head)
	var title := Label.new()
	title.text = "TEST WYDAJNOŚCI"
	title.add_theme_font_size_override("font_size", int(17 * pt))
	title.add_theme_color_override("font_color", Color("#ffd23f"))
	head.add_child(title)
	var sub := Label.new()
	sub.text = "Benchmark · wklej to w czacie, paste it into the chat"
	sub.add_theme_font_size_override("font_size", int(12 * pt))
	sub.add_theme_color_override("font_color", Color("#c9c2d8"))
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(sub)
	_bench_label = Label.new()
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_bench_label.add_theme_font_override("font", mono)
	_bench_label.add_theme_font_size_override("font_size", int(10 * pt))
	_bench_label.add_theme_color_override("font_color", Color("#d8f5d0"))
	rows.add_child(_bench_label)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", int(10 * pt))
	buttons.alignment = BoxContainer.ALIGNMENT_END
	rows.add_child(buttons)
	_bench_copy = _card_button(buttons, "KOPIUJ", "Copy", pt)
	_bench_copy.pressed.connect(func():
		DisplayServer.clipboard_set(_bench_text)
		_bench_copy.get_child(0).get_child(0).text = "SKOPIOWANE"
		print("bench: result copied to the clipboard"))
	_card_button(buttons, "ZAMKNIJ", "Close", pt).pressed.connect(hide_bench_card)
	_bench_card.visible = false
	add_child(_bench_card)
	get_viewport().size_changed.connect(_fit_bench_card)


## A 44 pt button with the Polish word over the English one.
func _card_button(parent: Node, pl: String, en: String, pt: float) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(110, 44) * pt
	var words := VBoxContainer.new()
	words.set_anchors_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in [[pl, 15, Color("#fbf7ee")], [en, 11, Color("#c9c2d8")]]:
		var l := Label.new()
		l.text = t[0]
		l.add_theme_font_size_override("font_size", int(t[1] * pt))
		l.add_theme_color_override("font_color", t[2])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
	b.add_child(words)
	parent.add_child(b)
	return b


func _fit_bench_card() -> void:
	if _bench_card == null or not _bench_card.visible:
		return
	var screen := get_viewport().get_visible_rect().size
	_bench_card.scale = Vector2.ONE
	_bench_card.reset_size()
	var need := _bench_card.get_combined_minimum_size()
	var room := Vector2(screen.x - _inset_left - _inset_right - 16 * ui, screen.y - 16 * ui)
	var k := minf(1.0, minf(room.x / maxf(need.x, 1.0), room.y / maxf(need.y, 1.0)))
	_bench_card.scale = Vector2(k, k)
	_bench_card.size = need
	_bench_card.position = Vector2(_inset_left + (screen.x - _inset_left - _inset_right - need.x * k) * 0.5, (screen.y - need.y * k) * 0.5)


func set_quality_name(quality_name: String) -> void:
	_quality_button.text = "QUALITY: " + quality_name


## The now-playing panel: bottom left, above the credit line, out of the way of
## the brake and the race button.
func _build_ticker() -> void:
	_ticker_style = StyleBoxFlat.new()
	_ticker_style.bg_color = Color(0.06, 0.02, 0.12, 0.86)
	_ticker_style.set_corner_radius_all(int(6 * ui))
	_ticker_style.content_margin_left = 14 * ui
	_ticker_style.content_margin_right = 14 * ui
	_ticker_style.content_margin_top = 6 * ui
	_ticker_style.content_margin_bottom = 6 * ui
	_ticker_style.border_width_left = int(4 * ui)
	_ticker_style.border_color = Color("#ff5fc8")
	_ticker = PanelContainer.new()
	_ticker.add_theme_stylebox_override("panel", _ticker_style)
	_ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(2 * ui))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker.add_child(rows)
	_ticker_label = _label(15, Color("#fbf7ee"))
	rows.add_child(_ticker_label)
	_ticker_sub = _label(13, Color("#d9d2e6"))
	rows.add_child(_ticker_sub)
	_ticker.visible = false
	add_child(_ticker)


## Shows a line on the now-playing ticker for a few seconds: the radio's station
## changes, and the radio host's lines with an English subtitle (held longer and
## wrapped to a readable width).
func ticker(text: String, colour: Color, subtitle := "") -> void:
	var font := ThemeDB.fallback_font
	var room := minf(620.0 * ui, get_viewport().get_visible_rect().size.x * 0.62)
	var long := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * ui)).x > room \
			or font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * ui)).x > room
	for l in [_ticker_label, _ticker_sub]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if long else TextServer.AUTOWRAP_OFF
		l.custom_minimum_size.x = room if long else 0.0
	_ticker_label.text = text
	_ticker_label.add_theme_color_override("font_color", colour.lerp(Color.WHITE, 0.35))
	_ticker_sub.text = subtitle
	_ticker_sub.visible = subtitle != ""
	_ticker_style.border_color = colour
	_ticker.reset_size()
	_ticker.visible = true
	_ticker_hold = 4.5 if subtitle == "" else 9.0
	_ticker_left = _ticker_hold
	_place_ticker(0.0)


func _place_ticker(slide: float) -> void:
	var screen := get_viewport().get_visible_rect().size
	var size := _ticker.get_combined_minimum_size()
	var x := 16 * ui + _inset_left
	var y := screen.y - 40 * ui - size.y
	# A side job's card at the bottom centre: the ticker steps up above it if they'd touch.
	if _card != null and _card.visible and _card_bottom:
		var card := _card.get_global_rect()
		if x + size.x > card.position.x - 8 * ui:
			y = minf(y, card.position.y - 8 * ui - size.y)
	_ticker.position = Vector2(lerpf(x, -size.x - 8 * ui, slide), y)


func _label(font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", int(font_size * ui))
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color("#1d1b19"))
	l.add_theme_constant_override("outline_size", int(4 * ui))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The call card and the pill sit at the top centre under the buttons; the running
## mission's status sits at the top right, so it never hides a target straight ahead.
func _build_mission_panels() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.09, 0.11, 0.84)
	panel_style.set_corner_radius_all(int(10 * ui))
	panel_style.set_content_margin_all(12 * ui)
	panel_style.border_color = Color(1, 1, 1, 0.12)
	panel_style.set_border_width_all(maxi(1, int(ui)))

	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", panel_style)
	_top_centre(_card, 440)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", int(8 * ui))
	_card.add_child(box)
	_card_title = _label(17, Color("#ffd23f"))
	box.add_child(_card_title)
	_card_body = _label(15, Color("#fbf7ee"))
	_card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_body.custom_minimum_size.x = 416 * ui
	box.add_child(_card_body)
	_card_buttons = HBoxContainer.new()
	_card_buttons.add_theme_constant_override("separation", int(8 * ui))
	box.add_child(_card_buttons)
	_card.visible = false
	add_child(_card)

	_status = PanelContainer.new()
	_status.add_theme_stylebox_override("panel", panel_style)
	_status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_status.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_status.custom_minimum_size.x = 360 * ui
	_status.offset_left = -(360 + 16) * ui - _inset_right
	_status.offset_right = -16 * ui - _inset_right
	_status.offset_top = 66 * ui
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(2 * ui))
	_status.add_child(rows)
	var head := HBoxContainer.new()
	rows.add_child(head)
	_status_title = _label(14, Color("#ffd23f"))
	_status_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_title.clip_text = true
	_status_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(_status_title)
	_status_badge = _label(20, Color.WHITE)
	head.add_child(_status_badge)
	var abort := Button.new()
	abort.text = "✕"
	abort.focus_mode = Control.FOCUS_NONE
	abort.custom_minimum_size = Vector2(34, 28) * ui
	abort.add_theme_font_size_override("font_size", int(13 * ui))
	abort.pressed.connect(func(): abort_pressed.emit())
	head.add_child(abort)
	_status_clock = _label(24, Color.WHITE)
	rows.add_child(_status_clock)
	_status_icons = Control.new()
	_status_icons.custom_minimum_size.y = 56 * ui
	_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icons.draw.connect(_draw_status_icons)
	_status_icons.visible = false
	rows.add_child(_status_icons)
	_status_hint = _label(14, Color("#e9e4d8"))
	rows.add_child(_status_hint)
	_status_track = Control.new()
	_status_track.custom_minimum_size.y = 5 * ui
	_status_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(_status_track)
	_status_bar = ColorRect.new()
	_status_bar.size = Vector2(0, 5 * ui)
	_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_track.add_child(_status_bar)
	_status.visible = false
	add_child(_status)

	_pill = _button(self, "RESCUE CALLS")
	_top_centre(_pill, 180)
	_pill.pressed.connect(func(): pill_pressed.emit())
	_pill.visible = false

	_challenge = _button(self, "FLASH LIGHTS")
	_challenge.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_challenge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_challenge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_challenge.custom_minimum_size = Vector2(380, 54) * ui
	_challenge.offset_left = -190 * ui
	_challenge.offset_right = 190 * ui
	_challenge.offset_top = -(64 + 54) * ui
	_challenge.offset_bottom = -64 * ui
	_challenge.add_theme_font_size_override("font_size", int(17 * ui))
	_challenge.pressed.connect(func(): challenge_pressed.emit())
	_challenge.visible = false

	_banner = _label(64, Color.WHITE)
	_banner.add_theme_constant_override("outline_size", int(12 * ui))
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.offset_top = -170 * ui
	_banner.offset_bottom = -90 * ui
	_banner.visible = false
	add_child(_banner)

	# The target pointer draws above the panels.
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_target)
	add_child(_overlay)


func _top_centre(c: Control, width: float) -> void:
	c.set_anchors_preset(Control.PRESET_CENTER_TOP)
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH
	c.custom_minimum_size.x = width * ui
	c.offset_left = -width * 0.5 * ui
	c.offset_right = width * 0.5 * ui
	c.offset_top = 66 * ui


## A call or a result: title, text, and up to three buttons (emit card_pressed(index)).
## `bottom` puts it at the bottom centre instead of the top.
func show_card(title: String, body: String, buttons: PackedStringArray, accent: Color, bottom := false) -> void:
	_card_bottom = bottom
	_card.anchor_top = 1.0 if bottom else 0.0
	_card.anchor_bottom = _card.anchor_top
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	var y := -44.0 * ui if bottom else _panel_top * ui
	_card.offset_top = y
	_card.offset_bottom = y
	_card_title.text = title
	_card_title.add_theme_color_override("font_color", accent)
	_card_body.text = body
	for b in _card_buttons.get_children():
		b.queue_free()
	for i in buttons.size():
		var b := _button(_card_buttons, buttons[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): card_pressed.emit(i))
	_card.visible = true
	_status.visible = false
	_pill.visible = false


func hide_card() -> void:
	_card.visible = false


## The running mission or race: where to, the clock, the distance, a hint, how
## much of the hold-still is done (0..1), and an optional badge (race position).
func show_status(title: String, clock: String, distance: String, hint: String, progress: float, accent: Color,
		badge := "", icons := {}) -> void:
	if icons != _icons:
		_icons = icons
		_status_icons.visible = not icons.is_empty()
		_status_icons.queue_redraw()
	_status_badge.text = badge
	_status_badge.visible = badge != ""
	_status_badge.add_theme_color_override("font_color", Color("#56d68a") if badge == "1ST" else Color("#ffd23f"))
	_status_title.text = title
	_status_title.add_theme_color_override("font_color", accent)
	_status_clock.text = clock + "    " + distance
	_status_hint.text = hint
	_status_bar.color = accent
	_status_bar.size.x = _status_track.size.x * clampf(progress, 0.0, 1.0)
	_status.visible = true


func hide_status() -> void:
	_status.visible = false


func show_pill(text: String) -> void:
	_pill.text = text
	_pill.visible = true


func hide_pill() -> void:
	_pill.visible = false


## The button that challenges the rival in front (key L does the same).
func show_challenge(text: String, accent: Color) -> void:
	_challenge.text = text
	_challenge.add_theme_color_override("font_color", accent)
	_challenge.visible = true


func hide_challenge() -> void:
	_challenge.visible = false


## A big line across the middle of the screen: the race countdown.
func show_banner(text: String, colour: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", colour)
	_banner.visible = true


func hide_banner() -> void:
	_banner.visible = false


## Coloured dots on the minimap (the rivals), in map coordinates.
func set_minimap_dots(points: PackedVector2Array, colours: PackedColorArray) -> void:
	_mini_dots = points
	_mini_dot_colours = colours


## A short message near the bottom of the screen that fades after a few seconds.
## A short line at the bottom for 3 s. Loop 10a: with `gloss`, the Polish line sits above its
## English gloss (smaller, the sub-text colour).
func toast(text: String, gloss := "") -> void:
	_toast.text = text
	_toast.visible = true
	_toast_left = 3.0
	_toast_gloss.text = gloss
	_toast_gloss.visible = gloss != ""
	_toast.offset_bottom = _toast_gloss.offset_bottom - (_toast_gloss.get_combined_minimum_size().y if gloss != "" else 0.0)
	_toast.offset_top = _toast.offset_bottom - _toast.get_combined_minimum_size().y


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= dt
		_toast.modulate.a = clampf(_toast_left / 0.6, 0.0, 1.0)
		_toast.visible = _toast_left > 0.0
		_toast_gloss.modulate.a = _toast.modulate.a
		_toast_gloss.visible = _toast.visible and _toast_gloss.text != ""
	if _ticker_left > 0.0:
		_ticker_left -= dt
		# Slide in over the first 0.3 s, out over the last 0.4 s.
		var slide := maxf(clampf((_ticker_left - (_ticker_hold - 0.3)) / 0.3, 0.0, 1.0), clampf(1.0 - _ticker_left / 0.4, 0.0, 1.0))
		_place_ticker(slide * slide)
		_ticker.visible = _ticker_left > 0.0
	if _wallet_flash > 0.0:
		_wallet_flash -= dt
		_wallet.queue_redraw()
	if _note_left > 0.0:
		_note_left -= dt
		_note.modulate.a = clampf(_note_left / 0.6, 0.0, 1.0) * clampf((5.5 - _note_left) / 0.25, 0.0, 1.0)
		_note.visible = _note_left > 0.0
	if _info_left > 0.0:
		_info_left -= dt
		_info_card.modulate.a = clampf(_info_left / 0.6, 0.0, 1.0) * clampf((8.0 - _info_left) / 0.25, 0.0, 1.0)
		_info_card.visible = _info_left > 0.0
	if not _icons.is_empty() and _status.visible:
		_status_icons.queue_redraw()


## In the helicopter the brake gives way to climb and sink pads, and the vehicle
## button offers the car back.
func set_flying(on: bool) -> void:
	flying = on
	_vehicle_button.text = "CAR" if on else "HELI"
	brake = false
	_brake_index = -1
	gas = false
	_gas_index = -1
	climb = 0.0
	_climb_index = -1
	_pad.queue_redraw()


## The mission target as seen on screen (`at` in screen pixels); an arrow on the
## screen edge points to it when it's off screen.
func set_target(at: Vector2, label: String, colour: Color, show: bool) -> void:
	if show or _target_visible:
		_overlay.queue_redraw()
	_target_visible = show
	_target_at = at
	_target_label = label
	_target_colour = colour


func set_minimap_target(xz: Vector2, colour: Color) -> void:
	_mini_target = xz
	_mini_target_colour = colour


## The panels on screen now (the speech bubbles keep clear of them).
func panel_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c in [_card, _status, _pill, _challenge]:
		if c.visible:
			out.append((c as Control).get_global_rect())
	return out


## Touches on the mission panels belong to their buttons, not to the stick.
func _over_panel(p: Vector2) -> bool:
	for c in [_card, _status, _pill, _challenge, _extras, _perf, _gear, _bench_card]:
		if c != null and c.visible and (c as Control).get_global_rect().has_point(p):
			return true
	return false


func setup_minimap(data: Dictionary) -> void:
	_mini_radius = 72.0 * ui
	_minimap = Control.new()
	_minimap.position = Vector2(16 * ui + _inset_left, 70 * ui)
	_minimap.size = Vector2.ONE * _mini_radius * 2.0
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.draw.connect(func(): _minimap.draw_circle(Vector2.ONE * _mini_radius, _mini_radius, Color(0.93, 0.9, 0.83, 0.92)))
	add_child(_minimap)
	_mini_mesh = _minimap_mesh(data)
	_mini_clip = ShaderMaterial.new()
	_mini_clip.shader = Shader.new()
	_mini_clip.shader.code = MINI_CLIP
	_mini_content = Node2D.new()
	_mini_content.material = _mini_clip
	_mini_content.draw.connect(func(): _mini_content.draw_mesh(_mini_mesh, null))
	_minimap.add_child(_mini_content)
	_mini_overlay = Control.new()
	_mini_overlay.size = _minimap.size
	_mini_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_overlay.draw.connect(_draw_minimap_overlay)
	_minimap.add_child(_mini_overlay)


func update_minimap(car_xz: Vector2, car_yaw: float, view_yaw: float) -> void:
	if _minimap == null:
		return
	var s := MINI_SCALE * ui
	_mini_car = car_xz
	_mini_yaw = view_yaw
	_mini_content.rotation = view_yaw
	_mini_content.position = Vector2.ONE * _mini_radius - (car_xz * s).rotated(view_yaw)
	# The clip is in screen pixels (the HUD layer is not moved or scaled).
	_mini_clip.set_shader_parameter("centre", _minimap.global_position + Vector2.ONE * _mini_radius)
	_mini_clip.set_shader_parameter("radius", _mini_radius)
	_car_dir = Vector2(-sin(car_yaw), -cos(car_yaw)).rotated(view_yaw)
	_north = Vector2(0, -1).rotated(view_yaw)
	_mini_overlay.queue_redraw()


## The minimap's map as one mesh (loop 2b), in the order it was drawn before: parks and
## water, then the streets (draw_polyline's strip: each point pushed out half the width
## along the mean of its two segments' normals), the map's edge and the Palace's dot.
func _minimap_mesh(data: Dictionary) -> ArrayMesh:
	var s := MINI_SCALE * ui
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var tri := func(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
		verts.append_array([a, b, c])
		cols.append_array([col, col, col])
	for a in data["areas"]:
		var colour: Color
		match String(a["k"]):
			"park", "grass", "pitch":
				colour = Color("#a9cf7c")
			"water":
				colour = Color("#7fb8de")
			_:
				continue
		var pts := PackedVector2Array()
		var flat: Array = a["p"]
		for i in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[i], flat[i + 1]) * s)
		if pts.size() < 3:
			continue
		var ids := Geometry2D.triangulate_polygon(pts)
		for k in range(0, ids.size() - 2, 3):
			tri.call(pts[ids[k]], pts[ids[k + 1]], pts[ids[k + 2]], colour)
	var strip := func(pts: PackedVector2Array, col: Color, width: float) -> void:
		var prev := Vector2.ZERO
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in pts.size():
			var t := prev
			if i < pts.size() - 1:
				t = (pts[i + 1] - pts[i]).normalized().orthogonal()
				if i == 0:
					prev = t
			var off := (t + prev).normalized() * width * 0.5
			left.append(pts[i] + off)
			right.append(pts[i] - off)
			prev = t
		for i in pts.size() - 1:
			tri.call(left[i], right[i], left[i + 1], col)
			tri.call(right[i], right[i + 1], left[i + 1], col)
	for r in data["roads"]:
		var pts := PackedVector2Array()
		var flat: Array = r["p"]
		for i in range(0, flat.size() - 1, 2):
			pts.append(Vector2(flat[i], flat[i + 1]) * s)
		if pts.size() < 2:
			continue
		var minor: bool = r["k"] in ["service", "living_street"]
		strip.call(pts, Color("#8d8f94") if minor else Color("#5b5e64"), maxf(1.0, float(r["w"]) * s))
	var b: Array = data["bounds"]
	var lo := Vector2(b[0], b[1]) * s
	var hi := Vector2(b[2], b[3]) * s
	strip.call(PackedVector2Array([lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y), lo]), Color("#6a503b"), 2.0 * ui)
	for l in data.get("landmarks", []):
		if l["name"] == "Pałac Kultury i Nauki":
			var flat: Array = l["p"]
			var centre := Vector2.ZERO
			for i in range(0, flat.size() - 1, 2):
				centre += Vector2(flat[i], flat[i + 1])
			centre = centre / (flat.size() / 2.0) * s
			for k in 24:
				tri.call(centre, centre + Vector2.from_angle(TAU * k / 24.0) * 4.5 * ui,
						centre + Vector2.from_angle(TAU * (k + 1) / 24.0) * 4.5 * ui, Color("#c9a24a"))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_2D_VERTICES)
	return mesh


func _draw_minimap_overlay() -> void:
	var t0 := Time.get_ticks_usec()
	_paint_minimap_overlay()
	spent_usec += Time.get_ticks_usec() - t0


func _paint_minimap_overlay() -> void:
	var centre := Vector2.ONE * _mini_radius
	var o := _mini_overlay
	# Side-job places: small blinking squares, pinned to the rim up to 700 m away.
	var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.006)
	for i in _mini_pois.size():
		if _mini_pois[i].distance_to(_mini_car) > 700.0:
			continue
		var r := ((_mini_pois[i] - _mini_car) * MINI_SCALE * ui).rotated(_mini_yaw)
		var far := r.length() > _mini_radius - 8.0 * ui
		r = r.limit_length(_mini_radius - 8.0 * ui)
		var half := (3.0 if far else 4.5) * ui
		o.draw_rect(Rect2(centre + r - Vector2.ONE * (half + 1.5 * ui), Vector2.ONE * (half + 1.5 * ui) * 2.0), Color("#1d1b19"))
		o.draw_rect(Rect2(centre + r - Vector2.ONE * half, Vector2.ONE * half * 2.0), Color(_mini_poi_colours[i], blink))
	for i in _mini_dots.size():
		# Rivals within the minimap's reach; the rest would crowd the rim.
		var r := ((_mini_dots[i] - _mini_car) * MINI_SCALE * ui).rotated(_mini_yaw)
		if r.length() < _mini_radius - 6.0 * ui:
			o.draw_circle(centre + r, 4.5 * ui, Color("#1d1b19"))
			o.draw_circle(centre + r, 3.2 * ui, _mini_dot_colours[i])
	if _mini_target != Vector2.INF:
		# The mission target, pinned to the rim when it's beyond the map's reach.
		var t := ((_mini_target - _mini_car) * MINI_SCALE * ui).rotated(_mini_yaw)
		t = t.limit_length(_mini_radius - 8.0 * ui)
		o.draw_circle(centre + t, 6.0 * ui, Color("#1d1b19"))
		o.draw_circle(centre + t, 4.5 * ui, _mini_target_colour)
	var d := _car_dir.normalized()
	var side := Vector2(-d.y, d.x)
	var tip := centre + d * 9.0 * ui
	o.draw_colored_polygon(PackedVector2Array([tip, centre - d * 6.0 * ui + side * 6.0 * ui,
			centre - d * 3.0 * ui, centre - d * 6.0 * ui - side * 6.0 * ui]), Color("#d8432f"))
	o.draw_arc(centre, _mini_radius - 1.5 * ui, 0, TAU, 64, Color(0.17, 0.15, 0.13, 0.85), 3.0 * ui)
	var font := ThemeDB.fallback_font
	var fs := int(12 * ui)
	var n := centre + _north * (_mini_radius - 12.0 * ui)
	o.draw_string(font, n + Vector2(-fs * 0.3, fs * 0.35), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#2a2622"))


func set_car_marker(at: Vector2, show: bool) -> void:
	if show != _marker_visible or (show and at.distance_to(_marker) > 0.5):
		_marker = at
		_marker_visible = show
		_pad.queue_redraw()


func set_info(text: String) -> void:
	_info.text = text


func set_style_name(style_name: String) -> void:
	_style_button.text = "STYLE: " + style_name


func set_camera_name(camera_name: String) -> void:
	_camera_button.text = "CAM: " + camera_name


## Side-job places on the minimap (map coordinates), drawn as blinking squares.
func set_minimap_pois(points: PackedVector2Array, colours: PackedColorArray) -> void:
	_mini_pois = points
	_mini_poi_colours = colours


# --- the wallet and the note card ------------------------------------------------------------

## The wallet sits under the minimap: a gold coin and the złoty, a pink star and the
## respect; a payment floats up from it as "+54 zł". The note card (an easter egg
## found) goes under it.
func _build_wallet() -> void:
	_wallet = Control.new()
	_wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallet.position = Vector2(16 * ui + _inset_left, (70 + 152) * ui)
	_wallet.size = Vector2(240, 30) * ui
	_wallet.draw.connect(_draw_wallet)
	add_child(_wallet)
	_note_style = StyleBoxFlat.new()
	_note_style.bg_color = Color(0.06, 0.02, 0.12, 0.88)
	_note_style.set_corner_radius_all(int(8 * ui))
	_note_style.set_content_margin_all(10 * ui)
	_note_style.border_width_left = int(4 * ui)
	_note_style.border_color = Color("#ff4fd8")
	_note = PanelContainer.new()
	_note.add_theme_stylebox_override("panel", _note_style)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.position = Vector2(16 * ui + _inset_left, (70 + 152 + 36) * ui)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(2 * ui))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.add_child(rows)
	_note_title = _label(14, Color("#ff4fd8"))
	rows.add_child(_note_title)
	_note_body = _label(14, Color("#fbf7ee"))
	rows.add_child(_note_body)
	_note.visible = false
	add_child(_note)

	var info_style := _note_style.duplicate() as StyleBoxFlat
	info_style.border_color = Color("#ffd23f")
	_info_card = PanelContainer.new()
	_info_card.add_theme_stylebox_override("panel", info_style)
	_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_card.position = _note.position
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", int(3 * ui))
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_card.add_child(lines)
	_info_title = _label(15, Color("#ffd23f"))
	lines.add_child(_info_title)
	_info_pl = _label(14, Color("#fbf7ee"))
	_info_en = _label(12, Color("#c9c2d8"))
	for l in [_info_pl, _info_en]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 330 * ui
		lines.add_child(l)
	_info_card.visible = false
	add_child(_info_card)


func set_wallet(zl: int, respect: int, gained := 0) -> void:
	_wallet_zl = zl
	_wallet_respect = respect
	if gained != 0:
		_wallet_gain = gained
		_wallet_flash = 2.2
	_wallet.queue_redraw()


func _draw_wallet() -> void:
	var w := _wallet
	var font := ThemeDB.fallback_font
	var fs := int(16 * ui)
	var ink := Color("#1d1b19")
	var y := 15.0 * ui
	# A coin with a "zł" stamp.
	var coin := Vector2(10.0 * ui, y)
	w.draw_circle(coin, 9.5 * ui, ink)
	w.draw_circle(coin, 8.0 * ui, Color("#f2c12e"))
	w.draw_circle(coin, 5.5 * ui, Color("#d9a21f"))
	var x := 24.0 * ui
	var money := _money(_wallet_zl)
	var base := Vector2(x, y + fs * 0.36)
	w.draw_string_outline(font, base, money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(5 * ui), ink)
	w.draw_string(font, base, money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffe27a"))
	x += font.get_string_size(money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0 * ui
	# A five-pointed star for respect.
	var star := PackedVector2Array()
	var c := Vector2(x + 8.0 * ui, y)
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		star.append(c + Vector2(cos(a), sin(a)) * (9.5 if k % 2 == 0 else 4.2) * ui)
	var outline := PackedVector2Array()
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		outline.append(c + Vector2(cos(a), sin(a)) * (11.5 if k % 2 == 0 else 5.6) * ui)
	w.draw_colored_polygon(outline, ink)
	w.draw_colored_polygon(star, Color("#ff4fd8"))
	var resp := str(_wallet_respect)
	base = Vector2(x + 21.0 * ui, y + fs * 0.36)
	w.draw_string_outline(font, base, resp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(5 * ui), ink)
	w.draw_string(font, base, resp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffd0f4"))
	if _wallet_flash > 0.0:
		# The payment floats up and fades.
		var t := 1.0 - _wallet_flash / 2.2
		var gain := ("+" if _wallet_gain > 0 else "") + _money(_wallet_gain)
		var at := Vector2(24.0 * ui, y - 8.0 * ui - t * 26.0 * ui)
		var a := clampf(_wallet_flash / 0.6, 0.0, 1.0)
		w.draw_string_outline(font, at, gain, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(5 * ui), Color(ink, a))
		w.draw_string(font, at, gain, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.55, 1.0, 0.6, a))


static func _money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out + " zł"


## A small card under the wallet for a few seconds (an easter egg found).
func show_note(title: String, body: String, colour: Color) -> void:
	_note_title.text = title
	_note_title.add_theme_color_override("font_color", colour.lerp(Color.WHITE, 0.2))
	_note_body.text = body
	_note_style.border_color = colour
	_note.reset_size()
	_note.visible = true
	_info_card.visible = false
	_info_left = 0.0
	_note.modulate.a = 0.0
	_note_left = 5.5


## v0.8: a landmark's info card (it was tapped): the name, a Polish line or two and the
## English under it. It takes the note card's place for eight seconds.
func show_info(title: String, polish: String, english: String) -> void:
	_info_title.text = title
	_info_pl.text = polish
	_info_en.text = english
	_note.visible = false
	_note_left = 0.0
	_info_card.reset_size()
	_info_card.visible = true
	_info_card.modulate.a = 0.0
	_info_left = 8.0


# --- the status panel's pictures --------------------------------------------------------------

## {"heat": 0..1}: a wrapped kebab with steam that fades as it cools. {"jars": [intact,
## total], "shake": 0..1}: a row of mum's jars, the broken ones as shards, rattling
## when one is close to breaking.
func _draw_status_icons() -> void:
	var c := _status_icons
	var h := c.size.y
	var ink := Color("#1d1b19")
	if _icons.has("heat"):
		var heat: float = _icons["heat"]
		var x := 6.0 * ui
		var u := ui * 1.5
		# The kebab: a wrap in foil, a cone with the meat and salad showing at the top.
		var foil := PackedVector2Array([Vector2(x + 8 * u, h - 2 * u), Vector2(x + 1 * u, h - 14 * u), Vector2(x + 15 * u, h - 14 * u)])
		c.draw_colored_polygon(foil, Color("#e8c48a").lerp(Color("#b9c6d6"), clampf(1.0 - heat * 1.6, 0.0, 1.0)))
		c.draw_rect(Rect2(Vector2(x + 1 * u, h - 16 * u), Vector2(14 * u, 3 * u)), Color("#c9ced6"))
		c.draw_rect(Rect2(Vector2(x + 3 * u, h - 19 * u), Vector2(10 * u, 3 * u)), Color("#7a4a2a"))
		c.draw_rect(Rect2(Vector2(x + 5 * u, h - 20.5 * u), Vector2(3 * u, 1.5 * u)), Color("#4f9e3f"))
		# Steam: three wavy wisps rising from it, shorter and fainter as it cools.
		var t := Time.get_ticks_msec() * 0.003
		var a := clampf((heat - 0.1) / 0.5, 0.0, 1.0)
		var rise := (h - 24 * u) * (0.35 + heat * 0.65)
		for j in 3:
			var pts := PackedVector2Array()
			var sx := x + (3 + j * 5) * u
			for q in 9:
				var f := q / 8.0
				pts.append(Vector2(sx + sin(t * 2.0 + j * 2.1 + f * 6.0) * 1.8 * u, h - 22 * u - f * rise))
			if a > 0.02:
				c.draw_polyline(pts, Color(1, 1, 1, a * (0.9 - j * 0.12)), 2.0 * ui)
		# A heat bar beside it, warm to cold.
		var bar := Rect2(Vector2(x + 24 * u, h * 0.5 - 4 * ui), Vector2(c.size.x - x - 26 * u, 8 * ui))
		c.draw_rect(bar.grow(1.5 * ui), ink)
		c.draw_rect(bar, Color(0.2, 0.22, 0.28))
		var hot := Color("#ff5a2a").lerp(Color("#ffd23f"), 0.3)
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(heat, 0.0, 1.0), bar.size.y)), Color("#7fb8de").lerp(hot, clampf(heat * 1.4, 0.0, 1.0)))
	elif _icons.has("jars"):
		var jars: Array = _icons["jars"]
		var intact: int = jars[0]
		var total: int = jars[1]
		var shake: float = _icons.get("shake", 0.0)
		var t := Time.get_ticks_msec() * 0.05
		var y0 := h * 0.5 - 7.0 * ui
		for k in total:
			var x := (6 + k * 24) * ui
			var jiggle := Vector2(sin(t + k * 2.1), cos(t * 1.3 + k)) * shake * shake * 2.2 * ui if k < intact else Vector2.ZERO
			var body := Rect2(Vector2(x, y0) + jiggle, Vector2(16 * ui, 20 * ui))
			if k < intact:
				c.draw_rect(body.grow(1.5 * ui), ink)
				c.draw_rect(body, Color("#d9a441"))
				c.draw_rect(Rect2(body.position + Vector2(2 * ui, 7 * ui), Vector2(12 * ui, 7 * ui)), Color("#f4ead2"))
				c.draw_rect(Rect2(body.position + Vector2(-1 * ui, -5 * ui), Vector2(18 * ui, 5 * ui)), Color("#c8282a"))
			else:
				# Shards and a puddle.
				c.draw_rect(Rect2(Vector2(x - 2 * ui, y0 + 16 * ui), Vector2(20 * ui, 4 * ui)), Color("#a0663a", 0.8))
				for s in [Vector2(1, 8), Vector2(8, 4), Vector2(12, 10)]:
					var p: Vector2 = Vector2(x, y0) + s * ui
					c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(4, 6) * ui, p + Vector2(-2, 6) * ui]), Color("#c9d6dc"))
		var label := "%d/%d" % [intact, total]
		var font := ThemeDB.fallback_font
		var fs := int(16 * ui)
		var at := Vector2((10 + total * 24) * ui, h * 0.5 + fs * 0.36)
		c.draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(4 * ui), ink)
		c.draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if intact == total else Color("#ffb05a"))


func _button(parent: Node, label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(56, 44) * ui
	b.add_theme_font_size_override("font_size", int(15 * ui))
	parent.add_child(b)
	return b


func _brake_centre() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	if scheme == CLASSIC:
		# Left of GAS and a little lower, so the thumb rolls from one to the other.
		return Vector2(size.x - 262 * ui - _inset_right, size.y - 92 * ui)
	return Vector2(size.x - 110 * ui - _inset_right, size.y - 110 * ui)


## Loop 2a: the GAS pedal (Classic), where BRAKE is in the other schemes.
func _gas_centre() -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return Vector2(size.x - 110 * ui - _inset_right, size.y - 110 * ui)


## The pedal radii for touches (a little larger than drawn).
func _brake_reach() -> float:
	return (62.0 if scheme == CLASSIC else 75.0) * ui


func _on_pedals(p: Vector2) -> bool:
	if flying:
		return false
	return p.distance_to(_brake_centre()) < _brake_reach() or (scheme == CLASSIC and p.distance_to(_gas_centre()) < 75 * ui)


## Loop 2a: the on-screen controls for a control scheme (drive_controls.gd).
func set_scheme(s: int) -> void:
	scheme = s
	gas = false
	_gas_index = -1
	brake = false
	_brake_index = -1
	_pad.queue_redraw()


## True while the stick's (or steering strip's) finger is down.
func stick_active() -> bool:
	return _stick_index != -1


## Loop 2a, for screenshots and replays (--stick=x,y --pedal=gas|brake): hold the stick at a
## deflection with its centre at `origin` (screen pixels), and a pedal.
func hold_stick(origin: Vector2, v: Vector2) -> void:
	_stick_index = 99
	_stick_origin = origin
	var radius := 70.0 * ui
	_stick_point = origin + (Vector2(v.x, 0.0) if scheme == CLASSIC else v) * radius
	stick = Vector2(v.x, 0.0) if scheme == CLASSIC else v
	_pad.queue_redraw()


func hold_pedal(which: String) -> void:
	if which == "gas":
		_gas_index = 98
		gas = true
	elif which == "brake":
		_brake_index = 97
		brake = true
	_pad.queue_redraw()


## Lets go of everything held (the settings panel opened over the game).
func release_all() -> void:
	_stick_index = -1
	stick = Vector2.ZERO
	_brake_index = -1
	brake = false
	_gas_index = -1
	gas = false
	_climb_index = -1
	climb = 0.0
	_free_touches.clear()
	_taps.clear()
	_pad.queue_redraw()


func open_settings(state: Dictionary) -> void:
	release_all()
	# Above everything added to the HUD since (the minimap, the bubbles).
	move_child(settings_panel, -1)
	settings_panel.open(state)


func settings_open() -> bool:
	return settings_panel != null and settings_panel.is_open()


const _UP_DOWN := [1, -1]


## The helicopter's climb (+1) and sink (-1) pads, stacked where the brake is.
func _climb_centre(direction: int) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return Vector2(size.x - 110 * ui - _inset_right, size.y - (205 if direction > 0 else 90) * ui)


func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if settings_open():
		return  # the panel's buttons take every touch; nothing steers under it
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		# Three fingers down together toggle the performance overlay.
		if touch.pressed:
			_fingers[touch.index] = Time.get_ticks_msec()
			if _fingers.size() == 3 and Time.get_ticks_msec() - int(_fingers.values().min()) < 400:
				perf_gesture.emit()
		else:
			_fingers.erase(touch.index)
		_track_tap(touch)
		if touch.pressed:
			if _over_panel(touch.position):
				pass  # a mission button takes it
			elif flying and (touch.position.distance_to(_climb_centre(1)) < 56 * ui
					or touch.position.distance_to(_climb_centre(-1)) < 56 * ui):
				_climb_index = touch.index
				climb = 1.0 if touch.position.distance_to(_climb_centre(1)) < touch.position.distance_to(_climb_centre(-1)) else -1.0
			elif not flying and scheme == CLASSIC and touch.position.distance_to(_gas_centre()) < 75 * ui:
				_gas_index = touch.index
				gas = true
			elif not flying and touch.position.distance_to(_brake_centre()) < _brake_reach():
				_brake_index = touch.index
				brake = true
			elif touch.position.x < size.x * 0.6 and touch.position.y > 80 * ui and _stick_index == -1:
				_stick_index = touch.index
				_stick_origin = touch.position
				_stick_point = touch.position
				stick = Vector2.ZERO
			elif touch.position.y > 80 * ui:
				_free_touches[touch.index] = touch.position
				_pinch_distance = _pinch_span()
		else:
			if touch.index == _stick_index:
				_stick_index = -1
				stick = Vector2.ZERO
			if touch.index == _brake_index:
				_brake_index = -1
				brake = false
			if touch.index == _gas_index:
				_gas_index = -1
				gas = false
			if touch.index == _climb_index:
				_climb_index = -1
				climb = 0.0
			_free_touches.erase(touch.index)
			_pinch_distance = _pinch_span()
		_pad.queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _taps.has(drag.index) and drag.position.distance_to(_taps[drag.index][0]) > 16 * ui:
			_taps.erase(drag.index)  # a drag (steering, a pinch), not a tap
		if _free_touches.has(drag.index):
			_free_touches[drag.index] = drag.position
			var span := _pinch_span()
			if span > 0.0 and _pinch_distance > 0.0:
				pinched.emit(span / _pinch_distance)
			_pinch_distance = span
		if drag.index == _stick_index:
			var radius := 70.0 * ui
			var d := drag.position - _stick_origin
			if scheme == CLASSIC and not flying:
				# The steering strip: left / right only; its centre follows a thumb that runs past the end.
				d.y = 0.0
				if absf(d.x) > radius:
					_stick_origin.x += signf(d.x) * (absf(d.x) - radius)
				_stick_point = Vector2(drag.position.x, _stick_origin.y)
				stick = Vector2((_stick_point.x - _stick_origin.x) / radius, 0.0)
			else:
				if d.length() > radius:
					_stick_origin += d.normalized() * (d.length() - radius)
				_stick_point = drag.position
				stick = (_stick_point - _stick_origin) / radius
			_pad.queue_redraw()
		elif scheme == CLASSIC and not flying and (drag.index == _gas_index or drag.index == _brake_index):
			# A thumb sliding from one pedal to the other switches pedals without lifting.
			var to_gas := drag.position.distance_to(_gas_centre())
			var to_brake := drag.position.distance_to(_brake_centre())
			if to_gas < 75 * ui and to_gas < to_brake and drag.index == _brake_index:
				_brake_index = -1
				brake = false
				_gas_index = drag.index
				gas = true
				_pad.queue_redraw()
			elif to_brake < _brake_reach() and to_brake < to_gas and drag.index == _gas_index:
				_gas_index = -1
				gas = false
				_brake_index = drag.index
				brake = true
				_pad.queue_redraw()


## A tap: one finger down and up again within 0.35 s and 16 px, not on a control, the
## brake or the climb pads, and not part of a pinch. It goes out as `tapped`; the stick
## it may have started never moved, so the car is not steered by it.
func _track_tap(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		var p := touch.position
		var on_control := _over_panel(p) or p.y < 80 * ui or (_minimap != null and _minimap.get_global_rect().has_point(p)) \
				or (flying and (p.distance_to(_climb_centre(1)) < 56 * ui or p.distance_to(_climb_centre(-1)) < 56 * ui)) \
				or _on_pedals(p)
		if not on_control and _taps.is_empty():
			_taps[touch.index] = [p, Time.get_ticks_msec()]
		else:
			_taps.clear()  # a second finger: a pinch
		return
	if not _taps.has(touch.index):
		return
	var start: Array = _taps[touch.index]
	_taps.erase(touch.index)
	if touch.position.distance_to(start[0]) <= 16 * ui and Time.get_ticks_msec() - int(start[1]) <= 350:
		tapped.emit(touch.position)


func _pinch_span() -> float:
	if _free_touches.size() != 2:
		return 0.0
	var points: Array = _free_touches.values()
	return (points[0] as Vector2).distance_to(points[1])


func _draw_pad() -> void:
	if _marker_visible:
		# A yellow pointer over the player's car.
		var m := _marker - Vector2(0, 10 * ui)
		var tri := PackedVector2Array([m + Vector2(-9, -14) * ui, m + Vector2(9, -14) * ui, m])
		var outline := PackedVector2Array([m + Vector2(-12.5, -16.5) * ui, m + Vector2(12.5, -16.5) * ui, m + Vector2(0, 3.5) * ui])
		_pad.draw_colored_polygon(outline, Color("#2a2622"))
		_pad.draw_colored_polygon(tri, Color("#ffd23f"))
	var ring := Color(1, 1, 1, 0.55)
	var fill := Color(0.1, 0.1, 0.12, 0.28)
	if _stick_index != -1 and scheme == CLASSIC and not flying:
		# The steering strip: a rounded bar with arrows at the ends and the thumb's knob.
		var half := 70 * ui
		var r := 26 * ui
		var o := _stick_origin
		var bar := Rect2(o - Vector2(half, r), Vector2(half * 2.0, r * 2.0))
		_pad.draw_rect(Rect2(bar.position + Vector2(r, 0), Vector2(bar.size.x - r * 2.0, bar.size.y)), fill)
		_pad.draw_circle(o - Vector2(half - r, 0), r, fill)
		_pad.draw_circle(o + Vector2(half - r, 0), r, fill)
		_pad.draw_line(o + Vector2(-half + r, -r), o + Vector2(half - r, -r), ring, 2.0 * ui)
		_pad.draw_line(o + Vector2(-half + r, r), o + Vector2(half - r, r), ring, 2.0 * ui)
		_pad.draw_arc(o - Vector2(half - r, 0), r, PI * 0.5, PI * 1.5, 20, ring, 2.0 * ui)
		_pad.draw_arc(o + Vector2(half - r, 0), r, -PI * 0.5, PI * 0.5, 20, ring, 2.0 * ui)
		for side in [-1.0, 1.0]:
			var tip := o + Vector2(side * (half + 14 * ui), 0)
			_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 11, -9) * ui, tip + Vector2(-side * 11, 9) * ui]),
					Color(1, 1, 1, 0.6))
		_pad.draw_circle(_stick_point, 24 * ui, Color(1, 1, 1, 0.75))
	elif _stick_index != -1:
		_pad.draw_circle(_stick_origin, 70 * ui, fill)
		_pad.draw_arc(_stick_origin, 70 * ui, 0, TAU, 40, ring, 2.0 * ui)
		_pad.draw_circle(_stick_point, 28 * ui, Color(1, 1, 1, 0.75))
	var font := ThemeDB.fallback_font
	var fs := int(15 * ui)
	if flying:
		for direction in _UP_DOWN:
			var c := _climb_centre(direction)
			var held := climb == float(direction)
			_pad.draw_circle(c, 48 * ui, Color(0.95, 0.75, 0.2, 0.5) if held else fill)
			_pad.draw_arc(c, 48 * ui, 0, TAU, 40, ring, 2.0 * ui)
			var s: float = 14.0 * ui * direction
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.6), c + Vector2(-s, s * 0.6)]),
					Color(1, 1, 1, 0.9))
		return
	var bc := _brake_centre()
	var br := (48.0 if scheme == CLASSIC else 58.0) * ui
	_pad.draw_circle(bc, br, Color(0.75, 0.15, 0.12, 0.55) if brake else fill)
	_pad.draw_arc(bc, br, 0, TAU, 40, ring, 2.0 * ui)
	var w := font.get_string_size("BRAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	_pad.draw_string(font, bc + Vector2(-w * 0.5, fs * 0.35), "BRAKE", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.9))
	if scheme == CLASSIC:
		var gc := _gas_centre()
		_pad.draw_circle(gc, 62 * ui, Color(0.2, 0.72, 0.36, 0.55) if gas else fill)
		_pad.draw_arc(gc, 62 * ui, 0, TAU, 40, ring, 2.0 * ui)
		var gw := font.get_string_size("GAS", HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 1.2)).x
		_pad.draw_string(font, gc + Vector2(-gw * 0.5, fs * 0.42), "GAS", HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs * 1.2), Color(1, 1, 1, 0.9))
		if _stick_index == -1:
			# Where the steering strip lives, faintly, until a thumb comes down.
			var size := get_viewport().get_visible_rect().size
			var o := Vector2(maxf(190 * ui + _inset_left, size.x * 0.16), size.y - 120 * ui)
			var hint := Color(1, 1, 1, 0.38)
			var shade := Color(0.1, 0.1, 0.12, 0.3)
			_pad.draw_line(o - Vector2(60, 0) * ui, o + Vector2(60, 0) * ui, shade, 7.0 * ui)
			_pad.draw_line(o - Vector2(60, 0) * ui, o + Vector2(60, 0) * ui, hint, 3.0 * ui)
			for side in [-1.0, 1.0]:
				var tip := o + Vector2(side * 76, 0) * ui
				_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 12, -10) * ui, tip + Vector2(-side * 12, 10) * ui]), hint)


## Loop 2a: the gear, drawn like the HUD's buttons (a dark disc with a light gear).
func _draw_gear() -> void:
	var c := Vector2(16 + 26, 12 + 26) * ui
	var held := _gear.button_pressed or _gear.is_pressed()
	_gear.draw_circle(c, 26 * ui, Color(0.09, 0.09, 0.11, 0.84 if not held else 0.95))
	_gear.draw_arc(c, 26 * ui, 0, TAU, 40, Color(1, 1, 1, 0.18), maxf(1.0, ui))
	var teeth := 8
	var pts := PackedVector2Array()
	for k in teeth * 4:
		var a := TAU * (k / 4.0) / teeth - PI / teeth * 0.5
		var r := (14.5 if k % 4 == 1 or k % 4 == 2 else 10.5) * ui
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	var ink := Color("#ffd23f") if held else Color("#fbf7ee")
	_gear.draw_colored_polygon(pts, ink)
	_gear.draw_circle(c, 4.5 * ui, Color(0.09, 0.09, 0.11))


## On screen: a bobbing pointer over the target with the distance. Off screen: an
## arrow on the screen edge (below the top buttons), pointing the way.
func _draw_target() -> void:
	if not _target_visible:
		return
	var o := _overlay
	var size := o.size
	var margin := 48.0 * ui
	var font := ThemeDB.fallback_font
	var fs := int(15 * ui)
	var outline := Color("#1d1b19")
	var w := font.get_string_size(_target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var top := 80.0 * ui
	if _status.visible:
		# Keep the edge arrow off the status panel in the top right.
		top = maxf(top, _status.get_global_rect().end.y + 12.0 * ui)
	var inside := Rect2(margin, top, size.x - margin * 2.0, size.y - margin - top)
	if inside.size.x <= 0.0 or inside.size.y <= 0.0:
		return  # no room to point (a headless run's tiny window)
	if inside.has_point(_target_at):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 3.0 * ui
		var m := _target_at - Vector2(0, 26 * ui + bob)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-13, -18) * ui, m + Vector2(13, -18) * ui, m + Vector2(0, 4) * ui]), outline)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-9, -15.5) * ui, m + Vector2(9, -15.5) * ui, m]), _target_colour)
		var at := m + Vector2(-w * 0.5, -24 * ui)
		o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(5 * ui), outline)
		o.draw_string(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _target_colour)
		return
	var centre := inside.get_center()
	var d := _target_at - centre
	if d.length() < 1.0:
		return
	# Scale the line from the centre so it ends on the inset screen edge.
	var t := minf((inside.size.x * 0.5) / maxf(absf(d.x), 0.001), (inside.size.y * 0.5) / maxf(absf(d.y), 0.001))
	var tip := centre + d * t
	var dir := d.normalized()
	var side := Vector2(-dir.y, dir.x)
	var a := 22.0 * ui
	o.draw_colored_polygon(PackedVector2Array([tip + dir * 4 * ui, tip - dir * (a + 4 * ui) + side * (a * 0.7 + 3 * ui),
			tip - dir * (a + 4 * ui) - side * (a * 0.7 + 3 * ui)]), outline)
	o.draw_colored_polygon(PackedVector2Array([tip, tip - dir * a + side * a * 0.6, tip - dir * a - side * a * 0.6]), _target_colour)
	var at := tip - dir * (a + 30 * ui) - Vector2(w * 0.5, -fs * 0.35)
	o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(5 * ui), outline)
	o.draw_string(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _target_colour)
