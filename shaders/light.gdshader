// A point light: a coloured dome of light brightest at the centre of this
// rectangle and gone at its edge, added over whatever is under it (walls, tiles,
// the hero, all of it), so one colour falls across every layer at once. Banded
// and dithered on the art-pixel grid, and it can flicker. ART.md: the light
// layer is what makes generated and painted layers one picture.
shader_type canvas_item;
render_mode blend_add;

#include "res://shaders/dither.gdshaderinc"

uniform vec4 tint : source_color;
uniform float strength = 0.5;
uniform float steps = 4.0;
// 0 is steady. 1 dips the light to nothing at the bottom of its flicker.
uniform float flicker = 0.0;
uniform float flicker_speed = 9.0;

varying vec2 uv_local;
varying vec2 world_px;

void vertex() {
	uv_local = UV;
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float dist = length(uv_local - vec2(0.5)) * 2.0;
	float dome = clamp(1.0 - dist, 0.0, 1.0);
	float wobble = 1.0 - flicker * (0.5 + 0.5 * sin(TIME * flicker_speed) * sin(TIME * flicker_speed * 0.37 + 1.3));
	float level = dome * dome * strength * wobble * steps;
	float band = floor(level);
	float a = (band + step(bayer4(world_px), level - band)) / steps;
	COLOR = vec4(tint.rgb, a);
}
