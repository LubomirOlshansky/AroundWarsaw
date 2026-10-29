extends RefCounted
## Loop 3d-1: the pedestrian zones (docs/design/police.md 5.6): the polygons tools/bake_osm.py
## writes as `ped_zones` (the Old Town, Plac Zamkowy, Krakowskie Przedmieście's car-free north
## end; each {"z": zone id, "p": flat ring}), filed in 32 m cells so the per-frame test is a
## few point-in-polygon checks. Traffic never enters them (highway=pedestrian is not in the lane
## graph); main.gd caps the player's car at CAP there. The pill, the guards and the clamp are
## loop 3g-2's (police.md 5.6).

const CELL := 32.0
## The player's top speed inside a zone, m/s (20 km/h, police.md 14).
const CAP := 20.0 / 3.6

var _rings: Array[PackedVector2Array] = []
var _ids: PackedStringArray = []
var _cells := {}


func _init(zones: Array) -> void:
	for zone: Dictionary in zones:
		var flat: Array = zone["p"]
		var ring := PackedVector2Array()
		for k in range(0, flat.size() - 1, 2):
			ring.append(Vector2(flat[k], flat[k + 1]))
		if ring.size() < 3:
			continue
		var r := _rings.size()
		_rings.append(ring)
		_ids.append(String(zone.get("z", "")))
		var lo := ring[0]
		var hi := ring[0]
		for p in ring:
			lo = lo.min(p)
			hi = hi.max(p)
		for i in range(floori(lo.x / CELL), floori(hi.x / CELL) + 1):
			for j in range(floori(lo.y / CELL), floori(hi.y / CELL) + 1):
				var key := Vector2i(i, j)
				if not _cells.has(key):
					_cells[key] = PackedInt32Array()
				var list: PackedInt32Array = _cells[key]
				list.append(r)
				_cells[key] = list


## How many polygons there are.
func size() -> int:
	return _rings.size()


## The zone id at (x, z), or "" outside every zone.
func at(x: float, z: float) -> String:
	var key := Vector2i(floori(x / CELL), floori(z / CELL))
	if not _cells.has(key):
		return ""
	var p := Vector2(x, z)
	for r: int in _cells[key]:
		if Geometry2D.is_point_in_polygon(p, _rings[r]):
			return _ids[r]
	return ""
