// Act 2's backdrop, the lava caverns, until a painted one replaces it: cave
// air warming toward the floor where the lava is, a far wall of stalactites
// and mounds with the odd lavafall running down it, nearer pillars of rock rim
// lit from below, and ash drifting up. Two layers of parallax.
//
// ART_DIRECTION.md: backgrounds lose. Every colour here is darker and duller
// than anything the hero can touch, and the lavafalls are lava's crust, never
// its flow, so a lavafall on the wall is never read as one on the floor.
shader_type canvas_item;

#include "res://shaders/backdrop.gdshaderinc"

uniform vec4 air_top : source_color;
uniform vec4 air_bottom : source_color;
uniform vec4 far_rock : source_color;
uniform vec4 near_rock : source_color;
uniform vec4 rim : source_color;
uniform vec4 fall_dark : source_color;
uniform vec4 fall_lit : source_color;
uniform vec4 ash : source_color;
uniform float far_depth = 0.2;
uniform float near_depth = 0.45;
uniform float fall_speed = 30.0;
uniform float ash_speed = 9.0;
// Off where the room's own obstacles are pillars, so the backdrop's never
// read as one of them.
uniform bool near_pillars = true;

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// How far down the rock reaches from the ceiling at `x`: a broken line with
// stalactites hanging off it.
float ceiling_edge(float x) {
	float edge = 34.0 + 50.0 * fbm1(x * 0.011);
	float cell = floor(x / 16.0);
	float within = fract(x / 16.0);
	float drop = hash11(cell + 3.0);
	float spike = max(drop - 0.4, 0.0) / 0.6 * 64.0;
	float taper = max(1.0 - abs(within - 0.5) * 2.4, 0.0);
	return edge + spike * taper * taper;
}

// How far up the far floor rises at `x`: mounds, with stalagmites.
float floor_edge(float x) {
	float edge = 300.0 - 70.0 * fbm1(x * 0.009 + 50.0);
	float cell = floor(x / 22.0);
	float within = fract(x / 22.0);
	float rise = hash11(cell + 71.0);
	float spike = max(rise - 0.55, 0.0) / 0.45 * 46.0;
	float taper = max(1.0 - abs(within - 0.5) * 2.2, 0.0);
	return edge - spike * taper;
}

void fragment() {
	vec2 p = floor(world_px);
	float h = clamp(p.y / room_height, 0.0, 1.0);
	vec3 col = mix(air_top.rgb, air_bottom.rgb, banded(h * h, 6.0));

	// The far wall.
	float fx = layer_x(far_depth);
	bool far_solid = p.y < ceiling_edge(fx) || p.y > floor_edge(fx);
	// A lavafall, now and then, from the ceiling down behind the far mounds.
	float fall_cell = floor(fx / 230.0);
	float fall_pick = hash11(fall_cell + 9.0);
	float fall_x = fall_cell * 230.0 + 50.0 + hash11(fall_cell + 21.0) * 130.0;
	float fall_half = 2.0 + floor(hash11(fall_cell + 33.0) * 3.0);
	float from_fall = abs(fx - fall_x);
	bool has_fall = fall_pick > 0.55 && p.y > ceiling_edge(fall_x) - 2.0;
	if (has_fall && from_fall > fall_half && !far_solid) {
		// Its glow on the air either side.
		float halo = 1.0 - (from_fall - fall_half) / 20.0;
		col = mix(col, fall_dark.rgb, banded(halo, 3.0) * 0.6);
	}
	if (far_solid) {
		col = far_rock.rgb;
	}
	if (has_fall && from_fall <= fall_half && p.y < floor_edge(fx) + 6.0) {
		float flow = noise1((p.y - TIME * fall_speed) / 7.0 + fall_cell * 13.0 + floor(from_fall) * 0.7);
		col = mix(fall_dark.rgb, fall_lit.rgb, step(0.55, flow));
	}

	// Nearer pillars, rim lit from the lava below.
	float nx = layer_x(near_depth);
	float cell = floor(nx / 300.0);
	float centre = cell * 300.0 + 70.0 + hash11(cell + 5.0) * 160.0;
	float waist = abs(h - 0.45) * 2.0;
	float half_width = 14.0 + 9.0 * noise1(p.y * 0.035 + cell * 7.0) + 26.0 * waist * waist;
	bool pillar = near_pillars && hash11(cell + 2.0) > 0.35 && abs(nx - centre) < half_width;
	bool fringe = p.y < 14.0 + 14.0 * fbm1(nx * 0.02 + 90.0);
	if (pillar || fringe) {
		col = near_rock.rgb;
		float edge = half_width - abs(nx - centre);
		if (pillar && edge < 3.0) {
			col = mix(near_rock.rgb, rim.rgb, banded(h * h * 1.2, 3.0));
		}
	} else {
		// Ash, drifting up through the air in front of the far wall.
		vec2 q = vec2(nx, p.y + TIME * ash_speed);
		vec2 grid = floor(q / 19.0);
		vec2 spot = grid * 19.0 + floor(vec2(hash21(grid), hash21(grid + 7.3)) * 19.0);
		if (hash21(grid + 2.1) > 0.86 && floor(q) == spot) {
			col = mix(col, ash.rgb, 0.75);
		}
	}
	COLOR = vec4(col, 1.0);
}
