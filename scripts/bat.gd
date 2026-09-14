## SPEC.md's bat: erratic flight, fast, no ground contact. The mistake it
## punishes is throwing at a moving target, and the path in `BatFlight` is what
## makes that true without a hitscan or a difficulty dial: it is fast and it
## does not go where a straight throw would expect.
##
## The room owns the box it tumbles inside, the way it owns a ferry's span,
## because how far a bat is allowed to roam is a fact about where it was put.
class_name Bat
extends Enemy

var _config: EnemyConfig
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


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_update()


func _update() -> void:
	_facing = BatFlight.facing_at(
		_elapsed, _config.bat_angular_speed, _config.bat_axis_ratio, _half_extents, _facing
	)
	position = _centre + BatFlight.offset_at(
		_elapsed, _config.bat_angular_speed, _config.bat_axis_ratio, _half_extents
	)
	queue_redraw()


## Back to the centre of its box at the first frame of its path. A bat left
## running through a respawn could be anywhere in the box, including on top of
## the checkpoint it just put the hero at, which is the geyser bug M3 found
## applied to something that also kills on touch.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "bat"


## A narrow diamond, wings out. Reads as small and quick against the hero's
## capsule, which ART_DIRECTION.md's silhouette rule asks of every enemy.
func _draw() -> void:
	var r := killing_box.length() * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r, 0.0), Vector2(0.0, -r * 0.4), Vector2(r, 0.0), Vector2(0.0, r * 0.4),
	]), Palette.ENEMY_CHITIN)
	draw_line(Vector2(-r * 0.5, 0.0), Vector2(r * 0.5, 0.0), Palette.SPIKE_TIP, 1.5)
