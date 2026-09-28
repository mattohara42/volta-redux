## SPEC.md's floating eyeball: tracks you slowly, at your height. The anti-
## catch enemy, and it eats returning swords with no code of its own that knows
## what a catch is: it just drifts toward wherever the hero now is, and the
## sword's own contact rule (`Sword._on_area_entered`) does the rest, the same
## way it would for any enemy that happened to be standing in the return line.
##
## `roam` is the box the room lets it drift inside, so a checkpoint it drifted
## right up against is still survivable on a respawn: see `reset`.
class_name Eyeball
extends Enemy

## The pixel-art eyeball (`ANIMATION.md`): a float-and-pulse loop, drawn at 1x.
## It does not turn to face the hero; the pupil looks straight out.
const SPRITE_SCENE: PackedScene = preload("res://scenes/eyeball_sprite.tscn")

var _roam := Rect2()
var _start := Vector2.ZERO


## See `Bat.place` for why this is not called `configure`.
func place(size: Vector2, roam: Rect2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_roam = roam
	_config = enemy_config
	add_to_group("mechanisms")


func _ready() -> void:
	_start = position
	_attach_sprite(SPRITE_SCENE, "float")


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	position = EyeballSeek.step(position, player.global_position, _config.eyeball_seek_speed, delta, _roam)


## Back to wherever the room first put it. Not clock-driven the way a bat or a
## scorpion is, so there is no elapsed time to park: it is a position, and
## `frozen_for` is spent by the hero's own freeze before this ever gets asked
## to move again.
func reset(_frozen_for: float) -> void:
	position = _start


func status() -> String:
	return "eyeball" + _status_suffix()
