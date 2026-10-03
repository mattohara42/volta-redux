## M2's first room: **it cannot be finished without standing on your own thrown
## sword.** That is BUILD_PLAN.md's done-when, stated as geometry.
##
## The far side stands 64 px up, out of a 56 px jump, and its face is wood.
## Throw into the face and the sword is a step 44 px under the top: jump onto it,
## then off it. A ladder gets you out of the ditch, so falling in is a retry.
##
## It used to be a post standing in a 120 px gap, and no build could finish it:
## a jump off the ledge cannot clear a post a jump from the floor cannot land on.
## The tests checked horizontal reach only. `DitchChecks` now holds every room
## with this crossing, and a scenario crosses `Act1Gate`'s in a real build.
class_name RoomM2Gap
extends Bench

const ROOM_WIDTH: float = 820.0

## Where the near side stops. The player's centre can reach 391, being 9 px of
## half-width short of it, and that is where the throw is measured from.
const NEAR_EDGE: float = 400.0
## The far side, higher than a jump, with a wooden face the sword bites.
const FAR_EDGE: float = 472.0
const FAR_TOP: float = FLOOR_TOP - 64.0
const HOARDING := Rect2(FAR_EDGE, FAR_TOP, 16.0, ROOM_HEIGHT - FAR_TOP)

## The bottom of the gap. Shallow on the near side and deep on the far side,
## which is what makes falling in a retry and not a shortcut.
const PIT_TOP: float = 356.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, NEAR_EDGE, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(HOARDING.end.x, FAR_TOP, ROOM_WIDTH - HOARDING.end.x, ROOM_HEIGHT - FAR_TOP))
	_add_solid(Rect2(NEAR_EDGE, PIT_TOP, FAR_EDGE - NEAR_EDGE, ROOM_HEIGHT - PIT_TOP))
	_add_wood(HOARDING)
	# The way back out of the pit, and the first ladder in a room built after the
	# jump question was settled. A 36 px step would also do it; this is what
	# SPEC.md now says vertical movement is.
	_add_ladder(NEAR_EDGE + 4.0, FLOOR_TOP, PIT_TOP)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	# The far side, which is the done-when. Gold means interactive.
	draw_rect(Rect2(ROOM_WIDTH - 70.0, FAR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
