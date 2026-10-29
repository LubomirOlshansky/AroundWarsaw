extends PanelContainer
## Loop 3g-1 (police.md sections 7, 11.2): the pull-over card, Dialogue Manager's balloon
## re-skinned to the HUD's one card recipe (art bible): a near-black violet card at ~94 %, the
## speaker's accent as a 4 pt edge (police blue), the portrait on the left, the Polish line
## (15 pt, ink #fbf7ee) over its English (13 pt, #c9c2d8), reply buttons at least 44 pt tall.
## Sized in points (loop 2e; `pt` from the HUD), placed by the HUD's layout at the bottom centre
## (hud.gd `add_panel`). police.gd drives it a line at a time; a tap on the card skips the
## beat, a tap on a reply picks it.
##
## The portraits are drawn from simple shapes until part two brings the PixelLab ones
## (police.md section 9: Sierżant Bogdan, Posterunkowy Kacper, Strażnik Henio).

signal advanced
signal replied(index: int)

const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const CARD_BG := Color(0.07, 0.06, 0.1, 0.94)
const POLICE_BLUE := Color("#1f4fd8")
## The speaker's name: police blue lightened to read on the dark card.
const NAME_BLUE := Color("#8fb0ff")
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
const TOUCH := 44.0
## The text column: wide enough that a line and its English take a line or two each, so the card
## stays low enough to pass under the wallet on a 375 pt tall phone (check_hud.gd).
const TEXT_W := 520.0
const FACE := 56.0

var pt := 1.0
var _style: StyleBoxFlat
var _portrait: Control
var _speaker: Label
var _pl: Label
var _en: Label
var _replies: HBoxContainer
var _who := ""


func _ready() -> void:
	name = "police_talk"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style = StyleBoxFlat.new()
	_style.bg_color = CARD_BG
	_style.set_corner_radius_all(roundi(10.0 * pt))
	_style.set_content_margin_all(10.0 * pt)
	_style.content_margin_left = 14.0 * pt
	_style.border_color = POLICE_BLUE
	_style.border_width_left = roundi(4.0 * pt)
	add_theme_stylebox_override("panel", _style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", roundi(12.0 * pt))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2.ONE * FACE * pt
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.draw.connect(_draw_face)
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", roundi(2.0 * pt))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	_speaker = _label(T_LABEL, NAME_BLUE)
	col.add_child(_speaker)
	_pl = _label(T_BODY, INK)
	_pl.name = "talk_pl"
	_en = _label(T_SUB, SUB)
	_en.name = "talk_en"
	for l in [_pl, _en]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = TEXT_W * pt
		col.add_child(l)
	_replies = HBoxContainer.new()
	_replies.add_theme_constant_override("separation", roundi(8.0 * pt))
	_replies.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_replies)
	gui_input.connect(_on_input)


func _label(points: float, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", maxi(1, roundi(points * pt)))
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A line: who says it, the Polish, the English, and the replies ([Polish, English] each).
func show_line(speaker: String, polish: String, english: String, replies: Array) -> void:
	_who = speaker
	_speaker.text = speaker
	_pl.text = polish
	_en.text = english
	_en.visible = english != ""
	for c in _replies.get_children():
		_replies.remove_child(c)
		c.queue_free()
	for i in replies.size():
		_replies.add_child(_reply_button(i, replies[i][0], replies[i][1]))
	_replies.visible = not replies.is_empty()
	_portrait.queue_redraw()
	reset_size()


func _reply_button(i: int, pl: String, en: String) -> Button:
	var b := Button.new()
	b.name = "reply%d" % i
	b.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = CARD_BG
	normal.set_corner_radius_all(roundi(10.0 * pt))
	normal.border_color = Color(1, 1, 1, 0.22)
	normal.set_border_width_all(maxi(1, roundi(1.0 * pt)))
	normal.set_content_margin_all(4.0 * pt)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(1, 0.82, 0.25, 0.3)
	pressed.border_color = Color("#ffd23f")
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
	var font := ThemeDB.fallback_font
	var w := 0.0
	for t: Array in [[pl, T_BODY, INK], [en, T_LABEL, SUB]]:
		var l := _label(t[1], t[2])
		l.text = t[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		words.add_child(l)
		w = maxf(w, font.get_string_size(t[0], HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(float(t[1]) * pt)).x)
	b.add_child(words)
	b.custom_minimum_size = Vector2(w + 24.0 * pt, TOUCH * pt)
	b.pressed.connect(func(): replied.emit(i))
	return b


func _on_input(event: InputEvent) -> void:
	var tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
			or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if tap:
		accept_event()
		advanced.emit()


## A face from simple shapes: a cap with a dark visor (no badge, no crest), the sergeant's grey
## moustache, the constable's younger look.
func _draw_face() -> void:
	var c := _portrait
	var s := c.size
	var u := s.x / FACE
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("#1b2338")
	plate.set_corner_radius_all(roundi(8.0 * u))
	c.draw_style_box(plate, Rect2(Vector2.ZERO, s))
	var mid := s.x * 0.5
	# Shoulders, the uniform's dark blue.
	c.draw_rect(Rect2(Vector2(mid - 22.0 * u, 44.0 * u), Vector2(44.0 * u, 12.0 * u)), Color("#24324a"))
	# The face.
	c.draw_circle(Vector2(mid, 30.0 * u), 13.0 * u, Color("#e2b48c"))
	var young := _who.begins_with("Posterunkowy")
	# The cap: crown and visor.
	c.draw_rect(Rect2(Vector2(mid - 15.0 * u, 11.0 * u), Vector2(30.0 * u, 9.0 * u)), Color("#24324a"))
	c.draw_rect(Rect2(Vector2(mid - 13.0 * u, 20.0 * u), Vector2(26.0 * u, 3.0 * u)), Color("#121620"))
	# Eyes.
	for side in [-1.0, 1.0]:
		c.draw_rect(Rect2(Vector2(mid + side * 5.0 * u - 1.5 * u, 27.0 * u), Vector2(3.0 * u, 3.0 * u)), Color("#2a2622"))
	if not young:
		# The sergeant's grey moustache.
		c.draw_rect(Rect2(Vector2(mid - 7.0 * u, 34.0 * u), Vector2(14.0 * u, 3.5 * u)), Color("#b8b4ac"))
	else:
		c.draw_rect(Rect2(Vector2(mid - 3.0 * u, 36.0 * u), Vector2(6.0 * u, 1.5 * u)), Color("#9c6b52"))
