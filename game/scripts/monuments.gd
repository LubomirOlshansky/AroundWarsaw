extends RefCounted
## Monuments and plaques from OpenStreetMap (docs/CITY_INVENTORY.md Part 3 item 6, rows 142 and
## 144): a generic piece for each of the city's named statues, busts, memorial stones, steles,
## obelisks, crosses, sculptures and talking benches (ławeczki), Ogród Saski's sandstone
## allegories at their real spots, and a sandstone memorial plaque with candles on the wall for
## each of the Uprising plaques (Tchorek's cross-in-a-frame tablets) and the other memorial
## plaques. From game/data/monuments.json (tools/bake_monuments.py): `items` = [kind, x, z, yaw,
## colour, name]. park_details.gd builds them into its per-cell meshes (one draw call a cell in
## view, shared with the park pieces); the free-standing pieces stop the car with one box each.
## The famous monuments are hand-built sites in landmarks.gd and are skipped by the bake. Fronts
## face -Z (the street); a plaque's +Z goes into its wall.

const Props := preload("res://scripts/props.gd")
const Life := preload("res://scripts/park_props_life.gd")
const Models := preload("res://scripts/models.gd")

const FILE := "res://data/monuments.json"
const KINDS := ["statue", "bust", "allegory", "stone", "stele", "obelisk", "cross", "sculpture", "bench", "plaque"]
## Footprint halves (x, z) of the contact pad under a tall piece (the mesh casts no sun shadow).
const PAD := {"statue": Vector2(1.3, 1.3), "obelisk": Vector2(1.0, 1.0), "cross": Vector2(0.8, 0.8),
		"allegory": Vector2(0.6, 0.6), "sculpture": Vector2(0.8, 0.8)}
## Half sizes (x, z) of the car's box for the solid pieces.
const SOLID := {"statue": Vector2(1.2, 1.2), "bust": Vector2(0.4, 0.4), "allegory": Vector2(0.5, 0.5),
		"stone": Vector2(0.6, 0.4), "stele": Vector2(0.55, 0.25), "obelisk": Vector2(0.9, 0.9),
		"cross": Vector2(0.6, 0.6), "sculpture": Vector2(0.7, 0.7)}
## Total limit; check_monuments.gd holds the file to it (tools/bake_monuments.py MAX_ITEMS).
const MAX_ITEMS := 1200

const GRANITE := Color("#8f8b85")
const DARK_GRANITE := Color("#4f4e4c")
const BRONZE_PLATE := Color("#5a4630")
const CANDLE := Color("#b3241f")
const FLAME := Color("#ffb04a")
const RIBBON_WHITE := Color("#f2f0ea")
const RIBBON_RED := Color("#c8282a")


## The baked items, [] when the file is missing.
static func load_items() -> Array:
	if not FileAccess.file_exists(FILE):
		return []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if parsed is Dictionary and (parsed as Dictionary).has("items"):
		return (parsed as Dictionary)["items"]
	return []


static func known(kind: String) -> bool:
	return KINDS.has(kind)


static func _xbox(st: SurfaceTool, xf: Transform3D, centre: Vector3, size: Vector3, colour: Color, part := Models.FIXED) -> void:
	Props.obox(st, xf * centre, xf.basis.orthonormalized(), size, colour, part)


## Adds one item's pieces to `st` at `xf` (a pad first for the tall kinds).
static func add_item(st: SurfaceTool, kind: String, xf: Transform3D, colour: String) -> void:
	if PAD.has(kind):
		Props.add_contact_pad(st, xf, PAD[kind])
	var c := Color(colour)
	match kind:
		"statue": add_statue(st, xf, c)
		"bust": add_bust(st, xf, c)
		"allegory": Life.add_statue(st, xf, c)
		"stone": Props.add_memorial_stone(st, xf)
		"stele": add_stele(st, xf, c)
		"obelisk": add_obelisk(st, xf, c)
		"cross": add_cross(st, xf, c)
		"sculpture": add_sculpture(st, xf, c)
		"bench": add_bench(st, xf, c)
		"plaque": add_plaque(st, xf, c)


## Two red grave candles and a little flame each (the flames glow at night). `at` is the middle.
static func _candles(st: SurfaceTool, xf: Transform3D, at: Vector3) -> void:
	for dx: float in [-0.12, 0.1]:
		_xbox(st, xf, at + Vector3(dx, 0.07, 0.0), Vector3(0.08, 0.14, 0.08), CANDLE)
		_xbox(st, xf, at + Vector3(dx, 0.16, 0.0), Vector3(0.025, 0.04, 0.025), FLAME, Models.LIT_SIGN)


## A bronze figure on a granite pedestal, about 5.5 m: two steps, the pedestal with a bronze
## inscription plate on its front, a cornice, then a standing man in a long coat, one arm a little
## forward. `colour` is the figure (bronze, or sandstone for a stone statue). ~200 triangles.
static func add_statue(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var dark := colour.darkened(0.18)
	var light := colour.lightened(0.12)
	_xbox(st, xf, Vector3(0, 0.12, 0), Vector3(2.6, 0.24, 2.6), GRANITE.darkened(0.08))
	_xbox(st, xf, Vector3(0, 0.36, 0), Vector3(2.2, 0.24, 2.2), GRANITE)
	_xbox(st, xf, Vector3(0, 1.48, 0), Vector3(1.5, 2.0, 1.5), GRANITE.lightened(0.05))
	_xbox(st, xf, Vector3(0, 1.6, -0.76), Vector3(0.9, 0.5, 0.03), BRONZE_PLATE)
	_xbox(st, xf, Vector3(0, 2.6, 0), Vector3(1.75, 0.24, 1.75), GRANITE)
	_xbox(st, xf, Vector3(0, 2.76, 0), Vector3(1.2, 0.08, 1.0), dark)
	# the figure, 2.6 m: legs, the coat's skirt, the body, shoulders, head, one arm forward
	_xbox(st, xf, Vector3(-0.15, 3.25, 0), Vector3(0.22, 0.9, 0.28), dark)
	_xbox(st, xf, Vector3(0.15, 3.25, -0.05), Vector3(0.22, 0.9, 0.28), dark)
	_xbox(st, xf, Vector3(0, 3.75, 0.02), Vector3(0.72, 0.7, 0.5), colour)
	_xbox(st, xf, Vector3(0, 4.35, 0), Vector3(0.62, 0.65, 0.4), colour)
	_xbox(st, xf, Vector3(0, 4.68, 0), Vector3(0.78, 0.16, 0.42), light)
	_xbox(st, xf, Vector3(0, 4.92, 0), Vector3(0.24, 0.3, 0.26), light)
	_xbox(st, xf, Vector3(-0.42, 4.25, 0), Vector3(0.16, 0.75, 0.18), colour)
	_xbox(st, xf, Vector3(0.38, 4.45, -0.28), Vector3(0.16, 0.16, 0.6), colour)


## A bronze bust on a 1.5 m stone pillar with a plate. ~84 triangles.
static func add_bust(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.05, 0), Vector3(0.8, 0.1, 0.8), GRANITE.darkened(0.06))
	_xbox(st, xf, Vector3(0, 0.8, 0), Vector3(0.55, 1.4, 0.55), GRANITE.lightened(0.06))
	_xbox(st, xf, Vector3(0, 0.95, -0.28), Vector3(0.36, 0.22, 0.02), BRONZE_PLATE)
	_xbox(st, xf, Vector3(0, 1.62, 0), Vector3(0.62, 0.1, 0.62), GRANITE)
	_xbox(st, xf, Vector3(0, 1.82, 0), Vector3(0.52, 0.3, 0.3), colour)
	_xbox(st, xf, Vector3(0, 2.04, 0), Vector3(0.16, 0.12, 0.16), colour.darkened(0.1))
	_xbox(st, xf, Vector3(0, 2.2, 0), Vector3(0.24, 0.28, 0.26), colour.lightened(0.1))


## An upright granite slab on a low base with a bronze plate and two candles. ~108 triangles.
static func add_stele(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.08, 0), Vector3(1.2, 0.16, 0.6), colour.darkened(0.1))
	_xbox(st, xf, Vector3(0, 1.0, 0.04), Vector3(0.9, 1.7, 0.24), colour)
	_xbox(st, xf, Vector3(0, 1.88, 0.04), Vector3(0.96, 0.08, 0.3), colour.lightened(0.08))
	_xbox(st, xf, Vector3(0, 1.15, -0.09), Vector3(0.6, 0.55, 0.02), BRONZE_PLATE)
	_candles(st, xf, Vector3(0, 0.16, -0.18))


## A stepped granite obelisk, about 6 m. ~72 triangles.
static func add_obelisk(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.15, 0), Vector3(1.9, 0.3, 1.9), colour.darkened(0.1))
	_xbox(st, xf, Vector3(0, 0.75, 0), Vector3(1.2, 0.9, 1.2), colour)
	_xbox(st, xf, Vector3(0, 0.85, -0.61), Vector3(0.6, 0.4, 0.02), BRONZE_PLATE)
	_xbox(st, xf, Vector3(0, 2.8, 0), Vector3(0.7, 3.2, 0.7), colour.lightened(0.05))
	_xbox(st, xf, Vector3(0, 4.9, 0), Vector3(0.5, 1.0, 0.5), colour.lightened(0.05))
	_xbox(st, xf, Vector3(0, 5.55, 0), Vector3(0.28, 0.3, 0.28), colour.lightened(0.1))


## A memorial cross on two steps, 4 m, with a white-and-red ribbon. ~84 triangles.
static func add_cross(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.12, 0), Vector3(1.6, 0.24, 1.6), GRANITE)
	_xbox(st, xf, Vector3(0, 0.34, 0), Vector3(1.0, 0.2, 1.0), GRANITE.lightened(0.05))
	_xbox(st, xf, Vector3(0, 2.2, 0), Vector3(0.26, 3.6, 0.26), colour)
	_xbox(st, xf, Vector3(0, 3.1, 0), Vector3(1.5, 0.24, 0.26), colour)
	_xbox(st, xf, Vector3(0, 2.6, -0.14), Vector3(0.28, 0.08, 0.02), RIBBON_WHITE)
	_xbox(st, xf, Vector3(0, 2.52, -0.14), Vector3(0.28, 0.08, 0.02), RIBBON_RED)
	_candles(st, xf, Vector3(0, 0.44, -0.3))


## A modern sculpture: three turned slabs leaning on each other on a low plinth. ~72 triangles.
static func add_sculpture(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	_xbox(st, xf, Vector3(0, 0.1, 0), Vector3(1.4, 0.2, 1.4), GRANITE)
	for k in 3:
		var turn := Basis(Vector3.UP, k * TAU / 3.0) * Basis(Vector3.RIGHT, 0.22)
		var part := Transform3D(xf.basis * turn, xf * Vector3(0, 0.2, 0))
		_xbox(st, part, Vector3(0, 1.1, 0.28), Vector3(0.5, 2.2 - 0.35 * k, 0.12), colour.lightened(0.06 * k))


## A talking bench (ławeczka): a bronze bench and a bronze man sitting on its left end. ~84 triangles.
static func add_bench(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var light := colour.lightened(0.12)
	for x: float in [-0.75, 0.75]:
		_xbox(st, xf, Vector3(x, 0.22, 0), Vector3(0.08, 0.44, 0.5), colour.darkened(0.2))
	_xbox(st, xf, Vector3(0, 0.46, 0), Vector3(1.8, 0.06, 0.5), colour)
	_xbox(st, xf, Vector3(0, 0.75, 0.24), Vector3(1.8, 0.4, 0.05), colour)
	_xbox(st, xf, Vector3(-0.45, 0.58, -0.18), Vector3(0.36, 0.16, 0.44), colour)
	_xbox(st, xf, Vector3(-0.45, 0.26, -0.4), Vector3(0.32, 0.5, 0.14), colour.darkened(0.12))
	_xbox(st, xf, Vector3(-0.45, 0.92, 0.04), Vector3(0.46, 0.56, 0.28), colour)
	_xbox(st, xf, Vector3(-0.45, 1.36, 0.04), Vector3(0.24, 0.26, 0.24), light)


## A memorial plaque on a wall (Tchorek's Uprising tablet): a 0.62 x 0.95 m sandstone frame on the
## wall 1.3-2.25 m up, a cross relief in it, a small metal holder for flowers with a white-and-red
## ribbon, and two candles on the pavement below. Origin at the wall face, +Z into the wall.
## ~120 triangles.
static func add_plaque(st: SurfaceTool, xf: Transform3D, colour: Color) -> void:
	var relief := colour.darkened(0.16)
	_xbox(st, xf, Vector3(0, 1.78, 0.02), Vector3(0.62, 0.95, 0.06), colour)
	_xbox(st, xf, Vector3(0, 1.98, -0.02), Vector3(0.09, 0.42, 0.03), relief)
	_xbox(st, xf, Vector3(0, 2.08, -0.02), Vector3(0.3, 0.08, 0.03), relief)
	_xbox(st, xf, Vector3(0, 1.52, -0.02), Vector3(0.44, 0.2, 0.02), relief.lightened(0.05))
	_xbox(st, xf, Vector3(0, 1.22, -0.04), Vector3(0.3, 0.05, 0.1), DARK_GRANITE)
	_xbox(st, xf, Vector3(0.05, 1.3, -0.08), Vector3(0.05, 0.12, 0.02), RIBBON_WHITE)
	_xbox(st, xf, Vector3(-0.03, 1.3, -0.08), Vector3(0.05, 0.12, 0.02), RIBBON_RED)
	_candles(st, xf, Vector3(0, 0.0, -0.18))
