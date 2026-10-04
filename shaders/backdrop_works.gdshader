// Act 3's backdrop, the generator's works, until a painted one replaces it:
// cold air, a far line of lattice pylons strung with cable and turning
// flywheels between them, and nearer bundles of pipe rim lit by the residue
// blue of spent current. A lamp blinks on each pylon. Two layers of parallax.
//
// ART_DIRECTION.md: backgrounds lose, and electricity is the only cool bright.
// So nothing here is bright, the lamps are residue rather than arc, and no
// bolt is drawn: an arc on the wall must never be read as one in the room.
shader_type canvas_item;

#include "res://shaders/backdrop.gdshaderinc"

uniform vec4 air_top : source_color;
uniform vec4 air_bottom : source_color;
uniform vec4 far_iron : source_color;
uniform vec4 near_iron : source_color;
uniform vec4 rim : source_color;
uniform vec4 lamp : source_color;
uniform vec4 lamp_warm : source_color;
uniform float far_depth = 0.2;
uniform float near_depth = 0.45;
uniform float gear_spin = 0.15;
uniform float lamp_rate = 0.7;

const float PYLON_SPACING = 176.0;
const float PYLON_TOP = 64.0;
const float PYLON_FOOT = 336.0;
const float ARM_Y = 70.0;
const float ARM_HALF = 22.0;

void vertex() {
	world_px = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// A lattice pylon centred on `cx`: two legs, X bracing, an insulator stack and
// a cross arm. True where `p` is iron.
bool pylon(vec2 p, float cx) {
	float dx = p.x - cx;
	if (p.y >= PYLON_TOP && p.y <= PYLON_FOOT) {
		float t = (p.y - PYLON_TOP) / (PYLON_FOOT - PYLON_TOP);
		float half_width = floor(mix(4.0, 13.0, t));
		if (abs(abs(dx) - half_width) < 1.0) {
			return true;
		}
		if (abs(dx) < half_width) {
			float panel = fract((p.y - PYLON_TOP) / 22.0);
			float brace = half_width * (panel * 2.0 - 1.0);
			if (abs(dx - brace) < 1.0 || abs(dx + brace) < 1.0 || panel < 0.05) {
				return true;
			}
		}
	}
	// The cross arm and the insulators hanging under each end of it.
	if (abs(p.y - ARM_Y) < 1.5 && abs(dx) <= ARM_HALF) {
		return true;
	}
	if (p.y > ARM_Y && p.y < ARM_Y + 10.0 && abs(abs(dx) - ARM_HALF) < (mod(p.y, 3.0) < 1.5 ? 2.5 : 1.5)) {
		return true;
	}
	// The mast above the arm.
	return p.y >= PYLON_TOP - 22.0 && p.y < PYLON_TOP && abs(dx) < 1.0;
}

// A flywheel centred on `centre`, turning: a toothed rim, six spokes, a hub.
bool flywheel(vec2 p, vec2 centre, float radius, float turn) {
	vec2 d = p - centre;
	float r = length(d);
	if (r > radius + 5.0) {
		return false;
	}
	float a = atan(d.y, d.x) + turn;
	float tooth = step(0.5, fract(a / 6.2831853 * 22.0));
	if (r > radius - 7.0) {
		return r < radius + 5.0 * tooth;
	}
	if (r < 10.0) {
		return r > 4.0;
	}
	return abs(sin(a * 3.0)) * r < 2.5;
}

void fragment() {
	vec2 p = floor(world_px);
	float h = clamp(p.y / room_height, 0.0, 1.0);
	vec3 col = mix(air_top.rgb, air_bottom.rgb, banded(h, 5.0));

	// The far works.
	float fx = layer_x(far_depth);
	vec2 fp = vec2(fx, p.y);
	float index = floor(fx / PYLON_SPACING + 0.5);
	float cx = index * PYLON_SPACING;
	bool iron = pylon(fp, cx);
	// Cable from this pylon's arm to the next one's, sagging between.
	float span_left = floor(fx / PYLON_SPACING) * PYLON_SPACING;
	float s = (fx - span_left - ARM_HALF) / (PYLON_SPACING - ARM_HALF * 2.0);
	if (s > 0.0 && s < 1.0) {
		float sag = 18.0 + 10.0 * hash11(floor(fx / PYLON_SPACING));
		for (int k = 0; k < 2; k++) {
			float cable_y = ARM_Y + 10.0 + float(k) * 6.0 + sag * 4.0 * s * (1.0 - s);
			if (abs(p.y - floor(cable_y)) < 0.5) {
				iron = true;
			}
		}
	}
	// A flywheel in some spans, turning slowly behind the cables.
	float wheel_cell = floor(fx / (PYLON_SPACING * 2.0));
	if (hash11(wheel_cell + 4.0) > 0.4) {
		float wheel_x = wheel_cell * PYLON_SPACING * 2.0 + PYLON_SPACING;
		float spin = (hash11(wheel_cell) > 0.5 ? 1.0 : -1.0) * TIME * gear_spin;
		if (flywheel(fp, vec2(wheel_x, 236.0), 46.0, spin)) {
			iron = true;
		}
	}
	if (iron) {
		col = far_iron.rgb;
	}
	// A lamp at the top of each mast, blinking on its own clock.
	vec2 bulb = vec2(cx, PYLON_TOP - 23.0);
	if (abs(fx - bulb.x) < 1.5 && abs(p.y - bulb.y) < 1.5) {
		float phase = hash11(index + 11.0);
		bool on = fract(TIME * lamp_rate + phase) < 0.35;
		col = on ? (phase > 0.75 ? lamp_warm.rgb : lamp.rgb) : far_iron.rgb;
	}

	// Nearer pipe, in bundles, with flanges and a cold rim down one side.
	float nx = layer_x(near_depth);
	float bundle = floor(nx / 280.0);
	if (hash11(bundle + 1.0) > 0.3) {
		float start = bundle * 280.0 + 40.0 + floor(hash11(bundle + 8.0) * 170.0);
		float count = 2.0 + floor(hash11(bundle + 15.0) * 2.0);
		float along = nx - start;
		float which = floor(along / 15.0);
		float within = along - which * 15.0;
		if (along >= 0.0 && which < count) {
			float flange = mod(p.y + which * 13.0, 52.0) < 4.0 ? 2.0 : 0.0;
			if (within >= 2.0 - flange && within < 12.0 + flange) {
				col = near_iron.rgb;
				if (within < 4.0 - flange) {
					col = rim.rgb;
				}
			}
		}
	}
	// A duct along the top of the room.
	if (p.y > 38.0 && p.y < 54.0) {
		col = near_iron.rgb;
		if (p.y < 40.0 || mod(nx, 64.0) < 1.0) {
			col = rim.rgb;
		}
	}
	COLOR = vec4(col, 1.0);
}
