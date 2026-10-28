extends Control
## Speech bubbles and name tags over things in the world, drawn in the HUD layer
## (full resolution, above the pixel-art view, so they need no 3D transparency).
##
## Anyone can talk: pass a Node3D (the bubble follows it) or a Callable that returns
## a world position. A line is Polish with an optional English subtitle; it types
## itself out, stays a few seconds and fades. One bubble per speaker: a new line
## replaces the old one. Off-screen speakers are pinned to the screen edge with the
## tail pointing their way.
##
##   bubbles.say(rival_node, "Seba z Pragi", "Ej, kierowniku!", "Hey, boss!")
##   bubbles.tag(rival_node, "Seba z Pragi", Color("#b45cff"))

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

## World position -> screen pixels; set by the game (camera and pixel scale).
var project: Callable
## UI scale (the HUD's).
var ui := 1.0

const TYPE_RATE := 42.0      # characters per second
const FADE := 0.35
const LINE_SIZE := 15
const SUB_SIZE := 12
const NAME_SIZE := 11
const WIDTH := 290.0

var _bubbles: Array[Dictionary] = []
var _tags: Array[Dictionary] = []
var _panel: StyleBoxFlat
var _tag_box: StyleBoxFlat


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = StyleBoxFlat.new()
	_panel.bg_color = Color("#fbf7ee")
	_panel.border_color = Color("#1d1b19")
	_panel.set_border_width_all(maxi(2, int(2 * ui)))
	_panel.set_corner_radius_all(int(9 * ui))
	_tag_box = StyleBoxFlat.new()
	_tag_box.bg_color = Color(0.09, 0.09, 0.11, 0.78)
	_tag_box.set_corner_radius_all(int(5 * ui))


## Shows `line` (and an English `subtitle`) over `anchor` for `seconds` after it has
## typed out. `height` lifts the tail above a Node3D anchor's origin.
func say(anchor: Variant, speaker: String, line: String, subtitle := "", seconds := 4.0,
		accent := Color("#ffd23f"), height := 2.6) -> void:
	hush(anchor)
	var font := ThemeDB.fallback_font
	var w := WIDTH * ui
	var line_size := font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, w, int(LINE_SIZE * ui))
	var sub_size := Vector2.ZERO
	if subtitle != "":
		sub_size = font.get_multiline_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, w, int(SUB_SIZE * ui))
	var name_h := font.get_height(int(NAME_SIZE * ui)) if speaker != "" else 0.0
	var pad := 10.0 * ui
	var size := Vector2(maxf(line_size.x, maxf(sub_size.x, font.get_string_size(speaker, HORIZONTAL_ALIGNMENT_LEFT, -1, int(NAME_SIZE * ui)).x)),
			name_h + line_size.y + (sub_size.y + 3.0 * ui if subtitle != "" else 0.0)) + Vector2.ONE * pad * 2.0
	var typing := line.length() / TYPE_RATE
	_bubbles.append({"anchor": anchor, "speaker": speaker, "line": line, "sub": subtitle, "age": 0.0,
			"life": typing + seconds, "typing": typing, "accent": accent, "height": height, "size": size,
			"name_h": name_h, "line_h": line_size.y})
	queue_redraw()


## Removes the bubble over `anchor`, if any.
func hush(anchor: Variant) -> void:
	for i in range(_bubbles.size() - 1, -1, -1):
		if _same(_bubbles[i]["anchor"], anchor):
			_bubbles.remove_at(i)
	queue_redraw()


## Anchors can be nodes or callables; == between the two kinds is an error.
static func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


func clear() -> void:
	_bubbles.clear()
	queue_redraw()


## How many bubbles are up.
func count() -> int:
	return _bubbles.size()


func is_talking(anchor: Variant) -> bool:
	for b in _bubbles:
		if _same(b["anchor"], anchor):
			return true
	return false


## A small name label that stays over `anchor` until untag(); hidden while it talks.
func tag(anchor: Variant, text: String, colour: Color, height := 2.6) -> void:
	for t in _tags:
		if _same(t["anchor"], anchor):
			t["text"] = text
			t["colour"] = colour
			return
	_tags.append({"anchor": anchor, "text": text, "colour": colour, "height": height})


func untag(anchor: Variant) -> void:
	for i in range(_tags.size() - 1, -1, -1):
		if _same(_tags[i]["anchor"], anchor):
			_tags.remove_at(i)


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	if _bubbles.is_empty() and _tags.is_empty():
		return
	for i in range(_bubbles.size() - 1, -1, -1):
		var b := _bubbles[i]
		b["age"] = float(b["age"]) + dt
		if b["age"] >= b["life"] or (b["anchor"] is Object and not is_instance_valid(b["anchor"])):
			_bubbles.remove_at(i)
	queue_redraw()


func _where(anchor: Variant, height: float) -> Vector3:
	if anchor is Callable:
		return (anchor as Callable).call()
	if anchor is Node3D and is_instance_valid(anchor):
		return (anchor as Node3D).global_position + Vector3(0, height, 0)
	return Vector3.INF


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_paint()
	spent_usec += Time.get_ticks_usec() - t0


func _paint() -> void:
	if not project.is_valid():
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size
	for t in _tags:
		if is_talking(t["anchor"]):
			continue
		var p := _where(t["anchor"], t["height"])
		if p == Vector3.INF:
			continue
		var at: Vector2 = project.call(p)
		var fs := int(NAME_SIZE * ui)
		var text: String = t["text"]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(at - Vector2(w * 0.5 + 6.0 * ui, font.get_height(fs) + 14.0 * ui), Vector2(w + 12.0 * ui, font.get_height(fs) + 6.0 * ui))
		if not Rect2(Vector2.ZERO, screen).encloses(box):
			continue
		draw_style_box(_tag_box, box)
		draw_string(font, box.position + Vector2(6.0 * ui, 3.0 * ui + font.get_ascent(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, t["colour"])
	# Two speakers close together: the later bubble steps up (or down, at the top
	# of the screen) out of the earlier one's way, so they never overlap.
	var placed: Array[Rect2] = []
	# The HUD's panels that are up (the call pill, a card, the status) count as taken.
	var hud := get_parent()
	if hud != null and hud.has_method("panel_rects"):
		placed.append_array(hud.panel_rects())
	for b in _bubbles:
		var p := _where(b["anchor"], b["height"])
		if p == Vector3.INF:
			continue
		var at: Vector2 = project.call(p)
		var rect := _place(b, at, screen)
		var gap := 6.0 * ui
		for attempt in 6:
			var hit := false
			for r in placed:
				if r.grow(gap * 0.5).intersects(rect):
					var up := r.position.y - rect.size.y - gap
					rect.position.y = up if up >= 70.0 * ui else r.end.y + gap
					hit = true
			if not hit:
				break
		placed.append(rect)
		_draw_bubble(b, font, at, rect)


## Where a bubble goes: centred over its speaker, kept on screen under the buttons.
func _place(b: Dictionary, at: Vector2, screen: Vector2) -> Rect2:
	var size: Vector2 = b["size"]
	var tail := 14.0 * ui
	var margin := 8.0 * ui
	var top := 70.0 * ui  # below the HUD's top row of buttons
	var rect := Rect2(at - Vector2(size.x * 0.5, size.y + tail), size)
	rect.position.x = clampf(rect.position.x, margin, screen.x - size.x - margin)
	rect.position.y = clampf(rect.position.y, top, screen.y - size.y - margin - tail)
	if rect.grow(4.0 * ui).has_point(at):
		# Pushed down over its speaker (near the top of the screen): beside it instead.
		var right := at.x + tail * 1.6
		var left := at.x - tail * 1.6 - size.x
		rect.position.x = right if right + size.x < screen.x - margin or left < margin else left
		rect.position.y = clampf(at.y - size.y * 0.5, top, screen.y - size.y - margin)
	return rect


func _draw_bubble(b: Dictionary, font: Font, at: Vector2, rect: Rect2) -> void:
	var age: float = b["age"]
	var alpha := clampf((float(b["life"]) - age) / FADE, 0.0, 1.0) * clampf(age / 0.12, 0.0, 1.0)
	var size: Vector2 = b["size"]
	var tail := 14.0 * ui
	var ink := Color("#1d1b19", alpha)
	# The tail: from the edge facing the speaker (the lower edge, unless the bubble
	# had to move beside it), towards the speaker, shortened when far.
	var inner := rect.grow(-14.0 * ui)
	var out := Vector2(0, 1)
	var foot := Vector2(clampf(at.x, inner.position.x, inner.end.x), rect.end.y - 2.0 * ui)
	if at.y < rect.end.y and at.x > rect.end.x:
		out = Vector2(1, 0)
		foot = Vector2(rect.end.x - 2.0 * ui, clampf(at.y, inner.position.y, inner.end.y))
	elif at.y < rect.end.y and at.x < rect.position.x:
		out = Vector2(-1, 0)
		foot = Vector2(rect.position.x + 2.0 * ui, clampf(at.y, inner.position.y, inner.end.y))
	var tip := foot + (at - foot).limit_length(tail * 2.2)
	if (tip - foot).dot(out) < 4.0 * ui:
		tip = foot + out * tail
	var side := Vector2(-out.y, out.x) * 8.0 * ui
	draw_colored_polygon(PackedVector2Array([foot - side * 1.3, foot + side * 1.3, tip + (tip - foot).normalized() * 2.0 * ui]), ink)
	# The style box draws at once, so one shared box can change alpha per bubble.
	_panel.bg_color.a = alpha
	_panel.border_color.a = alpha
	draw_style_box(_panel, rect)
	draw_colored_polygon(PackedVector2Array([foot - side, foot + side, tip]), Color("#fbf7ee", alpha))
	var pad := 10.0 * ui
	var y := rect.position.y + pad
	var x := rect.position.x + pad
	var w := size.x - pad * 2.0
	var accent: Color = b["accent"]
	if b["speaker"] != "":
		var fs := int(NAME_SIZE * ui)
		draw_string(font, Vector2(x, y + font.get_ascent(fs)), b["speaker"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(accent.darkened(0.35), alpha))
		y += float(b["name_h"])
	var line: String = b["line"]
	var shown := line.substr(0, int(age * TYPE_RATE)) if age < float(b["typing"]) else line
	var ls := int(LINE_SIZE * ui)
	draw_multiline_string(font, Vector2(x, y + font.get_ascent(ls)), shown, HORIZONTAL_ALIGNMENT_LEFT, w + 1.0, ls, -1, ink)
	y += float(b["line_h"]) + 3.0 * ui
	if b["sub"] != "" and age >= float(b["typing"]) * 0.5:
		var ss := int(SUB_SIZE * ui)
		draw_multiline_string(font, Vector2(x, y + font.get_ascent(ss)), b["sub"], HORIZONTAL_ALIGNMENT_LEFT, w + 1.0, ss, -1, Color("#5d5750", alpha))
