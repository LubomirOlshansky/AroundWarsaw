// The time of day, shared by the city shaders. main.gd sets these globals
// (project.godot [shader_globals]); in the day they are lights_on 0 and
// daylight 1, which leaves every shader's daytime output untouched.

// How far the city's lights are on: 0 day, ~0.8 dusk, 1 night.
global uniform float lights_on;
// 1 in daylight, about 0.5 at dusk, 0 at night: cloud shadows, sky reflections.
global uniform float daylight;
// The sky the glass reflects (sRGB): pale blue by day, pink at dusk, navy at night.
global uniform vec3 sky_colour;

// Street-lamp pools baked by tools/bake_lights.py (map_builder.gd loads it):
// red = sodium lamps, green = LED lamps, 160/255 = one lamp's full brightness.
uniform sampler2D light_map : filter_linear, repeat_disable, hint_default_black;
uniform vec4 light_rect = vec4(0.0, 0.0, 1.0, 1.0); // x0, z0, width, depth in metres

const vec3 SODIUM = vec3(1.0, 0.4, 0.08);
const vec3 LED = vec3(0.62, 0.74, 1.0);

// Lamp light falling on a point of the map (linear colour, ~1 under a lamp).
vec3 lamp_light(vec2 xz) {
	vec2 lm = texture(light_map, (xz - light_rect.xy) / light_rect.zw).rg * (255.0 / 160.0);
	return lm.r * SODIUM + lm.g * LED;
}
