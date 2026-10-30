extends RefCounted
## Loop 3d-2b: the AO, lamp-light and surface maps per sector (BACKLOG "From loop 3d-1": as whole
## textures they were 93 MB of video memory on the demo map, held all the time).
##
## Each sector carries its slice of the three maps (map_builder.gd `map_slices`: the whole map's
## own texels over the sector, MARGIN texels round it, the map's edge repeated past its end); a
## sector that comes in puts its slices into a free layer ("slot") of three texture arrays, and
## gives it back when it goes. A tiny table (one texel per sector, the slot + 1, 0 for none) tells
## every shader which slot holds the sector under a point (city_maps.gdshaderinc), so the ground,
## the buildings, the trees, the vehicles and the post pass all read the maps by world position
## as before, through global shader uniforms (project.godot [shader_globals]): nothing per
## material. The texels are the whole map's, at the same places, so two sectors meet without a
## seam; where no sector is loaded the maps read as empty (no shade, no lamp light, no water).
##
## The arrays have SLOTS layers (the streamer never holds more sectors in full than that); the
## whole city at once (--monolithic, --sectors=all) gets one layer per sector.

## Texels round a sector's square in its slice (bilinear filtering reads one past the edge).
const MARGIN := 2
## Layers in the arrays: the most sectors in full detail at once (sector_streamer.gd keeps to it).
const SLOTS := 24
const SECTOR := 512.0

## The maps' grids: x0, z0, metres a texel, the slice's texels a side (map_builder.gd map_grids).
var fine := Vector4.ZERO
var surface := Vector4.ZERO
var slots := 0
var _ao: Texture2DArray
var _light: Texture2DArray
var _surface: Texture2DArray
var _table: Image
var _table_tex: ImageTexture
var _origin := Vector2i.ZERO
var _free: Array[int] = []
var _slot_of := {}  # sector key -> slot


## The slice's side in texels for a map of `px` metres a texel.
static func slice_texels(px: float) -> int:
	return int(ceil(SECTOR / px)) + 2 * MARGIN


## The first whole-map texel (column or row) of the slice of the sector starting at `start`
## metres, for a map starting at `origin` with `px` metres a texel.
static func slice_start(start: float, origin: float, px: float) -> int:
	return floori((start - origin) / px) - MARGIN


## A sector's slice of a whole map `img` (grid: x0, z0, metres a texel): the texels from
## slice_start on, the map's edge rows and columns repeated past its end (what the whole texture's
## clamped sampling read there).
static func cut(img: Image, grid: Vector4, key: Vector2i) -> Image:
	var n := slice_texels(grid.z)
	var tx := slice_start(key.x * SECTOR, grid.x, grid.z)
	var tz := slice_start(key.y * SECTOR, grid.y, grid.z)
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create_empty(n, n, false, img.get_format())
	# The part inside the map, then its edges carried outwards.
	var x0 := clampi(tx, 0, w - 1)
	var x1 := clampi(tx + n, 1, w)
	var z0 := clampi(tz, 0, h - 1)
	var z1 := clampi(tz + n, 1, h)
	var dx := x0 - tx
	var dz := z0 - tz
	if x1 > x0 and z1 > z0:
		out.blit_rect(img, Rect2i(x0, z0, x1 - x0, z1 - z0), Vector2i(dx, dz))
	var cols := x1 - x0
	var rows := z1 - z0
	if tx >= w or tx + n <= 0 or tz >= h or tz + n <= 0:
		# Wholly off the map: its nearest texel everywhere (rare: the sliver sectors' corners).
		out.blit_rect(img, Rect2i(x0, z0, 1, 1), Vector2i.ZERO)
		cols = 1
		rows = 1
		dx = 0
		dz = 0
	if dx > 0:
		var strip := out.get_region(Rect2i(dx, dz, 1, rows))
		for i in dx:
			out.blit_rect(strip, Rect2i(0, 0, 1, rows), Vector2i(i, dz))
	if dx + cols < n:
		var strip := out.get_region(Rect2i(dx + cols - 1, dz, 1, rows))
		for i in range(dx + cols, n):
			out.blit_rect(strip, Rect2i(0, 0, 1, rows), Vector2i(i, dz))
	if dz > 0:
		var strip := out.get_region(Rect2i(0, dz, n, 1))
		for j in dz:
			out.blit_rect(strip, Rect2i(0, 0, n, 1), Vector2i(0, j))
	if dz + rows < n:
		var strip := out.get_region(Rect2i(0, dz + rows - 1, n, 1))
		for j in range(dz + rows, n):
			out.blit_rect(strip, Rect2i(0, 0, n, 1), Vector2i(0, j))
	return out


## The arrays and the table for the sector grid `keys`, `count` layers.
func setup(keys: Array[Vector2i], fine_grid: Vector4, surface_grid: Vector4, count: int) -> void:
	slots = clampi(count, 1, 255)
	fine = Vector4(fine_grid.x, fine_grid.y, fine_grid.z, slice_texels(fine_grid.z))
	surface = Vector4(surface_grid.x, surface_grid.y, surface_grid.z, slice_texels(surface_grid.z))
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := -lo
	for k in keys:
		lo = Vector2i(mini(lo.x, k.x), mini(lo.y, k.y))
		hi = Vector2i(maxi(hi.x, k.x), maxi(hi.y, k.y))
	if keys.is_empty():
		lo = Vector2i.ZERO
		hi = Vector2i.ZERO
	_origin = lo
	var size := hi - lo + Vector2i.ONE
	_table = Image.create_empty(size.x, size.y, false, Image.FORMAT_R8)
	_table_tex = ImageTexture.create_from_image(_table)
	_ao = _blank_array(int(fine.w), Image.FORMAT_RG8, Color(1, 1, 0))
	_light = _blank_array(int(fine.w), Image.FORMAT_RG8, Color(0, 0, 0))
	_surface = _blank_array(int(surface.w), Image.FORMAT_RGBA8, Color(0, 0, 0, 0))
	_free.clear()
	for s in range(slots - 1, -1, -1):
		_free.append(s)
	_slot_of.clear()
	var rs := RenderingServer
	rs.global_shader_parameter_set("city_ao", _ao)
	rs.global_shader_parameter_set("city_light", _light)
	rs.global_shader_parameter_set("city_surface", _surface)
	rs.global_shader_parameter_set("city_slots", _table_tex)
	rs.global_shader_parameter_set("city_slots_grid", Vector4(lo.x, lo.y, size.x, size.y))
	rs.global_shader_parameter_set("city_fine_map", fine)
	rs.global_shader_parameter_set("city_surface_map", surface)


func _blank_array(n: int, format: Image.Format, fill: Color) -> Texture2DArray:
	var img := Image.create_empty(n, n, false, format)
	img.fill(fill)
	var layers: Array[Image] = []
	for s in slots:
		layers.append(img)
	var arr := Texture2DArray.new()
	arr.create_from_images(layers)
	return arr


## Whether the sector's slices are in.
func has(key: Vector2i) -> bool:
	return _slot_of.has(key)


func free_slots() -> int:
	return _free.size()


## Puts a sector's slices ([ao, light, surface]; `part` -1 all three, else only that one: the
## streamer spreads them over frames) into its slot, taking one first. False when none is free
## or the slices don't fit.
func attach(key: Vector2i, slices: Array, part := -1) -> bool:
	if slices.size() != 3:
		return false
	var slot: int = _slot_of.get(key, -1)
	if slot < 0:
		if _free.is_empty():
			return false
		slot = _free.pop_back()
		_slot_of[key] = slot
	var arrays: Array[Texture2DArray] = [_ao, _light, _surface]
	for k in 3:
		if part >= 0 and k != part:
			continue
		var img: Image = slices[k]
		if img == null or img.get_width() != arrays[k].get_width() or img.get_format() != arrays[k].get_format():
			push_warning("city maps: %s's slice %d doesn't fit (%s)" % [key, k, img])
			continue
		arrays[k].update_layer(img, slot)
	return true


## The sector's slot shows its slices (after attach: the table says where they are).
func show(key: Vector2i) -> void:
	_set_table(key, int(_slot_of.get(key, -1)) + 1)


## The sector's slot goes back; the table forgets it.
func detach(key: Vector2i) -> void:
	if not _slot_of.has(key):
		return
	_free.append(int(_slot_of[key]))
	_slot_of.erase(key)
	_set_table(key, 0)


func _set_table(key: Vector2i, value: int) -> void:
	var c := key - _origin
	if c.x < 0 or c.y < 0 or c.x >= _table.get_width() or c.y >= _table.get_height():
		return
	_table.set_pixel(c.x, c.y, Color8(value, 0, 0))
	_table_tex.update(_table)
