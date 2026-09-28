// Warm light thrown up a wall from a light source below: a dome, brightest at
// the bottom centre of this rectangle and gone at its edges, added over
// whatever is there. The gradient is a handful of bands with ordered (Bayer)
// dithering between them, which is how pixel art shades a smooth falloff
// without a smooth gradient or a visible ring. ART.md: the light layer is what
// makes generated and painted layers one picture.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 tint : source_color;
uniform vec2 band_size;
uniform float strength;
uniform float steps = 4.0;

varying vec2 local;
varying vec2 world_px;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(floor(p), 4.0));
	return (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
}

void vertex() {
	local = VERTEX;
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 from_source = vec2((local.x - band_size.x * 0.5) / (band_size.x * 0.5), (local.y - band_size.y) / band_size.y);
	float dome = clamp(1.0 - length(from_source), 0.0, 1.0);
	float level = dome * dome * strength * steps;
	float band = floor(level);
	float a = (band + step(bayer4(world_px), level - band)) / steps;
	COLOR = vec4(tint.rgb, a);
}
