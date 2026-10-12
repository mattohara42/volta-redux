// A level's solid interiors falling into the dark (N2). TEXTURE is one texel
// per cell, its colour the dark and its alpha how far, read with a linear filter so
// the dark falls smoothly between cells; it is then stepped in the house
// dither, two art pixels a step, so it reads as pixel art rather than a blur.
shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"

uniform float steps = 4.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec4 field = texture(TEXTURE, UV);
	float a = field.a;
	float level = floor(a * steps + bayer4(floor(local / 2.0))) / steps;
	COLOR = vec4(field.rgb, clamp(level, 0.0, 1.0));
}
