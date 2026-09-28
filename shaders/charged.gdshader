// A charged surface (Act 3's conductive floors): thin cyan filaments crawling
// over a dark blue-violet base, hard-edged, on the art-pixel grid. The same
// electricity as the arc, spread over a plane, and no texture.
shader_type canvas_item;

uniform vec4 base_colour : source_color;
uniform vec4 filament_colour : source_color;
uniform vec4 core_colour : source_color;
uniform float crawl_speed;
uniform float noise_scale;
uniform float line_width;

varying vec2 world_px;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 px = floor(world_px);
	float n = value_noise(px * noise_scale + vec2(TIME * crawl_speed, TIME * crawl_speed * 0.6));
	float m = value_noise(px * noise_scale * 1.7 - vec2(TIME * crawl_speed * 0.8, 3.1));
	float line = step(abs(n - 0.5), line_width);
	float second = step(abs(m - 0.5), line_width * 0.7);
	float spark = step(0.985, hash21(px + floor(TIME * 12.0)));
	vec3 col = base_colour.rgb;
	col = mix(col, filament_colour.rgb, max(line, second));
	col = mix(col, core_colour.rgb, spark * max(line, second));
	COLOR = vec4(col, 1.0);
}
