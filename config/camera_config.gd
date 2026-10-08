## The hero's camera (N0). It looks ahead the way you last moved, so what is
## coming is on screen before you reach it.
class_name CameraConfig
extends Resource

## How far ahead of the hero the view sits, design px: a tenth of the 640 px
## view.
@export var look_ahead: float = 64.0
## How fast the view swings to the other side when you turn and run, px/s. Slow
## enough that a turn is a glide rather than a cut.
@export var look_ahead_speed: float = 160.0
## Below this horizontal speed (px/s) the lead holds where it is, so turning
## on the spot to throw does not swing the view.
@export var look_ahead_min_speed: float = 20.0
## Godot's own position smoothing, which follows the hero and the lead both.
## It lived in player.tscn until N0.
@export var smoothing_speed: float = 8.0
