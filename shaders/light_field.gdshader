// The room's light and dark: every pixel multiplied by the act's ambient, a
// coloured dark, plus whatever light reaches it from the room's points and
// lines. Banded and dithered on the art-pixel grid, the way every light in the
// game is, so the falloff reads as pixel art and not as a smooth gradient.
//
// Multiplied over everything under it, so a lit brazier or a lava pit pushes
// back the dark around itself, and a corner nothing lights stays in the act's
// own colour of shadow (ART_DIRECTION.md: every dark is a coloured dark).
shader_type canvas_item;
render_mode blend_mul, unshaded;

#include "res://shaders/dither.gdshaderinc"

const int MAX_LIGHTS = 32;

uniform vec4 ambient : source_color;
// How much darker the top of the room is than the floor, 0 to 1. Light in
// this game comes from below: lava, braziers, the hero.
uniform float ceiling_dim = 0.0;
uniform float room_height = 360.0;
uniform float steps = 8.0;
uniform float flicker_speed = 9.0;
uniform int light_count = 0;
// Per light: both ends of its line (a point repeats one end), its colour times
// its strength with its radius in the fourth place, and its flicker.
uniform vec4 ends[MAX_LIGHTS];
uniform vec4 colours[MAX_LIGHTS];
uniform float flickers[MAX_LIGHTS];

varying vec2 world_px;

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float distance_to_line(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float len2 = dot(ab, ab);
	float t = len2 > 0.0 ? clamp(dot(p - a, ab) / len2, 0.0, 1.0) : 0.0;
	return length(p - (a + ab * t));
}

void fragment() {
	vec2 p = floor(world_px) + 0.5;
	float height = clamp(p.y / room_height, 0.0, 1.0);
	vec3 light = ambient.rgb * (1.0 - ceiling_dim * (1.0 - height));
	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}
		vec4 e = ends[i];
		vec4 c = colours[i];
		float reach = 1.0 - distance_to_line(p, e.xy, e.zw) / max(c.w, 1.0);
		if (reach <= 0.0) {
			continue;
		}
		float wobble = 1.0 - flickers[i] * (0.5 + 0.5 * sin(TIME * flicker_speed) * sin(TIME * flicker_speed * 0.37 + 1.3));
		light += c.rgb * reach * reach * wobble;
	}
	light = min(light, 1.0);
	vec3 level = light * steps;
	vec3 band = floor(level);
	float threshold = bayer4(world_px);
	vec3 lifted = band + step(vec3(threshold), level - band);
	COLOR = vec4(lifted / steps, 1.0);
}
