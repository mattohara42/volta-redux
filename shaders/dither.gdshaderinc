// Ordered (Bayer) dithering on the art-pixel grid: how pixel art shades a smooth
// falloff without a smooth gradient or a visible ring. Shared by every light.
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
