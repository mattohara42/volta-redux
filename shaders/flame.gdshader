// The dragon's breath (ART_DIRECTION.md: atmosphere is code). A plume of fire
// streaming from the mouth: white-hot at the mouth, cooling through orange and
// red as it travels, rising a little and fraying into smoke at its tip, all
// quantised to palette bands and dithered on the art pixel grid.
//
// What kills is a cone inside the room's breath box: narrow at the jaws, at
// the top of the box where the head is, spreading down to the floor as it
// travels. The drawn
// rectangle overspills the box by `spill` px on the top and the far end,
// where the flame frays, and never below it, where the floor is. At full
// intensity every pixel of the cone is fire, so what kills is always seen
// burning; the frayed edge beyond it is only seen, the same mercy an enemy
// sprite drawn bigger than its killing box gives. `intensity` is 0 to
// 1, and the telegraph is the same plume, shorter and cooler, growing from the
// mouth.
shader_type canvas_item;

uniform vec4 falloff_colour : source_color;
uniform vec4 core_colour : source_color;
uniform vec4 hot_colour : source_color;
uniform vec4 ember_colour : source_color;
uniform vec4 smoke_colour : source_color;
uniform vec2 box_size;
uniform float spill = 0.0;
// The cone that kills (`DragonBreath.cone`): the fraction of the box's height
// that burns at the jaws, and how far along it opens to the full height.
uniform float cone_mouth = 0.5;
uniform float cone_open = 0.35;
uniform float direction = 1.0;
uniform float intensity = 1.0;
uniform float stream_speed;
uniform float noise_scale;

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

// A 2x2 ordered dither, so a soft edge is a pattern of whole art pixels
// rather than a blend.
float dither(vec2 px) {
	vec2 m = mod(px, 2.0);
	return (m.x + m.y * 2.0 + 0.5) / 4.0;
}

void vertex() {
	local_px = VERTEX;
}

void fragment() {
	vec2 px = floor(local_px);
	float length_px = box_size.x + spill;
	// Distance from the jaws, px, and as a fraction of the box's reach.
	float d = direction > 0.0 ? px.x : length_px - px.x;
	float a = d / box_size.x;
	// Rows from the top of the box (the drawn rectangle starts `spill` above).
	float row = px.y - spill;
	float floor_row = box_size.y;

	// The cone's bottom edge, the same formula as `DragonBreath.cone_gap`.
	float cone_row = floor_row - box_size.y * (1.0 - cone_mouth) * (1.0 - smoothstep(0.0, cone_open, clamp(a, 0.0, 1.0)));
	// The plume: from the cone's bottom up to the box's top, lifting further
	// into the spill as it travels, the way hot air rises.
	float top = -spill * smoothstep(0.25, 1.1, a);
	float centre = (top + cone_row) * 0.5;
	float half_height = max((cone_row - top) * 0.5, 1.0);

	// Turbulence streaming away from the jaws; the row wobbles with it so
	// tongues curl.
	float travel = d - TIME * stream_speed;
	vec2 p = vec2(travel, px.y * 1.6) * noise_scale;
	float n = fbm(p + vec2(0.0, fbm(p * 0.5 + TIME * 0.4) * 2.5));

	float radial = abs(row - centre) / half_height;
	// Hottest at the jaws and along the middle, cooling as it travels.
	float heat = (1.0 - pow(radial, 1.3)) * (1.35 - 0.85 * clamp(a, 0.0, 1.3));
	// More turbulence toward the edge, so tongues break out above it.
	heat += (n - 0.5) * (0.8 + 0.6 * radial);
	// The charge: shorter and cooler, growing out of the jaws.
	heat -= (1.0 - intensity) * (0.35 + 1.4 * a);
	// Nothing burns below the floor.
	heat = row >= floor_row ? -1.0 : heat;

	vec3 col = ember_colour.rgb;
	float alpha = 0.0;
	float dith = dither(px);
	if (heat > 0.78) {
		col = hot_colour.rgb; alpha = 1.0;
	} else if (heat > 0.52) {
		col = core_colour.rgb; alpha = 1.0;
	} else if (heat > 0.30) {
		col = falloff_colour.rgb; alpha = 1.0;
	} else if (heat > 0.14) {
		col = ember_colour.rgb; alpha = step(dith, 0.8);
	} else if (heat > 0.02 && a > 0.55) {
		// Smoke, only where the flame has travelled far enough to burn out.
		col = smoke_colour.rgb; alpha = step(dith, 0.5) * smoke_colour.a;
	}

	// Honesty: at full breath, everywhere that kills is visibly on fire.
	bool in_cone = d >= 0.0 && d < box_size.x && row >= 0.0 && row < cone_row;
	if (intensity >= 0.999 && in_cone && alpha < 1.0) {
		float flick = hash21(px + floor(TIME * 12.0));
		col = flick > 0.5 ? ember_colour.rgb : falloff_colour.rgb;
		alpha = 1.0;
	}
	COLOR = vec4(col, alpha);
}
