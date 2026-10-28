extends RefCounted
## Box-built models for everything that moves: traffic cars, taxis, vans, the city
## bus, tram cars, pedestrians and the rivals' cars. Fronts face -Z, like the
## player's car. Vertex UV.x picks how actor.gdshader colours a part: PAINT takes
## the instance paint, FIXED keeps the vertex colour, TROUSERS uses the palette;
## HEAD_LAMP, TAIL_LAMP, LIT_WINDOW and LIT_SIGN keep their colour and glow when the
## city's lights are on; BLINK (loop 1: the roadwork lamps) glows and blinks; HERO (the look
## loop: the player's car, car.gd) keeps its colour and lights from within at night by UV.y.
## headlight_pools() is the light the lamps throw on the road.

const PAINT := 0.0
const FIXED := 1.0
const TROUSERS := 2.0
const HEAD_LAMP := 3.0
const TAIL_LAMP := 4.0
const LIT_WINDOW := 5.0
const LIT_SIGN := 6.0
const BLINK := 7.0
const HERO := 8.0

const GLASS := Color("#34404e")
const TYRE := Color("#1c1c1e")
const HEADLIGHT := Color("#fff3c4")
const TAIL := Color("#b3241f")
const TRIM := Color("#3a3b3f")

static var _material: ShaderMaterial
static var _glow_material: ShaderMaterial


## The one material every model uses (cheap to batch, one shader to compile).
static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://shaders/actor.gdshader")
	return _material


## An axis-aligned box with outward faces. `leg` marks pedestrian legs (+1 / -1).
static func box(st: SurfaceTool, centre: Vector3, size: Vector3, colour: Color, part := FIXED, leg := 0.0) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := centre + n * h[axis]
			var q := [c - u - v, c + u - v, c + u + v, c - u + v]
			# Godot's front faces are clockwise: (b - a) x (c - a) points away from the viewer.
			if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
				q = [q[0], q[3], q[2], q[1]]
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(colour)
				st.set_normal(n)
				st.set_uv(Vector2(part, leg))
				st.add_vertex(q[k])


static func _begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func _wheels(st: SurfaceTool, half_track: float, axles: Array, radius := 0.32) -> void:
	for x in [-half_track, half_track]:
		for z in axles:
			box(st, Vector3(x, radius, z), Vector3(0.3, radius * 2.0, radius * 2.1), TYRE)


static func _lamps(st: SurfaceTool, half_length: float, y: float, spread := 0.58) -> void:
	for x in [-spread, spread]:
		box(st, Vector3(x, y, -half_length - 0.02), Vector3(0.34, 0.15, 0.06), HEADLIGHT, HEAD_LAMP)
		box(st, Vector3(x, y + 0.02, half_length + 0.02), Vector3(0.34, 0.14, 0.06), TAIL, TAIL_LAMP)


## The additive material for light on the road (glow.gdshader), shared by every
## vehicle; shown only at night (the game hides the nodes by day).
static func glow_material() -> ShaderMaterial:
	if _glow_material == null:
		_glow_material = ShaderMaterial.new()
		_glow_material.shader = load("res://shaders/glow.gdshader")
		_glow_material.render_priority = 1
	return _glow_material


## Headlight light on the road ahead of a vehicle whose front is `half_length`
## ahead of its origin (fronts face -Z): one soft fan the width of the car that
## widens and fades over `reach` metres, brightest a few metres ahead and dark at
## its edges; and a faint red glow behind. A grid of vertices carries the falloff
## in their colour's alpha (`peak` at its brightest; the look loop gives the player's car a
## stronger one). Flat, a little above the road; the shader lifts it over the road layers.
static func headlight_pools(half_length: float, spread := 0.6, reach := 13.0, tail := true, peak := 0.42) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var warm := Color(1.0, 0.84, 0.58)
	var y := 0.15
	var rings := 7
	var cols := 8
	var grid := []
	for i in rings + 1:
		var t := float(i) / rings
		var row := []
		var half_w := spread + 0.35 + t * reach * 0.3
		for j in cols + 1:
			var u := float(j) / cols * 2.0 - 1.0
			var p := Vector3(u * half_w, y, -half_length - 0.2 - t * reach)
			var along := smoothstep(0.0, 0.18, t) * pow(1.0 - t, 1.6)
			var across := 1.0 - u * u
			row.append([p, peak * along * across * across])
		grid.append(row)
	for i in rings:
		for j in cols:
			var a: Array = grid[i][j]
			var b: Array = grid[i][j + 1]
			var c: Array = grid[i + 1][j + 1]
			var d: Array = grid[i + 1][j]
			for v in [a, b, c, a, c, d]:
				_glow_vertex(st, v[0], Color(warm, v[1]))
	if tail:
		var red := Color(1.0, 0.08, 0.05)
		var centre := Vector3(0.0, y, half_length + 0.9)
		var n := 12
		for k in n:
			var a0 := TAU * k / n
			var a1 := TAU * (k + 1) / n
			_glow_vertex(st, centre, Color(red, 0.16))
			_glow_vertex(st, centre + Vector3(cos(a0) * 1.6, 0.0, sin(a0) * 1.3), Color(red, 0.0))
			_glow_vertex(st, centre + Vector3(cos(a1) * 1.6, 0.0, sin(a1) * 1.3), Color(red, 0.0))
	return st.commit()


static func _glow_vertex(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	st.set_normal(Vector3.UP)
	st.add_vertex(p)


## A small hatchback / saloon; the paint comes from the instance.
static func car_mesh(taxi := false) -> ArrayMesh:
	var st := _begin()
	box(st, Vector3(0, 0.62, 0), Vector3(1.78, 0.6, 4.2), Color.WHITE, PAINT)
	box(st, Vector3(0, 1.16, 0.15), Vector3(1.56, 0.5, 2.05), GLASS)
	box(st, Vector3(0, 1.44, 0.2), Vector3(1.6, 0.08, 1.85), Color.WHITE, PAINT)
	box(st, Vector3(0, 0.36, 0), Vector3(1.82, 0.16, 4.26), TRIM)
	_wheels(st, 0.84, [-1.3, 1.3])
	_lamps(st, 2.1, 0.74)
	if taxi:
		# Warsaw taxis: a lit roof sign and a band of chequers along the doors.
		box(st, Vector3(0, 1.6, 0.25), Vector3(0.75, 0.24, 0.32), Color("#f3c72b"), LIT_SIGN)
		for k in 6:
			var z := -0.9 + k * 0.36
			for x in [-0.9, 0.9]:
				box(st, Vector3(x, 0.78, z), Vector3(0.03, 0.14, 0.18), Color("#f3c72b") if k % 2 == 0 else Color("#1f1f22"))
	return st.commit()


## A delivery van: a tall load box behind a short cab.
static func van_mesh() -> ArrayMesh:
	var st := _begin()
	box(st, Vector3(0, 1.45, 0.75), Vector3(1.96, 2.1, 3.7), Color.WHITE, PAINT)
	box(st, Vector3(0, 0.9, -1.85), Vector3(1.9, 1.0, 1.5), Color.WHITE, PAINT)
	box(st, Vector3(0, 1.72, -1.55), Vector3(1.84, 0.66, 0.92), GLASS)
	box(st, Vector3(0, 0.36, 0), Vector3(1.98, 0.16, 5.2), TRIM)
	_wheels(st, 0.88, [-1.75, 1.8], 0.34)
	_lamps(st, 2.6, 0.82, 0.66)
	return st.commit()


## Warsaw city bus: red below, yellow above, a long dark window band.
static func bus_mesh() -> ArrayMesh:
	var st := _begin()
	var red := Color("#c8282a")
	var yellow := Color("#f2c12e")
	box(st, Vector3(0, 0.95, 0), Vector3(2.5, 1.2, 12.0), red)
	box(st, Vector3(0, 2.25, 0), Vector3(2.5, 1.4, 12.0), yellow)
	box(st, Vector3(0, 2.15, 0.3), Vector3(2.54, 0.85, 10.6), GLASS, LIT_WINDOW)
	box(st, Vector3(0, 2.0, -5.98), Vector3(2.3, 1.3, 0.1), GLASS)
	box(st, Vector3(0, 3.0, 2.5), Vector3(1.6, 0.25, 3.0), Color("#d9d4c8"))
	_wheels(st, 1.12, [-3.9, 3.4], 0.48)
	_lamps(st, 6.0, 0.8, 0.85)
	return st.commit()


## A tram car about 10.5 m long; `cab` adds a driver's cab and windscreen at -Z.
## Warsaw colours: yellow body over a red skirt, dark window band, grey roof. The
## rear car (`rear`, turned round by the trams) shows red tail lamps at its cab.
static func tram_mesh(cab: bool, rear := false) -> ArrayMesh:
	var st := _begin()
	var yellow := Color("#f4c430")
	var red := Color("#c42f2a")
	var length := 10.5
	box(st, Vector3(0, 0.7, 0), Vector3(2.4, 0.8, length), red)
	box(st, Vector3(0, 2.15, 0), Vector3(2.4, 2.1, length), yellow)
	box(st, Vector3(0, 2.1, 0.2 if cab else 0.0), Vector3(2.44, 1.0, length - (1.6 if cab else 0.8)), GLASS, LIT_WINDOW)
	box(st, Vector3(0, 3.28, 0), Vector3(2.0, 0.16, length - 0.6), Color("#a4a19b"))
	for z in [-3.2, 3.2]:
		box(st, Vector3(0, 0.22, z), Vector3(2.0, 0.36, 1.8), TYRE)
	if cab:
		box(st, Vector3(0, 2.15, -length * 0.5 - 0.12), Vector3(2.1, 1.25, 0.24), GLASS)
		box(st, Vector3(0, 0.85, -length * 0.5 - 0.1), Vector3(2.2, 0.9, 0.24), red)
		for x in [-0.75, 0.75]:
			if rear:
				box(st, Vector3(x, 1.0, -length * 0.5 - 0.24), Vector3(0.3, 0.14, 0.06), TAIL, TAIL_LAMP)
			else:
				box(st, Vector3(x, 1.0, -length * 0.5 - 0.24), Vector3(0.3, 0.14, 0.06), HEADLIGHT, HEAD_LAMP)
	else:
		# Pantograph on the middle car.
		box(st, Vector3(0, 3.5, 0), Vector3(1.4, 0.08, 0.5), Color("#2b2c2f"))
		box(st, Vector3(0, 3.75, 0), Vector3(0.1, 0.5, 0.1), Color("#2b2c2f"))
		box(st, Vector3(0, 4.0, 0), Vector3(1.2, 0.06, 0.12), Color("#2b2c2f"))
	return st.commit()


## A pedestrian 1.75 m tall: trousers (palette), shirt (instance paint), skin, hair.
static func person_mesh() -> ArrayMesh:
	var st := _begin()
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.11 * side, 0.43, 0), Vector3(0.17, 0.86, 0.22), Color.WHITE, TROUSERS, side)
	box(st, Vector3(0, 1.15, 0), Vector3(0.46, 0.62, 0.28), Color.WHITE, PAINT)
	for side in [-1.0, 1.0]:
		box(st, Vector3(0.29 * side, 1.12, 0), Vector3(0.12, 0.56, 0.16), Color.WHITE, PAINT)
	box(st, Vector3(0, 1.58, 0), Vector3(0.26, 0.26, 0.26), Color("#e2b48c"))
	box(st, Vector3(0, 1.72, 0.02), Vector3(0.28, 0.08, 0.3), Color("#4a3426"))
	return st.commit()


## The rivals' cars, one look each (style 0..5), all colours fixed.
static func rival_mesh(style: int) -> ArrayMesh:
	var st := _begin()
	match style:
		0:  # Seba z Pragi: lowered purple coupe, a big wing, pink stripes
			var purple := Color("#7b2fbf")
			box(st, Vector3(0, 0.48, 0), Vector3(1.86, 0.46, 4.4), purple)
			box(st, Vector3(0, 0.9, 0.35), Vector3(1.5, 0.4, 1.7), GLASS)
			box(st, Vector3(0, 1.12, 0.4), Vector3(1.54, 0.07, 1.5), purple)
			for x in [-0.25, 0.25]:
				box(st, Vector3(x, 0.72, -1.1), Vector3(0.16, 0.02, 2.0), Color("#ff4fd8"))
			for x in [-0.7, 0.7]:
				box(st, Vector3(x, 0.92, 2.0), Vector3(0.08, 0.36, 0.1), TYRE)
			box(st, Vector3(0, 1.12, 2.05), Vector3(1.96, 0.07, 0.5), TYRE)
			_wheels(st, 0.86, [-1.35, 1.35], 0.3)
			_lamps(st, 2.2, 0.55)
		1:  # Mordor Mike: grey company estate, dark glass, roof box
			var grey := Color("#6d7480")
			box(st, Vector3(0, 0.62, 0), Vector3(1.84, 0.62, 4.7), grey)
			box(st, Vector3(0, 1.17, 0.4), Vector3(1.6, 0.5, 2.8), Color("#1e2530"))
			box(st, Vector3(0, 1.46, 0.45), Vector3(1.64, 0.08, 2.65), grey)
			box(st, Vector3(0, 1.68, 0.55), Vector3(0.95, 0.36, 1.9), Color("#202124"))
			_wheels(st, 0.86, [-1.5, 1.5])
			_lamps(st, 2.35, 0.75)
		2:  # Pani Halina: tiny mint two-tone hatch with a basket on the roof
			var mint := Color("#86d3b0")
			box(st, Vector3(0, 0.62, 0), Vector3(1.6, 0.66, 3.4), mint)
			box(st, Vector3(0, 1.2, 0.2), Vector3(1.42, 0.52, 1.7), GLASS)
			box(st, Vector3(0, 1.5, 0.2), Vector3(1.46, 0.08, 1.6), Color("#f4ead2"))
			box(st, Vector3(0, 1.62, 0.2), Vector3(0.8, 0.22, 0.6), Color("#c8a26a"))
			box(st, Vector3(0.18, 1.78, 0.2), Vector3(0.22, 0.14, 0.22), Color("#e04f5f"))
			_wheels(st, 0.76, [-1.05, 1.05], 0.28)
			_lamps(st, 1.7, 0.74, 0.5)
		3:  # Słoik z Radomia: white van, rear spoiler, mum's jars on the roof rack
			var white := Color("#f2f2ee")
			box(st, Vector3(0, 1.45, 0.75), Vector3(1.96, 2.1, 3.7), white)
			box(st, Vector3(0, 0.9, -1.85), Vector3(1.9, 1.0, 1.5), white)
			box(st, Vector3(0, 1.72, -1.55), Vector3(1.84, 0.66, 0.92), GLASS)
			box(st, Vector3(0, 0.95, 0.75), Vector3(1.98, 0.18, 3.6), Color("#d93a3a"))
			box(st, Vector3(0, 2.62, 2.45), Vector3(2.0, 0.08, 0.5), TYRE)
			box(st, Vector3(0, 2.55, 0.4), Vector3(1.6, 0.06, 2.4), TRIM)
			for k in 4:
				box(st, Vector3(-0.55 + k * 0.37, 2.75, 0.2 + (k % 2) * 0.5), Vector3(0.24, 0.32, 0.24), Color("#d9a441"))
				box(st, Vector3(-0.55 + k * 0.37, 2.94, 0.2 + (k % 2) * 0.5), Vector3(0.26, 0.06, 0.26), Color("#f0f0ea"))
			_wheels(st, 0.88, [-1.75, 1.8], 0.34)
			_lamps(st, 2.6, 0.82, 0.66)
		4:  # Taksiarz Zbyszek: long black saloon, yellow sign and chequer band
			var black := Color("#232428")
			box(st, Vector3(0, 0.62, 0), Vector3(1.86, 0.6, 4.8), black)
			box(st, Vector3(0, 1.16, 0.1), Vector3(1.6, 0.5, 2.3), GLASS)
			box(st, Vector3(0, 1.44, 0.15), Vector3(1.64, 0.08, 2.1), black)
			box(st, Vector3(0, 1.62, 0.2), Vector3(0.8, 0.28, 0.34), Color("#f3c72b"), LIT_SIGN)
			for k in 8:
				for x in [-0.94, 0.94]:
					box(st, Vector3(x, 0.78, -1.25 + k * 0.36), Vector3(0.03, 0.15, 0.18), Color("#f3c72b") if k % 2 == 0 else Color("#e8e4d8"))
			_wheels(st, 0.86, [-1.5, 1.55])
			_lamps(st, 2.4, 0.74)
		_:  # Bulwar Bartek: neon-green hatch, magenta wing, a speaker on the roof
			var green := Color("#7cff3a")
			box(st, Vector3(0, 0.6, 0), Vector3(1.76, 0.62, 3.9), green)
			box(st, Vector3(0, 1.13, 0.2), Vector3(1.54, 0.48, 1.9), GLASS)
			box(st, Vector3(0, 1.4, 0.25), Vector3(1.58, 0.08, 1.75), green)
			box(st, Vector3(0, 1.62, 0.3), Vector3(0.7, 0.36, 0.5), TYRE)
			box(st, Vector3(0, 1.62, 0.05), Vector3(0.42, 0.24, 0.02), Color("#ff4fd8"))
			box(st, Vector3(0, 1.48, 1.85), Vector3(1.7, 0.06, 0.36), Color("#ff4fd8"))
			_wheels(st, 0.82, [-1.25, 1.25])
			_lamps(st, 1.95, 0.72)
	return st.commit()
