// Shared by the city shaders.

// Vertex colours are authored in sRGB; lighting needs them linear.
vec3 srgb_to_linear(vec3 c) {
	return mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, lessThan(c, vec3(0.04045)));
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
			mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Soft cloud shadows drifting slowly across the city: 0 in sun, up to 1 under a cloud.
float cloud_shadow(vec2 xz, float time) {
	vec2 p = xz / 220.0 + vec2(time * 0.010, time * 0.004);
	float n = value_noise(p) * 0.65 + value_noise(p * 2.7 + 7.3) * 0.35;
	return smoothstep(0.56, 0.74, n);
}
