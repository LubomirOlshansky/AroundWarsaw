extends Node3D
## The 3D corner screen on Skylight at Złote Tarasy (F, 2026-11-05, from his photos): the big curved
## LED screen wrapped round the tower's south-east corner above the glass entrance, on the crossing
## of Emilii Plater and Złota, with anamorphic content that floats out of its frame (glowing
## flowers, a cat leaning out, a title). Ours is an original loop under a parody title (SCENA
## WARSZAWA); no real brand is on it.
## A strip of mesh along Skylight's mapped wall (the same outline landmarks.gd builds), standing
## 1.6 m off it and starting above the entrance canopy (the mapped plate tops out at 27 m):
## one mesh, one material, one draw call. All the looks are in shaders/led_screen.gdshader, which
## follows a ray into a little box so the walls and layers parallax with the viewer. Built at
## runtime on both city paths (it isn't in the sector scenes), like skwer_zlota.gd.

const Pixel := preload("res://scripts/pixel_font.gd")

## Skylight's wall from its south face round the curved corner to the Emilii Plater face, walked
## west to east so the screen's right is the viewer's right (world x east, z south).
const WALL := [Vector2(-1389.0, 440.0), Vector2(-1381.0, 439.0), Vector2(-1373.0, 437.0),
		Vector2(-1368.0, 433.0), Vector2(-1360.0, 429.0), Vector2(-1355.0, 424.0), Vector2(-1358.4, 413.1)]
const OFFSET := 1.6         # off the wall (the cabinets are a metre deep, and clear the corner's fins)
const BOTTOM := 27.4        # metres above the ground at the corner: over the 27 m plate
const HEIGHT := 17.0        # the box's height
const MARGIN := 2.6         # the mesh below the box, for what hangs out of it
const SHADER := "res://shaders/led_screen.gdshader"
const TITLE := ["SCENA", "WARSZAWA"]

var map: Node3D
var length := 0.0
var mesh_instance: MeshInstance3D


## The wall's total length, and the outward offset polyline the strip follows.
static func outline() -> Array:
	var pts: Array = []
	var norms: Array = []
	for i in WALL.size():
		var a: Vector2 = WALL[maxi(i - 1, 0)]
		var b: Vector2 = WALL[mini(i + 1, WALL.size() - 1)]
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		norms.append(n)
		pts.append(WALL[i] + n * OFFSET)
	return [pts, norms]


func build() -> void:
	var o := outline()
	var pts: Array = o[0]
	var norms: Array = o[1]
	var ground: float = map.ground_height(WALL[4].x, WALL[4].y) if map != null else 0.0
	var y0 := ground + BOTTOM - MARGIN
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s := 0.0
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var s1 := s + p0.distance_to(p1)
		var n0: Vector2 = norms[i]
		var n1: Vector2 = norms[i + 1]
		var v := [
			[Vector3(p0.x, y0, p0.y), Vector3(n0.x, 0, n0.y), Vector2(s, -MARGIN)],
			[Vector3(p1.x, y0, p1.y), Vector3(n1.x, 0, n1.y), Vector2(s1, -MARGIN)],
			[Vector3(p1.x, y0 + MARGIN + HEIGHT, p1.y), Vector3(n1.x, 0, n1.y), Vector2(s1, HEIGHT)],
			[Vector3(p0.x, y0 + MARGIN + HEIGHT, p0.y), Vector3(n0.x, 0, n0.y), Vector2(s, HEIGHT)]]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_normal(v[k][1])
			st.set_uv(v[k][2])
			st.add_vertex(v[k][0])
		s = s1
	length = s
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "TarasyScreen"
	mesh_instance.mesh = st.commit()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.custom_aabb = AABB(Vector3(-1395, y0, 405), Vector3(45, MARGIN + HEIGHT, 40))
	var tex := _title_texture()
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER)
	mat.set_shader_parameter("size", Vector2(length, HEIGHT))
	mat.set_shader_parameter("margin", MARGIN)
	mat.set_shader_parameter("words", tex)
	mat.set_shader_parameter("words_px", Vector2(tex.get_width(), tex.get_height()))
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	print("tarasy_screen: %.1f m x %.1f m at y %.1f" % [length, HEIGHT, y0 + MARGIN])


## The title as one image (red channel = lit): the two lines, one pixel of the font a texel.
func _title_texture() -> ImageTexture:
	var wide := 0
	for l: String in TITLE:
		wide = maxi(wide, Pixel.width(l))
	var img := Image.create_empty(wide + 4, TITLE.size() * Pixel.LINE + 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for i in TITLE.size():
		var l: String = TITLE[i]
		Pixel.draw(img, l, (img.get_width() - Pixel.width(l)) / 2, 1 + i * Pixel.LINE, Color.WHITE)
	return ImageTexture.create_from_image(img)
