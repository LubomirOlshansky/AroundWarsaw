extends RefCounted
## Box-built park props for the play and rest corners of the parks (the Ogród Krasińskich
## carousel, a playground, a gazebo, a sundial, a pergola). Same style as props.gd: one
## SurfaceTool surface, actors' material, no textures, metres, fronts face -Z, `xf` is the
## placement with its origin on the ground. `colour` is the main accent of each kind.

const Props := preload("res://scripts/props.gd")


## A box at `centre` (local to `xf`) turned by `rot` (a local basis), size in the box's own axes.
static func _xo(st: SurfaceTool, xf: Transform3D, centre: Vector3, rot: Basis, size: Vector3, colour: Color, part := Props.FIXED) -> void:
	Props.obox(st, xf * centre, (xf.basis * rot).orthonormalized(), size, colour, part)


## An axis box in the placement's frame (as props.gd's own helper).
static func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color, part := Props.FIXED) -> void:
	Props.obox(st, xf * centre, xf.basis.orthonormalized(), size, colour, part)


## A beam between two local points, `w` wide and `t` thick.
static func _xbeam(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, w: float, t: float, colour: Color) -> void:
	Props.beam(st, xf * a, xf * b, w, t, colour)


## One triangle facing `n` (winding fixed to match the normal).
static func _tri(st: SurfaceTool, xf: Transform3D, a: Vector3, b: Vector3, c: Vector3, n: Vector3, colour: Color) -> void:
	var wa := xf * a
	var wb := xf * b
	var wc := xf * c
	var wn := (xf.basis * n).normalized()
	if (wb - wa).cross(wc - wa).dot(wn) > 0.0:
		var t := wb
		wb = wc
		wc = t
	for p in [wa, wb, wc]:
		st.set_color(colour)
		st.set_normal(wn)
		st.set_uv(Vector2(Props.FIXED, 0.0))
		st.add_vertex(p)


## Direction on the ground at angle `a` (0 = +z, turning towards +x).
static func _dir(a: float) -> Vector3:
	return Vector3(sin(a), 0.0, cos(a))


## A regular n-sided prism (flat sides, `apothem` to the flats, a flat facing +z) from y0 to y1.
static func _prism(st: SurfaceTool, xf: Transform3D, n: int, apothem: float, y0: float, y1: float, colour: Color) -> void:
	var rc := apothem / cos(PI / n)
	for k in n:
		var a0 := (k - 0.5) * TAU / n
		var a1 := (k + 0.5) * TAU / n
		var p0 := _dir(a0) * rc
		var p1 := _dir(a1) * rc
		_tri(st, xf, Vector3(0, y1, 0), p0 + Vector3(0, y1, 0), p1 + Vector3(0, y1, 0), Vector3.UP, colour)
		var nn := _dir(k * TAU / n)
		_tri(st, xf, p0 + Vector3(0, y0, 0), p1 + Vector3(0, y0, 0), p1 + Vector3(0, y1, 0), nn, colour.darkened(0.12))
		_tri(st, xf, p0 + Vector3(0, y0, 0), p1 + Vector3(0, y1, 0), p0 + Vector3(0, y1, 0), nn, colour.darkened(0.12))


## A ring of n thin boxes (a polygon band) at flat distance `r`, centred height `y`, `h` tall and
## `t` thick; `skip` is the side index left out (-1 = none).
static func _band(st: SurfaceTool, xf: Transform3D, n: int, r: float, y: float, h: float, t: float, colour: Color, skip := -1) -> void:
	var chord := 2.0 * r * tan(PI / n) + t
	for k in n:
		if k == skip:
			continue
		var rot := Basis(Vector3.UP, k * TAU / n)
		_xo(st, xf, rot * Vector3(0, y, r), rot, Vector3(chord, h, t), colour)


## A pyramid roof of n flat faces from the eave ring (`apothem`, height y0) up to the apex at y1.
## Faces alternate between `a` and `b`; `under` closes the underside.
static func _pyramid(st: SurfaceTool, xf: Transform3D, n: int, apothem: float, y0: float, y1: float, a: Color, b: Color, under: Color) -> void:
	var rc := apothem / cos(PI / n)
	var apex := Vector3(0, y1, 0)
	var slope := (y1 - y0) / apothem
	for k in n:
		var p0 := _dir((k - 0.5) * TAU / n) * rc + Vector3(0, y0, 0)
		var p1 := _dir((k + 0.5) * TAU / n) * rc + Vector3(0, y0, 0)
		var nn := (_dir(k * TAU / n) + Vector3(0, 1.0 / maxf(slope, 0.05), 0)).normalized()
		_tri(st, xf, p0, p1, apex, nn, a if k % 2 == 0 else b)
		_tri(st, xf, Vector3(0, y0 - 0.02, 0), p1 - Vector3(0, 0.02, 0), p0 - Vector3(0, 0.02, 0), Vector3.DOWN, under)


# --- the carousel ---------------------------------------------------------------------

## The old merry-go-round of Ogród Krasińskich, 5 m across: a round plinth, a centre column, a
## 10-sided canopy to 4.2 m with `colour`/cream wedges and a valance, eight pastel horses on
## poles around the rim and a warm bulb strip under the canopy. ~700 tris.
static func add_carousel(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var cream := Color("#f1e6cc")
	var gold := Color("#d9b24a")
	var wood := Color("#7a5a3a")
	_prism(st, xf, 10, 2.5, 0.0, 0.25, Color("#8d877d"))
	_xbox(st, xf, Vector3(0, 1.55, 0), Vector3(0.4, 2.6, 0.4), wood)
	_xbox(st, xf, Vector3(0, 0.45, 0), Vector3(0.9, 0.4, 0.9), wood.darkened(0.15))
	_pyramid(st, xf, 10, 2.5, 2.85, 4.2, colour, cream, cream.darkened(0.25))
	_xbox(st, xf, Vector3(0, 4.28, 0), Vector3(0.12, 0.2, 0.12), gold)
	# Valance, alternating, and the bulb strip under the rim.
	for k in 10:
		var rot := Basis(Vector3.UP, k * TAU / 10.0)
		var chord := 2.0 * 2.49 * tan(PI / 10.0) + 0.02
		_xo(st, xf, rot * Vector3(0, 2.7, 2.49), rot, Vector3(chord, 0.28, 0.04), colour if k % 2 == 0 else cream)
	_band(st, xf, 10, 2.3, 2.5, 0.08, 0.08, Color("#ffd98a"))
	# Horses on poles, bobbing at two heights.
	var coats: Array[Color] = [Color("#f4b8c8"), Color("#a9d6f0"), Color("#f6e08a"), Color("#b9e0b0"), Color("#d6b8ec"), Color("#f7c79a"), Color("#c8e8e0"), Color("#f2f0e6")]
	for i in 8:
		var a := i * TAU / 8.0
		var rot := Basis(Vector3.UP, a)
		var base := _dir(a) * 1.8
		var h := 0.95 + float(i % 2) * 0.3
		var coat := coats[i]
		_xo(st, xf, base + Vector3(0, 1.5, 0), rot, Vector3(0.05, 2.5, 0.05), gold)
		_xo(st, xf, base + rot * Vector3(0, h, 0), rot, Vector3(0.78, 0.34, 0.22), coat)
		_xo(st, xf, base + rot * Vector3(0.36, h + 0.26, 0), rot, Vector3(0.2, 0.5, 0.17), coat)
		_xo(st, xf, base + rot * Vector3(0.5, h + 0.5, 0), rot, Vector3(0.34, 0.16, 0.14), coat.darkened(0.08))


# --- the playground -------------------------------------------------------------------

## A 6.5 x 5.5 m rubber-floor patch with a two-seat swing frame, a slide on a 1.6 m deck in
## `colour`, a timber-edged sandbox and a spring-rider animal. ~430 tris.
static func add_playground(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var steel := Color("#7d8791")
	var timber := Color("#8a5a34")
	_xbox(st, xf, Vector3(0, 0.02, 0), Vector3(6.5, 0.04, 5.5), Color("#a5533f"))
	# Swing frame along x at z = 1.8: four posts in two splayed-free pairs, a top bar, two swings.
	for x: float in [-3.0, -0.8]:
		for z: float in [1.5, 2.1]:
			_xbox(st, xf, Vector3(x, 1.2, z), Vector3(0.1, 2.4, 0.1), steel)
	_xbox(st, xf, Vector3(-1.9, 2.4, 1.8), Vector3(2.4, 0.12, 0.12), steel)
	for x: float in [-2.45, -1.35]:
		for dx: float in [-0.2, 0.2]:
			_xbox(st, xf, Vector3(x + dx, 1.4, 1.8), Vector3(0.025, 2.0, 0.025), Color("#4a4d52"))
		_xbox(st, xf, Vector3(x, 0.4, 1.8), Vector3(0.46, 0.05, 0.2), Color("#d8a02a"))
	# The slide: deck at 1.6 m on four posts, a ladder behind, a chute running to -z.
	var sx := 2.0
	for dx: float in [-0.4, 0.4]:
		for dz: float in [-0.4, 0.4]:
			_xbox(st, xf, Vector3(sx + dx, 0.8, 1.8 + dz), Vector3(0.07, 1.6, 0.07), steel)
	_xbox(st, xf, Vector3(sx, 1.6, 1.8), Vector3(0.9, 0.06, 0.9), timber)
	_xbox(st, xf, Vector3(sx, 1.85, 2.2), Vector3(0.9, 0.45, 0.04), colour.darkened(0.15))
	for dx: float in [-0.3, 0.3]:
		Props.beam(st, xf * Vector3(sx + dx, 0.0, 2.8), xf * Vector3(sx + dx, 1.6, 2.2), 0.05, 0.05, steel)
	for y: float in [0.5, 0.95, 1.4]:
		_xbox(st, xf, Vector3(sx, y, 2.8 - y * 0.375), Vector3(0.6, 0.04, 0.05), steel)
	_xbeam(st, xf, Vector3(sx, 1.58, 1.3), Vector3(sx, 0.3, -0.7), 0.5, 0.05, colour)
	for dx: float in [-0.27, 0.27]:
		_xbeam(st, xf, Vector3(sx + dx, 1.68, 1.3), Vector3(sx + dx, 0.4, -0.7), 0.04, 0.12, colour.darkened(0.2))
	# The sandbox.
	var scx := -1.7
	var scz := -1.3
	_xbox(st, xf, Vector3(scx, 0.07, scz), Vector3(2.0, 0.06, 1.6), Color("#e3cf9a"))
	for z: float in [-0.8, 0.8]:
		_xbox(st, xf, Vector3(scx, 0.14, scz + z), Vector3(2.1, 0.2, 0.1), timber)
	for x: float in [-1.0, 1.0]:
		_xbox(st, xf, Vector3(scx + x, 0.14, scz), Vector3(0.1, 0.2, 1.5), timber)
	# The spring rider: a base plate, a spring, a body, a head and handles.
	var rx := 1.7
	var rz := -1.6
	var pink := Color("#e56f8e")
	_xbox(st, xf, Vector3(rx, 0.03, rz), Vector3(0.5, 0.05, 0.3), steel)
	_xbox(st, xf, Vector3(rx, 0.22, rz), Vector3(0.1, 0.4, 0.1), Color("#4a4d52"))
	_xbox(st, xf, Vector3(rx, 0.6, rz), Vector3(0.28, 0.32, 0.7), pink)
	_xbox(st, xf, Vector3(rx, 0.88, rz - 0.4), Vector3(0.22, 0.28, 0.24), pink.lightened(0.1))
	_xbox(st, xf, Vector3(rx, 0.82, rz - 0.55), Vector3(0.16, 0.12, 0.12), pink.darkened(0.1))
	_xbox(st, xf, Vector3(rx, 0.86, rz - 0.15), Vector3(0.5, 0.04, 0.04), steel)


# --- the gazebo -----------------------------------------------------------------------

## An open wooden park gazebo / bandstand, 4.4 m across: an 8-sided platform, eight posts to
## 2.6 m, a rail all round except at the two front steps, and a pyramid roof to 4.2 m in
## `colour` with a finial. ~360 tris.
static func add_gazebo(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var timber := Color("#a98258")
	var cream := Color("#efe4cc")
	_prism(st, xf, 8, 2.2, 0.0, 0.4, Color("#9a9288"))
	var rc := 1.95 / cos(PI / 8.0)
	for k in 8:
		var p := _dir((k + 0.5) * TAU / 8.0) * rc
		_xbox(st, xf, p + Vector3(0, 1.5, 0), Vector3(0.14, 2.2, 0.14), cream)
	# Rails on the seven sides that are not the entrance (front is the side facing -z, index 4).
	_band(st, xf, 8, 1.95, 1.0, 0.1, 0.07, timber, 4)
	_pyramid(st, xf, 8, 2.7, 2.6, 4.2, colour, colour.darkened(0.12), timber.darkened(0.3))
	_band(st, xf, 8, 2.68, 2.55, 0.14, 0.06, cream)
	_xbox(st, xf, Vector3(0, 4.3, 0), Vector3(0.14, 0.3, 0.14), Color("#d9b24a"))
	_xbox(st, xf, Vector3(0, 0.27, -2.55), Vector3(1.4, 0.14, 0.4), Color("#9a9288"))
	_xbox(st, xf, Vector3(0, 0.13, -2.8), Vector3(1.6, 0.26, 0.3), Color("#9a9288"))


# --- the sundial ----------------------------------------------------------------------

## A 1.2 m stone column on a two-step base with a bronze dial plate and gnomon. `colour` is
## the stone. ~75 tris.
static func add_sundial(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var bronze := Color("#8c6a32")
	_xbox(st, xf, Vector3(0, 0.08, 0), Vector3(1.0, 0.16, 1.0), colour.darkened(0.12))
	_xbox(st, xf, Vector3(0, 0.22, 0), Vector3(0.7, 0.12, 0.7), colour.darkened(0.05))
	_xbox(st, xf, Vector3(0, 0.78, 0), Vector3(0.32, 1.0, 0.32), colour)
	_xbox(st, xf, Vector3(0, 1.32, 0), Vector3(0.5, 0.1, 0.5), colour.lightened(0.05))
	# The dial plate tilted towards the viewer (-z), with its gnomon rising from the middle.
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-20.0))
	_xo(st, xf, Vector3(0, 1.4, 0), tilt, Vector3(0.44, 0.04, 0.44), bronze)
	_xo(st, xf, Vector3(0, 1.5, 0.05), tilt, Vector3(0.03, 0.22, 0.2), bronze.darkened(0.2))


# --- the pergola ----------------------------------------------------------------------

## A 6.4 m long (local x) by 3 m wide timber pergola: six posts to 2.6 m, side beams, cross
## beams and slats on top, a bench against the back and a few green climbers. `colour` is the
## timber. ~340 tris.
static func add_pergola(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var leaf := Color("#4f7a3a")
	for x: float in [-3.0, 0.0, 3.0]:
		for z: float in [-1.35, 1.35]:
			_xbox(st, xf, Vector3(x, 1.3, z), Vector3(0.18, 2.6, 0.18), colour)
		_xbox(st, xf, Vector3(x, 2.68, 0), Vector3(0.14, 0.14, 3.0), colour.darkened(0.08))
	for z: float in [-1.35, 1.35]:
		_xbox(st, xf, Vector3(0, 2.6, z), Vector3(6.4, 0.16, 0.14), colour.darkened(0.08))
	for i in 8:
		var x := -2.8 + i * 0.8
		_xbox(st, xf, Vector3(x, 2.79, 0), Vector3(0.08, 0.06, 3.0), colour.lightened(0.1))
	# Climbers hanging from a few slats.
	for p: Vector3 in [Vector3(-2.0, 2.6, 0.5), Vector3(-0.4, 2.65, -0.6), Vector3(1.2, 2.6, 0.3), Vector3(2.4, 2.65, -0.7), Vector3(-3.0, 2.0, 1.35)]:
		_xbox(st, xf, p, Vector3(0.5, 0.18, 0.4), leaf)
	# The bench against the back.
	_xbox(st, xf, Vector3(0, 0.45, 1.0), Vector3(1.6, 0.06, 0.45), Color("#8a5a34"))
	_xbox(st, xf, Vector3(0, 0.75, 1.24), Vector3(1.6, 0.4, 0.05), Color("#8a5a34"))
	for x: float in [-0.7, 0.7]:
		_xbox(st, xf, Vector3(x, 0.22, 1.0), Vector3(0.08, 0.44, 0.4), Color("#3a3b3f"))
