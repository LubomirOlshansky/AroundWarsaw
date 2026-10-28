shader_type spatial;
// Neon shop signs (neon_signs.gd): one quad per sign from a MultiMesh. The words
// atlas holds the tubes (red) and a faded ring of glow round them (green); the
// instance colour is the tube's colour, INSTANCE_CUSTOM = (atlas row, word width
// as a share of the atlas, 1 = on a dark plate, flicker seed). Unshaded and bright
// enough for the night glow to bloom; the game hides the signs by day.

render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;

global uniform float lights_on;

uniform sampler2D words : filter_nearest, repeat_disable;
uniform float rows = 9.0;

varying vec4 info;
varying vec3 tube;

void vertex() {
	info = INSTANCE_CUSTOM;
	tube = COLOR.rgb;
}

void fragment() {
	vec4 t = texture(words, vec2(UV.x * info.y, (info.x + UV.y) / rows));
	// A tired tube: every so often it drops out for a moment.
	float on = lights_on;
	if (info.w > 0.88) {
		float n = fract(sin(floor(TIME * 9.0) * 12.9898 + info.w * 78.233) * 43758.5453);
		on *= n < 0.2 ? 0.12 : 1.0;
	}
	vec3 plate = vec3(0.014, 0.011, 0.024);
	if (t.r > 0.5) {
		ALBEDO = mix(tube, vec3(1.0), 0.4) * 2.2 * on;
	} else if (t.g > 0.3) {
		ALBEDO = tube * t.g * 0.85 * on + plate * info.z;
	} else if (info.z > 0.5) {
		ALBEDO = plate;
	} else {
		discard;
	}
}
