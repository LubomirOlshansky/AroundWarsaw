extends Node3D
## Wellness circles (docs/design/city-life-satire.md ideas 2, 3, 4 and 8; F, 2026-11-02): four gentle
## parodies of the city's wellbeing habits, one crowd-spot family on lawns and park paths:
##  - **Sound healing** (`sound`): a ring on mats round a gong and singing bowls, a sandwich
##    board "DŹWIĘKOTERAPIA, WEJŚCIE 80 ZŁ"; the joke is the price and the gong.
##  - **Techno yoga** (`techno`): two rows of mats facing a speaker stack and a lit board
##    "TECHNO JOGA + CHOMIKI", hamsters in see-through balls rolling between the mats.
##  - **Women's club 40+** (`club`): KLUB PEŁNI, a circle holding hands round a tree and slowly
##    turning ("we wake the little girl inside"), a banner, balloons, hula hoops and a
##    thermos of something with bubbles; warm, never mean.
##  - **Kung-fu in the park** (`kungfu`): a school in white behind a master in black, all doing
##    one very slow move in step (a dip and a turn every 12 s), a pigeon among them.
## Each runs in its hours (`SPOTS`, the game clock), at fixed lawn spots read off the baked map
## (grass or park, clear of buildings, roads, water and trees; tools in the PR notes), with
## 7-10 people: the figures are one MultiMesh of the pedestrians' person mesh (standing or
## cross-legged), the hamster balls two more (a frame, the hamster), the mats, stands and signs one
## small mesh per spot shown only while the spot is on and near. +1 to +3 draw calls near a
## spot, +0 elsewhere. No shadows, no collision (like the packs and the dawn crowd). The logic
## ticks at 2 Hz, the figures at 10 Hz and only for spots within ACTIVE_R of the view.
## Lines (`sound_healing`, `techno_yoga`, `club_40`, `park_kungfu` in data/dialogue.json): a spot
## on screen near the view speaks every 22-40 s, its leader's lines tagged `leader`, a slow car
## close by the `car` lines; the spot's name as a toast the first time the car meets it.
## Add-ons: Beehave / Dialogue Manager not used (crowd spots and single lines, like packs.gd).
## The rules are static functions (check_wellness.gd runs them on synthetic clocks).

const Models := preload("res://scripts/models.gd")
const InstanceBuffers := preload("res://scripts/instance_buffers.gd")
const Crowds := preload("res://scripts/crowds.gd")
const PixelFont := preload("res://scripts/pixel_font.gd")

const TICK := 0.5
const ANIM_TICK := 0.1
## A spot within this of the view is drawn and animated.
const ACTIVE_R := 260.0
const LINE_VIEW := 110.0
const LINE_GAP := Vector2(22.0, 40.0)
const MEET_R := 28.0
const CAR_NEAR := 20.0
const CAR_KMH := 20.0
## The beat of the techno speaker (130 bpm) in Hz.
const BEAT := 2.17
## The kung-fu form's period (s): one dip and one turn, all in step.
const FORM := 12.0
## The women's circle turns this fast (rad/s).
const SPIN := 0.18
const HAMSTERS := 3
const BALL_R := 0.25

## id -> kind, `at` (game x, z on a lawn), `yaw` (which way the spot's front faces, rad), `max` people
## (the leader counted), `hours` ({"week": [[from, to]...], "weekend": [...]}, game clock), names.
## `at` read off centrum.json's grass and park areas with a search for 4-6.5 m of open lawn
## (no building within R + 1.5 m, no road, no water, no tree in the way; the women's circles
## stand round a real tree of the baked trees) near the park F's list names: Park
## Świętokrzyski, Skwer Kościuszki, Rondo Daszyńskiego, Browary Warszawskie, Ogród Saski, Park
## Ujazdowski, Ogród Krasińskich *guess* (a Mac look check is parked).
const SPOTS := {
	"sound_swietokrzyski": {"kind": "sound", "at": Vector2(-1161.0, -11.0), "yaw": 0.4, "max": 9,
			"hours": {"week": [[12.0, 15.0]], "weekend": [[10.0, 17.0]]}},
	"sound_kosciuszki": {"kind": "sound", "at": Vector2(441.0, -789.0), "yaw": 2.6, "max": 9,
			"hours": {"week": [[17.5, 19.5]], "weekend": [[10.0, 18.0]]}},
	"techno_rondo": {"kind": "techno", "at": Vector2(-2791.0, 371.0), "yaw": 0.0, "max": 10,
			"hours": {"week": [[12.0, 14.5]], "weekend": [[10.0, 12.0]]}},
	"techno_browary": {"kind": "techno", "at": Vector2(-2470.0, -103.0), "yaw": 1.2, "max": 10,
			"hours": {"week": [[17.5, 19.5]], "weekend": [[10.0, 15.0]]}},
	"club_saski": {"kind": "club", "at": Vector2(-993.1, -580.9), "yaw": 0.0, "max": 10,
			"hours": {"week": [[13.0, 15.5]], "weekend": [[11.0, 15.0]]}},
	"club_ujazdowski": {"kind": "club", "at": Vector2(74.6, 1246.1), "yaw": 0.0, "max": 10,
			"hours": {"week": [[10.0, 12.5]], "weekend": [[12.0, 16.0]]}},
	"kungfu_krasinskich": {"kind": "kungfu", "at": Vector2(-1441.0, -1622.0), "yaw": 0.5, "max": 10,
			"hours": {"week": [[7.0, 9.0], [17.5, 19.5]], "weekend": [[8.5, 11.0]]}},
	"kungfu_ujazdowski": {"kind": "kungfu", "at": Vector2(135.0, 1329.0), "yaw": 3.6, "max": 10,
			"hours": {"week": [[7.5, 9.0], [18.0, 19.5]], "weekend": [[9.0, 11.5]]}},
}
## Per kind: the dialogue group, the toast on first meeting [Polish, English], the speaker of the
## leader's lines and the bubble colour.
const KINDS := {
	"sound": {"group": "sound_healing", "toast": ["Dźwiękoterapia w parku", "Sound healing in the park"],
			"leader": "Mistrzyni gongu", "accent": Color("#c9b6ff")},
	"techno": {"group": "techno_yoga", "toast": ["Techno joga i chomiki", "Techno yoga with hamsters"],
			"leader": "Instruktor Bas", "accent": Color("#ff6fd8")},
	"club": {"group": "club_40", "toast": ["Klub Pełni 40+", "Full Moon Club 40+"],
			"leader": "Przewodniczka Pełni", "accent": Color("#ffb3d1")},
	"kungfu": {"group": "park_kungfu", "toast": ["Kung-fu w parku", "Kung-fu in the park"],
			"leader": "Mistrz Wolny", "accent": Color("#f2efe8")},
}
const EARTH := ["#e8e0cf", "#c9a46b", "#8c9a73", "#d8c3a5", "#b8b2a7", "#e4d6b6"]
const NEON := ["#ff5fa2", "#4ae0c0", "#ffd23f", "#9b6bff", "#ff8a3c", "#5aa9c9"]
const PASTEL := ["#f4b6c9", "#c7b8ea", "#a8d8c9", "#f6d6a8", "#f2efe8", "#b7cdea", "#e9a9a9"]
const WHITE := ["#f2efe8", "#ebe7dc", "#f5f3ee"]

var focus: Callable
## {"hour": float, "weekday": int} (TimeOfDay.local_clock).
var clock: Callable
## [world position, km/h, flying] of the player's vehicle.
var vehicle: Callable
var on_screen: Callable
var map: Node3D
var dialogue: Node
var hud: CanvasLayer
## The --crowd scale (Low tier 0.5).
var amount := 1.0
var log_on := false
## --wellness-now: every spot on at any hour.
var force := false
var spent_usec := 0
var lines_said := 0
var meets := 0
var spots: Array[Dictionary] = []
var t := 0.0

var _rng := RandomNumberGenerator.new()
var _tick_t := 0.0
var _anim_t := 0.0
var _log_t := 0.0
var _hour := 14.0
var _weekday := 5
var _people_mm: MultiMesh
var _people_mmi: MultiMeshInstance3D
var _people_buf := PackedFloat32Array()
var _ball_mm: MultiMesh
var _ball_mmi: MultiMeshInstance3D
var _ball_buf := PackedFloat32Array()
var _ham_mm: MultiMesh
var _ham_mmi: MultiMeshInstance3D
var _ham_buf := PackedFloat32Array()


# --- the rules (static, for the check) ------------------------------------------------------------

## Is `hours` ({"week", "weekend"} lists of [from, to]) open at `hour` on `weekday` (1 Mon .. 7 Sun)?
static func spot_on(hours: Dictionary, hour: float, weekday: int) -> bool:
	for w: Array in hours.get("weekend" if weekday >= 6 else "week", []):
		if hour >= float(w[0]) and hour < float(w[1]):
			return true
	return false


## How many are there now: 0 outside the hours (`forced`: --wellness-now), else the spot's `max`
## scaled by the --crowd scale `k` (at least a leader and two, at most `max`).
static func spot_count(spec: Dictionary, hour: float, weekday: int, k := 1.0, forced := false) -> int:
	if not forced and not spot_on(spec["hours"], hour, weekday):
		return 0
	return clampi(roundi(int(spec["max"]) * k), 3, int(spec["max"]))


## The spot-local figures of a kind, the leader first: [Vector2 local (x right, z toward the
## front), yaw (0 faces -z), pose (Crowds.STAND / SIT), Color shirt, trousers], `n` of them.
## The ring, the rows and the school are fixed; `seed_value` picks colours.
static func layout(kind: String, n: int, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	match kind:
		"sound":
			out.append([Vector2(0.0, 1.0), PI, Crowds.STAND, Color("#f2efe8"), 0.15])
			var m := maxi(n - 1, 0)
			for k in m:
				var a := TAU * float(k) / float(maxi(m, 1)) + 0.4
				var p := Vector2(sin(a), cos(a)) * 2.7
				out.append([p, atan2(p.x, p.y), Crowds.SIT, Color(EARTH[rng.randi() % EARTH.size()]), rng.randf()])
		"techno":
			out.append([Vector2(0.0, -2.6), PI, Crowds.BROAD, Color("#ff5fa2"), 0.2])
			for k in maxi(n - 1, 0):
				var col := k % 4
				var row := k / 4
				var p := Vector2(-2.4 + 1.6 * col, -1.2 + 1.7 * row)
				out.append([p, 0.0, Crowds.STAND, Color(NEON[rng.randi() % NEON.size()]), rng.randf()])
		"club":
			out.append([Vector2(0.0, 3.1), PI, Crowds.STAND, Color("#c0392b"), 0.1])
			var m := maxi(n - 1, 0)
			for k in m:
				var a := TAU * float(k) / float(maxi(m, 1))
				var p := Vector2(sin(a), cos(a)) * 2.4
				out.append([p, atan2(p.x, p.y) + PI, Crowds.STAND, Color(PASTEL[rng.randi() % PASTEL.size()]), rng.randf() * 0.6])
		"kungfu":
			out.append([Vector2(0.0, -2.6), PI, Crowds.STAND, Color("#141416"), 0.0])
			for k in maxi(n - 1, 0):
				var p := Vector2(-2.0 + 2.0 * (k % 3), -0.6 + 1.7 * (k / 3))
				out.append([p, 0.0, Crowds.STAND, Color(WHITE[rng.randi() % WHITE.size()]), 0.05])
	return out


## One figure's pose at time `t`: [Vector2 local position, yaw, y offset]. `base` is a
## `layout` row, `k` its index (0 the leader), `n` how many there are.
static func pose_at(kind: String, base: Array, k: int, n: int, tt: float) -> Array:
	var p: Vector2 = base[0]
	var yaw: float = base[1]
	var dy := 0.0
	var ph := float(k) * 1.7
	match kind:
		"sound":
			# The leader sways at the gong; the others sit, breathing.
			if k == 0:
				yaw += sin(tt * 0.7) * 0.25
				dy = maxf(0.0, sin(tt * 1.4)) * 0.03
			else:
				dy = sin(tt * 0.5 + ph) * 0.015
		"techno":
			# On the beat: a small bounce for the school, a big one for the instructor.
			var bob := absf(sin(tt * BEAT * PI + ph * 0.1))
			dy = bob * (0.12 if k == 0 else 0.05)
			yaw += sin(tt * 0.9 + ph) * 0.12
		"club":
			if k > 0:
				var m := maxi(n - 1, 1)
				var a := TAU * float(k - 1) / float(m) + tt * SPIN
				p = Vector2(sin(a), cos(a)) * 2.4
				yaw = atan2(p.x, p.y) + PI
				dy = absf(sin(tt * 1.6 + ph)) * 0.05
			else:
				dy = absf(sin(tt * 1.6)) * 0.07
				yaw += sin(tt * 0.8) * 0.3
		"kungfu":
			var f := fposmod(tt, FORM) / FORM
			dy = -0.14 * pow(sin(PI * f), 2.0)
			var turn := sin(TAU * f) * 0.9
			yaw += turn if k > 0 else -turn * 0.5
	return [p, yaw, dy]


## The counted figures (leader included) of a kind with the spot's hours, for the log.
func summary() -> String:
	var on := PackedStringArray()
	for s in spots:
		if int(s["n"]) > 0:
			on.append("%s %d" % [s["id"], s["n"]])
	return "%02d:%02d day %d · wellness %s · lines %d · meets %d" % [int(_hour), int(fmod(_hour, 1.0) * 60.0), _weekday,
			", ".join(on) if not on.is_empty() else "none", lines_said, meets]


# --- setup ----------------------------------------------------------------------------------------

func setup(seed_value := 2711) -> void:
	_rng.seed = seed_value
	var cap := 0
	var balls := 0
	for id: String in SPOTS:
		var spec: Dictionary = SPOTS[id]
		var kind: String = spec["kind"]
		var at: Vector2 = spec["at"]
		var g := _ground(at)
		var base := layout(kind, int(spec["max"]), hash(id))
		cap += base.size()
		if kind == "techno":
			balls += HAMSTERS
		spots.append({"id": id, "kind": kind, "spec": spec, "at": g, "yaw": float(spec["yaw"]), "base": base,
				"n": 0, "near": false, "props": null, "line_t": _rng.randf_range(4.0, 12.0), "met": false,
				"pos": PackedVector3Array(), "bub": PackedVector3Array()})
	_build_drawing(cap, balls)
	print("wellness: %d spots (%d sound, %d techno, %d club, %d kung-fu), amount %.2f" % [spots.size(), _count_kind("sound"),
			_count_kind("techno"), _count_kind("club"), _count_kind("kungfu"), amount])


func _count_kind(kind: String) -> int:
	var n := 0
	for s in spots:
		if s["kind"] == kind:
			n += 1
	return n


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, map.deck_height(-1, p.x, p.y) if map != null else 0.0, p.y)


# --- drawing --------------------------------------------------------------------------------------

## A box rotated and moved by `xf` into `st` (Models.box is axis-aligned).
static func _tbox(st: SurfaceTool, xf: Transform3D, size: Vector3, colour: Color, part := Models.FIXED) -> void:
	var one := SurfaceTool.new()
	one.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(one, Vector3.ZERO, size, colour, part)
	st.append_from(one.commit(), 0, xf)


static func _at(x: float, y: float, z: float, yaw := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y, z))


## A flat ring of `segs` thin boxes (a hoop, a ball's equator) in the plane spanned by the basis'
## x and z axes, radius `r`, thickness `th`.
static func _ring(st: SurfaceTool, centre: Vector3, basis: Basis, r: float, th: float, colour: Color, segs := 8) -> void:
	var seg := TAU * r / float(segs) * 1.08
	for i in segs:
		var a := TAU * float(i) / float(segs)
		var local := Vector3(sin(a) * r, 0.0, cos(a) * r)
		var b := basis * Basis(Vector3.UP, a)
		_tbox(st, Transform3D(b, centre + basis * local), Vector3(seg, th, th), colour)


## A text sign: a board on two posts facing +z, with up to two lines in `ink` (lit: glows at night).
static func _sign(st: SurfaceTool, at: Vector3, lines: Array, px: float, board: Color, ink: Color, lit := false) -> void:
	var widest := 0
	for l: String in lines:
		widest = maxi(widest, PixelFont.width(l))
	var bw := (widest + 8) * px
	var bh := (PixelFont.LINE * lines.size() + 3) * px
	var h := at.y + bh * 0.5
	Models.box(st, Vector3(at.x, h, at.z), Vector3(bw, bh, 0.06), board)
	for i in lines.size():
		var l: String = lines[i]
		var lw := PixelFont.width(l) * px
		PixelFont.add_quads(st, l, Vector3(at.x - lw * 0.5, h + bh * 0.5 - (1.5 + PixelFont.LINE * i) * px, at.z + 0.04), Vector3.RIGHT,
				Vector3.DOWN, px, ink, Models.LIT_SIGN if lit else Models.FIXED)
	for x in [-bw * 0.5 + 0.08, bw * 0.5 - 0.08]:
		Models.box(st, Vector3(at.x + x, at.y * 0.5, at.z), Vector3(0.07, at.y, 0.07), Color("#5a5d63"))


## Everything a spot of `kind` puts on the ground, spot-local, facing +z.
static func props_mesh(kind: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bronze := Color("#c79a3c")
	var dark := Color("#18181b")
	var grey := Color("#5a5d63")
	var wood := Color("#c9a46b")
	match kind:
		"sound":
			# A mat under each seat (radial), the gong on its frame in the middle, three singing bowls.
			for k in 8:
				var a := TAU * float(k) / 8.0 + 0.4
				_tbox(st, Transform3D(Basis(Vector3.UP, a), Vector3(sin(a) * 2.7, 0.015, cos(a) * 2.7)), Vector3(0.9, 0.03, 1.8),
						Color(EARTH[k % EARTH.size()]).darkened(0.1))
			for x in [-0.7, 0.7]:
				Models.box(st, Vector3(x, 0.95, 0.0), Vector3(0.08, 1.9, 0.1), wood)
				Models.box(st, Vector3(x, 0.04, 0.0), Vector3(0.1, 0.08, 0.7), wood)
			Models.box(st, Vector3(0, 1.88, 0.0), Vector3(1.5, 0.07, 0.07), wood)
			for q in 4:
				_tbox(st, Transform3D(Basis(Vector3.BACK, PI * float(q) / 4.0), Vector3(0, 1.15, 0.0)), Vector3(0.95, 0.24, 0.05), bronze)
			Models.box(st, Vector3(0, 1.15, 0.0), Vector3(0.22, 0.22, 0.08), bronze.lightened(0.25))
			Models.box(st, Vector3(0.45, 0.65, 0.04), Vector3(0.05, 0.5, 0.05), wood)
			Models.box(st, Vector3(0.45, 0.42, 0.04), Vector3(0.14, 0.14, 0.14), Color("#f2efe8"))
			for p in [Vector3(-1.2, 0.0, 0.5), Vector3(1.25, 0.0, 0.8), Vector3(0.2, 0.0, 1.5)]:
				Models.box(st, p + Vector3(0, 0.07, 0), Vector3(0.34, 0.14, 0.34), bronze)
				Models.box(st, p + Vector3(0, 0.145, 0), Vector3(0.24, 0.02, 0.24), bronze.darkened(0.35))
			_sign(st, Vector3(0, 1.0, 3.9), ["DŹWIĘKOTERAPIA", "WEJŚCIE 80 ZŁ"], 0.024, Color("#2f4a3b"), Color("#f2efe8"))
		"techno":
			for k in 8:
				var col := k % 4
				var row := k / 4
				Models.box(st, Vector3(-2.4 + 1.6 * col, 0.015, -1.2 + 1.7 * row), Vector3(0.7, 0.03, 1.5), Color(NEON[(k * 5) % NEON.size()]).darkened(0.25))
			for x in [-1.5, 1.5]:
				Models.box(st, Vector3(x, 0.8, -3.7), Vector3(0.7, 1.6, 0.55), dark)
				Models.box(st, Vector3(x, 0.55, -3.41), Vector3(0.46, 0.46, 0.02), grey)
				Models.box(st, Vector3(x, 1.15, -3.41), Vector3(0.22, 0.22, 0.02), grey)
			Models.box(st, Vector3(0, 0.55, -3.7), Vector3(1.6, 1.1, 0.5), wood)
			Models.box(st, Vector3(0, 1.14, -3.7), Vector3(1.0, 0.1, 0.4), dark)
			_sign(st, Vector3(0, 2.0, -4.3), ["TECHNO JOGA", "+ CHOMIKI"], 0.05, Color("#231a2e"), Color("#ffe2a8"), true)
			var bulbs := ["#ff5fa2", "#ffd23f", "#4ae0c0", "#9b6bff", "#ff8a3c"]
			for k in 9:
				var f := float(k) / 8.0
				Models.box(st, Vector3(lerpf(-3.2, 3.2, f), 3.15 - sin(f * PI) * 0.4, -4.3), Vector3(0.09, 0.11, 0.09), Color(bulbs[k % bulbs.size()]), Models.LIT_SIGN)
		"club":
			_sign(st, Vector3(0, 2.4, 4.4), ["KLUB PEŁNI 40+", "BUDZIMY MAŁĄ DZIEWCZYNKĘ"], 0.021, Color("#f0a7c4"), Color("#ffffff"))
			for k in 7:
				var bx := -2.1 + 0.7 * float(k)
				var by := 3.4 + 0.25 * float(k % 3)
				Models.box(st, Vector3(bx, by, 4.3), Vector3(0.3, 0.38, 0.3), Color(PASTEL[k % PASTEL.size()]))
				Models.box(st, Vector3(bx, by * 0.5 - 0.1, 4.3), Vector3(0.012, by - 0.2, 0.012), Color("#e8e4d8"))
			for p in [Vector3(3.3, 0, 1.0), Vector3(3.8, 0, 2.1), Vector3(-3.5, 0, 1.6)]:
				_ring(st, p + Vector3(0, 0.04, 0), Basis.IDENTITY, 0.45, 0.04, Color(PASTEL[int(absf(p.x) * 3.0) % PASTEL.size()]).darkened(0.1))
			# The thermos table: bubbles in plastic cups.
			Models.box(st, Vector3(-3.6, 0.5, -0.8), Vector3(0.9, 0.05, 0.6), Color("#f2efe8"))
			for x in [-0.4, 0.4]:
				Models.box(st, Vector3(-3.6 + x, 0.25, -0.8), Vector3(0.06, 0.5, 0.5), Color("#c8c2b4"))
			Models.box(st, Vector3(-3.8, 0.7, -0.8), Vector3(0.14, 0.34, 0.14), Color("#2f5a3b"))
			Models.box(st, Vector3(-3.5, 0.58, -0.7), Vector3(0.07, 0.1, 0.07), Color("#e8e4d8"))
			Models.box(st, Vector3(-3.35, 0.58, -0.9), Vector3(0.07, 0.1, 0.07), Color("#e8e4d8"))
		"kungfu":
			_sign(st, Vector3(0, 1.3, 4.0), ["SZKOŁA ŻURAWIA"], 0.026, Color("#7a1f1f"), Color("#f2d27a"))
			for x in [-1.9, 2.7]:
				Models.box(st, Vector3(x, 0.14, 2.4), Vector3(0.22, 0.28, 0.12), Color("#2b2c2f"))
			Models.box(st, Vector3(3.1, 0.07, 2.4), Vector3(0.08, 0.14, 0.08), Color("#4a90d9"))
			# A pigeon among the students.
			Models.box(st, Vector3(0.9, 0.12, 0.2), Vector3(0.16, 0.14, 0.3), Color("#8c929c"))
			Models.box(st, Vector3(0.9, 0.2, 0.06), Vector3(0.1, 0.1, 0.1), Color("#5d6470"))
			Models.box(st, Vector3(0.9, 0.2, 0.0), Vector3(0.03, 0.03, 0.06), Color("#e8b04a"))
	return st.commit()


## A hamster ball's frame: three thin rings about its centre (a see-through sphere in boxes).
static func ball_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frame := Color("#9bd3f0")
	_ring(st, Vector3.ZERO, Basis.IDENTITY, BALL_R, 0.025, frame)
	_ring(st, Vector3.ZERO, Basis(Vector3.RIGHT, PI * 0.5), BALL_R, 0.025, frame)
	_ring(st, Vector3.ZERO, Basis(Vector3.BACK, PI * 0.5), BALL_R, 0.025, frame)
	return st.commit()


## The hamster inside, facing -z, centred on its ball.
static func hamster_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Models.box(st, Vector3(0, -0.07, 0.0), Vector3(0.15, 0.12, 0.2), Color("#c78a4e"))
	Models.box(st, Vector3(0, -0.08, -0.12), Vector3(0.1, 0.09, 0.08), Color("#e8c9a0"))
	Models.box(st, Vector3(0, -0.01, -0.1), Vector3(0.12, 0.05, 0.06), Color("#c78a4e"))
	Models.box(st, Vector3(0, -0.06, 0.11), Vector3(0.05, 0.05, 0.04), Color("#e8c9a0"))
	return st.commit()


func _build_drawing(people_cap: int, ball_cap: int) -> void:
	var mat := Models.material().duplicate() as ShaderMaterial
	mat.set_shader_parameter("walk", 0.0)
	_people_mm = _new_mm(Models.person_mesh(), maxi(people_cap, 1))
	_people_mmi = _new_mmi(_people_mm, "WellnessPeople", mat)
	_people_buf.resize(maxi(people_cap, 1) * 16)
	_people_buf.fill(0.0)
	_ball_mm = _new_mm(ball_mesh(), maxi(ball_cap, 1))
	_ball_mmi = _new_mmi(_ball_mm, "HamsterBalls", Models.material())
	_ball_buf.resize(maxi(ball_cap, 1) * 16)
	_ball_buf.fill(0.0)
	_ham_mm = _new_mm(hamster_mesh(), maxi(ball_cap, 1))
	_ham_mmi = _new_mmi(_ham_mm, "Hamsters", Models.material())
	_ham_buf.resize(maxi(ball_cap, 1) * 16)
	_ham_buf.fill(0.0)
	var meshes := {}
	for s in spots:
		var kind: String = s["kind"]
		if not meshes.has(kind):
			meshes[kind] = props_mesh(kind)
		var mi := MeshInstance3D.new()
		mi.name = "Wellness_%s" % s["id"]
		mi.mesh = meshes[kind]
		mi.material_override = Models.material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = s["at"]
		mi.rotation.y = float(s["yaw"])
		mi.visible = false
		add_child(mi)
		s["props"] = mi


func _new_mm(mesh: Mesh, cap: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	InstanceBuffers.prepare(mm)
	mm.mesh = mesh
	mm.instance_count = cap
	mm.visible_instance_count = 0
	return mm


func _new_mmi(mm: MultiMesh, n: String, mat: Material) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = n
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mmi.visible = false
	add_child(mmi)
	return mmi


## Spot-local (x, z) to the world's, for a spot turned by `yaw` (the same turn as a node's rotation.y).
static func to_world(local: Vector2, yaw: float) -> Vector2:
	var c := cos(yaw)
	var s := sin(yaw)
	return Vector2(local.x * c + local.y * s, -local.x * s + local.y * c)


# --- the logic ------------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if dt <= 0.0 or not clock.is_valid():
		return
	var t0 := Time.get_ticks_usec()
	t += dt
	_tick_t += dt
	if _tick_t >= TICK:
		var step := _tick_t
		_tick_t = 0.0
		tick(step)
	_anim_t += dt
	if _anim_t >= ANIM_TICK:
		_anim_t = 0.0
		animate()
	spent_usec += Time.get_ticks_usec() - t0


## One tick: who is out, who is near the view, the lines and the toasts.
func tick(step: float) -> void:
	var now: Dictionary = clock.call()
	_hour = float(now["hour"])
	_weekday = int(now["weekday"])
	var eye3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var eye := Vector2(eye3.x, eye3.z)
	var veh: Array = vehicle.call() if vehicle.is_valid() else [Vector3.INF, 0.0, false]
	var vp: Vector3 = veh[0]
	var car2 := Vector2(vp.x, vp.z) if vp != Vector3.INF and not bool(veh[2]) else Vector2.INF
	for s in spots:
		var n := spot_count(s["spec"], _hour, _weekday, amount, force)
		var on := n > 0
		if on != (int(s["n"]) > 0) and log_on:
			var a: Vector3 = s["at"]
			print("wellness: %s %s (%d people at %.0f, %.0f)" % [s["id"], "starts" if on else "packs up", n, a.x, a.z])
		s["n"] = n
		var a3: Vector3 = s["at"]
		var a2 := Vector2(a3.x, a3.z)
		var near := on and eye.distance_to(a2) < ACTIVE_R
		if near != bool(s["near"]):
			s["near"] = near
		(s["props"] as MeshInstance3D).visible = near
		if near:
			_talk(s, step, eye, car2, float(veh[1]))
	if log_on:
		_log_t -= step
		if _log_t <= 0.0:
			_log_t = 60.0
			print("wellness: %s" % summary())


## The figures and the hamsters, 10 times a second for the spots near the view.
func animate() -> void:
	var np := 0
	var nb := 0
	var pbox := AABB()
	var bbox := AABB()
	var first_p := true
	var first_b := true
	for s in spots:
		if not bool(s["near"]):
			continue
		var kind: String = s["kind"]
		var g: Vector3 = s["at"]
		var yaw: float = s["yaw"]
		var base: Array = s["base"]
		var n := mini(int(s["n"]), base.size())
		var pos := PackedVector3Array()
		pos.resize(n)
		for k in n:
			if np >= _people_mm.instance_count:
				break
			var row: Array = base[k]
			var ps := pose_at(kind, row, k, n, t)
			var w := to_world(ps[0], yaw)
			var at := Vector3(g.x + w.x, g.y + float(ps[2]), g.z + w.y)
			pos[k] = at
			Crowds.put(_people_buf, np, at, float(ps[1]) + yaw, int(row[2]), row[3], float(row[4]))
			pbox = AABB(at, Vector3.ZERO) if first_p else pbox.expand(at)
			first_p = false
			np += 1
		s["pos"] = pos
		if kind == "techno":
			for h in HAMSTERS:
				if nb >= _ball_mm.instance_count:
					break
				var ph := float(h) * 2.1 + float(hash(s["id"]) % 7)
				# A slow Lissajous between the mats, and the heading from its derivative.
				var lx := 3.1 * sin(0.33 * t + ph)
				var lz := -1.3 + 2.0 * sin(0.21 * t * 1.3 + ph * 1.7)
				var dx := 3.1 * 0.33 * cos(0.33 * t + ph)
				var dz := 2.0 * 0.273 * cos(0.273 * t + ph * 1.7)
				var speed := Vector2(dx, dz).length()
				var head := atan2(-dx, -dz)
				var roll := -(t * speed) / BALL_R
				var wl := to_world(Vector2(lx, lz), yaw)
				var centre := Vector3(g.x + wl.x, g.y + BALL_R + 0.02, g.z + wl.y)
				var b := Basis(Vector3.UP, head + yaw) * Basis(Vector3.RIGHT, roll)
				_put_basis(_ball_buf, nb, centre, b, Color.WHITE, 0.0)
				_put_basis(_ham_buf, nb, centre, Basis(Vector3.UP, head + yaw), Color.WHITE, 0.0)
				bbox = AABB(centre, Vector3.ZERO) if first_b else bbox.expand(centre)
				first_b = false
				nb += 1
	_send(_people_mm, _people_mmi, _people_buf, np, pbox)
	_send(_ball_mm, _ball_mmi, _ball_buf, nb, bbox)
	_send(_ham_mm, _ham_mmi, _ham_buf, nb, bbox)


## An instance with a full rotation (the pedestrians' `Crowds.put` only turns about up).
static func _put_basis(buf: PackedFloat32Array, i: int, at: Vector3, b: Basis, shirt: Color, trousers: float) -> void:
	var o := i * 16
	buf[o] = b.x.x
	buf[o + 1] = b.y.x
	buf[o + 2] = b.z.x
	buf[o + 3] = at.x
	buf[o + 4] = b.x.y
	buf[o + 5] = b.y.y
	buf[o + 6] = b.z.y
	buf[o + 7] = at.y
	buf[o + 8] = b.x.z
	buf[o + 9] = b.y.z
	buf[o + 10] = b.z.z
	buf[o + 11] = at.z
	buf[o + 12] = shirt.r
	buf[o + 13] = shirt.g
	buf[o + 14] = shirt.b
	buf[o + 15] = trousers


func _send(mm: MultiMesh, mmi: MultiMeshInstance3D, buf: PackedFloat32Array, n: int, box: AABB) -> void:
	mm.visible_instance_count = n
	if n > 0:
		InstanceBuffers.send(mm.get_rid(), buf)
		mm.custom_aabb = box.grow(1.5).expand(box.end + Vector3(0, 2.8, 0))
	if mmi.visible != (n > 0):
		mmi.visible = n > 0


## A spot's lines: a slow car close by (`car`), else now and then a person or the leader while the
## spot is on screen near the view; the spot's name as a toast the first time the car meets it.
func _talk(s: Dictionary, step: float, eye: Vector2, car2: Vector2, kmh: float) -> void:
	var kind: Dictionary = KINDS[s["kind"]]
	var at: Vector3 = s["at"]
	var a2 := Vector2(at.x, at.z)
	if car2 != Vector2.INF and not bool(s["met"]) and car2.distance_to(a2) < MEET_R:
		s["met"] = true
		meets += 1
		var toast: Array = kind["toast"]
		if hud != null and hud.has_method("ambient_toast"):
			hud.ambient_toast(str(toast[0]), str(toast[1]))
		if log_on:
			print("wellness: the car meets %s" % s["id"])
	s["line_t"] = float(s["line_t"]) - step
	if float(s["line_t"]) > 0.0 or int(s["n"]) == 0:
		return
	var slow := car2 != Vector2.INF and car2.distance_to(a2) < CAR_NEAR and kmh < CAR_KMH
	var seen: bool = eye.distance_to(a2) < LINE_VIEW and (not on_screen.is_valid() or on_screen.call(at, 2.0))
	if not slow and not seen:
		return
	s["line_t"] = _rng.randf_range(LINE_GAP.x, LINE_GAP.y)
	var pos: PackedVector3Array = s["pos"]
	var n := mini(int(s["n"]), pos.size())
	if n == 0:
		return
	var group: String = kind["group"]
	var accent: Color = kind["accent"]
	if slow and _rng.randf() < 0.65:
		var j := 1 if n > 1 else 0
		_say(func() -> Vector3: return _spot_point(s, j) + Vector3(0, 2.1, 0), "", group, "car", accent, true)
	elif _rng.randf() < 0.35:
		_say(func() -> Vector3: return _spot_point(s, 0) + Vector3(0, 2.3, 0), str(kind["leader"]), group, "leader", accent, true)
	else:
		var j2 := 1 + _rng.randi() % maxi(n - 1, 1)
		_say(func() -> Vector3: return _spot_point(s, j2) + Vector3(0, 2.0, 0), "", group, "", accent)


func _spot_point(s: Dictionary, k: int) -> Vector3:
	var pos: PackedVector3Array = s["pos"]
	if k >= pos.size() or int(s["n"]) == 0:
		return Vector3.INF
	return pos[k]


func _say(anchor: Callable, speaker: String, group: String, tag: String, accent: Color, prefer := false) -> void:
	if dialogue == null:
		return
	var l: Array = dialogue.say_ambient(anchor, speaker, group, tag, 4.0, accent, 2.2, prefer or tag != "")
	if not l.is_empty():
		lines_said += 1
		if log_on:
			print("wellness: line %s/%s: %s" % [group, tag, l[0]])


## The spot nearest a point (for --wellness-now shots and the log): [kind, id, Vector3] or [].
func nearest_to(p: Vector2) -> Array:
	var best: Array = []
	var bd := INF
	for s in spots:
		var a: Vector3 = s["at"]
		var d := Vector2(a.x, a.z).distance_to(p)
		if d < bd:
			bd = d
			best = [s["kind"], s["id"], a]
	return best
