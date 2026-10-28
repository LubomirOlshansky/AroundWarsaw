shader_type spatial;
// Billboard posters (eggs.gd): a pixel-art texture drawn with pixel_font.gd, crisp
// (nearest filtering), shaded like the city. At night the billboard's lamps light
// it: it glows a little, enough for the bloom to pick up the brightest colours.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"

uniform sampler2D poster : source_color, filter_nearest, repeat_disable;
uniform float clouds = 0.18;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = texture(poster, UV).rgb;
	ALBEDO = c * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	if (lights_on > 0.001) {
		EMISSION = c * 0.7 * lights_on;
	}
}
