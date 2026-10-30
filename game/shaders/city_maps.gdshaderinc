// Loop 3d-2b: the baked maps per sector (scripts/city_maps.gd). The AO (tools/bake_ao.py), the
// street-lamp light (tools/bake_lights.py) and the surface map (tools/bake_water.py) are no longer
// one texture each over the whole map: each loaded sector's slice sits in a layer of an array,
// and a table of one texel per sector says which layer (+ 1; 0 = not loaded). A slice holds the
// whole map's texels at the same places, CITY_MARGIN round the sector, so reading it at a point
// is what reading the whole map was; two sectors meet without a seam. Where no sector is loaded
// the maps read empty: no shade, no lamp light, nothing that reflects.

#ifndef CITY_MAPS_INC
#define CITY_MAPS_INC

global uniform sampler2DArray city_ao : filter_linear, repeat_disable;
global uniform sampler2DArray city_light : filter_linear, repeat_disable;
global uniform sampler2DArray city_surface : filter_linear, repeat_disable;
global uniform sampler2D city_slots : filter_nearest, repeat_disable;
// The table's first sector (i, j) and its size in sectors.
global uniform vec4 city_slots_grid;
// The AO and light maps' grid: x0, z0, metres a texel, a slice's texels a side; the surface map's.
global uniform vec4 city_fine_map;
global uniform vec4 city_surface_map;

const float CITY_SECTOR = 512.0;
const float CITY_MARGIN = 2.0;

// The layer holding the sector under xz, -1 when none is loaded.
float city_slot(vec2 xz) {
	vec2 cell = floor(xz / CITY_SECTOR) - city_slots_grid.xy;
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= city_slots_grid.z || cell.y >= city_slots_grid.w) {
		return -1.0;
	}
	return floor(texelFetch(city_slots, ivec2(cell), 0).r * 255.0 + 0.5) - 1.0;
}

// Where xz falls in its sector's slice of a map with the grid `map`.
vec2 city_slice_uv(vec2 xz, vec4 map) {
	vec2 start = floor((floor(xz / CITY_SECTOR) * CITY_SECTOR - map.xy) / map.z) - CITY_MARGIN;
	return ((xz - map.xy) / map.z - start) / map.w;
}

// The AO map at xz: red the buildings' shade, green the parked cars' and trees' (1 = none).
vec2 city_ao_at(vec2 xz) {
	float slot = city_slot(xz);
	if (slot < 0.0) {
		return vec2(1.0);
	}
	return texture(city_ao, vec3(city_slice_uv(xz, city_fine_map), slot)).rg;
}

// The lamp-light map at xz: red sodium, green LED (160/255 = one lamp's full brightness).
vec2 city_light_at(vec2 xz) {
	float slot = city_slot(xz);
	if (slot < 0.0) {
		return vec2(0.0);
	}
	return texture(city_light, vec3(city_slice_uv(xz, city_fine_map), slot)).rg;
}

// The surface map at xz (tools/bake_water.py: shore distance, flow, what reflects, deck height).
vec4 city_surface_at(vec2 xz) {
	float slot = city_slot(xz);
	if (slot < 0.0) {
		return vec4(0.0);
	}
	return texture(city_surface, vec3(city_slice_uv(xz, city_surface_map), slot));
}

#endif
