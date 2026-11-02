extends RefCounted
## Park props for water and paths, built from boxes in the same style as props.gd: a duck, a
## swan, a footbridge, a fountain and a rowing boat. Each `add_*` appends triangles to a shared
## SurfaceTool at the placement transform `xf` (origin on the ground or the water surface,
## fronts face -Z, metres). `colour` is the one accent part of the prop; the rest is fixed.
## Single surface, no textures, so a whole park costs one draw call.

const Props := preload("res://scripts/props.gd")


## A box at `centre` (local to `xf`), axis-aligned in the prop's frame.
static func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color) -> void:
	Props.obox(st, xf * centre, xf.basis.orthonormalized(), size, colour)


## A box turned by `local` (a basis in the prop's frame) about its centre.
static func _rbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, local: Basis, size: Vector3, colour: Color) -> void:
	Props.obox(st, xf * centre, xf.basis.orthonormalized() * local, size, colour)


## A beam between two local points, `w` wide (sideways) and `t` thick.
static func _xbeam(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, w: float, t: float, colour: Color) -> void:
	Props.beam(st, xf * a, xf * b, w, t, colour, xf.basis.x.normalized())


## A mallard sitting low on the water, ~0.5 m long: grey body, green-brown head, orange bill;
## `colour` tints the wing patch. 6 boxes, 72 triangles.
static func add_duck(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var grey := Color("#8d8a85")
	var head := Color("#3f5a3a")
	var bill := Color("#e29a2a")
	_xbox(st, xf, Vector3(0, 0.1, 0.02), Vector3(0.26, 0.16, 0.38), grey)
	_xbox(st, xf, Vector3(0, 0.15, 0.24), Vector3(0.1, 0.08, 0.1), Color("#4a4640"))
	_xbox(st, xf, Vector3(0, 0.12, 0.03), Vector3(0.27, 0.05, 0.14), colour)
	_xbox(st, xf, Vector3(0, 0.2, -0.17), Vector3(0.1, 0.14, 0.1), head)
	_xbox(st, xf, Vector3(0, 0.26, -0.2), Vector3(0.11, 0.09, 0.12), head)
	_xbox(st, xf, Vector3(0, 0.24, -0.29), Vector3(0.07, 0.03, 0.09), bill)


## A white swan ~1.1 m long with an S-curved neck and an orange bill; `colour` is the plumage.
## 9 boxes, 108 triangles.
static func add_swan(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var bill := Color("#e8872a")
	_xbox(st, xf, Vector3(0, 0.2, 0.05), Vector3(0.42, 0.28, 0.7), colour)
	_xbox(st, xf, Vector3(0, 0.3, 0.45), Vector3(0.2, 0.12, 0.2), colour)
	# Raised wings along the back.
	for s in [-1.0, 1.0]:
		_rbox(st, xf, Vector3(0.22 * s, 0.36, 0.1), Basis(Vector3.BACK, 0.25 * s), Vector3(0.05, 0.18, 0.5), colour)
	# S-curved neck: forward, up, back, then the head leaning forward.
	_xbeam(st, xf, Vector3(0, 0.25, -0.25), Vector3(0, 0.5, -0.42), 0.12, 0.12, colour)
	_xbeam(st, xf, Vector3(0, 0.5, -0.42), Vector3(0, 0.72, -0.36), 0.1, 0.1, colour)
	_xbeam(st, xf, Vector3(0, 0.72, -0.36), Vector3(0, 0.84, -0.46), 0.09, 0.09, colour)
	_xbox(st, xf, Vector3(0, 0.86, -0.52), Vector3(0.09, 0.09, 0.14), colour)
	_xbox(st, xf, Vector3(0, 0.83, -0.65), Vector3(0.06, 0.04, 0.12), bill)


## A small arched park footbridge along local z, 7 m long and 2.2 m wide: stone abutments, a deck
## that steps up to 0.7 m in five segments, and two railings 0.9 m high on posts; `colour` is the
## railing paint. 21 boxes, 252 triangles.
static func add_footbridge(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var stone := Color("#9a958c")
	var plank := Color("#7d6446")
	for sgn in [-1.0, 1.0]:
		_xbox(st, xf, Vector3(0, 0.2, 3.1 * sgn), Vector3(2.5, 0.4, 0.8), stone)
	# Deck: five segments, tops 0.45, 0.6, 0.7, 0.6, 0.45.
	var tops := [0.45, 0.6, 0.7, 0.6, 0.45]
	for i in 5:
		var top: float = tops[i]
		var z := -2.16 + 1.08 * i
		_xbox(st, xf, Vector3(0, top - 0.15, z), Vector3(2.2, 0.3, 1.08), plank if i % 2 == 0 else plank.darkened(0.08))
	# Rails: sloped top beams from each end post to the middle post, posts under them.
	var rail_end := 1.35
	var rail_mid := 1.6
	for s in [-1.0, 1.0]:
		var x: float = 1.05 * s
		_xbeam(st, xf, Vector3(x, rail_end, -2.7), Vector3(x, rail_mid, 0.0), 0.1, 0.07, colour)
		_xbeam(st, xf, Vector3(x, rail_mid, 0.0), Vector3(x, rail_end, 2.7), 0.1, 0.07, colour)
		var post_z := [-2.7, -1.35, 0.0, 1.35, 2.7]
		var deck_top := [0.45, 0.6, 0.7, 0.6, 0.45]
		for j in 5:
			var pz: float = post_z[j]
			var ry: float = lerpf(rail_end, rail_mid, 1.0 - absf(pz) / 2.7)
			var base: float = deck_top[j]
			_xbox(st, xf, Vector3(x, (base + ry) * 0.5, pz), Vector3(0.09, ry - base, 0.09), colour)


## A round park fountain 6 m across: ten stone rim blocks 0.5 m high, a water disc just below the
## rim, a plinth and a two-tier stone bowl on a stem, and a thin white jet up to 2.6 m; `colour`
## is the stone. 25 boxes, 300 triangles.
static func add_fountain(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var water := Color("#5d93a8")
	var white := Color("#f3f6f8")
	var dark := colour.darkened(0.12)
	var sides := 10
	for i in sides:
		var a := TAU * i / sides
		var c := Vector3(sin(a) * 2.8, 0.25, cos(a) * 2.8)
		_rbox(st, xf, c, Basis(Vector3.UP, a), Vector3(1.95, 0.5, 0.4), colour)
	# Water: five crossing strips make a disc; tiny height steps stop them z-fighting.
	for k in 5:
		_rbox(st, xf, Vector3(0, 0.27 + 0.004 * k, 0), Basis(Vector3.UP, PI * k / 5.0), Vector3(1.6, 0.3, 5.2), water)
	# Plinth (an octagon from two squares), stem, two bowls, finial and the jet.
	for k in 2:
		var turn := Basis(Vector3.UP, PI * 0.25 * k)
		_rbox(st, xf, Vector3(0, 0.5 + 0.02 * k, 0), turn, Vector3(1.9, 0.2, 1.9), dark)
		_rbox(st, xf, Vector3(0, 1.15 + 0.01 * k, 0), turn, Vector3(1.5, 0.22, 1.5), colour)
		_rbox(st, xf, Vector3(0, 1.85 + 0.01 * k, 0), turn, Vector3(0.9, 0.18, 0.9), colour)
	_xbox(st, xf, Vector3(0, 0.8, 0), Vector3(0.5, 0.9, 0.5), dark)
	_xbox(st, xf, Vector3(0, 1.5, 0), Vector3(0.3, 0.6, 0.3), colour)
	_xbox(st, xf, Vector3(0, 2.2, 0), Vector3(0.07, 0.8, 0.07), white)
	_xbox(st, xf, Vector3(0, 2.57, 0), Vector3(0.16, 0.06, 0.16), white)


## A 3 m wooden rowing boat on water: a flat bottom, tilted side planks, a pointed bow and a flat
## transom, two thwarts and two oars; `colour` is the hull paint. 10 boxes, 120 triangles.
static func add_rowboat(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var wood := Color("#9b7a52")
	var inner := Color("#c8b48e")
	_xbox(st, xf, Vector3(0, 0.1, 0.0), Vector3(0.7, 0.08, 2.6), inner)
	for s in [-1.0, 1.0]:
		_rbox(st, xf, Vector3(0.4 * s, 0.24, 0.0), Basis(Vector3.BACK, -0.3 * s), Vector3(0.06, 0.34, 2.7), colour)
		_rbox(st, xf, Vector3(0.24 * s, 0.24, -1.4), Basis(Vector3.UP, 0.5 * s), Vector3(0.06, 0.34, 0.55), colour)
	_xbox(st, xf, Vector3(0, 0.26, 1.38), Vector3(0.9, 0.34, 0.07), colour.darkened(0.15))
	_xbox(st, xf, Vector3(0, 0.3, -0.35), Vector3(0.85, 0.05, 0.28), wood)
	_xbox(st, xf, Vector3(0, 0.3, 0.55), Vector3(0.9, 0.05, 0.28), wood)
	# Oars poke out of the sides, blades down in the water.
	for s in [-1.0, 1.0]:
		_xbeam(st, xf, Vector3(0.35 * s, 0.4, 0.1), Vector3(1.5 * s, 0.1, 0.45), 0.05, 0.04, wood)
