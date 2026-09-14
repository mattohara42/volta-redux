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


## True for every enemy but the scorpion. Takes the sword's node rather than
## just its position, because a species that cares about more than position
## (a sword's state, say) should be able to ask without a second signal.
func is_vulnerable_to(_sword: Node2D) -> bool:
	return true


## For the debug overlay and `tools/capture.gd`. Every species overrides this.
func status() -> String:
	return "enemy"
