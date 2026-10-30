extends RefCounted
## The memory loop (2026-10-30): the whole map's index, made smaller once the city is open.
## JSON gives every coordinate as its own Variant in an Array (about 24 bytes each, plus each
## Array's own allocation), and the index holds over a million of them. They become
## PackedFloat32Arrays (4 bytes each): the flat outlines (`p`) of the lists of features, the
## laser-scanned trees and the parked cars, and the lane graph's nodes and lanes. The parsed
## index.json went from 130 to 64 MB on the desktop.
##
## Packed in place, after the builder's own set-up has read the index (sector_streamer.gd
## open, open_whole) and before the prebuilt index is saved (tools/bake_city.gd), so both
## city paths hand the game the same data. A reader that still declares `var flat: Array =
## r["p"]` gets a copy (GDScript converts a packed array to an Array on assignment), so
## nothing breaks; the game's start-up readers take the packed array as it is. Float32 keeps a
## coordinate within 0.25 mm across the map (±3.2 km). Running it twice does nothing more.

## Lists of features whose `p` (a flat x, z outline) is packed.
const OUTLINED := ["areas", "paths", "roads", "landmarks", "trams", "platforms", "kerbs", "medians",
		"site_parts", "fills", "islands", "ped_zones"]
## Flat lists of numbers packed whole: [x, z, ...] runs per tree and per parked car.
const FLAT := ["trees3d", "parked"]


static func pack(index: Dictionary) -> void:
	for key in OUTLINED:
		var list: Variant = index.get(key)
		if list is Array:
			for f: Variant in list:
				if f is Dictionary and (f as Dictionary).get("p") is Array:
					f["p"] = PackedFloat32Array(f["p"])
	for key in FLAT:
		if index.get(key) is Array:
			index[key] = PackedFloat32Array(index[key])
	var graph: Variant = index.get("graph")
	if graph is Dictionary:
		if (graph as Dictionary).get("nodes") is Array:
			graph["nodes"] = PackedFloat32Array(graph["nodes"])
		for e: Variant in (graph as Dictionary).get("edges", []):
			if e is Dictionary and (e as Dictionary).get("p") is Array:
				e["p"] = PackedFloat32Array(e["p"])
