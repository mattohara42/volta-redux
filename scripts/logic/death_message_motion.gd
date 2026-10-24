## How the death line moves, as arithmetic: where it is in its life decides how
## large and how opaque it is. No nodes, so a headless test reaches every line.
##
## It flies in from behind the room, small and faint, overshoots to a size that
## lands it, settles to the size it is read at, holds, and then keeps coming
## toward you as it fades, as if it flew through the screen (Matt, 2026-10-24).
##
## The size moves in steps, never smoothly. The line is pixel lettering, and
## `ART_DIRECTION.md` forbids drawing it at a scale that splits one of its
## pixels. `step` is the smallest scale that keeps every font pixel a whole
## number of the game's pixels, and every size this returns is a multiple of it.
class_name DeathMessageMotion


## The scale the line is drawn at, `elapsed` seconds into a message that lasts
## `total`. One at rest. The exit is checked first, so a message too short for
## all four beats still leaves rather than holding its punch to the last frame.
static func scale_at(
	elapsed: float, total: float, fly_in: float, settle: float, fade_out: float,
	from: float, punch: float, exit: float, step: float
) -> float:
	var scale := 1.0
	var leaving := elapsed - (total - fade_out)
	if fade_out > 0.0 and leaving >= 0.0:
		var p := clampf(leaving / fade_out, 0.0, 1.0)
		scale = lerpf(1.0, exit, p * p)
	elif elapsed < fly_in:
		var p := clampf(elapsed / fly_in, 0.0, 1.0)
		scale = lerpf(from, punch, 1.0 - (1.0 - p) * (1.0 - p))
	elif elapsed < fly_in + settle:
		scale = lerpf(punch, 1.0, clampf((elapsed - fly_in) / settle, 0.0, 1.0))
	return snapped_scale(scale, step)


## Opacity, zero to one. It comes up as the line flies in and goes as it flies
## out. Opacity has no pixels to split, so this one is smooth.
static func alpha_at(elapsed: float, total: float, fly_in: float, fade_out: float) -> float:
	if elapsed < 0.0 or elapsed >= total:
		return 0.0
	var alpha := 1.0
	if fly_in > 0.0:
		alpha = minf(alpha, elapsed / fly_in)
	if fade_out > 0.0:
		alpha = minf(alpha, (total - elapsed) / fade_out)
	return clampf(alpha, 0.0, 1.0)


## `scale` rounded to the nearest multiple of `step`, and never below one step,
## so the line cannot vanish by rounding to nothing.
static func snapped_scale(scale: float, step: float) -> float:
	if step <= 0.0:
		return scale
	return maxf(snappedf(scale, step), step)
