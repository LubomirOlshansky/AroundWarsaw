extends Control
## F's asks (2026-10-30; BACKLOG "From loop MW-1"): the full-screen map, opened by a tap on the
## minimap (hud.gd `map_pressed`; main.gd pauses the game under it, like the settings card). The
## minimap's own map (hud.gd `_minimap_mesh`: one mesh, its day and night palette), north up and
## scaled to the screen: one finger pans, two pinch to zoom (the mouse wheel on a computer). On it
## the car's arrow, the mission target, the notebook's "?" marks (the places not found yet within
## the minimap's reach: never their names) and the places found (gold dots). The ✕, Esc or the
## Android back gesture close it. Built the first time it opens; hidden it draws nothing (0 cost).
## Loop 3h slice 1 (DEMO G3): the districts (districts.gd `view`, given by `set_districts` after
## open): the ones not discovered yet under a light fog, each discovered one's name and per cent
## at its label, and a card listing them all with the total (the districts' completion on the map).
## Loop 3h slice 3: the rival ladder's card on the right (DRABINKA · rival ladder: each rung with
## its stake, ★ beaten, → next and what it needs, · locked; the final's state), given by
## `set_ladder` after open, and the final's start marker (a diamond) once it is open at night.

signal closed

## The closest zoom: this many metres across the screen's height; the start: START_M.
const NEAR_M := 250.0
const START_M := 1400.0
const PAPER := Color(0.93, 0.9, 0.83)
const GOLD := Color("#f0b429")
const ARROW := Color("#d8432f")
## Type sizes in points (hud.gd's).
const T_TITLE := 17.0
const T_SUB := 13.0

## Set by hud.gd before the first open.
var hud: CanvasLayer
var mesh: ArrayMesh
var shader: Shader
## Mesh units per metre (the minimap's scale) and the map's bounds in metres.
var mini_scale := 0.2
var bounds := Rect2()
var pt := 1.0
var safe := Rect2()

## What it shows (map metres), from open().
var car := Vector2.ZERO
var car_yaw := 0.0
var unknown := PackedVector2Array()
var found := PackedVector2Array()
var target := Vector2.INF
## The garage loop: Warsztat u Mirka's diamond (INF: not shown yet).
var garage := Vector2.INF
var garage_colour := Color.WHITE
## Loop 3h slice 3: the final race's start marker (INF: not shown).
var final_start := Vector2.INF
var final_colour := Color.WHITE
var target_colour := Color.WHITE
var night := 0.0
## Loop 3h slice 1: districts.gd `view()` (names, label point, polygons, found, pct) and the total %.
var districts: Array[Dictionary] = []
var districts_total := 0

## The map point at the screen's centre (m) and the zoom (pixels per metre).
var centre := Vector2.ZERO
var ppm := 1.0

var _built := false
var _paper: ColorRect
var _content: Node2D
var _mat: ShaderMaterial
var _overlay: Control
var _head: PanelContainer
var _hint: PanelContainer
var _close: Button
var _touches := {}
var _pinch := 0.0
## Loop 3h slice 1: the fog's triangles (map points, three a triangle: the districts not
## discovered yet, clipped to the map's bounds) and the districts' card.
var _fog := PackedVector2Array()
var _list: PanelContainer
## Loop 3h slice 3: the ladder's card (top right, under the ✕).
var _ladder: PanelContainer
## Its rows' colours: beaten, next, locked.
const LADDER_COLOURS := {"won": Color("#ffd23f"), "next": Color("#fbf7ee"), "locked": Color("#8f88a0")}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	get_viewport().size_changed.connect(_fit)


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


func _build() -> void:
	_built = true
	_paper = ColorRect.new()
	_paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("radius", 1.0e7)
	_content = Node2D.new()
	_content.material = _mat
	_content.draw.connect(func() -> void: _content.draw_mesh(mesh, null))
	add_child(_content)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_paint)
	add_child(_overlay)
	_head = _card(["MAPA", "map · north up"], [T_TITLE, T_SUB])
	_head.name = "head"
	add_child(_head)
	_hint = _card(["Przesuń palcem · zbliż dwoma palcami", "Drag to move · pinch to zoom"], [T_SUB, T_SUB])
	_hint.name = "hint"
	add_child(_hint)
	_close = Button.new()
	_close.name = "close"
	_close.text = "✕"
	_close.focus_mode = Control.FOCUS_NONE
	_close.add_theme_font_size_override("font_size", _px(22))
	_close.add_theme_color_override("font_color", Color("#fbf7ee"))
	for s in ["normal", "hover", "pressed", "focus"]:
		_close.add_theme_stylebox_override(s, _box(0.94 if s != "pressed" else 1.0))
	_close.custom_minimum_size = Vector2.ONE * 48.0 * pt
	_close.pressed.connect(close)
	add_child(_close)
	_list = _card([], [])
	_list.name = "districts"
	_list.visible = false
	add_child(_list)
	_ladder = _card([], [])
	_ladder.name = "ladder"
	_ladder.visible = false
	add_child(_ladder)


func _box(alpha: float) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.07, 0.06, 0.1, alpha)
	b.set_corner_radius_all(_px(12))
	b.set_content_margin_all(10.0 * pt)
	b.border_color = Color("#ffd23f")
	b.border_width_left = _px(3)
	return b


## A small card: lines of text, Polish over English.
func _card(lines: Array, sizes: Array) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _box(0.9))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override("font_size", _px(sizes[i]))
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 and sizes[i] == T_TITLE else
				(Color("#fbf7ee") if i == 0 else Color("#c9c2d8")))
		v.add_child(l)
	return p


## Opens on the car, START_M across the screen's height.
func open(at: Vector2, yaw: float) -> void:
	if not _built:
		_build()
	car = at
	car_yaw = yaw
	centre = at
	_touches.clear()
	visible = true
	_fit()
	ppm = clampf(_view().y / START_M, _ppm_min(), _ppm_max())
	_mat.set_shader_parameter("night", night)
	_paper.color = PAPER.lerp(Color(0.07, 0.06, 0.1), night)
	_place()


func close() -> void:
	if not visible:
		return
	visible = false
	_touches.clear()
	closed.emit()


func is_open() -> bool:
	return visible


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _ppm_min() -> float:
	return minf(_view().x / maxf(bounds.size.x, 1.0), _view().y / maxf(bounds.size.y, 1.0)) * 0.9


func _ppm_max() -> float:
	return _view().y / NEAR_M


## The header top left, the ✕ top right, the hint bottom centre, inside the safe area.
func _fit() -> void:
	if not _built or not visible:
		return
	var s := safe if safe.has_area() else Rect2(Vector2.ZERO, _view())
	var m := 8.0 * pt
	_head.size = _head.get_combined_minimum_size()
	_head.position = s.position + Vector2(m, m)
	_close.size = _close.custom_minimum_size
	_close.position = Vector2(s.end.x - m - _close.size.x, s.position.y + m)
	_hint.size = _hint.get_combined_minimum_size()
	_hint.position = Vector2(s.position.x + (s.size.x - _hint.size.x) * 0.5, s.end.y - m - _hint.size.y)
	if _list.visible:
		_list.size = _list.get_combined_minimum_size()
		_list.position = Vector2(s.position.x + m, _head.position.y + _head.size.y + m)
	if _ladder.visible:
		_ladder.size = _ladder.get_combined_minimum_size()
		_ladder.position = Vector2(s.end.x - m - _ladder.size.x, _close.position.y + _close.size.y + m)
	_place()


## The map under the screen's centre and the zoom: the content's transform, the marks redrawn.
func _place() -> void:
	if not _built:
		return
	ppm = clampf(ppm, _ppm_min(), _ppm_max())
	if bounds.has_area():
		centre = centre.clamp(bounds.position, bounds.end)
	var k := ppm / mini_scale
	_content.scale = Vector2(k, k)
	_content.position = _view() * 0.5 - centre * ppm
	_overlay.queue_redraw()


## A map point (m) on the screen (px).
func to_screen(p: Vector2) -> Vector2:
	return _view() * 0.5 + (p - centre) * ppm


## For check_hud: the ✕ and the cards, in pixels.
func rects() -> Dictionary:
	if not _built:
		return {}
	var out := {"close": _close.get_global_rect(), "head": _head.get_global_rect(), "hint": _hint.get_global_rect()}
	if _list.visible:
		out["districts"] = _list.get_global_rect()
	if _ladder.visible:
		out["ladder"] = _ladder.get_global_rect()
	return out


## Loop 3h slice 3: the rival ladder's card (ladder.gd `rows`: [text, "won" | "next" | "locked"]);
## call after open(). Labels only: the game is paused under the map.
func set_ladder(rows: Array) -> void:
	if not _built:
		return
	var box: VBoxContainer = _ladder.get_child(0)
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	var lines: Array = [["DRABINKA", ""], ["rival ladder", ""]]
	lines.append_array(rows)
	for i in lines.size():
		var l := Label.new()
		l.text = str(lines[i][0])
		l.add_theme_font_size_override("font_size", _px(T_TITLE if i == 0 else T_SUB))
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 else
				(Color("#c9c2d8") if i == 1 else LADDER_COLOURS.get(str(lines[i][1]), Color.WHITE)))
		box.add_child(l)
	_ladder.visible = not rows.is_empty()
	_fit()


## Loop 3h slice 1: the districts to show (districts.gd `view()`) and the total per cent; call
## after open(). The fog is triangulated here once (the map is paused), so painting it is a few
## dozen triangles in the overlay's one batch (+0 draw calls).
## Loop 3h slice 2: `syrenki_total` > 0 adds one line, "Syrenki found/total", above the total.
func set_districts(view: Array[Dictionary], total: int, syrenki_found := 0, syrenki_total := 0) -> void:
	districts = view
	districts_total = total
	_fog = PackedVector2Array()
	var frame := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end,
			Vector2(bounds.position.x, bounds.end.y)])
	for d in districts:
		if d["found"]:
			continue
		for poly: PackedVector2Array in d["polys"]:
			var parts: Array[PackedVector2Array] = [poly]
			if bounds.has_area():
				parts = Geometry2D.intersect_polygons(poly, frame)
			for part in parts:
				var tris := Geometry2D.triangulate_polygon(part)
				for i in tris:
					_fog.append(part[i])
	if not _built:
		return
	var lines := ["DZIELNICE", "districts"]
	var sizes := [T_TITLE, T_SUB]
	for d in districts:
		lines.append("%s · %d%%" % [d["name_pl"], d["pct"]] if d["found"] else "? ? ?")
		sizes.append(T_SUB)
	if syrenki_total > 0:
		lines.append("Syrenki %d/%d" % [syrenki_found, syrenki_total])
		sizes.append(T_SUB)
	lines.append("Razem · in all %d%%" % total)
	sizes.append(T_SUB)
	var rows: VBoxContainer = _list.get_child(0)
	for c in rows.get_children():
		rows.remove_child(c)
		c.queue_free()
	for i in lines.size():
		var l := Label.new()
		l.text = lines[i]
		l.add_theme_font_size_override("font_size", _px(sizes[i]))
		var found: bool = i < 2 or i >= 2 + districts.size() or districts[i - 2]["found"]
		l.add_theme_color_override("font_color", Color("#ffd23f") if i == 0 else
				(Color("#fbf7ee") if found and i >= 2 else Color("#c9c2d8")))
		rows.add_child(l)
	_list.visible = not districts.is_empty()
	_fit()


func _paint() -> void:
	var o := _overlay
	var view := Rect2(Vector2.ZERO, _view()).grow(20.0 * pt)
	hud._tri_begin()
	# Loop 3h slice 1: the districts not discovered yet, under a light fog.
	var fog := Color(0.16, 0.14, 0.2, 0.3).lerp(Color(0.0, 0.0, 0.0, 0.45), night)
	for i in range(0, _fog.size() - 2, 3):
		hud._tri(to_screen(_fog[i]), to_screen(_fog[i + 1]), to_screen(_fog[i + 2]), fog, fog, fog)
	for q in found:
		var at := to_screen(q)
		if view.has_point(at):
			hud._tri_fan(at, 4.2 * pt, 0.0, TAU, hud.OUTLINE)
			hud._tri_fan(at, 3.0 * pt, 0.0, TAU, GOLD)
	for q in unknown:
		var at := to_screen(q)
		if view.has_point(at):
			hud._tri_question(at, 1.6)
	if garage != Vector2.INF:
		var g := to_screen(garage)
		if view.has_point(g):
			hud._tri_diamond(g, 6.5 * pt, garage_colour)
	if final_start != Vector2.INF:
		var fs := to_screen(final_start)
		if view.has_point(fs):
			hud._tri_diamond(fs, 8.0 * pt, final_colour)
	if target != Vector2.INF:
		var t := to_screen(target)
		hud._tri_fan(t, 5.0 * pt, 0.0, TAU, hud.OUTLINE)
		hud._tri_fan(t, 3.8 * pt, 0.0, TAU, target_colour)
	var c := to_screen(car)
	var d := Vector2(-sin(car_yaw), -cos(car_yaw))
	var side := Vector2(-d.y, d.x)
	var tip := c + d * 9.0 * pt
	var notch := c - d * 3.0 * pt
	hud._tri_fan(c, 9.5 * pt, 0.0, TAU, Color(1, 1, 1, 0.85))
	hud._tri(tip, c - d * 6.0 * pt + side * 6.0 * pt, notch, ARROW, ARROW, ARROW)
	hud._tri(tip, notch, c - d * 6.0 * pt - side * 6.0 * pt, ARROW, ARROW, ARROW)
	hud._tri_flush(o)
	# Loop 3h slice 1: each discovered district's name and per cent at its label.
	var font := ThemeDB.fallback_font
	var fs := _px(T_SUB)
	var ink := Color("#2a2622").lerp(Color("#fbf7ee"), night)
	var rim := Color(0.93, 0.9, 0.83, 0.9).lerp(Color(0.07, 0.06, 0.1, 0.9), night)
	for dd in districts:
		if not dd["found"]:
			continue
		var at := to_screen(dd["at"])
		if not view.has_point(at):
			continue
		for row: Array in [[str(dd["name_pl"]).to_upper(), -0.15], ["%d%%" % dd["pct"], 1.0]]:
			var text: String = row[0]
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var p := at + Vector2(-w * 0.5, fs * float(row[1]))
			o.draw_string_outline(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _px(4), rim)
			o.draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)


# --- gestures ------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _close.get_global_rect().has_point(t.position):
				return  # the ✕ takes it
			_touches[t.index] = t.position
		else:
			_touches.erase(t.index)
		_pinch = _span()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if not _touches.has(d.index):
			return
		if _touches.size() == 1:
			centre -= (d.position - _touches[d.index]) / ppm
			_touches[d.index] = d.position
		else:
			var before := _mid()
			_touches[d.index] = d.position
			var span := _span()
			if _pinch > 0.0 and span > 0.0:
				zoom_at(span / _pinch, _mid())
			centre -= (_mid() - before) / ppm
			_pinch = span
		_place()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var b := event as InputEventMouseButton
		if b.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(1.15, b.position)
		elif b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(1.0 / 1.15, b.position)


## Zooms by `ratio` keeping the map point under `at` (px) where it is.
func zoom_at(ratio: float, at: Vector2) -> void:
	var p := centre + (at - _view() * 0.5) / ppm
	ppm = clampf(ppm * ratio, _ppm_min(), _ppm_max())
	centre = p - (at - _view() * 0.5) / ppm
	_place()


func _span() -> float:
	if _touches.size() != 2:
		return 0.0
	var v: Array = _touches.values()
	return (v[0] as Vector2).distance_to(v[1])


func _mid() -> Vector2:
	var m := Vector2.ZERO
	for p: Vector2 in _touches.values():
		m += p
	return m / maxf(_touches.size(), 1.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and visible:
		close()
