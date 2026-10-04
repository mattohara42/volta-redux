## A switch that needs current, not impact (`SPEC.md`, Act 3). It is a socket of
## metal in a wall: wire it into a live circuit and it opens what the room tied
## it to. A sword thrown into it is just a sword in metal, which is the point:
## impact does nothing here, only current does. It never kills.
class_name CurrentSwitch
extends Conductor

signal held_changed(is_held: bool)


func _kills() -> bool:
	return false


func _on_live_changed(live: bool) -> void:
	held_changed.emit(live)


## Gold, because it is used (`ART_DIRECTION.md`): a gold socket from across the
## room, lit cyan while current runs through it.
func _draw() -> void:
	var local := Rect2(-rect.size * 0.5, rect.size)
	draw_rect(local, Palette.GOLD_SHADE)
	draw_rect(local.grow(-2.0), Palette.ARC if is_live else Palette.BACKDROP)
	draw_rect(local, Palette.GOLD_FACE, false, 1.0)
