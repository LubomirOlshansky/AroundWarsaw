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
const CityMaps := preload("res://scripts/city_maps.gd")
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

## Landmarks 0.3 (2026-10-31): the site key of `--solo=KEY` (main.gd); while set, a run builds
## that landmark alone (no ground, roads, buildings, trees or props) for the judge's unlit and
## silhouette shots. Static, because the streamer makes the builder. Runtime path only.
static var solo_site := ""
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
## Loop 3b-2: dry sand (beaches, sandbars), the wet band of a natural bank or a sandbar's rim
## (its colour from the vertex: sand or earth) and the foam line on the waterline.
const L_SAND := 16.0
const L_WET := 17.0
const L_FOAM := 18.0
## Loop 3b-2: the tram bed's concrete track slabs (joints across it every 3 m).
const L_TRAMBED := 19.0

const Y_GROUND := 0.0
const Y_AREA := 0.02
## Each green kind's height over Y_AREA (merging loop 3c): a fixed order where they overlap,
## park under grass under pitch, all under the sand (0.006 and up) and over the plazas (0).
const GREEN_Y := {"park": 0.003, "grass": 0.004, "pitch": 0.005}
## The stadium's grass embankment (_build_areas) under the plazas (Y_AREA) and over the ground.
const BANK_Y := -0.008
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
## The street-lamp light map's rectangle (tools/bake_lights.py; _sodium_at reads it).
@export_storage var light_rect := Vector4(0, 0, 1, 1)
## v0.9: the surface map's rectangle (tools/bake_water.py: distance to the shore, the river's
## flow, what reflects, bridge-deck heights; the ground shader and the post pass read it).
@export_storage var water_rect := Vector4(0, 0, 1, 1)
## Loop 3d-2b: the AO, lamp-light and surface maps reach the GPU per sector (city_maps.gd): their
## grids, "fine" (the AO and lamp-light maps) and "surface", each x0, z0, metres a texel, 0. The
## whole images stay on the CPU only while sectors are built (map_slices), never in index.res.
@export_storage var map_grids := {}
## Loop 3d-2b: per sector key, how many of its meshes and MultiMeshes tools/bake_city.gd saved as
## files of their own (map/sectors/s_<i>_<j>/<n>.res): the streamer's worker loads them one a
## frame before the sector's scene, so the GPU buffers they make reach the renderer a few a frame.
@export_storage var sector_pieces := {}
## Loop 3d-2b: the loaded sectors' map slices on the GPU (sector_streamer.gd, or main.gd for
## --monolithic: every sector's).
var city_maps: CityMaps
## Loop 3d-2b: the AO and surface maps' files and sizes: a sector's slices are read from them
## (rows of the file), so the whole maps never sit in memory (the lamp-light map's image does,
## for the lamp heads' colours).
var _ao_file := ""
var _ao_size := Vector2i.ZERO
var _water_file := ""
var _water_size := Vector2i.ZERO
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
## Loop 3c: stored, so the prebuilt index (map/index.res) has the map's rectangle too.
@export_storage var bounds: Rect2
## Map north (2026-10-31): the parts of `bounds` that are not map (centrum.json `outside`; today
## the north-east corner, east of the extension to Rondo Radosława and Arkadia). Each holds a
## corner of `bounds` (tools/map_shape.py, the bakes' twin of in_map, map_outline, clip_to_map).
@export_storage var outside: Array[Rect2] = []
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
## Loop 3d-1: per deck piece, 1 if its start meets another piece's end of the same deck, 2 its
## end (a joint: _decks_at lets a point DECK_JOINT_SLACK past it count); made with the cells.
var _deck_joints := PackedByteArray()
const DECK_JOINT_SLACK := 1.5
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
## Map round 2 (D5): an apron fades out over this past its corridor's sides.
const APRON_TAPER := 3.0
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
## The loading fix (2026-10-31): what colour tops each roof-grid cell, for the proxies
## (sector_proxies.gd), from the same buildings the sectors are built from: the roof's colour where
## a roof gives the cell its height (RGBA8, 0 for none), and the colour of a wall standing in it.
## Recorded only while `proxy_colours` is on (tools/bake_city.gd, or the runtime path when it makes
## the proxies itself): not saved, not in the exported game.
var proxy_colours := false
var roof_rgba := PackedInt32Array()
var wall_rgba := PackedInt32Array()
var _scratch_rgba := PackedInt32Array()
var _scratch_wall := PackedInt32Array()

# --- Loop 3c: sectors -------------------------------------------------------------------
## The city in 512 m sectors (docs/DEMO.md 2.4): tools/bake_sectors.py splits the map data
## into map/index.json (the whole map's: lane graph, decks, tunnels, points of interest...)
## and map/sectors/<i>_<j>.json (each sector's features, a border-crossing one in both);
## `build_sector` builds one sector from its file and keeps only the triangles, instances
## and collider faces whose centre lies in it, so the sectors together are what `build`
## makes in one go (tools/check_streaming.gd compares them). sector_streamer.gd loads them.
const SECTOR := 512.0
const SECTOR_DIR := "res://map/sectors/"
## The split's margin (tools/bake_sectors.py MARGIN): a sector's file holds what lies this
## close to it, so what it builds may reach this far (the landmarks and bridges it builds).
const SECTOR_MARGIN := 48.0
## The game's data for the whole map (index.json: what traffic, missions, the minimap read),
## kept in the prebuilt index (map/index.res) so the exported game needs no JSON.
@export_storage var index_data: Dictionary = {}
## Per sector key: Vector2(lowest ground - 15 m, highest roof or treetop), for the streamer's
## view test (a tall tower in a sector off the view's ground can still stand in the view).
@export_storage var sector_heights: Dictionary = {}
## Loop 3d-2b: per sector key, its highest ground (the far level: a sector whose ground and low
## buildings are out of the view, only its towers in it).
@export_storage var sector_ground: Dictionary = {}
## While one sector is built: it, its square, the square grown by the split's margin, its
## 2 x 2 tiles, and the roof grid its buildings mark (merged into _roof for its own cells).
var _in_sector := false
var _sector := Vector2i.ZERO
var _sector_rect := Rect2()
var _near := Rect2()
var _scratch_roof := PackedFloat32Array()
## The node the builder's meshes and bodies go under: this one, or the sector being built.
var _out: Node3D
## Whether a sector's build writes its cells of the roof and picking grids (build_sector).
var _merge := true
## The landmark sites, found once from the index (the streamed city).
var _marks
## The water's edge runs over the whole map, found once (the streamed city): [poly, side, kind, box].
var _global_shore: Array = []
## The terrain grid's smooth normals, found once.
var _gn := PackedVector3Array()
## Materials and meshes every sector shares (trees, lamps, signals, parked cars, props,
## halos, neon), made once: one per city, never one per sector.
var _shared := {}


func build(path: String, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> Dictionary:
	_out = self
	_setup(JSON.parse_string(FileAccess.get_file_as_string(path)), building_mat, flat_mat)
	# v0.8: the landmarks replace whatever LoD2 or OpenStreetMap lump stood in their place.
	var marks := Landmarks.new(self, data)
	_marks = marks
	landmark_info = marks.info
	_build_parts(marks, false)
	_build_collision()
	_index_raised()
	return data


## Loop 3c: the streamed city's global part (both city paths): what `build` sets up first,
## then what every sector build shares: the landmark sites and their info cards (from the
## index's `site_parts`), the water's edge, the kerbs and islands the car feels, the shared
## materials and meshes, and the walls at the map's edge.
func setup_streamed(index: Dictionary, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> void:
	_out = self
	_setup(index, building_mat, flat_mat)
	index_data = index
	# `areas`: the lawns of the University Library's roof garden (landmarks.gd _find_buw).
	_marks = Landmarks.new(self, {"landmarks": index.get("landmarks", []), "towers": index.get("towers", []),
			"buildings": index.get("site_parts", []), "areas": index.get("areas", [])})
	landmark_info = _marks.info
	_pick.resize(_roof_nx * _roof_nz)
	_pick.fill(0)
	_index_decks()
	_ground_normals()
	_global_shore = _find_shore_lines()
	_index_raised()
	_make_shared()
	_build_edge_walls()


## Loop 3c: each sector's lowest ground (- 20 m: tunnels, the river bed) and its highest roof
## or treetop (the terrain + 40 m at least), from the finished roof grid: the streamer loads a
## sector whose box meets the camera's view (sector_streamer.gd).
func measure_sectors() -> void:
	sector_heights.clear()
	sector_ground.clear()
	var step := float(_terrain.get("step", 10.0))
	for k: Array in index_data.get("sectors", {}).get("keys", []):
		var key := Vector2i(int(k[0]), int(k[1]))
		var rect := clip_to_map(Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR)))
		var lo := INF
		var hi := -INF
		var z := rect.position.y
		while z <= rect.end.y:
			var x := rect.position.x
			while x <= rect.end.x:
				var g := _grid_height(x, z)
				lo = minf(lo, g)
				hi = maxf(hi, g)
				x += step
			z += step
		var top := hi + 40.0
		var i0 := clampi(floori((rect.position.x - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
		var i1 := clampi(floori((rect.end.x - _roof_x0) / ROOF_CELL), 0, _roof_nx - 1)
		var j0 := clampi(floori((rect.position.y - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
		var j1 := clampi(floori((rect.end.y - _roof_z0) / ROOF_CELL), 0, _roof_nz - 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				top = maxf(top, _roof[j * _roof_nx + i])
		sector_heights[key] = Vector2((lo if lo < INF else 0.0) - 20.0, top + 2.0)
		sector_ground[key] = hi if hi > -INF else 0.0


## Loop 3c: the key of the sector holding a point.
static func sector_of(x: float, z: float) -> Vector2i:
	return Vector2i(floori(x / SECTOR), floori(z / SECTOR))


# --- Map north (2026-10-31): the map's shape, `bounds` without its `outside` corners ---------

## An outside part as the map grown by d metres sees it: its sides on the bounds move out with
## them, its inner sides in (tools/map_shape.py Shape.grow).
func _outside_grown(o: Rect2, d: float) -> Rect2:
	var x0 := o.position.x - d if o.position.x <= bounds.position.x else o.position.x + d
	var z0 := o.position.y - d if o.position.y <= bounds.position.y else o.position.y + d
	var x1 := o.end.x + d if o.end.x >= bounds.end.x else o.end.x - d
	var z1 := o.end.y + d if o.end.y >= bounds.end.y else o.end.y - d
	return Rect2(x0, z0, x1 - x0, z1 - z0)


## Map north: whether p lies on the map grown by `pad` metres (shrunk for pad < 0): inside the
## bounds and in no outside part.
func in_map(p: Vector2, pad := 0.0) -> bool:
	if not bounds.grow(pad).has_point(p):
		return false
	for o in outside:
		var g := _outside_grown(o, pad)
		if p.x > g.position.x and p.x < g.end.x and p.y > g.position.y and p.y < g.end.y:
			return false
	return true


## Map north: the map's outline grown by `pad`: the bounds' corners clockwise from the north-west
## (+z south), each corner an outside part holds replaced by the part's inner corner and the two
## points where its sides meet the bounds (six points with the north extension).
func map_outline(pad := 0.0) -> PackedVector2Array:
	var r := bounds.grow(pad)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var out := PackedVector2Array()
	for k in 4:
		var c: Vector2 = corners[k]
		var notch := Rect2()
		var found := false
		for o in outside:
			var g := _outside_grown(o, pad)
			if c.x >= g.position.x - 0.01 and c.x <= g.end.x + 0.01 and c.y >= g.position.y - 0.01 and c.y <= g.end.y + 0.01:
				notch = g
				found = true
		if not found:
			out.append(c)
			continue
		var ix := notch.end.x if is_equal_approx(c.x, r.position.x) else notch.position.x
		var iz := notch.end.y if is_equal_approx(c.y, r.position.y) else notch.position.y
		var prev: Vector2 = corners[(k + 3) % 4]
		var nxt: Vector2 = corners[(k + 1) % 4]
		out.append(Vector2(ix, c.y) if is_equal_approx(prev.y, c.y) else Vector2(c.x, iz))
		out.append(Vector2(ix, iz))
		out.append(Vector2(ix, c.y) if is_equal_approx(nxt.y, c.y) else Vector2(c.x, iz))
	return out


## Map north: rect cut to the map: to the bounds, then by any outside part that spans it whole
## in one direction (one that only bites a corner of it leaves it as it is).
func clip_to_map(rect: Rect2) -> Rect2:
	var r := rect.intersection(bounds)
	for o in outside:
		if not r.intersects(o):
			continue
		if o.position.y <= r.position.y and o.end.y >= r.end.y:
			if o.position.x <= r.position.x and o.end.x >= r.end.x:
				return Rect2(r.position, Vector2.ZERO)
			if o.position.x <= r.position.x:
				r = Rect2(o.end.x, r.position.y, r.end.x - o.end.x, r.size.y)
			elif o.end.x >= r.end.x:
				r = Rect2(r.position.x, r.position.y, o.position.x - r.position.x, r.size.y)
		elif o.position.x <= r.position.x and o.end.x >= r.end.x:
			if o.position.y <= r.position.y:
				r = Rect2(r.position.x, o.end.y, r.size.x, r.end.y - o.end.y)
			elif o.end.y >= r.end.y:
				r = Rect2(r.position.x, r.position.y, r.size.x, o.position.y - r.position.y)
	return r


## Map north: whether the 10 m ground cell [x, x + step] x [z, z + step] lies wholly in an outside
## part (no ground there; a cell across the outline is drawn, as on the box's own edges).
func _cell_outside(x: float, z: float, step: float) -> bool:
	for o in outside:
		var g := o.grow(0.01)
		# A side on the bounds runs on past them (the grid's last row reaches past the map's edge).
		var x0 := -INF if o.position.x <= bounds.position.x + 0.05 else g.position.x
		var z0 := -INF if o.position.y <= bounds.position.y + 0.05 else g.position.y
		var x1 := INF if o.end.x >= bounds.end.x - 0.05 else g.end.x
		var z1 := INF if o.end.y >= bounds.end.y - 0.05 else g.end.y
		if x >= x0 and x + step <= x1 and z >= z0 and z + step <= z1:
			return true
	return false


static func sector_name(key: Vector2i) -> String:
	return "s_%d_%d" % [key.x, key.y]


## Loop 3c: one sector from map/sectors/<i>_<j>.json, under a new node (not in the tree):
## ground, roads and markings, buildings and the landmarks' parts in it, trees, lamps,
## signals, parked cars and props, and its colliders. Its cells of the roof and picking grids
## go into the map's. Needs `setup_streamed`. `roofs_only`: no nodes, only those cells (the
## runtime path's pass over the whole map, which missions, eggs and the helicopter read).
## `merge` false leaves the map's grids alone (a sector built on a worker thread after that
## pass: the grids are complete, and the main thread reads them meanwhile).
func build_sector(key: Vector2i, roofs_only := false, merge := true) -> Node3D:
	var root := Node3D.new()
	root.name = sector_name(key)
	var path := SECTOR_DIR + "%d_%d.json" % [key.x, key.y]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		push_error("map: no sector file %s (run tools/bake_sectors.py)" % path)
		return root
	var whole := data
	data = parsed
	_out = root
	_in_sector = true
	_sector = key
	_sector_rect = Rect2(Vector2(key) * SECTOR, Vector2(SECTOR, SECTOR))
	# What the sector's file reaches (tools/bake_sectors.py: its buildings' surroundings, for
	# their shop signs): the landmarks and the water's edge in it are built too.
	var ctx: Array = data.get("context", [])
	_near = Rect2(ctx[0], ctx[1], ctx[2] - ctx[0], ctx[3] - ctx[1]) if ctx.size() == 4 else _sector_rect.grow(SECTOR_MARGIN)
	_wall_faces.clear()
	_scratch_roof.resize(_roof.size())
	_scratch_roof.fill(NO_ROOF)
	if proxy_colours:
		_open_colours()
		_scratch_rgba.resize(_roof.size())
		_scratch_rgba.fill(0)
		_scratch_wall.resize(_roof.size())
		_scratch_wall.fill(0)
	_merge = merge
	_build_parts(_marks, roofs_only)
	if not roofs_only:
		_build_collision()
		# Loop 3d-2b: the sector's slices of the baked maps travel with it (saved in its scene).
		var slices := map_slices(key)
		if not slices.is_empty():
			root.set_meta("map_slices", slices)
	if merge:
		_merge_roofs()
	_merge = true
	_wall_faces.clear()
	data = whole
	_out = self
	_in_sector = false
	return root


## Loop 3c: everything but the colliders, in build order (one sector or the whole map).
func _build_parts(marks, roofs_only: bool) -> void:
	if solo_site != "":
		# Landmarks 0.3: one site's triangles and nothing else (`marks.build`'s `only`).
		var solo_walls := _new_surface()
		solo_walls.none = roofs_only
		marks.build(solo_walls, _near if _in_sector else Rect2(), solo_site)
		if not roofs_only:
			_add_mesh(solo_walls, building_material, true)
		return
	if not roofs_only:
		var flat := _new_surface()
		# Loop 3d-2a: the ground is built last, so it can leave out what the flat layers on it
		# cover whole (`_cover_on`: they note their outlines while they are laid).
		_cover_reset()
		# Wide gaps between the depth biases: two layers that fit a slope with different
		# triangles can differ by a few centimetres, and must not poke through each other.
		# Loop 3b-2: the areas lie exactly on the ground's own triangles (_fill_on_grid), so their
		# few millimetres of height order them over the ground and each other without a depth bias
		# to speak of (0.05 before); the thin strips laid over them (paths at 0.1) keep a margin for
		# their pieces' sag over the grid's folds (game/tools/check_drape.gd counts it).
		_drape_bias = 0.01
		_cover_on = true
		_build_areas(flat)
		_cover_on = false
		# The sandbars over the water (fill 0.02, rim 0.07, foam 0.09) and the natural banks' wet
		# bands and foam (0.07, 0.09), under the paving and the paths.
		_drape_bias = 0.02
		_build_sandbars(flat)
		_drape_bias = 0.07
		_build_banks(flat)
		_cover_on = true
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
		_cover_on = false
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
		_build_ground(flat)
		_cover_reset()
		_add_mesh(flat, flat_material, false)

	var walls := _new_surface()
	walls.none = roofs_only
	var keep := _build_lod2(walls, marks)
	var t_parts := Time.get_ticks_msec()
	_build_buildings(walls, keep, marks)
	if not _in_sector:
		print("buildings: %d floating parts: %d lowered (%d to the ground), %d tiny left out · %d ms" % [floating_parts,
				floating_parts - floating_dropped, floating_to_ground, floating_dropped, Time.get_ticks_msec() - t_parts])
	marks.build(walls, _near if _in_sector else Rect2())
	if not _in_sector:
		_pick = marks.pick_grid()
	elif _merge:
		_merge_pick(marks.pick_grid())
	if roofs_only:
		return
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
	_build_landmark_signs(marks)

	_build_trees()
	_build_street_furniture()
	_build_props()


## Loop 3c: a chunked surface keeping only the sector's tiles while one is built.
func _new_surface() -> Chunked:
	var st := Chunked.new()
	if _in_sector:
		st.only = Rect2i(_sector * 2, Vector2i(2, 2))
	return st


## Loop 3c: the sector's own cells (their centres in it) of the roof grid its build marked.
func _merge_roofs() -> void:
	var r := _cell_range()
	for j in range(r.position.y, r.end.y):
		for i in range(r.position.x, r.end.x):
			var k := j * _roof_nx + i
			if _scratch_roof[k] > _roof[k]:
				_roof[k] = _scratch_roof[k]
			if proxy_colours:
				if _scratch_rgba[k] != 0:
					roof_rgba[k] = _scratch_rgba[k]
				if _scratch_wall[k] != 0:
					wall_rgba[k] = _scratch_wall[k]


## Loop 3c: the sector's own cells of the landmarks' picking grid.
func _merge_pick(grid: PackedByteArray) -> void:
	var r := _cell_range()
	for j in range(r.position.y, r.end.y):
		for i in range(r.position.x, r.end.x):
			var k := j * _roof_nx + i
			_pick[k] = grid[k]


## Loop 3c: the roof-grid cells whose centres lie in the sector being built (i, j from, to).
func _cell_range() -> Rect2i:
	var i0 := clampi(ceili((_sector_rect.position.x - _roof_x0) / ROOF_CELL - 0.5), 0, _roof_nx)
	var i1 := clampi(ceili((_sector_rect.end.x - _roof_x0) / ROOF_CELL - 0.5), 0, _roof_nx)
	var j0 := clampi(ceili((_sector_rect.position.y - _roof_z0) / ROOF_CELL - 0.5), 0, _roof_nz)
	var j1 := clampi(ceili((_sector_rect.end.y - _roof_z0) / ROOF_CELL - 0.5), 0, _roof_nz)
	return Rect2i(i0, j0, i1 - i0, j1 - j0)


## Loop 3c: whether a triangle (or a piece) can have its centre in the sector being built
## (its box meets the sector): the drape skips the rest before the costly height lookups.
func _touches(a: Vector3, b: Vector3, c: Vector3, pad := 0.01) -> bool:
	var r := _sector_rect
	return maxf(a.x, maxf(b.x, c.x)) >= r.position.x - pad and minf(a.x, minf(b.x, c.x)) <= r.end.x + pad \
			and maxf(a.z, maxf(b.z, c.z)) >= r.position.y - pad and minf(a.z, minf(b.z, c.z)) <= r.end.y + pad


## Loop 3c: the bounds, roof grid, surface maps, terrain, approaches, aprons, decks and
## tunnels from a map's data (the whole map's, or the index's).
func _setup(d: Dictionary, building_mat: ShaderMaterial, flat_mat: ShaderMaterial) -> void:
	building_material = building_mat
	flat_material = flat_mat
	data = d
	var b: Array = data["bounds"]
	bounds = Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
	outside.clear()
	for o: Array in data.get("outside", []):
		outside.append(Rect2(o[0], o[1], float(o[2]) - float(o[0]), float(o[3]) - float(o[1])))
	_roof_x0 = bounds.position.x
	_roof_z0 = bounds.position.y
	# Map north: the 4 m roof grid keeps the box's own cells (its lines through the box's north-west
	# corner, which an outside part's inner edge marks): grown from the extension's edge, every
	# cell of the box moved 1.8 m and the helicopter's heights, the roof rescues and the landmarks'
	# tap cells with it (check_landmarks: the Presidential Palace's tallest cell lost its tap).
	for o in outside:
		if o.position.y <= bounds.position.y + 0.05 and o.end.y < bounds.end.y:
			_roof_z0 = o.end.y - ceilf((o.end.y - bounds.position.y) / ROOF_CELL - 1e-4) * ROOF_CELL
		if o.position.x <= bounds.position.x + 0.05 and o.end.x < bounds.end.x:
			_roof_x0 = o.end.x - ceilf((o.end.x - bounds.position.x) / ROOF_CELL - 1e-4) * ROOF_CELL
	_roof_nx = ceili((bounds.end.x - _roof_x0) / ROOF_CELL)
	_roof_nz = ceili((bounds.end.y - _roof_z0) / ROOF_CELL)
	_roof.resize(_roof_nx * _roof_nz)
	_roof.fill(NO_ROOF)
	map_grids.clear()
	_load_ao()
	_load_water()
	_load_lights()
	_set_floodlit(building_material)
	if FileAccess.file_exists("res://map/terrain.json"):
		_terrain = JSON.parse_string(FileAccess.get_file_as_string("res://map/terrain.json"))
		_t_h = PackedFloat32Array(_terrain["h"])

	_load_fills()
	_load_aprons()
	_load_decks()
	_load_tunnels()


func _add_mesh(st, material: Material, shadows: bool) -> void:
	for mesh in st.meshes():
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_out.add_child(mi)


## The baked occlusion map (tools/bake_ao.py): red the buildings' shade (the occlusion ghost
## lifts it), green the parked cars' and trees'. Loop 3d-2b: kept as an image for the sectors'
## slices (map_slices); the ground shader reads them per sector (city_maps.gdshaderinc).
func _load_ao() -> void:
	if not FileAccess.file_exists("res://map/ao.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/ao.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	# Loop 1: two bytes per metre (the buildings' shade, then the parked cars' and trees').
	if bytes.size() < 20 + w * h * 2:
		push_error("map: ao.bin is a one-byte map (re-run tools/bake_ao.py)")
		return
	_ao_file = "res://map/ao.bin"
	_ao_size = Vector2i(w, h)
	map_grids["fine"] = Vector4(x0, z0, px, 0.0)


## The surface map (tools/bake_water.py): RGBA per 2 m. Loop 3d-2b: kept as an image for the
## sectors' slices; the ground shader and the post pass read them per sector.
func _load_water() -> void:
	if not FileAccess.file_exists("res://map/water.bin"):
		return
	var bytes := FileAccess.get_file_as_bytes("res://map/water.bin")
	var w := bytes.decode_u32(0)
	var h := bytes.decode_u32(4)
	var x0 := bytes.decode_float(8)
	var z0 := bytes.decode_float(12)
	var px := bytes.decode_float(16)
	var image := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes.slice(20, 20 + w * h * 4))
	_water_file = "res://map/water.bin"
	_water_size = Vector2i(w, h)
	water_rect = Vector4(x0, z0, w * px, h * px)
	map_grids["surface"] = Vector4(x0, z0, px, 0.0)
	# Loop 10a: the R channel alone, for the car's water test (the convert keeps red).
	var red := image.duplicate() as Image
	red.convert(Image.FORMAT_R8)
	_shore = red.get_data()
	_shore_size = Vector2i(w, h)
	_shore_zip = _shore.compress(FileAccess.COMPRESSION_ZSTD)


## The baked street-lamp pools (tools/bake_lights.py): two bytes per metre, sodium
## and LED. Kept as an image: each lamp's head glows in its pool's colour, and (loop 3d-2b)
## the sectors' slices come from it. Its grid is the AO map's.
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
	light_rect = Vector4(x0, z0, w * px, h * px)
	if map_grids.has("fine") and not Vector4(x0, z0, px, 0.0).is_equal_approx(map_grids["fine"]):
		push_error("map: lights.bin's grid differs from ao.bin's (one slice grid for both: re-run tools/bake_lights.py)")
	if bytes.size() >= end + 4:
		var n := bytes.decode_u32(end)
		_extra_lamps = bytes.slice(end + 4, end + 4 + n * 12).to_float32_array()


## Loop 3d-2b: a sector's slices of the AO, lamp-light and surface maps ([ao, light, surface],
## city_maps.gd cut), or [] when the whole maps aren't loaded (the prebuilt index: its sectors
## carry their slices).
func map_slices(key: Vector2i) -> Array:
	if _ao_file == "" or _light_image == null or _water_file == "":
		return []
	var fine: Vector4 = map_grids["fine"]
	var ao := _slice_from_file(_ao_file, _ao_size, 2, Image.FORMAT_RG8, fine, key)
	var water := _slice_from_file(_water_file, _water_size, 4, Image.FORMAT_RGBA8, map_grids["surface"], key)
	if ao == null or water == null:
		return []
	return [ao, CityMaps.cut(_light_image, fine, key), water]


## Loop 3d-2b: a sector's slice of a baked map file (20-byte header, then `bpp` bytes a texel, row
## by row): only the rows and columns the slice reaches inside the map are read, then cut as from
## the whole image (city_maps.gd cut, the map's edge repeated past it).
func _slice_from_file(path: String, size: Vector2i, bpp: int, format: Image.Format, grid: Vector4, key: Vector2i) -> Image:
	var n := CityMaps.slice_texels(grid.z)
	var tx := CityMaps.slice_start(key.x * SECTOR, grid.x, grid.z)
	var tz := CityMaps.slice_start(key.y * SECTOR, grid.y, grid.z)
	var x0 := clampi(tx, 0, size.x - 1)
	var x1 := clampi(tx + n, x0 + 1, size.x)
	var z0 := clampi(tz, 0, size.y - 1)
	var z1 := clampi(tz + n, z0 + 1, size.y)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data := PackedByteArray()
	for z in range(z0, z1):
		f.seek(20 + (z * size.x + x0) * bpp)
		data.append_array(f.get_buffer((x1 - x0) * bpp))
	var part := Image.create_from_data(x1 - x0, z1 - z0, false, format, data)
	# The part as if it were the whole map: its grid starts at its first texel.
	return CityMaps.cut(part, Vector4(grid.x + x0 * grid.z, grid.y + z0 * grid.z, grid.z, 0.0), key)


## Loop 3d-2b: the slices on the GPU for `keys` (every sector of the whole city when `all`, for
## --monolithic), the arrays sized for `count` sectors (city_maps.gd).
func open_maps(keys: Array[Vector2i], count: int) -> void:
	city_maps = CityMaps.new()
	city_maps.setup(keys, map_grids.get("fine", Vector4(0, 0, 1, 0)), map_grids.get("surface", Vector4(0, 0, 2, 0)), count)


## Loop 3d-2b, --monolithic: the whole city's sectors' slices all on the GPU at once.
func open_maps_whole() -> void:
	var keys: Array[Vector2i] = []
	var a := sector_of(bounds.position.x - SECTOR_MARGIN, bounds.position.y - SECTOR_MARGIN)
	var b := sector_of(bounds.end.x + SECTOR_MARGIN, bounds.end.y + SECTOR_MARGIN)
	for j in range(a.y, b.y + 1):
		for i in range(a.x, b.x + 1):
			keys.append(Vector2i(i, j))
	open_maps(keys, keys.size())
	for key in keys:
		city_maps.attach(key, map_slices(key))
		city_maps.show(key)


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
		# Map round 2 (D5): past the corridor's sides the apron fades out over APRON_TAPER (it
		# stopped at a 0.65 m step inside a carriageway wider than the deck at the viaduct's west
		# end; the drawn ground follows a slope, not a step).
		var out := maxf(-a[6] - lat, lat - a[7])
		if along >= 0.0 and along <= a[4] and out < APRON_TAPER:
			var target := minf(h, a[5]) if along < a[8] else lerpf(a[5], h, (along - a[8]) / (a[4] - a[8]))
			h = target if out <= 0.0 else lerpf(target, h, out / APRON_TAPER)
	return h


## The grid raised to any approach whose corridor holds the point (terrain_height before the
## aprons).
func _fill_height(x: float, z: float) -> float:
	var h := _grid_height(x, z)
	_set_hit = false
	if _fill_cells.is_empty():
		return h
	var codes: PackedInt32Array = _fill_cells.get((floori(x / FILL_CELL) + 1024) * 4096 + floori(z / FILL_CELL) + 1024,
			PackedInt32Array())
	if codes.is_empty():
		return h
	# Loop 3a: inside an approach's corridor the ground is its profile (never lower).
	# Loop 3e: inside a ground profile's ("s": the 1 m NMT's level of a way by a structure,
	# tools/bake_roads.py `_ground_profiles`) it is that level, up or down: the nearest one's,
	# its corridor with round joins (a disc at each vertex).
	var p := Vector2(x, z)
	var set_h := NAN
	var set_d := INF
	for code in codes:
		var d: Dictionary = _fills[code >> 12]
		var k := code & 4095
		var pts: PackedVector2Array = d["pts"]
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var hs: PackedFloat32Array = d["h"]
		var is_set: bool = d["s"]
		if is_set:
			var w := minf(float(d["l"]), float(d["r"]))
			var da := p.distance_to(a)
			if da <= w and da < set_d:
				set_h = hs[k]
				set_d = da
			var db := p.distance_to(pts[k + 1])
			if db <= w and db < set_d:
				set_h = hs[k + 1]
				set_d = db
		var u := (p - a).dot(ab) / l2
		if (u < 0.0 and k > 0) or (u > 1.0 and k < pts.size() - 2) or u < -0.05 or u > 1.05:
			continue
		var t := clampf(u, 0.0, 1.0)
		var lat := ab.cross(p - a) / sqrt(l2)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			var v := lerpf(hs[k], hs[k + 1], t)
			if is_set:
				if absf(lat) < set_d:
					set_h = v
					set_d = absf(lat)
			else:
				h = maxf(h, v)
	_set_hit = not is_nan(set_h)
	if _set_hit:
		return set_h
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
	var on_ground := true
	for d in _decks_at(x, z):
		if d <= near_y + 1.2 and d > best:
			best = d
			on_ground = false
	# Loop 3b: in a tunnel's corridor, a vehicle down at its floor drives the floor.
	var t := tunnel_floor(x, z, near_y)
	if not is_nan(t):
		return t
	# Loop 3b-2: on a traffic island or a grass median the car rides KERB_UP higher.
	if on_ground and not _raise_cells.is_empty():
		best += raise_at(x, z)
	return best


## Loop 3b-2: kerbs you feel. The raised ground at street level: traffic islands and grass
## medians (KERB_UP over the road), and the kerb lines (the bake's kerbs and the islands'
## outlines), in RAISE_CELL cells; stored in the scene so the prebuilt city has them too.
## drive_height lifts the car onto an island or a median; the car (car.gd kerb_feel) loses a
## little speed with a bounce when it hops a kerb line and rolls slower on the raised ground.
## Traffic keeps to its lanes (lane_graph heights) and never feels them.
const RAISE_CELL := 8.0
@export_storage var _raise_polys: Array[PackedVector2Array] = []
@export_storage var _raise_cells := {}
@export_storage var _kerb_segs := PackedVector2Array()
@export_storage var _kerb_cells := {}


func _index_raised() -> void:
	_raise_polys.clear()
	_raise_cells.clear()
	_kerb_segs.clear()
	_kerb_cells.clear()
	var raised: Array[PackedVector2Array] = []
	for a in data.get("islands", []):
		if int(a.get("dk", -1)) < 0:
			raised.append(_pts(a["p"]))
	for m in data.get("medians", []):
		if m["k"] != "grass" or int(m.get("dk", -1)) >= 0:
			continue
		var s4: Array = m["s"]
		for i in range(0, s4.size() - 7, 4):
			raised.append(PackedVector2Array([Vector2(s4[i], s4[i + 1]), Vector2(s4[i + 2], s4[i + 3]),
					Vector2(s4[i + 6], s4[i + 7]), Vector2(s4[i + 4], s4[i + 5])]))
	for poly in raised:
		if poly.size() < 3:
			continue
		var id := _raise_polys.size()
		_raise_polys.append(poly)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		for cz in range(floori(box.position.y / RAISE_CELL), floori(box.end.y / RAISE_CELL) + 1):
			for cx in range(floori(box.position.x / RAISE_CELL), floori(box.end.x / RAISE_CELL) + 1):
				var key := Vector2i(cx, cz)
				var list: PackedInt32Array = _raise_cells.get(key, PackedInt32Array())
				list.append(id)
				_raise_cells[key] = list
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		_add_kerb_line(ring)
	for k in data.get("kerbs", []):
		if int(k.get("dk", -1)) < 0:
			_add_kerb_line(_pts(k["p"]))


func _add_kerb_line(poly: PackedVector2Array) -> void:
	for i in poly.size() - 1:
		var a := poly[i]
		var b := poly[i + 1]
		if a.distance_squared_to(b) < 0.0004:
			continue
		var id := _kerb_segs.size() / 2
		_kerb_segs.append(a)
		_kerb_segs.append(b)
		var lo := a.min(b)
		var hi := a.max(b)
		for cz in range(floori(lo.y / RAISE_CELL), floori(hi.y / RAISE_CELL) + 1):
			for cx in range(floori(lo.x / RAISE_CELL), floori(hi.x / RAISE_CELL) + 1):
				var key := Vector2i(cx, cz)
				var list: PackedInt32Array = _kerb_cells.get(key, PackedInt32Array())
				list.append(id)
				_kerb_cells[key] = list


## Loop 3b-2: how far the ground at (x, z) stands over the road at street level: KERB_UP on an
## island or a grass median, else 0.
func raise_at(x: float, z: float) -> float:
	var p := Vector2(x, z)
	for id: int in _raise_cells.get(Vector2i(floori(x / RAISE_CELL), floori(z / RAISE_CELL)), PackedInt32Array()):
		if Geometry2D.is_point_in_polygon(p, _raise_polys[id]):
			return KERB_UP
	return 0.0


## Loop 3b-2: for a car that moved from `from` to `to` at height y: x = the raise under `to`
## (raise_at), y = 1 if the move crossed a kerb line. Nothing on a deck or in a tunnel (the car
## more than a little over or under the street).
func kerb_feel(from: Vector2, to: Vector2, y: float) -> Vector2:
	if _kerb_cells.is_empty() and _raise_cells.is_empty():
		return Vector2.ZERO
	var g := terrain_height(to.x, to.y)
	if y > g + KERB_UP + 0.4 or y < g - 0.4:
		return Vector2.ZERO
	var crossed := 0.0
	var c0 := Vector2i(floori(from.x / RAISE_CELL), floori(from.y / RAISE_CELL))
	var c1 := Vector2i(floori(to.x / RAISE_CELL), floori(to.y / RAISE_CELL))
	for cz in range(mini(c0.y, c1.y), maxi(c0.y, c1.y) + 1):
		for cx in range(mini(c0.x, c1.x), maxi(c0.x, c1.x) + 1):
			for id: int in _kerb_cells.get(Vector2i(cx, cz), PackedInt32Array()):
				if Geometry2D.segment_intersects_segment(from, to, _kerb_segs[id * 2], _kerb_segs[id * 2 + 1]) != null:
					crossed = 1.0
					break
			if crossed > 0.0:
				break
		if crossed > 0.0:
			break
	return Vector2(raise_at(to.x, to.y), crossed)


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
	var best := p
	var best_r := 800.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 0.0
		while r < best_r:
			var q := p + d * r
			if not in_map(q, -6.0):
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
			# Past the deck's end, unless the end is a joint with the next piece of its deck: on
			# the outside of a bend a point can be past one piece's end and before the next one's
			# start (loop 3d-1: Most Świętokrzyski's pylon joint dropped the car 7.6 m to the river).
			var joint := (_deck_joints[i] & (1 if k == 0 else 2)) != 0
			var past := (-u if k == 0 else u - 1.0) * (pts[k + 1] - pts[k]).length()
			if not joint or past > DECK_JOINT_SLACK:
				continue
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
	# Loop 3d-1: which piece ends meet another piece's end of the same deck (a joint).
	_deck_joints.resize(_decks.size())
	_deck_joints.fill(0)
	for i in _decks.size():
		var pi: PackedVector2Array = _decks[i]["pts"]
		for j in _decks.size():
			if j == i or int(_decks[j]["g"]) != int(_decks[i]["g"]):
				continue
			var pj: PackedVector2Array = _decks[j]["pts"]
			for e in [pj[0], pj[pj.size() - 1]]:
				if pi[0].distance_to(e) < 0.6:
					_deck_joints[i] |= 1
				if pi[pi.size() - 1].distance_to(e) < 0.6:
					_deck_joints[i] |= 2
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
		_fills.append({"pts": pts, "h": PackedFloat32Array(piece["h"]), "l": float(piece["l"]), "r": float(piece["r"]),
				"s": int(piece.get("s", 0)) == 1})
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
		var reach := maxf(float(a["l"]), float(a["r"])) + APRON_TAPER + length
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


## Loop 3c: roof_height while the city is built: a sector's own grid during its build.
func _built_roof(x: float, z: float) -> float:
	if not _in_sector:
		return roof_height(x, z)
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return NO_ROOF
	return _scratch_roof[j * _roof_nx + i]


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
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return
	# Loop 3c: a sector's build marks its own grid (merged into _roof for its cells).
	if _in_sector:
		if y > _scratch_roof[j * _roof_nx + i]:
			_scratch_roof[j * _roof_nx + i] = y
	elif y > _roof[j * _roof_nx + i]:
		_roof[j * _roof_nx + i] = y


## A LoD2 triangle into the roof grid. Every corner marks its cell (that catches
## spires, chimneys and wall tops); roof triangles also give each cell centre
## they cover the roof's height there.
func _roof_triangle(a: Vector3, b: Vector3, c: Vector3, is_roof: bool, col := Color(0, 0, 0, 0)) -> void:
	_roof_mark(a.x, a.z, a.y)
	_roof_mark(b.x, b.z, b.y)
	_roof_mark(c.x, c.z, c.y)
	if not is_roof:
		if proxy_colours and col.a > 0.0:
			var m := (a + b + c) / 3.0
			_colour_mark(m.x, m.z, col, true, 0.0)
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
			if proxy_colours and col.a > 0.0:
				_colour_mark(x, z, col, false, y)
			if _in_sector:
				if y > _scratch_roof[k]:
					_scratch_roof[k] = y
			elif y > _roof[k]:
				_roof[k] = y


## A flat-roofed OpenStreetMap building into the roof grid.
func _roof_polygon(poly: PackedVector2Array, top: float, roof_col := Color(0, 0, 0, 0), wall_col := Color(0, 0, 0, 0)) -> void:
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
			if proxy_colours and roof_col.a > 0.0 and Geometry2D.is_point_in_polygon(p, poly):
				_colour_mark(p.x, p.y, roof_col, false, top)
				_colour_mark(p.x, p.y, wall_col, true, 0.0)
			if _in_sector:
				if top > _scratch_roof[k] and Geometry2D.is_point_in_polygon(p, poly):
					_scratch_roof[k] = top
			elif top > _roof[k] and Geometry2D.is_point_in_polygon(p, poly):
				_roof[k] = top


## The loading fix: the colour grids sized to the roof grid (empty until a build records them).
func _open_colours() -> void:
	if roof_rgba.size() != _roof.size():
		roof_rgba.resize(_roof.size())
		roof_rgba.fill(0)
		wall_rgba.resize(_roof.size())
		wall_rgba.fill(0)


## The loading fix: `col` for the cell holding a point: a wall's (`wall`), or a roof's at height `y`
## when it is the cell's highest so far (within a metre: a wall top or a spire's corner marks
## the height first) or the cell has no roof colour yet.
func _colour_mark(x: float, z: float, col: Color, wall: bool, y: float) -> void:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz:
		return
	var k := j * _roof_nx + i
	var c := Color(col.r, col.g, col.b, 1.0).to_rgba32()
	if _in_sector:
		if wall:
			_scratch_wall[k] = c
		elif _scratch_rgba[k] == 0 or y >= _scratch_roof[k] - 1.0:
			_scratch_rgba[k] = c
	else:
		_open_colours()
		if wall:
			wall_rgba[k] = c
		elif roof_rgba[k] == 0 or y >= _roof[k] - 1.0:
			roof_rgba[k] = c


## The loading fix (sector_proxies.gd): the roof's and the wall's colour over the cell holding a
## point (alpha 0: none recorded).
func roof_colour(x: float, z: float) -> Color:
	return _grid_colour(roof_rgba, x, z)


func wall_colour(x: float, z: float) -> Color:
	return _grid_colour(wall_rgba, x, z)


func _grid_colour(grid: PackedInt32Array, x: float, z: float) -> Color:
	var i := floori((x - _roof_x0) / ROOF_CELL)
	var j := floori((z - _roof_z0) / ROOF_CELL)
	if grid.is_empty() or i < 0 or j < 0 or i >= _roof_nx or j >= _roof_nz or grid[j * _roof_nx + i] == 0:
		return Color(0, 0, 0, 0)
	return Color.hex(grid[j * _roof_nx + i])


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
	if _in_sector and not _touches(a, b, c, COVER_REACH if _cover_on else 0.01):
		return  # loop 3c: no piece of it can lie in the sector being built
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
	_emit_draped(st, a, b, c, col)


## One flat-layer triangle lifted onto the surface (each corner's own y is the layer offset),
## wound to face up, with the layer's bias and id and the street axes in the UVs. Loop 3d-2a: true
## when it was noted as covering the ground (`_cover_on`).
func _emit_draped(st, a: Vector3, b: Vector3, c: Vector3, col: Color) -> bool:
	var p := [a, b, c]
	for k in 3:
		var v: Vector3 = p[k]
		var h := _surface_height(v.x, v.z)
		if _on_grid and _dk < 0 and _tn < 0:
			# Never under the drawn ground (map round 2: the drawn ground, which follows an
			# apron in its sub-cells).
			h = maxf(h, _drawn_height(v.x, v.z))
		p[k] = Vector3(v.x, h + v.y, v.z)
	if ((p[1] - p[0]).cross(p[2] - p[0]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
		p = [p[0], p[2], p[1]]
	var noted := false
	if _cover_on and _dk < 0 and _tn < 0:
		# Loop 3d-2a: a triangle of a layer that hides the ground, noted if it lies at the ground's
		# height (game/tools/check_ground.gd reads the meshes by the same rule).
		var mid: Vector3 = (p[0] + p[1] + p[2]) / 3.0
		var dy := mid.y - _grid_height(mid.x, mid.z)
		if dy >= COVER_GRADE.x and dy <= COVER_GRADE.y:
			_cover_add(PackedVector2Array([Vector2(p[0].x, p[0].z), Vector2(p[1].x, p[1].z), Vector2(p[2].x, p[2].z)]))
			noted = true
	var axis := _axis if _axis != Vector2.ZERO else CITY_GRID
	for v in p:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(_drape_bias, _layer))
		st.set_uv2(Vector2(v.x * axis.x + v.z * axis.y, -v.x * axis.y + v.z * axis.x))
		st.add_vertex(v)
	return noted


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


## Loop 3b-2: a polygon laid exactly on the terrain grid's own triangles (the two per cell that
## _build_ground draws), for the areas (water, grass, parks, plazas, sand) and the sandbars.
## The drape's pieces (up to 12 m, each a plane through three terrain points) cut under the
## grid's folds, and there the bare earth poked through as jagged beige patches: the 10 m
## grid holds the river's sandbars and a ridge along Most Poniatowskiego's piers (the "torn
## paper" sandbars in the river), lumps in the parks (game/tools/check_drape.gd). Cells the
## outline doesn't cross go in whole (two triangles), the ones it crosses are clipped. Off
## the grid (a flat world) or when not draping it is `_fill`.
func _fill_on_grid(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	if poly.size() < 3 or _t_h.is_empty() or _drape_bias < 0.0:
		_fill(st, poly, y, col)
		return
	_on_grid = true
	_fill_grid_cells(st, poly, y, col)
	_on_grid = false


## While _fill_on_grid lays a polygon: its corners never go under the drawn ground.
var _on_grid := false


## _fill_on_grid's work: the grid cells under the polygon's box, whole or clipped.
func _fill_grid_cells(st, poly: PackedVector2Array, y: float, col: Color) -> void:
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	var lo := poly[0]
	var hi := poly[0]
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var i0 := clampi(floori((lo.x - gx) / step), 0, nx - 2)
	var i1 := clampi(floori((hi.x - gx) / step), 0, nx - 2)
	var j0 := clampi(floori((lo.y - gz) / step), 0, nz - 2)
	var j1 := clampi(floori((hi.y - gz) / step), 0, nz - 2)
	if _in_sector:
		# Loop 3c: only the cells that reach into the sector being built (the others' pieces
		# all have their centres outside it).
		i0 = maxi(i0, floori((_sector_rect.position.x - gx) / step) - 1)
		i1 = mini(i1, floori((_sector_rect.end.x - gx) / step) + 1)
		j0 = maxi(j0, floori((_sector_rect.position.y - gz) / step) - 1)
		j1 = mini(j1, floori((_sector_rect.end.y - gz) / step) + 1)
		if i0 > i1 or j0 > j1:
			return
	var w := i1 - i0 + 1
	var h := j1 - j0 + 1
	var crossed := PackedByteArray()
	crossed.resize(w * h)
	var n := poly.size()
	for k in n:
		_mark_cells(crossed, (poly[k] - Vector2(gx, gz)) / step - Vector2(i0, j0),
				(poly[(k + 1) % n] - Vector2(gx, gz)) / step - Vector2(i0, j0), w, h)
	_fine_index()
	for j in h:
		var z := gz + (j0 + j) * step
		for i in w:
			var x := gx + (i0 + i) * step
			var a := Vector2(x, z)
			var b := Vector2(x + step, z)
			var c := Vector2(x + step, z + step)
			var d := Vector2(x, z + step)
			if _fine_cells.has(Vector2i(i0 + i, j0 + j)):
				# Map round 2 (D5): a cell an apron reaches is drawn in sub-cells; lay the
				# polygon on their triangles, each clipped.
				var sub: int = _fine_cells[Vector2i(i0 + i, j0 + j)]
				var s := step / sub
				for sj in sub:
					for si in sub:
						var sa := Vector2(x + si * s, z + sj * s)
						var sb := sa + Vector2(s, 0)
						var sc := sa + Vector2(s, s)
						var sd := sa + Vector2(0, s)
						for tri in [PackedVector2Array([sa, sb, sc]), PackedVector2Array([sa, sc, sd])]:
							for piece in Geometry2D.intersect_polygons(tri, poly):
								var pidx := Geometry2D.triangulate_polygon(piece)
								for t in range(0, pidx.size(), 3):
									var p0 := piece[pidx[t]]
									var p1 := piece[pidx[t + 1]]
									var p2 := piece[pidx[t + 2]]
									if absf((p1 - p0).cross(p2 - p0)) < 0.0002:
										continue
									_emit_draped(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), col)
				continue
			if crossed[j * w + i] == 0:
				if Geometry2D.is_point_in_polygon(Vector2(x + step * 0.5, z + step * 0.5), poly):
					var upper := _emit_draped(st, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), col)
					var lower := _emit_draped(st, Vector3(a.x, y, a.y), Vector3(c.x, y, c.y), Vector3(d.x, y, d.y), col)
					if upper and lower:
						_cover_whole[Vector2i(i0 + i, j0 + j)] = true  # loop 3d-2a
				continue
			# The cell's two triangles (the diagonal _grid_height uses), each clipped.
			for tri in [PackedVector2Array([a, b, c]), PackedVector2Array([a, c, d])]:
				for piece in Geometry2D.intersect_polygons(tri, poly):
					var idx := Geometry2D.triangulate_polygon(piece)
					for t in range(0, idx.size(), 3):
						var p0 := piece[idx[t]]
						var p1 := piece[idx[t + 1]]
						var p2 := piece[idx[t + 2]]
						if absf((p1 - p0).cross(p2 - p0)) < 0.0002:
							continue
						_emit_draped(st, Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), col)


## Marks the cells of a w x h grid (cell units, from its corner) that the segment p-q passes
## through: a grid walk, one cell at a time.
static func _mark_cells(mask: PackedByteArray, p: Vector2, q: Vector2, w: int, h: int) -> void:
	var ci := floori(p.x)
	var cj := floori(p.y)
	var ei := floori(q.x)
	var ej := floori(q.y)
	var d := q - p
	var si := 1 if d.x > 0.0 else -1
	var sj := 1 if d.y > 0.0 else -1
	var tdx := absf(1.0 / d.x) if absf(d.x) > 1e-9 else INF
	var tdz := absf(1.0 / d.y) if absf(d.y) > 1e-9 else INF
	var tmx := ((ci + 1 - p.x) if d.x > 0.0 else (p.x - ci)) * tdx if tdx != INF else INF
	var tmz := ((cj + 1 - p.y) if d.y > 0.0 else (p.y - cj)) * tdz if tdz != INF else INF
	for guard in 100000:
		if ci >= 0 and cj >= 0 and ci < w and cj < h:
			mask[cj * w + ci] = 1
		if ci == ei and cj == ej:
			return
		if tmx < tmz:
			if tmx > 1.0:
				return
			tmx += tdx
			ci += si
		else:
			if tmz > 1.0:
				return
			tmz += tdz
			cj += sj


func _disc(st, p: Vector2, r: float, y: float, col: Color, segments := 8) -> void:
	var centre := Vector3(p.x, y, p.y)
	for i in segments:
		var a0 := TAU * i / segments
		var a1 := TAU * (i + 1) / segments
		_tri(st, centre, Vector3(p.x + cos(a0) * r, y, p.y + sin(a0) * r),
				Vector3(p.x + cos(a1) * r, y, p.y + sin(a1) * r), Vector3.UP, col)


## Loop 3b-2: strips laid at this depth bias or less (footways, cycle paths, steps: just over the
## areas) follow the grid's triangles exactly; the ones higher up (roads 0.3, markings) keep the
## 10 m pieces, their bias covers any sag.
const EXACT_STRIP_BIAS := 0.12


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
		if _drape_bias >= 0.0 and _drape_bias <= EXACT_STRIP_BIAS and _dk < 0 and _tn < 0 and not _t_h.is_empty():
			# Loop 3b-2: a footway, cycle path or flight of steps on the ground follows the grid's
			# own triangles (clipped to them, as the areas are), so it never sags under the area
			# it crosses (the Praga beach's footpath was dashed by its sand; check_drape.gd).
			_on_grid = true
			_fill_grid_cells(st, PackedVector2Array([a + side, b + side, b - side, a - side]), y, col)
			_on_grid = false
			continue
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
	# Loop 3d-1: the walls stand on the map's edge, not the grid's: the demo box's grid reaches
	# 4 m past its north edge, past the sector grid too (check_streaming: walls in no sector).
	# Where the grid ends on the edge (the first box) this is the same as before.
	# Map north: one wall per side of the map's outline (six with the north extension). Along a
	# side the corners are the grid's columns or rows; at a convex corner of the outline the wall
	# runs on to the grid's next node past it (as the box's four always did), at the inner corner
	# it stops on the corner (past it would stand inside the map).
	var lx1 := x0 + (nx - 1) * step
	var lz1 := z0 + (nz - 1) * step
	var ring := map_outline()
	var sides := []
	for k in ring.size():
		var a := ring[k - 1]
		var c := ring[k]
		var along_x := absf(c.x - a.x) > absf(c.y - a.y)
		var mid := (a + c) * 0.5
		var n := Vector3.ZERO
		if along_x:
			n = Vector3.FORWARD if not in_map(mid + Vector2(0, -1)) else Vector3.BACK
		else:
			n = Vector3.LEFT if not in_map(mid + Vector2(-1, 0)) else Vector3.RIGHT
		var fixed := clampf(a.y if along_x else a.x, z0 if along_x else x0, lz1 if along_x else lx1)
		var lo0 := x0 if along_x else z0
		var lo1 := lx1 if along_x else lz1
		var ends := [a.x if along_x else a.y, c.x if along_x else c.y]
		var convex := [_outline_convex(ring, k - 1), _outline_convex(ring, k)]
		var vals := PackedFloat64Array()
		var u0 := minf(ends[0], ends[1])
		var u1 := maxf(ends[0], ends[1])
		var lo_convex: bool = convex[0] if ends[0] < ends[1] else convex[1]
		var hi_convex: bool = convex[1] if ends[0] < ends[1] else convex[0]
		var first := ceili((u0 - lo0) / step - 1e-6)
		var last := floori((u1 - lo0) / step + 1e-6)
		if lo_convex:
			first = maxi(floori((u0 - lo0) / step + 1e-6), 0)
		else:
			vals.append(u0)
		for q in range(first, last + 1):
			var u := lo0 + q * step
			if u > lo1 + 1e-6:
				break
			if (vals.is_empty() or u > vals[vals.size() - 1] + 1e-6) and (lo_convex or u > u0 + 1e-6) and (hi_convex or u < u1 - 1e-6):
				vals.append(u)
		if hi_convex:
			var past := lo0 + ceili((u1 - lo0) / step - 1e-6) * step
			if past <= lo1 + 1e-6 and (vals.is_empty() or past > vals[vals.size() - 1] + 1e-6):
				vals.append(past)
		else:
			vals.append(u1)
		var pts: Array[Vector3] = []
		for u in vals:
			var px := u if along_x else fixed
			var pz := fixed if along_x else u
			pts.append(Vector3(px, _grid_height(px, pz), pz))
		sides.append([pts, n])
	for side in sides:
		var pts: Array[Vector3] = side[0]
		var n: Vector3 = side[1]
		for k in pts.size() - 1:
			var a: Vector3 = pts[k]
			var b: Vector3 = pts[k + 1]
			var a1 := Vector3(a.x, a.y - 0.8, a.z)
			var b1 := Vector3(b.x, b.y - 0.8, b.z)
			var a2 := Vector3(a.x, bottom, a.z)
			var b2 := Vector3(b.x, bottom, b.z)
			var none := Vector2(-1, -1)
			_tri_shaded(st, a, b, b1, n, top_col, top_col, soil, none, none, none)
			_tri_shaded(st, a, b1, a1, n, top_col, soil, soil, none, none, none)
			_tri_shaded(st, a1, b1, b2, n, soil, soil, deep, none, none, none)
			_tri_shaded(st, a1, b2, a2, n, soil, deep, deep, none, none, none)


## Map north: whether the outline's corner k turns the way the outline does (a corner of the map,
## not its inner corner by the part left outside).
func _outline_convex(ring: PackedVector2Array, k: int) -> bool:
	var n := ring.size()
	var a := ring[(k - 1 + n) % n]
	var b := ring[(k + n) % n]
	var c := ring[(k + 1) % n]
	var turn := (b - a).cross(c - b)
	var area := 0.0
	for i in n:
		area += ring[i].cross(ring[(i + 1) % n])
	return turn * area > 0.0


## Smooth normals from the height gradient, so slopes shade softly instead of in facets
## (loop 3c: found once, every sector's ground uses them).
func _ground_normals() -> PackedVector3Array:
	if not _gn.is_empty() or _t_h.is_empty():
		return _gn
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	_gn.resize(nx * nz)
	for j in nz:
		for i in nx:
			var hl := _t_h[j * nx + maxi(i - 1, 0)]
			var hr := _t_h[j * nx + mini(i + 1, nx - 1)]
			var hu := _t_h[maxi(j - 1, 0) * nx + i]
			var hd := _t_h[mini(j + 1, nz - 1) * nx + i]
			_gn[j * nx + i] = Vector3(hl - hr, 2.0 * step, hu - hd).normalized()
	return _gn


# --- Map round 2 (2026-10-29, D5): the drawn ground follows the aprons ------------------------
# An apron (loop 3b) holds terrain_height under a structure's end below the 10 m grid (the end
# is flat across, the grid on the cross slope isn't), and everything drawn at terrain_height
# there (the road, its carriageway area, kerbs, tram and rail beds) lay under the drawn grid:
# the beige wedge of bare ground across the viaduct's west end (0.65 m), the Wisłostrada and
# abutment-link portals (up to 1 m), the Kruczkowskiego rail viaduct, two ramps' feet
# (check_roads C11). The grid cells an apron reaches are drawn as GROUND_SUB x GROUND_SUB
# sub-cells at min(grid, terrain_height) (`_drawn_height`), with the same diagonal as the grid,
# so where nothing is lowered they are the grid's own planes; the flat layers laid on the grid
# (_fill_grid_cells) use the same sub-cells and never go under them. check_roads `Map.drawn`
# mirrors this.

## The sub-cells per grid cell side under an apron (1 m on the 10 m grid).
const GROUND_SUB := 10
## Loop 3e: a cell only a ground profile reaches (no apron) in SET_SUB x SET_SUB sub-cells (1 m,
## as the aprons': 2 m ones left the drawn ground over the road at a trench's edge, check_roads C11).
const SET_SUB := 10
## Grid cells (Vector2i(i, j)) an apron's corridor reaches, from `_aprons` (built on first use,
## the same for the whole city and each sector); loop 3e: and a lowering ground profile's, each
## with its sub-cells a side (GROUND_SUB, SET_SUB).
var _fine_cells := {}
var _fine_ready := false


func _fine_index() -> void:
	if _fine_ready:
		return
	_fine_ready = true
	_fine_cells.clear()
	if _t_h.is_empty():
		return
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	# Loop 3e: the cells a ground profile reaches (where it lowers the ground, the drawn ground
	# follows it in the 1 m sub-cells; check_roads Map.drawn the same).
	for d in _fills:
		if not bool(d["s"]):
			continue
		var reach := maxf(float(d["l"]), float(d["r"]))
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		for k in pts.size() - 1:
			# Only where it lowers the ground (a raised one stands on the grid, like an approach).
			if not _set_lowers(pts[k], pts[k + 1], minf(hs[k], hs[k + 1]), reach):
				continue
			var lo := pts[k].min(pts[k + 1]) - Vector2.ONE * reach
			var hi := pts[k].max(pts[k + 1]) + Vector2.ONE * reach
			for j in range(clampi(floori((lo.y - gz) / step), 0, nz - 2), clampi(floori((hi.y - gz) / step), 0, nz - 2) + 1):
				for i in range(clampi(floori((lo.x - gx) / step), 0, nx - 2), clampi(floori((hi.x - gx) / step), 0, nx - 2) + 1):
					_fine_cells[Vector2i(i, j)] = maxi(int(_fine_cells.get(Vector2i(i, j), 0)), SET_SUB)
	for a in _aprons:
		var o := Vector2(a[0], a[1])
		var u := Vector2(a[2], a[3])
		var n := Vector2(-u.y, u.x)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for along in [0.0, a[4]]:
			for lat in [-a[6] - APRON_TAPER, a[7] + APRON_TAPER]:
				var p: Vector2 = o + u * float(along) + n * float(lat)
				lo = lo.min(p)
				hi = hi.max(p)
		for j in range(clampi(floori((lo.y - gz) / step), 0, nz - 2), clampi(floori((hi.y - gz) / step), 0, nz - 2) + 1):
			for i in range(clampi(floori((lo.x - gx) / step), 0, nx - 2), clampi(floori((hi.x - gx) / step), 0, nx - 2) + 1):
				_fine_cells[Vector2i(i, j)] = GROUND_SUB


## Loop 3e: whether a ground profile's segment a-b (its lower end at h) lies under the grid
## anywhere over its corridor (its ends and the corridor's corners, `reach` out).
func _set_lowers(a: Vector2, b: Vector2, h: float, reach: float) -> bool:
	var ab := b - a
	var n := Vector2(-ab.y, ab.x).normalized() * reach if ab.length_squared() > 0.000001 else Vector2.ZERO
	for p: Vector2 in [a, b, a + n, a - n, b + n, b - n]:
		if h < _grid_height(p.x, p.y) - SET_FINE:
			return true
	return false


## The drawn ground's height at a sub-cell corner: the grid, or terrain_height where an apron
## holds the ground under it.
func _drawn_corner(x: float, z: float) -> float:
	var g := _grid_height(x, z)
	var t := terrain_height(x, z)
	# Loop 3e: under a ground profile that lowers the ground, SET_SINK lower still (the 1 m
	# sub-cells between two profiles' levels or across a corridor's edge stay under the road).
	if _set_hit and t < g - 0.001:
		t -= SET_SINK
	return minf(g, t)


## Loop 3e: the drawn ground's sink under a lowering ground profile (`_drawn_corner`;
## check_roads Map.drawn the same), and whether the last `_fill_height` was in one's corridor.
const SET_SINK := 0.1
## Loop 3e: a ground profile's segment gets the 1 m sub-cells where it lies this far under the grid
## anywhere (a raised one doesn't; a lowered one left out would meet its sub-celled neighbour in a
## crack at their shared edge: check_ground's height rule).
const SET_FINE := 0.001
var _set_hit := false


## The drawn ground's height at a point (the mesh `_build_ground` draws): the grid's two
## triangles per cell, or in a cell an apron reaches the sub-cells' (GROUND_SUB).
func _drawn_height(x: float, z: float) -> float:
	_fine_index()
	if _fine_cells.is_empty():
		return _grid_height(x, z)
	var step := float(_terrain["step"])
	var fx := clampf((x - float(_terrain["x0"])) / step, 0.0, int(_terrain["nx"]) - 1.0001)
	var fz := clampf((z - float(_terrain["z0"])) / step, 0.0, int(_terrain["nz"]) - 1.0001)
	var i := int(fx)
	var j := int(fz)
	if not _fine_cells.has(Vector2i(i, j)):
		return _grid_height(x, z)
	var sub: int = _fine_cells[Vector2i(i, j)]
	var s := step / sub
	var si := clampi(int((fx - i) * sub), 0, sub - 1)
	var sj := clampi(int((fz - j) * sub), 0, sub - 1)
	var x0 := float(_terrain["x0"]) + i * step + si * s
	var z0 := float(_terrain["z0"]) + j * step + sj * s
	var u := clampf((x - x0) / s, 0.0, 1.0)
	var v := clampf((z - z0) / s, 0.0, 1.0)
	var h00 := _drawn_corner(x0, z0)
	var h10 := _drawn_corner(x0 + s, z0)
	var h01 := _drawn_corner(x0, z0 + s)
	var h11 := _drawn_corner(x0 + s, z0 + s)
	if u >= v:
		return h00 + (h10 - h00) * u + (h11 - h10) * v
	return h00 + (h11 - h01) * u + (h01 - h00) * v


## One grid cell an apron reaches. Map round 2 drew it as GROUND_SUB x GROUND_SUB sub-cells of
## the drawn ground; loop 3d-2a keeps the 1 m sub-cells only where they touch a lowered point (the
## ground under an apron, below the grid by over a millimetre) and draws the rest of each half of
## the cell (the grid's two triangles) in runs along the sub-rows, which lie on the half's own
## plane: a half with no lowered point is the grid's triangle itself. The heights are the same
## (`_drawn_height`, check_roads `Map.drawn`); 339 apron cells, 67,697 triangles before.
func _ground_fine_cell(st, i: int, j: int, normals: PackedVector3Array, colour: Color) -> void:
	var step := float(_terrain["step"])
	var nx := int(_terrain["nx"])
	var cx := float(_terrain["x0"]) + i * step
	var cz := float(_terrain["z0"]) + j * step
	var sub: int = _fine_cells[Vector2i(i, j)]
	var s := step / sub
	var n00 := normals[j * nx + i]
	var n10 := normals[j * nx + i + 1]
	var n01 := normals[(j + 1) * nx + i]
	var n11 := normals[(j + 1) * nx + i + 1]
	var side := sub + 1
	# The lattice: each point's height, normal and whether an apron lowers it.
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var low := PackedByteArray()
	pos.resize(side * side)
	nrm.resize(side * side)
	low.resize(side * side)
	for b in side:
		for a in side:
			var x := cx + a * s
			var z := cz + b * s
			var g := _grid_height(x, z)
			var h := _drawn_corner(x, z)
			var k := b * side + a
			pos[k] = Vector3(x, h, z)
			low[k] = 1 if g - h > 0.001 or not ground_lean else 0
			var fu := float(a) / sub
			var fv := float(b) / sub
			var n := (n00.lerp(n10, fu)).lerp(n01.lerp(n11, fu), fv).normalized()
			if g - h > 0.01:
				# Lowered: the slope of the drawn ground itself.
				n = Vector3(_drawn_corner(x - s, z) - _drawn_corner(x + s, z), 2.0 * s,
						_drawn_corner(x, z - s) - _drawn_corner(x, z + s)).normalized()
			nrm[k] = n
	for half in 2:
		# Half 0 is the grid's triangle (0,0)-(1,0)-(1,1) (u >= v), half 1 (0,0)-(1,1)-(0,1).
		var lowered := false
		for b in side:
			for a in side:
				if low[b * side + a] == 1 and ((a >= b) if half == 0 else (a <= b)):
					lowered = true
		if not lowered:
			var far := Vector2i(sub, 0) if half == 0 else Vector2i(0, sub)
			_ground_lattice_tri(st, pos, nrm, side, [Vector2i(0, 0), far, Vector2i(sub, sub)], colour)
			continue
		for sj in sub:
			var run := -1
			for si in sub + 1:
				var inside := si < sub and ((si >= sj) if half == 0 else (si <= sj))
				var sub_low := inside and (low[sj * side + si] == 1 or low[sj * side + si + 1] == 1
						or low[(sj + 1) * side + si] == 1 or low[(sj + 1) * side + si + 1] == 1)
				if inside and not sub_low:
					if run < 0:
						run = si
					continue
				if run >= 0:
					_ground_run(st, pos, nrm, side, half, sj, run, si - 1, colour)
					run = -1
				if sub_low:
					# The sub-cell's part of this half at 1 m (both triangles off the diagonal).
					var c00 := Vector2i(si, sj)
					var c10 := Vector2i(si + 1, sj)
					var c11 := Vector2i(si + 1, sj + 1)
					var c01 := Vector2i(si, sj + 1)
					if half == 0 or si != sj:
						_ground_lattice_tri(st, pos, nrm, side, [c00, c10, c11], colour)
					if half == 1 or si != sj:
						_ground_lattice_tri(st, pos, nrm, side, [c00, c11, c01], colour)


## Loop 3d-2a: a run of unlowered sub-cells si0..si1 in sub-row sj of one half of an apron cell,
## as one quad (or a triangle at the diagonal) on the half's plane.
func _ground_run(st, pos: PackedVector3Array, nrm: PackedVector3Array, side: int, half: int, sj: int,
		si0: int, si1: int, colour: Color) -> void:
	var lb := Vector2i(si0, sj)
	var lt := Vector2i(si0, sj + 1)
	var rb := Vector2i(si1 + 1, sj)
	var rt := Vector2i(si1 + 1, sj + 1)
	if half == 0 and si0 == sj:
		lt = Vector2i(sj + 1, sj + 1)  # starts with the diagonal sub-cell's upper triangle
	if half == 1 and si1 == sj:
		rb = Vector2i(sj, sj)  # ends with the diagonal sub-cell's lower triangle
	if lb != rb and rb != rt:
		_ground_lattice_tri(st, pos, nrm, side, [lb, rb, rt], colour)
	if lt != rt and lb != lt:
		_ground_lattice_tri(st, pos, nrm, side, [lb, rt, lt], colour)


## Loop 3d-2a: one ground triangle between three lattice points of an apron cell, wound to face up.
func _ground_lattice_tri(st, pos: PackedVector3Array, nrm: PackedVector3Array, side: int, pts: Array,
		colour: Color) -> void:
	var ks: Array[int] = []
	for p: Vector2i in pts:
		ks.append(p.y * side + p.x)
	var order := [0, 1, 2]
	if ((pos[ks[1]] - pos[ks[0]]).cross(pos[ks[2]] - pos[ks[0]]).dot(Vector3.UP) > 0.0) == CLOCKWISE_FRONT:
		order = [0, 2, 1]
	for o in order:
		st.set_color(colour)
		st.set_normal(nrm[ks[o]])
		st.set_uv(Vector2(-1, -1))
		st.add_vertex(pos[ks[o]])
# --- end of map round 2 (D5) ------------------------------------------------------------------


## Loop 3d-2a: whether the pieces (flat polygons) together cover `poly` whole, to COVER_EPS m2:
## `poly` minus each piece in turn (Clipper). A piece that would cut a hole in what is left (it
## lies inside without touching its edge) is tried again after the others; the answer doesn't
## depend on the pieces' order. game/tools/check_ground.gd uses it too.
const COVER_EPS := 0.01
const COVER_SLIVER := 0.0001
## Loop 3d-2a: whether Clipper's results hold a hole: wound against the biggest one (an outline
## and the hole a piece lying wholly inside it cuts). Slivers under COVER_SLIVER m2 are dropped
## first: their windings and middles say nothing.
static func _has_hole(out: Array[PackedVector2Array]) -> bool:
	if out.size() < 2:
		return false
	var big := 0.0
	for o in out:
		var a := _poly_area(o)
		if absf(a) > absf(big):
			big = a
	for o in out:
		if _poly_area(o) * big < 0.0:
			return true
	return false


## Loop 3d-2a: how far past a ground triangle the flat layers must reach for it to be left out:
## a layer lies up to ~0.3 m over the drawn ground (a road's pieces over the grid's folds), and
## at the camera's 30 degree pitch a sight line under its edge reaches 1.7 times that inwards.
const COVER_MARGIN := 0.5
## Loop 3d-2a: a covering triangle counts when its centre lies this far under / over the grid: a
## road sunk under the ground (a hump the grid has and its pieces cut through) or standing over it
## (an approach) leaves a gap a sight line can reach, so the ground stays there.
const COVER_GRADE := Vector2(-0.25, 0.3)
## Loop 3d-2a: a sector lays the covering layers' pieces this far past its edge too (the ground
## triangles reaching out of it need them), and drops what lies outside by their tiles as before.
const COVER_REACH := 12.0
static func covers(poly: PackedVector2Array, pieces: Array[PackedVector2Array], area_test := true) -> bool:
	if area_test:
		var need := absf(_poly_area(poly)) - COVER_EPS
		var have := 0.0
		for p in pieces:
			have += absf(_poly_area(p))
		if have < need:
			return false
	var left: Array[PackedVector2Array] = [poly]
	var todo := pieces.duplicate()
	# Once no piece is left that cuts without a hole (`loose`), the rest are taken by their
	# outlines alone: what is left can only be overstated, never a gap missed.
	var loose := false
	while not todo.is_empty():
		var later: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in todo:
			var next: Array[PackedVector2Array] = []
			var holed := false
			for r in left:
				var res := Geometry2D.clip_polygons(r, piece)
				if res.size() < 2:
					next.append_array(res)
					continue
				var out: Array[PackedVector2Array] = []
				for o in res:
					if absf(_poly_area(o)) > COVER_SLIVER:
						out.append(o)
				if not _has_hole(out):
					next.append_array(out)
				elif loose:
					next.append_array(_outlines(out))
				else:
					holed = true  # an outline and a hole: keep r whole for now
					next.append(r)
			left = next
			if left.is_empty():
				return true
			if holed:
				later.append(piece)
		if _area_of(left) < COVER_EPS:
			return true
		if later.size() == todo.size():
			loose = true
		todo = later
	return _area_of(left) < COVER_EPS


static func _area_of(list: Array[PackedVector2Array]) -> float:
	var s := 0.0
	for r in list:
		s += absf(_poly_area(r))
	return s


## Loop 3d-2a: Clipper's results without their holes (wound like the biggest).
static func _outlines(out: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var big := 0.0
	for o in out:
		var a := _poly_area(o)
		if absf(a) > absf(big):
			big = a
	var keep: Array[PackedVector2Array] = []
	for o in out:
		if _poly_area(o) * big > 0.0:
			keep.append(o)
	return keep


# --- Loop 3d-2a (2026-10-30): no ground under what covers it ----------------------------------
# The flat layers laid on the ground (the areas: water, grass, parks, plazas, sand; paving,
# footways, steps, rail beds, roads and carriageway areas) are opaque and lie on or over the
# drawn ground, so a ground triangle one of them covers whole is drawn for nothing (Slop New
# York's "no ground under roads"). While those layers are laid (`_cover_on`) they note their
# outlines in plan per 10 m cell of the grid; the ground, built after them, leaves out a 10 m
# triangle they cover whole grown by COVER_MARGIN, so no sight line under a layer's edge reaches
# the gap. Not left out: the apron cells (their own drawing), the cells near an approach or an
# apron (the road there stands over the grid), the grid's outer row (the map's edge walls).
# Only at grade: a layer on a deck or in a tunnel notes nothing. game/tools/check_ground.gd
# counts what is still hidden and that nothing is left open.

## Ground triangles left out by the last build (a sector's, or the whole city's).
var ground_hidden := 0
## False: the ground as before loop 3d-2a (nothing left out, every apron sub-cell drawn), for
## check_ground.gd's before count (`--whole`).
var ground_lean := true
var _cover_on := false
var _cover: Array[PackedVector2Array] = []
var _cover_box: Array[Rect2] = []
## Grid cell (Vector2i) -> indices into _cover of the outlines whose boxes (grown by COVER_MARGIN)
## meet it.
var _cover_cells := {}
## Grid cells an area covers whole (its two triangles laid as they are).
var _cover_whole := {}
## Grid cell -> the summed area of the outlines filed under it (a quick "can't be covered").
var _cover_area := {}


func _cover_reset() -> void:
	_cover.clear()
	_cover_box.clear()
	_cover_cells.clear()
	_cover_whole.clear()
	_cover_area.clear()


## One outline (plan) of a flat layer on the ground, filed under the grid cells its box meets.
func _cover_add(poly: PackedVector2Array) -> void:
	if _t_h.is_empty() or poly.size() < 3:
		return
	var lo := poly[0]
	var hi := poly[0]
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	if _in_sector:
		# A sector tests the ground triangles in it: what lies over 24 m off can't cover them.
		var r := _sector_rect.grow(24.0)
		if hi.x < r.position.x or lo.x > r.end.x or hi.y < r.position.y or lo.y > r.end.y:
			return
	var step := float(_terrain["step"])
	var gx := float(_terrain["x0"])
	var gz := float(_terrain["z0"])
	var k := _cover.size()
	_cover.append(poly)
	_cover_box.append(Rect2(lo, hi - lo))
	var area := absf(_poly_area(poly))
	# Filed under every cell its box grown by COVER_MARGIN meets (and a little: the grown outline's
	# square corners reach 0.6 m): a ground triangle's grown outline lies in its cell grown the
	# same, so its cell's list holds all that can cover it.
	var pad := COVER_MARGIN + 0.25
	for j in range(floori((lo.y - pad - gz) / step), floori((hi.y + pad - gz) / step) + 1):
		for i in range(floori((lo.x - pad - gx) / step), floori((hi.x + pad - gx) / step) + 1):
			var key := Vector2i(i, j)
			var list: PackedInt32Array = _cover_cells.get(key, PackedInt32Array())
			list.append(k)
			_cover_cells[key] = list
			_cover_area[key] = float(_cover_area.get(key, 0.0)) + area


## Whether the ground of the 10 m cell (i, j) stays whatever covers it: the grid's outer row (the
## map's edge walls meet it) and the cells near an approach or an apron (the road there stands
## over or under the grid; the apron cells are drawn on their own). check_ground.gd asks too.
func ground_kept(i: int, j: int) -> bool:
	var nx := int(_terrain["nx"])
	var nz := int(_terrain["nz"])
	if i <= 0 or j <= 0 or i >= nx - 2 or j >= nz - 2:
		return true
	var step := float(_terrain["step"])
	var x := float(_terrain["x0"]) + i * step
	var z := float(_terrain["z0"]) + j * step
	for cz in range(floori((z - COVER_MARGIN) / FILL_CELL), floori((z + step + COVER_MARGIN) / FILL_CELL) + 1):
		for cx in range(floori((x - COVER_MARGIN) / FILL_CELL), floori((x + step + COVER_MARGIN) / FILL_CELL) + 1):
			var key := (cx + 1024) * 4096 + cz + 1024
			if _fill_cells.has(key) or _apron_cells.has(key):
				return true
	return false


## Whether the flat layers cover the 10 m cell (i, j)'s triangle whole, grown by COVER_MARGIN
## (`upper`: the u >= v one, (0,0)-(1,0)-(1,1)).
func _ground_hidden(i: int, j: int, upper: bool) -> bool:
	var step := float(_terrain["step"])
	var key := Vector2i(i, j)
	# What lies over the triangle is filed under its cell: less than its area can't cover it.
	if float(_cover_area.get(key, 0.0)) < step * step * 0.5 - COVER_EPS or ground_kept(i, j):
		return false
	# Inside an area (the river, a park): the cell and the eight round it covered whole.
	var whole := true
	for dj in range(-1, 2):
		for di in range(-1, 2):
			if whole and not _cover_whole.has(key + Vector2i(di, dj)):
				whole = false
	if whole:
		return true
	var x := float(_terrain["x0"]) + i * step
	var z := float(_terrain["z0"]) + j * step
	var tri := PackedVector2Array([Vector2(x, z), Vector2(x + step, z), Vector2(x + step, z + step)]) if upper \
			else PackedVector2Array([Vector2(x, z), Vector2(x + step, z + step), Vector2(x, z + step)])
	var list: PackedInt32Array = _cover_cells[key]
	# Quick no: the triangle's middle (nudged off the lines where pieces meet) under no piece.
	var mid := (tri[0] + tri[1] + tri[2]) / 3.0
	if not _cover_point(mid + Vector2(0.0011, 0.0007), list):
		return false
	var grown: PackedVector2Array = Geometry2D.offset_polygon(tri, COVER_MARGIN, Geometry2D.JOIN_SQUARE)[0]
	var lo := grown[0]
	var hi := grown[0]
	for p in grown:
		lo = lo.min(p)
		hi = hi.max(p)
	var pieces: Array[PackedVector2Array] = []
	for k: int in list:
		var box := _cover_box[k]
		if box.position.x < hi.x and box.end.x > lo.x and box.position.y < hi.y and box.end.y > lo.y:
			pieces.append(_cover[k])
	# ...then its grown corners and the middles of its sides.
	var n := grown.size()
	for s in n:
		for p: Vector2 in [grown[s], (grown[s] + grown[(s + 1) % n]) * 0.5]:
			if not _cover_point(p.lerp(mid, 0.013) + Vector2(0.0011, 0.0007), list):
				return false
	return covers(grown, pieces, false)


## Loop 3d-2a: whether a point lies under one of the listed outlines.
func _cover_point(p: Vector2, list: PackedInt32Array) -> bool:
	for k in list:
		if _cover_box[k].has_point(p) and Geometry2D.is_point_in_polygon(p, _cover[k]):
			return true
	return false
# --- end of loop 3d-2a ------------------------------------------------------------------------


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
	var normals := _ground_normals()
	var colour: Color = COL["ground"]
	# Loop 3c: one sector builds only the cells that reach into it.
	var ci := Vector2i(0, nx - 1)
	var cj := Vector2i(0, nz - 1)
	if _in_sector:
		ci = Vector2i(clampi(floori((_sector_rect.position.x - x0) / step) - 1, 0, nx - 1),
				clampi(floori((_sector_rect.end.x - x0) / step) + 1, 0, nx - 1))
		cj = Vector2i(clampi(floori((_sector_rect.position.y - z0) / step) - 1, 0, nz - 1),
				clampi(floori((_sector_rect.end.y - z0) / step) + 1, 0, nz - 1))
	_fine_index()
	var hidden := 0
	for j in range(cj.x, cj.y):
		for i in range(ci.x, ci.y):
			if not outside.is_empty() and _cell_outside(x0 + i * step, z0 + j * step, step):
				continue  # map north: no ground where the map isn't
			if _fine_cells.has(Vector2i(i, j)):
				_ground_fine_cell(st, i, j, normals, colour)  # map round 2 (D5), loop 3d-2a
				continue
			var k00 := j * nx + i
			var k10 := k00 + 1
			var k01 := k00 + nx
			var k11 := k01 + 1
			for tri in [[k00, k10, k11], [k00, k11, k01]]:
				# Loop 3d-2a: not under a flat layer that covers it whole (a sector tests only its own:
				# the rest is dropped by its tile anyway).
				var mid := Vector2(x0 + (i + (0.6667 if tri[1] == k10 else 0.3333)) * step,
						z0 + (j + (0.3333 if tri[1] == k10 else 0.6667)) * step)
				if ground_lean and (not _in_sector or _sector_rect.has_point(mid)) and _ground_hidden(i, j, tri[1] == k10):
					hidden += 1
					continue
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

	ground_hidden += hidden


func _build_areas(st) -> void:
	# Plazas first so parks, sand and water sit on top of them. Loop 3b-2: laid on the
	# terrain grid's own triangles (_fill_on_grid), so the bare earth never pokes through;
	# the beaches' sand (bake_banks.py) goes in under the water, which covers any of it
	# mapped past the edge.
	# Stadion Narodowy's grass embankment (landmarks.gd `embankment`): under every mapped
	# area, a few millimetres over the bare ground, so only the bank's bare slopes turn green.
	if _marks != null:
		_layer = L_GREEN
		for poly: PackedVector2Array in _marks.embankment:
			_fill_on_grid(st, poly, Y_AREA + BANK_Y, COL["grass"])
	for pass_kind in ["plaza", "green", "sand", "water"]:
		if pass_kind == "sand":
			_layer = L_SAND
			# Gap fills (`f`) under the sand, gravel over it: a millimetre apart, so where they
			# overlap the nearer one is always the same.
			for a in data.get("sand", []):
				var y := Y_AREA + (0.006 if a.has("f") else (0.008 if a.has("g") else 0.007))
				_fill_on_grid(st, _pts(a["p"]), y, GRAVEL if a.has("g") else SAND)
			continue
		for a in data["areas"]:
			var k: String = a["k"]
			var group := "plaza" if k == "plaza" else ("water" if k == "water" else "green")
			if group != pass_kind:
				continue
			# Green kinds a millimetre apart (park under grass under pitch), like the sand: laid on
			# the same grid triangles since loop 3b-2, a lawn inside a park was exactly coplanar
			# with it, and which colour won depended on the draw order (loop 3c's sectors split
			# the triangles differently, so the streamed park showed darker triangles).
			var green_y: float = GREEN_Y.get(k, 0.005)
			var y := Y_AREA + (green_y if group == "green" else 0.0) + (0.01 if group == "water" else 0.0)
			_layer = L_GREEN if group == "green" else (L_WATER if group == "water" else L_PLAZA)
			_fill_on_grid(st, _pts(a["p"]), y, COL[k])
	_layer = L_GROUND


## Loop 3b-2: sand, wet sand and earth, foam (sRGB). Sand is a little warmer and quieter than
## the bare ground (the art bible's day chroma: the ground is calmer than what you drive).
const SAND := Color("#c8b995")
const GRAVEL := Color("#a8a091")
const WET_GRAVEL := Color("#878071")
const WET_SAND := Color("#9c8c6d")
const DAMP_SAND := Color("#b0a07f")
const WET_EARTH := Color("#5f5f45")
const DAMP_EARTH := Color("#727253")
const FOAM := Color("#dce4e2")
## The natural bank's two wet bands (from the waterline inland) and the foam line (from the
## waterline out), metres; a sandbar's wet rim inside its outline. Pieces at most BAND_PIECE
## long, so the thin strips stay on the ground's folds.
const BAND_W := 0.9
const FOAM_W := 0.22
const RIM_W := 1.1
const BAND_PIECE := 2.0
## The sandbars' rim and foam depth biases (their fill lies on the grid at the caller's).
const SANDBAR_RIM_BIAS := 0.07
const SANDBAR_FOAM_BIAS := 0.09
var _sandbars: Array[PackedVector2Array] = []
var _sandbar_boxes: Array[Rect2] = []


## Loop 3b-2: the sandbars on the river (bake_banks.py: smoothed, no slivers), over the water:
## sand on the grid's triangles, a darker wet rim inside the outline and a foam line round it.
## The water test (water.bin) still counts them as river: the car never gets there.
func _build_sandbars(st) -> void:
	_sandbars.clear()
	_sandbar_boxes.clear()
	var gravel: Array[bool] = []
	for b in data.get("sandbars", []):
		var poly := _pts(b["p"])
		if poly.size() < 3:
			continue
		_sandbars.append(poly)
		gravel.append(b.has("g"))
		var box := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			box = box.expand(p)
		_sandbar_boxes.append(box.grow(0.5))
	var keep := _drape_bias
	for k in _sandbars.size():
		var poly := _sandbars[k]
		_drape_bias = keep
		_layer = L_SAND
		_fill_on_grid(st, poly, Y_AREA + 0.012, GRAVEL if gravel[k] else SAND)
		var ring := PackedVector2Array(poly)
		ring.append(poly[0])
		var inside := _inside_sign(ring)
		_drape_bias = SANDBAR_RIM_BIAS
		_layer = L_WET
		_band(st, ring, inside, 0.0, RIM_W, WET_GRAVEL if gravel[k] else WET_SAND, Y_AREA + 0.03)
		_drape_bias = SANDBAR_FOAM_BIAS
		_layer = L_FOAM
		_band(st, ring, -inside, 0.0, FOAM_W, FOAM, Y_AREA + 0.04)
	_drape_bias = keep
	_layer = L_GROUND


## Which side of a closed ring its inside is on: +1 the side Vector2(-d.y, d.x) points to.
func _inside_sign(ring: PackedVector2Array) -> float:
	return 1.0 if _ring_area(ring) > 0.0 else -1.0


## A band along a polyline between `off0` and `off1` metres out on the side `sign` (+1 the side
## Vector2(-d.y, d.x) points to), mitred at the bends (as the shore stone is), laid on the
## surface (`y` over it) in pieces of at most BAND_PIECE. `skip` (optional) leaves out the
## pieces whose middle it says yes to.
func _band(st, poly: PackedVector2Array, sign: float, off0: float, off1: float, col: Color, y: float, skip := Callable()) -> void:
	var n := poly.size()
	if n < 2:
		return
	var closed := poly[0].distance_to(poly[n - 1]) < 0.05
	var mit := PackedVector2Array()
	mit.resize(n)
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
		var cos_half := maxf(m.dot(nb if nb != Vector2.ZERO else na), 0.5)
		mit[i] = m * (sign / cos_half)
	for i in n - 1:
		var a := poly[i]
		var b := poly[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.02:
			continue
		var pieces := maxi(1, ceili(seg / BAND_PIECE))
		for k in pieces:
			var t0 := float(k) / pieces
			var t1 := float(k + 1) / pieces
			var p0 := a.lerp(b, t0)
			var p1 := a.lerp(b, t1)
			if skip.is_valid() and skip.call((p0 + p1) * 0.5):
				continue
			var m0 := mit[i].lerp(mit[i + 1], t0)
			var m1 := mit[i].lerp(mit[i + 1], t1)
			_quad(st, Vector3(p0.x + m0.x * off0, y, p0.y + m0.y * off0), Vector3(p1.x + m1.x * off0, y, p1.y + m1.y * off0),
					Vector3(p1.x + m1.x * off1, y, p1.y + m1.y * off1), Vector3(p0.x + m0.x * off1, y, p0.y + m0.y * off1),
					Vector3.UP, col)


## Whether a point lies on a sandbar (a natural bank's foam stops where a sandbar meets it).
func _on_sandbar(p: Vector2) -> bool:
	for k in _sandbars.size():
		if _sandbar_boxes[k].has_point(p) and Geometry2D.is_point_in_polygon(p, _sandbars[k]):
			return true
	return false


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


## Loop 3b-2: a surface the bake put on a bridge deck (`dk`: a bridge's pavement or tram bed,
## bake_roads.py level_surfaces) is laid on the deck; the rest on the ground's own triangles.
func _build_surfaces(st) -> void:
	for a in data.get("surfaces", []):
		var style: Array = SURFACE_STYLE.get(a["k"], ["#cfc7b5", 0.0])
		_layer = float(style[1])
		_dk = int(a.get("dk", -1))
		if _dk >= 0:
			_fill(st, _pts(a["p"]), Y_AREA + 0.01, Color(style[0]))
		else:
			_fill_on_grid(st, _pts(a["p"]), Y_AREA + 0.01, Color(style[0]))
	_dk = -1
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


## Loop 3b-2: the tram bed (a median with trams) a concrete track slab, darker than the
## pavements (its pale grey read as pavement, and with dark rails on it as a barcode), and the
## tram rails thinner and closer to it in tone.
const TRAM_BED := Color("#8c887f")
const TRAM_RAIL := Color("#6a6761")
const TRAM_RAIL_W := 0.16


## Dual-carriageway medians: raised grass, or the tram bed at road level where trams run.
func _build_medians(st) -> void:
	for m in data.get("medians", []):
		_dk = int(m.get("dk", -1))
		var grass: bool = m["k"] == "grass"
		_layer = L_GREEN if grass else L_TRAMBED
		var col: Color = COL["grass"] if grass else TRAM_BED
		var y := KERB_UP if grass else Y_ROAD + 0.005
		var s4: Array = m["s"]
		for i in range(0, s4.size() - 7, 4):
			var a := Vector3(s4[i], y, s4[i + 1])
			var b := Vector3(s4[i + 2], y, s4[i + 3])
			var c := Vector3(s4[i + 6], y, s4[i + 7])
			var d := Vector3(s4[i + 4], y, s4[i + 5])
			# The street's axes in UV2 (the slab joints run across the bed).
			_axis = Vector2(d.x - a.x, d.z - a.z).normalized() if not grass else Vector2.ZERO
			_quad(st, a, b, c, d, Vector3.UP, col)
	_axis = Vector2.ZERO
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
		if _in_sector and not _touches(Vector3(p.x, 0.0, p.y), Vector3(q.x, 0.0, q.y), Vector3(p.x, 0.0, p.y)):
			continue  # loop 3c
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
## Loop 3b-2: two pieces of one bridge (its road, tram bed and footways) further apart than the
## bake's 1.2 m look each got an outer parapet and the river showed through the gap between them
## (Most Poniatowskiego). Up to DECK_JOIN apart, the slabs now meet half way across the gap, the
## parapets there go and a low kerb marks each piece's edge (the car still can't cross it: the
## parapet's collider stays where there is a drop under it).
const DECK_JOIN := 6.0


## Per point of deck piece `di`, how far across the gap on each side another piece of its bridge
## starts (x: left, y: right; -1 none within DECK_JOIN), for the sides the bake made outer.
func _deck_gaps(di: int) -> PackedVector2Array:
	var d: Dictionary = _decks[di]
	var pts: PackedVector2Array = d["pts"]
	var outer: PackedByteArray = d["o"]
	var g := int(d["g"])
	var out := PackedVector2Array()
	out.resize(pts.size())
	if _deck_cells.is_empty():
		_index_decks()
	for i in pts.size():
		var dir := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var right := Vector2(-dir.y, dir.x)
		var gap := Vector2(-1.0, -1.0)
		var bits := int(outer[i]) if i < outer.size() else 3
		for side in [0, 1]:
			if not (bits & (1 << side)):
				continue
			var sgn := -1.0 if side == 0 else 1.0
			var edge := float(d["l"]) if side == 0 else float(d["r"])
			var t := 0.5
			while t <= DECK_JOIN:
				if _other_piece_at(di, g, pts[i] + right * sgn * (edge + t)):
					if side == 0:
						gap.x = t
					else:
						gap.y = t
					break
				t += 0.5
		out[i] = gap
	return out


## Whether a piece of deck group g other than `skip` holds the point in its corridor.
func _other_piece_at(skip: int, g: int, p: Vector2) -> bool:
	for code: int in _deck_cells.get(Vector3i(floori(p.x / DECK_CELL), floori(p.y / DECK_CELL), g), PackedInt32Array()):
		var i := code >> 12
		if i == skip:
			continue
		var d: Dictionary = _decks[i]
		var pts: PackedVector2Array = d["pts"]
		var k := code & 4095
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		if l2 < 0.000001:
			continue
		var u := (p - a).dot(ab) / l2
		if (u < 0.0 and k > 0) or (u > 1.0 and k < pts.size() - 2) or u < -0.02 or u > 1.02:
			continue
		var lat := ab.cross(p - a) / sqrt(l2)
		if lat >= -float(d["l"]) and lat <= float(d["r"]):
			return true
	return false


func _build_bridge_structures(st) -> void:
	_uv2 = Vector2(0.5, -1.0)
	var concrete := Color("#b8b2a7")
	var joined := 0.0
	for di in _decks.size():
		var d: Dictionary = _decks[di]
		if _in_sector and not (d["box"] as Rect2).grow(8.0).intersects(_sector_rect):
			continue  # loop 3c: none of this piece reaches the sector being built
		var pts: PackedVector2Array = d["pts"]
		var hs: PackedFloat32Array = d["h"]
		var outer: PackedByteArray = d["o"]
		var piers: bool = d["k"] in ["road", "rail"]
		var l := float(d["l"]) + 0.2
		var r := float(d["r"]) + 0.2
		var gaps := _deck_gaps(di)
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
			# A side whose gap to its bridge's next piece is bridged at both ends: no parapet,
			# the slab out to half way across, a kerb at the piece's own edge.
			var join := 0
			var lo := l if bits & 1 else l + 1.6
			var ro := r if bits & 2 else r + 1.6
			if bits & 1 and gaps[i].x > 0.0 and gaps[i + 1].x > 0.0:
				join |= 1
				lo = float(d["l"]) + maxf(gaps[i].x, gaps[i + 1].x) * 0.5 + 0.1
			if bits & 2 and gaps[i].y > 0.0 and gaps[i + 1].y > 0.0:
				join |= 2
				ro = float(d["r"]) + maxf(gaps[i].y, gaps[i + 1].y) * 0.5 + 0.1
			if join:
				joined += length * ((join & 1) + (join >> 1))
			bits &= ~join
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
			for side in [-1.0, 1.0]:
				if not (join & (1 if side < 0.0 else 2)):
					continue
				# The joined side: a low kerb on the piece's own edge, and the parapet's collider
				# kept where the deck stands over a drop (the gap between is no road).
				var e := (float(d["l"]) if side < 0.0 else float(d["r"])) + 0.05
				var k0: Vector2 = a + right * side * e
				var k1: Vector2 = b + right * side * e
				var k2: Vector2 = a + right * side * (e + 0.3)
				var k3: Vector2 = b + right * side * (e + 0.3)
				var kn := Vector3(right.x * side, 0.0, right.y * side)
				_quad(st, Vector3(k0.x, ya + 0.08, k0.y), Vector3(k1.x, yb + 0.08, k1.y), Vector3(k3.x, yb + 0.22, k3.y),
						Vector3(k2.x, ya + 0.22, k2.y), Vector3.UP, concrete.lightened(0.05))
				_quad(st, Vector3(k0.x, ya, k0.y), Vector3(k1.x, yb, k1.y), Vector3(k1.x, yb + 0.22, k1.y),
						Vector3(k0.x, ya + 0.22, k0.y), -kn, concrete.darkened(0.08))
				var drop2 := maxf(ya - terrain_height(k0.x, k0.y), yb - terrain_height(k1.x, k1.y))
				if (piers or d["k"] == "path" or d["k"] == "tram") and drop2 > 1.0:
					_wall_faces.append_array([Vector3(k0.x, ya - 0.2, k0.y), Vector3(k1.x, yb - 0.2, k1.y), Vector3(k1.x, yb + 1.6, k1.y),
							Vector3(k0.x, ya - 0.2, k0.y), Vector3(k1.x, yb + 1.6, k1.y), Vector3(k0.x, ya + 1.6, k0.y)])
	for p: Dictionary in data.get("decks", {}).get("piers", []):
		_pier(st, p, concrete.darkened(0.1))
	_uv2 = Vector2.ZERO
	if not _in_sector:
		print("decks: %.0f m of deck edges joined across a gap to the bridge's next piece (loop 3b-2)" % joined)


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
## The runs, each [polyline, water side (+1 left, -1 right), natural (0 built, 1 a sandy bank,
## 2 a green one: bake_banks.py)], found once for the stone, the natural banks and the collider.
var _shore_lines: Array = []
var _shore_baked := 0
var _shore_fountains := 0


## Loop 3b-2: the runs of the water's edge (see above), and the natural ones drawn: a wet band
## and a damper one inland from the waterline (sand or earth, by what the bank is), and a
## 1-px foam line on the water (not where a sandbar meets the bank). Built runs get the stone
## later (_build_shore_stone). The collider is the same on both (_build_shore): on a natural
## bank the car stops at the foam, on the wet sand.
func _build_banks(st) -> void:
	_shore_lines.clear()
	if _in_sector:
		# Loop 3c: the runs found once for the whole map, those near the sector.
		for line in _global_shore:
			if (line[3] as Rect2).intersects(_near):
				_shore_lines.append(line)
	else:
		_shore_lines = _find_shore_lines()
	_shore_fountains = 0
	for s in data.get("surfaces", []):
		if s["k"] != "fountain":
			continue
		var ring := _pts(s["p"])
		if ring.size() < 3:
			continue
		ring.append(ring[0])
		# The water is inside the ring: on the left of its way round if it runs anticlockwise
		# (a positive area here).
		_shore_lines.append([ring, 1.0 if _ring_area(ring) > 0.0 else -1.0, 0, _poly_box(ring).grow(2.0)])
		_shore_fountains += 1
	var keep := _drape_bias
	for line in _shore_lines:
		var kind: int = line[2]
		if kind == 0:
			continue
		var side: float = line[1]
		_drape_bias = keep
		_layer = L_WET
		_band(st, line[0], -side, 0.0, BAND_W, WET_EARTH if kind == 2 else WET_SAND, Y_AREA + 0.02)
		_band(st, line[0], -side, BAND_W, BAND_W * 2.0, DAMP_EARTH if kind == 2 else DAMP_SAND, Y_AREA + 0.02)
		_drape_bias = keep + 0.02
		_layer = L_FOAM
		_band(st, line[0], side, 0.0, FOAM_W, FOAM, Y_AREA + 0.04, _on_sandbar)
	_drape_bias = keep
	_layer = L_GROUND


## Loop 3c: the water's edge runs (the bake's and the ones by the decks), each [polyline,
## water side, natural kind, box]: over the whole map, so a sector takes the same runs.
func _find_shore_lines() -> Array:
	var lines := []
	var runs: Array[PackedVector2Array] = []
	var kinds: Array[int] = []
	for sh in data.get("shore", []):
		runs.append(_pts(sh["p"]))
		kinds.append(int(sh.get("n", 0)))
	_shore_baked = runs.size()
	var extra := _shore_under_decks(runs)
	runs.append_array(extra)
	for k in extra.size():
		kinds.append(0)
	for i in runs.size():
		lines.append([runs[i], _water_side(runs[i]), kinds[i], _poly_box(runs[i]).grow(2.0)])
	return lines


## The built runs' granite edge goes into the ground's mesh `st` (see above).
func _build_shore_stone(st) -> void:
	var length := 0.0
	var natural := 0.0
	var layer := _layer
	_layer = L_ISLAND
	for line in _shore_lines:
		if int(line[2]) != 0:
			var poly: PackedVector2Array = line[0]
			for i in poly.size() - 1:
				natural += poly[i].distance_to(poly[i + 1])
			continue
		length += _shore_edge(st, line[0], line[1])
	_layer = layer
	if not _in_sector:
		print("shore: %d baked runs, %d more by bridges, %d fountains, %.1f km of stone, %.1f km natural bank" % [_shore_baked,
			_shore_lines.size() - _shore_baked - _shore_fountains, _shore_fountains, length / 1000.0, natural / 1000.0])


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
			var want := in_map(p, -1.0) and not _near_segments(grid, CELL, p, 0.75)
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
## Loop 3b-2: the combined arrows 9 cells wide (they were 11: at the default view their
## 0.22 m cells and one-cell gaps ran together), the same width as the others.
const ARROW_LR := [
	".#.....#.", "##.....##", "#########", "##..#..##", ".#..#..#.", "....#....", "....#....",
	"....#....", "....#....", "....#....",
]
const ARROW_LTR := [
	"....#....", "...###...", "..#####..", "....#....", ".#..#..#.", "##..#..##", "#########",
	"##..#..##", ".#..#..#.", "....#....", "....#....",
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
				# Loop 3b-2: cells up to 0.3 m across, the arrow up to 2.7 m wide (a lane is 3+ m),
				# so a 9-cell arrow keeps whole 0.3 m strokes and gaps (2.4 m made them 0.27).
				_pixel_shape(st, rows, at, fwd, minf(0.3, 2.7 / String(rows[0]).length()), 0.5, mirror)
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
			_strip(st, rail, TRAM_RAIL_W, Y_MARK + 0.005, TRAM_RAIL)
	_dk = -1


## Loop 3d-1: whether a wall at p stands in one of `lod2_open`'s boxes (a wall in a lane's
## corridor, tools/bake_structures.py open_lod2: LoD2 and, since loop 3d-1, OSM buildings).
func _open_wall(p: Vector2, open: Array) -> bool:
	for o: Array in open:
		if absf(p.x - float(o[0])) < float(o[2]) and absf(p.y - float(o[1])) < float(o[2]):
			return true
	return false


func _build_buildings(st, keep: Array, marks) -> void:
	var list: Array = data["buildings"]
	var open: Array = data.get("lod2_open", [])
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
		var plan := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			plan = plan.expand(q)
		var skin: Dictionary = marks.skin_at(plan)
		if not skin.is_empty():
			wall = skin["wall"]
			roof = skin["roof"]
			_uv2.x = skin["mode"]

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
			if mh < 2.0 and not _open_wall((a + b) * 0.5, open):
				var g0 := ground - 1.0
				# Loop 3b: never over the building's own top (a viaduct's pillar ends under its slab).
				var g1 := ground + minf(5.0, h)
				_wall_faces.append_array([Vector3(a.x, g0, a.y), Vector3(b.x, g0, b.y), Vector3(b.x, g1, b.y),
						Vector3(a.x, g0, a.y), Vector3(b.x, g1, b.y), Vector3(a.x, g1, a.y)])
		_uv2 = Vector2(_uv2.x, -1.0)
		_fill(st, poly, ground + h, roof)
		_roof_polygon(poly, ground + h, roof, wall)
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
	var meta: Dictionary = {}
	var count := 0
	var f := PackedFloat32Array()
	# Loop 3c: one sector reads only its buildings (the split's `lod2_runs`: vertex ranges of
	# lod2.bin, one per building) and keeps them apart by that table, not by their seeds.
	var runs := PackedInt32Array()
	if _in_sector:
		_lod2_footprints = data.get("lod2_footprints", [])
		var picked := _read_lod2_runs(data.get("lod2_runs", []))
		count = picked[0]
		f = picked[1]
		runs = picked[2]
	else:
		meta = JSON.parse_string(FileAccess.get_file_as_string("res://map/lod2.json"))
		_lod2_footprints = meta.get("footprints", [])
		var bytes := FileAccess.get_file_as_bytes("res://map/lod2.bin")
		count = bytes.decode_u32(0)
		f = bytes.slice(4).to_float32_array()
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
		var clipped := _clip_lod2(pos, nrm, col, uv, uv2, cuts, runs)
		pos = clipped[0]
		nrm = clipped[1]
		col = clipped[2]
		uv = clipped[3]
		uv2 = clipped[4]
		runs = clipped[5]
		count = pos.size()
	# v0.8: whole LoD2 buildings that stand where a landmark is built are left out. The
	# bake writes each building's triangles in one run sharing its style seed (UV2.x).
	var dropped := PackedByteArray()
	dropped.resize(count / 3)
	var t0 := 0
	var ri := 0
	while t0 < count:
		var seed := uv2[t0].x
		var first := Vector2(pos[t0].x, pos[t0].z)
		var lo := first
		var hi := first
		var t1 := t0
		if not runs.is_empty():
			var end := t0 + runs[ri]
			ri += 1
			while t1 < end:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
			if t1 == t0:
				continue
		else:
			while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		if marks.replaces((lo + hi) * 0.5):
			for t in range(t0, t1, 3):
				dropped[t / 3] = 1
		else:
			# The landmarks loop: a kept building in a landmark's own stone (Muzeum Narodowe).
			var skin: Dictionary = marks.skin_at(Rect2(lo, hi - lo))
			if not skin.is_empty():
				for t in range(t0, t1):
					col[t] = skin["roof"] if nrm[t].y >= 0.7 else skin["wall"]
					uv2[t].x = skin["mode"]
		t0 = t1
	var facades := _tenement_facades(pos, nrm, col, uv2, dropped)
	col = facades[0]
	uv2 = facades[1]
	# Split into tiles by triangle, like the other city meshes (not on the roof pass).
	var tiles := {}
	for t in range(0, count if not walls.none else 0, 3):
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
				# Loop 3d-1: the triangle's edges, not its centre (a long wall's triangle reaches
				# into the lane with its centre metres away: 5 lanes in the demo box).
				var ta := Vector2(pos[t].x, pos[t].z)
				var tb := Vector2(pos[t + 1].x, pos[t + 1].z)
				var tc := Vector2(pos[t + 2].x, pos[t + 2].z)
				for o: Array in open:
					var oc := Vector2(float(o[0]), float(o[1]))
					var r := float(o[2])
					if Geometry2D.get_closest_point_to_segment(oc, ta, tb).distance_to(oc) < r \
							or Geometry2D.get_closest_point_to_segment(oc, tb, tc).distance_to(oc) < r \
							or Geometry2D.get_closest_point_to_segment(oc, tc, ta).distance_to(oc) < r:
						solid = false
						break
			if solid:
				_wall_faces.append_array([pos[t], pos[t + 1], pos[t + 2]])
		_roof_triangle(pos[t], pos[t + 1], pos[t + 2], flat_ish, col[t])
	_has_lod2 = true
	if not _in_sector:
		return meta["keep_osm"]
	# Loop 3c: the split marks the OpenStreetMap buildings LoD2 keeps (`keep`).
	var keep := []
	var list: Array = data["buildings"]
	for i in list.size():
		if list[i].has("keep"):
			keep.append(i)
	return keep


## Loop 3c: the LoD2 vertex ranges [t0, t1, ...] read from lod2.bin: [vertex count, the
## floats in lod2.bin's layout (positions, normals, colours, UV, UV2), each range's count].
func _read_lod2_runs(ranges: Array) -> Array:
	var file := FileAccess.open("res://map/lod2.bin", FileAccess.READ)
	var total := file.get_32()
	var runs := PackedInt32Array()
	var count := 0
	for r in range(0, ranges.size() - 1, 2):
		runs.append(int(ranges[r + 1]) - int(ranges[r]))
		count += runs[-1]
	var bytes := PackedByteArray()
	for block: Vector2i in [Vector2i(0, 3), Vector2i(total * 3, 3), Vector2i(total * 6, 4), Vector2i(total * 10, 2),
			Vector2i(total * 12, 2)]:
		for r in range(0, ranges.size() - 1, 2):
			var t0 := int(ranges[r])
			file.seek(4 + (block.x + t0 * block.y) * 4)
			bytes.append_array(file.get_buffer((int(ranges[r + 1]) - t0) * block.y * 4))
	return [count, bytes.to_float32_array(), runs]


## Loop 3b: the LoD2 triangles with the cut buildings clipped. A building is a run of
## triangles sharing its style seed (as `_build_lod2` finds them); a run whose box centre is a
## cut's ([x, z, top, left out]) loses everything over the top: walls are clipped at it, roof
## triangles over it are laid flat at it (they cover the footprint, so the cut is closed).
func _clip_lod2(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array, cuts: Array, runs := PackedInt32Array()) -> Array:
	# Loop 3c: `runs` (a sector's table of buildings) comes back with each one's new count.
	var o_runs := PackedInt32Array()
	var ri := 0
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
		if not runs.is_empty():
			var end := t0 + runs[ri]
			ri += 1
			while t1 < end:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		else:
			while t1 < count and uv2[t1].x == seed and Vector2(pos[t1].x, pos[t1].z).distance_to(first) < 300.0:
				for k in 3:
					var q := Vector2(pos[t1 + k].x, pos[t1 + k].z)
					lo = lo.min(q)
					hi = hi.max(q)
				t1 += 3
		var before := o_pos.size()
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
		o_runs.append(o_pos.size() - before)
		t0 = t1
	if not _in_sector:
		print("lod2: %d buildings cut under a deck (loop 3b)" % n_cut)
	return [o_pos, o_nrm, o_col, o_uv, o_uv2, o_runs if not runs.is_empty() else PackedInt32Array()]


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
	# Loop 3b-2: each crown's scale in hundredths (bake_osm.py crown_scales: 75 within 12 m of
	# a road, full size in the parks); its radius and depth shrink, its base stays (it still
	# clears a bus).
	var crowns: Array = data.get("trees3d_crown", [])
	var real_trunks: Array[Transform3D] = []
	for i in range(0, real.size() - 5, 6):
		var x := float(real[i])
		var z := float(real[i + 1])
		var f := float(crowns[i / 6]) / 100.0 if i / 6 < crowns.size() else 1.0
		var base := minf(float(real[i + 4]), float(real[i + 2]) - 1.5)
		var top := base + (float(real[i + 2]) - base) * f
		var radius := float(real[i + 3]) * f
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

	_make_shared()
	var lifted: Array[Transform3D] = []
	for t in all_spots:
		lifted.append(Transform3D(t.basis, t.origin + Vector3(0, 1.4 * t.basis.get_scale().y, 0)))
	lifted.append_array(real_trunks)
	var no_colours: Array[Color] = []
	_tree_multimesh(_shared["trunk"], _shared["trunk_mat"], lifted, no_colours)
	_tree_multimesh(_shared["broadleaf"], leaf_material, broad, broad_col)
	_tree_multimesh(_shared["conifer"], leaf_material, needle, needle_col)


## Loop 3c: the materials and meshes of the trees, lamps, signals, parked cars, props, lamp
## halos and neon signs, made once for the whole city (every sector's MultiMeshes share them;
## tools/bake_city.gd saves them once under map/shared/). The leaves and the parked cars'
## paint are `fade_materials` (the see-through hole round the car).
func _make_shared() -> void:
	if not _shared.is_empty():
		return
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.3
	trunk.height = 2.8
	trunk.radial_segments = 5
	trunk.rings = 1
	_shared["trunk"] = trunk
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color("#5e4636")
	_shared["trunk_mat"] = trunk_mat
	leaf_material = ShaderMaterial.new()
	leaf_material.shader = load("res://shaders/foliage.gdshader")
	_shared["broadleaf"] = _broadleaf_mesh()
	_shared["conifer"] = _conifer_mesh()

	var metal := StandardMaterial3D.new()
	metal.vertex_color_use_as_albedo = true
	metal.vertex_color_is_srgb = true
	metal.roughness = 0.7
	_shared["metal"] = metal
	var lamp := SurfaceTool.new()
	lamp.begin(Mesh.PRIMITIVE_TRIANGLES)
	var grey := Color("#43474c")
	_box(lamp, Vector3(0, 3.5, 0), Vector3(0.16, 7.0, 0.16), grey)
	_box(lamp, Vector3(0.6, 6.95, 0), Vector3(1.3, 0.1, 0.12), grey)
	_box(lamp, Vector3(1.2, 6.85, 0), Vector3(0.55, 0.16, 0.3), LAMP_HEAD)
	_shared["lamp"] = _mark_head(lamp.commit())
	# The landmarks loop (street furniture): the Royal Route's and the Old Town's cast-iron
	# lantern, a dark green post with a fluted foot, a collar and a four-sided lantern under a
	# cap and finial. The pole stands on the spot; the lantern is LANTERN_HEAD up.
	var lantern := SurfaceTool.new()
	lantern.begin(Mesh.PRIMITIVE_TRIANGLES)
	var iron := Color("#283029")
	_box(lantern, Vector3(0, 0.3, 0), Vector3(0.42, 0.6, 0.42), iron)
	_box(lantern, Vector3(0, 0.66, 0), Vector3(0.3, 0.12, 0.3), iron)
	_box(lantern, Vector3(0, 2.3, 0), Vector3(0.13, 3.2, 0.13), iron)
	_box(lantern, Vector3(0, 3.92, 0), Vector3(0.3, 0.1, 0.3), iron)
	_box(lantern, Vector3(0, 4.0, 0), Vector3(0.24, 0.08, 0.24), iron)
	_box(lantern, LANTERN_HEAD, Vector3(0.44, 0.6, 0.44), LAMP_HEAD)
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		_box(lantern, LANTERN_HEAD + Vector3(c.x * 0.22, 0, c.y * 0.22), Vector3(0.05, 0.62, 0.05), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.34, 0), Vector3(0.58, 0.08, 0.58), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.45, 0), Vector3(0.34, 0.14, 0.34), iron)
	_box(lantern, LANTERN_HEAD + Vector3(0, 0.62, 0), Vector3(0.06, 0.22, 0.06), iron)
	_shared["lantern"] = _mark_head(lantern.commit())
	# Plac Konstytucji's candelabras (MDM, 1952): a stone plinth, a tall iron column and three
	# lanterns, two on a crossarm and one on top. The pole stands on the spot.
	var candelabra := SurfaceTool.new()
	candelabra.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(candelabra, Vector3(0, 0.5, 0), Vector3(1.0, 1.0, 1.0), Color("#a59b88"))
	_box(candelabra, Vector3(0, 1.1, 0), Vector3(0.6, 0.2, 0.6), iron)
	_box(candelabra, Vector3(0, 4.2, 0), Vector3(0.24, 6.0, 0.24), iron)
	_box(candelabra, Vector3(0, 7.2, 0), Vector3(2.1, 0.14, 0.16), iron)
	for x in [-1.0, 1.0]:
		_box(candelabra, Vector3(x, 7.4, 0), Vector3(0.08, 0.3, 0.08), iron)
	_box(candelabra, Vector3(0, 7.7, 0), Vector3(0.1, 0.9, 0.1), iron)
	for c: Vector3 in [Vector3(-1.0, 7.9, 0), Vector3(1.0, 7.9, 0), CANDELABRA_HEAD]:
		_box(candelabra, c, Vector3(0.5, 0.7, 0.5), LAMP_HEAD)
		_box(candelabra, c + Vector3(0, 0.4, 0), Vector3(0.62, 0.1, 0.62), iron)
		_box(candelabra, c + Vector3(0, 0.55, 0), Vector3(0.08, 0.22, 0.08), iron)
	_shared["candelabra"] = _mark_head(candelabra.commit())
	var fixture := ShaderMaterial.new()
	fixture.shader = load("res://shaders/fixture.gdshader")
	_shared["fixture"] = fixture
	var signal_mesh := SurfaceTool.new()
	signal_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dark := Color("#26282b")
	_box(signal_mesh, Vector3(0, 1.8, 0), Vector3(0.14, 3.6, 0.14), dark)
	_box(signal_mesh, Vector3(0, 3.35, 0.2), Vector3(0.34, 1.0, 0.28), dark)
	_box(signal_mesh, Vector3(0, 3.65, 0.35), Vector3(0.16, 0.16, 0.04), Color("#c8432f"))
	_box(signal_mesh, Vector3(0, 3.05, 0.35), Vector3(0.16, 0.16, 0.04), Color("#4f9a52"))
	_shared["signal"] = signal_mesh.commit()
	_shared["parked"] = Models.parked_mesh()
	var car_paint := leaf_material.duplicate() as ShaderMaterial
	car_paint.set_shader_parameter("sway", 0.0)
	_shared["car_paint"] = car_paint
	fade_materials.clear()
	fade_materials.append(leaf_material)
	fade_materials.append(car_paint)

	var halo := ShaderMaterial.new()
	halo.shader = load("res://shaders/glow.gdshader")
	halo.set_shader_parameter("billboard", true)
	halo.set_shader_parameter("radial", true)
	halo.set_shader_parameter("lift", 1.5)
	halo.render_priority = 1
	_shared["halo"] = halo
	_shared["halo_quad"] = halo_quad(4.6)
	var neon := ShaderMaterial.new()
	neon.shader = load("res://shaders/neon.gdshader")
	neon.set_shader_parameter("words", Neon.atlas())
	neon.set_shader_parameter("rows", float(Neon.all_words().size()))
	_shared["neon"] = neon
	_shared["neon_quad"] = Neon.quad()

	var prop_metal := StandardMaterial3D.new()
	prop_metal.vertex_color_use_as_albedo = true
	prop_metal.vertex_color_is_srgb = true
	prop_metal.roughness = 0.75
	_shared["prop_metal"] = prop_metal
	var bench := SurfaceTool.new()
	bench.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wood := Color("#8b6a48")
	_box(bench, Vector3(0, 0.45, 0), Vector3(1.7, 0.08, 0.5), wood)
	_box(bench, Vector3(0, 0.78, 0.22), Vector3(1.7, 0.36, 0.07), wood)
	for x in [-0.7, 0.7]:
		_box(bench, Vector3(x, 0.22, 0), Vector3(0.08, 0.44, 0.45), Color("#2e3033"))
	_shared["bench"] = bench.commit()
	var bin := SurfaceTool.new()
	bin.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(bin, Vector3(0, 0.45, 0), Vector3(0.45, 0.9, 0.45), Color("#3e5a44"))
	_box(bin, Vector3(0, 0.92, 0), Vector3(0.5, 0.06, 0.5), Color("#2c2e30"))
	_shared["bin"] = bin.commit()
	var rack := SurfaceTool.new()
	rack.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in [-0.9, -0.3, 0.3, 0.9]:
		_box(rack, Vector3(0, 0.45, z), Vector3(0.7, 0.07, 0.07), Color("#8c9096"))
		for x in [-0.33, 0.33]:
			_box(rack, Vector3(x, 0.22, z), Vector3(0.06, 0.45, 0.06), Color("#8c9096"))
	_shared["rack"] = rack.commit()
	# Advertising column: green foot and cap, a poster band tinted per column.
	var column := SurfaceTool.new()
	column.begin(Mesh.PRIMITIVE_TRIANGLES)
	var green := Color("#2f5a46")
	_cylinder(column, Vector3.ZERO, 0.66, 0.5, 10, green)
	_cylinder(column, Vector3(0, 0.5, 0), 0.6, 2.4, 10, Color.WHITE)
	_cylinder(column, Vector3(0, 2.9, 0), 0.7, 0.18, 10, green)
	_cylinder(column, Vector3(0, 3.08, 0), 0.45, 0.35, 8, green)
	_cylinder(column, Vector3(0, 3.43, 0), 0.12, 0.3, 6, Color("#c9a24a"))
	_shared["column"] = column.commit()
	# Bus and tram shelter. The landmarks loop (2026-10-30): Warsaw's glass shelter, as seen
	# from the game's camera: a pale glass roof in a graphite frame overhanging the kerb, a
	# dark fascia, glass back and end, three posts, a bench, a lit poster box at the far end
	# (its faces glow at night: SHELTER_POSTER, fixture.gdshader) and the stop's blue sign
	# (D-15) on its own pole. The road is on its -z side.
	var shelter := SurfaceTool.new()
	shelter.begin(Mesh.PRIMITIVE_TRIANGLES)
	var glass := Color("#b8d3df")
	var graphite := Color("#33363b")
	# The Rondo photos (2026-10-31): Warsaw's shelter has a red frame: the roof's edge, the
	# posts and a red loop round the glass end, with an ad panel in a black case.
	var red := Color("#c8282a")
	_box(shelter, Vector3(0, 2.5, 0.08), Vector3(4.3, 0.12, 1.95), graphite)
	_box(shelter, Vector3(0, 2.57, 0.08), Vector3(4.0, 0.03, 1.7), Color("#a7c2cf"))
	_box(shelter, Vector3(0, 2.38, -0.86), Vector3(4.3, 0.3, 0.06), red)
	_box(shelter, Vector3(0, 1.3, 0.75), Vector3(3.85, 2.05, 0.04), glass)
	_box(shelter, Vector3(0, 0.12, 0.75), Vector3(3.9, 0.1, 0.06), graphite)
	_box(shelter, Vector3(-1.95, 1.3, 0.17), Vector3(0.04, 2.05, 1.15), glass)
	for x in [-1.95, 0.0, 1.95]:
		_box(shelter, Vector3(x, 1.25, 0.78), Vector3(0.09, 2.5, 0.09), red)
	# The red loop round the glass end: a post at each corner and a bar along the foot.
	_box(shelter, Vector3(-1.95, 0.05, 0.17), Vector3(0.06, 0.06, 1.2), red)
	_box(shelter, Vector3(-1.95, 2.4, -0.4), Vector3(0.06, 0.2, 0.06), red)
	# The poster box: a graphite case, a poster on each face.
	_box(shelter, Vector3(1.95, 1.2, 0.12), Vector3(0.2, 1.95, 1.3), graphite)
	for sx in [-0.11, 0.11]:
		_box(shelter, Vector3(1.95 + sx, 1.5, 0.12), Vector3(0.02, 1.0, 1.12), SHELTER_POSTER[0])
		_box(shelter, Vector3(1.95 + sx, 0.78, 0.12), Vector3(0.02, 0.44, 1.12), SHELTER_POSTER[1])
	_box(shelter, Vector3(-0.2, 0.46, 0.5), Vector3(2.2, 0.06, 0.38), Color("#5c6168"))
	for x in [-1.1, 0.7]:
		_box(shelter, Vector3(x, 0.22, 0.5), Vector3(0.06, 0.44, 0.3), graphite)
	# The stop's sign: a grey pole, a blue square with a white bus.
	_box(shelter, Vector3(-2.45, 1.35, -0.7), Vector3(0.07, 2.7, 0.07), Color("#9aa0a6"))
	_box(shelter, Vector3(-2.45, 2.45, -0.7), Vector3(0.56, 0.56, 0.05), Color("#1f5fae"))
	for sz in [-0.03, 0.03]:
		_box(shelter, Vector3(-2.45, 2.47, -0.7 + sz), Vector3(0.34, 0.2, 0.02), Color("#f2f2ee"))
		_box(shelter, Vector3(-2.45, 2.34, -0.7 + sz), Vector3(0.3, 0.05, 0.02), Color("#f2f2ee"))
	# The Rondo photos' ad panel: a big lit panel in a black case on the glass end, a poster
	# (orange over cream, SHELTER_POSTER) on both faces, glowing at night.
	_box(shelter, Vector3(-2.3, 1.3, 0.3), Vector3(0.12, 1.95, 1.2), Color("#141518"))
	for sx: float in [-0.075, 0.075]:
		_box(shelter, Vector3(-2.3 + sx, 1.5, 0.3), Vector3(0.02, 1.4, 1.02), SHELTER_POSTER[0])
		_box(shelter, Vector3(-2.3 + sx, 0.72, 0.3), Vector3(0.02, 0.2, 1.02), SHELTER_POSTER[1])
	_shared["shelter"] = _mark_glow(shelter.commit(), SHELTER_POSTER)


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
	for key: Vector2i in tiles:
		if _in_sector and key != _sector:
			continue  # loop 3c: another sector's tile
		var members: Array = tiles[key]
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
		(parent if parent != null else _out).add_child(mmi)
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
	_make_shared()
	var metal: Material = _shared["metal"]
	var spots: Array[Transform3D] = []
	var glows: Array[Color] = []
	var lanterns: Array[Transform3D] = []
	var lantern_glows: Array[Color] = []
	var royal := _royal_segments()
	var candelabras: Array[Transform3D] = []
	var candelabra_glows: Array[Color] = []
	var list: Array = data.get("lamps", [])
	for i in range(0, list.size() - 1, 2):
		var x := float(list[i])
		var z := float(list[i + 1])
		var t := Transform3D(Basis(Vector3.UP, fposmod(x * 0.37 + z * 0.11, TAU)), Vector3(x, terrain_height(x, z), z))
		if Vector2(x, z).distance_to(Vector2(CANDELABRAS.x, CANDELABRAS.y)) < CANDELABRAS.z:
			candelabras.append(t)
			candelabra_glows.append(SODIUM_GLOW)
			continue
		if _on_royal_route(x, z, royal):
			lanterns.append(t)
			lantern_glows.append(SODIUM_GLOW if _sodium_at(x, z) else LED_GLOW)
			continue
		spots.append(t)
		var head := t * Vector3(1.2, 0.0, 0.0)
		glows.append(SODIUM_GLOW if _sodium_at(head.x, head.z) else LED_GLOW)
	# The bake's own lamps (bridges; map round 2: the streets' unlit stretches too): on the deck or
	# the kerb, arm over the carriageway, sodium or LED as the light map has them at the head.
	for i in range(0, _extra_lamps.size() - 2, 3):
		var x := _extra_lamps[i]
		var z := _extra_lamps[i + 1]
		var t := Transform3D(Basis(Vector3.UP, _extra_lamps[i + 2]), Vector3(x, ground_height(x, z), z))
		spots.append(t)
		var head := t * Vector3(1.2, 0.0, 0.0)
		glows.append(SODIUM_GLOW if _sodium_at(head.x, head.z) else LED_GLOW)
	var none: Array[Color] = []
	for mmi in _tree_multimesh(_shared["lamp"], _shared["fixture"], spots, none, glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	for mmi in _tree_multimesh(_shared["lantern"], _shared["fixture"], lanterns, none, lantern_glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	for mmi in _tree_multimesh(_shared["candelabra"], _shared["fixture"], candelabras, none, candelabra_glows):
		mmi.add_to_group(SMALL_CASTERS, true)
	var heads: Array[Transform3D] = []
	for t in spots:
		heads.append(Transform3D(Basis(), t * Vector3(1.2, 6.78, 0.0)))
	for t in lanterns:
		heads.append(Transform3D(Basis(), t * LANTERN_HEAD))
	for t in candelabras:
		heads.append(Transform3D(Basis(), t * Vector3(0, 7.9, 0)))
	glows.append_array(lantern_glows)
	glows.append_array(candelabra_glows)
	_build_lamp_halos(heads, glows)

	spots = []
	list = data.get("signals", [])
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	for mmi in _tree_multimesh(_shared["signal"], metal, spots, none):
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
	for mmi in _tree_multimesh(_shared["parked"], _shared["car_paint"], spots, paints):
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
## The landmarks loop: the shelter's poster box faces (an orange poster over a cream band),
## lit at night in SHELTER_GLOW through the street lamps' fixture.gdshader.
const SHELTER_POSTER := [Color("#e8603f"), Color("#f1e7cf")]
const SHELTER_GLOW := Color(0.62, 0.66, 0.72)
const SODIUM_GLOW := Color(1.0, 0.45, 0.12, 0.6)
const LED_GLOW := Color(0.72, 0.82, 1.0, 0.5)


## The landmarks loop (street furniture): the historic lantern's glass centre above its spot.
const LANTERN_HEAD := Vector3(0, 4.38, 0)
## Streets whose lamps are the historic lanterns (the Royal Route and round the Old Town),
## within ROYAL_REACH metres of the carriageway's edge; and the Old Town itself, a circle.
const ROYAL_STREETS := ["Krakowskie Przedmieście", "Nowy Świat", "Senatorska", "Miodowa", "Podwale",
		"Kozia", "Brzozowa"]
const ROYAL_REACH := 8.0
const OLD_TOWN := Vector3(-760.0, -1680.0, 190.0)
## Plac Konstytucji (x, z, radius): its lamps are MDM's candelabras, three lanterns each.
const CANDELABRAS := Vector3(-533.8, 1282.4, 75.0)
const CANDELABRA_HEAD := Vector3(0, 8.5, 0)

## The landmarks loop (Old Town): the historic districts (x, z, radius), the Old Town and the
## New Town, where GUGiK models a whole block of tenements as one building (Rynek's sides are
## 49 and 84 OpenStreetMap houses in one model), so it stood in one colour like a modern block.
const HISTORIC := [Vector3(-760.0, -1680.0, 200.0), Vector3(-830.0, -1920.0, 170.0)]
## Their tenements' own colours where OpenStreetMap has none (ochre, salmon, cream, terracotta,
## pale yellow, sage, blue-grey, peach, oxblood): the rebuilt Old Town's palette.
const TENEMENTS := ["#d9a441", "#e1968f", "#ebe1d1", "#c8733f", "#efd9a0", "#a9b98a", "#9fb6cf",
		"#f0c1ab", "#9c4a43", "#e8c07a", "#cf8c59", "#dcc9a3"]
## Their pitched roofs' tiles, half mixed into the aerial photo's colour (which reads pale pink).
const TILES := ["#9c4a35", "#a85a3e", "#8a4434", "#b0603f", "#94503c"]
## Kinds whose walls keep their own colour there (the churches: a skin or brick of their own).
const NOT_TENEMENTS := ["church", "cathedral", "chapel", "monastery", "convent", "religious"]


## The historic districts: each LoD2 wall in them takes the colour and window seed of the
## OpenStreetMap house it stands on (its centre a metre inside the wall), so a block reads as
## a row of tenements, each its own colour and window rhythm, under a tiled roof. Load time only, both city paths
## (the house's own data, never which sector it came in). Returns [colours, UV2s] (packed
## arrays are copies).
func _tenement_facades(pos: PackedVector3Array, nrm: PackedVector3Array, col: PackedColorArray,
		uv2: PackedVector2Array, dropped: PackedByteArray) -> Array:
	var cell := 24.0
	var grid := {}
	var polys: Array[PackedVector2Array] = []
	var looks: Array[Color] = []
	var seeds: Array[float] = []
	var roofs: Array[Color] = []
	for bld in data.get("buildings", []):
		var p: Array = bld["p"]
		if p.size() < 6 or NOT_TENEMENTS.has(str(bld.get("kind", ""))):
			continue
		var poly := _pts(p)
		var box := Rect2(poly[0], Vector2.ZERO)
		for q in poly:
			box = box.expand(q)
		if not _historic(box.get_center(), 40.0):
			continue
		var hsh := absi(int(poly[0].x * 73.0 + poly[0].y * 31.0))
		var k := polys.size()
		polys.append(poly)
		looks.append(_osm_colour(bld["c"], Color(TENEMENTS[hsh % TENEMENTS.size()])))
		seeds.append(fposmod(hsh * 0.6180339887, 1.0))
		roofs.append(Color(TILES[hsh % TILES.size()]))
		for gx in range(floori(box.position.x / cell), floori(box.end.x / cell) + 1):
			for gz in range(floori(box.position.y / cell), floori(box.end.y / cell) + 1):
				var key := Vector2i(gx, gz)
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append(k)
	if polys.is_empty():
		return [col, uv2]
	for t in range(0, pos.size(), 3):
		if dropped[t / 3] or uv2[t].x >= 1.0 or col[t].a < 0.9 or nrm[t].y > 0.95 or nrm[t].y < -0.3:
			continue  # a landmark's, glass, a flat roof or an underside
		var pitched := nrm[t].y >= 0.3
		var c := (pos[t] + pos[t + 1] + pos[t + 2]) / 3.0
		# A wall's house is a metre behind it; a roof slope's is under its centre.
		var probe := Vector2(c.x, c.z) if pitched else Vector2(c.x, c.z) - Vector2(nrm[t].x, nrm[t].z).normalized()
		if not _historic(probe, 0.0):
			continue
		var cands: Array = grid.get(Vector2i(floori(probe.x / cell), floori(probe.y / cell)), [])
		for k in cands:
			if Geometry2D.is_point_in_polygon(probe, polys[k]):
				for v in 3:
					if pitched:
						col[t + v] = col[t + v].lerp(roofs[k], 0.5)
					else:
						col[t + v] = looks[k]
						uv2[t + v].x = seeds[k]
				break
	return [col, uv2]


## Whether a point is within `slack` metres of a historic district (HISTORIC).
func _historic(at: Vector2, slack: float) -> bool:
	for d in HISTORIC:
		if at.distance_to(Vector2(d.x, d.y)) < d.z + slack:
			return true
	return false


## The named Royal Route streets' segments in this map or sector: [a, b, half width + reach].
func _royal_segments() -> Array:
	var out := []
	for r in data.get("roads", []):
		if not ROYAL_STREETS.has(r.get("name", "")):
			continue
		var p: Array = r["p"]
		var reach := float(r.get("w", 6.0)) * 0.5 + ROYAL_REACH
		for i in range(0, p.size() - 3, 2):
			out.append([Vector2(float(p[i]), float(p[i + 1])), Vector2(float(p[i + 2]), float(p[i + 3])), reach])
	return out


## Whether a lamp at (x, z) is one of the historic lanterns.
func _on_royal_route(x: float, z: float, royal: Array) -> bool:
	var at := Vector2(x, z)
	if at.distance_to(Vector2(OLD_TOWN.x, OLD_TOWN.y)) < OLD_TOWN.z:
		return true
	for s in royal:
		if absf(at.x - s[0].x) > 100.0 or absf(at.y - s[0].y) > 100.0:
			continue
		if Geometry2D.get_closest_point_to_segment(at, s[0], s[1]).distance_to(at) < float(s[2]):
			return true
	return false


## Marks the lamp head's vertices (its colour) with UV.x = 1, so fixture.gdshader
## knows what glows.
func _mark_head(mesh: ArrayMesh) -> ArrayMesh:
	return _mark_glow(mesh, [LAMP_HEAD])


## The landmarks loop: _mark_head for any parts, by their colours (the shelter's posters).
func _mark_glow(mesh: ArrayMesh, glowing: Array) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in colours.size():
		var lit := false
		for c: Color in glowing:
			lit = lit or colours[i].is_equal_approx(c)
		uv[i] = Vector2(1.0, 1.0) if lit else Vector2(-1.0, -1.0)
	arrays[Mesh.ARRAY_TEX_UV] = uv
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## A soft glow round every lamp head (glow.gdshader, billboards; `heads` in world space),
## under a "LampHalos" node the game shows only when the lights are on.
func _build_lamp_halos(heads: Array[Transform3D], glows: Array[Color]) -> void:
	var holder := Node3D.new()
	holder.name = "LampHalos"
	# Loop 3c: in the group main.gd shows at night, so every sector's halos follow the lights.
	holder.add_to_group("night_lights", true)
	_out.add_child(holder)
	var none: Array[Color] = []
	_tree_multimesh(_shared["halo_quad"], _shared["halo"], heads, glows, none, holder)
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
## The landmarks loop: the landmarks' own big signs (`marks.signs`: word, the middle of its
## bottom edge, the wall's outward normal, the scale over a shop sign), lit by day and night
## (INSTANCE_CUSTOM.z = 2), so not under the night lights' holder.
## Loop 3e merge: the sectors share one Landmarks, whose `signs` grow with every landmark it
## builds, and a landmark can be built by more than one sector; so each sector takes only the
## signs standing in it, and the list is emptied after each build.
func _build_landmark_signs(marks) -> void:
	var list: Array = marks.signs.duplicate()
	marks.signs.clear()
	if _in_sector:
		list = list.filter(func(s: Array) -> bool: return _sector_rect.has_point(Vector2((s[1] as Vector3).x, (s[1] as Vector3).z)))
	if list.is_empty():
		return
	_make_shared()
	var spots: Array[Transform3D] = []
	var colours: Array[Color] = []
	var custom: Array[Color] = []
	var all := Neon.all_words()
	for sign: Array in list:
		var word: String = sign[0]
		var t := Neon.place(word, sign[1], sign[2])
		var k: float = sign[3]
		t.basis = Basis(t.basis.x * k, t.basis.y * k, t.basis.z)
		t.origin = sign[1] + Vector3.UP * (t.basis.y.length() * 0.5) + (sign[2] as Vector3).normalized() * 0.4
		spots.append(t)
		colours.append(sign[4])
		custom.append(Color(all.find(word), float(Neon.word_width(word) + 2 * Neon.PAD) / Neon.ATLAS_W, 2.0, 0.0))
	var holder := Node3D.new()
	holder.name = "LandmarkSigns"
	_out.add_child(holder)
	_tree_multimesh(_shared["neon_quad"], _shared["neon"], spots, colours, custom, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


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
			if _built_roof(front.x, front.y) != NO_ROOF or not _street_ahead(streets, mid, out):
				continue
			var ground := terrain_height(mid.x, mid.y)
			var inside := mid - out * 2.5
			if _built_roof(inside.x, inside.y) < ground + 6.0:
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
	_make_shared()
	var holder := Node3D.new()
	holder.name = "Neon"
	holder.add_to_group("night_lights", true)  # loop 3c, as the lamp halos
	_out.add_child(holder)
	_tree_multimesh(_shared["neon_quad"], _shared["neon"], spots, colours, custom, holder)
	for c in holder.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if holder.get_child_count() == 0:
		holder.free()  # loop 3c: this sector's signs all stand in its neighbours
	if not _in_sector:
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


## Benches, bins, bike racks, bus shelters and Warsaw's advertising columns. The easy-driving
## loop (2026-10-30, the user's call): the small ones (benches, bins, bike racks, columns) are not
## obstacles, the car drives through them like the lamps and signal poles; shelters stay solid.
func _build_props() -> void:
	_make_shared()
	var metal: Material = _shared["prop_metal"]
	var none: Array[Color] = []
	_props(_shared["bench"], metal, data.get("benches", []), 0.0, none, true)
	_props(_shared["bin"], metal, data.get("bins", []), 0.0, none, true)
	_props(_shared["rack"], metal, data.get("bikes", []), 0.0, none, true)
	var tints: Array[Color] = []
	var list: Array = data.get("columns", [])
	for i in range(0, list.size() - 2, 3):
		tints.append(Color(POSTER[int(absf(float(list[i]) * 7.0 + float(list[i + 1]) * 3.0)) % POSTER.size()]))
	_props(_shared["column"], metal, list, 0.0, tints)
	var shelters: Array = data.get("shelters", [])
	var glows: Array[Color] = []
	glows.resize(shelters.size() / 3)
	glows.fill(SHELTER_GLOW)
	_props(_shared["shelter"], _shared["fixture"], shelters, 4.0, none, false, glows)


## Instances of one prop at (x, z, yaw) triples; props bigger than `solid` metres
## across become obstacles. `fine`: under a metre tall (loop 2b: no shadow, FINE_GROUP).
func _props(mesh: Mesh, material: Material, list: Array, solid: float, tints: Array[Color], fine := false,
		custom: Array[Color] = []) -> void:
	var spots: Array[Transform3D] = []
	for i in range(0, list.size() - 2, 3):
		var x := float(list[i])
		var z := float(list[i + 1])
		spots.append(Transform3D(Basis(Vector3.UP, float(list[i + 2])), Vector3(x, terrain_height(x, z), z)))
	for mmi in _tree_multimesh(mesh, material, spots, tints, custom):
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
	var faces := _wall_faces
	if _in_sector:
		# Loop 3c: the faces whose centre lies in the sector (each face in exactly one).
		faces = PackedVector3Array()
		for i in range(0, _wall_faces.size() - 2, 3):
			var c := (_wall_faces[i] + _wall_faces[i + 1] + _wall_faces[i + 2]) / 3.0
			if _sector_rect.has_point(Vector2(c.x, c.z)):
				faces.append_array([_wall_faces[i], _wall_faces[i + 1], _wall_faces[i + 2]])
		if faces.is_empty():
			return
	var body := StaticBody3D.new()
	if _in_sector:
		# Loop 3d-2b: a sector's faces in shapes of at most COLLIDER_CHUNK faces, sorted by 64 m
		# cell (each shape a compact patch). The physics server builds a shape made on the
		# streamer's worker on the main thread, at once: a sector's 7,000-19,000 faces as one shape
		# stalled the frame its load ended 5-20 ms on the Mac; the prebuilt sector's worker loads
		# these one a frame (tools/bake_city.gd saves each as a piece). The faces are the same.
		for part in _collider_chunks(faces):
			var cs := CollisionShape3D.new()
			var piece := ConcavePolygonShape3D.new()
			piece.backface_collision = true
			piece.set_faces(part)
			cs.shape = piece
			body.add_child(cs)
		_out.add_child(body)
		return
	var shape := CollisionShape3D.new()
	var concave := ConcavePolygonShape3D.new()
	concave.backface_collision = true
	concave.set_faces(faces)
	shape.shape = concave
	body.add_child(shape)
	_add_edge_walls(body)
	add_child(body)


## Loop 3d-2b: a sector's collider faces, at most this many to a shape (_build_collision).
const COLLIDER_CHUNK := 1000


## Loop 3d-2b: the faces (three vertices each) in runs of at most COLLIDER_CHUNK, sorted by the
## 64 m cell of each face's centre (row by row), so each run is a compact patch.
func _collider_chunks(faces: PackedVector3Array) -> Array[PackedVector3Array]:
	var order := []
	for i in range(0, faces.size() - 2, 3):
		var c := (faces[i] + faces[i + 1] + faces[i + 2]) / 3.0
		order.append([floori(c.z / 64.0) * 4096 + floori(c.x / 64.0), i])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array[PackedVector3Array] = []
	var part := PackedVector3Array()
	for o: Array in order:
		var i: int = o[1]
		part.append_array([faces[i], faces[i + 1], faces[i + 2]])
		if part.size() >= COLLIDER_CHUNK * 3:
			out.append(part)
			part = PackedVector3Array()
	if not part.is_empty():
		out.append(part)
	return out


## Loop 3c: the walls at the map's edge on their own body (the streamed city's index).
func _build_edge_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Edges"
	_add_edge_walls(body)
	add_child(body)


## Invisible walls at the edge of the baked area (map north: along the map's outline, 5 m in;
## four walls for a box, six with the north extension).
func _add_edge_walls(body: StaticBody3D) -> void:
	var ring := map_outline(-5.0)
	for k in ring.size():
		var a := ring[k - 1]
		var c := ring[k]
		var mid := (a + c) * 0.5
		var along_x := absf(c.x - a.x) > absf(c.y - a.y)
		var edge := [Vector3(mid.x, 50, mid.y),
				Vector3(absf(c.x - a.x), 200, 1) if along_x else Vector3(1, 200, absf(c.y - a.y))]
		var wall := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = edge[1]
		wall.shape = box
		wall.position = edge[0]
		body.add_child(wall)
