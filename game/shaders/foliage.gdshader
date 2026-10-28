shader_type spatial;
// Tree crowns: per-tree colour from the MultiMesh, and the same dithered
// see-through hole as buildings wherever a crown covers the car. At night the
// street-lamp pools (night.gdshaderinc) light the crowns from below.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"

uniform float clouds = 0.18;
// Crowns lean a little in the wind; parked cars use the same shader with sway = 0.
uniform float sway = 1.0;
// Rotor wash from a low helicopter: x, z of the rotor and a strength (0 = none).
uniform vec3 wash = vec3(0.0);
varying vec3 world_pos;
// Height of the vertex above the tree's (or parked car's) foot, for the lamp light.
varying float lift_h;

uniform vec3 car_view = vec3(0.0, 0.0, -100000.0);
uniform float fade_radius = 6.0;


const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	lift_h = VERTEX.y;
	float lift = clamp((VERTEX.y - 2.0) / 5.0, 0.0, 1.0);
	float gust = sin(TIME * 1.3 + world_pos.x * 0.07 + world_pos.z * 0.05);
	VERTEX.x += sway * gust * 0.12 * lift;
	VERTEX.z += sway * cos(TIME * 1.1 + world_pos.z * 0.06) * 0.08 * lift;
	// Downwash: a fast flutter that fades out about 25 m from the rotor.
	float w = sway * wash.z * smoothstep(26.0, 6.0, distance(world_pos.xz, wash.xy)) * lift;
	VERTEX.x += w * 0.45 * sin(TIME * 17.0 + world_pos.x * 1.7);
	VERTEX.z += w * 0.45 * cos(TIME * 15.0 + world_pos.z * 1.3);
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	if (lights_on > 0.001) {
		EMISSION = col * lamp_light(world_pos.xz) * (1.0 - smoothstep(1.5, 8.5, lift_h)) * 2.0 * lights_on;
	}

	float d = length(VERTEX.xy - car_view.xy);
	if (VERTEX.z > car_view.z + 0.5 && d < fade_radius) {
		float fade = smoothstep(fade_radius, fade_radius * 0.5, d);
		ivec2 p = ivec2(FRAGCOORD.xy) % 4;
		float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
		if (threshold < fade * 0.92) {
			discard;
		}
	}
}
