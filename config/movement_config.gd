## Every number that decides how it feels to move.
##
## Tuning happens in jump height and time to apex, not in velocity and gravity,
## because height and time are the units a person thinks in. The velocity and
## the gravity are derived from them by `Motion` and are never authored.
class_name MovementConfig
extends Resource

## Shown in the debug overlay so you know which preset you are feeling.
@export var preset_name: String = "unnamed"
## Why this preset exists. Read by nobody, written for the next session.
@export_multiline var note: String = ""

@export_group("Run")
## Top horizontal speed on the ground and in the air, px/s.
@export var max_run_speed: float = 200.0
## How hard the ground pushes you toward top speed, px/s².
@export var ground_accel: float = 1600.0
## How hard the ground stops you when you let go, px/s².
@export var ground_friction: float = 2400.0
## Air control. Below ground_accel or the jump has no commitment in it.
@export var air_accel: float = 1200.0
## Drag with no input in the air. Low, so a jump holds its line.
@export var air_friction: float = 400.0

@export_group("Jump")
## Apex height of a fully held jump, px. Compare against WorldConfig.tier_height.
@export var jump_height: float = 112.0
## Seconds from leaving the floor to the top of that jump.
@export var time_to_apex: float = 0.36
## Falling gravity as a multiple of rising gravity. Above 1.0 or it floats.
@export var fall_gravity_multiplier: float = 1.6
## Rising velocity is cut to this fraction when jump is released early.
@export_range(0.0, 1.0) var jump_release_damping: float = 0.4
## Terminal velocity, px/s.
@export var max_fall_speed: float = 700.0

@export_group("Forgiveness")
## Seconds after walking off a ledge during which jump still works.
@export var coyote_time: float = 0.10
## Seconds before landing during which a jump press is remembered.
@export var jump_buffer_time: float = 0.12

@export_group("Climbing")
## Ladder speed, px/s. Deliberately slower than running.
@export var climb_speed: float = 90.0

@export_group("Air moves")
## A jump taken at or above this horizontal speed is a somersault, px/s. Just
## above what one frame of held direction gives from a standstill, so pressing
## a direction as you jump flips and jumping straight up does not.
@export var somersault_min_speed: float = 20.0
## A fall at this vertical speed or faster is a dive, px/s. Above the speed a
## full jump lands at, or every jump would dive, and no higher than
## `max_fall_speed`, or nothing ever could.
@export var dive_fall_speed: float = 640.0
## Seconds the hero is rooted after landing from a dive. Nothing answers: no
## steering, no jump, no throw, no ladder.
@export var dive_recovery_time: float = 0.25
