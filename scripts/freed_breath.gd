## The freed dragon's one breath, at Volta (`Act4Throne`). A cone of fire from
## `from` to `to` for `BREATH_TIME`, then gone. Presentation only: it kills
## nothing, because what it does is the room's (`Volta.fall_into`).
class_name FreedBreath
extends Node2D

signal finished

const BREATH_TIME: float = 0.7
const WIDTH: float = 22.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _clock := 0.0


func setup(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()
	if _clock >= BREATH_TIME:
		finished.emit()
		queue_free()


func _draw() -> void:
	var along := (_to - _from).normalized()
	var across := Vector2(-along.y, along.x)
	var reach := minf(_clock / (BREATH_TIME * 0.4), 1.0)
	var tip := _from.lerp(_to, reach)
	var flicker := 1.0 + 0.15 * sin(_clock * 40.0)
	for layer in [[1.0, Palette.FIRE_FALLOFF], [0.6, Palette.FIRE_CORE], [0.25, Palette.FIRE_HOT]]:
		var w: float = WIDTH * float(layer[0]) * flicker
		draw_colored_polygon(PackedVector2Array([
			_from,
			tip + across * w * 0.5,
			tip + along * w * 0.3,
			tip - across * w * 0.5,
		]), layer[1])
