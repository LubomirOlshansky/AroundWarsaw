extends CanvasLayer
## The title screen on a normal launch: a chrome "NOCNA WARSZAWA" wordmark over a
## striped setting sun, the Warsaw skyline (the Palace of Culture against the
## sun), a neon perspective grid, and a palm in silhouette (the artificial palm on
## Rondo de Gaulle'a). The city builds behind it; once it is ready, a tap or any
## key fades the title out ("TAP TO DRIVE / DOTKNIJ, BY JECHAĆ").

signal dismissed

var ready_to_drive := false
var _root: Control
var _backdrop: ColorRect
var _palm: Control
var _mark: Label
var _shadow: Label
var _prompt: Label
var _prompt_pl: Label
var _gone := false
var _t := 0.0
var _start_sound: AudioStreamPlayer
## Safe area in pixels: left, top, right, bottom.
var _safe := Rect2()


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/title.gdshader")
	_backdrop.material = mat
	_root.add_child(_backdrop)

	_palm = Control.new()
	_palm.set_anchors_preset(Control.PRESET_FULL_RECT)
	_palm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palm.draw.connect(_draw_palm)
	_root.add_child(_palm)

	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.1
	font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	font.spacing_glyph = 2
	_shadow = _make_label(font)
	_mark = _make_label(font)
	var chrome := ShaderMaterial.new()
	chrome.shader = load("res://shaders/chrome.gdshader")
	_mark.material = chrome

	_prompt = _make_label(ThemeDB.fallback_font)
	_prompt_pl = _make_label(ThemeDB.fallback_font)
	_start_sound = AudioStreamPlayer.new()
	_start_sound.volume_db = -8.0
	if ResourceLoader.exists("res://audio/ui/start.wav"):
		_start_sound.stream = load("res://audio/ui/start.wav")
	add_child(_start_sound)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _make_label(font: Font) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


## Everything is placed from the screen size, inside the safe area (notch, home bar).
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	_safe = Rect2(Vector2.ZERO, size)
	if OS.has_feature("mobile"):
		var screen := DisplayServer.screen_get_size()
		var area := DisplayServer.get_display_safe_area()
		var k := size.x / float(maxi(screen.x, 1))
		_safe = Rect2(Vector2(area.position) * k, Vector2(area.size) * k)
	(_backdrop.material as ShaderMaterial).set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
	var h := size.y
	var fs := int(minf(h * 0.12, _safe.size.x * 0.072))
	for l in [_mark, _shadow]:
		l.text = "NOCNA WARSZAWA"
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_constant_override("outline_size", maxi(4, int(fs * 0.1)))
		l.position = Vector2(_safe.position.x, h * 0.07)
		l.size = Vector2(_safe.size.x, fs * 1.6)
	_mark.add_theme_color_override("font_color", Color.WHITE)
	_mark.add_theme_color_override("font_outline_color", Color("#2a0838"))
	_shadow.add_theme_color_override("font_color", Color("#ff2fa0"))
	_shadow.add_theme_color_override("font_outline_color", Color("#ff2fa0"))
	_shadow.position += Vector2(fs * 0.06, fs * 0.08)
	# The chrome gradient spans the capitals: from the cap top to the baseline.
	var font: Font = _mark.get_theme_font("font")
	var ascent := font.get_ascent(fs)
	var chrome := _mark.material as ShaderMaterial
	chrome.set_shader_parameter("top", ascent - fs * 0.74)
	chrome.set_shader_parameter("bottom", ascent)

	var ps := int(maxf(h * 0.04, 14.0))
	_prompt.add_theme_font_size_override("font_size", ps)
	_prompt.add_theme_color_override("font_color", Color("#7ff6ff"))
	_prompt.add_theme_color_override("font_outline_color", Color("#14053a"))
	_prompt.add_theme_constant_override("outline_size", maxi(3, int(ps * 0.22)))
	_prompt_pl.add_theme_font_size_override("font_size", int(ps * 0.72))
	_prompt_pl.add_theme_color_override("font_color", Color("#ffb3e6"))
	_prompt_pl.add_theme_color_override("font_outline_color", Color("#14053a"))
	_prompt_pl.add_theme_constant_override("outline_size", maxi(3, int(ps * 0.18)))
	var bottom := _safe.end.y - h * 0.06
	_prompt_pl.size = Vector2(_safe.size.x, ps * 1.3)
	_prompt_pl.position = Vector2(_safe.position.x, bottom - ps * 1.0)
	_prompt.size = Vector2(_safe.size.x, ps * 1.5)
	_prompt.position = Vector2(_safe.position.x, bottom - ps * 2.4)
	_set_prompt()
	_palm.queue_redraw()


func _set_prompt() -> void:
	if ready_to_drive:
		_prompt.text = "TAP TO DRIVE"
		_prompt_pl.text = "DOTKNIJ, BY JECHAĆ"
	else:
		_prompt.text = "building the city…"
		_prompt_pl.text = "budujemy miasto…"


## The city is built: the prompt changes and a tap or a key starts the game.
func set_ready() -> void:
	ready_to_drive = true
	_t = 0.0
	_set_prompt()


func _process(dt: float) -> void:
	_t += dt
	if ready_to_drive and not _gone:
		# The prompt pulses like a VCR's menu.
		var a := 0.45 + 0.55 * (0.5 + 0.5 * cos(_t * 4.2))
		_prompt.modulate.a = a
		_prompt_pl.modulate.a = a


func _input(event: InputEvent) -> void:
	if _gone:
		return
	var go := false
	if event is InputEventKey:
		go = (event as InputEventKey).pressed and not (event as InputEventKey).echo
	elif event is InputEventScreenTouch:
		go = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		go = (event as InputEventMouseButton).pressed
	if not go:
		return
	get_viewport().set_input_as_handled()
	if ready_to_drive:
		dismiss()


func dismiss() -> void:
	if _gone:
		return
	_gone = true
	_prompt.modulate.a = 1.0
	_prompt_pl.modulate.a = 1.0
	if _start_sound.stream != null:
		_start_sound.play()
	dismissed.emit()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(queue_free).set_delay(0.6)


## The palm: a curved, ringed trunk and a crown of drooping fronds, each a rachis
## with leaflets hanging off both sides, in silhouette with a pink rim on the
## sun's side.
func _draw_palm() -> void:
	var size := get_viewport().get_visible_rect().size
	var h := size.y
	var base := Vector2(_safe.position.x + _safe.size.x * 0.1, h * 1.02)
	var height := h * 0.58
	var top := base + Vector2(height * 0.2, -height)
	var bend := base + Vector2(-height * 0.04, -height * 0.55)
	var rim := Color("#ff4fb0")
	var dark := Color("#10041f")
	var px := maxf(h / 720.0, 1.0)
	for pass_i in 2:
		var off := Vector2(2.5, -1.5) * px if pass_i == 0 else Vector2.ZERO
		var col := rim if pass_i == 0 else dark
		# Trunk: quadratic curve, tapering, in short ringed segments.
		var segs := 18
		for i in segs:
			var t0 := float(i) / segs
			var t1 := float(i + 1) / segs
			var p0 := _bezier(base, bend, top, t0)
			var p1 := _bezier(base, bend, top, t1)
			var w0 := lerpf(height * 0.045, height * 0.024, t0)
			var w1 := lerpf(height * 0.045, height * 0.024, t1) * 0.84
			var d := (p1 - p0).normalized()
			var n := Vector2(-d.y, d.x)
			_palm.draw_primitive(PackedVector2Array([p0 + n * w0 + off, p0 - n * w0 + off,
					p1 - n * w1 + off, p1 + n * w1 + off]), PackedColorArray([col, col, col, col]), PackedVector2Array())
		# Fronds: arcs out from the top that droop towards their tips.
		var fronds := [-3.05, -2.6, -2.15, -1.75, -1.35, -0.95, -0.5, -0.08, 0.3]
		for k in fronds.size():
			var a: float = fronds[k]
			var length := height * (0.4 + 0.07 * sin(k * 2.3))
			var dir := Vector2(cos(a), sin(a))
			var tip := top + dir * length + Vector2(0, height * (0.12 + 0.3 * absf(dir.x)))
			var mid := top + dir * length * 0.55 - Vector2(0, height * 0.06)
			var steps := 16
			var prev := top + off
			for i in range(1, steps + 1):
				var t := float(i) / steps
				var p := _bezier(top, mid, tip, t) + off
				var d := (p - prev).normalized()
				var n := Vector2(-d.y, d.x)
				if n.y < 0.0:
					n = -n
				_palm.draw_line(prev, p, col, maxf(height * 0.01 * (1.0 - t * 0.6), 1.5 * px))
				# Leaflets: thin blades hanging off both sides, longest mid-frond.
				var leaf := sin(PI * minf(t * 1.25, 1.0)) * height * 0.085
				for side: float in [-1.0, 1.0]:
					var hang := (n * side * 0.75 + Vector2(0, 0.85) + d * 0.35).normalized() * leaf
					var w := (p - prev) * 0.55
					# draw_primitive: a plain triangle, no triangulation (tips can be degenerate).
					_palm.draw_primitive(PackedVector2Array([prev, p, p - w * 0.2 + hang]), PackedColorArray([col, col, col]), PackedVector2Array())
				prev = p
		_palm.draw_circle(top + off, height * 0.03, col)


func _bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)
