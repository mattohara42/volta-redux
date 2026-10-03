## A slab that crosses a gap on a schedule and does not care whether you are on
## it.
##
## The clock and every transition in it live in `PlatformFerry`, where a headless
## test can reach them. This script is the part that cannot be pure: it moves a
## body, carries what is standing on it, and draws.
##
## It is the same node as `FallingPlatform` with a different clock and no
## trigger, and that is the design. A falling platform punishes standing still. A
## ferry punishes the opposite mistake, which is walking at a gap as though the
## room owed you a floor when you got there.
class_name MovingPlatform
extends Platform

## How thick the rail it runs on is drawn, and how far the posts at each dock
## stand off it. Both are how it looks rather than how it behaves, so they stay
## here and not in `config/hazards.tres`.
const RAIL_THICKNESS: float = 2.0
const POST_HEIGHT: float = 5.0
## How wide the runners under each end of the slab are drawn.
const RUNNER_WIDTH: float = 6.0

## Read by the overlay and by `tools/capture.gd`. What it is doing now.
var phase: PlatformFerry.Phase = PlatformFerry.Phase.HOME

## The whole trip, as an offset from home. The room owns it, because how far a
## ferry goes is a fact about the moat it was put over.
var _travel := Vector2.ZERO
## Seconds since the room started. A ferry has no trigger, so unlike a falling
## platform this begins at zero and never stops.
var _elapsed: float = 0.0


func configure(size: Vector2, travel: Vector2, hazards: HazardConfig) -> void:
	_travel = travel
	_build(size, hazards)


func _physics_process(delta: float) -> void:
	if config == null:
		return
	_elapsed += delta
	var crossing := PlatformFerry.travel_seconds(_travel.length(), config.platform_travel_speed)
	var was := phase
	phase = PlatformFerry.phase_at(_elapsed, crossing, config.platform_wait_time)
	position = _home + PlatformFerry.offset_at(
		_elapsed, crossing, config.platform_wait_time, _travel
	)
	# The rail is drawn at a fixed place in the room by a node that is moving, so
	# its local coordinates change every frame the slab does. Docked, nothing
	# moves and nothing is redrawn.
	if phase != was or phase == PlatformFerry.Phase.OUTBOUND \
			or phase == PlatformFerry.Phase.INBOUND:
		queue_redraw()


## Back at the dock it started from, with its wait beginning again once the
## player can move.
##
## This is what makes a ferry survivable twenty deaths in a row. Left running, a
## respawn would hand you a platform somewhere out in the middle of the moat, and
## the first thing you would do with your restored controls is stand still and
## watch it come back. The clock starts negative so that the freeze the respawn
## still owes the player is spent at the dock rather than out of their window to
## board: see `Platform.reset`.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	phase = PlatformFerry.Phase.HOME
	position = _home
	queue_redraw()


func status() -> String:
	return PlatformFerry.phase_name(phase)


## Cold and matte, like everything you can stand on. `ART_DIRECTION.md` reserves
## warm and saturated for what kills you, and this does not kill you: the lava it
## crosses does.
##
## So the tell is shape, and it is the opposite of the falling slab's. That one
## is a bitten-off block with a fault through it, a thing that has already half
## gone. This is intact stone sitting on runners, on a rail that reaches both
## ends of its trip. **The rail is the only thing in the room that says where the
## slab will be in a second**, and that is the sentence a player has to read
## before they decide to jump.
func _draw() -> void:
	if _draw_art():
		return
	_draw_rail()
	var rect := Rect2(-_size * 0.5, _size)
	draw_rect(rect, Palette.STONE_MID)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), Palette.STONE_LIT)
	# Runners under each end, so the slab reads as resting on the rail rather
	# than as floating above it.
	for x in [rect.position.x, rect.end.x - RUNNER_WIDTH]:
		draw_rect(
			Rect2(Vector2(x, rect.end.y), Vector2(RUNNER_WIDTH, RAIL_THICKNESS)),
			Palette.STONE_DEEP
		)


## The rail, in the node's own coordinates, which move with it.
##
## A horizontal run only. A lift would want a different fixture and there is no
## lift in the game, so this draws nothing rather than guessing at one.
func _draw_rail() -> void:
	if not is_zero_approx(_travel.y) or is_zero_approx(_travel.x):
		return
	var home := _home - position
	var left := minf(home.x, home.x + _travel.x) - _size.x * 0.5
	var right := maxf(home.x, home.x + _travel.x) + _size.x * 0.5
	var top := home.y + _size.y * 0.5
	draw_rect(Rect2(left, top, right - left, RAIL_THICKNESS), Palette.STONE_DEEP)
	# A post at each dock, so the two ends of the trip are places and not just
	# where the rail happens to stop.
	for x in [left, right - RAIL_THICKNESS]:
		draw_rect(Rect2(x, top, RAIL_THICKNESS, POST_HEIGHT), Palette.STONE_DEEP)
