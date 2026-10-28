shader_type spatial;
// Moving things built from coloured boxes: traffic, trams, rivals, pedestrians.
// UV.x says how a vertex is coloured (models.gd): 0 = its colour times the instance
// paint (INSTANCE_CUSTOM.rgb, MultiMesh only), 1 = its own colour, 2 = trousers from a
// small palette picked by INSTANCE_CUSTOM.a, and its own colour that glows when the
// city's lights are on: 3 = headlamp, 4 = tail lamp, 5 = a lit window (bus, tram),
// 6 = a lit sign (taxi), 7 = an amber lamp that blinks (roadworks, loop 1; all in one
// beat with their halos, glow.gdshader); 8 = the player's car (car.gd, the look loop): its own
// colour, lit from within at night by UV.y (a hero material: never darker than the road
// under it), a little brighter on the faces that look up. UV.y = +1 / -1 marks the left /
// right leg of a pedestrian, which swing as they walk. Under the street lamps (night.gdshaderinc; main.gd
// hands this material the baked light map) they catch the light at night.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"

uniform float clouds = 0.18;
// Pedestrians swing their legs; vehicles leave this at 0.
uniform float walk = 0.0;
varying vec3 world_pos;
varying vec3 tint;
varying vec3 glow;
varying float blink;

const vec3 TROUSERS[4] = vec3[](vec3(0.18, 0.22, 0.33), vec3(0.12, 0.12, 0.13), vec3(0.42, 0.40, 0.37), vec3(0.55, 0.45, 0.32));

void vertex() {
	vec3 c = srgb_to_linear(COLOR.rgb);
	int part = int(UV.x + 0.5);
	glow = vec3(0.0);
	blink = 0.0;
	if (part == 0) {
		c *= srgb_to_linear(INSTANCE_CUSTOM.rgb);
	} else if (part == 2) {
		c = srgb_to_linear(TROUSERS[int(clamp(INSTANCE_CUSTOM.a * 4.0, 0.0, 3.0))]);
	} else if (part == 3) {
		glow = vec3(1.0, 0.9, 0.7) * 3.0;
	} else if (part == 4) {
		glow = vec3(1.0, 0.06, 0.04) * 2.2;
	} else if (part == 5) {
		glow = vec3(1.0, 0.82, 0.55) * 0.75;
	} else if (part == 6) {
		glow = c * 1.6;
	} else if (part == 7) {
		glow = c * 4.0;
		blink = 1.0;
	} else if (part == 8) {
		// A touch more orange than the paint: a saturated red tops out at a low luma, so
		// the glow needs some green to climb clear of the road (kept red-orange, hue ~13
		// degrees: the jobs' beacon is orange, 24).
		glow = (c + vec3(0.0, 0.028, 0.008)) * UV.y * (0.75 + 0.25 * max(NORMAL.y, 0.0));
	}
	tint = c;
	if (walk > 0.0 && abs(UV.y) > 0.5) {
		float phase = TIME * 9.0 + float(INSTANCE_ID) * 1.7;
		VERTEX.z += UV.y * sin(phase) * walk * clamp(1.0 - VERTEX.y / 0.9, 0.0, 1.0);
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	ALBEDO = tint * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.7;
	SPECULAR = 0.3;
	if (lights_on > 0.001) {
		vec3 g = glow;
		if (blink > 0.5) {
			// On a little over half the time, about once a second.
			g *= step(0.42, fract(TIME * 1.15));
		}
		EMISSION = (g + tint * lamp_light(world_pos.xz) * 1.4) * lights_on;
	}
}
