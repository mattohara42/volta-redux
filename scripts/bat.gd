## SPEC.md's bat: erratic flight, fast, no ground contact. The mistake it
## punishes is throwing at a moving target, and the path in `BatFlight` is what
## makes that true without a hitscan or a difficulty dial: it is fast and it
## does not go where a straight throw would expect.
##
## The room owns the box it tumbles inside, the way it owns a ferry's span,
## because how far a bat is allowed to roam is a fact about where it was put.
class_name Bat
extends Enemy

## The rig this species is built from, painted once for the whole game.
## `assets/art/bat/rig/`, cut from the M5 delivery `ART.md` records.
const RIG_SCENE: PackedScene = preload("res://scenes/bat_rig.tscn")
## `scenes/bat_rig.tscn`'s own bone and sprite offsets, composited: the
## wingtip-to-wingtip, nose-to-tail bounding box the rig actually draws
## into, centred here so the rig sits on the killing box the same way the
## drawn diamond did.
const RIG_SOURCE_CENTRE: Vector2 = Vector2(600.0, 425.0)
## `assets/art/bat/rig/body.png`'s own width, head to tail, in the same
## source pixels as the centre above.
const RIG_SOURCE_BODY_LENGTH: float = 660.0
## Roughly Lothar's own torso height at the game's default `world.hero_height`
## (`Player.RIG_SOURCE_TORSO_LENGTH`, scaled): `ART.md`'s prompt asked for a
## bat "roughly the size of a human torso." Picked to render and check by
## screenshot, not tracked live against a debug hero resize.
const RIG_TARGET_BODY_LENGTH: float = 18.0

var _half_extents := Vector2.ZERO
var _centre := Vector2.ZERO
var _elapsed: float = 0.0
var _facing := 1.0
## The painted rig, standing in for the drawn diamond wherever one is
## available. Null only if `RIG_SCENE` fails to load, in which case `_draw`
## falls back to the diamond rather than showing nothing.
var _rig: Node2D = null


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
	if RIG_SCENE != null:
		_rig = RIG_SCENE.instantiate()
		add_child(_rig)
		_update_rig()


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
	_update_rig()
	queue_redraw()


## Sized off the rig's own recorded offsets rather than the killing box,
## which is deliberately smaller than the painted creature (`BUILD_PLAN.md`'s
## M4 bench). Mirrors around the rig's own centreline, same reason as
## `Player._update_rig`: the painted bat is not centred on (0, 0) in its own
## scene.
func _update_rig() -> void:
	if _rig == null:
		return
	var rig_scale := RIG_TARGET_BODY_LENGTH / RIG_SOURCE_BODY_LENGTH
	var signed_scale := rig_scale * _facing
	_rig.scale = Vector2(signed_scale, rig_scale)
	_rig.position = -RIG_SOURCE_CENTRE * Vector2(signed_scale, rig_scale)


## Back to the centre of its box at the first frame of its path. A bat left
## running through a respawn could be anywhere in the box, including on top of
## the checkpoint it just put the hero at, which is the geyser bug M3 found
## applied to something that also kills on touch.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "bat" + _status_suffix()


## A narrow diamond, wings out. M5 painted the real thing (`_update_rig`), so
## this only runs as the fallback for a scene that somehow has no rig, and the
## shape it draws still reads as small and quick against the hero's capsule,
## which ART_DIRECTION.md's silhouette rule asks of every enemy.
func _draw() -> void:
	if _rig != null:
		return
	var r := killing_box.length() * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-r, 0.0), Vector2(0.0, -r * 0.4), Vector2(r, 0.0), Vector2(0.0, r * 0.4),
	]), Palette.ENEMY_CHITIN)
	draw_line(Vector2(-r * 0.5, 0.0), Vector2(r * 0.5, 0.0), Palette.SPIKE_TIP, 1.5)
