## Embers lifting off a fire for as long as it burns: a lit brazier, a torch.
## Single art pixels, hot to nothing as they rise, and light (they draw over
## the room's dark). The fire's own flame is `Flame`; this is what comes off it.
##
## Purely how it looks, so its numbers sit here (`Burst` says why).
class_name Embers
extends CPUParticles2D


## An emitter at `at`, `half_width` across, `rate` times a brazier's flow.
static func rising(at: Vector2, half_width: float, rate: float = 1.0) -> Embers:
	var embers := Embers.new()
	embers.position = at
	embers.amount = maxi(int(6.0 * rate), 1)
	embers.lifetime = 1.1
	embers.emission_shape = EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(maxf(half_width, 1.0), 1.0)
	embers.direction = Vector2.UP
	embers.spread = 20.0
	embers.initial_velocity_min = 10.0
	embers.initial_velocity_max = 26.0
	embers.gravity = Vector2(0.0, -6.0)
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Palette.FIRE_HOT)
	ramp.set_color(1, Color(Palette.FIRE_FALLOFF, 0.0))
	ramp.add_point(0.5, Palette.FIRE_CORE)
	embers.color_ramp = ramp
	LightField.emissive(embers)
	return embers
