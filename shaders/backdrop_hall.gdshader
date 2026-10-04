// Act 4's backdrop, the Hall of Volta, until a painted one replaces it: a far
// wall of dark masonry pierced by tall arched windows on a storm, rain running
// down them and, now and then, lightning; nearer, a colonnade with Volta's
// banners hanging between the columns. Two layers of parallax.
//
// ART_DIRECTION.md: backgrounds lose. The flash is a lift of the window's own
// dull colours, never a white, and it is rare.
shader_type canvas_item;

#include "res://shaders/backdrop.gdshaderinc"

uniform vec4 air_top : source_color;
uniform vec4 air_bottom : source_color;
uniform vec4 wall : source_color;
uniform vec4 mortar : source_color;
uniform vec4 storm : source_color;
uniform vec4 flash : source_color;
uniform vec4 column : source_color;
uniform vec4 column_lit : source_color;
uniform vec4 banner : source_color;
uniform vec4 sigil : source_color;
uniform float far_depth = 0.25;
uniform float near_depth = 0.5;
uniform float rain_speed = 140.0;
// Chance, per sixth of a second, that the storm flashes.
uniform float flash_chance = 0.012;

const float WINDOW_SPACING = 184.0;
const float WINDOW_HALF = 16.0;
const float ARCH_CENTRE = 92.0;
const float SILL = 236.0;
const float COLUMN_SPACING = 232.0;

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = floor(world_px);
	float h = clamp(p.y / room_height, 0.0, 1.0);

	// The far wall, coursed masonry, in the dark.
	float fx = layer_x(far_depth);
	vec3 col = mix(air_top.rgb, wall.rgb, banded(0.35 + h * 0.65, 4.0));
	float course = floor(p.y / 12.0);
	float joint = mod(fx + mod(course, 2.0) * 12.0, 24.0);
	if (mod(p.y, 12.0) < 1.0 || joint < 1.0) {
		col = mix(col, mortar.rgb, 0.7);
	}

	// Windows on the storm.
	float index = floor(fx / WINDOW_SPACING + 0.5);
	float wx = index * WINDOW_SPACING;
	float dx = fx - wx;
	bool in_arch = p.y < ARCH_CENTRE && length(vec2(dx, p.y - ARCH_CENTRE)) < WINDOW_HALF;
	bool in_shaft = p.y >= ARCH_CENTRE && p.y < SILL && abs(dx) < WINDOW_HALF;
	bool in_frame = (p.y < ARCH_CENTRE && length(vec2(dx, p.y - ARCH_CENTRE)) < WINDOW_HALF + 2.0)
		|| (p.y >= ARCH_CENTRE && p.y < SILL + 3.0 && abs(dx) < WINDOW_HALF + 2.0);
	if (in_frame) {
		col = column_lit.rgb;
	}
	if (in_arch || in_shaft) {
		float lit = step(1.0 - flash_chance, hash11(floor(TIME * 6.0)));
		vec3 sky = mix(storm.rgb, air_top.rgb, banded(h * 1.6, 3.0));
		// Rain, slanting, a streak a column.
		float streak = fract((fx * 0.9 + p.y * 0.3 - TIME * rain_speed * 0.3) / 11.0);
		if (streak < 0.07 && hash11(floor(fx) + floor(p.y / 40.0)) > 0.5) {
			sky = mix(sky, flash.rgb, 0.35);
		}
		col = mix(sky, flash.rgb, lit * 0.8);
		// Leading: a mullion and two transoms.
		if (abs(dx) < 1.0 || abs(p.y - 150.0) < 1.0 || abs(p.y - ARCH_CENTRE) < 1.0) {
			col = column.rgb;
		}
	}

	// The colonnade.
	float nx = layer_x(near_depth);
	float c_index = floor(nx / COLUMN_SPACING + 0.5);
	float cx = nx - c_index * COLUMN_SPACING;
	float half_width = 12.0;
	if (p.y < 52.0 || p.y > 318.0) {
		half_width = 18.0;
	}
	if (p.y < 44.0) {
		half_width = 0.0;
	}
	if (abs(cx) < half_width) {
		col = column.rgb;
		float flute = mod(cx + 12.0, 6.0);
		if (cx < -half_width + 2.0) {
			col = column_lit.rgb;
		} else if (flute < 1.0 && p.y > 52.0 && p.y < 318.0) {
			col = mix(column.rgb, air_top.rgb, 0.5);
		}
	}
	// A banner between each pair, swallowtailed, with Volta's bolt on it.
	float bx = cx - COLUMN_SPACING * 0.5 * sign(cx);
	if (abs(cx) > COLUMN_SPACING * 0.5 - 14.0) {
		float across = abs(bx);
		float hem = 206.0 - 12.0 * (1.0 - across / 12.0);
		if (across < 12.0 && p.y > 44.0 && p.y < hem) {
			col = banner.rgb;
			if (across > 10.0) {
				col = mix(banner.rgb, column.rgb, 0.5);
			}
			float bolt_t = (p.y - 100.0) / 50.0;
			if (bolt_t > 0.0 && bolt_t < 1.0) {
				float zig = (abs(fract(bolt_t * 2.0) - 0.5) * 4.0 - 1.0) * 4.0;
				if (abs(bx - zig) < 1.5) {
					col = sigil.rgb;
				}
			}
		}
	}
	COLOR = vec4(col, 1.0);
}
