// Heat haze: shifts what is behind this rectangle sideways by whole art pixels,
// most at its bottom edge (the lava surface) and none at its top. Whole pixels
// only, in art-pixel units against the 640x360 design viewport, so it is
// identical at every window size and never smears the pixel grid.
shader_type canvas_item;

uniform sampler2D behind : hint_screen_texture, filter_nearest, repeat_disable;
uniform float band_height;
uniform float max_shift;
uniform float speed;
uniform float frequency;
uniform vec2 design_size = vec2(640.0, 360.0);

varying vec2 world_px;
varying float local_y;

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	local_y = VERTEX.y;
}

void fragment() {
	float strength = clamp(local_y / band_height, 0.0, 1.0);
	float shift = floor(sin(floor(world_px.y) * frequency + TIME * speed) * max_shift * strength + 0.5);
	COLOR = texture(behind, SCREEN_UV + vec2(shift / design_size.x, 0.0));
}
