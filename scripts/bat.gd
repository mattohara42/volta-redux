## SPEC.md's bat: erratic flight, fast, no ground contact. The mistake it
## punishes is throwing at a moving target, and the path in `BatFlight` is what
## makes that true without a hitscan or a difficulty dial: it is fast and it
## does not go where a straight throw would expect.
##
## The room owns the box it tumbles inside, the way it owns a ferry's span,
## because how far a bat is allowed to roam is a fact about where it was put.
class_name Bat
extends Enemy

## The pixel-art bat (`ANIMATION.md`): a flap loop, drawn at 1x.
const SPRITE_SCENE: PackedScene = preload("res://scenes/bat_sprite.tscn")

var _half_extents := Vector2.ZERO
var _centre := Vector2.ZERO
var _elapsed: float = 0.0
var _facing := 1.0


## Not `configure`: `Hazard` already gives that name one argument, and a
## species with more to say needs a name of its own rather than an override
## with a different arity. `Platform`'s two subclasses make the same choice
## for the same reason, just with `_build` underneath instead of `Enemy`'s
## `configure`.
func place(size: Vector2, half_extents: Vector2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_half_extents = half_extents
	_config = enemy_config
	add_to_group("mechanisms")


func _ready() -> void:
	_centre = position
	_attach_sprite(SPRITE_SCENE, "fly")
	_face_sprite(_facing)


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	_elapsed += delta
	_update()


func _update() -> void:
	_facing = BatFlight.facing_at(
		_elapsed, _config.bat_angular_speed, _config.bat_axis_ratio, _half_extents, _facing
	)
	position = _centre + BatFlight.offset_at(
		_elapsed, _config.bat_angular_speed, _config.bat_axis_ratio, _half_extents
	)
	_face_sprite(_facing)


## Back to the centre of its box at the first frame of its path. A bat left
## running through a respawn could be anywhere in the box, including on top of
## the checkpoint it just put the hero at, which is the geyser bug M3 found
## applied to something that also kills on touch.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "bat" + _status_suffix()
