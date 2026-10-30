shader_type spatial;
// Ground, parks, paths, roads, markings and rails. UV.x carries each layer's
// depth bias: the vertex is pulled that many metres towards the camera in
// depth only (with an orthographic camera it doesn't move on screen), so a
// layer always draws over the one beneath it even where both follow the terrain.
// UV.y is the layer id (map_builder.gd L_*), UV2 is metres along/across the
// street so paving runs with it. A baked occlusion map darkens the ground next
// to walls, under parked cars and beneath trees. At night the baked street-lamp
// pools (night.gdshaderinc) light it up, and the river glints.
//
// v0.9: the surface map (tools/bake_water.py: shore distance, flow, what reflects,
// bridge decks) gives the river and ponds depth colour from the shore inwards, a
// current drifting north along the river, shore foam and sun sparkles; at night the
// lamps' light becomes broken columns of reflection on the water instead of pools,
// and nothing under a bridge deck gets the deck lamps' pools. In the rain (`wetness`,
// weather.gd) asphalt and paving go darker with a sheen of the sky, puddles (a noise
// mask, on roads and paving only, never kerbs) lie darker still with rings where the
// drops land, and the lamps reflect in long streaks. post.gdshader adds the mirror
// reflections of what stands on screen above the water and the wet streets.
//
// Loop 1: where the occlusion ghost (ghost.gdshaderinc) shows a building's footprint
// through its dither, the buildings' baked shade is lifted (ao_map red; the parked cars'
// and trees' shade in green stays) and, inside the footprint, which its own building
// always shades, the sunlight it would get is given back (ghost_sun), so the street
// round the car reads as bright as the street outside the ghost.
//
// Loop 3b-2: layers 16 (sand), 17 (a natural bank's wet bands, a sandbar's rim), 18 (the
// foam line on a natural waterline) and 19 (the tram bed's slabs), map_builder.gd L_SAND,
// L_WET, L_FOAM, L_TRAMBED.

#include "res://shaders/common.gdshaderinc"
#include "res://shaders/night.gdshaderinc"
#include "res://shaders/ghost.gdshaderinc"

uniform float clouds = 0.18;
uniform sampler2D ao_map : filter_linear, repeat_disable, hint_default_white;
uniform vec4 ao_rect = vec4(0.0, 0.0, 1.0, 1.0); // x0, z0, width, depth in metres
uniform bool debug_ao = false;
uniform float ao_strength = 1.0;
// The sun's light (linear colour x energy x how much of it to give back) and the way
// to it (world space), for ghosted footprints (main.gd).
uniform vec3 ghost_sun = vec3(0.0);
uniform vec3 ghost_sun_dir = vec3(0.0, 1.0, 0.0);
uniform sampler2D surface_map : filter_linear, repeat_disable, hint_default_black;
uniform vec4 surface_rect = vec4(0.0, 0.0, 1.0, 1.0);
global uniform float wetness;
global uniform float rain;
varying vec3 world_pos;
varying vec2 street;
varying float layer;

// The look loop (2026-10-28), calmer day colours (the overcast rain-day look as the guide):
// grass less yellow (a multiplier on its linear colour) and with less chroma (the share
// kept), cycle lanes in brick red (sRGB), the river by day a grey-green-blue lowland river
// (sRGB, the colour its depth shading starts from; at night it keeps the old one).
const vec3 GRASS_TINT = vec3(0.86, 1.0, 1.2);
const float GRASS_CHROMA = 0.88;
const vec3 BRICK = vec3(0.6, 0.31, 0.28);
const vec3 DAY_WATER = vec3(0.41, 0.6, 0.6);

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	street = UV2;
	layer = UV.y;
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.z += max(UV.x, 0.0);
	POSITION = PROJECTION_MATRIX * view;
}

// Lamp light seen in wet ground or water: the light map sampled further from the
// viewer (a lamp head about 6-12 m up reflects that far towards the camera), peaked
// so a lamp gives a narrow column, broken into short dashes across it.
vec3 lamp_reflection(vec2 wp, vec2 away, float dashes, float speed) {
	vec3 col = vec3(0.0);
	for (int k = 0; k < 4; k++) {
		vec3 l = lamp_light(wp + away * (9.0 + 4.0 * float(k)));
		// Peaked on brightness (not per channel: that would turn sodium red).
		float b = clamp(dot(l, vec3(0.45, 0.45, 0.1)), 0.0, 1.5);
		float b2 = b * b;
		col = max(col, l * b2 * b2);
	}
	vec2 side = vec2(-away.y, away.x);
	float dash = smoothstep(0.42, 0.72, value_noise(vec2(dot(wp, side) * 0.5, dot(wp, away) * dashes + TIME * speed)));
	return col * (0.25 + 1.5 * dash);
}

// 1 on the joint lines of a square grid of the given size (metres), else 0.
float joints(vec2 p, float size, float width) {
	vec2 d = abs(fract(p / size + 0.5) - 0.5) * size;
	return 1.0 - step(width, min(d.x, d.y));
}

void fragment() {
	vec3 base = srgb_to_linear(COLOR.rgb);
	vec2 wp = world_pos.xz;
	float n1 = value_noise(wp * 0.9);
	float n2 = value_noise(wp * 3.1);
	float shade = 0.95 + 0.1 * (n1 * 0.6 + n2 * 0.4);
	float ripple = 0.0;
	int id = int(round(layer));
	vec4 surf = texture(surface_map, (wp - surface_rect.xy) / surface_rect.zw);
	// A bridge deck over this point, and whether this fragment lies under it.
	float deck_y = surf.a > 0.0 ? surf.a * 255.0 / 4.0 - 32.0 : -1e4;
	bool under_deck = world_pos.y < deck_y - 1.5;
	vec3 emit = vec3(0.0);
	float puddle = 0.0;
	float sheen = 0.0;
	if (id == 4 || id == 2) {
		// Paving slabs: small along footpaths, large granite on plazas.
		float size = id == 4 ? 1.2 : 2.4;
		vec2 cell = floor(street / size);
		shade = 0.96 + 0.07 * hash12(cell) - 0.08 * joints(street, size, 0.09);
	} else if (id == 6) {
		// Asphalt: fine grain, a little lighter wear, darker repair patches.
		float grain = hash12(floor(wp * 6.0));
		float patch = smoothstep(0.63, 0.7, value_noise(wp * 0.11 + 3.7));
		shade = 0.95 + 0.07 * grain - 0.06 * patch + 0.04 * n1;
	} else if (id == 1) {
		// Grass: soft lighter and darker patches with a slight hue drift. The look loop:
		// calmer, the lime read louder than the car: less yellow, and less chroma.
		float g = value_noise(wp * 0.35) * 0.6 + value_noise(wp * 1.7) * 0.4;
		base *= mix(vec3(0.88, 0.94, 0.84), vec3(1.08, 1.05, 0.9), g);
		base *= GRASS_TINT;
		base = mix(vec3(dot(base, LUMA)), base, GRASS_CHROMA);
		shade = 0.97 + 0.06 * hash12(floor(wp * 4.0));
	} else if (id == 5) {
		// Cycle lanes and crossings: Warsaw brick red (the look loop; the mapped coral read
		// louder than the player's red car).
		base = srgb_to_linear(BRICK);
		shade = 0.94 + 0.08 * hash12(floor(wp * 5.0));
	} else if (id == 7) {
		shade = 0.88 + 0.12 * value_noise(wp * 1.3); // worn paint
	} else if (id == 9 || id == 15) {
		// Ballast gravel; along a track, concrete sleepers across it every 0.65 m.
		shade = 0.86 + 0.24 * hash12(floor(wp * 7.0));
		if (id == 9 && fract(street.x / 0.65) < 0.32) {
			base = mix(base, srgb_to_linear(vec3(0.62, 0.6, 0.57)), 0.8);
		}
	} else if (id == 10) {
		// Steps: a darker edge line on every tread.
		shade = fract(street.x / 0.34) < 0.22 ? 0.8 : 1.0;
	} else if (id == 11) {
		// Flowerbeds: leaves with dots of flowers.
		vec2 cell = floor(wp * 2.5);
		float pick = hash12(cell);
		if (pick > 0.62) {
			vec3 bloom[4] = vec3[4](vec3(0.85, 0.25, 0.3), vec3(0.95, 0.75, 0.2), vec3(0.65, 0.4, 0.8), vec3(0.95, 0.95, 0.9));
			base = srgb_to_linear(bloom[int(pick * 40.0) % 4]);
		}
		shade = 0.9 + 0.15 * hash12(cell + 3.1);
	} else if (id == 12) {
		shade = 0.85 + 0.2 * value_noise(wp * 0.8) + 0.06 * hash12(floor(wp * 5.0)); // dirt
	} else if (id == 13) {
		// Playground rubber in muted tiles.
		vec2 tile = floor(street / 2.0);
		vec3 rubber[3] = vec3[3](vec3(0.78, 0.45, 0.35), vec3(0.45, 0.6, 0.75), vec3(0.55, 0.7, 0.45));
		base = srgb_to_linear(rubber[int(hash12(tile) * 30.0) % 3]);
	} else if (id == 14) {
		shade = 0.95 + 0.06 * hash12(floor(wp * 4.0)); // traffic island concrete
	} else if (id == 19) {
		// Loop 3b-2: the tram bed: concrete track slabs, a joint across it every 3 m.
		vec2 slab = floor(street / vec2(3.0, 2.0));
		shade = 0.95 + 0.06 * hash12(slab) - 0.1 * step(fract(street.x / 3.0), 0.05);
	} else if (id == 16 || id == 17) {
		// Loop 3b-2: sand (beaches, sandbars) and the wet bands of a natural bank or a
		// sandbar's rim (their colour, sand or earth, from the vertex): a fine grain, soft
		// drifts on the dry sand; darker after dark (the beach read as a pale lavender plane).
		shade = 0.95 + 0.06 * hash12(floor(wp * 4.5));
		if (id == 16) {
			shade += 0.06 * (value_noise(wp * 0.45) - 0.5);
		}
		base *= mix(0.6, 1.0, daylight);
	} else if (id == 18) {
		// Loop 3b-2: the foam line on a natural waterline: a 1-px line that breathes a little,
		// dim after dark (night water stays calm and dark).
		shade = 0.9 + 0.1 * value_noise(wp * 0.8 + vec2(TIME * 0.15, 0.0));
		base *= mix(0.32, 1.0, daylight);
	} else if (id == 3) {
		// Water. The river (B = 1 in the surface map) flows along its baked direction;
		// ponds and fountains are still.
		float d = surf.r * 64.0;
		bool flowing = surf.b > 0.9;
		float ang = (surf.g * 255.0 - 128.0) / 127.0 * PI;
		vec2 flow = flowing ? vec2(sin(ang), -cos(ang)) * 0.75 : vec2(0.0);
		// A flow map: the pattern slides downstream in two phases that take turns
		// (offsets stay under 10 m, so the current can turn with the banks without
		// tearing the pattern), stretched along the river's general line (NNW).
		float ph0 = fract(TIME * 0.075);
		float ph1 = fract(TIME * 0.075 + 0.5);
		float k0 = 1.0 - abs(2.0 * ph0 - 1.0);
		const vec2 AX = vec2(-0.34, -0.94);
		const vec2 AY = vec2(0.94, -0.34);
		vec2 p0 = wp - flow * ph0 * 13.3;
		vec2 p1 = wp - flow * ph1 * 13.3 + vec2(3.7, 1.9);
		vec2 s0 = vec2(dot(p0, AX) * 0.2, dot(p0, AY) * 0.85);
		vec2 s1 = vec2(dot(p1, AX) * 0.2, dot(p1, AY) * 0.85);
		float r1 = mix(value_noise(s1), value_noise(s0), k0);
		float r2 = mix(value_noise(s1 * vec2(3.6, 1.7) + vec2(0.0, TIME * 0.07)), value_noise(s0 * vec2(3.6, 1.7) + vec2(0.0, TIME * 0.07)), k0);
		ripple = r1 * 0.55 + r2 * 0.45;
		// Depth from the shore inwards: light and a little green at the edge, deep blue
		// mid-river. Loop 1: a slow lowland river, not the open sea: a touch deeper and
		// greyer, the flow a low-contrast drift (calmer still after dark), few glints.
		float deep = smoothstep(1.5, flowing ? 42.0 : 14.0, d);
		// The look loop: by day the depth shading starts from a grey-green-blue (the mapped
		// azure read as an open sea); at night from the old colour, so night is unchanged.
		base = mix(base, srgb_to_linear(DAY_WATER), daylight);
		base = mix(base * vec3(1.02, 1.1, 0.98) + vec3(0.0, 0.02, 0.012), base * vec3(0.38, 0.56, 0.86), deep);
		base = mix(vec3(dot(base, vec3(0.3, 0.59, 0.11))), base, mix(0.75, 0.9, daylight));
		float calm = mix(0.5, 1.0, daylight);
		base *= 1.0 + (smoothstep(0.3, 0.75, ripple) - 0.5) * 0.16 * calm;
		vec3 glint = mix(srgb_to_linear(sky_colour) * 0.7, srgb_to_linear(vec3(0.74, 0.86, 0.93)), daylight);
		// The pale crests: a third as strong by day (they read as white streaks), as before at night.
		base = mix(base, glint, smoothstep(0.68, 0.86, ripple) * 0.24 * calm * mix(1.0, 0.33, daylight));
		// Shore foam: a broken band that laps in and out (thin round ponds and fountains).
		float lap = 0.5 + 0.5 * sin(TIME * 1.2 + value_noise(wp * 0.25) * 6.0);
		float band = flowing ? 1.4 + 1.0 * lap : 0.5 + 0.3 * lap;
		float foam = (1.0 - smoothstep(0.3, band, d)) * step(0.42, value_noise(wp * 1.7 + vec2(TIME * 0.25, 0.0)));
		base = mix(base, vec3(0.8, 0.86, 0.88), foam * (surf.b > 0.5 ? 0.6 : 0.0));
		// Sun sparkles: a rare pixel on the highest crests flickers (day only). The look loop:
		// a quarter as many (1 cell in 1,600 was 1 in 400), each a 0.3 m cell, 1-2 px.
		float spark = step(0.999375, hash12(floor(wp * 3.4) + floor(TIME * 3.0) * 17.0)) * smoothstep(0.66, 0.82, ripple);
		base += vec3(1.0, 0.96, 0.85) * spark * daylight * (1.0 - 0.8 * rain) * 0.7;
		if (under_deck) {
			base *= 0.6; // in the bridge's shade
		}
		// After dark the river goes deep and inky.
		base *= mix(vec3(0.22, 0.2, 0.3), vec3(1.0), daylight);
		// Loop 3i (BACKLOG "night water too plain at the widest zoom"): after dark a faint
		// sheen of the night sky comes back as light, strongest on the slow crests, and the
		// city's glow warms the water near the banks. Low contrast, so the lamps' reflections
		// still carry the river; only below dusk's daylight (0.45), so dusk keeps its own colour.
		float night = smoothstep(0.35, 0.0, daylight) * (under_deck ? 0.3 : 1.0) * (1.0 - 0.6 * rain);
		// Broad slow patches (40-80 m) so the sheen still reads at the widest zoom, where the
		// ripple is finer than a pixel.
		float crest = smoothstep(0.5, 0.85, ripple);
		float broad = smoothstep(0.3, 0.8, value_noise(vec2(dot(wp, AX) * 0.012, dot(wp, AY) * 0.03) + vec2(TIME * 0.004, 0.0)));
		emit += srgb_to_linear(sky_colour) * night * (0.05 + 0.16 * broad + 0.1 * crest) * mix(1.0, 0.75, deep);
		emit += srgb_to_linear(vec3(0.55, 0.32, 0.42)) * night * 0.1 * (1.0 - smoothstep(2.0, 40.0, d));
	}
	// Rain: wet asphalt and paving darken, puddles lie darker still and mirror the sky.
	if (wetness > 0.001 && (id == 6 || id == 2 || id == 4 || id == 5 || id == 7 || id == 14 || id == 19)) {
		base *= mix(1.0, id == 6 ? 0.62 : (id == 7 ? 0.82 : 0.74), wetness);
		if (id == 6 || id == 2 || id == 4) {
			float pm = value_noise(wp * 0.16 + 11.3) * 0.6 + value_noise(wp * 0.53 + 2.1) * 0.4;
			puddle = smoothstep(0.64, 0.69, pm) * smoothstep(0.35, 0.9, wetness);
		}
		base *= 1.0 - 0.5 * puddle;
		sheen = wetness * (id == 6 ? 0.14 : 0.09) + puddle * 0.32;
		if (puddle > 0.0 && rain > 0.0) {
			// Rings where the drops land: one per 0.9 m cell, growing and fading.
			vec2 cell = floor(wp / 0.9);
			vec2 c = (cell + 0.2 + 0.6 * vec2(hash12(cell), hash12(cell + 7.1))) * 0.9;
			float ph = fract(TIME * 1.3 + hash12(cell + 3.3));
			float ring = 1.0 - smoothstep(0.0, 0.06, abs(length(wp - c) - ph * 0.42));
			sheen += ring * (1.0 - ph) * puddle * rain * 0.6;
		}
	}
	vec2 shade_map = texture(ao_map, (wp - ao_rect.xy) / ao_rect.zw).rg;
	float ghost = ghost_fade(VERTEX.xy, wp);
	float ao = mix(1.0, mix(shade_map.r, 1.0, ghost) * shade_map.g, ao_strength);
	ALBEDO = base * shade * ao * (1.0 - clouds * daylight * (1.0 - rain) * cloud_shadow(wp, TIME));
	if (ghost > 0.0) {
		// Inside a ghosted footprint (deep in the buildings' shade): its sunlight back.
		float inside = smoothstep(0.5, 0.8, (1.0 - shade_map.r) / 0.72);
		vec3 n = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		emit += ALBEDO * ghost_sun * max(dot(n, ghost_sun_dir), 0.0) * inside * ghost;
	}
	vec3 fwd = -INV_VIEW_MATRIX[2].xyz;
	vec2 away = normalize(fwd.xz + vec2(1e-5));
	if (sheen > 0.0) {
		// The wet surface mirrors the (overcast) sky.
		emit += mix(srgb_to_linear(sky_colour) * 0.35, srgb_to_linear(vec3(0.72, 0.76, 0.8)), daylight) * sheen * (0.25 + 0.5 * daylight);
	}
	if (lights_on > 0.001) {
		// Lamp pools, softened a little by the contact shadows; none under a bridge deck
		// (its lamps stand on top). (A little light even on dark asphalt: sodium-lit roads
		// read orange.) On the water, the lamps reflect instead: broken columns of light
		// towards the viewer, shimmering, on dark, calm water (loop 1: the pink and cyan
		// glints that washed over half the river went; the mirror carries the neon).
		// The look loop: the pools are banded pixel light, capped under the lit windows'
		// brightness, and tint grass, cycle lanes and flowerbeds instead of adding to them.
		vec3 glow;
		if (id == 3) {
			glow = lamp_reflection(wp, away, 2.6, 1.6) * 0.7 * (under_deck ? 0.3 : 1.0);
		} else {
			vec4 pool = lamp_pool(wp, FRAGCOORD.xy);
			glow = pool_glow(base * shade * mix(1.0, ao, 0.6), pool, id == 1 || id == 5 || id == 11) * (under_deck ? 0.05 : 1.0);
			if (sheen > 0.0) {
				glow += lamp_reflection(wp, away, 1.4, 0.4) * min(sheen * 2.2, 1.0) * 0.8;
			}
		}
		emit += glow * lights_on;
	}
	EMISSION = emit;
	if (debug_ao) {
		ALBEDO = vec3(ao) * 0.45; // dim, so the sunlight doesn't push it to white
	}
	ROUGHNESS = 1.0 - 0.45 * min(sheen * 3.0, 1.0);
	SPECULAR = 0.1 + 0.3 * min(sheen * 3.0, 1.0);
}
