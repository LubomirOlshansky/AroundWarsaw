shader_type canvas_item;
// Chrome lettering for the title (title.gd): the label's fill (font colour white)
// becomes a chrome gradient by height, a sky-blue top over a bright horizon line
// and a dark band, then warm metal below; its outline keeps its own colour.

// The letters' cap top and baseline in the label's own pixels.
uniform float top = 0.0;
uniform float bottom = 100.0;

varying float y;

void vertex() {
	y = VERTEX.y;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = clamp((y - top) / max(bottom - top, 1.0), 0.0, 1.0);
	vec3 chrome;
	if (t < 0.5) {
		chrome = mix(vec3(0.35, 0.62, 1.0), vec3(0.97, 0.98, 1.0), smoothstep(0.0, 0.5, t));
	} else {
		chrome = mix(vec3(0.24, 0.07, 0.3), vec3(1.0, 0.55, 0.3), smoothstep(0.5, 0.78, t));
		chrome = mix(chrome, vec3(1.0, 0.94, 0.75), smoothstep(0.78, 1.0, t));
	}
	// A glint line across the horizon of the letters.
	chrome += vec3(1.0) * exp(-abs(t - 0.5) * 60.0) * 0.6;
	vec4 c = COLOR;
	if (c.r > 0.9 && c.g > 0.9 && c.b > 0.9) {
		c.rgb = chrome;
	}
	COLOR = vec4(c.rgb, c.a * tex.a);
}
