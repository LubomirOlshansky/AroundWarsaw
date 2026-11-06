extends Node3D
## Inside the club (F's ask 2026-11-06, option A of docs/design/secret-rave.md): after the door,
## a cutaway room in the city's own isometric look, the walls on two sides and a black void
## round it, like a diorama. The camera leaves the car (main.gd `_update_camera` reads `inside`,
## `centre`, `view_size`), the HUD steps aside for the room's own panel, the car waits at the
## door (its process off).
##
## The room (about ROOM.x × ROOM.y m, far off the map at PLACE so nothing of the city is in view):
## a concrete floor and two walls with a pillar grid (the power-station look of Berlin-style
## clubs), the DJ booth on a riser under a truss, speaker stacks, the bar with lit bottles, the
## cloakroom, a queue for the toilets, a sofa in the chill corner, the lit WYJŚCIE door. Forty-odd
## dancers in black bob on the beat; beams, lasers and a strobe come down from the truss (the
## rave rig's light pose, the city's glow material). Now and then the lights turn red and the
## DJ jokes about the sprinklers (a nod to a famous film's blood rave, no blood: `club_red`).
##
## People to tap (their lines in data/dialogue.json): the DJ (`club_dj`), Ziomek (`club_ziomek`),
## the bartender (`club_bar`), Pan Kołek, a tall vampire hunter in a long coat and sunglasses
## who insists he is only here for the music (`club_kolek`, our own parody character), and the
## crowd (`club_crowd`: the techno scene, Lusterko's after, Berlin, phones). TAŃCZ: tap on the
## beat (the ring on the button pulses at BPM); eight in a row earn respect (DANCE_PAY, up to
## DANCE_MAX times a visit). WYJDŹ goes back to the car. MORDOR FM plays (the radio tunes to it).
##
## Cost: three draw calls (the room with its people's furniture, the dancers' MultiMesh, the
## lights' MultiMesh); the city is out of view. The room is built once, on the first visit.

## The room's kick under the music: the city's techno thump, looped.
const THUMP_FILE := "res://audio/sfx/techno_thump.wav"
const THUMP_DB := -8.0
const Models := preload("res://scripts/models.gd")
const Rave := preload("res://scripts/rave.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Access := preload("res://scripts/access.gd")

## Where the room stands: far past the map's edge.
const PLACE := Vector3(9000.0, 0.0, 9000.0)
## The floor, x across, y deep (m); the walls' height.
const ROOM := Vector2(24.0, 16.0)
const WALL_H := 6.0
## The camera: the view's height (m) and its yaw (degrees: from the open corner).
const VIEW := 21.0
const YAW := 45.0
const DANCERS := 44
const BPM := 132.0
## The dance: a tap within this many seconds of a beat counts; STREAK in a row pays.
const BEAT_WINDOW := 0.13
const STREAK := 8
const DANCE_PAY := 15
const DANCE_MAX := 3
## The red lights: every RED_GAP s for RED_LONG s.
const RED_GAP := Vector2(35.0, 55.0)
const RED_LONG := 6.0
const VIOLET := Color("#b44cff")
const TAP_R := 1.6

signal left

var hud: CanvasLayer
var dialogue: Node
var wallet: Node
var radio: Node
var _thump: AudioStreamPlayer
## The view's camera (main.gd's), for taps.
var cam: Camera3D
var log_on := false

var inside := false
var centre := PLACE + Vector3(0, 1.2, 0)
var view_size := VIEW
var yaw := YAW
## The people one can tap: [name, group, local position].
var people: Array = []
var danced := 0
var streak := 0
var title_pl := "SMOŁA"
var title_en := "SMOŁA"

var _built := false
var _room: MeshInstance3D
var _dancers: MultiMeshInstance3D
var _lights: MultiMeshInstance3D
var _floor: Array[Vector3] = []
var _clock := 0.0
var _red_in := 40.0
var _red_t := 0.0
var _dance_t := 0.0
var _ui: CanvasLayer
var _title: Label
var _who: Label
var _line: Label
var _line_en: Label
var _talk: PanelContainer
var _beat: Control
var _dance_btn: Button
var _rng := RandomNumberGenerator.new()


# --- the room -------------------------------------------------------------------------------

## The room's static mesh: floor, walls, pillars, the booth, bar, cloakroom, sofa, the door, the
## void under it all, and Pan Kołek (he never moves). Local frame: the floor's middle at the
## origin, the back wall at -Z, the left wall at -X, the open sides +X and +Z (towards the camera).
static func room_mesh() -> ArrayMesh:
	var st := Models._begin()
	var hx := ROOM.x * 0.5
	var hz := ROOM.y * 0.5
	var concrete := Color("#3b3a3f")
	var dark := Color("#1c1b20")
	var black := Color("#0d0d10")
	var steel := Color("#4a4a52")
	# The void: a black slab far round the room, then the floor.
	Models.box(st, Vector3(0, -0.6, 0), Vector3(400, 1.0, 400), Color("#020203"), Models.FIXED)
	Models.box(st, Vector3(0, -0.1, 0), Vector3(ROOM.x, 0.2, ROOM.y), Color("#29282d"), Models.FIXED)
	# The walls (back -Z, left -X), panels and pillars.
	Models.box(st, Vector3(0, WALL_H * 0.5, -hz - 0.2), Vector3(ROOM.x + 0.8, WALL_H, 0.4), concrete, Models.FIXED)
	Models.box(st, Vector3(-hx - 0.2, WALL_H * 0.5, 0), Vector3(0.4, WALL_H, ROOM.y), concrete, Models.FIXED)
	for i in 6:
		var x := -hx + 2.0 + i * 4.0
		Models.box(st, Vector3(x, WALL_H * 0.5, -hz + 0.05), Vector3(0.5, WALL_H, 0.3), dark, Models.FIXED)
	for i in 4:
		var z := -hz + 2.0 + i * 4.0
		Models.box(st, Vector3(-hx + 0.05, WALL_H * 0.5, z), Vector3(0.3, WALL_H, 0.5), dark, Models.FIXED)
	for p: Vector2 in [Vector2(-4, -1), Vector2(4, -1), Vector2(-4, 4), Vector2(4, 4)]:
		Models.box(st, Vector3(p.x, WALL_H * 0.5, p.y), Vector3(0.6, WALL_H, 0.6), concrete, Models.FIXED)
	# The riser, booth, stacks and truss at the back wall's middle.
	Models.box(st, Vector3(0, 0.3, -hz + 2.0), Vector3(8.0, 0.6, 3.4), dark, Models.FIXED)
	Models.box(st, Vector3(0, 1.1, -hz + 2.2), Vector3(2.8, 1.0, 0.9), black, Models.FIXED)
	Models.box(st, Vector3(0, 1.35, -hz + 2.68), Vector3(2.7, 0.08, 0.04), VIOLET, Models.LIT_SIGN)
	for side in [-1.0, 1.0]:
		Models.box(st, Vector3(side * 3.0, 1.8, -hz + 1.6), Vector3(1.3, 2.4, 1.1), black, Models.FIXED)
		Models.box(st, Vector3(side * 3.0, 1.4, -hz + 2.16), Vector3(0.8, 0.8, 0.02), steel, Models.FIXED)
		Models.box(st, Vector3(side * 3.0, 2.5, -hz + 2.16), Vector3(0.6, 0.6, 0.02), steel, Models.FIXED)
	Models.box(st, Vector3(0, 5.4, -hz + 3.0), Vector3(14.0, 0.25, 0.25), steel, Models.FIXED)
	Models.box(st, Vector3(0, 5.4, 2.0), Vector3(14.0, 0.25, 0.25), steel, Models.FIXED)
	# The bar along the left wall, its bottles lit.
	Models.box(st, Vector3(-hx + 1.6, 0.55, 1.5), Vector3(1.0, 1.1, 7.0), dark, Models.FIXED)
	Models.box(st, Vector3(-hx + 1.6, 1.12, 1.5), Vector3(1.1, 0.06, 7.1), steel, Models.FIXED)
	Models.box(st, Vector3(-hx + 0.35, 2.2, 1.5), Vector3(0.3, 0.08, 6.0), steel, Models.FIXED)
	var bottles := [Color("#3ad8ff"), Color("#ff3ad0"), Color("#f2d34a"), Color("#7ad66a")]
	for i in 14:
		Models.box(st, Vector3(-hx + 0.35, 2.42, -1.2 + i * 0.42), Vector3(0.12, 0.36, 0.12), bottles[i % 4], Models.LIT_SIGN)
	# The cloakroom by the door (front left), the sofa (front right), the toilets' doors.
	Models.box(st, Vector3(-hx + 1.0, 0.6, hz - 2.0), Vector3(1.6, 1.2, 2.6), dark, Models.FIXED)
	for i in 6:
		Models.box(st, Vector3(-hx + 0.3, 1.9, hz - 3.0 + i * 0.4), Vector3(0.2, 0.9, 0.3), [black, Color("#5a2a6a"), dark][i % 3], Models.FIXED)
	Models.box(st, Vector3(hx - 2.5, 0.35, -hz + 1.6), Vector3(3.4, 0.7, 1.2), Color("#5a2a6a"), Models.FIXED)
	Models.box(st, Vector3(hx - 2.5, 0.9, -hz + 1.1), Vector3(3.4, 0.6, 0.3), Color("#5a2a6a"), Models.FIXED)
	for i in 2:
		Models.box(st, Vector3(hx - 7.0 + i * 1.6, 1.1, -hz + 0.02), Vector3(1.0, 2.2, 0.06), steel, Models.FIXED)
	Models.box(st, Vector3(hx - 6.2, 2.5, -hz + 0.05), Vector3(2.4, 0.3, 0.04), Color("#3ad8ff"), Models.LIT_SIGN)
	# The way out: a door in the left wall at the front, its lit sign.
	Models.box(st, Vector3(-hx + 0.02, 1.2, hz - 5.0), Vector3(0.06, 2.4, 1.4), Color("#2a5a3a"), Models.FIXED)
	Models.box(st, Vector3(-hx + 0.06, 2.75, hz - 5.0), Vector3(0.04, 0.3, 1.4), Color("#3aff7a"), Models.LIT_SIGN)
	# Pan Kołek by the front-right pillar: a long black coat, a pale face, sunglasses.
	var k := Vector3(5.2, 0, 4.6)
	Models.box(st, k + Vector3(0, 0.95, 0), Vector3(0.62, 1.9, 0.42), Color("#0b0b0d"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.08, 0), Vector3(0.28, 0.3, 0.28), Color("#8a6a52"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.12, 0.15), Vector3(0.3, 0.07, 0.03), Color("#050505"), Models.FIXED)
	Models.box(st, k + Vector3(0, 2.26, 0), Vector3(0.3, 0.06, 0.3), Color("#0b0b0d"), Models.FIXED)
	return st.commit()


func _build(world: Node3D) -> void:
	_built = true
	_rng.randomize()
	_room = MeshInstance3D.new()
	_room.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_room.name = "ClubRoom"
	_room.mesh = room_mesh()
	_room.material_override = Models.material()
	_room.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_room.position = PLACE
	world.add_child(_room)
	var dmat := Models.material().duplicate() as ShaderMaterial
	dmat.set_shader_parameter("walk", 0.0)
	var dm := MultiMesh.new()
	dm.transform_format = MultiMesh.TRANSFORM_3D
	dm.use_custom_data = true
	InstanceBuffers.prepare(dm)
	dm.mesh = Models.person_mesh()
	dm.instance_count = DANCERS + 4
	InstanceBuffers.whiten(dm)
	_dancers = MultiMeshInstance3D.new()
	_dancers.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_dancers.multimesh = dm
	_dancers.material_override = dmat
	_dancers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dancers.position = PLACE
	world.add_child(_dancers)
	var hz := ROOM.y * 0.5
	var hx := ROOM.x * 0.5
	var frng := RandomNumberGenerator.new()
	frng.seed = 4242
	var clothes := [Color("#1a1a1e"), Color("#232327"), Color("#141416"), Color("#2e2e34"), Color("#1a1a1e"), Color("#3ad8ff"), Color("#ff3ad0")]
	while _floor.size() < DANCERS:
		var p := Vector3(frng.randf_range(-7.5, 7.5), frng.randf(), frng.randf_range(-hz + 4.4, hz - 2.0))
		var clear := true
		for q: Vector2 in [Vector2(-4, -1), Vector2(4, -1), Vector2(-4, 4), Vector2(4, 4), Vector2(5.2, 4.6)]:
			if Vector2(p.x, p.z).distance_to(q) < 0.9:
				clear = false
		if clear:
			dm.set_instance_custom_data(_floor.size(), Color(clothes[frng.randi() % 7], 0.25))
			_floor.append(p)
	# The DJ, Ziomek (front of the floor, his violet shirt), the bartender, the cloakroom lady.
	var named := [
		["DJ", "club_dj", Vector3(0, 0.6, -hz + 1.6), Color("#141416")],
		["Ziomek", "club_ziomek", Vector3(1.5, 0, 0.8), Color("#7a3aa8")],
		["Barman", "club_bar", Vector3(-hx + 0.9, 0, 0.5), Color("#e8e2d6")],
		["Szatnia", "club_crowd", Vector3(-hx + 0.6, 0, hz - 2.0), Color("#a83a3a")],
	]
	people.clear()
	for i in named.size():
		var row: Array = named[i]
		dm.set_instance_custom_data(DANCERS + i, Color(row[3], 0.25))
		var face := 0.0 if i == 0 else (PI * 0.5 if i >= 2 else PI)
		dm.set_instance_transform(DANCERS + i, Transform3D(Basis(Vector3.UP, face), row[2]))
		people.append([row[0], row[1], row[2]])
	people.append(["Pan Kołek", "club_kolek", Vector3(5.2, 0, 4.6)])
	for i in 6:
		people.append(["", "club_crowd", _floor[i * 7]])
	# The lights from the truss: the rave rig's pose, turned to hang down over the floor.
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader")
	mat.render_priority = 1
	mat.set_shader_parameter("lift", 0.0)
	mat.set_shader_parameter("strength", 1.4)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = Rave.cone_mesh()
	mm.instance_count = Rave.BEAMS + Rave.LASERS + 1
	_lights = MultiMeshInstance3D.new()
	_lights.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_lights.multimesh = mm
	_lights.material_override = mat
	_lights.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lights.position = PLACE
	world.add_child(_lights)
	_build_ui()
	_show(false)


func _build_ui() -> void:
	var pt: float = hud.pt if hud != null else 1.0
	_ui = CanvasLayer.new()
	_ui.layer = 20
	add_child(_ui)
	var top := PanelContainer.new()
	top.add_theme_stylebox_override("panel", _box(Color(0.03, 0.03, 0.04, 0.85), VIOLET))
	top.position = Vector2(16, 16) * pt
	_ui.add_child(top)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", int(16 * pt))
	_title.add_theme_color_override("font_color", VIOLET)
	top.add_child(_title)
	_talk = PanelContainer.new()
	_talk.add_theme_stylebox_override("panel", _box(Color(0.03, 0.03, 0.04, 0.9), VIOLET))
	_talk.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_talk.position = Vector2(16 * pt, 0)
	_talk.custom_minimum_size = Vector2(360, 0) * pt
	_talk.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(_talk)
	var v := VBoxContainer.new()
	_talk.add_child(v)
	_who = Label.new()
	_who.add_theme_font_size_override("font_size", int(13 * pt))
	_who.add_theme_color_override("font_color", VIOLET)
	v.add_child(_who)
	_line = Label.new()
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.x = 340 * pt
	_line.add_theme_font_size_override("font_size", int(14 * pt))
	v.add_child(_line)
	_line_en = Label.new()
	_line_en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_en.custom_minimum_size.x = 340 * pt
	_line_en.add_theme_font_size_override("font_size", int(11 * pt))
	_line_en.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	v.add_child(_line_en)
	var buttons := HBoxContainer.new()
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.add_theme_constant_override("separation", int(10 * pt))
	_ui.add_child(buttons)
	_dance_btn = _button(buttons, "TAŃCZ", "dance", pt)
	_dance_btn.pressed.connect(_on_dance)
	var out := _button(buttons, "WYJDŹ", "leave", pt)
	out.pressed.connect(leave)
	_beat = Control.new()
	_beat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat.draw.connect(_draw_beat)
	_dance_btn.add_child(_beat)
	_beat.set_anchors_preset(Control.PRESET_FULL_RECT)
	var vp := get_viewport().get_visible_rect().size
	_talk.position.y = vp.y - 16 * pt
	buttons.position = vp - Vector2(16, 16) * pt


func _button(parent: Node, pl: String, en: String, pt: float) -> Button:
	if hud != null and hud.has_method("_chip"):
		var b: Button = hud._chip(parent, pl, en, VIOLET)
		b.custom_minimum_size = Vector2(96, 52) * pt
		return b
	var c := Button.new()
	c.text = pl
	c.custom_minimum_size = Vector2(96, 52) * pt
	parent.add_child(c)
	return c


static func _box(bg: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(2)
	s.set_content_margin_all(10)
	return s


func _draw_beat() -> void:
	var ph := fmod(_clock * BPM / 60.0, 1.0)
	var a := 1.0 - ph
	_beat.draw_rect(Rect2(Vector2.ZERO, _beat.size).grow(-2.0 - ph * 6.0), Color(VIOLET, a * 0.9), false, 3.0)
	if streak > 0:
		_beat.draw_string(ThemeDB.fallback_font, Vector2(4, 14), "×%d" % streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)


# --- going in and out -----------------------------------------------------------------------

## In: the room built (once) in `world`, shown, the radio on MORDOR FM, the panel up.
func enter(world: Node3D, pl: String, en: String, mordor: int) -> void:
	if not _built:
		_build(world)
	title_pl = pl
	title_en = en
	_title.text = "%s · w środku / inside" % pl
	danced = 0
	streak = 0
	_red_in = _rng.randf_range(RED_GAP.x, RED_GAP.y)
	inside = true
	_show(true)
	if radio != null and mordor >= 0 and int(radio.station) != mordor:
		radio.tune(mordor)
	_thump_on(true)
	_say(people[0])
	_log("in: %s" % pl)


func leave() -> void:
	if not inside:
		return
	inside = false
	_show(false)
	_thump_on(false)
	_log("out (danced %d)" % danced)
	left.emit()


## The room's kick (the city's techno thump, looped) under the radio while inside; silent
## headless.
func _thump_on(on: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if on and _thump == null and ResourceLoader.exists(THUMP_FILE):
		var w := (load(THUMP_FILE) as AudioStreamWAV).duplicate() as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
		_thump = AudioStreamPlayer.new()
		_thump.stream = w
		_thump.volume_db = THUMP_DB
		_thump.bus = &"SFX"
		add_child(_thump)
	if _thump == null:
		return
	if on:
		_thump.play()
	else:
		_thump.stop()


func _show(on: bool) -> void:
	_room.visible = on
	_dancers.visible = on
	_lights.visible = on
	_ui.visible = on
	_talk.visible = false


# --- the frame ------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if not inside or dt <= 0.0:
		return
	_clock += dt
	_pose_lights()
	_dance_t -= dt
	if _dance_t <= 0.0:
		_dance_t = 1.0 / 15.0
		_dance()
	_red_in -= dt
	if _red_in <= 0.0 and _red_t <= 0.0:
		_red_t = RED_LONG
		_red_in = _rng.randf_range(RED_GAP.x, RED_GAP.y)
		_say(["DJ", "club_red", people[0][2]])
	_red_t = maxf(0.0, _red_t - dt)
	_beat.queue_redraw()


## The lights in the room: BEAMS cones from the two trusses down onto the floor, swinging on the
## beat; LASERS from the booth fanning over the heads; the strobe from the ceiling (none with
## `calm`). All red while the "sprinklers" go off.
static func room_lights(t: float, calm: bool, red: bool) -> Array:
	var out: Array = []
	var beat := t * BPM / 60.0
	var cols := [Color("#b44cff"), Color("#3ad8ff"), Color("#ff3ad0"), Color("#ffffff"), Color("#3ad8ff"), Color("#b44cff")]
	for i in Rave.BEAMS:
		var back := i < Rave.BEAMS / 2
		var k := i % (Rave.BEAMS / 2)
		var base := Vector3(-5.0 + k * 5.0, 5.3, -ROOM.y * 0.5 + 3.0 if back else 2.0)
		var sway := sin(beat * PI * 0.25 + k * 1.3 + (0.0 if back else 2.0)) * 0.5
		var tilt := cos(beat * PI * 0.125 + k) * 0.35
		var dir := Vector3(sin(sway), -1.0, sin(tilt) + (0.25 if back else -0.1)).normalized()
		out.append([Rave._aim(base, dir, 0.9, 5.6), Color(1, 0.05, 0.08) if red else cols[i] * 0.8])
	for i in Rave.LASERS:
		var a := (float(i) / (Rave.LASERS - 1) - 0.5) * 1.2 + sin(beat * PI * 0.5) * 0.3
		var dir := Vector3(sin(a), 0.02 + 0.05 * sin(beat * PI + i), cos(a)).normalized()
		var c := Color(1, 0.05, 0.08) if red else Color(0.2, 1.0, 0.35) * (0.35 if calm else 0.9)
		out.append([Rave._aim(Vector3(0, 2.3, -ROOM.y * 0.5 + 2.8), dir, 0.05, 13.0), c])
	var flash := 0.0
	if not calm and not red:
		flash = 1.0 if fmod(beat * 0.5, 1.0) < 0.12 else 0.0
	out.append([Rave._aim(Vector3(0, 5.4, 1.0), Vector3.DOWN, 4.0, 5.4), Color(1, 1, 1) * flash])
	return out


func _pose_lights() -> void:
	var mm := _lights.multimesh
	var pose := room_lights(_clock, Access.calm, _red_t > 0.0)
	for i in pose.size():
		mm.set_instance_transform(i, pose[i][0])
		mm.set_instance_color(i, pose[i][1])


func _dance() -> void:
	var dm := _dancers.multimesh
	var beat := _clock * BPM / 60.0
	for i in _floor.size():
		var f := _floor[i]
		var ph := fmod(beat + f.y * 0.3, 1.0)
		var hop := 0.12 * (1.0 - absf(ph * 2.0 - 1.0))
		var yaw_i := PI + sin(beat * PI * 0.5 + f.y * 6.0) * 0.4
		dm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw_i), Vector3(f.x, hop, f.z)))
	var nod := 0.05 * absf(sin(beat * PI))
	dm.set_instance_transform(DANCERS, Transform3D(Basis.IDENTITY, people[0][2] + Vector3(0, nod, 0)))
	var zh := 0.1 * (1.0 - absf(fmod(beat, 1.0) * 2.0 - 1.0))
	dm.set_instance_transform(DANCERS + 1, Transform3D(Basis(Vector3.UP, PI + sin(beat) * 0.3), people[1][2] + Vector3(0, zh, 0)))


# --- taps -----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not inside or cam == null:
		return
	var at := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		at = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		at = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			leave()
		elif event.keycode == KEY_SPACE:
			_on_dance()
		return
	if at == Vector2.INF:
		return
	var who := pick(at)
	if who >= 0:
		_say(people[who])
		get_viewport().set_input_as_handled()


## The person under screen point `at` (the view's pixels): the nearest within TAP_R m of the ray
## at chest height, or -1.
func pick(at: Vector2) -> int:
	var vp := cam.get_viewport()
	var scale := Vector2(vp.get_visible_rect().size) / get_viewport().get_visible_rect().size
	var p := at * scale
	var from := cam.project_ray_origin(p)
	var dir := cam.project_ray_normal(p)
	var best := -1
	var best_d := TAP_R
	for i in people.size():
		var c: Vector3 = PLACE + (people[i][2] as Vector3) + Vector3(0, 1.2, 0)
		var t := (c - from).dot(dir)
		var d := (from + dir * t).distance_to(c)
		if d < best_d:
			best_d = d
			best = i
	return best


func _say(person: Array) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.line(String(person[1]))
	if l.is_empty():
		return
	_who.text = String(person[0]) if String(person[0]) != "" else "Ktoś z tłumu / someone in the crowd"
	_line.text = String(l[0])
	_line_en.text = String(l[1])
	_talk.visible = true
	_talk.reset_size()
	var vp := get_viewport().get_visible_rect().size
	_talk.position.y = vp.y - _talk.size.y - 16.0 * (hud.pt if hud != null else 1.0)


## TAŃCZ: a tap near a beat keeps the streak, else it starts again; STREAK in a row pays.
func _on_dance() -> void:
	var beat := _clock * BPM / 60.0
	var off := absf(beat - roundf(beat)) * 60.0 / BPM
	if off <= BEAT_WINDOW:
		streak += 1
	else:
		streak = 0
	if streak >= STREAK:
		streak = 0
		if danced < DANCE_MAX and wallet != null:
			danced += 1
			wallet.pay(0, DANCE_PAY, "club_dance")
			_say(["Ziomek", "club_dance", people[1][2]])
		elif danced >= DANCE_MAX:
			_say(["Ziomek", "club_dance", people[1][2]])


## On the beat (for the check): seconds from `t` to the nearest beat.
static func beat_offset(t: float) -> float:
	var beat := t * BPM / 60.0
	return absf(beat - roundf(beat)) * 60.0 / BPM


func _log(text: String) -> void:
	if log_on:
		print("club: " + text)
