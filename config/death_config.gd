## Every number that decides what dying costs.
##
## SPEC.md: the lethality is the good part and the punishment was the bad part.
## These are the numbers that decide whether dying twenty times in a row is
## annoying (fine) or tedious (a failed milestone), so they live here and no
## script sets one.
class_name DeathConfig
extends Resource

@export_group("The one second")
## How long the body stays where it died before it is moved to the checkpoint,
## seconds. This is the beat that makes a death read as a death rather than as
## the screen glitching, and it is the first number to cut if the loop feels
## slow.
@export var death_hold: float = 0.25
## How long after being placed at the checkpoint before the controls answer,
## seconds. Short, and it exists so you see where you are before you move, and
## so a held direction does not walk you straight back into what killed you.
@export var respawn_freeze: float = 0.15

@export_group("The message")
## How long the death message stays on screen, seconds. It deliberately outlasts
## the loop itself: the line is still there once you have the controls back, so
## reading it costs nothing. Set it to zero to turn the messages off.
@export var message_seconds: float = 2.2
## Point size of the death message, against a 640x360 viewport. It is centred on
## the screen and meant to be read at a glance while you are already running, so
## it is a good deal larger than anything else the game draws.
@export var message_font_size: int = 24

@export_group("What comes back")
## Whether a respawn restores the swords you had spent. SPEC.md says it does:
## arriving at a checkpoint empty is the punishment the modernisation removes.
## Exposed rather than assumed because M14 will want to try it off once.
@export var restore_swords: bool = true
## How far from where you respawn a timed mechanism is put back to the start
## of its clock, px either way: about a screen. Further away, a big level
## keeps running (Matt, 2026-10-07).
@export var reset_reach: Vector2 = Vector2(640.0, 360.0)
