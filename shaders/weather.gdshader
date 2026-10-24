// Weather on a level's stone and back wall: broad patches of damp and of dry,
// faded stone, so a wall a screen wide reads as one built and rained on
// rather than as one tile repeated. Multipliers on the art's own colours
// (`Palette`), so a dark stays the coloured dark it was. Stepped in the house
// dither, two art pixels a step, as `ground_shade.gdshader` steps the
// interiors' dark.
shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"

uniform vec3 damp = vec3(1.0);
uniform vec3 dry = vec3(1.0);
// Art px across one patch.
uniform float patch_size = 96.0;
// How much of each a pixel can take, 0 to 1, and how many steps it comes in.
uniform float damp_most = 0.0;
uniform float dry_most = 0.0;
uniform float steps = 3.0;
// Where in the noise this level sits, so two levels are not weathered alike.
uniform vec2 seed = vec2(0.0);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float stepped(float amount, vec2 p) {
	return clamp(floor(amount * steps + bayer4(floor(p / 2.0))) / steps, 0.0, 1.0);
}

void fragment() {
	vec2 p = local + seed;
	float w = noise(p / patch_size) * 0.65 + noise(p / (patch_size * 0.4) + 17.0) * 0.35;
	float wet = smoothstep(0.55, 0.85, w) * damp_most;
	float sun = smoothstep(0.45, 0.15, w) * dry_most;
	vec3 rgb = COLOR.rgb;
	rgb = mix(rgb, rgb * damp, stepped(wet, local));
	rgb = mix(rgb, min(rgb * dry, vec3(1.0)), stepped(sun, local + vec2(1.0, 0.0)));
	COLOR.rgb = rgb;
}
