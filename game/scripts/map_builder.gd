extends Node3D
## Builds the city: terrain, parks, paths, roads with lane markings and tram
## rails laid over it, GUGiK LoD2 buildings (plus OpenStreetMap extrusions where
## LoD2 has nothing), trees, the collision the car drives against, and a grid of
## roof heights the helicopter flies over.

# Godot treats clockwise triangles as front faces, so a front face's
# (b - a) x (c - a) points away from the viewer.
const CLOCKWISE_FRONT := true
const Chunked := preload("res://scripts/chunked_surface.gd")
const Neon := preload("res://scripts/neon_signs.gd")
const Landmarks := preload("res://scripts/landmarks.gd")
## Loop 2c: the parked cars' mesh and paints come from the vehicles' models (one source).
const Models := preload("res://scripts/models.gd")
## Tile size for instanced things (trees, lamps, parked cars). Loop 2b: 512 m (was 256): one
## MultiMesh is one draw call, and the iPhone pays per draw call, not per instance.
const INSTANCE_TILE := 512.0
## Loop 2b: things under a metre tall (benches, bins, bike racks) cast no sun shadow (a few
## texels at most) and hide when the view is wider than main.gd's FINE_VIEW metres, where
## they are under two pixels: the group "fine_detail".
const FINE_GROUP := "fine_detail"
## Loop 2b: lamps, signals, parked cars, advertising columns and shelters: they cast sun shadows
## on High only (main.gd QUALITY); the group "small_casters".
const SMALL_CASTERS := "small_casters"
## Direction of the Śródmieście street grid (Marszałkowska), for paving on open areas.
const CITY_GRID := Vector2(0.342, 0.940)
## Ground-shader layer ids (UV.y).
const L_GROUND := 0.0
const L_GREEN := 1.0
const L_PLAZA := 2.0
const L_WATER := 3.0
const L_FOOT := 4.0
const L_CYCLE := 5.0
const L_ROAD := 6.0
const L_MARK := 7.0
const L_RAIL := 8.0
const L_BALLAST := 9.0
const L_STEPS := 10.0
const L_FLOWERS := 11.0
const L_DIRT := 12.0
const L_PLAY := 13.0
const L_ISLAND := 14.0
const L_GRAVEL := 15.0

const Y_GROUND := 0.0
const Y_AREA := 0.02
const Y_PATH := 0.04
const Y_ROAD := 0.06
const Y_MARK := 0.08
const FLOOR_HEIGHT := 3.3

const COL := {
	"ground": Color("#bdb6a3"),
	"plaza": Color("#d9d1bf"),
	"park": Color("#7fb04f"),
	"grass": Color("#8fbd58"),
	"pitch": Color("#6fa94f"),
	"water": Color("#5ea8d8"),
	"road": Color("#4f535a"),
	"road_minor": Color("#62666c"),
	"foot": Color("#e6e0d2"),
	"cycle": Color("#c86e5c"),
	"mark": Color("#f4f1e8"),
	"rail": Color("#3d3a37"),
}
const FACADES := ["#e9dcc2", "#d8c6a6", "#cfc4b2", "#e3c993", "#c9b08e", "#b9bec4", "#d9b98f", "#b59c7e", "#e6dccd", "#c98f6b", "#a8a49d", "#d6a77a"]
const ROOFS := ["#8d8882", "#7d726a", "#9b9187", "#72777c", "#857a70"]
const GLASS := ["#8fb4cb", "#9fbfd2", "#7ea4bd", "#a9c3cf"]
const CANOPY_SUMMER := ["#4e8a3b", "#5d9a44", "#437c36", "#6aa64c", "#5a8f3e"]
const CANOPY_AUTUMN := ["#4f8a3b", "#5f9640", "#7a9a35", "#a59a32", "#cfa22b", "#de8b2b", "#c8642c", "#4a8038", "#93a03a"]
const NEEDLE := ["#2f5e3a", "#376b40", "#2a5434"]

## "autumn" or "summer": picks the leaf colours.
var season := "autumn"
var data: Dictionary
## Tree crowns; the game feeds it the car position so crowns can open up around the car.
@export_storage var leaf_material: ShaderMaterial
## The materials the game updates every frame (car position for the see-through hole).
@export_storage var building_material: ShaderMaterial
@export_storage var flat_material: ShaderMaterial
## Every material that opens a see-through hole around the car (trees, parked cars).
@export_storage var fade_materials: Array[ShaderMaterial] = []
## The street-lamp light map (tools/bake_lights.py) and the map rectangle it covers;
## the game hands them to the vehicles' material too.
@export_storage var light_texture: ImageTexture
@export_storage var light_rect := Vector4(0, 0, 1, 1)
## v0.9: the surface map (tools/bake_water.py): distance to the shore, the river's
## flow, what reflects, bridge-deck heights; the ground shader and the post pass read it.
@export_storage var water_texture: ImageTexture
@export_storage var water_rect := Vector4(0, 0, 1, 1)
## Loop 10a: the surface map's shore distance (its R channel: a quarter metre per step inside
## water, 0 on dry land), one byte per texel, kept on the CPU for the car's water test
## (`shore_distance`); stored zstd-packed so the prebuilt city carries it too (the export
## leaves water.bin out), unpacked on first use.
@export_storage var _shore_zip := PackedByteArray()
@export_storage var _shore_size := Vector2i.ZERO
var _shore := PackedByteArray()
var _light_image: Image
## Lamps the light bake added where OpenStreetMap maps none (the bridges): x, z, yaw.
var _extra_lamps := PackedFloat32Array()
var _lod2_footprints: Array = []
var bounds: Rect2
var _wall_faces := PackedVector3Array()

## Terrain heights in metres relative to the bake's base height; empty means a flat world.
@export_storage var _terrain: Dictionary = {}
@export_storage var _t_h := PackedFloat32Array()
## While the flat layers are built, triangles are subdivided and laid onto the
## ground. The value is the depth bias (metres towards the camera) that keeps a
## layer above the one under it; -1 means "not draping".
var _drape_bias := -1.0
## Ground-shader layer id written to UV.y (see ground.gdshader) and the second UV:
## along/across metres for paths and roads (paving runs with the street), the
## building style seed and wall top for facades.
var _layer := 0.0
var _axis := Vector2.ZERO
var _uv2 := Vector2.ZERO
## Bridge decks (tools/bake_roads.py): pieces with a height every few metres, one per
## bridge road, footway, tram track or railway, in groups (one structure each). Each
## piece: pts, cum (metres along), h, l/r (corridor left/right of its line), g (group),
## k (road, path, tram, rail), o (per point: 1 = left side outer, 2 = right side outer),
## box (bounds, for quick rejection).
@export_storage var _decks: Array[Dictionary] = []
## Loop 3a (R1): the approaches of the bridges (tools/bake_roads.py `fills`: abutments,
## embankments, the ways onto a bridge where the 10 m terrain grid blurs the abutment into a
## slope): pieces like the decks' (pts, cum, h, l, r) that correct the ground under their
## corridor, so the road, its markings, the lanes and the car there sit on the solved
## profile instead of the blur. `terrain_height` includes them; the ground mesh does not.
@export_storage var _fills: Array[Dictionary] = []
## Fill segments per FILL_CELL cell (cell key -> piece << 12 | segment), built on load.
@export_storage var _fill_cells := {}
## Loop 3b: the aprons (tools/bake_structures.py `aprons`: where a deck's or tunnel's end meets
## the ground, the ground blends from the end's flat height to the terrain): per apron x0, z0,
## the unit direction, the length, the end's height, left and right reach, the inside part's
## length; and per cell.
@export_storage var _aprons: Array[PackedFloat32Array] = []
## An apron (of a map baked without `i`) starts this far inside the structure's end (the ground
## held under it there).
const APRON_IN := 4.0
@export_storage var _apron_cells := {}
const FILL_CELL := 16.0
## Loop 3a (R4): tunnel pieces (tools/bake_roads.py `tunnels`): pts, h, g (one tunnel each).
## Only their heights are used so far (the lane graph's tunnel edges); loop 3b builds them.
@export_storage var _tunnels: Array[Dictionary] = []
## While a flat layer is built: the deck group it lies on (-1: the terrain).
var _dk := -1
## Loop 3b: ...or the tunnel it lies in (-1: none).
var _tn := -1
var _has_lod2 := false
## Building tops on a grid of ROOF_CELL squares (NO_ROOF in the open), so the
## helicopter can treat buildings as solid without a physics query per frame.
const ROOF_CELL := 4.0
const NO_ROOF := -1000.0
@export_storage var _roof := PackedFloat32Array()
@export_storage var _roof_x0 := 0.0
@export_storage var _roof_z0 := 0.0
@export_storage var _roof_nx := 0
@export_storage var _roof_nz := 0
## v0.8 landmarks (landmarks.gd): what each one's info card says, and which landmark
## (1-based, 0 for none) covers each roof-grid cell, for tapping.
@export_storage var landmark_info: Array[Dictionary] = []
@export_storage var _pick := PackedByteArray()


func build(path: String, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> Dictionary:
	building_material = building_mat
	flat_material = flat_mat
	var text := FileAccess.get_file_as_string(path)
	data = JSON.parse_string(text)
	var b: Array = data["bounds"]
	bounds = Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
	_roof_x0 = bounds.position.x
	_roof_z0 = bounds.position.y
	_roof_nx = ceili(bounds.size.x / ROOF_CELL)
	_roof_nz = ceili(bounds.size.y / ROOF_CELL)
	_roof.resize(_roof_nx * _roof_nz)
	_roof.fill(NO_ROOF)
	_load_ao(flat_material)
	_load_water(flat_material)
	_load_lights()
	_apply_lights(flat_material)
	_apply_lights(building_material)
	_set_floodlit(building_material)
	if FileAccess.file_exists("res://map/terrain.json"):
		_terrain = JSON.parse_string(FileAccess.get_file_as_string("res://map/terrain.json"))
		_t_h = PackedFloat32Array(_terrain["h"])

	_load_fills()
	_load_aprons()
	_load_decks()
	_load_tunnels()
	var flat := Chunked.new()
	_build_ground(flat)
	# Wide gaps between the depth biases: two layers that fit a slope with different
	# triangles can differ by a few centimetres, and must not poke through each other.
	_drape_bias = 0.05
	_build_areas(flat)
	_drape_bias = 0.08
	_build_surfaces(flat)
	_drape_bias = 0.1
	_build_paths(flat)
	_build_steps(flat)
	_drape_bias = 0.2
	_build_rail_beds(flat)
	_drape_bias = 0.3
	_build_roads(flat)
	_build_tunnel_roads(flat)
	_build_carriageways(flat)
	_drape_bias = 0.34
	_build_islands(flat)
	_build_medians(flat)
	_drape_bias = 0.36
	_build_kerbs(flat)
	_build_shore_stone(flat)
	_drape_bias = 0.38
	_build_markings(flat)
	_build_symbols(flat)
	_build_crossings(flat)
	_drape_bias = 0.46
	_build_trams(flat)
	_build_rails(flat)
	_drape_bias = -1.0
	_dk = -1
	_add_mesh(flat, flat_material, false)

	# v0.8: the landmarks replace whatever LoD2 or OpenStreetMap lump stood in their place.
	var marks := Landmarks.new(self, data)
	var walls := Chunked.new()
	var keep := _build_lod2(walls, marks)
	var t_parts := Time.get_ticks_msec()
	_build_buildings(walls, keep, marks)
	print("buildings: %d floating parts: %d lowered (%d to the ground), %d tiny left out · %d ms" % [floating_parts,
			floating_parts - floating_dropped, floating_to_ground, floating_dropped, Time.get_ticks_msec() - t_parts])
	marks.build(walls)
	landmark_info = marks.info
	_pick = marks.pick_grid()
	_build_platforms(walls)
	_build_barriers(walls)
	_build_bridge_structures(walls)
	_build_walls(walls)
	_build_portals(walls)
	_build_garage_doors(walls)
	_build_guard_rails(walls)
	_build_shore()
	_add_mesh(walls, building_material, true)
	_build_neon(keep, marks)

	_build_trees()
	_build_street_furniture()
	_build_props()
	_build_collision()
	return data


func _add_mesh(st, material: Material, shadows: bool) -> void:
	for mesh in st.meshes():
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


## The baked occlusion map (tools/bake_ao.py) goes to the ground shader: red the
## buildings' shade (the occlusion ghost lifts it), green the parked cars' and trees'.
func _load_ao(material: Material) -> void:
	if not FileAccess.file_exists("res://map/ao.bin") or not (material is ShaderMaterial):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/ao.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	# Loop 1: two bytes per metre (the buildings' shade, then the parked cars' and trees');
	# an older one-byte map still loads (as both).
	var two := bytes.size() >= 20 + w * h * 2
	var image := Image.create_from_data(w, h, false, Image.FORMAT_RG8 if two else Image.FORMAT_L8,
			bytes.slice(20, 20 + w * h * (2 if two else 1)))
	if not two:
		image.convert(Image.FORMAT_RG8)
		var grey := image.get_data()
		for k in range(1, grey.size(), 2):
			grey[k] = 255
		image = Image.create_from_data(w, h, false, Image.FORMAT_RG8, grey)
	var m := material as ShaderMaterial
	m.set_shader_parameter("ao_map", ImageTexture.create_from_image(image))
	m.set_shader_parameter("ao_rect", Vector4(x0, z0, w * px, h * px))


## The surface map (tools/bake_water.py): RGBA per 2 m, linear filtering.
func _load_water(material: Material) -> void:
	if not FileAccess.file_exists("res://map/water.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/water.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	var image := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes.slice(20, 20 + w * h * 4))
	water_texture = ImageTexture.create_from_image(image)
	water_rect = Vector4(x0, z0, w * px, h * px)
	# Loop 10a: the R channel alone, for the car's water test (the convert keeps red).
	var red := image.duplicate() as Image
	red.convert(Image.FORMAT_R8)
	_shore = red.get_data()
	_shore_size = Vector2i(w, h)
	_shore_zip = _shore.compress(FileAccess.COMPRESSION_ZSTD)
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("surface_map", water_texture)
		(material as ShaderMaterial).set_shader_parameter("surface_rect", water_rect)


## The baked street-lamp pools (tools/bake_lights.py): two bytes per metre, sodium
## and LED. Kept as an image too, so each lamp's head can glow in its pool's colour.
func _load_lights() -> void:
	if not FileAccess.file_exists("res://map/lights.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/lights.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	var end := 20 + w * h * 2
	_light_image = Image.create_from_data(w, h, false, Image.FORMAT_RG8, bytes.slice(20, end))
	light_texture = ImageTexture.create_from_image(_light_image)
	light_rect = Vector4(x0, z0, w * px, h * px)
	if bytes.size() >= end + 4:
		var n := bytes.decode_u32(end)
		_extra_lamps = bytes.slice(end + 4, end + 4 + n * 12).to_float32_array()


func _apply_lights(material: Material) -> void:
	if light_texture != null and material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("light_map", light_texture)
		(material as ShaderMaterial).set_shader_parameter("light_rect", light_rect)


## Sodium (true) or LED (false) light at a point of the light map.
func _sodium_at(x: float, z: float) -> bool:
	if _light_image == null:
		return true
	var i := clampi(int((x - light_rect.x) / light_rect.z * _light_image.get_width()), 0, _light_image.get_width() - 1)
	var j := clampi(int((z - light_rect.y) / light_rect.w * _light_image.get_height()), 0, _light_image.get_height() - 1)
	var c := _light_image.get_pixel(i, j)
	return c.r >= c.g


## The Palace of Culture's floodlights: its centre and reach, from its outline.
func _set_floodlit(material: Material) -> void:
	if not (material is ShaderMaterial):
		return
	for l in data.get("landmarks", []):
		if l["name"] != "Pałac Kultury i Nauki":
			continue
		var pts := _pts(l["p"])
		var centre := Vector2.ZERO
		for q in pts:
			centre += q
		centre /= maxf(pts.size(), 1)
		var reach := 0.0
		for q in pts:
			reach = maxf(reach, q.distance_to(centre))
		(material as ShaderMaterial).set_shader_parameter("floodlit", Vector4(centre.x, centre.y, reach + 12.0, 0.0))
		return

# --- heights ------------------------------------------------------------------

func terrain_height(x: float, z: float) -> float:
	var h := _fill_height(x, z)
	if _apron_cells.is_empty():
		return h
	# Loop 3b: an apron where a structure's end meets the ground: under its last APRON_IN metres
	# the ground is held under the end's height, then it blends from that height (flat across,
	# as the deck or tunnel is) to the terrain.
	var list: PackedInt32Array = _apron_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	for k in list:
		var a: PackedFloat32Array = _aprons[k]
		var along := (x - a[0]) * a[2] + (z - a[1]) * a[3]
		var lat := (z - a[1]) * a[2] - (x - a[0]) * a[3]
		if along >= 0.0 and along <= a[4] and lat >= -a[6] and lat <= a[7]:
			h = minf(h, a[5]) if along < a[8] else lerpf(a[5], h, (along - a[8]) / (a[4] - a[8]))
	return h


## The grid raised to any approach whose corridor holds the point (terrain_height before the
## aprons).
func _fill_height(x: float, z: float) -> float:
	var h := _grid_height(x, z)
	if _fill_cells.is_empty():
		return h
	var codes: PackedInt32Array = _fill_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	if codes.is_empty():
		return h
	# Loop 3a: inside an approach's corridor the ground is its profile (never lower).
	var p := Vector2(x, z)
	for code in codes:
		var d: Dictionary = _fills[code >> 12]
		var k := code & 4095
		var pts: PackedVector2Array = d["pts"]
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var u := (p - a).dot(ab) / l2
		if (u < 0.0 and k > 0) or (u > 1.0 and k < pts.size() - 2) or u < -0.05 or u > 1.05:
			continue
		var t := clampf(u, 0.0, 1.0)
		var lat := ab.cross(p - a) / sqrt(l2)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			var hs: PackedFloat32Array = d["h"]
			h = maxf(h, lerpf(hs[k], hs[k + 1], t))
	return h


## The GUGiK terrain grid alone (the two triangles per cell `_build_ground` draws).
func _grid_height(x: float, z: float) -> float:
	if _t_h.is_empty():
		return 0.0
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var fx := clampf((x - float(_terrain["x0"])) / step, 0.0, nx - 1.0001)
	var fz := clampf((z - float(_terrain["z0"])) / step, 0.0, nz - 1.0001)
	var i := int(fx)
	var j := int(fz)
	var u := fx - i
	var v := fz - j
	var h00 := _t_h[j * nx + i]
	var h10 := _t_h[j * nx + i + 1]
	var h01 := _t_h[(j + 1) * nx + i]
	var h11 := _t_h[(j + 1) * nx + i + 1]
	# The same two triangles per cell that _build_ground draws.
	if u >= v:
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	return h00 + (h11 - h01) * u + (h01 - h00) * v


## The top surface at a point: the terrain, or the highest bridge deck over it.
func ground_height(x: float, z: float) -> float:
	var h := terrain_height(x, z)
	for d in _decks_at(x, z):
		h = maxf(h, d)
	return h


## Where a vehicle at height `near_y` drives: of the terrain and the decks over the
## point, the highest one it can step onto (a ramp rises gently; a deck 5 m over the
## road stays overhead). The car and the skid marks use it.
func drive_height(x: float, z: float, near_y: float) -> float:
	var best := terrain_height(x, z)
	for d in _decks_at(x, z):
		if d <= near_y + 1.2 and d > best:
			best = d
	# Loop 3b: in a tunnel's corridor, a vehicle down at its floor drives the floor.
	var t := tunnel_floor(x, z, near_y)
	if not is_nan(t):
		return t
	return best


## Loop 3b: the floor of the tunnel whose corridor holds (x, z), for a vehicle at height
## near_y that is at it (within 1.2 m); NAN otherwise (on the street over a tunnel, the
## street; at the portal the floor meets the open road's height).
func tunnel_floor(x: float, z: float, near_y: float) -> float:
	if _tunnels.is_empty():
		return NAN
	var p := Vector2(x, z)
	for d in _tunnels:
		if not (d["box"] as Rect2).has_point(p):
			continue
		var hit := _deck_hit(d, p)
		if hit.z > 0.0 and near_y <= hit.x + 1.2 and near_y >= hit.x - 1.2:
			return hit.x
	return NAN


## Loop 3b: the floor of a tunnel whose corridor holds (x, z), whatever the height (NAN when
## none): main.gd's --tunnel start.
func tunnel_floor_under(x: float, z: float) -> float:
	for d in _tunnels:
		if (d["box"] as Rect2).has_point(Vector2(x, z)):
			var hit := _deck_hit(d, Vector2(x, z))
			if hit.z > 0.0:
				return hit.x
	return NAN


## Loop 3b: a vehicle at (x, y, z) is inside a tunnel (on its floor, more than 2 m under the
## ground): main.gd shows the car through the ground then (its x-ray).
func in_tunnel(x: float, z: float, y: float) -> bool:
	var t := tunnel_floor(x, z, y)
	return not is_nan(t) and terrain_height(x, z) - t > 2.0


## Loop 10a: how far into the water (river, pond or fountain) a point lies, in metres from
## the nearest dry texel, interpolated between the 2 m texels' centres; 0 on dry land and
## off the map. Four byte reads: cheap enough for the car every frame.
func shore_distance(x: float, z: float) -> float:
	if _shore.is_empty():
		if _shore_zip.is_empty():
			return 0.0
		_shore = _shore_zip.decompress(_shore_size.x * _shore_size.y, FileAccess.COMPRESSION_ZSTD)
	var px := water_rect.z / maxf(_shore_size.x, 1)
	var fx := (x - water_rect.x) / px - 0.5
	var fz := (z - water_rect.y) / px - 0.5
	var i := floori(fx)
	var j := floori(fz)
	if i < 0 or j < 0 or i >= _shore_size.x - 1 or j >= _shore_size.y - 1:
		return 0.0
	var k := j * _shore_size.x + i
	var u := fx - i
	var near := lerpf(_shore[k], _shore[k + 1], u)
	var far := lerpf(_shore[k + _shore_size.x], _shore[k + _shore_size.x + 1], u)
	return lerpf(near, far, fz - j) * 0.25


## Loop 10a: how far past the water's edge a vehicle's centre must be to count as in the water
## (metres, from shore_distance). The first water texel's centre lies 0-2 m past the mapped
## edge, so this is ~1-2.5 m in: a car stopped by the shore edge (its centre a metre or two
## inland) never counts, a car that rolled in does.
const WET := 2.5


## Loop 10a: a vehicle at height y over (x, z) is in the water: well past the water's edge
## and down at the water's level (a bridge deck over the river is not the water).
func in_water(x: float, z: float, y: float) -> bool:
	return shore_distance(x, z) >= WET and y < terrain_height(x, z) + 0.5


## Loop 10a: the nearest dry point to (x, z) inside the edge walls (the point itself when it
## is dry): 72 rays out, each jumping ahead by the water's own distance to the shore (shore
## distance is a distance field: a few hundred lookups even from mid-river).
func nearest_dry(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	if shore_distance(x, z) == 0.0:
		return p
	var inner := bounds.grow(-6.0)
	var best := p
	var best_r := 800.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 0.0
		while r < best_r:
			var q := p + d * r
			if not inner.has_point(q):
				break
			var w := shore_distance(q.x, q.y)
			if w == 0.0:
				best_r = r
				best = q
				break
			r += maxf(w - 2.0, 1.0)
	return best


## Heights of the deck pieces whose corridor holds the point (usually none).
func _decks_at(x: float, z: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if _decks.is_empty():
		return out
	if _deck_cells.is_empty():
		_index_decks()
	var codes: PackedInt32Array = _deck_any.get(Vector2i(floori(x / DECK_CELL), floori(z / DECK_CELL)), PackedInt32Array())
	if codes.is_empty():
		return out
	var p := Vector2(x, z)
	# The nearest segment of each piece near here, then whether p is in its corridor.
	var near := {}
	for code in codes:
		var i := code >> 12
		var k := code & 4095
		var pts: PackedVector2Array = _decks[i]["pts"]
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := maxf(ab.length_squared(), 0.000001)
		var u := (p - a).dot(ab) / l2
		var d2 := p.distance_squared_to(a + ab * clampf(u, 0.0, 1.0))
		if not near.has(i) or d2 < float(near[i][0]):
			near[i] = [d2, k, u]
	for i: int in near:
		var d: Dictionary = _decks[i]
		var k: int = near[i][1]
		var u: float = near[i][2]
		var pts: PackedVector2Array = d["pts"]
		if (k == 0 and u < 0.0) or (k == pts.size() - 2 and u > 1.0):
			continue  # past the deck's end
		var ab := pts[k + 1] - pts[k]
		var lat := ab.cross(p - pts[k]) / maxf(ab.length(), 0.001)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			var hs: PackedFloat32Array = d["h"]
			out.append(lerpf(hs[k], hs[k + 1], clampf(u, 0.0, 1.0)))
	return out


## The height of deck group g at a point (its nearest piece, projected onto it), or the
## terrain for g < 0. Things baked onto a bridge (markings, kerbs, tram tracks) use it.
func deck_height(g: int, x: float, z: float) -> float:
	if g < 0:
		return terrain_height(x, z)
	if _deck_cells.is_empty():
		_index_decks()
	var p := Vector2(x, z)
	var best := INF
	var h := terrain_height(x, z)
	var cell := Vector2i(floori(x / DECK_CELL), floori(z / DECK_CELL))
	# Segments of the group's pieces in this cell and around it; the far ones only if none.
	for pass_ in 2:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for code: int in _deck_cells.get(Vector3i(cell.x + dx, cell.y + dz, g), PackedInt32Array()):
					var d: Dictionary = _decks[code >> 12]
					var k := code & 4095
					var pts: PackedVector2Array = d["pts"]
					var a := pts[k]
					var ab := pts[k + 1] - a
					var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
					var d2 := p.distance_squared_to(a + ab * t)
					if d2 < best:
						best = d2
						var hs: PackedFloat32Array = d["h"]
						h = lerpf(hs[k], hs[k + 1], t)
		if best < INF:
			return h
		for d in _decks:
			if int(d["g"]) == g:
				var hit := _deck_hit(d, p)
				if hit.y < best:
					best = hit.y
					h = hit.x
		return h
	return h


const DECK_CELL := 16.0
## (cell x, cell z, group) -> segment codes (piece << 12 | segment), built on first use;
## and per cell, every segment whose corridor reaches into it.
var _deck_cells := {}
var _deck_any := {}


func _index_decks() -> void:
	for i in _decks.size():
		var d: Dictionary = _decks[i]
		var pts: PackedVector2Array = d["pts"]
		var g := int(d["g"])
		var reach := maxf(float(d["l"]), float(d["r"])) + 1.0
		for k in pts.size() - 1:
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for cz in range(floori(lo.y / DECK_CELL), floori(hi.y / DECK_CELL) + 1):
				for cx in range(floori(lo.x / DECK_CELL), floori(hi.x / DECK_CELL) + 1):
					var key := Vector3i(cx, cz, g)
					var list: PackedInt32Array = _deck_cells.get(key, PackedInt32Array())
					list.append((i << 12) | k)
					_deck_cells[key] = list
					var key2 := Vector2i(cx, cz)
					var any: PackedInt32Array = _deck_any.get(key2, PackedInt32Array())
					any.append((i << 12) | k)
					_deck_any[key2] = any


## Against one deck piece: (height at the nearest point, squared distance to it,
## 1 if the point is inside its corridor else 0).
func _deck_hit(d: Dictionary, p: Vector2) -> Vector3:
	var pts: PackedVector2Array = d["pts"]
	var cum: PackedFloat32Array = d["cum"]
	var hs: PackedFloat32Array = d["h"]
	var best := INF
	var height := 0.0
	var inside := 0.0
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var u := (p - a).dot(ab) / l2
		var t := clampf(u, 0.0, 1.0)
		var q := a + ab * t
		var d2 := p.distance_squared_to(q)
		if d2 < best:
			best = d2
			height = lerpf(hs[k], hs[k + 1], t)
			var lat := ab.cross(p - a) / sqrt(l2)  # right of the line is +
			var along := cum[k] + t * (cum[k + 1] - cum[k])
			var ends := (k == 0 and u < 0.0) or (k == pts.size() - 2 and u > 1.0)
			inside = 1.0 if not ends and along >= 0.0 and lat >= -float(d["l"]) and lat <= float(d["r"]) else 0.0
	return Vector3(height, best, inside)


func _load_decks() -> void:
	_decks.clear()
	var data_decks: Dictionary = data.get("decks", {})
	for piece in data_decks.get("pieces", []):
		var pts := _pts(piece["p"])
		var cum := PackedFloat32Array([0.0])
		for k in range(1, pts.size()):
			cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		var reach := maxf(float(piece["l"]), float(piece["r"])) + 1.0
		_decks.append({"pts": pts, "cum": cum, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]),
				"r": float(piece["r"]), "g": int(piece["g"]), "k": String(piece["k"]),
				"o": PackedByteArray(piece.get("o", [])), "box": box.grow(reach)})


## Loop 3a (R1): the approaches' pieces and their cell index (`terrain_height` reads them).
func _load_fills() -> void:
	_fills.clear()
	_fill_cells.clear()
	for piece in data.get("fills", []):
		var pts := _pts(piece["p"])
		var i := _fills.size()
		_fills.append({"pts": pts, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]), "r": float(piece["r"])})
		var reach := maxf(float(piece["l"]), float(piece["r"])) + 0.5
		for k in pts.size() - 1:
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for cz in range(floori(lo.y / FILL_CELL), floori(hi.y / FILL_CELL) + 1):
				for cx in range(floori(lo.x / FILL_CELL), floori(hi.x / FILL_CELL) + 1):
					var key := (cx + 1024) * 4096 + cz + 1024
					var list: PackedInt32Array = _fill_cells.get(key, PackedInt32Array())
					list.append((i << 12) | k)
					_fill_cells[key] = list


## Loop 3b (R6): retaining walls where an approach (a fill) stands above the ground beside it
## (tools/bake_structures.py `walls`): a stone face (roads; concrete under tracks) from the
## ground outside to the fill's top, a light coping, and on roads where the drop is a metre or
## more a parapet with its inner face; solid where the bake says so (not where a way joins the
## approach). Into the walls' tile meshes, like the slabs. The same runs line the tunnels
## (kind "tunnel": dark, from the floor up, solid only inside) and their open ramps (kind
## "concrete", facing the road in its trench). Loop 3a drew plain faces
## (`_build_fill_sides`, still used for a map baked without `walls`).
const WALL_STONE := Color("#a69d8f")
const WALL_CONCRETE := Color("#a59f95")
const WALL_COPING := Color("#c9c4b8")
const WALL_TUNNEL := Color("#6e6a63")
const WALL_PARAPET := 0.9


func _build_walls(st) -> void:
	if not data.has("walls"):
		_build_fill_sides(st)
		return
	_uv2 = Vector2(0.5, -1.0)
	for w: Dictionary in data["walls"]:
		var pts := _pts(w["p"])
		var tops: Array = w["t"]
		var lows: Array = w["b"]
		var flags: Array = w["f"]
		var tunnel: bool = w["k"] == "tunnel"
		var face := WALL_STONE if w["k"] == "stone" else (WALL_TUNNEL if tunnel else WALL_CONCRETE)
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var out := Vector2(-dir.y, dir.x)
			var n := Vector3(out.x, 0.0, out.y)
			var flag := int(flags[i])
			var ta := float(tops[i]) - (0.2 if tunnel else 0.0)
			var tb := float(tops[i + 1]) - (0.2 if tunnel else 0.0)
			var lift := WALL_PARAPET if flag & 2 else 0.0
			# Blocks: every other stretch a shade lighter, so a long wall reads as masonry.
			var col := face.lightened(0.04) if i % 2 == 0 else face.darkened(0.03)
			_quad(st, Vector3(a.x, float(lows[i]) - 0.3, a.y), Vector3(b.x, float(lows[i + 1]) - 0.3, b.y),
					Vector3(b.x, tb + lift, b.y), Vector3(a.x, ta + lift, a.y), n, col)
			# The coping (and the parapet's top), WALL_OUT wide back to the fill's corridor.
			var ai := a - out * 0.3
			var bi := b - out * 0.3
			if not tunnel:
				_quad(st, Vector3(a.x, ta + lift, a.y), Vector3(b.x, tb + lift, b.y), Vector3(bi.x, tb + lift, bi.y),
						Vector3(ai.x, ta + lift, ai.y), Vector3.UP, WALL_COPING)
			if lift > 0.0:
				_quad(st, Vector3(ai.x, ta - 0.05, ai.y), Vector3(bi.x, tb - 0.05, bi.y), Vector3(bi.x, tb + lift, bi.y),
						Vector3(ai.x, ta + lift, ai.y), -n, face.lightened(0.08))
			if flag & 4:
				# Inside a tunnel: solid from its floor to over a bus, not up to the street above.
				var fa := float(lows[i])
				var fb := float(lows[i + 1])
				_wall_faces.append_array([Vector3(a.x, fa - 1.0, a.y), Vector3(b.x, fb - 1.0, b.y), Vector3(b.x, fb + 4.5, b.y),
						Vector3(a.x, fa - 1.0, a.y), Vector3(b.x, fb + 4.5, b.y), Vector3(a.x, fa + 4.5, a.y)])
			elif flag & 1:
				var y0a := float(lows[i]) - 1.0
				var y0b := float(lows[i + 1]) - 1.0
				_wall_faces.append_array([Vector3(a.x, y0a, a.y), Vector3(b.x, y0b, b.y), Vector3(b.x, tb + 1.6, b.y),
						Vector3(a.x, y0a, a.y), Vector3(b.x, tb + 1.6, b.y), Vector3(a.x, ta + 1.6, a.y)])
	_uv2 = Vector2.ZERO


## Loop 3b: a frame at each tunnel portal (`tunnels.frames`, tools/bake_structures.py): a
## concrete headwall over the mouth up to the ground above it, two posts and a dark mouth a
## little inside (the tunnel's road and walls show in it); the headwall and posts are solid.
const PORTAL_CONCRETE := Color("#b3ada3")
const PORTAL_DARK := Color("#1f1d22")
const PORTAL_MOUTH := 4.8


func _build_portals(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for f: Dictionary in data.get("tunnels", {}).get("frames", []):
		var c := Vector2(float(f["c"][0]), float(f["c"][1]))
		var d := Vector2(float(f["d"][0]), float(f["d"][1]))
		var side := Vector2(-d.y, d.x)
		var w := float(f["w"])
		var y := float(f["y"])
		var top := maxf(float(f["top"]), y + PORTAL_MOUTH + 0.8) + 0.6
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var head := c + d * 0.5
		# The headwall over the mouth, the posts either side, the mouth's dark back.
		_box_oriented(st, Vector3(head.x, (y + PORTAL_MOUTH + top) * 0.5, head.y), basis,
				Vector3(w + 2.4, top - y - PORTAL_MOUTH, 1.0), PORTAL_CONCRETE)
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = head + side * sgn * (w * 0.5 + 0.6)
			_box_oriented(st, Vector3(p.x, (y - 0.5 + y + PORTAL_MOUTH) * 0.5, p.y), basis,
					Vector3(1.2, PORTAL_MOUTH + 0.5, 1.0), PORTAL_CONCRETE.darkened(0.06))
		var back := c + d * 3.0
		var l0 := back - side * w * 0.5
		var r0 := back + side * w * 0.5
		_quad(st, Vector3(l0.x, y - 0.2, l0.y), Vector3(r0.x, y - 0.2, r0.y), Vector3(r0.x, y + PORTAL_MOUTH, r0.y),
				Vector3(l0.x, y + PORTAL_MOUTH, l0.y), Vector3(-d.x, 0.0, -d.y), PORTAL_DARK)
		# The headwall's front face is solid (the street above can't drive off into the ramp).
		var a := head - d * 0.5 - side * (w * 0.5 + 1.2)
		var b := head - d * 0.5 + side * (w * 0.5 + 1.2)
		_wall_faces.append_array([Vector3(a.x, y + PORTAL_MOUTH, a.y), Vector3(b.x, y + PORTAL_MOUTH, b.y), Vector3(b.x, top + 1.6, b.y),
				Vector3(a.x, y + PORTAL_MOUTH, a.y), Vector3(b.x, top + 1.6, b.y), Vector3(a.x, top + 1.6, a.y)])
	_uv2 = Vector2.ZERO


## Loop 3b: a garage door at each ramp top where R9 ended a service way (`garage_doors`): a
## concrete frame and a grey roller shutter across the way, solid.
func _build_garage_doors(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for g: Dictionary in data.get("garage_doors", []):
		var c := Vector2(float(g["c"][0]), float(g["c"][1]))
		var d := Vector2(float(g["d"][0]), float(g["d"][1])).normalized()
		var side := Vector2(-d.y, d.x)
		var w := float(g["w"])
		var y := float(g["y"])
		var basis := Basis(Vector3.UP, atan2(-d.x, -d.y))
		var at := c + d * 0.6
		_box_oriented(st, Vector3(at.x, y + 1.2, at.y), basis, Vector3(w, 2.4, 0.15), Color("#8e9196"))
		_box_oriented(st, Vector3(at.x, y + 2.65, at.y), basis, Vector3(w + 0.8, 0.5, 0.4), PORTAL_CONCRETE)
		for sgn in [-1.0, 1.0]:
			var p: Vector2 = at + side * sgn * (w * 0.5 + 0.2)
			_box_oriented(st, Vector3(p.x, y + 1.2, p.y), basis, Vector3(0.4, 2.4, 0.4), PORTAL_CONCRETE)
		var a := at - side * (w * 0.5 + 0.4)
		var b := at + side * (w * 0.5 + 0.4)
		_wall_faces.append_array([Vector3(a.x, y - 0.5, a.y), Vector3(b.x, y - 0.5, b.y), Vector3(b.x, y + 2.9, b.y),
				Vector3(a.x, y - 0.5, a.y), Vector3(b.x, y + 2.9, b.y), Vector3(a.x, y + 2.9, a.y)])
	_uv2 = Vector2.ZERO


## Loop 3b: the aprons and their cell index (`terrain_height` reads them).
func _load_aprons() -> void:
	_aprons.clear()
	_apron_cells.clear()
	for a in data.get("aprons", []):
		var p: Array = a["p"]
		var d := Vector2(float(p[2]) - float(p[0]), float(p[3]) - float(p[1]))
		var length := maxf(d.length(), 0.01)
		d /= length
		var k := _aprons.size()
		_aprons.append(PackedFloat32Array([float(p[0]), float(p[1]), d.x, d.y, length, float(a["h"]), float(a["l"]),
				float(a["r"]), float(a.get("i", APRON_IN))]))
		var reach := maxf(float(a["l"]), float(a["r"])) + length
		for cz in range(floori((float(p[1]) - reach) / FILL_CELL), floori((float(p[1]) + reach) / FILL_CELL) + 1):
			for cx in range(floori((float(p[0]) - reach) / FILL_CELL), floori((float(p[0]) + reach) / FILL_CELL) + 1):
				var key := (cx + 1024) * 4096 + cz + 1024
				var list: PackedInt32Array = _apron_cells.get(key, PackedInt32Array())
				list.append(k)
				_apron_cells[key] = list


## Loop 3a: where an approach stands above the terrain grid (the grid's blur at an abutment),
## a plain concrete face down each side of its corridor, so it doesn't float (a map baked
## before loop 3b; `_build_walls` draws the retaining walls instead).
func _build_fill_sides(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var concrete := Color("#b8b2a7").darkened(0.1)
	for d in _fills:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var right := Vector2(-(b - a).y, (b - a).x) / length
			for side in [-1.0, 1.0]:
				var off := float(d["r"]) if side > 0.0 else float(d["l"])
				var p0: Vector2 = a + right * side * off
				var p1: Vector2 = b + right * side * off
				var g0 := _grid_height(p0.x, p0.y)
				var g1 := _grid_height(p1.x, p1.y)
				if hs[i] - g0 < 0.35 and hs[i + 1] - g1 < 0.35:
					continue
				var n := Vector3(right.x * side, 0.0, right.y * side)
				_quad(st, Vector3(p0.x, minf(g0, hs[i]) - 0.3, p0.y), Vector3(p1.x, minf(g1, hs[i + 1]) - 0.3, p1.y),
						Vector3(p1.x, hs[i + 1] - 0.02, p1.y), Vector3(p0.x, hs[i] - 0.02, p0.y), n, concrete)
	_uv2 = Vector2.ZERO


## Loop 3a (R4): the tunnel pieces, for their heights (`tunnel_height`).
func _load_tunnels() -> void:
	_tunnels.clear()
	for piece in data.get("tunnels", {}).get("pieces", []):
		var pts := _pts(piece["p"])
		var cum := PackedFloat32Array([0.0])
		for k in range(1, pts.size()):
			cum.append(cum[k - 1] + pts[k].distance_to(pts[k - 1]))
		var box := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			box = box.expand(q)
		_tunnels.append({"pts": pts, "cum": cum, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]),
				"r": float(piece["r"]), "g": int(piece["g"]), "box": box.grow(maxf(float(piece["l"]), float(piece["r"])) + 1.0)})


## Loop 3a (R4): the height of tunnel t at a point (its nearest piece, projected), or the
## terrain if there is no such tunnel. The lane graph's tunnel edges use it (once per edge).
func tunnel_height(t: int, x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := INF
	var h := terrain_height(x, z)
	for d in _tunnels:
		if int(d["g"]) != t:
			continue
		var hit := _deck_hit(d, p)
		if hit.y < best:
			best = hit.y
			h = hit.x
	return h


## The highest roof over the grid cell holding a point, or NO_ROOF in the open.
func roof_height(x: float, z: float) -> float:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return NO_ROOF
	return _roof[j * _roof_nx + i]


## The top of whatever stands within `radius` of a point: ground, bridge deck or roof.
## Nine samples, so a radius up to one cell can't slip between them.
func top_height(x: float, z: float, radius := 0.0) -> float:
	var h := ground_height(x, z)
	if radius <= 0.0:
		return maxf(h, roof_height(x, z))
	for sz in _SPREAD:
		for sx in _SPREAD:
			h = maxf(h, roof_height(x + sx * radius, z + sz * radius))
	return h


const _SPREAD := [-1.0, 0.0, 1.0]


## The landmark (an index into landmark_info, or -1) a ray from the camera meets first:
## it walks the ray in 1 m steps against the roof grid (whatever stands in a cell is
## treated as filling it up to its top) and the ground.
func pick_landmark(origin: Vector3, dir: Vector3) -> int:
	if dir.y > -0.01:
		return -1
	var t := maxf(0.0, (origin.y - 340.0) / -dir.y)
	var end := t + 2600.0
	while t < end:
		var p := origin + dir * t
		var top := roof_height(p.x, p.z)
		if top != NO_ROOF and p.y <= top:
			return landmark_at(p.x, p.z)
		if p.y < terrain_height(p.x, p.z) - 0.5:
			return -1
		t += 1.0
	return -1


## The landmark (an index into landmark_info, or -1) whose model covers a point.
func landmark_at(x: float, z: float) -> int:
	if _pick.is_empty():
		return -1
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return -1
	return int(_pick[j * _roof_nx + i]) - 1


## Marks the cell holding a point as at least `y` high.
func _roof_mark(x: float, z: float, y: float) -> void:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i >= 0 and j >= 0 and i < _roof_nx and j < _roof_nz and y > _roof[j * _roof_nx + i]:
		_roof[j * _roof_nx + i] = y


## A LoD2 triangle into the roof grid. Every corner marks its cell (that catches
## spires, chimneys and wall tops); roof triangles also give each cell centre
## they cover the roof's height there.
func _roof_triangle(a: Vector3, b: Vector3, c: Vector3, is_roof: bool) -> void:
	_roof_mark(a.x, a.z, a.y)
	_roof_mark(b.x, b.z, b.y)
	_roof_mark(c.x, c.z, c.y)
	if not is_roof:
		return
	var d := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(d) < 0.01:
		return
	# Only the cells whose centres lie inside the triangle's bounding box.
	var i0 := maxi(ceili((minf(a.x, minf(b.x, c.x)) - _roof_x0) / ROOF_CELL - 0.5), 0)
	var i1 := mini(floori((maxf(a.x, maxf(b.x, c.x)) - _roof_x0) / ROOF_CELL - 0.5), _roof_nx - 1)
	var j0 := maxi(ceili((minf(a.z, minf(b.z, c.z)) - _roof_z0) / ROOF_CELL - 0.5), 0)
	var j1 := mini(floori((maxf(a.z, maxf(b.z, c.z)) - _roof_z0) / ROOF_CELL - 0.5), _roof_nz - 1)
	for j in range(j0, j1 + 1):
		var z := _roof_z0 + (j + 0.5) * ROOF_CELL
		for i in range(i0, i1 + 1):
			var x := _roof_x0 + (i + 0.5) * ROOF_CELL
			var l1 := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / d
			var l2 := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / d
			var l3 := 1.0 - l1 - l2
			if l1 < -0.001 or l2 < -0.001 or l3 < -0.001:
				continue
			var y := l1 * a.y + l2 * b.y + l3 * c.y
			var k := j * _roof_nx + i
			if y > _roof[k]:
				_roof[k] = y


## A flat-roofed OpenStreetMap building into the roof grid.
func _roof_polygon(poly: PackedVector2Array, top: float) -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in poly:
		_roof_mark(q.x, q.y, top)
		lo = lo.min(q)
		hi = hi.max(q)
	var i0 := maxi(ceili((lo.x - _roof_x0) / ROOF_CELL - 0.5), 0)
	var i1 := mini(floori((hi.x - _roof_x0) / ROOF_CELL - 0.5), _roof_nx - 1)
	var j0 := maxi(ceili((lo.y - _roof_z0) / ROOF_CELL - 0.5), 0)
	var j1 := mini(floori((hi.y - _roof_z0) / ROOF_CELL - 0.5), _roof_nz - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var p := Vector2(_roof_x0 + (i + 0.5) * ROOF_CELL, _roof_z0 + (j + 0.5) * ROOF_CELL)
			var k := j * _roof_nx + i
			if top > _roof[k] and Geometry2D.is_point_in_polygon(p, poly):
				_roof[k] = top


## The surface a flat layer is laid on: the terrain, or the deck it was baked onto.
func _surface_height(x: float, z: float) -> float:
	if _tn >= 0:
		return tunnel_height(_tn, x, z)
	return deck_height(_dk, x, z) if _dk >= 0 else terrain_height(x, z)


# --- primitives -------------------------------------------------------------

func _tri(st, a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color,
		ua := Vector2(-1, -1), ub := Vector2(-1, -1), uc := Vector2(-1, -1)) -> void:
	if _drape_bias >= 0.0:
		_draped_tri(st, a, b, c, col, 0)
		return
	var facing_viewer := (b - a).cross(c - a).dot(n) > 0.0
	if facing_viewer == CLOCKWISE_FRONT:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_color(col)
		st.set_normal(n)
		st.set_uv(v[1])
		st.set_uv2(_uv2)
		st.add_vertex(v[0])


## A flat-layer triangle laid on the ground: split until no edge is longer than
## the terrain grid, then lifted to the surface (its own y is the layer offset).
func _draped_tri(st, a: Vector3, b: Vector3, c: Vector3, col: Color, depth: int) -> void:
	# Split the longest edge in two until every edge fits the terrain grid; long thin
	# strips (rails, lane lines) then cost a handful of triangles, not thousands.
	var ab := Vector2(a.x - b.x, a.z - b.z).length()
	var bc := Vector2(b.x - c.x, b.z - c.z).length()
	var ca := Vector2(c.x - a.x, c.z - a.z).length()
	if maxf(ab, maxf(bc, ca)) > 12.0 and depth < 16 and not _t_h.is_empty():
		if ab >= bc and ab >= ca:
			var m := (a + b) * 0.5
			_draped_tri(st, a, m, c, col, depth + 1)
			_draped_tri(st, m, b, c, col, depth + 1)
		elif bc >= ca:
			var m := (b + c) * 0.5
			_draped_tri(st, a, b, m, col, depth + 1)
			_draped_tri(st, a, m, c, col, depth + 1)
		else:
			var m := (c + a) * 0.5
			_draped_tri(st, a, b, m, col, depth + 1)
			_draped_tri(st, m, b, c, col, depth + 1)
		return
	var p := [a, b, c]
	for k in 3:
		var v: Vector3 = p[k]
		p[k] = Vector3(v.x, _surface_height(v.x, v.z) + v.y, v.z)
	if ((p[1] - p[0]).cross(p[2] - p[0]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
		p = [p[0], p[2], p[1]]
	var axis := _axis if _axis != Vector2.ZERO else CITY_GRID
	for v in p:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(_drape_bias, _layer))
		st.set_uv2(Vector2(v.x * axis.x + v.z * axis.y, -v.x * axis.y + v.z * axis.x))
		st.add_vertex(v)


func _quad(st, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	_tri(st, a, b, c, n, col)
	_tri(st, a, c, d, n, col)


func _pts(flat_list: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat_list.size() - 1, 2):
		out.append(Vector2(flat_list[i], flat_list[i + 1]))
	return out


func _fill(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	if poly.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(poly)
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		_tri(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, col)


func _disc(st, p: Vector2, r: float, y: float, col: Color, segments := 8) -> void:
	var centre := Vector3(p.x, y, p.y)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		_tri(st, centre, Vector3(p.x + cos(a0) * r, y, p.y + sin(a0) * r),
				Vector3(p.x + cos(a1) * r, y, p.y + sin(a1) * r), Vector3.UP, col)


## A polyline as a flat band; square caps overlap at the joints.
func _strip(st, poly: PackedVector2Array, width: float, y: float, col: Color, extend := true) -> void:
	var hw := width * 0.5
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.01:
			continue
		var dir := d.normalized()
		_axis = dir
		if extend:
			a -= dir * hw
			b += dir * hw
		var side := Vector2(-dir.y, dir.x) * hw
		# Draped: cut into pieces no longer than the terrain grid, so a long thin strip
		# costs two triangles per piece instead of a fan of slivers.
		var pieces := maxi(1, ceili(a.distance_to(b) / 10.0)) if _drape_bias >= 0.0 else 1
		for k in pieces:
			var p := a.lerp(b, float(k) / pieces)
			var q := a.lerp(b, float(k + 1) / pieces)
			_quad(st, Vector3(p.x + side.x, y, p.y + side.y), Vector3(q.x + side.x, y, q.y + side.y),
					Vector3(q.x - side.x, y, q.y - side.y), Vector3(p.x - side.x, y, p.y - side.y), Vector3.UP, col)
	_axis = Vector2.ZERO


# --- layers -------------------------------------------------------------------

## The map ends like a diorama: earth walls drop from the terrain edge.
func _build_edges(st) -> void:
	var step := float(_terrain["step"])
	var x0 := float(_terrain["x0"])
	var z0 := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var bottom: float = Array(_t_h).min() - 14.0
	var top_col := Color("#7d6a52")
	var soil := Color("#6a503b")
	var deep := Color("#45342a")
	var sides := [
		[nx, func(i: int) -> Vector3: return Vector3(x0 + i * step, _t_h[i], z0), Vector3.FORWARD],
		[nx, func(i: int) -> Vector3: return Vector3(x0 + i * step, _t_h[(nz - 1) * nx + i], z0 + (nz - 1) * step), Vector3.BACK],
		[nz, func(j: int) -> Vector3: return Vector3(x0, _t_h[j * nx], z0 + j * step), Vector3.LEFT],
		[nz, func(j: int) -> Vector3: return Vector3(x0 + (nx - 1) * step, _t_h[j * nx + nx - 1], z0 + j * step), Vector3.RIGHT],
	]
	for side in sides:
		var corner: Callable = side[1]
		var n: Vector3 = side[2]
		for k in int(side[0]) - 1:
			var a: Vector3 = corner.call(k)
			var b: Vector3 = corner.call(k + 1)
			var a1 := Vector3(a.x, a.y - 0.8, a.z)
			var b1 := Vector3(b.x, b.y - 0.8, b.z)
			var a2 := Vector3(a.x, bottom, a.z)
			var b2 := Vector3(b.x, bottom, b.z)
			var none := Vector2(-1, -1)
			_tri_shaded(st, a, b, b1, n, top_col, top_col, soil, none, none, none)
			_tri_shaded(st, a, b1, a1, n, top_col, soil, soil, none, none, none)
			_tri_shaded(st, a1, b1, b2, n, soil, soil, deep, none, none, none)
			_tri_shaded(st, a1, b2, a2, n, soil, deep, deep, none, none, none)


func _build_ground(st) -> void:
	if _t_h.is_empty():
		var r := bounds
		_quad(st, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y),
				Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y), Vector3.UP, COL["ground"])
		return
	_build_edges(st)
	var step := float(_terrain["step"])
	var x0 := float(_terrain["x0"])
	var z0 := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	# Smooth normals from the height gradient, so slopes shade softly instead of in facets.
	var normals := PackedVector3Array()
	normals.resize(nx * nz)
	for j in nz:
		for i in nx:
			var hl := _t_h[j * nx + maxi(i - 1, 0)]
			var hr := _t_h[j * nx + mini(i + 1, nx - 1)]
			var hu := _t_h[maxi(j - 1, 0) * nx + i]
			var hd := _t_h[mini(j + 1, nz - 1) * nx + i]
			normals[j * nx + i] = Vector3(hl - hr, 2.0 * step, hu - hd).normalized()
	var colour: Color = COL["ground"]
	for j in nz - 1:
		for i in nx - 1:
			var k00 := j * nx + i
			var k10 := k00 + 1
			var k01 := k00 + nx
			var k11 := k01 + 1
			for tri in [[k00, k10, k11], [k00, k11, k01]]:
				var corners: Array[Vector3] = []
				for k in tri:
					corners.append(Vector3(x0 + (int(k) % nx) * step, _t_h[k], z0 + (int(k) / nx) * step))
				var order := [0, 1, 2]
				if ((corners[1] - corners[0]).cross(corners[2] - corners[0]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
					order = [0, 2, 1]
				for o in order:
					st.set_color(colour)
					st.set_normal(normals[tri[o]])
					st.set_uv(Vector2(-1, -1))
					st.add_vertex(corners[o])


func _build_areas(st) -> void:
	# Plazas first so parks and water sit on top of them.
	for pass_kind in ["plaza", "green", "water"]:
		for a in data["areas"]:
			var k: String = a["k"]
			var group := "plaza" if k == "plaza" else ("water" if k == "water" else "green")
			if group != pass_kind:
				continue
			var y := Y_AREA + (0.005 if group == "green" else 0.0) + (0.01 if group == "water" else 0.0)
			_layer = L_GREEN if group == "green" else (L_WATER if group == "water" else L_PLAZA)
			_fill(st, _pts(a["p"]), y, COL[k])
	_layer = L_GROUND


func _build_paths(st) -> void:
	for p in data["paths"]:
		if p["k"] in ["cyclecross", "zebra"]:
			continue  # these lie on the road; the crossing builder paints them
		var col: Color = COL["cycle"] if p["k"] == "cycle" else COL["foot"]
		var y := Y_PATH + (0.005 if p["k"] == "cycle" else 0.0)
		_layer = L_CYCLE if p["k"] == "cycle" else L_FOOT
		_dk = int(p.get("dk", -1))
		_strip(st, _pts(p["p"]), float(p["w"]), y, col)
	_dk = -1
	_layer = L_GROUND


## Roads as strips `w` wide around their centreline shifted `c` to the right, except
## where a mapped carriageway area already covers them ("hide": metres along the road).
func _build_roads(st) -> void:
	_layer = L_ROAD
	for r in data["roads"]:
		var minor: bool = r["k"] in ["service", "living_street"]
		var col: Color = COL["road_minor"] if minor else COL["road"]
		var w := float(r["w"])
		var y := Y_ROAD - (0.005 if minor else 0.0)
		_dk = int(r.get("dk", -1))
		var full := _pts(r["p"])
		for run in _visible_runs(full, r.get("hide", [])):
			var poly := _offset(run[0], float(r.get("c", 0.0)))
			_strip(st, poly, w, y, col, false)
			# Round patches fill the gaps at the ends and wherever the road bends; not
			# where an area takes over (the area has the exact shape there).
			for i in poly.size():
				var bend := 1.0
				if i > 0 and i < poly.size() - 1:
					bend = absf((poly[i] - poly[i - 1]).angle_to(poly[i + 1] - poly[i]))
				elif (i == 0 and run[1]) or (i == poly.size() - 1 and run[2]):
					continue
				if bend > 0.12:
					_disc(st, poly[i], w * 0.5, y, col)
	_dk = -1
	_layer = L_GROUND


## Loop 3b: the tunnels' roads (`tunnels.roads`), on their tunnel's floor, with a centre line;
## under the ground, so seen only in the portals' mouths (and the car's x-ray inside).
func _build_tunnel_roads(st) -> void:
	_layer = L_ROAD
	for r in data.get("tunnels", {}).get("roads", []):
		_tn = int(r.get("tn", -1))
		if _tn < 0:
			continue
		var poly := _pts(r["p"])
		_strip(st, poly, float(r["w"]), Y_ROAD, COL["road"], true)
		_layer = L_MARK
		_dashes(st, poly, 0.0, 3.0, 6.0, 0.15)
		_layer = L_ROAD
	_tn = -1
	_layer = L_GROUND


## The stretches of a polyline outside the hidden [s0, s1] ranges: [points, cut at
## the start, cut at the end] each.
func _visible_runs(poly: PackedVector2Array, hide: Array) -> Array:
	if hide.is_empty():
		return [[poly, false, false]]
	var runs := []
	var cur := PackedVector2Array()
	var cut_start := false
	var s := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var length := a.distance_to(b)
		var cuts := [0.0, length]
		for h in hide:
			for c in [float(h[0]) - s, float(h[1]) - s]:
				if c > 0.0 and c < length:
					cuts.append(c)
		cuts.sort()
		for k in cuts.size() - 1:
			var c0: float = cuts[k]
			var c1: float = cuts[k + 1]
			if c1 - c0 < 0.001:
				continue
			var mid := s + (c0 + c1) * 0.5
			var hidden := false
			for h in hide:
				if mid >= float(h[0]) and mid <= float(h[1]):
					hidden = true
			var p0 := a.lerp(b, c0 / length) if length > 0.0 else a
			var p1 := a.lerp(b, c1 / length) if length > 0.0 else b
			if hidden:
				if cur.size() >= 2:
					runs.append([cur, cut_start, true])
				cur = PackedVector2Array()
				cut_start = true
			else:
				if cur.is_empty():
					cur.append(p0)
				cur.append(p1)
		s += length
	if cur.size() >= 2:
		runs.append([cur, cut_start, false])
	return runs


## A polyline moved `off` metres to its right, mitred at the corners.
static func _offset(poly: PackedVector2Array, off: float) -> PackedVector2Array:
	if absf(off) < 0.001:
		return poly
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var back := (poly[i] - poly[i - 1]).normalized() if i > 0 else Vector2.ZERO
		var ahead := (poly[i + 1] - poly[i]).normalized() if i < n - 1 else Vector2.ZERO
		if back == Vector2.ZERO:
			back = ahead
		if ahead == Vector2.ZERO:
			ahead = back
		var r0 := Vector2(-back.y, back.x)
		var r1 := Vector2(-ahead.y, ahead.x)
		var m := (r0 + r1).normalized()
		if m == Vector2.ZERO:
			m = r1
		out.append(poly[i] + m * off / maxf(m.dot(r1), 0.5))
	return out


## Mapped carriageway areas (area:highway): the exact road surface, junction boxes
## and bus bays included; hatched areas are asphalt too (the hatching comes later).
func _build_carriageways(st) -> void:
	_layer = L_ROAD
	for c in data.get("carriage", []):
		_dk = int(c.get("dk", -1))
		var minor: bool = c["k"] in ["service", "living_street"]
		_fill(st, _pts(c["p"]), Y_ROAD - (0.005 if minor else 0.0), COL["road_minor"] if minor else COL["road"])
	_dk = -1
	_layer = L_GROUND


const SURFACE_STYLE := {
	"paving": ["#ddd6c8", 4.0],
	"ballast": ["#8f887d", 15.0],
	"flowerbed": ["#6c9844", 11.0],
	"construction": ["#a48b6a", 12.0],
	"playground": ["#c98a64", 13.0],
	"fountain": ["#5ea8d8", 3.0],
}


func _build_surfaces(st) -> void:
	for a in data.get("surfaces", []):
		var style: Array = SURFACE_STYLE.get(a["k"], ["#cfc7b5", 0.0])
		_layer = float(style[1])
		_fill(st, _pts(a["p"]), Y_AREA + 0.01, Color(style[0]))
	_layer = L_GROUND


func _build_steps(st) -> void:
	_layer = L_STEPS
	for p in data.get("steps", []):
		_strip(st, _pts(p["p"]), 2.4, Y_PATH + 0.01, Color("#d2cabb"))
	_layer = L_GROUND


## Kerbs: raised granite strips along the carriageway edges, KERB_UP high.
const KERB_UP := 0.14
const KERB_W := 0.3
const KERB_TOP := Color("#b9b6ae")
const KERB_FACE := Color("#8d8a83")


## Traffic islands, raised to kerb height (their kerb comes with the kerbs).
func _build_islands(st) -> void:
	_layer = L_ISLAND
	for a in data.get("islands", []):
		_dk = int(a.get("dk", -1))
		_fill(st, _pts(a["p"]), KERB_UP, Color("#d3cdc1"))
	_dk = -1
	_layer = L_GROUND


## Dual-carriageway medians: raised grass, or paving at road level where trams run.
func _build_medians(st) -> void:
	for m in data.get("medians", []):
		_dk = int(m.get("dk", -1))
		var grass: bool = m["k"] == "grass"
		_layer = L_GREEN if grass else L_ISLAND
		var col: Color = COL["grass"] if grass else Color("#bdb8ad")
		var y := KERB_UP if grass else Y_ROAD + 0.005
		var s4: Array = m["s"]
		for i in range(0, s4.size() - 7, 4):
			var a := Vector3(s4[i], y, s4[i + 1])
			var b := Vector3(s4[i + 2], y, s4[i + 3])
			var c := Vector3(s4[i + 6], y, s4[i + 7])
			var d := Vector3(s4[i + 4], y, s4[i + 5])
			_quad(st, a, b, c, d, Vector3.UP, col)
	_dk = -1
	_layer = L_GROUND


func _build_kerbs(st) -> void:
	_layer = L_ISLAND
	# Baked edges: the outside (pavement, median) is on the line's right.
	for k in data.get("kerbs", []):
		_dk = int(k.get("dk", -1))
		_kerb(st, _pts(k["p"]), 1.0)
	# Islands: kerbed all round, the face looking out at the road.
	for a in data.get("islands", []):
		_dk = int(a.get("dk", -1))
		var poly := _pts(a["p"])
		if poly.size() < 3:
			continue
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		# With +z south, a clockwise ring seen from above has its inside on the right.
		var cw := _ring_area(poly) > 0.0
		_kerb(st, ring, 1.0 if cw else -1.0)
	_dk = -1
	_layer = L_GROUND


static func _ring_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## A kerb along a polyline: the raised side `side` (1 = right, -1 = left) gets a granite
## top KERB_W wide; the face drops to the road along the line.
func _kerb(st, poly: PackedVector2Array, side: float) -> void:
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		var length := d.length()
		if length < 0.02:
			continue
		var dir := d / length
		var out := Vector2(-dir.y, dir.x) * side
		# Overlap the next piece a little, so corners don't open up.
		var a2 := a - dir * 0.05
		var b2 := b + dir * 0.05
		var pieces := maxi(1, ceili(length / 10.0))
		for k in pieces:
			var p := a2.lerp(b2, float(k) / pieces)
			var q := a2.lerp(b2, float(k + 1) / pieces)
			var po := p + out * KERB_W
			var qo := q + out * KERB_W
			_quad(st, Vector3(p.x, KERB_UP, p.y), Vector3(q.x, KERB_UP, q.y), Vector3(qo.x, KERB_UP, qo.y),
					Vector3(po.x, KERB_UP, po.y), Vector3.UP, KERB_TOP)
		_draped_wall(st, a2, b2, Y_ROAD - 0.02, KERB_UP, -out, KERB_FACE)


## A vertical face laid along the surface from a to b, between heights y0 and y1 above
## it, looking towards `facing` (so it shows from that side only).
func _draped_wall(st, a: Vector2, b: Vector2, y0: float, y1: float, facing: Vector2, col: Color) -> void:
	var n := maxi(1, ceili(a.distance_to(b) / 10.0))
	var normal := Vector3(facing.x, 0.0, facing.y).normalized()
	for k in n:
		var p := a.lerp(b, float(k) / n)
		var q := a.lerp(b, float(k + 1) / n)
		var hp := _surface_height(p.x, p.y)
		var hq := _surface_height(q.x, q.y)
		var v := [Vector3(p.x, hp + y0, p.y), Vector3(q.x, hq + y0, q.y), Vector3(q.x, hq + y1, q.y), Vector3(p.x, hp + y1, p.y)]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			var t0: Vector3 = v[tri[0]]
			var t1: Vector3 = v[tri[1]]
			var t2: Vector3 = v[tri[2]]
			var order := [t0, t1, t2]
			if ((t1 - t0).cross(t2 - t0).dot(normal) > 0.0) == CLOCKWISE_FRONT:
				order = [t0, t2, t1]
			for w in order:
				st.set_color(col)
				st.set_normal(normal)
				st.set_uv(Vector2(_drape_bias, _layer))
				st.set_uv2(Vector2.ZERO)
				st.add_vertex(w)


## Railway ballast with sleepers (the WKD line in its cutting); the rails come later.
func _build_rail_beds(st) -> void:
	_layer = L_BALLAST
	for r in data.get("rails", []):
		_dk = int(r.get("dk", -1))
		_strip(st, _pts(r["p"]), 3.4, Y_PATH, Color("#857d72"))
	_dk = -1
	_layer = L_GROUND


func _build_rails(st) -> void:
	_layer = L_RAIL
	for r in data.get("rails", []):
		_dk = int(r.get("dk", -1))
		var poly := _pts(r["p"])
		for side in [-0.72, 0.72]:
			var rail := PackedVector2Array()
			for i in poly.size():
				var d: Vector2 = (poly[mini(i + 1, poly.size() - 1)] - poly[maxi(i - 1, 0)]).normalized()
				rail.append(poly[i] + Vector2(-d.y, d.x) * side)
			_strip(st, rail, 0.16, Y_MARK + 0.005, Color("#4a4744"))
	_dk = -1
	_layer = L_GROUND


## A solid along a polyline whose foot follows the terrain: hedges, fences, walls,
## platforms drawn as lines. Goes into the building meshes (UV.x < 0: no windows).
func _wall_along(st, poly: PackedVector2Array, width: float, height: float, col: Color, collide: bool) -> void:
	var hw := width * 0.5
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var d := b - a
		if d.length() < 0.05:
			continue
		var dir := d.normalized()
		var side := Vector2(-dir.y, dir.x) * hw
		var ga := terrain_height(a.x, a.y)
		var gb := terrain_height(b.x, b.y)
		var corners := [a + side, b + side, b - side, a - side]
		var g := [ga, gb, gb, ga]
		var top: Array[Vector3] = []
		var bottom: Array[Vector3] = []
		for k in 4:
			var c: Vector2 = corners[k]
			top.append(Vector3(c.x, float(g[k]) + height, c.y))
			bottom.append(Vector3(c.x, float(g[k]) - 0.3, c.y))
		_quad(st, top[0], top[1], top[2], top[3], Vector3.UP, col)
		for k in 4:
			var n := Vector3(corners[(k + 1) % 4].x - corners[k].x, 0, corners[(k + 1) % 4].y - corners[k].y).cross(Vector3.UP).normalized()
			_quad(st, bottom[k], bottom[(k + 1) % 4], top[(k + 1) % 4], top[k], -n, col.darkened(0.08))
		if collide:
			for k in [0, 2]:
				var p0: Vector3 = bottom[k]
				var p1: Vector3 = bottom[(k + 1) % 4]
				var up := Vector3(0, height + 1.5, 0)
				_wall_faces.append_array([p0, p1, p1 + up, p0, p1 + up, p0 + up])


const BARRIER_STYLE := {
	"hedge": ["#4f7d39", 0.9, 1.2],
	"fence": ["#7d838a", 0.12, 1.6],
	"wall": ["#a49d92", 0.35, 1.9],
	"platform": ["#d2cdc3", 2.4, 0.25],
}


func _build_barriers(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for l in data.get("lines", []):
		var style: Array = BARRIER_STYLE.get(l["k"], ["#999999", 0.3, 1.0])
		# Loop 3b: a stop's platform is kerb height (0.25 m), not a wall: like the kerbs and
		# islands, the car drives over it (check_drive.gd found buses brushing them).
		_wall_along(st, _pts(l["p"]), float(style[1]), float(style[2]), Color(style[0]), l["k"] != "platform")
	_uv2 = Vector2.ZERO


## Under every deck piece: its slab (concrete top, underside) and a parapet girder on the
## sides that face out of the structure; sides that face another piece of the same bridge
## reach over to meet it. Loop 3b (R5): the piers are the bake's (`decks.piers`,
## tools/bake_structures.py: slid along the deck clear of the roads, tracks and kerbs under
## it, portal legs where nothing else fits), drawn into the same tile meshes and solid.
func _build_bridge_structures(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var concrete := Color("#b8b2a7")
	for d in _decks:
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var outer: PackedByteArray = d["o"]
		var piers: bool = d["k"] in ["road", "rail"]
		var l := float(d["l"]) + 0.2
		var r := float(d["r"]) + 0.2
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var right := Vector2(-dir.y, dir.x)
			var ya := hs[i] - 0.08
			var yb := hs[i + 1] - 0.08
			var bits := outer[i] & outer[i + 1] if outer.size() > i + 1 else 3
			var lo := l if bits & 1 else l + 1.6
			var ro := r if bits & 2 else r + 1.6
			var al := a - right * lo
			var bl := b - right * lo
			var ar := a + right * ro
			var br := b + right * ro
			# Slab top (shows between the pieces) and underside.
			_quad(st, Vector3(al.x, ya, al.y), Vector3(bl.x, yb, bl.y), Vector3(br.x, yb, br.y), Vector3(ar.x, ya, ar.y), Vector3.UP, concrete.darkened(0.15))
			_quad(st, Vector3(al.x, ya - 1.3, al.y), Vector3(bl.x, yb - 1.3, bl.y), Vector3(br.x, yb - 1.3, br.y), Vector3(ar.x, ya - 1.3, ar.y), Vector3.DOWN, concrete.darkened(0.3))
			for side in [-1.0, 1.0]:
				var is_outer := bool(bits & (1 if side < 0.0 else 2))
				var p0 := al if side < 0.0 else ar
				var p1 := bl if side < 0.0 else br
				var n := Vector3(right.x * side, 0.0, right.y * side)
				var top := 0.55 if is_outer else 0.0
				_quad(st, Vector3(p0.x, ya - 1.3, p0.y), Vector3(p1.x, yb - 1.3, p1.y),
						Vector3(p1.x, yb + top, p1.y), Vector3(p0.x, ya + top, p0.y), n, concrete)
				if is_outer:
					# The parapet's top and inner face.
					var q0: Vector2 = p0 - right * side * 0.3
					var q1: Vector2 = p1 - right * side * 0.3
					_quad(st, Vector3(p0.x, ya + top, p0.y), Vector3(p1.x, yb + top, p1.y), Vector3(q1.x, yb + top, q1.y),
							Vector3(q0.x, ya + top, q0.y), Vector3.UP, concrete.lightened(0.1))
					_quad(st, Vector3(q0.x, ya, q0.y), Vector3(q1.x, yb, q1.y), Vector3(q1.x, yb + top, q1.y),
							Vector3(q0.x, ya + top, q0.y), -n, concrete.darkened(0.05))
					# Solid where there is a drop beside it (loop 3b: where the deck runs within a
					# metre of the ground beside it, as at its ends, the parapet is a kerb to the car).
					var drop := maxf(ya - terrain_height(p0.x, p0.y), yb - terrain_height(p1.x, p1.y))
					if (piers or d["k"] == "path") and drop > 1.0:
						_wall_faces.append_array([Vector3(p0.x, ya - 0.2, p0.y), Vector3(p1.x, yb - 0.2, p1.y), Vector3(p1.x, yb + 1.6, p1.y),
								Vector3(p0.x, ya - 0.2, p0.y), Vector3(p1.x, yb + 1.6, p1.y), Vector3(p0.x, ya + 1.6, p0.y)])
	for p: Dictionary in data.get("decks", {}).get("piers", []):
		_pier(st, p, concrete.darkened(0.1))
	_uv2 = Vector2.ZERO


## Loop 3b (R5): one of the bake's pier boxes (a pier, a portal leg or its cap beam): drawn
## and, for the ones that reach the ground, solid from the ground up (one concave shape,
## like the walls).
func _pier(st, p: Dictionary, col: Color) -> void:
	var c := Vector2(float(p["c"][0]), float(p["c"][1]))
	var dir := Vector2(float(p["d"][0]), float(p["d"][1]))
	var y0 := float(p["y"][0])
	var y1 := float(p["y"][1])
	var across := float(p["s"][0])
	var along := float(p["s"][1])
	_box_oriented(st, Vector3(c.x, (y0 + y1) * 0.5, c.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)),
			Vector3(across, y1 - y0, along), col if p["k"] != "cap" else col.lightened(0.06))
	if p["k"] == "cap":
		return
	var right := Vector2(-dir.y, dir.x)
	var corners: Array[Vector2] = []
	for uv in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(c + dir * uv.x * along * 0.5 + right * uv.y * across * 0.5)
	for k in 4:
		var a := corners[k]
		var b := corners[(k + 1) % 4]
		_wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)])


## Guard rails (bridge edges and mapped barrier=guard_rail): a steel beam on posts,
## solid for the car.
func _build_guard_rails(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var steel := Color("#a7abb0")
	var post := Color("#6c7075")
	for g in data.get("guards", []):
		var poly := _pts(g["p"])
		var dk := int(g.get("dk", -1))
		var run := 0.0
		var next_post := 0.0
		for i in poly.size() - 1:
			var a := poly[i]
			var b := poly[i + 1]
			var length := a.distance_to(b)
			if length < 0.05:
				continue
			var dir := (b - a) / length
			var side := Vector2(-dir.y, dir.x) * 0.06
			var ga := deck_height(dk, a.x, a.y)
			var gb := deck_height(dk, b.x, b.y)
			# The beam: two faces and a top, 0.55-0.85 m up.
			var n := Vector3(side.x, 0, side.y).normalized()
			for sgn in [1.0, -1.0]:
				var o: Vector2 = side * sgn
				_quad(st, Vector3(a.x + o.x, ga + 0.55, a.y + o.y), Vector3(b.x + o.x, gb + 0.55, b.y + o.y),
						Vector3(b.x + o.x, gb + 0.85, b.y + o.y), Vector3(a.x + o.x, ga + 0.85, a.y + o.y), n * sgn, steel)
			_quad(st, Vector3(a.x + side.x, ga + 0.85, a.y + side.y), Vector3(b.x + side.x, gb + 0.85, b.y + side.y),
					Vector3(b.x - side.x, gb + 0.85, b.y - side.y), Vector3(a.x - side.x, ga + 0.85, a.y - side.y), Vector3.UP, steel.lightened(0.15))
			while next_post <= run + length:
				var p := a + dir * (next_post - run)
				var y := lerpf(ga, gb, (next_post - run) / length)
				_box_oriented(st, Vector3(p.x, y + 0.35, p.y), Basis(Vector3.UP, atan2(-dir.x, -dir.y)), Vector3(0.1, 0.7, 0.1), post)
				next_post += 4.0
			run += length
			_wall_faces.append_array([Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb - 0.3, b.y), Vector3(b.x, gb + 1.6, b.y),
					Vector3(a.x, ga - 0.3, a.y), Vector3(b.x, gb + 1.6, b.y), Vector3(a.x, ga + 1.6, a.y)])
	_uv2 = Vector2.ZERO


## Loop 10a: the water's edge, a low granite edge the car can see and can't cross (until
## loop 10a it was an invisible wall along the bake's runs only).
## Where: the bake's `shore` runs (the river's and ponds' edges); the stretches the bake left
## open within 6 m of a bridge deck, wherever the deck over them is at least SHORE_CLEAR up (a
## car on the boulevard under a bridge drove straight into the river there: 9 places, ~210 m),
## plus two short gaps (a road ending at a canal, a seam between two runs); and round every
## fountain (they had no edge at all: 35 places a car drove into). The map's rim stays open:
## the edge walls close it.
## How: the stone is drawn like the kerbs, into the ground's mesh (its material and tiles: no
## draw call, no shadow; under a metre tall), SHORE_UP over the ground on the water's side of
## the line, so the car's bumper meets its face, laid on the ground like the kerbs. The
## collider stands on the line, SHORE_WALL over the ground (under any deck above it), in pieces
## of at most SHORE_PIECE with the ground's height at each end.
const SHORE_W := 0.5
const SHORE_UP := 0.45
const SHORE_WALL := 3.0
const SHORE_PIECE := 2.0
const SHORE_CLEAR := 3.2
const SHORE_TOP := Color("#c9c4b8")
const SHORE_FACE := Color("#8d8a83")
## The runs, each [polyline, water side (+1 left, -1 right)], found once for the stone and the
## collider.
var _shore_lines: Array = []


## The runs of the water's edge (see above): the stone goes into the ground's mesh `st`.
func _build_shore_stone(st) -> void:
	_shore_lines.clear()
	var runs: Array[PackedVector2Array] = []
	for sh in data.get("shore", []):
		runs.append(_pts(sh["p"]))
	var baked := runs.size()
	runs.append_array(_shore_under_decks(runs))
	for poly in runs:
		_shore_lines.append([poly, _water_side(poly)])
	var fountains := 0
	for s in data.get("surfaces", []):
		if s["k"] != "fountain":
			continue
		var ring := _pts(s["p"])
		if ring.size() < 3:
			continue
		ring.append(ring[0])
		# The water is inside the ring: on the left of its way round if it runs anticlockwise
		# (a positive area here).
		_shore_lines.append([ring, 1.0 if _ring_area(ring) > 0.0 else -1.0])
		fountains += 1
	var length := 0.0
	var layer := _layer
	_layer = L_ISLAND
	for line in _shore_lines:
		length += _shore_edge(st, line[0], line[1])
	_layer = layer
	print("shore: %d baked runs, %d more by bridges, %d fountains, %.1f km of edge" % [baked, runs.size() - baked,
			fountains, length / 1000.0])


## The colliders along the runs _build_shore_stone found.
func _build_shore() -> void:
	for line in _shore_lines:
		var poly: PackedVector2Array = line[0]
		for i in poly.size() - 1:
			var a := poly[i]
			var b := poly[i + 1]
			var pieces := maxi(1, ceili(a.distance_to(b) / SHORE_PIECE))
			for k in pieces:
				var p0 := a.lerp(b, float(k) / pieces)
				var p1 := a.lerp(b, float(k + 1) / pieces)
				var g0 := terrain_height(p0.x, p0.y)
				var g1 := terrain_height(p1.x, p1.y)
				var h0 := _shore_wall_top(p0, g0)
				var h1 := _shore_wall_top(p1, g1)
				_wall_faces.append_array([Vector3(p0.x, g0 - 1.0, p0.y), Vector3(p1.x, g1 - 1.0, p1.y), Vector3(p1.x, h1, p1.y),
						Vector3(p0.x, g0 - 1.0, p0.y), Vector3(p1.x, h1, p1.y), Vector3(p0.x, h0, p0.y)])


## Which side of a run the water is on: +1 left (the side Vector2(-d.y, d.x) points to), -1
## right; by the surface map a metre and a half either side of each segment.
func _water_side(poly: PackedVector2Array) -> float:
	var vote := 0.0
	for i in poly.size() - 1:
		var d := poly[i + 1] - poly[i]
		if d.length() < 0.05:
			continue
		var m := (poly[i] + poly[i + 1]) * 0.5
		var left := Vector2(-d.y, d.x).normalized() * 1.5
		vote += (shore_distance(m.x + left.x, m.y + left.y) - shore_distance(m.x - left.x, m.y - left.y)) * d.length()
	return 1.0 if vote >= 0.0 else -1.0


## The edge stone along one run, draped on the ground (the caller sets the drape bias and the
## layer); returns its length.
func _shore_edge(st, poly: PackedVector2Array, side: float) -> float:
	var n := poly.size()
	if n < 2:
		return 0.0
	# Mitred offsets towards the water at every point, so the stone keeps its width round bends.
	var off := PackedVector2Array()
	off.resize(n)
	var closed := poly[0].distance_to(poly[n - 1]) < 0.05
	for i in n:
		var prev := i - 1 if i > 0 else (n - 2 if closed else -1)
		var next := i + 1 if i < n - 1 else (1 if closed else -1)
		var na := Vector2.ZERO
		var nb := Vector2.ZERO
		if prev >= 0 and poly[i].distance_to(poly[prev]) > 0.01:
			var d := (poly[i] - poly[prev]).normalized()
			na = Vector2(-d.y, d.x)
		if next >= 0 and poly[next].distance_to(poly[i]) > 0.01:
			var d := (poly[next] - poly[i]).normalized()
			nb = Vector2(-d.y, d.x)
		var m := na + nb
		if m.length() < 0.01:
			m = na if na != Vector2.ZERO else nb
		m = m.normalized()
		var cos_half := maxf(m.dot(nb if nb != Vector2.ZERO else na), 0.4)
		off[i] = m * (SHORE_W * side / cos_half)
	var length := 0.0
	for i in n - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.05:
			continue
		length += seg
		var dir := (b - a) / seg
		var land := Vector2(-dir.y, dir.x) * -side
		# One piece per segment: the drape lays it on the ground in pieces of the terrain grid.
		var qa := a + off[i]
		var qb := b + off[i + 1]
		_quad(st, Vector3(a.x, SHORE_UP, a.y), Vector3(b.x, SHORE_UP, b.y), Vector3(qb.x, SHORE_UP, qb.y),
				Vector3(qa.x, SHORE_UP, qa.y), Vector3.UP, SHORE_TOP)
		_draped_wall(st, a, b, 0.0, SHORE_UP, land, SHORE_FACE)
		_draped_wall(st, qa, qb, 0.0, SHORE_UP, -land, SHORE_FACE.darkened(0.12))
		if i == 0 and not closed:
			_draped_wall(st, a, a + off[0], 0.0, SHORE_UP, -dir, SHORE_FACE)
		if i == n - 2 and not closed:
			_draped_wall(st, b, b + off[n - 1], 0.0, SHORE_UP, dir, SHORE_FACE)
	return length


## The shore collider's top at a point: SHORE_WALL over the ground, or under the lowest deck
## over it (a car on the deck must never touch it).
func _shore_wall_top(p: Vector2, g: float) -> float:
	var top := g + SHORE_WALL
	for d in _decks_at(p.x, p.y):
		if d > g:
			top = minf(top, d - 1.4)
	return maxf(top, g + 1.6)


## The water's edge the bake left open near bridge decks (and in a few short gaps), where the
## deck over it is high enough to drive under: runs of points a metre apart, each run reaching
## a metre into the baked edge on both ends. Not at the map's rim (the edge walls close it).
func _shore_under_decks(baked: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	const CELL := 8.0
	var grid := {}
	for poly in baked:
		for i in poly.size() - 1:
			var lo := poly[i].min(poly[i + 1]) - Vector2.ONE
			var hi := poly[i].max(poly[i + 1]) + Vector2.ONE
			for cz in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
				for cx in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
					var key := Vector2i(cx, cz)
					var list: PackedVector2Array = grid.get(key, PackedVector2Array())
					list.append_array(PackedVector2Array([poly[i], poly[i + 1]]))
					grid[key] = list
	var inner := bounds.grow(-1.0)
	var out: Array[PackedVector2Array] = []
	for a in data["areas"]:
		if a["k"] != "water":
			continue
		var ring := _pts(a["p"])
		var samples := PackedVector2Array()
		for i in ring.size():
			var p := ring[i]
			var q := ring[(i + 1) % ring.size()]
			var steps := maxi(1, ceili(p.distance_to(q)))
			for k in steps:
				samples.append(p.lerp(q, float(k) / steps))
		# open[k]: wall this sample (not covered, not the rim, nothing low overhead).
		var open := PackedByteArray()
		open.resize(samples.size())
		var start := -1
		for k in samples.size():
			var p := samples[k]
			var want := inner.has_point(p) and not _near_segments(grid, CELL, p, 0.75)
			if want:
				var g := terrain_height(p.x, p.y)
				for d in _decks_at(p.x, p.y):
					if d > g - 0.5 and d < g + SHORE_CLEAR:
						want = false
			open[k] = 1 if want else 0
			if not want and start < 0:
				start = k
		if start < 0:
			# Nothing baked round this water at all: the whole ring.
			ring.append(ring[0])
			out.append(ring)
			continue
		var run := PackedVector2Array()
		var count := samples.size()
		for j in count + 1:
			var k := (start + j) % count
			if open[k] == 1:
				if run.is_empty():
					run.append(samples[(k - 1 + count) % count])
				run.append(samples[k])
			elif not run.is_empty():
				run.append(samples[k])
				if run.size() >= 3:
					out.append(run)
				run = PackedVector2Array()
	return out


static func _near_segments(grid: Dictionary, cell: float, p: Vector2, reach: float) -> bool:
	var segs: PackedVector2Array = grid.get(Vector2i(floori(p.x / cell), floori(p.y / cell)), PackedVector2Array())
	for i in range(0, segs.size(), 2):
		var a := segs[i]
		var ab := segs[i + 1] - a
		var l2 := ab.length_squared()
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0) if l2 > 0.000001 else 0.0
		if p.distance_to(a + ab * t) < reach:
			return true
	return false


func _box_oriented(st, centre: Vector3, basis: Basis, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var n := Vector3.ZERO
			n[axis] = sgn
			var u := Vector3.ZERO
			u[(axis + 1) % 3] = h[(axis + 1) % 3]
			var v := Vector3.ZERO
			v[(axis + 2) % 3] = h[(axis + 2) % 3]
			var c := n * h[axis]
			_quad(st, centre + basis * (c - u - v), centre + basis * (c + u - v), centre + basis * (c + u + v),
					centre + basis * (c - u + v), basis * n, col)


## Tram and bus stop islands and railway platforms: raised concrete slabs.
func _build_platforms(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	for a in data.get("platforms", []):
		var poly := _pts(a["p"])
		if poly.size() < 3:
			continue
		var h := float(a["h"])
		var ground := INF
		for q in poly:
			ground = minf(ground, terrain_height(q.x, q.y))
		var col := Color("#d4cfc5")
		_fill(st, poly, ground + h + 0.1, col)
		for i in poly.size():
			var p0 := poly[i]
			var p1 := poly[(i + 1) % poly.size()]
			var e := p1 - p0
			if e.length() < 0.05:
				continue
			var n := Vector3(e.y, 0.0, -e.x).normalized()
			_quad(st, Vector3(p0.x, ground - 0.3, p0.y), Vector3(p1.x, ground - 0.3, p1.y),
					Vector3(p1.x, ground + h + 0.1, p1.y), Vector3(p0.x, ground + h + 0.1, p0.y), n, col.darkened(0.12))
	_uv2 = Vector2.ZERO


## Cycle crossings in red across the road, and zebra stripes on pedestrian crossings.
func _build_crossings(st) -> void:
	var keep_bias := _drape_bias
	_layer = L_CYCLE
	_drape_bias = keep_bias - 0.02
	for p in data["paths"]:
		if p["k"] == "cyclecross":
			_dk = int(p.get("dk", -1))
			_strip(st, _pts(p["p"]), 2.2, Y_MARK, COL["cycle"])
	_drape_bias = keep_bias
	_layer = L_MARK
	for p in data["paths"]:
		if p["k"] != "zebra":
			continue
		_dk = int(p.get("dk", -1))
		var poly := _pts(p["p"])
		for i in poly.size() - 1:
			var a := poly[i]
			var seg := poly[i + 1] - a
			var length := seg.length()
			if length < 1.0:
				continue
			var dir := seg / length
			var t := 0.6
			while t < length - 0.4:
				var c := a + dir * t
				_strip(st, PackedVector2Array([c - dir * 0.25, c + dir * 0.25]), 3.6, Y_MARK, COL["mark"], false)
				t += 1.0
	_dk = -1


## Painted lines (tools/bake_roads.py), already cut where other roads cross: edge
## lines, lane lines (dashed), solid centre lines, stop lines, the bus lanes' wide
## line, cycle lanes (line and red surface), hatching stripes.
const MARK_STYLE := {
	"edge": [0.0, 0.2], "lane": [3.0, 0.22], "centre": [0.0, 0.2], "stop": [0.0, 0.5],
	"bus": [0.0, 0.3], "cycle": [0.0, 0.18], "stripe": [0.0, 0.45],
}


func _build_markings(st) -> void:
	var keep_bias := _drape_bias
	for m in data.get("markings", []):
		var poly := _pts(m["p"])
		_dk = int(m.get("dk", -1))
		var kind: String = m["k"]
		if kind == "cyclefill":
			# Under the white lines: a touch lower in the depth order.
			_layer = L_CYCLE
			_drape_bias = keep_bias - 0.015
			_strip(st, poly, float(m.get("w", 1.4)), Y_MARK - 0.005, COL["cycle"], false)
			_drape_bias = keep_bias
			continue
		_layer = L_MARK
		var style: Array = MARK_STYLE.get(kind, [0.0, 0.2])
		if float(style[0]) > 0.0:
			_dashes(st, poly, 0.0, float(style[0]), 5.0, float(style[1]))
		else:
			_dashes(st, poly, 0.0, 1000000.0, 0.0, float(style[1]))
	_dk = -1
	_layer = L_GROUND


## Turn arrows, BUS and bike symbols painted on the road, from pixel shapes: rows of
## "#" (paint) and "." whose top row lies furthest along the direction of travel and
## whose columns run across the lane, left to right as the driver sees them.
const ARROW_T := [
	"..#..", ".###.", "#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..",
]
const ARROW_L := [
	"..#......", ".##......", "#######..", ".##...#..", "..#...#..", "......#..", "......#..", "......#..",
	"......#..", "......#..",
]
const ARROW_TL := [
	"......#..", ".....###.", "....#####", "......#..", "..#...#..", ".##...#..", "#######..", ".##...#..",
	"..#...#..", "......#..",
]
const ARROW_LR := [
	"..#.....#..", ".##.....##.", "###########", ".##..#..##.", "..#..#..#..", ".....#.....", ".....#.....",
	".....#.....", ".....#.....", ".....#.....",
]
const ARROW_LTR := [
	".....#.....", "....###....", "...#####...", ".....#.....", "..#..#..#..", ".##..#..##.", "###########",
	".##..#..##.", "..#..#..#..", ".....#.....",
]
const BIKE := [
	"....##..", "...#..#.", ".###....", "#..#.##.", "#..##..#", "#.#.#..#", ".#...##.",
]
const BUS_TEXT := [
	"###..#..#..###", "#..#.#..#.#...", "###..#..#..##.", "#..#.#..#....#", "###...##..###.",
]


func _build_symbols(st) -> void:
	_layer = L_MARK
	for m in data.get("symbols", []):
		_dk = int(m.get("dk", -1))
		var at := Vector2(m["x"], m["z"])
		var d: Array = m["d"]
		var fwd := Vector2(d[0], d[1]).normalized()
		match String(m["k"]):
			"arrow":
				var rows: Array = ARROW_T
				var mirror := false
				match String(m["t"]):
					"L":
						rows = ARROW_L
					"R":
						rows = ARROW_L
						mirror = true
					"LT":
						rows = ARROW_TL
					"TR":
						rows = ARROW_TL
						mirror = true
					"LR":
						rows = ARROW_LR
					"LTR":
						rows = ARROW_LTR
				_pixel_shape(st, rows, at, fwd, minf(0.3, 2.4 / String(rows[0]).length()), 0.5, mirror)
			"bike":
				_pixel_shape(st, BIKE, at, fwd, 0.16, 0.2, false)
			"bus":
				_pixel_shape(st, BUS_TEXT, at, fwd, 0.19, 0.5, false)
	_dk = -1
	_layer = L_GROUND


## A pixel shape on the road centred on `at`, its top row towards `fwd`; cells `cw`
## wide (across the road) and `cl` long (along it); `mirror` flips it left to right.
func _pixel_shape(st, rows: Array, at: Vector2, fwd: Vector2, cw: float, cl: float, mirror: bool) -> void:
	var right := Vector2(-fwd.y, fwd.x)
	var h := rows.size()
	var w := String(rows[0]).length()
	for j in h:
		var row := String(rows[j])
		var i := 0
		while i < w:
			if row[i] != "#":
				i += 1
				continue
			# A run of paint in a row becomes one rectangle.
			var i1 := i
			while i1 + 1 < w and row[i1 + 1] == "#":
				i1 += 1
			var x0 := float(i) - w * 0.5
			var x1 := float(i1 + 1) - w * 0.5
			if mirror:
				var t := -x1
				x1 = -x0
				x0 = t
			var y0 := h * 0.5 - float(j + 1)
			var y1 := h * 0.5 - float(j)
			var c: Array[Vector2] = []
			for corner in [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]:
				c.append(at + right * (corner.x * cw) + fwd * (corner.y * cl))
			_quad(st, Vector3(c[0].x, Y_MARK, c[0].y), Vector3(c[1].x, Y_MARK, c[1].y),
					Vector3(c[2].x, Y_MARK, c[2].y), Vector3(c[3].x, Y_MARK, c[3].y), Vector3.UP, COL["mark"])
			i = i1 + 1


func _dashes(st, poly: PackedVector2Array, offset: float, on: float, off: float, width: float) -> void:
	var phase := 0.0
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := b - a
		var length := seg.length()
		if length < 0.01:
			continue
		var dir := seg / length
		var side := Vector2(-dir.y, dir.x)
		a += side * offset
		var t := -phase
		while t < length:
			var s0 := maxf(t, 0.0)
			var s1 := minf(t + on, length)
			if s1 > s0:
				var dash := PackedVector2Array([a + dir * s0, a + dir * s1])
				_strip(st, dash, width, Y_MARK, COL["mark"], false)
			t += on + off
		phase = fposmod(phase + length, on + off)


func _build_trams(st) -> void:
	_layer = L_RAIL
	for t in data["trams"]:
		var poly := _pts(t["p"])
		_dk = int(t.get("dk", -1))
		for side in [-0.72, 0.72]:
			var rail := PackedVector2Array()
			for i in poly.size():
				var d: Vector2
				if i < poly.size() - 1:
					d = (poly[i + 1] - poly[i]).normalized()
				else:
					d = (poly[i] - poly[i - 1]).normalized()
				rail.append(poly[i] + Vector2(-d.y, d.x) * side)
			_strip(st, rail, 0.22, Y_MARK + 0.005, COL["rail"])
	_dk = -1


func _build_buildings(st, keep: Array, marks) -> void:
	var list: Array = data["buildings"]
	var drawn: Array[int] = []
	for index in (keep if _has_lod2 else range(list.size())):
		var bld: Dictionary = list[int(index)]
		if (bld["p"] as Array).size() < 6 or bld.has("br") or bld.has("cutd"):
			continue  # a 3D-mapped bridge (the decks draw it), or left out under a deck (loop 3b)
		if not marks.keeps_building(bld):
			continue  # a landmark (landmarks.gd) stands here
		if float(bld["h"]) <= float(bld["mh"]):
			continue
		drawn.append(int(index))
	var bottoms := _part_bottoms(list, drawn, marks)
	for index in drawn:
		var bld: Dictionary = list[index]
		var poly := _pts(bld["p"])
		var h := float(bld["h"])
		var mh := float(bottoms.get(index, bld["mh"]))
		if mh < 0.0:
			continue  # a tiny floating bit (_part_bottoms)
		var ground := INF
		for q in poly:
			ground = minf(ground, terrain_height(q.x, q.y))
		if bld.has("pil"):
			# Loop 3b: a viaduct's mapped pillar, fitted to the slab it carries.
			h = float(bld["cut"]) - ground
		elif bld.has("cut"):
			# Loop 3b: under a deck, cut to the slab's bottom - 0.5 m (tools/bake_structures.py).
			h = minf(h, float(bld["cut"]) - ground)
		var hsh := absi(int(poly[0].x * 73.0 + poly[0].y * 31.0))
		var glass := h > 55.0
		var wall := _osm_colour(bld["c"], Color(GLASS[hsh % GLASS.size()] if glass else FACADES[hsh % FACADES.size()]))
		var roof := _osm_colour(bld["rc"], Color(ROOFS[hsh % ROOFS.size()]))
		if glass and str(bld["rc"]) == "":
			roof = wall.darkened(0.25)
		# Alpha tells the building shader which window pattern to draw.
		wall.a = 0.5 if glass else 1.0
		_uv2 = Vector2(fposmod(hsh * 0.6180339887, 1.0), h)

		var run := 0.0
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var edge := b - a
			var length := edge.length()
			if length < 0.05:
				continue
			# Polygons are counter-clockwise in x/z, so the outward normal is to the right.
			var n := Vector3(edge.y, 0.0, -edge.x).normalized()
			var bottom := ground + mh - (0.4 if mh < 0.5 else 0.0)
			var p0 := Vector3(a.x, bottom, a.y)
			var p1 := Vector3(b.x, bottom, b.y)
			var p2 := Vector3(b.x, ground + h, b.y)
			var p3 := Vector3(a.x, ground + h, a.y)
			var base_col := wall.darkened(0.12) if mh < 1.0 else wall
			var u0 := Vector2(run, mh)
			var u1 := Vector2(run + length, mh)
			var u2 := Vector2(run + length, h)
			var u3 := Vector2(run, h)
			_tri_shaded(st, p0, p1, p2, n, base_col, base_col, wall, u0, u1, u2)
			_tri_shaded(st, p0, p2, p3, n, base_col, wall, wall, u0, u2, u3)
			run += length
			if mh < 2.0:
				var g0 := ground - 1.0
				# Loop 3b: never over the building's own top (a viaduct's pillar ends under its slab).
				var g1 := ground + minf(5.0, h)
				_wall_faces.append_array([Vector3(a.x, g0, a.y), Vector3(b.x, g0, b.y), Vector3(b.x, g1, b.y),
						Vector3(a.x, g0, a.y), Vector3(b.x, g1, b.y), Vector3(a.x, g1, a.y)])
		_uv2 = Vector2(_uv2.x, -1.0)
		_fill(st, poly, ground + h, roof)
		_roof_polygon(poly, ground + h)
	_uv2 = Vector2.ZERO


## Loop 1: OpenStreetMap building parts that would float. A part is drawn from its
## min_height up; where the parts under it are not mapped (Varso 2's 80-90 m top hung over
## nothing, a "broken lamp post" from the south-west), it hangs in the air. A part that
## starts FLOAT_MIN or more up (lower ones are real: canopies, passages, pilotis) and rests on something under less than half of its
## footprint (another drawn part reaching to within FLOAT_GAP of its bottom, or, within
## FLOAT_SLACK, a LoD2 building or a landmark: those outlines differ a little from
## OpenStreetMap's) is lowered to the highest roof below it that carries at least half of
## it, or to the ground; a tiny one (under FLOAT_TINY m2: a mast's or a sign's bits, the
## spire of a tower that stands off the map) is left out instead. Lowest parts first, so a
## part resting on a left-out one is judged without it. Returns index -> new bottom in
## metres (-1: left out); `floating_parts` / `floating_to_ground` / `floating_dropped` count.
const FLOAT_MIN := 10.0
const FLOAT_GAP := 3.0
const FLOAT_SLACK := 2.5
const FLOAT_TINY := 12.0
const FLOAT_CELL := 32.0
var floating_parts := 0
var floating_to_ground := 0
var floating_dropped := 0


func _part_bottoms(list: Array, drawn: Array[int], marks) -> Dictionary:
	var out := {}
	var polys := {}
	var boxes := {}
	var grid := {}
	for index in drawn:
		var poly := _pts(list[index]["p"])
		var box := _poly_box(poly)
		polys[index] = poly
		boxes[index] = box
		_grid_add(grid, box, index)
	# LoD2 buildings stand on the ground and carry what sits on them: negative keys.
	var lod := {}
	for k in _lod2_footprints.size():
		var poly := _pts(_lod2_footprints[k])
		if poly.size() < 3:
			continue
		var box := _poly_box(poly)
		lod[-1 - k] = poly
		boxes[-1 - k] = box
		_grid_add(grid, box, -1 - k)
	var high: Array[int] = []
	for index in drawn:
		if float(list[index]["mh"]) >= FLOAT_MIN:
			high.append(index)
	high.sort_custom(func(a: int, b: int) -> bool: return float(list[a]["mh"]) < float(list[b]["mh"]))
	for index in high:
		var mh := float(list[index]["mh"])
		var poly: PackedVector2Array = polys[index]
		var box: Rect2 = boxes[index]
		# Up to 8 x 8 points over the footprint.
		var step := maxf(1.0, maxf(box.size.x, box.size.y) / 8.0)
		var samples := PackedVector2Array()
		var y := box.position.y + step * 0.5
		while y < box.end.y:
			var x := box.position.x + step * 0.5
			while x < box.end.x:
				if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
					samples.append(Vector2(x, y))
				x += step
			y += step
		if samples.is_empty():
			samples.append(box.get_center())
		var under: Array[int] = []
		var seen := {}
		var near := box.grow(FLOAT_SLACK)
		for key in _grid_keys(near):
			for j in grid.get(key, []):
				if j == index or seen.has(j) or not (boxes[j] as Rect2).intersects(near):
					continue
				seen[j] = true
				if j < 0 or (float(list[j]["mh"]) < mh and float(out.get(j, 0.0)) >= 0.0):
					under.append(j)
		if _carried(list, samples, under, polys, lod, marks, mh) >= 0.5:
			continue
		floating_parts += 1
		if absf(_poly_area(poly)) < FLOAT_TINY:
			out[index] = -1.0
			floating_dropped += 1
			continue
		var tops: Array[float] = []
		for j in under:
			if j >= 0 and float(list[j]["h"]) < mh and not tops.has(float(list[j]["h"])):
				tops.append(float(list[j]["h"]))
		tops.sort()
		tops.reverse()
		var bottom := 0.0
		for t in tops:
			if t >= FLOAT_MIN and _carried(list, samples, under, polys, lod, marks, t) >= 0.5:
				bottom = t
				break
		out[index] = bottom
		if bottom == 0.0:
			floating_to_ground += 1
	return out


## The share of `samples` resting on something at `level`: a part that starts below it and
## reaches up to within FLOAT_GAP of it, or (within FLOAT_SLACK) a LoD2 building or a landmark.
func _carried(list: Array, samples: PackedVector2Array, under: Array[int], polys: Dictionary, lod: Dictionary, marks, level: float) -> float:
	var held := 0
	var slack: Array[Vector2] = [Vector2.ZERO, Vector2(FLOAT_SLACK, 0), Vector2(-FLOAT_SLACK, 0), Vector2(0, FLOAT_SLACK), Vector2(0, -FLOAT_SLACK)]
	for q in samples:
		var ok := false
		for j in under:
			if j < 0:
				for o in slack:
					if Geometry2D.is_point_in_polygon(q + o, lod[j]):
						ok = true
						break
			elif float(list[j]["mh"]) < level and float(list[j]["h"]) >= level - FLOAT_GAP \
					and Geometry2D.is_point_in_polygon(q, polys[j]):
				ok = true
			if ok:
				break
		if not ok:
			for o in slack:
				if marks.replaces(q + o):
					ok = true
					break
		if ok:
			held += 1
	return float(held) / float(samples.size())


static func _poly_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


static func _poly_box(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	return box


static func _grid_keys(box: Rect2) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for i in range(floori(box.position.x / FLOAT_CELL), floori(box.end.x / FLOAT_CELL) + 1):
		for j in range(floori(box.position.y / FLOAT_CELL), floori(box.end.y / FLOAT_CELL) + 1):
			keys.append(Vector2i(i, j))
	return keys


static func _grid_add(grid: Dictionary, box: Rect2, index: int) -> void:
	for key in _grid_keys(box):
		if not grid.has(key):
			grid[key] = []
		grid[key].append(index)


## GUGiK LoD2 buildings from the baked mesh. Returns the OpenStreetMap
## buildings that still need drawing (empty when there is no LoD2 bake).
func _build_lod2(walls, marks) -> Array:
	if not FileAccess.file_exists("res://map/lod2.bin"):
		return []
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://map/lod2.json"))
	_lod2_footprints = meta.get("footprints", [])
	var bytes := FileAccess.get_file_as_bytes("res://map/lod2.bin")
	var count := bytes.decode_u32(0)
	var f := bytes.slice(4).to_float32_array()
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var col := PackedColorArray()
	var uv := PackedVector2Array()
	pos.resize(count)
	nrm.resize(count)
	col.resize(count)
	uv.resize(count)
	var uv2 := PackedVector2Array()
	uv2.resize(count)
	var o_n := count * 3
	var o_c := count * 6
	var o_u := count * 10
	var o_u2 := count * 12
	for i in count:
		var k := i * 3
		pos[i] = Vector3(f[k], f[k + 1], f[k + 2])
		nrm[i] = Vector3(f[o_n + k], f[o_n + k + 1], f[o_n + k + 2])
		var c := o_c + i * 4
		col[i] = Color(f[c], f[c + 1], f[c + 2], f[c + 3])
		uv[i] = Vector2(f[o_u + i * 2], f[o_u + i * 2 + 1])
		uv2[i] = Vector2(f[o_u2 + i * 2], f[o_u2 + i * 2 + 1])
	# Loop 3b: LoD2 buildings under a bridge deck, cut to the slab's bottom - 0.5 m or left
	# out (tools/bake_structures.py `lod2_cuts`; the Poniatowski viaduct's arcades).
	var cuts: Array = data.get("lod2_cuts", [])
	if not cuts.is_empty():
		var clipped := _clip_lod2(pos, nrm, col, uv, uv2, cuts)
		pos = clipped[0]
		nrm = clipped[1]
		col = clipped[2]
		uv = clipped[3]
		uv2 = clipped[4]
		count = pos.size()
	# v0.8: whole LoD2 buildings that stand where a landmark is built are left out. The
	# bake writes each building's triangles in one run sharing its style seed (UV2.x).
	var dropped := PackedByteArray()
	dropped.resize(count / 3)
	var t0 := 0
	while t0 < count:
		var seed := uv2[t0].x
		var first := Vector2(pos[t0].x, pos[t0].z)
		var lo := first
		var hi := first
		var t1 := t0
		while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
			for k in 3:
				var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
				lo = lo.min(q)
				hi = hi.max(q)
			t1 += 3
		if marks.replaces((lo + hi) * 0.5):
			for t in range(t0, t1, 3):
				dropped[t / 3] = 1
		t0 = t1
	# Split into tiles by triangle, like the other city meshes.
	var tiles := {}
	for t in range(0, count, 3):
		if dropped[t / 3]:
			continue
		var centre := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
		var key := Chunked.tile_of(centre)
		if not tiles.has(key):
			tiles[key] = [[], [], [], [], []]
		var tile: Array = tiles[key]
		for k in 3:
			(tile[0] as Array).append(pos[t + k])
			(tile[1] as Array).append(nrm[t + k])
			(tile[2] as Array).append(col[t + k])
			(tile[3] as Array).append(uv[t + k])
			(tile[4] as Array).append(uv2[t + k])
	# Loop 2b: into the walls' tile meshes (same material): one draw call per tile, not two.
	for key in tiles:
		var tile: Array = tiles[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(tile[0])
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(tile[1])
		arrays[Mesh.ARRAY_COLOR] = PackedColorArray(tile[2])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(tile[3])
		arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(tile[4])
		walls.add_arrays(key, arrays)
	# Walls are what the car bumps into; roofs (and wall tops) are what the helicopter can't fly through.
	# Loop 3b: not where a wall stands in a lane (`lod2_open`, tools/bake_structures.py).
	var open: Array = data.get("lod2_open", [])
	for t in range(0, count, 3):
		if dropped[t / 3]:
			continue
		var flat_ish := absf(nrm[t].y) >= 0.3
		if not flat_ish:
			var solid := true
			if not open.is_empty():
				var c := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
				for o: Array in open:
					if absf(c.x - float(o[0])) < float(o[2]) and absf(c.z - float(o[1])) < float(o[2]):
						solid = false
						break
			if solid:
				_wall_faces.append_array([pos[t], pos[t + 1], pos[t + 2]])
		_roof_triangle(pos[t], pos[t + 1], pos[t + 2], flat_ish)
	_has_lod2 = true
	return meta["keep_osm"]


## Loop 3b: the LoD2 triangles with the cut buildings clipped. A building is a run of
## triangles sharing its style seed (as `_build_lod2` finds them); a run whose box centre is a
## cut's ([x, z, top, left out]) loses everything over the top: walls are clipped at it, roof
## triangles over it are laid flat at it (they cover the footprint, so the cut is closed).
func _clip_lod2(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array, cuts: Array) -> Array:
	var o_pos := PackedVector3Array()
	var o_nrm := PackedVector3Array()
	var o_col := PackedColorArray()
	var o_uv := PackedVector2Array()
	var o_uv2 := PackedVector2Array()
	var count := pos.size()
	var t0 := 0
	var n_cut := 0
	while t0 < count:
		var seed := uv2[t0].x
		var first := Vector2(pos[t0].x, pos[t0].z)
		var lo := first
		var hi := first
		var t1 := t0
		while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
			for k in 3:
				var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
				lo = lo.min(q)
				hi = hi.max(q)
			t1 += 3
		var centre := (lo + hi) * 0.5
		var cut := INF
		var drop := false
		for c: Array in cuts:
			if absf(float(c[0]) - centre.x) < 0.3 and absf(float(c[1]) - centre.y) < 0.3:
				cut = float(c[2])
				drop = int(c[3]) == 1
				break
		if drop:
			n_cut += 1
		elif cut == INF:
			o_pos.append_array(pos.slice(t0, t1))
			o_nrm.append_array(nrm.slice(t0, t1))
			o_col.append_array(col.slice(t0, t1))
			o_uv.append_array(uv.slice(t0, t1))
			o_uv2.append_array(uv2.slice(t0, t1))
		else:
			n_cut += 1
			for t in range(t0, t1, 3):
				var roof := nrm[t].y >= 0.3
				var below: Array = []   # [pos, colour, uv] corners of the part under the cut
				var above: Array = []
				for k in 3:
					var a := t + k
					var b := t + (k + 1) % 3
					var a_up := pos[a].y > cut
					var b_up := pos[b].y > cut
					(above if a_up else below).append([pos[a], col[a], uv[a]])
					if a_up != b_up:
						var f := (cut - pos[a].y) / (pos[b].y - pos[a].y)
						var corner := [pos[a].lerp(pos[b], f), col[a].lerp(col[b], f), uv[a].lerp(uv[b], f)]
						below.append(corner)
						above.append(corner)
				for pi in (2 if roof else 1):
					var part: Array = below if pi == 0 else above
					var flat := pi == 1
					for k in range(1, part.size() - 1):
						for v: Array in [part[0], part[k], part[k + 1]]:
							var p: Vector3 = v[0]
							o_pos.append(Vector3(p.x, cut, p.z) if flat else p)
							o_nrm.append(Vector3.UP if flat else nrm[t])
							o_col.append(v[1])
							o_uv.append(v[2])
							o_uv2.append(uv2[t])
		t0 = t1
	print("lod2: %d buildings cut under a deck (loop 3b)" % n_cut)
	return [o_pos, o_nrm, o_col, o_uv, o_uv2]


## Like _tri, but with a colour per corner (walls darken towards the ground).
func _tri_shaded(st, a: Vector3, b: Vector3, c: Vector3, n: Vector3,
		ca: Color, cb: Color, cc: Color, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var facing_viewer := (b - a).cross(c - a).dot(n) > 0.0
	var verts := [[a, ca, ua], [b, cb, ub], [c, cc, uc]]
	if facing_viewer == CLOCKWISE_FRONT:
		verts = [verts[0], verts[2], verts[1]]
	for v in verts:
		st.set_color(v[1])
		st.set_normal(n)
		st.set_uv(v[2])
		st.set_uv2(_uv2)
		st.add_vertex(v[0])


func _osm_colour(value, fallback: Color) -> Color:
	var s := str(value).strip_edges().to_lower().replace("grey", "gray")
	if s == "":
		return fallback
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	if c.a == 0.0:
		return fallback
	# Pull mapped colours slightly towards the palette so the city reads as one piece.
	return c.lerp(fallback, 0.3)


func _build_trees() -> void:
	var list: Array = data.get("trees", [])
	var canopy: Array = CANOPY_AUTUMN if season == "autumn" else CANOPY_SUMMER
	var all_spots: Array[Transform3D] = []
	var broad: Array[Transform3D] = []
	var broad_col: Array[Color] = []
	var needle: Array[Transform3D] = []
	var needle_col: Array[Color] = []
	for i in range(0, list.size() - 3, 4):
		var x := float(list[i])
		var z := float(list[i + 1])
		var s := float(list[i + 2])
		var h := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
		var t := Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(s, s * (0.9 + h * 0.3), s)), Vector3(x, terrain_height(x, z) - 0.2, z))
		all_spots.append(t)
		if int(list[i + 3]) == 1:
			needle.append(t)
			needle_col.append(Color(NEEDLE[int(h * 100.0) % NEEDLE.size()]))
		else:
			broad.append(t)
			broad_col.append(Color(canopy[int(h * 1000.0) % canopy.size()]))

	# GUGiK trees from the 2023 laser scan: each crown is stretched to the tree's real
	# radius and spans its real crown base to its top; the trunk fills the gap below.
	var real: Array = data.get("trees3d", [])
	var real_trunks: Array[Transform3D] = []
	for i in range(0, real.size() - 5, 6):
		var x := float(real[i])
		var z := float(real[i + 1])
		var top := float(real[i + 2])
		var radius := float(real[i + 3])
		var base := minf(float(real[i + 4]), top - 1.5)
		var is_needle := int(real[i + 5]) == 1
		var h := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
		var ground := terrain_height(x, z) - 0.2
		# Crown meshes in model space: broadleaf spans y 2.09-6.51 at radius 2.3, conifer 1.6-7.4 at 2.2.
		var low := 1.6 if is_needle else 2.09
		var sy := (top - base) / (5.8 if is_needle else 4.42)
		var sxz := clampf(radius / (2.2 if is_needle else 2.3), 0.45, 7.0)
		var t := Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(sxz, sy, sxz)),
				Vector3(x, ground + base - low * sy, z))
		if is_needle:
			needle.append(t)
			needle_col.append(Color(NEEDLE[int(h * 100.0) % NEEDLE.size()]))
		else:
			broad.append(t)
			broad_col.append(Color(canopy[int(h * 1000.0) % canopy.size()]))
		var trunk_h := base + (top - base) * 0.3
		var girth := clampf(0.55 + top / 28.0, 0.6, 1.7)
		real_trunks.append(Transform3D(Basis(Vector3.UP, h * TAU).scaled(Vector3(girth, trunk_h / 2.8, girth)),
				Vector3(x, ground + trunk_h * 0.5, z)))

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.3
	trunk.height = 2.8
	trunk.radial_segments = 5
	trunk.rings = 1
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("#5e4636")
	var lifted: Array[Transform3D] = []
	for t in all_spots:
		lifted.append(Transform3D(t.basis, t.origin + Vector3(0, 1.4 * t.basis.get_scale().y, 0)))
	lifted.append_array(real_trunks)
	var no_colours: Array[Color] = []
	_tree_multimesh(trunk, trunk_mat, lifted, no_colours)

	leaf_material = ShaderMaterial.new()
	leaf_material.shader = load("res://shaders/foliage.gdshader")
	_apply_lights(leaf_material)
	fade_materials.append(leaf_material)
	_tree_multimesh(_broadleaf_mesh(), leaf_material, broad, broad_col)
	_tree_multimesh(_conifer_mesh(), leaf_material, needle, needle_col)


func _tree_multimesh(mesh: Mesh, material: Material, spots: Array[Transform3D], colours: Array[Color],
		custom: Array[Color] = [], parent: Node = null) -> Array[MultiMeshInstance3D]:
	var made: Array[MultiMeshInstance3D] = []
	# One MultiMesh per tile, so off-screen tiles are skipped.
	var tiles := {}
	for i in spots.size():
		var o := spots[i].origin
		var key := Vector2i(floori(o.x / INSTANCE_TILE), floori(o.z / INSTANCE_TILE))
		if not tiles.has(key):
			tiles[key] = []
		(tiles[key] as Array).append(i)
	for members in tiles.values():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = not colours.is_empty()
		mm.use_custom_data = not custom.is_empty()
		mm.mesh = mesh
		mm.instance_count = members.size()
		var box := AABB(spots[members[0]].origin, Vector3.ZERO)
		for k in members.size():
			var i: int = members[k]
			mm.set_instance_transform(k, spots[i])
			box = box.expand(spots[i].origin)
			if mm.use_colors:
				mm.set_instance_color(k, colours[i])
			if mm.use_custom_data:
				mm.set_instance_custom_data(k, custom[i])
		# Saved MultiMeshes don't recompute their bounds on load (the prebuilt city
		# would cull every tile), so store them explicitly.
		mm.custom_aabb = box.grow(12.0)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = material
		(parent if parent != null else self).add_child(mmi)
		made.append(mmi)
	return made


## A faceted crown: an icosahedron, stretched a little, flat-shaded.
func _broadleaf_mesh() -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var v := [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
			Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
			Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4],
			[11, 10, 2], [10, 7, 6], [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
			[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var centre := Vector3(0, 4.3, 0)
	var stretch := Vector3(2.4, 2.6, 2.4) / Vector3(1, t, 1).length()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a: Vector3 = centre + v[f[0]] * stretch
		var b: Vector3 = centre + v[f[1]] * stretch
		var c: Vector3 = centre + v[f[2]] * stretch
		var n := (b - a).cross(c - a).normalized()
		if n.dot((a + b + c) / 3.0 - centre) < 0.0:
			n = -n
		_tri(st, a, b, c, n, Color.WHITE)
	return st.commit()


## A conifer: three stacked six-sided cones, flat-shaded.
func _conifer_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tier in [[1.6, 2.2, 4.4], [3.4, 1.7, 6.0], [5.0, 1.1, 7.4]]:
		var base_y: float = tier[0]
		var radius: float = tier[1]
		var apex := Vector3(0, tier[2], 0)
		for i in 6:
			var a := Vector3(cos(TAU * i / 6.0) * radius, base_y, sin(TAU * i / 6.0) * radius)
			var b := Vector3(cos(TAU * (i + 1) / 6.0) * radius, base_y, sin(TAU * (i + 1) / 6.0) * radius)
			var n := (b - a).cross(apex - a).normalized()
			if n.dot((a + b) * 0.5 - Vector3(0, base_y, 0)) < 0.0:
				n = -n
			_tri(st, a, b, apex, n, Color.WHITE)
	return st.commit()


## The parked cars' paints, picked by the bake's index (loop 2c: models.gd, the red one slate).
const CAR_PAINT := Models.PARKED_PAINT


func _box(st, centre: Vector3, size: Vector3, col: Color) -> void:
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
			_quad(st, c - u - v, c + u - v, c + u + v, c - u + v, n, col)


func _build_street_furniture() -> void:
	var metal := StandardMaterial3D.new()
	metal.vertex_color_use_as_albedo = true
	metal.vertex_color_is_srgb = true
	metal.roughness = 0.7

	var lamp := SurfaceTool.new()
	lamp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grey := Color("#43474c")
	_box(lamp, Vector3(0, 3.5, 0), Vector3(0.16, 7.0, 0.16), grey)
	_box(lamp, Vector3(0.6, 6.95, 0), Vector3(1.3, 0.1, 0.12), grey)
	_box(lamp, Vector3(1.2, 6.85, 0), Vector3(0.55, 0.16, 0.3), LAMP_HEAD)
	var spots: Array[Transform3D] = []
	var glows: Array[Color] = []
	var list: Array = data.get("lamps", [])
	for i in range(0, list.size() - 1, 2):
		var x := float(list[i])
		var z := float(list[i + 1])
		var t := Transform3D(Basis(Vector3.UP, fposmod(x * 0.37 + z * 0.11, TAU)), Vector3(x, terrain_height(x, z), z))
		spots.append(t)
		var head := t * Vector3(1.2, 0.0, 0.0)
		glows.append(SODIUM_GLOW if _sodium_at(head.x, head.z) else LED_GLOW)
	# The bake's own lamps (bridges): on the deck, arm over the carriageway.
	for i in range(0, _extra_lamps.size() - 2, 3):
		var x := _extra_lamps[i]
		var z := _extra_lamps[i + 1]
		spots.append(Transform3D(Basis(Vector3.UP, _extra_lamps[i + 2]), Vector3(x, ground_height(x, z), z)))
		glows.append(SODIUM_GLOW)
	var none: Array[Color] = []
	var fixture := ShaderMaterial.new()
	fixture.shader = load("res://shaders/fixture.gdshader")
	for mmi in _tree_multimesh(_mark_head(lamp.commit()), fixture, spots, none, glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	_build_lamp_halos(spots, glows)

	var signal_mesh := SurfaceTool.new()
	signal_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color("#26282b")
	_box(signal_mesh, Vector3(0, 1.8, 0), Vector3(0.14, 3.6, 0.14), dark)
	_box(signal_mesh, Vector3(0, 3.35, 0.2), Vector3(0.34, 1.0, 0.28), dark)
	_box(signal_mesh, Vector3(0, 3.65, 0.35), Vector3(0.16, 0.16, 0.04), Color("#c8432f"))
	_box(signal_mesh, Vector3(0, 3.05, 0.35), Vector3(0.16, 0.16, 0.04), Color("#4f9a52"))
	spots = []
	list = data.get("signals", [])
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	for mmi in _tree_multimesh(signal_mesh.commit(), metal, spots, none):
		mmi.add_to_group(SMALL_CASTERS, true)

	# Parked cars: white body and dark glass, tinted per car by the instance colour (loop 2c:
	# the shape is models.gd's parked_mesh(), a small saloon like the traffic's).
	spots = []
	var paints: Array[Color] = []
	list = data.get("parked", [])
	for i in range(0, list.size() - 3, 4):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
		paints.append(Color(CAR_PAINT[int(list[i + 3]) % CAR_PAINT.size()]))
	var car_paint := leaf_material.duplicate() as ShaderMaterial
	car_paint.set_shader_parameter("sway", 0.0)
	fade_materials.append(car_paint)
	for mmi in _tree_multimesh(Models.parked_mesh(), car_paint, spots, paints):
		mmi.add_to_group(SMALL_CASTERS, true)
	# Parked cars are obstacles too.
	var footprint := [Vector3(-0.9, 0, -2.1), Vector3(0.9, 0, -2.1), Vector3(0.9, 0, 2.1), Vector3(-0.9, 0, 2.1)]
	for t in spots:
		for k in 4:
			var a: Vector3 = t * footprint[k]
			var b: Vector3 = t * footprint[(k + 1) % 4]
			var up := Vector3(0, 1.5, 0)
			_wall_faces.append_array([a, b, b + up, a, b + up, a + up])


## Street-lamp heads, and the light they give off at night (linear; alpha = halo brightness).
const LAMP_HEAD := Color("#d9d4c3")
const SODIUM_GLOW := Color(1.0, 0.45, 0.12, 0.6)
const LED_GLOW := Color(0.72, 0.82, 1.0, 0.5)


## Marks the lamp head's vertices (its colour) with UV.x = 1, so fixture.gdshader
## knows what glows.
func _mark_head(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in colours.size():
		uv[i] = Vector2(1.0, 1.0) if colours[i].is_equal_approx(LAMP_HEAD) else Vector2(-1.0, -1.0)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## A soft glow round every lamp head (glow.gdshader, billboards), under a "LampHalos"
## node the game shows only when the lights are on.
func _build_lamp_halos(spots: Array[Transform3D], glows: Array[Color]) -> void:
	var holder := Node3D.new()
	holder.name = "LampHalos"
	add_child(holder)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glow.gdshader")
	mat.set_shader_parameter("billboard", true)
	mat.set_shader_parameter("radial", true)
	mat.set_shader_parameter("lift", 1.5)
	mat.render_priority = 1
	var heads: Array[Transform3D] = []
	for t in spots:
		heads.append(Transform3D(Basis(), t * Vector3(1.2, 6.78, 0.0)))
	var none: Array[Color] = []
	_tree_multimesh(halo_quad(4.6), mat, heads, glows, none, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A square of `size` metres centred on the origin, UV 0..1, white: a halo sprite.
static func halo_quad(size: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size * 0.5
	var corners := [Vector3(-h, h, 0), Vector3(h, h, 0), Vector3(h, -h, 0), Vector3(-h, -h, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_color(Color.WHITE)
		st.set_uv(uvs[k])
		st.add_vertex(corners[k])
	return st.commit()


## Neon shop signs (neon_signs.gd) on the ground floor of about a third of the
## buildings with a street in front: on the longest wall facing it, if the word
## fits. They go under a "Neon" node the game shows only when the lights are on.
func _build_neon(keep: Array, marks) -> void:
	var streets := {}
	for r in data["roads"]:
		if String(r["k"]) in ["service", "footway", "path", "track"]:
			continue
		var half := float(r["w"]) * 0.5
		var pts := _pts(r["p"])
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var steps := maxi(1, ceili(a.distance_to(b) / 5.0))
			for k in steps + 1:
				var q := a.lerp(b, float(k) / steps)
				var key := Vector2i(floori(q.x / 24.0), floori(q.y / 24.0))
				# Packed arrays are values: append to the copy, then put it back.
				var cell: PackedVector3Array = streets.get(key, PackedVector3Array())
				cell.append(Vector3(q.x, q.y, half))
				streets[key] = cell
	var polys: Array[PackedVector2Array] = []
	for f in _lod2_footprints:
		polys.append(_pts(f))
	var list: Array = data["buildings"]
	for index in (keep if _has_lod2 else range(list.size())):
		var bld: Dictionary = list[int(index)]
		if float(bld["mh"]) < 0.5 and not bld.has("br"):
			polys.append(_pts(bld["p"]))

	var spots: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	for poly in polys:
		if poly.size() < 3:
			continue
		var mid_p := Vector2.ZERO
		for q in poly:
			mid_p += q
		if marks.replaces(mid_p / poly.size()):
			continue  # no shop signs on the landmarks
		var pick := fposmod(sin(poly[0].x * 12.9898 + poly[0].y * 78.233) * 43758.5453, 1.0)
		if pick > 0.36:
			continue
		var best := -1.0
		var best_mid := Vector2.ZERO
		var best_out := Vector2.ZERO
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			var length := a.distance_to(b)
			if length < 7.0 or length <= best:
				continue
			var mid := (a + b) * 0.5
			var e := (b - a) / length
			var out := Vector2(e.y, -e.x)
			if Geometry2D.is_point_in_polygon(mid + out * 0.3, poly):
				out = -out
			var front := mid + out * 4.5
			if roof_height(front.x, front.y) != NO_ROOF or not _street_ahead(streets, mid, out):
				continue
			var ground := terrain_height(mid.x, mid.y)
			var inside := mid - out * 2.5
			if roof_height(inside.x, inside.y) < ground + 6.0:
				continue
			best = length
			best_mid = mid
			best_out = out
		if best < 0.0:
			continue
		var word := ""
		for attempt in 4:
			var w: String = Neon.WORDS[int(fposmod(pick * 97.0 + attempt * 3.0, 1.0) * Neon.WORDS.size()) % Neon.WORDS.size()]
			if Neon.length_of(w) + 1.5 <= best:
				word = w
				break
		if word == "":
			continue
		var row := Neon.WORDS.find(word)
		var ground := terrain_height(best_mid.x, best_mid.y)
		spots.append(Neon.place(word, Vector3(best_mid.x, ground + 2.7, best_mid.y), Vector3(best_out.x, 0.0, best_out.y)))
		var tone := fposmod(pick * 53.7, 1.0)
		colours.append(Neon.colour_for(word, tone))
		var width := float(Neon.word_width(word) + 2 * Neon.PAD) / Neon.ATLAS_W
		var plate := 1.0 if fposmod(pick * 19.3, 1.0) < 0.45 else 0.0
		custom.append(Color(row, width, plate, fposmod(pick * 71.9, 1.0)))
	if spots.is_empty():
		return
	var holder := Node3D.new()
	holder.name = "Neon"
	add_child(holder)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/neon.gdshader")
	mat.set_shader_parameter("words", Neon.atlas())
	mat.set_shader_parameter("rows", float(Neon.WORDS.size()))
	_tree_multimesh(Neon.quad(), mat, spots, colours, custom, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	print("neon signs: ", spots.size())


## True when a street's carriageway lies 3–16 m in front of a wall.
func _street_ahead(streets: Dictionary, mid: Vector2, out: Vector2) -> bool:
	for d: float in [3.0, 7.0, 11.0, 16.0]:
		var q: Vector2 = mid + out * d
		var key := Vector2i(floori(q.x / 24.0), floori(q.y / 24.0))
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var near: PackedVector3Array = streets.get(key + Vector2i(dx, dz), PackedVector3Array())
				for p in near:
					if Vector2(p.x, p.y).distance_to(q) < p.z + 2.5:
						return true
	return false


const POSTER := ["#e8d36a", "#e07a5f", "#81b29a", "#f2cc8f", "#9db4d8", "#e8a6b8", "#f4f1de"]


func _cylinder(st, centre: Vector3, radius: float, height: float, sides: int, col: Color) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		var p0 := centre + Vector3(cos(a0) * radius, 0, sin(a0) * radius)
		var p1 := centre + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var up := Vector3(0, height, 0)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		_quad(st, p0, p1, p1 + up, p0 + up, n, col)
		_tri(st, centre + up, p1 + up, p0 + up, Vector3.UP, col)


## Benches, bins, bike racks, bus shelters and Warsaw's advertising columns.
func _build_props() -> void:
	var metal := StandardMaterial3D.new()
	metal.vertex_color_use_as_albedo = true
	metal.vertex_color_is_srgb = true
	metal.roughness = 0.75
	var none: Array[Color] = []

	var bench := SurfaceTool.new()
	bench.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color("#8b6a48")
	_box(bench, Vector3(0, 0.45, 0), Vector3(1.7, 0.08, 0.5), wood)
	_box(bench, Vector3(0, 0.78, 0.22), Vector3(1.7, 0.36, 0.07), wood)
	for x in [-0.7, 0.7]:
		_box(bench, Vector3(x, 0.22, 0), Vector3(0.08, 0.44, 0.45), Color("#2e3033"))
	_props(bench.commit(), metal, data.get("benches", []), 3.2, none, true)

	var bin := SurfaceTool.new()
	bin.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(bin, Vector3(0, 0.45, 0), Vector3(0.45, 0.9, 0.45), Color("#3e5a44"))
	_box(bin, Vector3(0, 0.92, 0), Vector3(0.5, 0.06, 0.5), Color("#2c2e30"))
	_props(bin.commit(), metal, data.get("bins", []), 1.0, none, true)

	var rack := SurfaceTool.new()
	rack.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-0.9, -0.3, 0.3, 0.9]:
		_box(rack, Vector3(0, 0.45, z), Vector3(0.7, 0.07, 0.07), Color("#8c9096"))
		for x in [-0.33, 0.33]:
			_box(rack, Vector3(x, 0.22, z), Vector3(0.06, 0.45, 0.06), Color("#8c9096"))
	_props(rack.commit(), metal, data.get("bikes", []), 3.4, none, true)

	# Advertising column: green foot and cap, a poster band tinted per column.
	var column := SurfaceTool.new()
	column.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := Color("#2f5a46")
	_cylinder(column, Vector3.ZERO, 0.66, 0.5, 10, green)
	_cylinder(column, Vector3(0, 0.5, 0), 0.6, 2.4, 10, Color.WHITE)
	_cylinder(column, Vector3(0, 2.9, 0), 0.7, 0.18, 10, green)
	_cylinder(column, Vector3(0, 3.08, 0), 0.45, 0.35, 8, green)
	_cylinder(column, Vector3(0, 3.43, 0), 0.12, 0.3, 6, Color("#c9a24a"))
	var tints: Array[Color] = []
	var list: Array = data.get("columns", [])
	for i in range(0, list.size() - 2, 3):
		tints.append(Color(POSTER[int(absf(float(list[i]) * 7.0 + float(list[i + 1]) * 3.0)) % POSTER.size()]))
	_props(column.commit(), metal, list, 1.4, tints)

	# Bus and tram shelter: dark roof, glass back and ends, two posts.
	var shelter := SurfaceTool.new()
	shelter.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := Color("#b8d3df")
	_box(shelter, Vector3(0, 2.45, 0), Vector3(3.8, 0.12, 1.6), Color("#43474d"))
	_box(shelter, Vector3(0, 1.3, 0.72), Vector3(3.7, 2.1, 0.05), glass)
	for x in [-1.85, 1.85]:
		_box(shelter, Vector3(x, 1.3, 0.2), Vector3(0.05, 2.1, 1.05), glass)
	_box(shelter, Vector3(0, 0.45, 0.5), Vector3(2.4, 0.07, 0.4), Color("#7c8087"))
	_props(shelter.commit(), metal, data.get("shelters", []), 4.0, none)


## Instances of one prop at (x, z, yaw) triples; props bigger than `solid` metres
## across become obstacles. `fine`: under a metre tall (loop 2b: no shadow, FINE_GROUP).
func _props(mesh: Mesh, material: Material, list: Array, solid: float, tints: Array[Color], fine := false) -> void:
	var spots: Array[Transform3D] = []
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	for mmi in _tree_multimesh(mesh, material, spots, tints):
		if fine:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.add_to_group(FINE_GROUP, true)
		else:
			mmi.add_to_group(SMALL_CASTERS, true)
	if solid < 1.3:
		return
	for t in spots:
		var r := solid * 0.5
		var c := [t * Vector3(-r, 0, -0.5), t * Vector3(r, 0, -0.5), t * Vector3(r, 0, 0.5), t * Vector3(-r, 0, 0.5)]
		for k in 4:
			var a: Vector3 = c[k]
			var b: Vector3 = c[(k + 1) % 4]
			var up := Vector3(0, 2.0, 0)
			_wall_faces.append_array([a, b, b + up, a, b + up, a + up])


func _build_collision() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.backface_collision = true
	concave.set_faces(_wall_faces)
	shape.shape = concave
	body.add_child(shape)
	# Invisible walls at the edge of the baked area.
	var r := bounds.grow(-5.0)
	var centre := r.get_center()
	for edge in [[Vector3(centre.x, 50, r.position.y), Vector3(r.size.x, 200, 1)],
			[Vector3(centre.x, 50, r.end.y), Vector3(r.size.x, 200, 1)],
			[Vector3(r.position.x, 50, centre.y), Vector3(1, 200, r.size.y)],
			[Vector3(r.end.x, 50, centre.y), Vector3(1, 200, r.size.y)]]:
		var wall := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = edge[1]
		wall.shape = box
		wall.position = edge[0]
		body.add_child(wall)
	add_child(body)
