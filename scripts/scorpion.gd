## SPEC.md's scorpion: ground patrol, armoured front, and it hunts. The mistake
## it punishes is throwing from the front, which the armour bounces;
## `ScorpionPatrol` carries the geometry that decides whether a given hit gets
## through, and `ScorpionHunt` what it does about the hero.
##
## The room owns the range it walks, the way it owns a ferry's span: `range` is
## the distance from where the room placed it (the near end) to the far end.
## Where its floor stops, and whether it can see the hero, it finds out from
## the world each frame, so the same scorpion hunts in a hand-built bench and
## in a level drawn in text.
class_name Scorpion
extends Enemy

## The pixel-art scorpion (`ANIMATION.md`): a walk loop, drawn at 1x, its
## paler armoured claws and face leading the way it walks.
const SPRITE_SCENE: PackedScene = preload("res://scenes/scorpion_sprite.tscn")

## How far past its own body it looks for the end of its floor, px: one step
## of the walk at any speed it has, so it stops before it is over the edge.
const PROBE_AHEAD := 3.0
## How far under its feet a floor still counts as floor, px. Less than any
## step a level draws (16), so a step down is a ledge.
const PROBE_DEPTH := 8.0
## How far above its feet the wall probe runs, px: low, so a step up one cell
## is a wall it will not walk into, as a wall of any height is.
const PROBE_RISE := 4.0
## Layer 1, "world": what it stands on and what it cannot see through.
const WORLD_MASK := 1

var _range: float = 0.0
var _home := Vector2.ZERO
var _hunt := ScorpionHunt.State.new()
## Seconds still to wait before moving, the hero's freeze at a respawn.
var _frozen := 0.0


## See `Bat.place` for why this is not called `configure`.
func place(size: Vector2, range: float, enemy_config: EnemyConfig) -> void:
	configure(size)
	_range = range
	_config = enemy_config
	add_to_group("mechanisms")


func _ready() -> void:
	_home = position
	_hunt.x = _home.x
	_attach_sprite(SPRITE_SCENE, "walk")
	_face_sprite(_hunt.facing)


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	if _frozen > 0.0:
		_frozen -= delta
		return
	var hero := get_tree().get_first_node_in_group("player") as Player
	var seen := false
	var hero_dx := 0.0
	if hero != null:
		var hero_feet := hero.global_position + Vector2(0.0, hero.world.hero_height * 0.5)
		var offset := hero_feet - _feet()
		hero_dx = offset.x
		seen = (
			ScorpionHunt.sees(offset, _hunt.facing, _hunt.hunting, _config.scorpion_sight)
			and _clear_line_to(hero.global_position)
		)
	ScorpionHunt.step(
		_hunt, seen, hero_dx, _floor_stops(-1.0), _floor_stops(1.0),
		_home.x, _home.x + _range, _config.scorpion_speed, _config.scorpion_hunt_speed,
		_config.scorpion_lose_after, delta
	)
	position.x = _hunt.x
	_face_sprite(_hunt.facing)


func _feet() -> Vector2:
	return global_position + Vector2(0.0, killing_box.y * 0.5)


## Whether its floor stops within a step the way `dir` points: a wall in the
## way, or no floor under the next step.
func _floor_stops(dir: float) -> bool:
	var space := get_world_2d().direct_space_state
	var feet := _feet()
	var reach := killing_box.x * 0.5 + PROBE_AHEAD
	var wall := PhysicsRayQueryParameters2D.create(
		feet + Vector2(0.0, -PROBE_RISE), feet + Vector2(dir * reach, -PROBE_RISE), WORLD_MASK
	)
	if not space.intersect_ray(wall).is_empty():
		return true
	var ahead := feet + Vector2(dir * reach, 0.0)
	var ground := PhysicsRayQueryParameters2D.create(
		ahead + Vector2(0.0, -PROBE_RISE), ahead + Vector2(0.0, PROBE_DEPTH), WORLD_MASK
	)
	return space.intersect_ray(ground).is_empty()


func _clear_line_to(target: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var line := PhysicsRayQueryParameters2D.create(global_position, target, WORLD_MASK)
	return space.intersect_ray(line).is_empty()


## Back to where the room first put it, walking out, its hunt forgotten, and
## still until the hero's freeze is over.
func reset(frozen_for: float) -> void:
	_hunt = ScorpionHunt.State.new()
	_hunt.x = _home.x
	_frozen = maxf(frozen_for, 0.0)
	position.x = _hunt.x
	_face_sprite(_hunt.facing)


func status() -> String:
	return "scorpion" + _status_suffix()


## Armour only stops a hit within `is_vulnerable_to`'s geometry, computed from
## where the sword actually is relative to this scorpion's own centre right
## now: the same "ask the world, do not guess" rule `Sword.embed_position`
## follows, for the same reason.
func is_vulnerable_to(sword: Node2D) -> bool:
	var offset := sword.global_position - global_position
	return ScorpionPatrol.is_vulnerable_to(
		offset, _hunt.facing, killing_box.y * 0.5, _config.scorpion_armor_top_fraction
	)
