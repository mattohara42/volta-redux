// Lava (ART_DIRECTION.md: crust, flow, fissure, core). A drifting warped noise
// on a gradient, quantised to four palette bands, with bubbles that grow and
// pop. Nothing here is a texture. Everything is computed on the art-pixel grid
// (world position floored), so it reads as pixel art at any window size.
shader_type canvas_item;

uniform vec4 crust_colour : source_color;
uniform vec4 flow_colour : source_color;
uniform vec4 fissure_colour : source_color;
uniform vec4 core_colour : source_color;
uniform float scroll_speed;
uniform float noise_scale;
uniform float warp_strength;
uniform float flow_cut;
uniform float fissure_cut;
uniform float core_cut;
uniform float hot_depth;
uniform float bubble_cell;
uniform float bubble_rate;
uniform float crest_depth;

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
	for (int i = 0; i < 4; i++) {
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
	vec2 px = floor(world_px);
	float t = TIME;
	vec2 p = (px + vec2(t * scroll_speed, 0.0)) * noise_scale;
	float warp = fbm(p + vec2(0.0, t * 0.05));
	float n = fbm(p + vec2(warp * warp_strength, -t * 0.02 * scroll_speed));

	// Hot at the surface, crust further down.
	float surface_heat = smoothstep(hot_depth, 0.0, local_px.y) * 0.24;
	float heat = n * 0.95 + surface_heat;

	// Bubbles: a ring that grows out of a cell, then a bright pop.
	vec2 cell = floor(px / bubble_cell);
	float h1 = hash21(cell);
	float h2 = hash21(cell + vec2(7.3, 1.7));
	float h3 = hash21(cell + vec2(19.1, 4.9));
	float alive = step(0.5, h1);
	float phase = fract(t * bubble_rate * (0.6 + 0.8 * h1) + h2);
	vec2 centre = (cell + vec2(0.25 + 0.5 * h2, 0.25 + 0.5 * h3)) * bubble_cell;
	float radius = phase * bubble_cell * 0.42;
	float d = distance(px + 0.5, centre);
	float ring = step(abs(d - radius), 0.8) * step(0.12, phase) * alive;
	float pop = step(0.9, phase) * step(d, radius * 0.7) * alive;
	heat += ring * 0.30 + pop * 0.6;

	// The bright crest along the surface, a few pixels thick and wobbling.
	float wobble = floor(sin(px.x * 0.33 + t * 2.1) + 0.5);
	float crest = step(local_px.y, crest_depth + wobble);

	vec3 col = crust_colour.rgb;
	col = mix(col, flow_colour.rgb, step(flow_cut, heat));
	col = mix(col, fissure_colour.rgb, step(fissure_cut, heat));
	col = mix(col, core_colour.rgb, step(core_cut, heat));
	col = mix(col, core_colour.rgb, crest);
	COLOR = vec4(col, 1.0);
}
