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

@export_group("Dragon")
## Seconds of tell before a breath goes out. Read against the falling
## platform's 0.45 s and the geyser's 0.5 s warnings: this one is a little
## longer again, because SPEC.md's mistake is panic and the tell has to last
## long enough to be read rather than flinched at.
@export var dragon_charge_time: float = 0.7
## Seconds the cone stays lethal.
@export var dragon_breathe_time: float = 0.5
## Seconds of quiet between breaths. Long enough that lining up a throw into
## the wood past the dragon, and then the recall through it, both fit inside
## one rest: BUILD_PLAN.md's M11 done-when is that the dragon is beatable
## without spending a sword on it, and a rest too short to set up the one
## legitimate shot would make that a matter of luck.
@export var dragon_rest_time: float = 2.6
## How far the snout reaches from the dragon's centre, px, which is where the
## breath starts. A property of the sprite: the room decides how far the breath
## goes, and the dragon fills the gap back to its own face so the fire and the
## kill box both leave the mouth.
@export var dragon_snout_reach: float = 36.0

@export_group("Dormant")
## How close the hero has to come to wake a dormant enemy, px. Bigger than a
## catch radius or a switch's reach: this is a warning distance, not a
## precise trigger, and LEVELS.md's whole point is that the hero finds out by
## something moving, not by reading a hitbox.
@export var dormant_wake_range: float = 40.0

@export_group("Generator")
## The rest between arcs, seconds. The generator throws at where you were when
## it began to charge, so this is how long you get to stand still and throw.
@export var generator_rest_time: float = 1.6
## The warning, seconds: a marker where the arc will land. Long enough to step
## out of at a walk, which is the only thing it asks.
@export var generator_warning_time: float = 0.8
## How long the arc stays in the ground, seconds.
@export var generator_strike_time: float = 0.3
## The arc's killing box, px, centred on where you stood.
@export var generator_strike_size: Vector2 = Vector2(32.0, 48.0)
