extends RefCounted
## Park life for the street-prop mesh: a seated person, a picnic, a peacock, a red squirrel,
## a sandstone garden statue and an outdoor yoga class. All boxes in one SurfaceTool surface,
## placed by `xf` (origin on the ground, fronts face -Z, metres), in the style of props.gd's
## people and pigeon. `colour` is each kind's main accent (shirt, blanket, fur, stone).

const Props := preload("res://scripts/props.gd")

const SKIN := Color("#e2b48c")
const TROUSERS := Color("#3d4658")


## A box through a transform (a private copy of props.gd's `_xbox`).
static func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color) -> void:
	Props.obox(st, xf * centre, xf.basis.orthonormalized(), size, colour)


## Hair tone from the accent's hue, so neighbours in different tops differ in hair too.
static func _hair(colour: Color) -> Color:
	var tones: Array[Color] = [Color("#4a3426"), Color("#1f1a18"), Color("#8a6a3c"), Color("#b5532f")]
	return tones[int(colour.h * 4.0) % 4]


## A person sitting with the seat surface at `seat` metres, at local x/z `at`: thighs forward,
## shins down, a 0.5 m torso, head with hair, arms folded into one wide shirt box. 5 boxes.
static func _sitter(st: SurfaceTool, xf: Transform3D, at: Vector3, seat: float, colour: Color) -> void:
	_xbox(st, xf, at + Vector3(0, seat + 0.09, -0.2), Vector3(0.3, 0.16, 0.44), TROUSERS)
	_xbox(st, xf, at + Vector3(0, seat - 0.2, -0.4), Vector3(0.28, 0.4, 0.14), TROUSERS)
	_xbox(st, xf, at + Vector3(0, seat + 0.43, 0.04), Vector3(0.42, 0.5, 0.26), colour)
	_xbox(st, xf, at + Vector3(0, seat + 0.9, 0.04), Vector3(0.24, 0.24, 0.24), SKIN)
	_xbox(st, xf, at + Vector3(0, seat + 1.0, 0.07), Vector3(0.26, 0.09, 0.28), _hair(colour))


## One person on a park bench (seat 0.45 m), facing -Z. ~60 triangles.
static func add_seated(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	# The arms are folded into the torso box; the sitter helper has 5 boxes.
	_sitter(st, xf, Vector3.ZERO, 0.45, colour)


## A cross-legged figure on the ground (picnic, yoga): crossed legs, torso, head and hair,
## arms as one box. 5 boxes.
static func _lotus(st: SurfaceTool, xf: Transform3D, at: Vector3, colour: Color) -> void:
	_xbox(st, xf, at + Vector3(0, 0.08, -0.08), Vector3(0.5, 0.16, 0.42), TROUSERS)
	_xbox(st, xf, at + Vector3(0, 0.45, 0.02), Vector3(0.4, 0.5, 0.24), colour)
	_xbox(st, xf, at + Vector3(0, 0.86, 0.02), Vector3(0.23, 0.23, 0.23), SKIN)
	_xbox(st, xf, at + Vector3(0, 0.96, 0.05), Vector3(0.25, 0.09, 0.27), _hair(colour))
	_xbox(st, xf, at + Vector3(0, 0.36, -0.12), Vector3(0.56, 0.1, 0.1), colour)


## A picnic: a 1.8 x 1.4 m blanket in `colour` with a pair of white stripes, two people, a
## basket and two bottles. ~200 triangles.
static func add_picnic(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var white := Color("#f4f1ea")
	_xbox(st, xf, Vector3(0, 0.015, 0), Vector3(1.8, 0.03, 1.4), colour)
	_xbox(st, xf, Vector3(0, 0.032, 0.0), Vector3(1.8, 0.01, 0.12), white)
	_xbox(st, xf, Vector3(0.0, 0.034, 0.0), Vector3(0.12, 0.01, 1.4), white)
	_lotus(st, xf, Vector3(-0.5, 0.03, 0.3), colour.lerp(Color("#d8d4c8"), 0.6))
	_lotus(st, xf, Vector3(0.5, 0.03, 0.3), Color("#c85a4a"))
	_xbox(st, xf, Vector3(-0.1, 0.16, -0.4), Vector3(0.4, 0.26, 0.28), Color("#a8793f"))
	_xbox(st, xf, Vector3(-0.1, 0.32, -0.4), Vector3(0.34, 0.05, 0.05), Color("#7a5530"))
	_xbox(st, xf, Vector3(0.35, 0.15, -0.38), Vector3(0.08, 0.26, 0.08), Color("#2f6b3a"))
	_xbox(st, xf, Vector3(0.5, 0.14, -0.3), Vector3(0.08, 0.24, 0.08), Color("#7a2a34"))


## A peacock standing, ~1.5 m with its train trailing behind (+Z): `colour` is the body blue,
## a darker neck, small crest, and a fan of three flat green boxes with eye-spots. 10 boxes.
static func add_peacock(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var neck := colour.darkened(0.2)
	var green := Color("#2f7d4a")
	_xbox(st, xf, Vector3(0, 0.5, 0.05), Vector3(0.26, 0.28, 0.5), colour)
	_xbox(st, xf, Vector3(0, 0.78, -0.2), Vector3(0.11, 0.42, 0.11), neck)
	_xbox(st, xf, Vector3(0, 1.02, -0.25), Vector3(0.12, 0.12, 0.2), colour.darkened(0.1))
	_xbox(st, xf, Vector3(0, 1.12, -0.2), Vector3(0.03, 0.1, 0.03), Color("#1c2a4a"))
	_xbox(st, xf, Vector3(0, 0.18, 0.02), Vector3(0.12, 0.36, 0.06), Color("#8a8a82"))
	_xbox(st, xf, Vector3(0, 0.42, 0.75), Vector3(0.2, 0.04, 0.9), green)
	_xbox(st, xf, Vector3(-0.2, 0.4, 0.7), Vector3(0.2, 0.04, 0.8), green.darkened(0.15))
	_xbox(st, xf, Vector3(0.2, 0.4, 0.7), Vector3(0.2, 0.04, 0.8), green.darkened(0.15))
	_xbox(st, xf, Vector3(-0.2, 0.43, 1.0), Vector3(0.08, 0.02, 0.1), Color("#2a5fb0"))
	_xbox(st, xf, Vector3(0.2, 0.43, 1.0), Vector3(0.08, 0.02, 0.1), Color("#2a5fb0"))


## A red squirrel sitting up, 0.25 m tall, with a big curled tail behind. 4 boxes.
static func add_squirrel(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.1, 0), Vector3(0.1, 0.16, 0.12), colour)
	_xbox(st, xf, Vector3(0, 0.2, -0.02), Vector3(0.08, 0.08, 0.08), colour.lightened(0.1))
	_xbox(st, xf, Vector3(0, 0.22, -0.02), Vector3(0.1, 0.04, 0.03), colour.darkened(0.25))
	_xbox(st, xf, Vector3(0, 0.15, 0.13), Vector3(0.08, 0.26, 0.12), colour.darkened(0.1))


## An allegorical sandstone garden statue (Ogród Saski): a 1.3 m moulded plinth and a 1.6 m
## draped figure with one arm raised holding an urn. `colour` is the stone. 16 boxes.
static func add_statue(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var dark := colour.darkened(0.12)
	var light := colour.lightened(0.1)
	_xbox(st, xf, Vector3(0, 0.1, 0), Vector3(1.0, 0.2, 1.0), dark)
	_xbox(st, xf, Vector3(0, 0.22, 0), Vector3(0.88, 0.05, 0.88), light)
	_xbox(st, xf, Vector3(0, 0.65, 0), Vector3(0.7, 0.8, 0.7), colour)
	_xbox(st, xf, Vector3(0, 0.7, -0.355), Vector3(0.44, 0.4, 0.02), dark)
	_xbox(st, xf, Vector3(0, 1.1, 0), Vector3(0.84, 0.08, 0.84), light)
	_xbox(st, xf, Vector3(0, 1.18, 0), Vector3(0.96, 0.1, 0.96), colour)
	# The figure on the top (plinth top at 1.23 m).
	_xbox(st, xf, Vector3(0, 1.45, 0), Vector3(0.6, 0.4, 0.4), colour)
	_xbox(st, xf, Vector3(0, 1.8, 0), Vector3(0.46, 0.35, 0.3), light)
	_xbox(st, xf, Vector3(0, 2.15, 0), Vector3(0.44, 0.38, 0.26), colour)
	_xbox(st, xf, Vector3(0, 2.2, -0.15), Vector3(0.1, 0.6, 0.04), dark)
	_xbox(st, xf, Vector3(0, 2.46, 0), Vector3(0.2, 0.22, 0.2), light)
	_xbox(st, xf, Vector3(-0.3, 1.95, -0.02), Vector3(0.12, 0.6, 0.14), colour)
	_xbox(st, xf, Vector3(0.28, 2.5, -0.02), Vector3(0.12, 0.55, 0.14), colour)
	_xbox(st, xf, Vector3(0.28, 2.85, -0.02), Vector3(0.22, 0.14, 0.22), dark)
	_xbox(st, xf, Vector3(0.28, 2.97, -0.02), Vector3(0.14, 0.1, 0.14), light)


## An outdoor yoga class: four mats in a row, each with a person alternating cross-legged
## and a tree pose with arms up; `colour` is their top. ~330 triangles.
static func add_yoga(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var mats: Array[Color] = [Color("#6a8f7a"), Color("#b66a8d"), Color("#5a79b0"), Color("#c9a03c")]
	for i in 4:
		var x := -1.2 + 0.8 * i
		var top := colour if i % 2 == 0 else colour.lerp(Color("#f4f1ea"), 0.5)
		_xbox(st, xf, Vector3(x, 0.01, 0), Vector3(0.62, 0.02, 1.8), mats[i])
		if i % 2 == 0:
			_lotus(st, xf, Vector3(x, 0.02, 0.1), top)
		else:
			# Tree pose: one straight leg, the other foot to the knee, hands joined overhead.
			_xbox(st, xf, Vector3(x, 0.45, 0), Vector3(0.14, 0.86, 0.16), TROUSERS)
			_xbox(st, xf, Vector3(x - 0.14, 0.62, -0.1), Vector3(0.22, 0.12, 0.2), TROUSERS)
			_xbox(st, xf, Vector3(x, 1.15, 0), Vector3(0.4, 0.62, 0.24), top)
			_xbox(st, xf, Vector3(x, 1.58, 0), Vector3(0.23, 0.23, 0.23), SKIN)
			_xbox(st, xf, Vector3(x, 1.68, 0.03), Vector3(0.25, 0.09, 0.27), _hair(top))
			_xbox(st, xf, Vector3(x, 1.98, 0), Vector3(0.1, 0.5, 0.1), top)
			_xbox(st, xf, Vector3(x, 1.7, 0.0), Vector3(0.56, 0.1, 0.1), top)
