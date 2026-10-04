// What every act's backdrop shares: hashed noise to shape silhouettes with,
// the parallax arithmetic, and the dithered band that shades a gradient the
// way pixel art does. Shapes are decided per whole art pixel, so nothing here
// draws a sub-pixel edge.
#include "res://shaders/dither.gdshaderinc"

uniform float camera_left = 0.0;
uniform float room_height = 360.0;
// Where in the endless pattern this room's left edge falls, so two rooms of
// one act do not open on the same pillar.
uniform float pattern_offset = 0.0;

varying vec2 world_px;

float hash11(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Smooth value noise along one axis, 0 to 1.
float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash11(i), hash11(i + 1.0), u);
}

// Three octaves of `noise1`, 0 to 1.
float fbm1(float x) {
	return (noise1(x) * 0.57 + noise1(x * 2.03 + 17.0) * 0.29 + noise1(x * 4.01 + 41.0) * 0.14);
}

// The x this layer shows at this pixel. `depth` is how fast the layer moves
// against the room: 1 moves with it, 0 holds still on the screen. Whole art
// pixels only, so a slow layer steps rather than swims.
float layer_x(float depth) {
	return floor(world_px.x) - floor(camera_left * (1.0 - depth)) + pattern_offset;
}

// A smooth 0 to 1 ramp shaded as pixel art: `steps` bands, dithered between.
float banded(float t, float steps) {
	float level = clamp(t, 0.0, 1.0) * steps;
	float band = floor(level);
	return (band + step(bayer4(world_px), level - band)) / steps;
}
