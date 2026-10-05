// A rim of light on a sprite's edge, on the side a real light is: every
// opaque pixel whose neighbour toward the light is empty takes the light's
// colour. ART_DIRECTION.md's first fix for a shape that will not separate from
// its background is "a rim light from the nearest real light source", and
// this is that, moving as the light and the sprite move.
//
// The direction and strength are set each frame by `RimLight`; with no light
// near, the strength is zero and the sprite is drawn exactly as it was.
shader_type canvas_item;

uniform vec4 rim_colour : source_color;
// Toward the light, in the texture's own axes (already mirrored for facing).
uniform vec2 rim_dir = vec2(1.0, 0.0);
uniform float rim_strength = 0.0;

void fragment() {
	// COLOR arrives already textured and modulated; only the neighbours are
	// sampled here.
	vec4 c = COLOR;
	if (c.a > 0.5 && rim_strength > 0.0) {
		vec2 o = vec2(sign(rim_dir.x) * TEXTURE_PIXEL_SIZE.x, sign(rim_dir.y) * TEXTURE_PIXEL_SIZE.y);
		float edge = 0.0;
		if (abs(rim_dir.x) > 0.35) {
			edge = max(edge, step(texture(TEXTURE, UV + vec2(o.x, 0.0)).a, 0.5));
		}
		if (abs(rim_dir.y) > 0.35) {
			edge = max(edge, step(texture(TEXTURE, UV + vec2(0.0, o.y)).a, 0.5));
		}
		c.rgb = mix(c.rgb, rim_colour.rgb, edge * rim_strength);
	}
	COLOR = c;
}
