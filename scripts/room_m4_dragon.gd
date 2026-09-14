## The M4 dragon bench: SPEC.md's mini-boss, alone in a small arena.
##
## The whole fight is a positioning puzzle rather than a new system: see
## `Dragon`. This bench's one job is to make the intended shot physically
## possible without asking the player to throw through the dragon's own body
## to set it up. A ledge lets a throw clear the dragon's low body and reach
## wood on the far side; standing on the floor in front of the dragon to
## recall is what brings the sword home through it.
class_name RoomM4Dragon
extends Bench

const ROOM_WIDTH: float = 600.0

const START_BRAZIER_X: float = 40.0

## Tall enough to clear a throw over the dragon's body, short enough that
## both movement presets' jumps reach it.
const LEDGE := Rect2(120.0, FLOOR_TOP - 40.0, 90.0, 40.0)

## Low and immobile, but tall enough that a throw off the ledge only just
## clears it (measured in a running build), which is what makes jumping the
## ledge the honest way over it rather than an accident of scale.
const DRAGON_SIZE := Vector2(56.0, 48.0)
## Far enough from the ledge that there is real floor to land and stand on
## before the dragon's own body, not the 22 px a first pass left, which a
## falling hero cannot reliably stop inside of. Measured in a running build.
const DRAGON_X: float = 340.0
## Angled down and kept short, so the ledge stays a safe place to stand and
## the cone still reaches the floor a hero clear of the body is standing on.
const BREATH_OFFSET := Vector2(-150.0, 10.0)
const BREATH_SIZE := Vector2(90.0, 30.0)

## A tall strip rather than a plank at one height, so the exact throw height
## off the ledge does not have to be threaded to the pixel.
const WOOD := Rect2(400.0, 180.0, 24.0, 140.0)


func _ready() -> void:
	# One sword. BUILD_PLAN.md's M11 done-when is that the dragon is beatable
	# without spending a sword on it, and the honest way to prove that is to
	# remove the option of a second throw rather than trust a player not to
	# take it: with three in hand, holding to recall still throws a fresh
	# one first, per Player._step_throw_button, and that one bounces off the
	# dragon's body for nothing. One sword makes the only throw available
	# the one that has to come home again.
	_hand_out_swords(1)
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_solid(LEDGE)
	_add_dragon(
		Rect2(DRAGON_X - DRAGON_SIZE.x * 0.5, FLOOR_TOP - DRAGON_SIZE.y, DRAGON_SIZE.x, DRAGON_SIZE.y),
		BREATH_OFFSET, BREATH_SIZE
	)
	_add_wood(WOOD)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
