## What every one of the six SPEC.md enemies has in common: touching it kills
## you, and it can be killed back.
##
## Extends `Hazard` rather than composing one, because "touches the hero, hero
## dies" is exactly `Hazard`'s whole job and SPEC.md's kill list already has
## animals on it beside lava, water and spikes. `configure` reclaims the two
## fields that make an enemy different from a hazard that never moves: it has
## to sit on a physics layer a sword can stop against (`Hazard`'s own boxes are
## invisible to everything on purpose, so a thrown sword would sail through),
## and it has to be told when a sword arrived so it can decide, itself, whether
## that hit was a killing one.
##
## That decision is the one piece every species overrides. A bat, an ant and an
## eyeball die to any contact, so the base implementation says yes to all of
## them, and only `Scorpion` says anything else, per SPEC.md's "must be hit
## from behind or above". Nothing about the sword's own machine changes: see
## `Sword._on_area_entered`.
class_name Enemy
extends Hazard

## Layer 6, "enemies". A sword watches it and nothing else does, the same
## arrangement lava and spikes have with layer 3: a box only the thing that
## needs to see it can see.
const ENEMY_LAYER: int = 1 << 5

## Every species stores the same resource under the same name, so it lives
## here once rather than five times: `place` sets it, `_step_dormancy` reads
## it, and a species reads it for whatever numbers its own patrol needs.
var _config: EnemyConfig

## True while decoration rather than an enemy: no patrol, no seeking, no
## killing on touch, until the hero comes within `_wake_range`. SPEC.md's
## six do not include this on their own; it is LEVELS.md's "is this
## decoration or is it alive" trick, built once here so any species can use
## it rather than once per costume.
var is_dormant := false
var _wake_range := 0.0


func configure(size: Vector2) -> void:
	super.configure(size)
	add_to_group("enemies")
	collision_layer = ENEMY_LAYER
	# Others can find this one now: a hazard is invisible on purpose, and an
	# enemy has to be the opposite, or the sword that is supposed to stop
	# against it sails through.
	monitorable = true
	# Still watching the player (inherited from Hazard's mask=4) and now the
	# swords layer too, so both halves of "both die" have one place to start
	# from: whichever of the two shows up in this box first.
	collision_mask |= SWORD_LAYER
	area_entered.connect(_on_area_entered)


## Layer 4, matching `scenes/sword.tscn`'s `collision_layer`.
const SWORD_LAYER: int = 1 << 3


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("swords"):
		return
	if is_vulnerable_to(area):
		queue_free()


## Dormant decoration does not kill on touch. `Hazard`'s own signal calls
## this; overridden rather than left alone so "asleep" means asleep, not
## merely still. A sword can still test it early: `_on_area_entered` above
## is untouched, so a suspicious player gets to be right about a statue.
func _on_body_entered(body: Node2D) -> void:
	if is_dormant:
		return
	super._on_body_entered(body)


## True for every enemy but the scorpion. Takes the sword's node rather than
## just its position, because a species that cares about more than position
## (a sword's state, say) should be able to ask without a second signal.
func is_vulnerable_to(_sword: Node2D) -> bool:
	return true


## Opts an already-placed enemy into starting dormant. Called by whoever
## placed it, after `place`, because "does this one start asleep" is a room
## decision the way a patrol's range is, not a fact about the species.
func start_dormant() -> void:
	is_dormant = true
	_wake_range = _config.dormant_wake_range


## The one thing every species calls first in its own `_physics_process`.
## Returns true while still dormant, which is a species' cue to do nothing
## else this frame: a sleeping scorpion does not patrol, a sleeping bat does
## not tumble. Waking has no tell beyond starting to move, which is the
## point: the surprise is that decoration moves at all.
func _step_dormancy(_delta: float) -> bool:
	if not is_dormant:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= _wake_range:
		is_dormant = false
		return false
	return true


## For the debug overlay and `tools/capture.gd`. Every species overrides this,
## appending `_status_suffix` so a sleeping one says so in the log.
func status() -> String:
	return "enemy" + _status_suffix()


func _status_suffix() -> String:
	return " (dormant)" if is_dormant else ""
