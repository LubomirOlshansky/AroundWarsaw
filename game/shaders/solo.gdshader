shader_type spatial;
render_mode unshaded, cull_disabled;

// Landmarks 0.3 (2026-10-31): the look of `--solo=KEY --solo-look=flat|sil` (main.gd).
// A landmark alone on a plain background, for the judge's shots (model-from-photos skill
// section 5): shape errors hide in lighting and street clutter. flat: the vertex colour,
// unlit (the site's own colours without light or window rhythm). sil: one dark colour, the
// outline only. It replaces building.gdshader on the shared building material, so it costs
// no draw call beyond the normal one; it never ships in a normal run.

uniform int look = 0;

void fragment() {
	if (look == 1) {
		ALBEDO = vec3(0.04, 0.05, 0.07);
	} else {
		vec3 c = COLOR.rgb;
		ALBEDO = mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, vec3(lessThan(c, vec3(0.04045))));
	}
}
