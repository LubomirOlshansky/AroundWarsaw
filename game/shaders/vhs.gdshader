shader_type canvas_item;
// The Retro filter (V / Settings → Obraz / --vhs; the tape pickups pulse it for a few seconds):
// an original 80s vaporwave grade (2026-11-01, F: "like the city in Vice City", the mood only).
// Set as the material of the SubViewportContainer that shows the pixel-art image, so it runs
// once per screen pixel at full resolution while the image itself stays pixel-sharp.
// Shadows go violet-teal, highlights warm pink-peach, a soft neon bloom lifts the bright
// parts, scanlines every few screen pixels, red and blue pulled apart a little, faint grain,
// and now and then a tracking wobble rolls up the picture.

uniform float strength = 1.0;
// Screen pixels per scanline pair (2 on a Mac, more on a phone's dense screen).
uniform float line_px = 3.0;

const vec3 SHADOW = vec3(0.30, 0.55, 0.80);   // teal-blue shadows (multiplier, lerped from 1)
const vec3 LIGHT = vec3(1.12, 0.82, 0.92);    // pink sunset highlights
const vec3 NEON_PINK = vec3(1.0, 0.25, 0.6);
const vec3 NEON_TEAL = vec3(0.1, 0.9, 0.9);

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
	uv.x += wobble * strength;

	// Chroma shift: red one way, blue the other, in screen pixels.
	vec2 shift = vec2(SCREEN_PIXEL_SIZE.x * 2.0, 0.0) * strength;
	vec3 col;
	col.r = texture(TEXTURE, uv + shift).r;
	col.g = texture(TEXTURE, uv).g;
	col.b = texture(TEXTURE, uv - shift).b;

	// Soft bloom: four taps a few screen pixels out; only the bright part spills, in neon pink
	// on one side and teal on the other.
	vec2 o = SCREEN_PIXEL_SIZE * line_px * 3.0;
	vec3 b1 = texture(TEXTURE, uv + vec2(o.x, o.y)).rgb + texture(TEXTURE, uv + vec2(-o.x, o.y)).rgb;
	vec3 b2 = texture(TEXTURE, uv + vec2(o.x, -o.y)).rgb + texture(TEXTURE, uv + vec2(-o.x, -o.y)).rgb;
	vec3 glow = max((b1 + b2) * 0.25 - 0.55, vec3(0.0));
	float gl = dot(glow, vec3(0.333));
	col += gl * mix(NEON_TEAL, NEON_PINK, uv.y) * 1.1 * strength;

	// The grade: split-toned, a touch more saturated, a lifted violet black.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 graded = mix(col, vec3(luma), -0.18);
	graded *= mix(SHADOW, LIGHT, smoothstep(0.1, 0.7, luma));
	graded = graded * 0.94 + vec3(0.05, 0.015, 0.075);
	// A sunset wash from the top of the screen (peach-magenta) fading to nothing below.
	graded += vec3(0.10, 0.02, 0.07) * smoothstep(0.6, 0.0, uv.y) * 0.8;
	col = mix(col, graded, strength);

	// Scanlines: the lower part of every line pair darker.
	float scan = step(0.5, fract(FRAGCOORD.y / line_px));
	col *= 1.0 - 0.14 * scan * strength;
	// Grain, stronger inside the tracking band.
	float n = hash(FRAGCOORD.xy + fract(t * 7.13) * 512.0);
	col += (n - 0.5) * (0.035 + 0.3 * band) * strength;
	// Dim the corners a little.
	float edge = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x);
	col *= mix(vec3(0.85, 0.8, 0.95), vec3(1.0), mix(1.0, edge, strength));
	COLOR = vec4(col, 1.0);
}
