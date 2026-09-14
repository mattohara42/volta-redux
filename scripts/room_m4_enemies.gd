## The M4 enemy bench: one floor, all six from SPEC.md's table minus the two
## bosses, each placed so the mistake it punishes is the first thing you would
## try against it.
##
## BUILD_PLAN.md's M4 done-when is that a room with all six is survivable on
## three swords. The two bosses are Act 2 and Act 3 set pieces with mechanics
## SPEC.md has not designed yet (see `BACKLOG.md`), so this bench holds the
## four that are built: the scorpion, the giant ant, the bat and the eyeball.
##
## No platforming. M3 already proved the jump and the fall; this room is only
## about the fight, so the floor never breaks.
class_name RoomM4Enemies
extends Bench

const ROOM_WIDTH: float = 1000.0

const START_BRAZIER_X: float = 60.0

## The scorpion walks this far from `SCORPION_HOME_X`, armoured front first.
## SPEC.md's mistake: throwing from the front, which the armour bounces.
## Tall enough that a standing throw meets its body rather than automatically
## reading as "from above": measured in a running build, a squat 20 px body
## put its centre far enough below the hero's own throw height that every
## ground-level throw landed in the top of the armour's fraction regardless of
## side, which made the front/back rule impossible to reach without jumping.
## SPEC.md's "or above" is meant to reward gaining height on purpose, not to
## fire by default. 34 px puts a standing throw a few pixels under the line
## instead, with jumping over it still reaching genuinely above.
const SCORPION_SIZE := Vector2(30.0, 34.0)
const SCORPION_HOME_X: float = 260.0
const SCORPION_RANGE: float = 140.0

## After the scorpion, before the ant: a death here costs the scorpion crossing
## and nothing before it, the same bargain `RoomM3`'s braziers make.
const MID_BRAZIER_1_X: float = 430.0

## The ant's loop. Its floor leg sits on the real floor (`track.end.y ==
## FLOOR_TOP`), on purpose: SPEC.md's mistake is assuming the floor is safe,
## and the floor here is the same floor the hero is walking, not a second one
## drawn to look dangerous. M9 gives it an actual wall to be seen on; the loop
## is where it will be.
const ANT_SIZE := Vector2(22.0, 16.0)
const ANT_TRACK := Rect2(560.0, FLOOR_TOP - 150.0, 90.0, 150.0)

## The bat tumbles above the walkway rather than beside it, low enough that
## its box reaches head height on the dip: SPEC.md's mistake is throwing at a
## moving target, and the honest way to make that available is to put the
## target somewhere a thrown sword would have to lead it.
const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(740.0, FLOOR_TOP - 90.0)
const BAT_HALF_EXTENTS := Vector2(70.0, 60.0)

## Before the bat and the eyeball, the two that do not hold still.
const MID_BRAZIER_2_X: float = 820.0

## The eyeball's roam overlaps the finish on purpose: SPEC.md's anti-catch
## enemy is the last thing between the hero and the door, not a side room.
const EYEBALL_SIZE := Vector2(24.0, 24.0)
const EYEBALL_START := Vector2(900.0, FLOOR_TOP - 60.0)
const EYEBALL_ROAM := Rect2(830.0, FLOOR_TOP - 150.0, 140.0, 150.0)

const FINISH_X: float = ROOM_WIDTH - 60.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_scorpion(
		Rect2(SCORPION_HOME_X - SCORPION_SIZE.x * 0.5, FLOOR_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y),
		SCORPION_RANGE
	)
	_add_brazier(Vector2(MID_BRAZIER_1_X, FLOOR_TOP))
	_add_ant(ANT_SIZE, ANT_TRACK)
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_brazier(Vector2(MID_BRAZIER_2_X, FLOOR_TOP))
	_add_eyeball(
		Rect2(EYEBALL_START - EYEBALL_SIZE * 0.5, EYEBALL_SIZE), EYEBALL_ROAM
	)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	draw_rect(Rect2(FINISH_X, FLOOR_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
