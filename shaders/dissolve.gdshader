// A screen covered in the backdrop's coloured dark, dissolving away (or
// filling in) two art pixels at a time in an ordered pattern: how a room
// arrives, in the same dither every light in the game is shaded with.
shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"

uniform vec4 colour : source_color;
// 1 covers the screen, 0 leaves it clear.
uniform float cover = 1.0;

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	if (bayer4(floor(local / 2.0)) >= cover) {
		discard;
	}
	COLOR = vec4(colour.rgb, 1.0);
}
