extends Node3D
## First scene (docs/design/first-scene.md items 4 and 5, 2026-11-01): the street furniture the
## map data doesn't have, on Marszałkowska's east pavement in the first frame of play (by the
## Eastern Wall's stores, from Junior to the pavilions under the towers): a newspaper kiosk, a
## flower stall, café tables under parasols, an advertising column and concrete planters.
## Built at runtime on both city paths (it isn't in the sector scenes) as one mesh in the actors'
## material (models.gd): one draw call in view, no sun shadow below a metre (the planters). The
## kiosk and the stall stop the car; the rest are drive-through like the map's benches.

const Props := preload("res://scripts/props.gd")
const Models := preload("res://scripts/models.gd")

## Marszałkowska's frame here: `s` metres north along the street from FRAME_O, `t` metres east
## of it (the east carriageway's middle is t 17, its kerb 21.6, the cycle path 26-28, the stores'
## overhang 32). Fronts face the street (west).
const FRAME_O := Vector2(-937.0, 210.1)
const FRAME_S := Vector2(-0.34917, -0.93706)
const FRAME_T := Vector2(0.93706, -0.34917)
## [kind, s, t, extra]: extra is a colour for planters, parasols and the column. Each faces the
## street's middle (t 8, the tram tracks). Only where the first frame sees them: the stores'
## own fronts hide behind their 17 m boxes from the game's camera, so the first frame's furniture
## stands on the west pavement in front of the museum (between the tree row at t -14 and the
## museum's edge at t -21.7), and more on the way to Świętokrzyska: in front of the low pavilions
## north of Junior and on the paving north of the museum (clear of the map's lamps and trees).
const ITEMS := [
	# west, in front of the museum (the first frame)
	["planter", 88.5, -20.4, "#e63946"],
	["cafe", 97.5, -20.2, "#2f6b4f"], ["cafe", 104.5, -20.2, "#f4f1de"], ["cafe", 111.5, -20.2, "#2f6b4f"],
	["planter", 127.0, -20.4, "#ffd23f"],
	["kiosk", 140.0, -19.9, ""],
	["stall", 149.5, -20.0, ""],
	["column", 158.0, -19.9, "#e07a5f"],
	["planter", 168.0, -20.4, "#9b5de5"],
	# east, in front of the pavilions under the towers
	["planter", 182.0, 33.6, "#e63946"],
	["cafe", 188.0, 34.2, "#24324a"], ["cafe", 194.5, 34.2, "#c8282a"], ["cafe", 201.0, 34.2, "#24324a"],
	["planter", 208.0, 33.6, "#ffd23f"],
	["column", 215.0, 33.4, "#e8d36a"],
	["planter", 233.0, 33.6, "#9b5de5"],
	# west, the paving north of the museum
	["planter", 188.0, -19.6, "#f4a261"],
	["kiosk", 196.5, -24.0, ""],
	["stall", 208.5, -24.6, ""],
	["column", 199.0, -30.5, "#9db4d8"],
	["planter", 221.0, -19.6, "#e8a6b8"],
	["cafe", 192.0, -31.0, "#2f6b4f"], ["cafe", 186.0, -27.0, "#e07a5f"],
]
## The middle of the street (the tram tracks), which every item faces.
const STREET_T := 8.0
## The kiosk's and the stall's footprints for the car (half sizes).
const SOLID := {"kiosk": Vector2(1.45, 1.1), "stall": Vector2(1.2, 0.9)}

var map: Node3D
var count := 0


## Builds the mesh and the colliders; `map` gives the ground (map_builder.ground_height).
func build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "FirstSceneSolids"
	for item: Array in ITEMS:
		var p := FRAME_O + FRAME_S * float(item[1]) + FRAME_T * float(item[2])
		# +z of a prop points away from the street, so its -z front faces it.
		var face := FRAME_T * signf(float(item[2]) - STREET_T)
		var yaw := atan2(face.x, face.y)
		var y: float = map.ground_height(p.x, p.y)
		var xf := Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, y, p.y))
		var kind: String = item[0]
		match kind:
			"kiosk":
				Props.add_kiosk(st, xf)
			"stall":
				Props.add_flower_stall(st, xf)
			"cafe":
				Props.add_cafe_set(st, xf, Color(item[3]))
			"planter":
				Props.add_planter(st, xf, Color(item[3]))
			"column":
				Props.add_ad_column(st, xf, Color(item[3]))
		if SOLID.has(kind):
			var half: Vector2 = SOLID[kind]
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(half.x * 2.0, 2.4, half.y * 2.0)
			shape.shape = box
			shape.transform = Transform3D(xf.basis, xf.origin + Vector3.UP * 1.2)
			body.add_child(shape)
		count += 1
	var mi := MeshInstance3D.new()
	mi.name = "FirstSceneProps"
	mi.mesh = st.commit()
	mi.material_override = Models.material()
	add_child(mi)
	add_child(body)
