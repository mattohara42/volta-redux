// A geyser's jet while it is up: steam billowing upward inside the column.
//
// ART_DIRECTION.md: steam is the only pale thing in the game, cool and low in
// chroma because a geyser is the one hazard that does not kill, soft where the
// arc is hard-edged, and lit from the lava it rises out of, so it keeps a
// little warmth at the vent and loses it going up.
//
// The drawn column and the lifting box are the same rectangle (`Geyser`): the
// billows move inside it and never past it, and even its thinnest steam fills
// the whole box faintly, so a player can always read where the lift is.
// Banded and dithered on the art-pixel grid, the way every soft thing is here.
shader_type canvas_item;

#include "res://shaders/dither.gdshaderinc"

uniform vec4 body : source_color;
uniform vec4 core : source_color;
uniform vec4 warm : source_color;
// The column's size in art px, so the billows are drawn on the pixel grid.
uniform vec2 size = vec2(24.0, 120.0);
uniform float rise_speed = 110.0;
// How far up from the vent the warmth reaches, 0 to 1 of the height.
uniform float warm_reach = 0.3;
// How dense the jet is at its thinnest, at the edge of the box.
uniform float edge_alpha = 0.26;
// How tall the head of the jet is: the top of the reach, as a place.
uniform float crown = 5.0;
uniform float steps = 5.0;
// So two geysers side by side never billow in step.
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 px = floor(UV * size);
	float across = abs((px.x + 0.5) / size.x * 2.0 - 1.0);
	float down = (px.y + 0.5) / size.y;
	// Billows, sampled in coordinates that travel upward.
	vec2 q = vec2(px.x * 0.2, (px.y + TIME * rise_speed) * 0.06) + vec2(seed * 17.0, seed * 31.0);
	float billow = noise(q) * 0.65 + noise(q * 2.3 + 7.0) * 0.35;
	// The body's edge breathes with the billows, always inside the box.
	float edge = 0.62 + 0.38 * billow;
	float body_density = 1.0 - smoothstep(edge - 0.5, edge, across);
	float density = max(edge_alpha, body_density * (0.55 + 0.45 * billow));
	float head = step(px.y, crown - 1.0);
	density = max(density, head * 0.9);
	float level = clamp(density, 0.0, 1.0) * steps;
	float band = floor(level);
	float alpha = (band + step(bayer4(px), level - band)) / steps;
	float lit = clamp((1.0 - across) * (0.5 + 0.5 * billow) + head, 0.0, 1.0);
	vec3 colour = mix(body.rgb, core.rgb, lit);
	float warmth = smoothstep(1.0 - warm_reach, 1.0, down);
	colour = mix(colour, warm.rgb, warmth * 0.5);
	COLOR = vec4(colour, alpha);
}
