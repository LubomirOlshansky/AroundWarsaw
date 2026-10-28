shader_type spatial;
// Double-sided: a few LoD2 walls are wound inside out, and Godot flips the normal for back faces.
render_mode cull_disabled;
// Buildings. Walls carry UV = (metres along the wall, metres above the ground)
// and UV2 = (per-building style seed 0..1, wall top above the ground); roofs
// have UV.x < 0. From those the shader draws each building's own window rhythm,
// shop fronts on the ground floor, a cornice, and curtain walls on glass towers.
// It also opens a dithered hole wherever a building stands between camera and car,
// and (v0.8, reworked in loop 1) turns everything on the camera's side of the car that
// covers the car's surroundings on screen into a thin dithered ghost (ghost.gdshaderinc).
//
// v0.8 landmarks (landmarks.gd) carry a material code in UV2.x (2 and up; ordinary
// buildings keep their 0..1 style seed there): the Palace of Culture's stone with tall
// windows, plain stone, crenellated attics, gold, clock dials, Stadion Narodowy's
// woven red-and-white skin and roof membrane, Złote Tarasy's glass wave, the Rotunda's
// glass drum, lamps. Its fraction is a parameter (an attic's height in tens of metres).
//
// When the lights come on (night.gdshaderinc): a seeded share of the windows
// glows (warm flats, cool offices, the odd blue TV), whole floors of the glass
// towers, lit shop fronts with neon tubes over some of them, street-lamp light on
// the lower facades, and the Palace of Culture floodlit.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform float clouds = 0.18;
uniform float fade_radius = 7.5;
// The share of the ghost's pixels that stay in its core (a thin ghost keeps the tower's
// shape; the rim is a soft dither out to the whole wall).
uniform float ghost_keep = 0.19;
// --ghost-debug (main.gd): 1 paints the ghost magenta and the other buildings green,
// 2 cuts the ghost fully.
uniform int ghost_debug = 0;
// The Palace of Culture's clock (loop 1, main.gd, once a minute): the hour and minute
// hands' angles in radians, clockwise from twelve, for the time in Warsaw.
uniform vec2 clock_hands = vec2(5.32, 1.05);
uniform float windows = 1.0;
// The floodlit landmark: x, z of its centre and a radius (map_builder.gd, from the
// Palace of Culture's outline); only its sandstone walls light up.
uniform vec4 floodlit = vec4(0.0, 0.0, -1.0, 0.0);
varying vec3 world_pos;
varying vec2 style;

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

// Linear colours of the lit windows.
const vec3 WARM = vec3(1.0, 0.52, 0.2);
const vec3 WARM_PALE = vec3(1.0, 0.72, 0.42);
const vec3 COOL = vec3(0.62, 0.78, 1.0);
const vec3 TV = vec3(0.22, 0.36, 1.0);
const vec3 NEON[3] = vec3[3](vec3(1.0, 0.08, 0.5), vec3(0.05, 0.85, 1.0), vec3(0.55, 0.16, 1.0));

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	style = UV2;
}

// A lit room's colour: warm most often, cool white in offices, sometimes a TV.
vec3 room(float pick, bool office, vec2 cell) {
	if (office) {
		return pick < 0.7 ? COOL : WARM_PALE;
	}
	if (pick < 0.62) {
		return WARM;
	} else if (pick < 0.76) {
		return WARM_PALE;
	} else if (pick < 0.86) {
		return COOL;
	}
	// A television: blue, flickering.
	float flick = 0.65 + 0.35 * value_noise(vec2(TIME * 3.1 + cell.x * 7.0, cell.y * 3.0));
	return TV * flick;
}

// The wall's colour at (u along, h up); `glow` gets what it gives off at night.
vec3 facade(vec3 col, float u, float h, float seed, float top, bool glass, out vec3 glow) {
	glow = vec3(0.0);
	bool night = lights_on > 0.001;
	// Some buildings are mostly dark, some nearly all lit.
	float busy = 0.35 + 1.3 * fract(seed * 17.31);
	if (glass) {
		// Curtain wall: mullions, floor bands, and a sky reflection that brightens upwards.
		vec3 sky = srgb_to_linear(sky_colour);
		vec3 deep = srgb_to_linear(vec3(0.18, 0.27, 0.37)) * mix(0.3, 1.0, daylight);
		float refl = clamp(h / max(top, 1.0), 0.0, 1.0) * 0.55 + 0.3 * value_noise(vec2(u * 0.04, h * 0.02) + seed * 17.0);
		col = mix(col * mix(0.35, 0.7, daylight), mix(deep, sky, refl), 0.6);
		float mullion = abs(fract(u / 1.6) - 0.5) * 1.6;
		bool frame = fract(h / 3.7) < 0.07 || mullion > 0.72;
		if (frame) {
			col *= 0.7;
		} else if (night && h > 3.0) {
			// Whole office floors left on, and single bays here and there.
			float level = floor(h / 3.7);
			float whole = hash12(vec2(level, seed * 91.0));
			// Bays light in runs of three, like one office's worth of desks.
			float bay = hash12(vec2(floor(u / 4.8), level) + seed * 53.0);
			if (whole < 0.18 * busy * lights_on || bay < 0.12 * busy * lights_on) {
				float tone = hash12(vec2(level, 3.3) + seed);
				glow = (tone < 0.75 ? COOL : WARM_PALE) * (0.95 + 0.3 * bay);
				col *= 0.45;
			}
		}
		return col;
	}
	float fh = 3.0 + 0.7 * fract(seed * 7.13);   // floor height
	float sp = 2.2 + 1.4 * fract(seed * 3.71);   // window spacing
	float ww = 0.32 + 0.22 * fract(seed * 5.37); // window width (share of spacing)
	float wh = 0.42 + 0.18 * fract(seed * 9.11); // window height (share of floor)
	float fy = fract(h / fh);
	float fx = fract(u / sp);
	if (top > 4.0 && h > top - 0.7) {
		return col * 1.12; // cornice / parapet
	}
	if (h < fh) {
		// Ground floor: wide shop windows under a darker fascia band.
		bool shop = fy > 0.12 && fy < 0.78 && abs(fx - 0.5) < 0.38;
		vec3 window_col = mix(col * 0.45, srgb_to_linear(vec3(0.23, 0.27, 0.31)), 0.72);
		if (night) {
			vec2 unit = vec2(floor(u / sp), seed * 77.0);
			// Neon tubes along the fascia over some buildings' shops.
			if (fract(seed * 23.17) > 0.7 && fy > 0.83 && fy < 0.93 && abs(fx - 0.5) < 0.42) {
				vec3 tube = NEON[int(fract(seed * 41.3) * 3.0)];
				glow = tube * 2.6;
				return tube * 0.25;
			}
			if (shop && hash12(unit) < 0.72 * lights_on) {
				float tone = hash12(unit + 5.1);
				glow = (tone < 0.65 ? WARM_PALE : vec3(0.9, 0.92, 1.0)) * 1.35;
				return window_col * 0.6;
			}
		}
		if (shop) {
			return window_col;
		}
		return fy > 0.82 ? col * 0.84 : col;
	}
	if (abs(fx - 0.5) < ww * 0.5 && abs(fy - 0.55) < wh * 0.5) {
		// Each pane catches the light a little differently.
		vec2 cell = vec2(floor(u / sp), floor(h / fh));
		float pane = hash12(cell + seed * 31.0);
		vec3 glass_col = mix(srgb_to_linear(vec3(0.24, 0.29, 0.36)), srgb_to_linear(vec3(0.56, 0.67, 0.78)), pane * pane);
		if (night) {
			bool office = top > 35.0;
			float share = (office ? 0.42 : 0.34) * busy;
			if (hash12(cell * 1.37 + seed * 59.0 + 7.7) < share * lights_on) {
				glow = room(hash12(cell + seed * 13.0), office, cell) * (1.05 + 0.5 * hash12(cell + 2.2));
				return mix(col * 0.5, glass_col, 0.66) * 0.35;
			}
			// Dark panes at night reflect a little less sky.
			glass_col *= mix(0.45, 1.0, daylight);
		}
		return mix(col * 0.5, glass_col, 0.66);
	}
	if (fract(seed * 13.7) > 0.5 && fy < 0.05) {
		return col * 0.9; // floor line
	}
	return col;
}

// Landmark materials (landmarks.gd). Codes match landmarks.gd's M_* constants.
const int M_MONUMENT = 2;
const int M_STONE = 3;
const int M_GOLD = 4;
const int M_DIAL = 5;
const int M_WEAVE = 6;
const int M_GLASS_ROOF = 7;
const int M_PAVILION = 8;
const int M_ATTIC = 9;
const int M_LAMP = 10;
const int M_MEMBRANE = 11;
const int M_GLASS = 12;

// The Palace of Culture's walls: tall windows between stone piers, a pilaster every
// fourth bay, a plinth and a cornice; a few rooms lit at night.
vec3 monument(vec3 col, float u, float h, float top, out vec3 glow) {
	glow = vec3(0.0);
	float fh = 3.6;
	float sp = 2.3;
	float bay = floor(u / sp);
	float fx = fract(u / sp);
	float fy = fract(h / fh);
	if (h < 1.1) {
		return col * 0.78; // plinth
	}
	if (top > 3.0 && h > top - 1.1) {
		return col * (h > top - 0.45 ? 1.16 : 0.9); // cornice and its shadow line
	}
	if (mod(bay, 4.0) < 1.0) {
		return col * 1.07; // pilaster
	}
	if (abs(fx - 0.5) < 0.19 && fy > 0.22 && fy < 0.86) {
		vec2 cell = vec2(bay, floor(h / fh));
		float pane = hash12(cell * 1.7 + 3.1);
		vec3 dark = mix(srgb_to_linear(vec3(0.2, 0.22, 0.27)), srgb_to_linear(vec3(0.42, 0.47, 0.55)), pane * pane);
		if (lights_on > 0.001 && hash12(cell * 0.73 + 11.3) < 0.2 * lights_on) {
			glow = (pane < 0.7 ? WARM_PALE : WARM) * 0.9;
			return dark * 0.4;
		}
		return mix(dark, dark * mix(0.5, 1.0, daylight), 1.0 - daylight);
	}
	if (fy < 0.06) {
		return col * 0.92; // floor band
	}
	return col;
}

// Glass with mullions every `sp` metres and a transom band every `fh`; `lit` is the
// share of the bays glowing at night, `warmth` their tone.
vec3 glass_wall(vec3 col, float u, float h, float top, float sp, float fh, float lit, out vec3 glow) {
	glow = vec3(0.0);
	vec3 sky = srgb_to_linear(sky_colour);
	vec3 deep = srgb_to_linear(vec3(0.16, 0.24, 0.33)) * mix(0.35, 1.0, daylight);
	float refl = clamp(h / max(top, 1.0), 0.0, 1.0) * 0.5 + 0.25 * value_noise(vec2(u * 0.05, h * 0.03));
	vec3 c = mix(col * mix(0.35, 0.75, daylight), mix(deep, sky, refl), 0.62);
	float mullion = abs(fract(u / sp) - 0.5) * sp;
	if (mullion > sp * 0.5 - 0.12 || fract(h / fh) < 0.05) {
		return c * 0.6 + srgb_to_linear(vec3(0.75, 0.77, 0.8)) * 0.25 * daylight;
	}
	if (lights_on > 0.001 && h > 0.6) {
		float level = floor(h / fh);
		float b = hash12(vec2(floor(u / (sp * 3.0)), level) + 41.0);
		if (b < lit * lights_on) {
			glow = mix(COOL, WARM_PALE, step(0.6, hash12(vec2(level, 7.0)))) * 1.05;
			c *= 0.45;
		}
	}
	return c;
}

// Stadion Narodowy's skin: two families of strips woven diagonally, red over white,
// then white over red; dark gaps where the stands show through.
vec3 weave(float u, float h, out vec3 glow) {
	glow = vec3(0.0);
	float w = 4.2;
	float a = (u + h * 0.9) / w;
	float b = (u - h * 0.9) / w;
	float fa = fract(a);
	float fb = fract(b);
	bool in_a = fa > 0.08 && fa < 0.92;
	bool in_b = fb > 0.08 && fb < 0.92;
	vec3 red = srgb_to_linear(vec3(0.78, 0.12, 0.16));
	vec3 white = srgb_to_linear(vec3(0.9, 0.9, 0.88));
	vec3 gap = srgb_to_linear(vec3(0.16, 0.15, 0.17));
	bool a_over = mod(floor(a) + floor(b), 2.0) < 1.0;
	vec3 c;
	if (in_a && (a_over || !in_b)) {
		c = red * (0.85 + 0.3 * abs(fa - 0.5));
	} else if (in_b) {
		c = white * (0.82 + 0.3 * abs(fb - 0.5));
	} else {
		c = gap;
	}
	if (lights_on > 0.001) {
		// Lit from inside at night: the red strips glow, the white ones catch the light.
		glow = (c == gap ? vec3(0.0) : c * (c.r > c.g * 2.0 ? 1.6 : 0.9)) * 0.75;
	}
	return c;
}

// The glass wave (Złote Tarasy): a lattice of diamonds over the roof, the sky in it by
// day, the mall glowing through it at night.
vec3 glass_roof(vec3 col, vec2 xz, out vec3 glow) {
	glow = vec3(0.0);
	vec2 d = vec2(xz.x + xz.y, xz.x - xz.y) / 3.4;
	vec2 f = abs(fract(d) - 0.5);
	bool bar = f.x > 0.43 || f.y > 0.43;
	vec3 sky = srgb_to_linear(sky_colour);
	float n = value_noise(xz * 0.035);
	vec3 c = mix(col * mix(0.4, 0.85, daylight), sky, 0.4 + 0.35 * n);
	if (bar) {
		c = mix(c, srgb_to_linear(vec3(0.82, 0.84, 0.86)), 0.55 * daylight + 0.1);
	} else if (lights_on > 0.001) {
		glow = mix(WARM_PALE, vec3(1.0, 0.85, 0.55), n) * (0.55 + 0.35 * hash12(floor(d))) ;
		c *= 0.5;
	}
	return c;
}

// A clock hand at angle `a` (clockwise from twelve), `len` long and `w` wide (dial radii),
// with a short tail: 1 on it, 0 off.
float clock_hand(vec2 q, float a, float len, float w) {
	vec2 d = vec2(sin(a), cos(a));
	float t = clamp(dot(q, d), -0.12, len);
	return step(length(q - d * t), w);
}

vec3 landmark(int mode, float param, vec3 col, vec2 uv, float top, bool wall, vec3 wp, out vec3 glow, out bool cut) {
	glow = vec3(0.0);
	cut = false;
	if (mode == M_MONUMENT) {
		return wall ? monument(col, uv.x, uv.y, top, glow) : col * (0.94 + 0.08 * value_noise(wp.xz * 1.7));
	} else if (mode == M_STONE) {
		float grain = 0.95 + 0.07 * value_noise(wp.xz * 2.1 + wp.y * 1.3);
		if (wall && top > 2.0 && uv.y > top - 0.5) {
			return col * 1.12;
		}
		return col * grain;
	} else if (mode == M_ATTIC) {
		// A parapet: the top part cut into merlons (param = its height / 10 m).
		float height = max(param * 10.0, 0.6);
		if (wall && uv.y > top - height * 0.5 && fract(uv.x / 1.5) > 0.56) {
			cut = true;
		}
		return col * (wall && uv.y > top - 0.2 ? 1.12 : 1.0);
	} else if (mode == M_GOLD) {
		float sheen = 0.75 + 0.5 * smoothstep(0.2, 1.0, value_noise(vec2(wp.y * 0.6, wp.x + wp.z)));
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.8, 0.45) * 1.25;
		}
		return col * sheen;
	} else if (mode == M_DIAL) {
		// The hands, from the point on the dial (landmarks.gd: x right, y up, in radii, -10).
		vec2 q = uv + 10.0;
		float ink = max(clock_hand(q, clock_hands.x, 0.55, 0.075), clock_hand(q, clock_hands.y, 0.84, 0.05));
		ink = max(ink, step(length(q), 0.09));
		col = mix(col, srgb_to_linear(vec3(0.15, 0.14, 0.16)), ink);
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.92, 0.75) * 1.4 * (1.0 - ink);
		}
		return col;
	} else if (mode == M_WEAVE) {
		return wall ? weave(uv.x, uv.y, glow) : col;
	} else if (mode == M_GLASS_ROOF) {
		return glass_roof(col, wp.xz, glow);
	} else if (mode == M_PAVILION) {
		// A glass drum lit from inside: busy at night, nearly every bay.
		if (!wall) {
			return col;
		}
		vec3 c = glass_wall(col, uv.x, uv.y, top, 1.6, 4.2, 0.0, glow);
		if (lights_on > 0.001 && fract(uv.x / 1.6) > 0.1 && fract(uv.x / 1.6) < 0.9 && fract(uv.y / 4.2) > 0.06) {
			// param 0: warm (the Rotunda), 0.5: cool white (Varso's crown).
			vec3 tone = param > 0.25 ? vec3(0.78, 0.88, 1.0) : vec3(1.0, 0.86, 0.62);
			glow = tone * (0.9 + 0.35 * hash12(vec2(floor(uv.x / 1.6), floor(uv.y / 4.2))));
			c *= 0.4;
		}
		return c;
	} else if (mode == M_GLASS) {
		return wall ? glass_wall(col, uv.x, uv.y, top, 1.5, 4.0, 0.34, glow) : col;
	} else if (mode == M_LAMP) {
		if (lights_on > 0.001) {
			glow = col * 2.4;
		}
		return col;
	} else if (mode == M_MEMBRANE) {
		if (lights_on > 0.001) {
			glow = col * vec3(1.0, 0.95, 0.9) * 0.18;
		}
		return col * (0.96 + 0.06 * value_noise(wp.xz * 0.5));
	}
	return col;
}

// Floodlights on the landmark: warm from below, violet up the tower, a bright edge
// at the top of every wall, where the next terrace's lamps stand.
vec3 floodlight(vec3 col, float h, float top) {
	vec3 light = vec3(1.0, 0.72, 0.42) * (0.5 + 0.9 * exp(-h / 22.0));
	light += vec3(0.75, 0.32, 1.0) * smoothstep(25.0, 110.0, h) * 0.75;
	light += vec3(1.0, 0.85, 0.65) * smoothstep(top - 9.0, top - 0.5, h) * 0.55;
	return col * light * 1.25;
}

void fragment() {
	vec3 col = srgb_to_linear(COLOR.rgb);
	vec3 glow = vec3(0.0);
	bool walls = UV.x >= 0.0;
	int mode = style.x >= 2.0 ? int(style.x) : 0;
	if (mode > 0) {
		bool cut;
		col = landmark(mode, fract(style.x), col, UV, style.y, walls, world_pos, glow, cut);
		if (cut) {
			discard;
		}
	} else if (!walls) {
		// Roofs: gravel and membrane grain.
		col *= 0.94 + 0.08 * value_noise(world_pos.xz * 1.7) + 0.04 * hash12(floor(world_pos.xz * 5.0));
	} else if (windows > 0.5) {
		col = facade(col, UV.x, UV.y, style.x, style.y, COLOR.a < 0.75, glow);
	}
	ALBEDO = col * (1.0 - clouds * daylight * cloud_shadow(world_pos.xz, TIME));
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
	if (mode == M_GOLD) {
		ROUGHNESS = 0.35;
		METALLIC = 0.55;
		SPECULAR = 0.6;
	}

	if (lights_on > 0.001 && (walls || mode > 0)) {
		if (walls) {
			// Street lamps light the lower floors facing them: sample the pools a step
			// out from the wall, so a wall only catches the lamps on its own side.
			vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
			vec2 out_dir = wn.xz / max(length(wn.xz), 0.001);
			vec3 lamp = lamp_light(world_pos.xz + out_dir * 1.2);
			glow += col * lamp * (1.0 - smoothstep(0.5, 12.0, UV.y)) * 1.6;
		}
		// The Palace of Culture, floodlit: its sandstone near its centre.
		vec3 c = COLOR.rgb / max(COLOR.r, 0.001);
		bool stone = mode == M_MONUMENT || mode == M_STONE || mode == M_ATTIC
				|| (mode == 0 && COLOR.r > 0.6 && abs(c.g - 0.905) < 0.05 && abs(c.b - 0.72) < 0.07);
		if (floodlit.z > 0.0 && stone && walls && distance(world_pos.xz, floodlit.xy) < floodlit.z) {
			glow += floodlight(col, UV.y, style.y);
		}
		EMISSION = glow * lights_on;
	}

	if (!IN_SHADOW_PASS) {
		if (ghost_debug == 1) {
			ALBEDO = vec3(0.0);
			EMISSION = vec3(0.0, 0.6, 0.0);
		}
		float d = length(VERTEX.xy - car_view.xy);
		ivec2 p = ivec2(FRAGCOORD.xy) % 4;
		float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
		if (VERTEX.z > car_view.z + 1.0 && d < fade_radius) {
			float fade = smoothstep(fade_radius, fade_radius * 0.5, d);
			if (ghost_debug == 1 && fade > 0.5) {
				EMISSION = vec3(0.6, 0.0, 0.6);
			} else if (ghost_debug != 1 && threshold < fade * 0.92) {
				discard;
			}
		}
		// Occlusion ghost (ghost.gdshaderinc): whatever stands on the camera's side of the
		// car and covers its surroundings on screen keeps only a thin dither of its pixels
		// (ghost_keep) in the core, more towards a soft rim, so the street shows through,
		// a tower keeps its shape and nothing above the cut floats. Every fragment goes,
		// near walls, far walls and roofs alike; looking into a cut building, its inner
		// faces go too (a little past the car, where the building runs on beyond it).
		float fade = ghost_fade(VERTEX.xy, world_pos.xz);
		if (!FRONT_FACING) {
			fade = ghost_fade(VERTEX.xy, world_pos.xz - occluder.zw * 8.0);
		}
		if (ghost_debug == 1) {
			if (fade > 0.5) {
				ALBEDO = vec3(0.0);
				EMISSION = vec3(0.6, 0.0, 0.6);
			}
		} else if (ghost_debug == 2) {
			if (fade > 0.01) {
				discard;
			}
		} else if (threshold < fade * (1.0 - ghost_keep)) {
			discard;
		}
		// What the ghost keeps is dimmed at night: its lit windows were a sparkle over the street.
		EMISSION *= 1.0 - 0.7 * fade;
	}
}
