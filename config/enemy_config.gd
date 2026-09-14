## Every number an enemy's behaviour is made of.
##
## CLAUDE.md puts tuning in `config/`, the same rule `HazardConfig` follows: an
## enemy's speed and reach are what decide whether the mistake it punishes reads
## as a puzzle or as bad luck, and that is not something a script gets to hold.
##
## Shape belongs to the room, the way a ferry's span and a geyser's shaft do.
## A patrol range, a roam rectangle and a wall-crawl's loop are all facts about
## where a room put the thing, not about what the species does, so they are
## arguments a room passes rather than numbers in here.
class_name EnemyConfig
extends Resource

@export_group("Bat")
## How fast a bat covers its Lissajous path, radians/second along the faster of
## its two axes. SPEC.md: fast, and erratic enough that throwing at one costs
## you the sword nine times in ten.
@export var bat_angular_speed: float = 2.4
## The slower axis's speed as a fraction of the fast one. Anything close to 1.0
## draws a circle, which reads as a patrol rather than as erratic, so this is
## kept well off it.
@export var bat_axis_ratio: float = 0.63

@export_group("Scorpion")
## Ground speed, px/s. Slower than the hero's run, so patrolling into one is a
## choice and not an ambush.
@export var scorpion_speed: float = 60.0
## How far down from the top of its body the armour stops, as a fraction of its
## height. A hit above this line counts as "from above" regardless of side, per
## SPEC.md's "must be hit from behind or above".
@export var scorpion_armor_top_fraction: float = 0.35

@export_group("Giant ant")
## Speed along the wall it is walking, px/s, the same on every leg of the loop:
## floor, wall, ceiling and back. SPEC.md: it ignores gravity, and a speed that
## changed with orientation would be the one place this enemy admitted gravity
## existed.
@export var ant_speed: float = 70.0

@export_group("Floating eyeball")
## How fast it drifts toward the hero, px/s. Slow, per SPEC.md: it is not a
## chase, it is a height the hero keeps finding it at.
@export var eyeball_seek_speed: float = 45.0
