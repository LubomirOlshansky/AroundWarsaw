shader_type canvas_item;
// The VHS overlay (V / the VHS button / --vhs): set as the material of the
// SubViewportContainer that shows the pixel-art image, so it runs once per
// screen pixel at full resolution while the image itself stays pixel-sharp.
// Scanlines every few screen pixels, red and blue pulled apart a little, faint
// noise, a soft tape-edge band, and now and then a tracking wobble that rolls
// up the picture.

uniform float strength = 1.0;
// Screen pixels per scanline pair (2 on a Mac, more on a phone's dense screen).
uniform float line_px = 3.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;
	// Tracking: every ~9 s a thin band of distorted lines rolls up the screen.
	float cycle = fract(t / 9.0);
	float band_y = 1.15 - cycle * 1.4;
	float band = smoothstep(0.06, 0.0, abs(uv.y - band_y)) * step(cycle, 0.55);
	float wobble = sin(uv.y * 220.0 + t * 30.0) * 0.004 * band;
	// A small constant jitter in bands of a few lines.
	float line = floor(FRAGCOORD.y / (line_px * 6.0));
	wobble += (hash(vec2(line, floor(t * 12.0))) - 0.5) * 0.0005;
	uv.x += wobble * strength;

	// Chroma shift: red one way, blue the other, in screen pixels.
	vec2 shift = vec2(SCREEN_PIXEL_SIZE.x * 2.5, 0.0) * strength;
	vec3 col;
	col.r = texture(TEXTURE, uv + shift).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - shift).b;

	// Scanlines: the lower part of every line pair darker.
	float scan = step(0.5, fract(FRAGCOORD.y / line_px));
	col *= 1.0 - 0.2 * scan * strength;
	// Noise, stronger inside the tracking band.
	float n = hash(FRAGCOORD.xy + fract(t * 7.13) * 512.0);
	col += (n - 0.5) * (0.05 + 0.35 * band) * strength;
	// Tape edges: a little dimmer and bluer towards the left and right.
	float edge = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x);
	col *= mix(vec3(0.85, 0.82, 0.95), vec3(1.0), mix(1.0, edge, strength));
	// Slightly washed-out tape colours.
	col = mix(col, col * vec3(1.03, 0.98, 1.06) + 0.015, strength);
	COLOR = vec4(col, 1.0);
}
