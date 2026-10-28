// The occlusion ghost (loop 1), shared by building.gdshader (which drops the ghosted
// fragments), ground.gdshader (which lifts the buildings' baked shade and shadow where a
// ghosted footprint shows through) and post.gdshader (no outlines on the ghost's pixels).
// main.gd sets the same values on all three materials every frame.
//
// The region: an ellipse round the vehicle on screen (wider than tall, lifted a little,
// its upper half stretched up a little), a core where the ghost is thinnest and a wide
// soft rim. Only what stands on the camera's side of the vehicle (more than a metre
// nearer, measured along the ground) is ghosted; the rest of the city stays whole.

// The vehicle's ground point (x, z) and the camera's horizontal forward (x, z).
uniform vec4 occluder = vec4(0.0, 0.0, 0.0, -1.0);
// The vehicle in view space (the camera's frame; orthographic, so x, y are screen metres).
uniform vec3 car_view = vec3(0.0, 0.0, -100000.0);
// The ellipse's height in view metres (0: off) and how far its middle sits above the vehicle.
uniform float occlusion_radius = 0.0;
uniform float occlusion_lift = 0.2;
// How far the region reaches up above its middle, in ellipse heights (1: a plain ellipse):
// a little taller than wide, so a tower right in front is ghosted a little way up and its
// top fades out into the thin ghost instead of ending at a cut (it never floats over a
// hole), while the skyline above stays whole.
uniform float occlusion_up = 1.35;

// 0 outside the ghost, 1 in its core, soft in between (the dithered rim). `view_xy` is the
// fragment's view-space x, y; `world_xz` its map position.
float ghost_fade(vec2 view_xy, vec2 world_xz) {
	if (occlusion_radius <= 0.0) {
		return 0.0;
	}
	float side = dot(world_xz - occluder.xy, occluder.zw);
	if (side > -1.0) {
		return 0.0;
	}
	vec2 dv = (view_xy - car_view.xy) / occlusion_radius - vec2(0.0, occlusion_lift);
	dv.x *= 0.78;
	float r = length(vec2(dv.x, dv.y > 0.0 ? dv.y / occlusion_up : dv.y));
	return (1.0 - smoothstep(0.55, 1.0, r)) * smoothstep(1.0, 4.0, -side);
}
