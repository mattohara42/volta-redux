// A sprite drawn as a flat silhouette in one colour: the frame's own shape,
// filled. For an enemy's last frame as it dies (`EnemyGhost`), so the thing
// that was there flashes before it goes. The colour is the caller's, from
// Palette, never a white.
shader_type canvas_item;

uniform vec4 tint : source_color;
uniform float alpha = 1.0;

void fragment() {
	COLOR = vec4(tint.rgb, texture(TEXTURE, UV).a * alpha);
}
