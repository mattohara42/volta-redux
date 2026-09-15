## SPEC.md's scorpion: ground patrol, armoured front. The mistake it punishes
## is throwing from the front, which the armour bounces; `ScorpionPatrol`
## carries both the walk and the geometry that decides whether a given hit gets
## through.
##
## The room owns the range it walks, the way it owns a ferry's span: `range` is
## the distance from where the room placed it (the near end) to the far end.
class_name Scorpion
extends Enemy

var _range: float = 0.0
var _home := Vector2.ZERO
var _elapsed: float = 0.0
var _facing := 1.0


## See `Bat.place` for why this is not called `configure`.
func place(size: Vector2, range: float, enemy_config: EnemyConfig) -> void:
	configure(size)
	_range = range
	_config = enemy_config
	add_to_group("mechanisms")


func _ready() -> void:
	_home = position


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	_elapsed += delta
	_update()


func _update() -> void:
	_facing = ScorpionPatrol.facing_at(_elapsed, _range, _config.scorpion_speed)
	position = _home + Vector2(ScorpionPatrol.offset_at(_elapsed, _range, _config.scorpion_speed), 0.0)
	queue_redraw()


func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "scorpion" + _status_suffix()


## Armour only stops a hit within `is_vulnerable_to`'s geometry, computed from
## where the sword actually is relative to this scorpion's own centre right
## now: the same "ask the world, do not guess" rule `Sword.embed_position`
## follows, for the same reason.
func is_vulnerable_to(sword: Node2D) -> bool:
	var offset := sword.global_position - global_position
	return ScorpionPatrol.is_vulnerable_to(
		offset, _facing, killing_box.y * 0.5, _config.scorpion_armor_top_fraction
	)


## Low and wide, with the armoured face drawn as a plate on whichever side it
## is walking toward, so the mistake the enemy punishes is legible before the
## sword is thrown and not only after.
func _draw() -> void:
	var half := killing_box * 0.5
	draw_rect(Rect2(-half, killing_box), Palette.ENEMY_CHITIN)
	var plate_x := _facing * half.x * 0.55
	draw_rect(Rect2(plate_x - 3.0, -half.y, 6.0, killing_box.y), Palette.STONE_LIT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(_facing * half.x, -half.y * 0.3),
		Vector2(_facing * (half.x + 8.0), 0.0),
		Vector2(_facing * half.x, half.y * 0.3),
	]), Palette.SPIKE_TIP)
