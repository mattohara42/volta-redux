## World scale. The three numbers every piece of art and every room is measured
## against, kept in one place because they are the numbers most likely to be
## wrong and they must not drift.
class_name WorldConfig
extends Resource

## Hero height in design px against a 640x360 design resolution.
## ART_DIRECTION.md called this the number most likely to be wrong. M0 settled
## it by cycling 28 / 34 / 40 / 46 / 54 in a running build: 40 is right. The
## pixel-art hero measures 36 at 1x, and ART_DIRECTION.md moves this to match
## rather than scaling the art (`world.tres`).
@export var hero_height: float = 40.0
## Hero width. Silhouette reads better narrower than half its height.
@export var hero_width: float = 18.0
## Grid the rooms are built on.
@export var tile_size: float = 16.0
## Blade length in design px. One tile, because M2 makes an embedded sword a
## one-tile ledge you stand on and those two numbers must not drift apart.
@export var sword_length: float = 16.0
## Floor-to-floor height of one storey. The jump-versus-ladders question is
## entirely about whether MovementConfig.jump_height clears this.
@export var tier_height: float = 96.0
