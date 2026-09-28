// The dragon's breath (ART_DIRECTION.md: atmosphere is code). A warped noise
// streaming away from the mouth, quantised to three palette bands, on the art
// pixel grid. It fills the killing rectangle and never leaves it: the rectangle
// is the ColorRect, so what burns is what kills. `intensity` is 0 to 1, and the
// telegraph is the same flame growing from a few tongues at the mouth to the
// whole box.
shader_type canvas_item;

uniform vec4 falloff_colour : source_color;
uniform vec4 core_colour : source_color;
uniform vec4 hot_colour : source_color;
uniform vec2 box_size;
uniform float direction = 1.0;
uniform float intensity = 1.0;
uniform float stream_speed;
uniform float noise_scale;

varying vec2 world_px;
varying vec2 local_px;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * value_noise(p);
		p = p * 2.03 + 17.1;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	local_px = VERTEX;
}

void fragment() {
	vec2 px = floor(local_px);
	// 0 at the mouth, 1 at the far edge; -1 to 1 across the box.
	float along = direction > 0.0 ? px.x / box_size.x : 1.0 - px.x / box_size.x;
	float across = px.y / box_size.y * 2.0 - 1.0;

	// Streams away from the mouth, with the row coordinate wobbling so the
	// tongues lick sideways.
	float travel = along * box_size.x - TIME * stream_speed;
	vec2 p = vec2(travel, px.y) * noise_scale;
	float n = fbm(p + vec2(0.0, fbm(p * 0.6 + TIME * 0.3) * 2.0));

	// Dense at the mouth, ragged toward the far edge, thinner at the top and
	// bottom of the box.
	float heat = n * 0.7 + (1.0 - along) * 0.5 - abs(across) * 0.25;
	// Growing intensity lowers the bar, so the charge is the same flame with
	// less of it, reaching further out as it builds.
	float bar = mix(1.05, 0.30, intensity) + along * mix(0.5, 0.0, intensity);

	float lit = step(bar, heat);
	vec3 col = falloff_colour.rgb;
	col = mix(col, core_colour.rgb, step(bar + 0.14, heat));
	col = mix(col, hot_colour.rgb, step(bar + 0.34, heat));
	COLOR = vec4(col, lit);
}
