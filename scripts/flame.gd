## How every small fire in the game is drawn: a brazier's, a wall torch's. One
## recipe, so a flame looks like the same fire wherever it burns, the way
## `LightGlow` makes every light look like the same light.
##
## Three tongues, outer to inner going from falloff to core to hot, each
## widest at the base, tapering to a leaning point. Atmosphere is code
## (`CLAUDE.md`): nothing here is a texture.
class_name Flame

const STEPS := 8
## How far the tip leans, as a fraction of a tongue's half width.
const LEAN := 0.45
## Each tongue's half width and height as a fraction of the outer one's, and
## the phase that keeps the three from moving as one.
const TONGUES: Array[Vector3] = [
	Vector3(1.0, 1.0, 0.0),
	Vector3(0.675, 0.72, 1.9),
	Vector3(0.325, 0.40, 3.6),
]
const COLOURS: Array[Color] = [Palette.FIRE_FALLOFF, Palette.FIRE_CORE, Palette.FIRE_HOT]


## A flame standing on `base`, `half_width` across at its widest and `height`
## tall. `flicker` is the owner's clock in seconds, wrapped however it likes.
## Only works inside `canvas`'s `_draw`.
static func draw(
	canvas: CanvasItem, base: Vector2, half_width: float, height: float, flicker: float
) -> void:
	for i in TONGUES.size():
		var tongue := TONGUES[i]
		_tongue(canvas, base, half_width * tongue.x, height * tongue.y, flicker, tongue.z, COLOURS[i])


static func _tongue(
	canvas: CanvasItem, base: Vector2, half_width: float, height: float,
	flicker: float, phase: float, colour: Color
) -> void:
	var lean := sin(flicker * 6.0 + phase) * half_width * LEAN
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in STEPS + 1:
		var t := float(i) / float(STEPS)
		# Full width at the base, a point at the tip, and a slight waist between
		# the two. A straight taper draws a horn rather than a flame.
		var width := half_width * pow(1.0 - t, 0.85) * (1.0 + 0.35 * sin(PI * t))
		var at := base + Vector2(lean * t * t, -height * t)
		left.append(at + Vector2(-width, 0.0))
		right.append(at + Vector2(width, 0.0))
	right.reverse()
	canvas.draw_colored_polygon(left + right, colour)
