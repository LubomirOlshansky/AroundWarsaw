extends Control
## Loop 2a: the settings panel, opened by the gear in the HUD's top left (or Esc). The game
## pauses under it (main.gd). A dark translucent card like the HUD's mission panels, Polish
## first with the English under it, every control at least 44 pt (the iPhone guideline):
## Controls (Point / Classic / Fixed camera, with a line saying what the scheme does),
## Traffic (Almost empty / Low / Normal / Busy), Quality (Low / Medium / High), Sound
## (volume, radio, effects: − and + in tenths, or drag along the bar) and the performance
## overlay. Two columns on a phone or a wide window; scaled down to fit a narrower one.
## Emits `changed(key, value)` for each change (main.gd applies and saves it) and `closed`.

signal changed(key: String, value: Variant)
signal closed

const ACCENT := Color("#ffd23f")
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const DIM := Color(1, 1, 1, 0.07)

const CONTROLS := [["Wskaż", "Point"], ["Klasycznie", "Classic"], ["Stała kamera", "Fixed camera"]]
const CONTROLS_SAY := [
	["Pokaż palcem, dokąd jechać. Kamera czeka, aż puścisz.", "Point where to go. The camera waits until you let go."],
	["Kierownica lewo–prawo, gaz i hamulec po prawej.", "Steer left–right; GAS and BRAKE on the right."],
	["Pokaż palcem, dokąd jechać. Kamera się nie obraca.", "Point where to go. The camera never turns."],
]
const TRAFFIC := [["Pustawo", "Almost empty"], ["Mało", "Low"], ["Normalnie", "Normal"], ["Tłoczno", "Busy"]]
const QUALITY := [["Niska", "Low"], ["Średnia", "Medium"], ["Wysoka", "High"]]
const PERF := [["Wył.", "Off"], ["Wł.", "On"]]
## Loop 2b: frames per second (settings.gd FPS: 60, 30) and the benchmark button.
const FPS := [["60", "płynnie · smooth"], ["30", "bateria · battery"]]
const LEVELS := [["master", "Głośność", "Volume"], ["music", "Radio", "Radio"], ["effects", "Efekty", "Effects"]]

var ui := 1.0
var inset_left := 0.0
var inset_right := 0.0
## The smallest touch target in pixels (44 pt).
var touch := 72.0
var _card: PanelContainer
var _groups := {}
var _bars := {}
var _values := {}
var _say_pl: Label
var _say_en: Label
var _built := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	get_viewport().size_changed.connect(_fit)


## 44 pt in pixels: the screen's points on a phone; on a computer the window is taken as a
## phone screen 390 pt tall (an iPhone in landscape), so screenshots show the phone's sizes.
func _touch_px() -> float:
	var h := get_viewport().get_visible_rect().size.y
	var pt := h / 390.0
	if OS.has_feature("mobile"):
		pt = maxf(DisplayServer.screen_get_scale(), 1.0)
	return maxf(44.0 * pt, 44.0 * ui)


func _build() -> void:
	_built = true
	touch = _touch_px()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.05, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	# A tap beside the card closes it.
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	add_child(shade)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.1, 0.94)
	style.set_corner_radius_all(int(12 * ui))
	style.set_content_margin_all(18 * ui)
	style.border_color = Color(1, 1, 1, 0.12)
	style.set_border_width_all(maxi(1, int(ui)))
	style.border_width_left = int(4 * ui)
	style.border_color = Color("#ff4fd8")
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", style)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", int(12 * ui))
	_card.add_child(rows)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", int(14 * ui))
	rows.add_child(head)
	var title := _text("USTAWIENIA", 26, ACCENT)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	var sub := _text("Settings · gra wstrzymana, game paused", 15, SUB)
	sub.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	var x := _flat_button("✕", 24)
	x.custom_minimum_size = Vector2(touch, touch)
	x.pressed.connect(close)
	head.add_child(x)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", int(30 * ui))
	rows.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", int(8 * ui))
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", int(8 * ui))
	cols.add_child(right)

	_heading(left, "Sterowanie", "Controls")
	_segments(left, "controls", CONTROLS)
	_say_pl = _text("", 14, INK)
	_say_en = _text("", 13, SUB)
	for l in [_say_pl, _say_en]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 10.0
		left.add_child(l)
	_gap(left, 6)
	_heading(left, "Ruch uliczny", "Traffic")
	_segments(left, "traffic", TRAFFIC)
	_gap(left, 6)
	_heading(left, "Jakość obrazu", "Quality")
	_segments(left, "quality", QUALITY)

	_heading(right, "Dźwięk", "Sound")
	for l in LEVELS:
		_level(right, l[0], l[1], l[2])
	_gap(right, 6)
	_gap(right, 6)
	_heading(right, "Klatki na sekundę", "Frame rate")
	_segments(right, "fps", FPS)
	_heading(right, "Licznik wydajności", "Performance overlay")
	var perf_row := HBoxContainer.new()
	perf_row.add_theme_constant_override("separation", int(8 * ui))
	right.add_child(perf_row)
	_segments(perf_row, "perf", PERF)
	# Loop 2b: a minute on the bench route, then a result card to copy (main.gd).
	var bench := _flat_button("", 16)
	bench.custom_minimum_size = Vector2(touch * 1.9, touch)
	var words := VBoxContainer.new()
	words.set_anchors_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in [_text("TEST", 20, ACCENT), _text("bench · 1 min", 14, SUB)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
	bench.add_child(words)
	bench.pressed.connect(func():
		close()
		changed.emit("bench", 1))
	perf_row.add_child(bench)


## Shows the panel with the current values: {controls, traffic, quality, master, music,
## effects, perf}.
func open(state: Dictionary) -> void:
	if not _built:
		_build()
	for key in _groups:
		_select(key, int(state.get(key, 0)))
	for key in _bars:
		_values[key] = float(state.get(key, 1.0))
		(_bars[key] as Control).queue_redraw()
	_say(int(state.get("controls", 0)))
	visible = true
	_fit.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if visible and key and key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## Centred in the safe area; scaled down if the window is too small for it.
func _fit() -> void:
	if _card == null or not visible:
		return
	var screen := get_viewport().get_visible_rect().size
	_card.reset_size()
	var need := _card.get_combined_minimum_size()
	var room := Vector2(screen.x - inset_left - inset_right - 24 * ui, screen.y - 24 * ui)
	var k := minf(1.0, minf(room.x / maxf(need.x, 1.0), room.y / maxf(need.y, 1.0)))
	_card.scale = Vector2(k, k)
	_card.size = need
	_card.position = Vector2(inset_left + (screen.x - inset_left - inset_right - need.x * k) * 0.5, (screen.y - need.y * k) * 0.5)


# --- pieces --------------------------------------------------------------------------------------

func _text(s: String, font_size: int, colour: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", int(font_size * ui))
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_outline_color", Color("#1d1b19"))
	l.add_theme_constant_override("outline_size", int(3 * ui))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _gap(parent: Node, h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = h * ui
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)


func _heading(parent: Node, pl: String, en: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(10 * ui))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_text(pl.to_upper(), 16, ACCENT))
	var e := _text(en, 14, SUB)
	e.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(e)
	parent.add_child(row)


func _box(bg: Color, border: Color, width: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(8 * ui))
	s.border_color = border
	s.set_border_width_all(maxi(1, int(width * ui)))
	s.set_content_margin_all(8 * ui)
	return s


func _flat_button(label: String, font_size: int) -> Button:
	var b := Button.new()
	b.text = label
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(font_size * ui))
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", ACCENT)
	var normal := _box(DIM, Color(1, 1, 1, 0.18), 1.0)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", _box(Color(1, 0.82, 0.25, 0.22), ACCENT, 2.0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


## A row of options (one chosen), each a button with the Polish word over the English.
func _segments(parent: Node, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * ui))
	parent.add_child(row)
	var buttons: Array[Button] = []
	for i in options.size():
		var b := _flat_button("", 16)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(touch * 1.45, touch)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_stylebox_override("hover_pressed", _box(Color(1, 0.82, 0.25, 0.22), ACCENT, 2.0))
		var words := VBoxContainer.new()
		words.set_anchors_preset(Control.PRESET_FULL_RECT)
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.add_theme_constant_override("separation", 0)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pl := _text(options[i][0], 20, INK)
		var en := _text(options[i][1], 14, SUB)
		for l in [pl, en]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			words.add_child(l)
		b.add_child(words)
		# The words set the button's width (a Button doesn't size to its children).
		var w := maxf(pl.get_combined_minimum_size().x, en.get_combined_minimum_size().x) + 28 * ui
		b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, w)
		b.pressed.connect(func():
			_select(key, i)
			if key == "controls":
				_say(i)
			changed.emit(key, i))
		row.add_child(b)
		buttons.append(b)
	_groups[key] = buttons


func _select(key: String, index: int) -> void:
	var buttons: Array = _groups[key]
	for k in buttons.size():
		(buttons[k] as Button).set_pressed_no_signal(k == index)


func _say(scheme: int) -> void:
	var s: Array = CONTROLS_SAY[clampi(scheme, 0, CONTROLS_SAY.size() - 1)]
	_say_pl.text = s[0]
	_say_en.text = s[1]


## A volume: the words, −, a bar (tap or drag along it) and +.
func _level(parent: Node, key: String, pl: String, en: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(8 * ui))
	parent.add_child(row)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.custom_minimum_size.x = 118 * ui
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(_text(pl, 20, INK))
	words.add_child(_text(en, 14, SUB))
	row.add_child(words)
	var minus := _flat_button("−", 26)
	minus.custom_minimum_size = Vector2(touch, touch)
	minus.pressed.connect(func(): _set_level(key, float(_values.get(key, 1.0)) - 0.1))
	row.add_child(minus)
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(220 * ui, touch)
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.draw.connect(_draw_bar.bind(bar, key))
	bar.gui_input.connect(func(e: InputEvent):
		var at := -1.0
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			at = (e as InputEventMouseButton).position.x
		elif e is InputEventMouseMotion and ((e as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			at = (e as InputEventMouseMotion).position.x
		if at >= 0.0:
			var pad := 10.0 * ui
			_set_level(key, snappedf(clampf((at - pad) / maxf(bar.size.x - pad * 2.0, 1.0), 0.0, 1.0), 0.05)))
	row.add_child(bar)
	_bars[key] = bar
	var plus := _flat_button("+", 26)
	plus.custom_minimum_size = Vector2(touch, touch)
	plus.pressed.connect(func(): _set_level(key, float(_values.get(key, 1.0)) + 0.1))
	row.add_child(plus)


func _set_level(key: String, v: float) -> void:
	v = clampf(snappedf(v, 0.05), 0.0, 1.0)
	if is_equal_approx(v, float(_values.get(key, -1.0))):
		return
	_values[key] = v
	(_bars[key] as Control).queue_redraw()
	changed.emit(key, v)


func _draw_bar(bar: Control, key: String) -> void:
	var v: float = _values.get(key, 1.0)
	var pad := 10.0 * ui
	var h := 14.0 * ui
	var track := Rect2(Vector2(pad, (bar.size.y - h) * 0.5), Vector2(bar.size.x - pad * 2.0, h))
	bar.draw_rect(track.grow(2.0 * ui), Color("#1d1b19"))
	bar.draw_rect(track, Color(1, 1, 1, 0.1))
	# Ten steps, lit up to the level: cyan to pink, the vaporwave way.
	var steps := 10
	var w := track.size.x / steps
	for k in steps:
		var f := (k + 1.0) / steps
		if f <= v + 0.001 or (k == floori(v * steps) and v * steps - k > 0.01):
			var share := clampf(v * steps - k, 0.0, 1.0)
			var c := Color("#5fd4ff").lerp(Color("#ff4fd8"), float(k) / (steps - 1))
			bar.draw_rect(Rect2(track.position + Vector2(k * w + 1.0 * ui, 0), Vector2((w - 2.0 * ui) * share, h)), c)
	var font := ThemeDB.fallback_font
	var fs := int(14 * ui)
	var label := "%d %%" % roundi(v * 100.0) if v > 0.001 else "0 % · cisza, mute"
	var at := Vector2(track.position.x, track.position.y - 6.0 * ui)
	bar.draw_string_outline(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, int(3 * ui), Color("#1d1b19"))
	bar.draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SUB)
