extends CanvasLayer
## On-screen controls and panels at full resolution, above the pixel-art view.
##
## Loop 2e: the whole HUD is sized in points (screen_points.gd: 3 px a point on the iPhones the
## game targets; on a computer the window stands in for a phone), every control at least 44 pt,
## every text on one type scale (T_*: body 13 pt and up, labels 11 pt), everything inside the
## safe area (the Dynamic Island or notch, the rounded corners, the home indicator). The first
## screen is thin: the gear (settings) top left with the speed beside it, one context button
## in the middle of the top row (a rescue call that came in), RADIO and HELI / AUTO top right;
## the minimap and the wallet under the gear; the pedals bottom right; the credit line bottom
## centre. Time of day, rain, VHS, the picture style and the camera moved into Settings
## (settings_panel.gd); zoom is a pinch, and with the fixed camera a two-finger twist turns the
## view. The panels that come and go (the status, the call or job card, FLASH LIGHTS, the race
## banner, toasts, the performance overlay, the note and landmark cards, the radio ticker) are
## placed by `_layout` in that order of priority, each giving way along its column so none
## covers another or a fixed control; the speech bubbles (bubbles.gd) keep clear of all of them
## (`panel_rects`). `game/tools/check_hud.gd` checks the sizes, the safe area and the overlaps.
##
## Before: a floating stick on the left (point-to-steer), BRAKE on the right (climb and sink
## pads in the helicopter), the rescue card and status (shared with races and the side jobs),
## an arrow to the target, the race challenge and countdown banner, rival dots, side-job places
## and the target on the minimap, the wallet (złoty and respect), the note card (an easter
## egg), the landmark card (v0.8), the now-playing ticker, the performance overlay (v0.9, a
## three-finger tap or P). Loop 2a: the gear and the settings panel; the controls follow the
## scheme: Point and Fixed keep the stick and BRAKE, Classic has a left / right steering strip
## and GAS with BRAKE beside it (a thumb can slide between them).

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const SettingsPanel := preload("res://scripts/settings_panel.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
## drive_controls.gd's schemes (POINT, CLASSIC, FIXED).
const CLASSIC := 1

## Loop 2e: the HUD's type scale, in points. Body text is 13 pt or more, labels 11 pt.
const T_BANNER := 44.0
const T_CLOCK := 22.0
const T_TITLE := 17.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
## Loop 2e: the layout, in points. TOUCH is Apple's smallest comfortable tap; EDGE is kept from
## the safe area's sides; the top row starts ROW_Y down and is ROW_H tall.
const TOUCH := 44.0
const EDGE := 10.0
const GAP := 8.0
const ROW_Y := 8.0
const ROW_H := 44.0
## The minimap: its diameter on screen and how far from the car its rim reaches (metres).
const MINI_D := 96.0
const MINI_REACH := 360.0
## The stick's (and Classic's steering strip's) reach: a full push is this far from where the
## thumb came down (loop 2a's 70 HUD units were 43 pt on the user's Pro Max, 38 on a 6.1").
const STICK_R := 42.0
## The pedals and the helicopter's pads: drawn radius and touch reach.
const BRAKE_R := 36.0
const BRAKE_REACH := 46.0
const GAS_R := 40.0
const GAS_REACH := 48.0
const CLASSIC_BRAKE_R := 31.0
const CLASSIC_BRAKE_REACH := 38.0
const PAD_R := 34.0
const PAD_REACH := 40.0
## Loop 2e: the player's car sits about the middle of the screen (the view leads it a little);
## the passing panels (toasts, the ticker, notes, the overlay, the banner) keep out of a box
## this big round the middle. The cards and the status come first and may cover it.
const CAR_ZONE := Vector2(110.0, 84.0)
## Panel widths.
const CARD_W := 440.0
const STATUS_W := 260.0
const NOTE_W := 236.0
const TICKER_W := 380.0
const TOAST_W := 420.0
## A long ticker line that finds no room at TICKER_W wraps this narrow and tries again.
const TICKER_NARROW := 250.0
## Loop 2e: the passing panels that, when the screen is full, wait for room (their time on
## screen counts only once they are up) instead of covering something; the performance overlay
## (a developer's tool) steps aside the same way when even its two-line form finds no room.
const WAITS := ["ticker", "note", "info", "perf"]
## A two-finger twist this far (radians) turns a fixed camera 90°.
const TWIST := 0.7
const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const ACCENT := Color("#ffd23f")
const OUTLINE := Color("#1d1b19")
## Loop 2e: the one card recipe for every HUD surface (the settings panel's): near-black violet,
## at least 90 % opaque, so no surface takes its colour from the street behind it.
const CARD_BG := Color(0.07, 0.06, 0.1, 0.94)
const CARD_EDGE := Color(1, 1, 1, 0.16)
## Card buttons: the English word the game passes in -> the Polish one shown over it.
const WORDS := {
	"ACCEPT": "PRZYJMIJ", "SKIP": "POMIŃ", "LATER": "PÓŹNIEJ", "NEXT CALL": "NASTĘPNE",
	"FREE ROAM": "SWOBODNIE", "TRY AGAIN": "JESZCZE RAZ", "GO!": "JEDZIEMY!", "NOT NOW": "NIE TERAZ",
}
enum { DOWN = 1, UP = -1 }

## Loop 2e: a two-finger twist with the fixed camera (+1 clockwise on screen).
signal rotate_pressed(direction: int)
signal pinched(ratio: float)          # finger distance now / before
signal vehicle_pressed
signal card_pressed(index: int)       # a button on the mission card
signal pill_pressed                   # the context button: a rescue call that came in
signal abort_pressed                  # the ✕ on the mission status
signal challenge_pressed              # FLASH LIGHTS: challenge the rival in front
signal radio_pressed                  # RADIO: next station or off
signal tapped(at: Vector2)            # a short tap on the city, not on a control (v0.8: landmarks)
signal perf_gesture                   # three fingers down at once: the performance overlay
signal settings_pressed               # loop 2a: the gear

var stick := Vector2.ZERO   # -1..1 in screen space, x right, y down
var brake := false
## Loop 2a: the GAS pedal (Classic), and the control scheme the pads are drawn for.
var gas := false
var scheme := 0
var settings_panel: Control
## Helicopter height pads: +1 held climbs, -1 sinks.
var climb := 0.0
var flying := false
## Loop 2e: pixels per point (the HUD was sized in 720-line units before), the screen and its
## safe area in pixels.
var pt := 1.0
var _screen := Vector2.ZERO
var _safe := Rect2()

var _gear: Button
var _speed: Label
var _speed_text := ""
var _vehicle_button: Button
var _radio_button: Button
## The context button in the middle of the top row (a rescue call that came in).
var _pill: Button
var _pill_t := 0.0
var _credit: Label
var _pad: Control
var _gas_index := -1
var _climb_index := -1
## Mission card (calls and results), the status panel while a mission runs.
var _card: PanelContainer
var _card_title: Label
var _card_body: Label
## Loop 2e: the English under the Polish title and text (smaller, the sub-text colour).
var _card_title_en: Label
var _card_body_en: Label
var _card_buttons: HBoxContainer
## The side jobs' cards sit at the bottom centre, clear of the speech bubbles over the stand
## or the door; the others at the top centre under the top row.
var _card_bottom := false
var _status: PanelContainer
var _status_title: Label
var _status_clock: Label
var _status_hint: Label
var _status_hint_en: Label
var _status_bar: ColorRect
var _status_track: Control
var _status_badge: Label
## Street races: the challenge button and a big banner (countdown, GO!).
var _challenge: Button
var _banner: Label
var _overlay: Control
## A short line (Polish, with its English gloss under it) at the bottom for 3 s.
var _toast_box: PanelContainer
var _toast: Label
var _toast_gloss: Label
var _toast_left := 0.0
## The performance overlay.
var _perf: PanelContainer
var _perf_label: Label
var _perf_text := ""
## Loop 2e: only the first two lines, when the layout found no room for all of them.
var _perf_compact := false
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
## The wallet under the minimap; a payment shows as "+54 zł" in its place for a moment.
var _wallet: Control
var _wallet_zl := 0
var _wallet_respect := 0
var _wallet_gain := 0
var _wallet_flash := 0.0
const WALLET_FLASH := 2.2
var _wallet_plate: StyleBoxFlat
var _note: PanelContainer
var _note_title: Label
var _note_body: Label
var _note_style: StyleBoxFlat
var _note_left := 0.0
## v0.8: the landmark info card (same look as the note card), and the touches that may turn
## out to be taps: index -> [start position, start time in ms].
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
## Touches that are neither the stick nor the pedals; two of them make a pinch (or a twist).
var _free_touches := {}
var _pinch_distance := 0.0
var _twist_angle := 0.0
var _twist := 0.0
var _marker := Vector2.ZERO
var _marker_visible := false
## Loop 2e: the plate under Classic's steering strip (and its hint).
var _strip_plate: StyleBoxFlat
## Minimap: north-up data drawn once, then turned and moved so the camera's view is up.
## Loop 2b: every street, park and pond is built once into one 2D mesh, drawn with one call and
## cut to the circle by a small shader (it was 6,500 draw calls, the iPhone's 16 fps).
## Loop 2e: at night (`night` 1) the map takes a night palette: the streets light on a dark
## ground, parks and water dark, so the minimap is no longer the brightest thing on screen.
const MINI_CLIP := """shader_type canvas_item;
uniform vec2 centre;
uniform float radius;
uniform float night = 0.0;
void fragment() {
	if (distance(FRAGCOORD.xy, centre) > radius) {
		discard;
	}
	vec3 c = COLOR.rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	vec3 street = vec3(0.98 - l) * vec3(0.8, 0.8, 1.0);
	vec3 area = c * 0.36 + vec3(0.02, 0.02, 0.05);
	COLOR.rgb = mix(c, mix(street, area, smoothstep(0.08, 0.2, sat)), night);
}
"""
var _minimap: Control
var _mini_content: Node2D
var _mini_mesh: ArrayMesh
var _mini_clip: ShaderMaterial
var _mini_overlay: Control
var _mini_radius := 48.0
## Minimap pixels per metre.
var _mini_scale := 0.2
var _car_dir := Vector2.UP
var _north := Vector2.UP
## Loop 2e: 0 by day, 1 at night (the minimap's palette).
var _night := 0.0

## Loop 2e, the layout: the panels that come and go, in order of priority; which of them the
## game wants on screen; where each went; every rect on screen after the last layout (the fixed
## controls and the placed panels; the bubbles keep clear of them); how many found no room.
var _floating: Array[Control] = []
var _wants := {}
var _placed := {}
var _taken: Array[Rect2] = []
var _unplaced: Array[String] = []
var _dirty := true
var _queued := false
## The ticker's spot is the bottom left (it slides in); elsewhere it fades in.
var _ticker_slides := true
## Where floating panels may go, and the rows the layout hangs them from (pixels).
var _bounds := Rect2()
var _top_y := 0.0
var _col_y := 0.0
var _col_right := 0.0
var _bottom_y := 0.0


func _ready() -> void:
	_screen = get_viewport().get_visible_rect().size
	var m := ScreenPoints.measure(_screen)
	pt = m["pt"]
	_safe = m["safe"]

	_pad = Control.new()
	_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)
	_strip_plate = StyleBoxFlat.new()
	_strip_plate.bg_color = CARD_BG
	_strip_plate.border_color = Color(1, 1, 1, 0.3)
	_strip_plate.set_border_width_all(maxi(1, roundi(1.2 * pt)))

	# The top row: the gear (loop 2a), the speed, the context button, RADIO and HELI / AUTO.
	_gear = Button.new()
	_gear.focus_mode = Control.FOCUS_NONE
	_gear.flat = true
	_gear.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_gear.draw.connect(_draw_gear)
	_gear.pressed.connect(func(): settings_pressed.emit())
	add_child(_gear)
	# Loop 2e: the speed on a plate in the card recipe (it was outlined text over the street).
	_speed = _label(T_BODY, INK)
	_speed.name = "speed"
	var plate := _panel_box(9.0, 0.0)
	plate.content_margin_left = 12.0 * pt
	plate.content_margin_right = 12.0 * pt
	plate.content_margin_top = 6.0 * pt
	plate.content_margin_bottom = 6.0 * pt
	_speed.add_theme_stylebox_override("normal", plate)
	_speed.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_speed)
	_pill = _chip(self, "WEZWANIE", "rescue call", ACCENT)
	_pill.pressed.connect(func(): pill_pressed.emit())
	_pill.visible = false
	_radio_button = _chip(self, "RADIO", "wył. · off")
	_radio_button.pressed.connect(func(): radio_pressed.emit())
	_vehicle_button = _chip(self, "HELI", "helicopter")
	_vehicle_button.pressed.connect(func(): vehicle_pressed.emit())

	_credit = _label(T_LABEL, Color(1, 1, 1, 0.88), true)
	_credit.text = "© OpenStreetMap contributors · 3D buildings, aerial photo, terrain: GUGiK"
	add_child(_credit)

	_build_ticker()
	_build_mission_panels()
	_build_toast()
	_build_wallet()
	_build_perf()
	_floating = [_status, _card, _challenge, _banner, _toast_box, _perf, _note, _info_card, _ticker]
	for c in _floating:
		_wants[c] = false
		c.visible = false
	settings_panel = SettingsPanel.new()
	settings_panel.pt = pt
	settings_panel.safe = _safe
	add_child(settings_panel)
	get_viewport().size_changed.connect(_on_resize)
	set_speed(0)
	_layout()


func _on_resize() -> void:
	_screen = get_viewport().get_visible_rect().size
	_safe = ScreenPoints.measure(_screen)["safe"]
	settings_panel.safe = _safe
	_mark()


# --- pieces ----------------------------------------------------------------------------------

## A font size in pixels for a size in points.
func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


## A label on the type scale; `outline` for text that sits on the city rather than a panel.
func _label(points: float, colour: Color, outline := false) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", _px(points))
	l.add_theme_color_override("font_color", colour)
	if outline:
		l.add_theme_color_override("font_outline_color", OUTLINE)
		l.add_theme_constant_override("outline_size", _px(2.5 if points >= T_SUB else 2.0))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A dark card: near-black, a thin light border, rounded (the art bible's HUD card).
func _panel_box(radius := 10.0, margin := 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD_BG
	s.set_corner_radius_all(roundi(radius * pt))
	s.set_content_margin_all(margin * pt)
	s.border_color = CARD_EDGE
	s.set_border_width_all(maxi(1, roundi(pt * 0.5)))
	return s


func _box(bg: Color, border: Color, width: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(roundi(10.0 * pt))
	s.border_color = border
	s.set_border_width_all(maxi(1, roundi(width * pt)))
	s.set_content_margin_all(4.0 * pt)
	return s


## Loop 2e: a button at least 44 pt tall with the Polish word over the English one (11 pt).
## `accent` draws its border in a colour (the context button).
func _chip(parent: Node, pl: String, en: String, accent := Color(0, 0, 0, 0)) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var lit := accent.a > 0.0
	var normal := _box(CARD_BG, accent if lit else Color(1, 1, 1, 0.22), 2.0 if lit else 1.0)
	var pressed := _box(Color(1, 0.82, 0.25, 0.3), ACCENT, 2.0)
	for s in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(s, normal)
	for s in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(s, pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var words := VBoxContainer.new()
	words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for t in [[T_BODY, accent if lit else INK], [T_LABEL, SUB]]:
		var l := _label(t[0], t[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
	b.add_child(words)
	parent.add_child(b)
	_set_chip(b, pl, en)
	return b


## New words on a chip; its width follows them (at least 64 pt).
func _set_chip(b: Button, pl: String, en: String, min_width := 64.0) -> void:
	var words := b.get_child(0)
	var top := words.get_child(0) as Label
	var low := words.get_child(1) as Label
	top.text = pl
	low.text = en
	low.visible = en != ""
	var font := ThemeDB.fallback_font
	var w := maxf(font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x,
			font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x)
	b.custom_minimum_size = Vector2(maxf(w + 24.0 * pt, min_width * pt), TOUCH * pt)
	b.size = b.custom_minimum_size
	_mark()


## A wrapped label `w` points wide (its height follows the text at that width at once).
func _wrap(l: Label, w: float) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w * pt
	l.size.x = w * pt


# --- the layout ------------------------------------------------------------------------------

## Something changed size or came or went: lay the HUD out again before the frame is drawn.
func _mark() -> void:
	_dirty = true
	if not _queued and is_inside_tree():
		_queued = true
		_relayout.call_deferred()


func _relayout() -> void:
	_queued = false
	if _dirty:
		_layout()


## Shows or hides a floating panel (the layout decides where, or that there's no room).
func _show(c: Control, on: bool) -> void:
	if bool(_wants.get(c, false)) != on:
		_wants[c] = on
		if not on:
			c.visible = false
		_mark()


## The fixed controls: the top row, the minimap and the wallet under the gear, the credit line.
func _layout_fixed() -> void:
	var x0 := _safe.position.x + EDGE * pt
	var y := ROW_Y * pt
	_gear.position = Vector2(x0, y)
	_gear.size = Vector2.ONE * TOUCH * pt
	_speed.size = _speed.get_combined_minimum_size()
	_speed.position = Vector2(x0 + (TOUCH + 8.0) * pt, y + (ROW_H * pt - _speed.size.y) * 0.5)
	var right := _safe.end.x - EDGE * pt
	for b: Button in [_vehicle_button, _radio_button]:
		b.size = b.custom_minimum_size
		b.position = Vector2(right - b.size.x, y)
		right = b.position.x - GAP * pt
	_pill.size = _pill.custom_minimum_size
	_pill.position = Vector2(_safe.get_center().x - _pill.size.x * 0.5, y)
	var below := (ROW_Y + ROW_H + GAP) * pt
	if _minimap != null:
		_minimap.position = Vector2(x0, below)
		_minimap.size = Vector2.ONE * MINI_D * pt
		_mini_overlay.size = _minimap.size
		below = _minimap.position.y + _minimap.size.y + 6.0 * pt
	_wallet.position = Vector2(x0, below)
	_wallet.size = Vector2(_wallet_width(), 30.0 * pt)
	_credit.size = _credit.get_combined_minimum_size()
	# Bottom left: centred, it ran into Classic's BRAKE.
	_credit.position = Vector2(x0, _safe.end.y - 3.0 * pt - _credit.size.y)
	_top_y = (ROW_Y + ROW_H + GAP) * pt
	_col_y = _wallet.position.y + _wallet.size.y + GAP * pt
	_col_right = maxf(_wallet.position.x + _wallet.size.x, below - 6.0 * pt if _minimap == null else _minimap.position.x + _minimap.size.x) + GAP * pt
	_bottom_y = _credit.position.y - 6.0 * pt
	_bounds = Rect2(_safe.position.x + 4.0 * pt, _top_y, _safe.size.x - 8.0 * pt, _safe.end.y - 4.0 * pt - _top_y)


## Lays the HUD out: the fixed controls, then each floating panel the game wants on screen, in
## order of priority, at its spot or given way along its column (down from the top row, up
## from the bottom) until it is clear of everything placed before it; a panel that finds no
## room anywhere waits off screen until there is (counted in `_unplaced`).
func _layout() -> void:
	_dirty = false
	if _perf_compact:
		_perf_compact = false
		_perf_label.text = _perf_lines()
	_layout_fixed()
	_taken.clear()
	_placed.clear()
	_unplaced.clear()
	for c: Control in [_gear, _pill, _radio_button, _vehicle_button, _minimap, _wallet, _credit]:
		if c != null and c.visible:
			_taken.append(Rect2(c.position, c.size))
	_taken.append(_speed_rect())
	_taken.append_array(_pedal_rects())
	var car_zone_added := false
	for c in _floating:
		if not car_zone_added and not c in [_status, _card, _challenge]:
			_taken.append(car_zone())
			car_zone_added = true
		if not bool(_wants.get(c, false)):
			c.visible = false
			continue
		var s := c.get_combined_minimum_size()
		var at := _place(c, s, _spots(c, s))
		if at < 0 and c == _perf and not _perf_compact:
			# No room for the whole overlay: its first two lines (fps and draw calls).
			_perf_compact = true
			_perf_label.text = _perf_lines()
			s = c.get_combined_minimum_size()
			at = _place(c, s, _spots(c, s))
		if at < 0 and c == _ticker and _ticker_label.custom_minimum_size.x > TICKER_NARROW * pt + 1.0:
			# No room for the long line: wrapped narrower it may fit beside what's in the way.
			for l: Label in [_ticker_label, _ticker_sub]:
				_wrap(l, TICKER_NARROW)
				l.update_minimum_size()
			_ticker.reset_size()
			s = c.get_combined_minimum_size()
			at = _place(c, s, _spots(c, s))
		c.visible = at >= 0
		if c == _ticker:
			_ticker_slides = at == 0
		if at < 0:
			# The ticker and the note and landmark cards wait for room (their clocks stop: see
			# WAITS); anything else is a layout fault.
			_unplaced.append(c.name)


## The spots a floating panel of size `s` may take, in order: [position, DOWN or UP].
func _spots(c: Control, s: Vector2) -> Array:
	var cx := _safe.get_center().x
	var col := _safe.position.x + EDGE * pt
	var top := Vector2(cx - s.x * 0.5, _top_y)
	var bottom := Vector2(cx - s.x * 0.5, _bottom_y - s.y)
	# Beside the minimap and the wallet, when the middle is taken.
	var beside := Vector2(_col_right, _top_y)
	var beside_low := Vector2(_col_right, _bottom_y - s.y)
	if c == _status:
		return [[Vector2(_safe.end.x - EDGE * pt - s.x, _top_y), DOWN]]
	if c == _card:
		return [[bottom, UP], [beside_low, UP]] if _card_bottom else [[top, DOWN], [beside, DOWN]]
	if c == _challenge:
		return [[bottom, UP], [beside_low, UP]]
	if c == _toast_box:
		return [[bottom, UP], [beside_low, UP], [top, DOWN]]
	if c == _banner:
		var mid := Vector2(cx - s.x * 0.5, _screen.y * 0.5 - s.y - 50.0 * pt)
		return [[mid, UP], [mid, DOWN]]
	if c == _perf:
		return [[top, DOWN], [beside, DOWN], [Vector2(col, _col_y), DOWN], [bottom, UP], [beside_low, UP]]
	if c == _note or c == _info_card:
		return [[Vector2(col, _col_y), DOWN], [beside, DOWN], [top, DOWN], [bottom, UP], [beside_low, UP]]
	if c == _ticker:
		return [[Vector2(col, _bottom_y - s.y), UP], [bottom, UP], [beside_low, UP], [top, DOWN], [beside, DOWN]]
	return []


## Puts `c` (size `s`) at the first candidate spot [position, DOWN or UP] where, after giving
## way along that direction, it is inside the bounds and clear of every rect taken so far.
## Returns the candidate's index, or -1.
func _place(c: Control, s: Vector2, cands: Array) -> int:
	var g := 6.0 * pt
	for k in cands.size():
		var r := Rect2(cands[k][0], s)
		var flow: int = cands[k][1]
		r.position.x = clampf(r.position.x, _bounds.position.x, maxf(_bounds.end.x - s.x, _bounds.position.x))
		for i in 12:
			if not _bounds.encloses(r):
				break
			var hit := Rect2()
			for t in _taken:
				if r.grow(g).intersects(t):
					hit = t
					break
			if not hit.has_area():
				c.position = r.position
				c.size = s
				_taken.append(r)
				_placed[c] = r
				return k
			r.position.y = hit.end.y + g if flow == DOWN else hit.position.y - g - s.y
	return -1


## The room the speed's plate may take: as wide as it gets ("188 km/h · 188 m"), so nothing has
## to move as the number changes.
func _speed_rect() -> Rect2:
	var font := ThemeDB.fallback_font
	var w := font.get_string_size("888 km/h · 888 m", HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x + 24.0 * pt
	return Rect2(_speed.position, Vector2(maxf(w, _speed.size.x), _speed.size.y))


## The pedals' (or the helicopter pads') plates with 4 pt round them, and where Classic's
## steering strip waits. (Their touch reach is a little wider; a card over its edge takes the
## touches it covers.)
func _pedal_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var disc := func(c: Vector2, r: float) -> Rect2: return Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0)
	if flying:
		out.append(disc.call(_climb_centre(1), (PAD_R + 4.0) * pt))
		out.append(disc.call(_climb_centre(-1), (PAD_R + 4.0) * pt))
		return out
	out.append(disc.call(_brake_centre(), ((CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) + 4.0) * pt))
	if scheme == CLASSIC:
		out.append(disc.call(_gas_centre(), (GAS_R + 4.0) * pt))
		var o := _strip_hint_centre()
		out.append(Rect2(o - Vector2(52, 12) * pt, Vector2(104, 24) * pt))
	return out


## Every rect the HUD has on screen (the fixed controls and the panels up now); the speech
## bubbles keep clear of them.
func panel_rects() -> Array[Rect2]:
	if _dirty:
		_layout()
	return _taken


## Loop 2e: the box round the middle of the screen, where the player's car usually is.
func car_zone() -> Rect2:
	return Rect2(_screen * 0.5 - CAR_ZONE * pt * 0.5, CAR_ZONE * pt)


## Loop 2e: where the bubbles may go: inside the safe area, under the top row.
func bubble_area() -> Rect2:
	return Rect2(_safe.position.x + 4.0 * pt, (ROW_Y + ROW_H + 4.0) * pt, _safe.size.x - 8.0 * pt,
			_safe.end.y - 4.0 * pt - (ROW_Y + ROW_H + 4.0) * pt)


## Loop 2e, for tools/check_hud.gd: the safe area, and the panels the layout found no room for.
func safe_rect() -> Rect2:
	return _safe


func unplaced() -> Array[String]:
	if _dirty:
		_layout()
	var out: Array[String] = []
	for n in _unplaced:
		if not n in WAITS:
			out.append(n)
	return out


## For tools/check_hud.gd: the passing panels waiting for room now.
func waiting() -> Array[String]:
	var out: Array[String] = []
	for n in _unplaced:
		if n in WAITS:
			out.append(n)
	return out


## For tools/check_hud.gd: takes everything that comes and goes off the screen at once.
func clear_all() -> void:
	for c in _floating:
		_show(c, false)
	_toast_left = 0.0
	_ticker_left = 0.0
	_note_left = 0.0
	_info_left = 0.0
	_wallet_flash = 0.0
	hide_pill()
	hide_bench_card()
	_mark()


## For tools/check_hud.gd: every control the player can press now, with a name.
func touch_targets() -> Dictionary:
	if _dirty:
		_layout()
	var out := {}
	for c: Control in [_gear, _pill, _radio_button, _vehicle_button, _challenge]:
		if c.is_visible_in_tree():
			out[c.name] = c.get_global_rect()
	for c: Control in [_card, _status, _bench_card]:
		if c != null and c.is_visible_in_tree():
			for b in c.find_children("*", "Button", true, false):
				if (b as Button).is_visible_in_tree():
					out["%s/%s" % [c.name, b.name]] = (b as Control).get_global_rect()
	var disc := func(c: Vector2, r: float) -> Rect2: return Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0)
	if flying:
		out["climb"] = disc.call(_climb_centre(1), PAD_R * pt)
		out["sink"] = disc.call(_climb_centre(-1), PAD_R * pt)
	else:
		out["brake"] = disc.call(_brake_centre(), (CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) * pt)
		if scheme == CLASSIC:
			out["gas"] = disc.call(_gas_centre(), GAS_R * pt)
	return out


## For tools/check_hud.gd: each panel and fixed control on screen now, by name.
func named_rects() -> Dictionary:
	if _dirty:
		_layout()
	var out := {}
	for c: Control in [_gear, _pill, _radio_button, _vehicle_button, _minimap, _wallet, _credit]:
		if c != null and c.visible:
			out[c.name] = Rect2(c.position, c.size)
	out["speed"] = _speed_rect()
	for c in _placed:
		out[(c as Control).name] = _placed[c]
	var pedals := _pedal_rects()
	for i in pedals.size():
		out["pedal%d" % i] = pedals[i]
	return out


# --- the top row -----------------------------------------------------------------------------

## The speed (and the helicopter's height) beside the gear.
func set_speed(kmh: int, metres := -1) -> void:
	var text := "%d km/h" % kmh if metres < 0 else "%d km/h · %d m" % [kmh, metres]
	if text != _speed_text:
		_speed_text = text
		_speed.text = text
		_speed.size = _speed.get_combined_minimum_size()


func set_radio_name(station_name: String) -> void:
	_set_chip(_radio_button, "RADIO", "wył. · off" if station_name == "OFF" else station_name)


## The context button: a call came in (Polish, English under it); pressing it emits pill_pressed.
func show_pill(pl: String, en := "") -> void:
	_set_chip(_pill, pl, en, 96.0)
	if not _pill.visible:
		_pill.visible = true
		_pill_t = 0.0
		_mark()


func hide_pill() -> void:
	if _pill.visible:
		_pill.visible = false
		_mark()


# --- the performance overlay and the bench card ----------------------------------------------

## The performance overlay: small monospace lines on a dark panel (Settings has Quality and the
## TEST button, so the overlay holds only numbers since loop 2e).
func _build_perf() -> void:
	var style := _panel_box(8.0, 8.0)
	_perf = PanelContainer.new()
	_perf.name = "perf"
	_perf.add_theme_stylebox_override("panel", style)
	_perf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perf_label = _label(T_LABEL, Color("#d8f5d0"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_perf_label.add_theme_font_override("font", mono)
	# As wide as its longest line can get, so changing numbers never move the other panels.
	_perf_label.custom_minimum_size.x = mono.get_string_size("x".repeat(44), HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x
	_perf.add_child(_perf_label)
	add_child(_perf)


func show_perf(on: bool) -> void:
	_show(_perf, on)


func set_perf(text: String) -> void:
	_perf_text = text
	_perf_label.text = _perf_lines()


## The overlay's text: all of it, or its first two lines when there is no room for more.
func _perf_lines() -> String:
	if not _perf_compact:
		return _perf_text
	var lines := _perf_text.split("\n")
	return "\n".join(lines.slice(0, 2))


func perf_visible() -> bool:
	return bool(_wants.get(_perf, false))


## Loop 2b: the bench's result: a card in the middle with the numbers (monospace, the same
## text as the clipboard's), KOPIUJ · COPY and ZAMKNIJ · CLOSE (44 pt). Loop 2e: the buttons
## sit in its title row and the numbers wrap to the card, so it fits a phone without shrinking.
func show_bench_card(text: String) -> void:
	_bench_text = text
	if _bench_card == null:
		_build_bench_card()
	_bench_label.text = text
	_set_chip(_bench_copy, "KOPIUJ", "copy", 96.0)
	_bench_card.visible = true
	_fit_bench_card()


func hide_bench_card() -> void:
	if _bench_card != null:
		_bench_card.visible = false


func bench_card_visible() -> bool:
	return _bench_card != null and _bench_card.visible


func _build_bench_card() -> void:
	var style := _panel_box(10.0, 12.0)
	style.border_width_left = roundi(3.0 * pt)
	style.border_color = Color("#5fd4ff")
	_bench_card = PanelContainer.new()
	_bench_card.name = "bench"
	_bench_card.add_theme_stylebox_override("panel", style)
	_bench_card.mouse_filter = Control.MOUSE_FILTER_STOP
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(8.0 * pt))
	_bench_card.add_child(rows)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	rows.add_child(head)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	head.add_child(words)
	var title := _label(T_TITLE, ACCENT)
	title.text = "TEST WYDAJNOŚCI"
	words.add_child(title)
	var sub := _label(T_SUB, SUB)
	sub.text = "Benchmark · wklej to w czacie, paste it into the chat"
	words.add_child(sub)
	_bench_copy = _chip(head, "KOPIUJ", "copy")
	_bench_copy.name = "copy"
	_bench_copy.pressed.connect(func():
		DisplayServer.clipboard_set(_bench_text)
		_set_chip(_bench_copy, "SKOPIOWANE", "copied", 96.0)
		_fit_bench_card()
		print("bench: result copied to the clipboard"))
	var close := _chip(head, "ZAMKNIJ", "close")
	_set_chip(close, "ZAMKNIJ", "close", 96.0)
	close.name = "close"
	close.pressed.connect(hide_bench_card)
	_bench_label = _label(T_LABEL, Color("#d8f5d0"))
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	_bench_label.add_theme_font_override("font", mono)
	rows.add_child(_bench_label)
	_bench_card.visible = false
	add_child(_bench_card)
	get_viewport().size_changed.connect(_fit_bench_card)


func _fit_bench_card() -> void:
	if _bench_card == null or not _bench_card.visible:
		return
	var room := _safe.grow(-8.0 * pt)
	# The numbers wrap to the card's width (the safe area's, less the card's margins).
	var font := _bench_label.get_theme_font("font")
	var natural := 0.0
	for line in _bench_text.split("\n"):
		natural = maxf(natural, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_LABEL)).x)
	var w := minf(natural + 2.0, room.size.x - 26.0 * pt)
	_bench_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bench_label.custom_minimum_size.x = w
	_bench_label.size.x = w
	_bench_label.update_minimum_size()
	_bench_card.scale = Vector2.ONE
	_bench_card.reset_size()
	var need := _bench_card.get_combined_minimum_size()
	# Shrunk only if it still can't fit (never on the phones the HUD is checked at).
	var k := minf(1.0, room.size.y / maxf(need.y, 1.0))
	_bench_card.scale = Vector2(k, k)
	_bench_card.size = need
	_bench_card.position = room.get_center() - need * k * 0.5


# --- the radio ticker ------------------------------------------------------------------------

## The now-playing panel: bottom left, above the credit line, out of the way of the pedals.
func _build_ticker() -> void:
	_ticker_style = _panel_box(8.0, 6.0)
	_ticker_style.content_margin_left = 12.0 * pt
	_ticker_style.content_margin_right = 12.0 * pt
	# Only the left edge takes the station's colour (the card recipe keeps colour off the rest).
	_ticker_style.set_border_width_all(0)
	_ticker_style.border_width_left = roundi(4.0 * pt)
	_ticker_style.border_color = Color("#ff5fc8")
	_ticker = PanelContainer.new()
	_ticker.name = "ticker"
	_ticker.add_theme_stylebox_override("panel", _ticker_style)
	_ticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker.add_child(rows)
	_ticker_label = _label(T_BODY, INK)
	rows.add_child(_ticker_label)
	_ticker_sub = _label(T_SUB, Color("#d9d2e6"))
	rows.add_child(_ticker_sub)
	add_child(_ticker)


## Shows a line on the now-playing ticker for a few seconds: the radio's station changes, and
## the radio host's lines with an English subtitle (held longer and wrapped to a readable width).
func ticker(text: String, colour: Color, subtitle := "") -> void:
	var font := ThemeDB.fallback_font
	var room := minf(TICKER_W * pt, _safe.size.x * 0.5)
	var long := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_BODY)).x > room \
			or font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB)).x > room
	for l: Label in [_ticker_label, _ticker_sub]:
		if long:
			_wrap(l, room / pt)
		else:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.custom_minimum_size.x = 0.0
	_ticker_label.text = text
	_ticker_sub.text = subtitle
	_ticker_sub.visible = subtitle != ""
	_ticker_style.border_color = colour
	_ticker.reset_size()
	_ticker_hold = 4.5 if subtitle == "" else 9.0
	_ticker_left = _ticker_hold
	_show(_ticker, true)
	_mark()
	_slide_ticker(1.0)


## Slides the ticker in from the left edge (or fades it, when it had to go elsewhere).
func _slide_ticker(slide: float) -> void:
	var r: Rect2 = _placed.get(_ticker, Rect2())
	if _ticker_slides:
		_ticker.position.x = lerpf(r.position.x, -r.size.x - 8.0 * pt, slide)
		_ticker.modulate.a = 1.0
	else:
		_ticker.position.x = r.position.x
		_ticker.modulate.a = 1.0 - slide


# --- the toast -------------------------------------------------------------------------------

func _build_toast() -> void:
	var style := _panel_box(8.0, 6.0)
	style.content_margin_left = 14.0 * pt
	style.content_margin_right = 14.0 * pt
	_toast_box = PanelContainer.new()
	_toast_box.name = "toast"
	_toast_box.add_theme_stylebox_override("panel", style)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_child(rows)
	_toast = _label(T_TITLE, INK)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_toast)
	_toast_gloss = _label(T_SUB, SUB)
	_toast_gloss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(_toast_gloss)
	add_child(_toast_box)


## A short line at the bottom for 3 s. Loop 10a: with `gloss`, the Polish line sits above its
## English gloss (smaller, the sub-text colour). Loop 2e: on a dark card, so it reads on any
## street by day or night.
func toast(text: String, gloss := "") -> void:
	# A long line wraps at TOAST_W points rather than running off a phone's screen.
	var font := ThemeDB.fallback_font
	for pair: Array in [[_toast, text, T_TITLE], [_toast_gloss, gloss, T_SUB]]:
		var l: Label = pair[0]
		if font.get_string_size(pair[1], HORIZONTAL_ALIGNMENT_LEFT, -1, _px(pair[2])).x > TOAST_W * pt:
			_wrap(l, TOAST_W)
		else:
			l.autowrap_mode = TextServer.AUTOWRAP_OFF
			l.custom_minimum_size.x = 0.0
	_toast.text = text
	_toast_gloss.text = gloss
	_toast_gloss.visible = gloss != ""
	_toast_left = 3.0
	_toast_box.modulate.a = 1.0
	_toast_box.reset_size()
	_show(_toast_box, true)
	_mark()


# --- the mission panels ----------------------------------------------------------------------

## The call card sits at the top centre under the top row (a side job's at the bottom centre);
## the running mission's status at the top right, so it never hides a target straight ahead.
func _build_mission_panels() -> void:
	_card = PanelContainer.new()
	_card.name = "card"
	_card.add_theme_stylebox_override("panel", _panel_box(10.0, 10.0))
	_card.custom_minimum_size.x = CARD_W * pt
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", roundi(6.0 * pt))
	_card.add_child(box)
	# The Polish title, and the English one beside it on the right (cut short rather than
	# widening the card).
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", roundi(10.0 * pt))
	box.add_child(head)
	_card_title = _label(T_TITLE, ACCENT)
	head.add_child(_card_title)
	_card_title_en = _label(T_LABEL, SUB)
	_card_title_en.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_title_en.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_card_title_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_card_title_en.clip_text = true
	_card_title_en.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(_card_title_en)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", roundi(2.0 * pt))
	box.add_child(text)
	_card_body = _label(T_SUB, INK)
	_wrap(_card_body, CARD_W - 20.0)
	text.add_child(_card_body)
	_card_body_en = _label(T_SUB, SUB)
	_wrap(_card_body_en, CARD_W - 20.0)
	text.add_child(_card_body_en)
	_card_buttons = HBoxContainer.new()
	_card_buttons.add_theme_constant_override("separation", roundi(8.0 * pt))
	box.add_child(_card_buttons)
	add_child(_card)

	_status = PanelContainer.new()
	_status.name = "status"
	_status.add_theme_stylebox_override("panel", _panel_box(10.0, 10.0))
	_status.custom_minimum_size.x = STATUS_W * pt
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	_status.add_child(rows)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", roundi(6.0 * pt))
	rows.add_child(top)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	top.add_child(words)
	_status_title = _label(T_SUB, ACCENT)
	_status_title.clip_text = true
	_status_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	words.add_child(_status_title)
	_status_clock = _label(T_CLOCK, Color.WHITE)
	words.add_child(_status_clock)
	_status_badge = _label(T_TITLE, Color.WHITE)
	_status_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_status_badge)
	var abort := _chip(top, "✕", "", Color(0, 0, 0, 0))
	abort.name = "abort"
	abort.custom_minimum_size = Vector2.ONE * TOUCH * pt
	abort.pressed.connect(func(): abort_pressed.emit())
	_status_icons = Control.new()
	_status_icons.custom_minimum_size.y = 36.0 * pt
	_status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_icons.draw.connect(_draw_status_icons)
	_status_icons.visible = false
	rows.add_child(_status_icons)
	_status_hint = _label(T_SUB, INK)
	_wrap(_status_hint, STATUS_W - 20.0)
	rows.add_child(_status_hint)
	_status_hint_en = _label(T_SUB, SUB)
	_wrap(_status_hint_en, STATUS_W - 20.0)
	rows.add_child(_status_hint_en)
	_status_track = Control.new()
	_status_track.custom_minimum_size.y = 4.0 * pt
	_status_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(_status_track)
	_status_bar = ColorRect.new()
	_status_bar.size = Vector2(0, 4.0 * pt)
	_status_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_track.add_child(_status_bar)
	add_child(_status)

	_challenge = _chip(self, "MRUGNIJ ŚWIATŁAMI", "flash your lights to race (L)")
	_challenge.name = "challenge"
	_challenge.pressed.connect(func(): challenge_pressed.emit())

	_banner = _label(T_BANNER, Color.WHITE, true)
	_banner.name = "banner"
	_banner.add_theme_constant_override("outline_size", _px(5.0))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_banner)

	# The target pointer draws above the panels.
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_target)
	add_child(_overlay)


## A call or a result: title, text, and up to three buttons (emit card_pressed(index)), each
## with the Polish word over the English one. `bottom` puts it at the bottom centre. Loop 2e:
## the title and text in Polish, `title_en` and `body_en` under them in English.
func show_card(title: String, body: String, buttons: PackedStringArray, accent: Color, bottom := false,
		title_en := "", body_en := "") -> void:
	_card_bottom = bottom
	_card_title.text = title
	_card_title.add_theme_color_override("font_color", accent)
	_card_title_en.text = title_en
	_card_title_en.visible = title_en != ""
	_card_body.text = body
	_card_body_en.text = body_en
	_card_body_en.visible = body_en != ""
	for b in _card_buttons.get_children():
		_card_buttons.remove_child(b)
		b.queue_free()
	for i in buttons.size():
		var en := buttons[i]
		var pl: String = WORDS.get(en, en)
		var b := _chip(_card_buttons, pl, "" if pl == en else en.substr(0, 1) + en.substr(1).to_lower())
		b.name = "button%d" % i
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): card_pressed.emit(i))
	_card.reset_size()
	_show(_card, true)
	_show(_status, false)
	hide_pill()
	_mark()


func hide_card() -> void:
	_show(_card, false)


## The running mission or race: where to, the clock, the distance, a hint, how much of the
## hold-still is done (0..1), and an optional badge (race position). Loop 2e: the hint in
## Polish, `hint_en` under it in English.
func show_status(title: String, clock: String, distance: String, hint: String, progress: float, accent: Color,
		badge := "", icons := {}, hint_en := "") -> void:
	if icons != _icons:
		if icons.is_empty() != _icons.is_empty():
			_mark()
		_icons = icons
		_status_icons.visible = not icons.is_empty()
		_status_icons.queue_redraw()
	_status_badge.text = badge
	_status_badge.visible = badge != ""
	_status_badge.add_theme_color_override("font_color", Color("#56d68a") if badge == "1ST" else ACCENT)
	_status_title.text = title
	_status_title.add_theme_color_override("font_color", accent)
	_status_clock.text = clock + "    " + distance
	if _status_hint.text != hint:
		_status_hint.text = hint
	if _status_hint_en.text != hint_en:
		_status_hint_en.text = hint_en
		_status_hint_en.visible = hint_en != ""
	_status_bar.color = accent
	_status_bar.size.x = _status_track.size.x * clampf(progress, 0.0, 1.0)
	_show(_status, true)


func hide_status() -> void:
	_show(_status, false)


## The button that challenges the rival in front (key L does the same): Polish over English.
func show_challenge(text: String, accent: Color, gloss := "flash your lights to race (L)") -> void:
	var top := (_challenge.get_child(0) as Control).get_child(0) as Label
	if top.text != text:
		_set_chip(_challenge, text, gloss, 240.0)
		top.add_theme_color_override("font_color", accent)
	_show(_challenge, true)


func hide_challenge() -> void:
	_show(_challenge, false)


## A big line across the middle of the screen: the race countdown.
func show_banner(text: String, colour: Color) -> void:
	if _banner.text != text:
		_banner.text = text
		_mark()
	_banner.add_theme_color_override("font_color", colour)
	_show(_banner, true)


func hide_banner() -> void:
	_show(_banner, false)


## Coloured dots on the minimap (the rivals), in map coordinates.
func set_minimap_dots(points: PackedVector2Array, colours: PackedColorArray) -> void:
	_mini_dots = points
	_mini_dot_colours = colours


# --- every frame -----------------------------------------------------------------------------

func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= dt
		_toast_box.modulate.a = clampf(_toast_left / 0.6, 0.0, 1.0)
		if _toast_left <= 0.0:
			_show(_toast_box, false)
	if _ticker_left > 0.0 and _ticker.visible:
		# (A ticker waiting for room keeps its time.)
		_ticker_left -= dt
		# Slide in over the first 0.3 s, out over the last 0.4 s.
		var slide := maxf(clampf((_ticker_left - (_ticker_hold - 0.3)) / 0.3, 0.0, 1.0), clampf(1.0 - _ticker_left / 0.4, 0.0, 1.0))
		_slide_ticker(slide * slide)
		if _ticker_left <= 0.0:
			_show(_ticker, false)
	if _wallet_flash > 0.0:
		_wallet_flash -= dt
		if _wallet_flash <= 0.0:
			_mark()  # back to the total: the wallet's width may change
		_wallet.queue_redraw()
	if _note_left > 0.0 and (_note.visible or not _wants.get(_note, false)):
		_note_left -= dt
		_note.modulate.a = clampf(_note_left / 0.6, 0.0, 1.0) * clampf((5.5 - _note_left) / 0.25, 0.0, 1.0)
		if _note_left <= 0.0:
			_show(_note, false)
	if _info_left > 0.0 and (_info_card.visible or not _wants.get(_info_card, false)):
		_info_left -= dt
		_info_card.modulate.a = clampf(_info_left / 0.6, 0.0, 1.0) * clampf((8.0 - _info_left) / 0.25, 0.0, 1.0)
		if _info_left <= 0.0:
			_show(_info_card, false)
	if _pill.visible:
		# The context button breathes so a call that came in is noticed.
		_pill_t += dt
		_pill.modulate.a = 0.78 + 0.22 * cos(_pill_t * 4.0)
	if not _icons.is_empty() and _status.visible:
		_status_icons.queue_redraw()
	# A panel whose text grew or shrank since it was placed: lay out again.
	if not _dirty:
		for c in _floating:
			if c.visible and c.get_combined_minimum_size() != (_placed.get(c, Rect2()) as Rect2).size:
				_mark()
				break


## In the helicopter the brake gives way to climb and sink pads, and the vehicle button offers
## the car back.
func set_flying(on: bool) -> void:
	flying = on
	_set_chip(_vehicle_button, "AUTO" if on else "HELI", "car" if on else "helicopter")
	brake = false
	_brake_index = -1
	gas = false
	_gas_index = -1
	climb = 0.0
	_climb_index = -1
	_pad.queue_redraw()
	_mark()


## The mission target as seen on screen (`at` in screen pixels); an arrow on the screen edge
## points to it when it's off screen.
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


## Touches on the buttons and cards belong to them, not to the stick.
func _over_panel(p: Vector2) -> bool:
	for c: Control in [_gear, _pill, _radio_button, _vehicle_button, _card, _status, _challenge, _bench_card]:
		if c != null and c.visible and c.get_global_rect().has_point(p):
			return true
	return false


# --- the minimap -----------------------------------------------------------------------------

func setup_minimap(data: Dictionary) -> void:
	_mini_radius = MINI_D * 0.5 * pt
	_mini_scale = _mini_radius / MINI_REACH
	_minimap = Control.new()
	_minimap.name = "minimap"
	_minimap.size = Vector2.ONE * _mini_radius * 2.0
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.draw.connect(func(): _minimap.draw_circle(Vector2.ONE * _mini_radius, _mini_radius,
			Color(0.93, 0.9, 0.83, 0.94).lerp(CARD_BG, _night)))
	add_child(_minimap)
	_mini_mesh = _minimap_mesh(data)
	_mini_clip = ShaderMaterial.new()
	_mini_clip.shader = Shader.new()
	_mini_clip.shader.code = MINI_CLIP
	_mini_clip.set_shader_parameter("night", _night)
	_mini_content = Node2D.new()
	_mini_content.material = _mini_clip
	_mini_content.draw.connect(func(): _mini_content.draw_mesh(_mini_mesh, null))
	_minimap.add_child(_mini_content)
	_mini_overlay = Control.new()
	_mini_overlay.size = _minimap.size
	_mini_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mini_overlay.draw.connect(_draw_minimap_overlay)
	_minimap.add_child(_mini_overlay)
	_layout()


func update_minimap(car_xz: Vector2, car_yaw: float, view_yaw: float) -> void:
	if _minimap == null:
		return
	var s := _mini_scale
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
	var s := _mini_scale
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
	strip.call(PackedVector2Array([lo, Vector2(hi.x, lo.y), hi, Vector2(lo.x, hi.y), lo]), Color("#6a503b"), 1.2 * pt)
	for l in data.get("landmarks", []):
		if l["name"] == "Pałac Kultury i Nauki":
			var flat: Array = l["p"]
			var centre := Vector2.ZERO
			for i in range(0, flat.size() - 1, 2):
				centre += Vector2(flat[i], flat[i + 1])
			centre = centre / (flat.size() / 2.0) * s
			for k in 24:
				tri.call(centre, centre + Vector2.from_angle(TAU * k / 24.0) * 2.8 * pt,
						centre + Vector2.from_angle(TAU * (k + 1) / 24.0) * 2.8 * pt, Color("#c9a24a"))
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
	var s := _mini_scale
	# Side-job places: small blinking squares, pinned to the rim up to 700 m away.
	var blink := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.006)
	for i in _mini_pois.size():
		if _mini_pois[i].distance_to(_mini_car) > 700.0:
			continue
		var r := ((_mini_pois[i] - _mini_car) * s).rotated(_mini_yaw)
		var far := r.length() > _mini_radius - 5.0 * pt
		r = r.limit_length(_mini_radius - 5.0 * pt)
		var half := (2.0 if far else 2.8) * pt
		o.draw_rect(Rect2(centre + r - Vector2.ONE * (half + 1.0 * pt), Vector2.ONE * (half + 1.0 * pt) * 2.0), OUTLINE)
		o.draw_rect(Rect2(centre + r - Vector2.ONE * half, Vector2.ONE * half * 2.0), Color(_mini_poi_colours[i], blink))
	for i in _mini_dots.size():
		# Rivals within the minimap's reach; the rest would crowd the rim.
		var r := ((_mini_dots[i] - _mini_car) * s).rotated(_mini_yaw)
		if r.length() < _mini_radius - 4.0 * pt:
			o.draw_circle(centre + r, 2.8 * pt, OUTLINE)
			o.draw_circle(centre + r, 2.0 * pt, _mini_dot_colours[i])
	if _mini_target != Vector2.INF:
		# The mission target, pinned to the rim when it's beyond the map's reach.
		var t := ((_mini_target - _mini_car) * s).rotated(_mini_yaw)
		t = t.limit_length(_mini_radius - 5.0 * pt)
		o.draw_circle(centre + t, 3.8 * pt, OUTLINE)
		o.draw_circle(centre + t, 2.8 * pt, _mini_target_colour)
	var d := _car_dir.normalized()
	var side := Vector2(-d.y, d.x)
	var tip := centre + d * 6.0 * pt
	o.draw_colored_polygon(PackedVector2Array([tip, centre - d * 4.0 * pt + side * 4.0 * pt,
			centre - d * 2.0 * pt, centre - d * 4.0 * pt - side * 4.0 * pt]), Color("#d8432f"))
	o.draw_arc(centre, _mini_radius - 1.0 * pt, 0, TAU, 64, Color(0.17, 0.15, 0.13, 0.85).lerp(Color(1, 1, 1, 0.3), _night), 1.8 * pt)
	var font := ThemeDB.fallback_font
	var fs := _px(T_LABEL)
	var n := centre + _north * (_mini_radius - 8.0 * pt)
	o.draw_string(font, n + Vector2(-fs * 0.3, fs * 0.35), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#2a2622").lerp(INK, _night))


## Loop 2e: the minimap's day or night palette (time_of_day.gd's lights: 0 day, 1 night).
func set_night(amount: float) -> void:
	if is_equal_approx(amount, _night):
		return
	_night = clampf(amount, 0.0, 1.0)
	if _minimap != null:
		_mini_clip.set_shader_parameter("night", _night)
		_minimap.queue_redraw()
		_mini_overlay.queue_redraw()


func set_car_marker(at: Vector2, show: bool) -> void:
	if show != _marker_visible or (show and at.distance_to(_marker) > 0.5):
		_marker = at
		_marker_visible = show
		_pad.queue_redraw()


## Side-job places on the minimap (map coordinates), drawn as blinking squares.
func set_minimap_pois(points: PackedVector2Array, colours: PackedColorArray) -> void:
	_mini_pois = points
	_mini_poi_colours = colours


# --- the wallet and the note card ------------------------------------------------------------

## The wallet sits under the minimap: a gold coin and the złoty, a pink star and the respect;
## a payment shows as "+54 zł" in green in the money's place for a moment (loop 2e: it used to
## float up over the minimap). The note card (an easter egg found) and the landmark card go
## under it.
func _build_wallet() -> void:
	_wallet = Control.new()
	_wallet.name = "wallet"
	_wallet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wallet.draw.connect(_draw_wallet)
	add_child(_wallet)
	_wallet_plate = _panel_box(9.0, 0.0)
	_note_style = _panel_box(8.0, 8.0)
	_note_style.set_border_width_all(0)
	_note_style.border_width_left = roundi(4.0 * pt)
	_note_style.border_color = ACCENT
	_note = PanelContainer.new()
	_note.name = "note"
	_note.add_theme_stylebox_override("panel", _note_style)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", roundi(2.0 * pt))
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.add_child(rows)
	_note_title = _label(T_SUB, Color("#ff4fd8"))
	rows.add_child(_note_title)
	_note_body = _label(T_SUB, INK)
	_wrap(_note_body, NOTE_W - 20.0)
	rows.add_child(_note_body)
	add_child(_note)

	var info_style := _note_style.duplicate() as StyleBoxFlat
	info_style.border_color = ACCENT
	_info_card = PanelContainer.new()
	_info_card.name = "info"
	_info_card.add_theme_stylebox_override("panel", info_style)
	_info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", roundi(2.0 * pt))
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_card.add_child(lines)
	_info_title = _label(T_BODY, ACCENT)
	lines.add_child(_info_title)
	_info_pl = _label(T_SUB, INK)
	_info_en = _label(T_SUB, SUB)
	for l in [_info_pl, _info_en]:
		_wrap(l, NOTE_W - 20.0)
		lines.add_child(l)
	add_child(_info_card)


func set_wallet(zl: int, respect: int, gained := 0) -> void:
	_wallet_zl = zl
	_wallet_respect = respect
	if gained != 0:
		_wallet_gain = gained
		_wallet_flash = WALLET_FLASH
	_wallet.queue_redraw()
	_mark()


## The text in the money's place: the payment for its first 1.6 s, then the total.
func _money_text() -> String:
	if _wallet_flash > WALLET_FLASH - 1.6:
		return ("+" if _wallet_gain > 0 else "") + _money(_wallet_gain)
	return _money(_wallet_zl)


## The wallet's width in pixels: coin, money, star, respect.
func _wallet_width() -> float:
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var money := maxf(font.get_string_size(_money(_wallet_zl), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
			font.get_string_size("+" + _money(_wallet_gain), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if _wallet_flash > 0.0 else 0.0)
	return (8.0 + 20.0 + 10.0 + 20.0 + 10.0) * pt + money + font.get_string_size(str(_wallet_respect), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _draw_wallet() -> void:
	var w := _wallet
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var y := w.size.y * 0.5
	# Loop 2e: on a plate in the card recipe.
	w.draw_style_box(_wallet_plate, Rect2(Vector2.ZERO, w.size))
	# A coin with a "zł" stamp.
	var coin := Vector2(16.0 * pt, y)
	w.draw_circle(coin, 8.0 * pt, OUTLINE)
	w.draw_circle(coin, 6.8 * pt, Color("#f2c12e"))
	w.draw_circle(coin, 4.6 * pt, Color("#d9a21f"))
	var x := 28.0 * pt
	var gain := _wallet_flash > WALLET_FLASH - 1.6
	var money := _money_text()
	var base := Vector2(x, y + fs * 0.36)
	var colour := Color("#ffe27a")
	if gain:
		colour = Color(0.55, 1.0, 0.6).lerp(Color("#ffe27a"), 0.5 + 0.5 * sin(_wallet_flash * 12.0))
	w.draw_string(font, base, money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, colour)
	x += maxf(font.get_string_size(money, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x,
			font.get_string_size(_money(_wallet_zl), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x) + 10.0 * pt
	# A five-pointed star for respect.
	var star := PackedVector2Array()
	var outer := PackedVector2Array()
	var c := Vector2(x + 8.0 * pt, y)
	for k in 10:
		var a := -PI / 2.0 + k * PI / 5.0
		star.append(c + Vector2(cos(a), sin(a)) * (7.2 if k % 2 == 0 else 3.2) * pt)
		outer.append(c + Vector2(cos(a), sin(a)) * (8.8 if k % 2 == 0 else 4.3) * pt)
	w.draw_colored_polygon(outer, OUTLINE)
	w.draw_colored_polygon(star, Color("#ff4fd8"))
	var resp := str(_wallet_respect)
	base = Vector2(x + 20.0 * pt, y + fs * 0.36)
	w.draw_string(font, base, resp, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#ffd0f4"))


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
	_note.reset_size()
	_show(_note, true)
	_show(_info_card, false)
	_info_left = 0.0
	_note.modulate.a = 0.0
	_note_left = 5.5
	_mark()


## v0.8: a landmark's info card (it was tapped): the name, a Polish line or two and the
## English under it. It takes the note card's place for eight seconds.
func show_info(title: String, polish: String, english: String) -> void:
	_info_title.text = title
	_info_pl.text = polish
	_info_en.text = english
	_show(_note, false)
	_note_left = 0.0
	_info_card.reset_size()
	_show(_info_card, true)
	_info_card.modulate.a = 0.0
	_info_left = 8.0
	_mark()


# --- the status panel's pictures --------------------------------------------------------------

## {"heat": 0..1}: a wrapped kebab with steam that fades as it cools. {"jars": [intact,
## total], "shake": 0..1}: a row of mum's jars, the broken ones as shards, rattling
## when one is close to breaking. Drawn in units of 0.62 pt (loop 2e kept their old size on the
## user's Pro Max).
func _draw_status_icons() -> void:
	var c := _status_icons
	var h := c.size.y
	var q := 0.62 * pt
	if _icons.has("heat"):
		var heat: float = _icons["heat"]
		var x := 6.0 * q
		var u := q * 1.5
		# The kebab: a wrap in foil, a cone with the meat and salad showing at the top.
		var foil := PackedVector2Array([Vector2(x + 8 * u, h - 2 * u), Vector2(x + 1 * u, h - 14 * u), Vector2(x + 15 * u, h - 14 * u)])
		c.draw_colored_polygon(foil, Color("#e8c48a").lerp(Color("#b9c6d6"), clampf(1.0 - heat * 1.6, 0.0, 1.0)))
		c.draw_rect(Rect2(Vector2(x + 1 * u, h - 16 * u), Vector2(14 * u, 3 * u)), Color("#c9ced6"))
		c.draw_rect(Rect2(Vector2(x + 3 * u, h - 19 * u), Vector2(10 * u, 3 * u)), Color("#7a4a2a"))
		c.draw_rect(Rect2(Vector2(x + 5 * u, h - 20.5 * u), Vector2(3 * u, 1.5 * u)), Color("#4f9e3f"))
		# Steam: three wavy wisps rising from it, shorter and fainter as it cools.
		var t := Time.get_ticks_msec() * 0.003
		var a := clampf((heat - 0.1) / 0.5, 0.0, 1.0)
		var rise := maxf(h - 22 * u, 0.0) * (0.35 + heat * 0.65)
		for j in 3:
			var pts := PackedVector2Array()
			var sx := x + (3 + j * 5) * u
			for k in 9:
				var f := k / 8.0
				pts.append(Vector2(sx + sin(t * 2.0 + j * 2.1 + f * 6.0) * 1.8 * u, h - 22 * u - f * rise))
			if a > 0.02:
				c.draw_polyline(pts, Color(1, 1, 1, a * (0.9 - j * 0.12)), 2.0 * q)
		# A heat bar beside it, warm to cold.
		var bar := Rect2(Vector2(x + 24 * u, h * 0.5 - 4 * q), Vector2(c.size.x - x - 26 * u, 8 * q))
		c.draw_rect(bar.grow(1.5 * q), OUTLINE)
		c.draw_rect(bar, Color(0.2, 0.22, 0.28))
		var hot := Color("#ff5a2a").lerp(ACCENT, 0.3)
		c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(heat, 0.0, 1.0), bar.size.y)), Color("#7fb8de").lerp(hot, clampf(heat * 1.4, 0.0, 1.0)))
	elif _icons.has("jars"):
		var jars: Array = _icons["jars"]
		var intact: int = jars[0]
		var total: int = jars[1]
		var shake: float = _icons.get("shake", 0.0)
		var t := Time.get_ticks_msec() * 0.05
		var y0 := h * 0.5 - 7.0 * q
		for k in total:
			var x := (6 + k * 24) * q
			var jiggle := Vector2(sin(t + k * 2.1), cos(t * 1.3 + k)) * shake * shake * 2.2 * q if k < intact else Vector2.ZERO
			var body := Rect2(Vector2(x, y0) + jiggle, Vector2(16 * q, 20 * q))
			if k < intact:
				c.draw_rect(body.grow(1.5 * q), OUTLINE)
				c.draw_rect(body, Color("#d9a441"))
				c.draw_rect(Rect2(body.position + Vector2(2 * q, 7 * q), Vector2(12 * q, 7 * q)), Color("#f4ead2"))
				c.draw_rect(Rect2(body.position + Vector2(-1 * q, -5 * q), Vector2(18 * q, 5 * q)), Color("#c8282a"))
			else:
				# Shards and a puddle.
				c.draw_rect(Rect2(Vector2(x - 2 * q, y0 + 16 * q), Vector2(20 * q, 4 * q)), Color("#a0663a", 0.8))
				for s in [Vector2(1, 8), Vector2(8, 4), Vector2(12, 10)]:
					var p: Vector2 = Vector2(x, y0) + s * q
					c.draw_colored_polygon(PackedVector2Array([p, p + Vector2(4, 6) * q, p + Vector2(-2, 6) * q]), Color("#c9d6dc"))
		var label := "%d/%d" % [intact, total]
		var font := ThemeDB.fallback_font
		var fs := _px(T_BODY)
		var at := Vector2((10 + total * 24) * q, h * 0.5 + fs * 0.36)
		c.draw_string(font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if intact == total else Color("#ffb05a"))


# --- the pedals and the stick ----------------------------------------------------------------

func _brake_centre() -> Vector2:
	if scheme == CLASSIC:
		# Left of GAS and a little lower, so the thumb rolls from one to the other.
		return Vector2(_safe.end.x - 156.0 * pt, _safe.end.y - 42.0 * pt)
	return Vector2(_safe.end.x - 56.0 * pt, _safe.end.y - 50.0 * pt)


## Loop 2a: the GAS pedal (Classic), where BRAKE is in the other schemes.
func _gas_centre() -> Vector2:
	return Vector2(_safe.end.x - 58.0 * pt, _safe.end.y - 52.0 * pt)


## The brake's touch radius (a little larger than drawn).
func _brake_reach() -> float:
	return (CLASSIC_BRAKE_REACH if scheme == CLASSIC else BRAKE_REACH) * pt


## Where Classic's steering strip is hinted until a thumb comes down.
func _strip_hint_centre() -> Vector2:
	return Vector2(maxf(_safe.position.x + 110.0 * pt, _screen.x * 0.16), _safe.end.y - 60.0 * pt)


func _on_pedals(p: Vector2) -> bool:
	if flying:
		return false
	return p.distance_to(_brake_centre()) < _brake_reach() or (scheme == CLASSIC and p.distance_to(_gas_centre()) < GAS_REACH * pt)


## Loop 2a: the on-screen controls for a control scheme (drive_controls.gd).
func set_scheme(s: int) -> void:
	scheme = s
	gas = false
	_gas_index = -1
	brake = false
	_brake_index = -1
	_pad.queue_redraw()
	_mark()


## True while the stick's (or steering strip's) finger is down.
func stick_active() -> bool:
	return _stick_index != -1


## Loop 2a, for screenshots and replays (--stick=x,y --pedal=gas|brake): hold the stick at a
## deflection with its centre at `origin` (screen pixels), and a pedal.
func hold_stick(origin: Vector2, v: Vector2) -> void:
	_stick_index = 99
	_stick_origin = origin
	var radius := STICK_R * pt
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
	return Vector2(_safe.end.x - 56.0 * pt, _safe.end.y - (130.0 if direction > 0 else 44.0) * pt)


## Touches above this line belong to the top row (not the stick, not a tap on the city).
func _row_bottom() -> float:
	return (ROW_Y + ROW_H + 4.0) * pt


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
				pass  # a button takes it
			elif flying and (touch.position.distance_to(_climb_centre(1)) < PAD_REACH * pt
					or touch.position.distance_to(_climb_centre(-1)) < PAD_REACH * pt):
				_climb_index = touch.index
				climb = 1.0 if touch.position.distance_to(_climb_centre(1)) < touch.position.distance_to(_climb_centre(-1)) else -1.0
			elif not flying and scheme == CLASSIC and touch.position.distance_to(_gas_centre()) < GAS_REACH * pt:
				_gas_index = touch.index
				gas = true
			elif not flying and touch.position.distance_to(_brake_centre()) < _brake_reach():
				_brake_index = touch.index
				brake = true
			elif touch.position.x < size.x * 0.6 and touch.position.y > _row_bottom() and _stick_index == -1:
				_stick_index = touch.index
				_stick_origin = touch.position
				_stick_point = touch.position
				stick = Vector2.ZERO
			elif touch.position.y > _row_bottom():
				_free_touches[touch.index] = touch.position
				_pinch_distance = _pinch_span()
				_twist_angle = _pinch_angle()
				_twist = 0.0
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
			_twist_angle = _pinch_angle()
			_twist = 0.0
		_pad.queue_redraw()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if _taps.has(drag.index) and drag.position.distance_to(_taps[drag.index][0]) > 10.0 * pt:
			_taps.erase(drag.index)  # a drag (steering, a pinch), not a tap
		if _free_touches.has(drag.index):
			_free_touches[drag.index] = drag.position
			var span := _pinch_span()
			if span > 0.0 and _pinch_distance > 0.0:
				pinched.emit(span / _pinch_distance)
			_pinch_distance = span
			# Loop 2e: two fingers turning together: every TWIST radians, a 90° turn of the view
			# (main.gd only takes it with the fixed camera).
			if _free_touches.size() == 2:
				var angle := _pinch_angle()
				_twist += wrapf(angle - _twist_angle, -PI, PI)
				_twist_angle = angle
				if absf(_twist) >= TWIST:
					rotate_pressed.emit(1 if _twist > 0.0 else -1)
					_twist = 0.0
		if drag.index == _stick_index:
			var radius := STICK_R * pt
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
			if to_gas < GAS_REACH * pt and to_gas < to_brake and drag.index == _brake_index:
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


## A tap: one finger down and up again within 0.35 s and 10 pt, not on a control, the pedals
## or the climb pads, and not part of a pinch. It goes out as `tapped`; the stick it may have
## started never moved, so the car is not steered by it.
func _track_tap(touch: InputEventScreenTouch) -> void:
	if touch.pressed:
		var p := touch.position
		var on_control := _over_panel(p) or p.y < _row_bottom() or (_minimap != null and _minimap.get_global_rect().has_point(p)) \
				or (flying and (p.distance_to(_climb_centre(1)) < PAD_REACH * pt or p.distance_to(_climb_centre(-1)) < PAD_REACH * pt)) \
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
	if touch.position.distance_to(start[0]) <= 10.0 * pt and Time.get_ticks_msec() - int(start[1]) <= 350:
		tapped.emit(touch.position)


func _pinch_span() -> float:
	if _free_touches.size() != 2:
		return 0.0
	var points: Array = _free_touches.values()
	return (points[0] as Vector2).distance_to(points[1])


## The angle of the line between the two free fingers (0 with fewer or more).
func _pinch_angle() -> float:
	if _free_touches.size() != 2:
		return 0.0
	var points: Array = _free_touches.values()
	return ((points[1] as Vector2) - (points[0] as Vector2)).angle()


## Polish over English, centred on a pedal (the Polish word smaller if it would not fit).
func _pad_words(c: Vector2, r: float, pl: String, en: String) -> void:
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB)
	if font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r * 2.0 - 10.0 * pt:
		fs = _px(T_LABEL)
	var es := _px(T_LABEL)
	var w := font.get_string_size(pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ew := font.get_string_size(en, HORIZONTAL_ALIGNMENT_LEFT, -1, es).x
	_pad.draw_string(font, c + Vector2(-w * 0.5, -1.0 * pt), pl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
	_pad.draw_string(font, c + Vector2(-ew * 0.5, es * 0.95), en, HORIZONTAL_ALIGNMENT_LEFT, -1, es, SUB)


## Loop 2e: a round control on a solid plate in the card recipe (it used to be a 1-px ring that
## vanished over trees); held, it lights up in the accent.
func _plate(c: Vector2, r: float, held: bool) -> void:
	_pad.draw_circle(c, r, CARD_BG)
	if held:
		_pad.draw_circle(c, r, Color(1, 0.82, 0.25, 0.32))
	_pad.draw_arc(c, r - 0.6 * pt, 0, TAU, 40, ACCENT if held else Color(1, 1, 1, 0.3), 1.3 * pt)


func _draw_pad() -> void:
	if _marker_visible:
		# A yellow pointer over the player's car.
		var m := _marker - Vector2(0, 6.0 * pt)
		var tri := PackedVector2Array([m + Vector2(-5.5, -8.5) * pt, m + Vector2(5.5, -8.5) * pt, m])
		var outline := PackedVector2Array([m + Vector2(-7.6, -10.0) * pt, m + Vector2(7.6, -10.0) * pt, m + Vector2(0, 2.2) * pt])
		_pad.draw_colored_polygon(outline, Color("#2a2622"))
		_pad.draw_colored_polygon(tri, ACCENT)
	if _stick_index != -1 and scheme == CLASSIC and not flying:
		# The steering strip on its plate: arrows at the ends and the thumb's knob.
		var half := STICK_R * pt
		var o := _stick_origin
		_strip_plate.set_corner_radius_all(roundi(16.0 * pt))
		_pad.draw_style_box(_strip_plate, Rect2(o - Vector2(half + 16.0 * pt, 16.0 * pt), Vector2(half * 2.0 + 32.0 * pt, 32.0 * pt)))
		for side in [-1.0, 1.0]:
			var tip := o + Vector2(side * (half + 8.0 * pt), 0)
			_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 7, -5.5) * pt, tip + Vector2(-side * 7, 5.5) * pt]), SUB)
		_pad.draw_circle(_stick_point, 13.0 * pt, INK)
	elif _stick_index != -1:
		_pad.draw_circle(_stick_origin, STICK_R * pt, Color(CARD_BG, 0.72))
		_pad.draw_arc(_stick_origin, STICK_R * pt - 0.6 * pt, 0, TAU, 40, Color(1, 1, 1, 0.3), 1.3 * pt)
		_pad.draw_circle(_stick_point, 16.0 * pt, Color(INK, 0.9))
	if flying:
		for direction in _UP_DOWN:
			var c := _climb_centre(direction)
			_plate(c, PAD_R * pt, climb == float(direction))
			var s: float = 9.0 * pt * direction
			_pad.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.6), c + Vector2(-s, s * 0.6)]), INK)
		return
	var bc := _brake_centre()
	var br := (CLASSIC_BRAKE_R if scheme == CLASSIC else BRAKE_R) * pt
	_plate(bc, br, brake)
	_pad_words(bc, br, "HAMULEC", "brake")
	if scheme == CLASSIC:
		var gc := _gas_centre()
		_plate(gc, GAS_R * pt, gas)
		_pad_words(gc, GAS_R * pt, "GAZ", "gas")
		if _stick_index == -1:
			# Where the steering strip lives, on a small plate, until a thumb comes down.
			var o := _strip_hint_centre()
			_strip_plate.set_corner_radius_all(roundi(12.0 * pt))
			_pad.draw_style_box(_strip_plate, Rect2(o - Vector2(52, 12) * pt, Vector2(104, 24) * pt))
			_pad.draw_line(o - Vector2(30, 0) * pt, o + Vector2(30, 0) * pt, SUB, 1.6 * pt)
			for side in [-1.0, 1.0]:
				var tip := o + Vector2(side * 44, 0) * pt
				_pad.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-side * 7.5, -6) * pt, tip + Vector2(-side * 7.5, 6) * pt]), INK)


## Loop 2a: the gear, drawn like the HUD's buttons (a dark disc with a light gear).
func _draw_gear() -> void:
	var c := Vector2.ONE * TOUCH * 0.5 * pt
	var held := _gear.button_pressed or _gear.is_pressed()
	_gear.draw_circle(c, 20.0 * pt, CARD_BG)
	_gear.draw_arc(c, 20.0 * pt - 0.5 * pt, 0, TAU, 40, ACCENT if held else Color(1, 1, 1, 0.22), maxf(1.0, 0.6 * pt))
	var teeth := 8
	var pts := PackedVector2Array()
	for k in teeth * 4:
		var a := TAU * (k / 4.0) / teeth - PI / teeth * 0.5
		var r := (11.0 if k % 4 == 1 or k % 4 == 2 else 8.0) * pt
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	_gear.draw_colored_polygon(pts, ACCENT if held else INK)
	_gear.draw_circle(c, 3.4 * pt, Color(CARD_BG, 1.0))


## On screen: a bobbing pointer over the target with the distance. Off screen: an arrow on the
## safe area's edge (below the top row, clear of the status panel), pointing the way.
func _draw_target() -> void:
	if not _target_visible:
		return
	var o := _overlay
	var margin := 28.0 * pt
	var font := ThemeDB.fallback_font
	var fs := _px(T_BODY)
	var w := font.get_string_size(_target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var top := _row_bottom() + 24.0 * pt
	if _status.visible:
		# Keep the edge arrow off the status panel in the top right.
		top = maxf(top, _status.get_global_rect().end.y + 8.0 * pt)
	var inside := Rect2(_safe.position.x + margin, top, _safe.size.x - margin * 2.0, _safe.end.y - margin - top)
	if inside.size.x <= 0.0 or inside.size.y <= 0.0:
		return  # no room to point (a headless run's tiny window)
	var outline := _px(2.5)
	if inside.has_point(_target_at):
		var bob := sin(Time.get_ticks_msec() * 0.006) * 2.0 * pt
		var m := _target_at - Vector2(0, 16.0 * pt + bob)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-8, -11) * pt, m + Vector2(8, -11) * pt, m + Vector2(0, 2.5) * pt]), OUTLINE)
		o.draw_colored_polygon(PackedVector2Array([m + Vector2(-5.5, -9.5) * pt, m + Vector2(5.5, -9.5) * pt, m]), _target_colour)
		var at := m + Vector2(-w * 0.5, -15.0 * pt)
		o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE)
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
	var a := 13.5 * pt
	o.draw_colored_polygon(PackedVector2Array([tip + dir * 2.5 * pt, tip - dir * (a + 2.5 * pt) + side * (a * 0.7 + 2.0 * pt),
			tip - dir * (a + 2.5 * pt) - side * (a * 0.7 + 2.0 * pt)]), OUTLINE)
	o.draw_colored_polygon(PackedVector2Array([tip, tip - dir * a + side * a * 0.6, tip - dir * a - side * a * 0.6]), _target_colour)
	var at := tip - dir * (a + 18.0 * pt) - Vector2(w * 0.5, -fs * 0.35)
	o.draw_string_outline(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, OUTLINE)
	o.draw_string(font, at, _target_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _target_colour)
