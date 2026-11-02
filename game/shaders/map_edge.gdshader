shader_type spatial;
// The land past the map's edge (map_edge.gd): vertex colours (sRGB), lit like the city, and
// faded into the background's colour as it goes out (UV.x the haze share, 0 at the edge, 1 far
// out), so the ground, the tree line and the blocks beyond melt into the sky with no visible end.
// The haze is emitted, not lit: at 1 the surface is exactly the background (edge_haze, linear,
// set with it by time_of_day.gd), by day, at dusk, at night and in the rain.
// UV.y 1 marks a block's wall: rows of windows from the world position, darker glass by day,
// some of them lit while the city's lights are on.

#include "res://shaders/common.gdshaderinc"

global uniform vec3 edge_haze;
global uniform float lights_on;
varying float haze;
varying float wall;
varying vec3 world_pos;
varying vec3 world_n;

void vertex() {
	haze = UV.x;
	wall = UV.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_n = NORMAL;
}

void fragment() {
	vec3 base = srgb_to_linear(COLOR.rgb);
	vec3 lit = vec3(0.0);
	if (wall > 0.5) {
		float along = abs(world_n.x) > abs(world_n.z) ? world_pos.z : world_pos.x;
		vec2 cell = vec2(along / 3.6, (world_pos.y - 0.6) / 3.2);
		vec2 f = fract(cell);
		float pane = step(0.22, f.x) * step(f.x, 0.78) * step(0.3, f.y) * step(f.y, 0.8);
		// Rounded so a wall's own windows agree on their cell (the lit ones among them).
		float on = step(0.58, hash12(floor(cell) + floor(world_pos.xz / 40.0) * 7.1));
		base = mix(base, base * vec3(0.42, 0.46, 0.52), pane);
		lit = vec3(1.0, 0.72, 0.38) * 0.75 * pane * on * lights_on;
	}
	ALBEDO = base * (1.0 - haze);
	EMISSION = edge_haze * haze + lit * (1.0 - haze);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
