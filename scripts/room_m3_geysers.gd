## The M3 geyser bench: two storeys, and no way up either of them except a jet
## of water that is not there most of the time.
##
## The four M3 benches ask four different questions. Lava and spikes ask where
## your feet are, and you can answer either standing still. A falling platform
## asks about time and the wrong answer is hesitating. A ferry asks the same
## question from the other end, which is walking at a gap as though the room owed
## you a floor. **A geyser asks what you are going to do while you are in the
## air**, which is the question the 1984 original could not ask, because once you
## were airborne there it was nothing but hope.
##
## So this is the only bench where the hazard is the route. SPEC.md has geysers
## as an Act 2 hazard and as one of the two ordinary ways to gain a storey, and
## both ledges here are a storey up: the jump owns holes and short steps and
## cannot reach either of them.
##
## **The first jet teaches and the second one asks.** The first comes up out of a
## solid floor and there is nothing under it to die in, so the only thing it can
## cost you is the wait for the next one. The second comes up out of a lava moat,
## and reading its clock wrong is the whole of what M3 is measuring. One new
## thing at a time, which is the shape of the spike bench and the ferry bench too.
##
## Both jets carry you exactly the same distance, so the room asks its question
## twice at one tempo rather than asking two questions at once.
class_name RoomM3Geysers
extends Bench

## How wide a shaft is. Four tiles, and the number is set by the second jet: you
## enter that one by walking off a lip at a run, and air friction needs 50 px to
## stop a 200 px/s hero. A jet you could cross before it had lifted you would be
## a hazard that punishes running, which is not the mistake it is about.
const COLUMN_WIDTH: float = 64.0
## How far the top of a jet stands above the ledge it serves.
##
## You leave a column by drifting sideways out of it and that takes air, so a jet
## stopping level with its ledge would ask for a sideways step with no time in it.
## Carried past the ledge instead, you come down onto it, and holding the
## direction you were already going is enough. The forgiving direction, which is
## where M3 puts its forgiveness.
const COLUMN_OVERSHOOT: float = 24.0

## How far below the ledge surface the lava sits, so a jet reads as rising out of
## the moat rather than as standing in a pool of it.
const LAVA_INSET: float = 20.0

const START_BRAZIER_X: float = 60.0
## Floor between the start brazier and the near edge of the first shaft. The one
## number in the first half of the room that is about the death loop rather than
## the climb: a respawn has to be standing in the column with enough of the
## eruption left to be carried the whole way.
const FIRST_VENT_X: float = 180.0
## The first ledge, which is the block the first jet runs up the face of.
const LEDGE_START: float = FIRST_VENT_X + COLUMN_WIDTH
const LEDGE_WIDTH: float = 200.0
## And its far edge, which is the lip you step off into the second jet.
const LEDGE_END: float = LEDGE_START + LEDGE_WIDTH

const FAR_BANK_START: float = LEDGE_END + COLUMN_WIDTH
const FAR_BANK_WIDTH: float = 140.0
const ROOM_WIDTH: float = FAR_BANK_START + FAR_BANK_WIDTH

## Ledge between the mid brazier and the lip.
##
## The number the second half of the room is built on, and it has a floor as well
## as a ceiling, which nothing else in M3 does. Too long and a respawn cannot
## reach the moat while the jet is still up. **Too short and it arrives before the
## jet does**, which is worse: a player running flat out of a checkpoint would
## step off the lip into lava having made no mistake at all.
const BOARDING_RUN: float = 128.0
const MID_BRAZIER_X: float = LEDGE_END - BOARDING_RUN


## The ledge the first jet serves, a storey above the floor.
static func first_ledge(tier: float) -> float:
	return FLOOR_TOP - tier


## And the one the second serves, a storey above that.
static func second_ledge(tier: float) -> float:
	return FLOOR_TOP - tier * 2.0


## How far a jet carries you: a storey, and then far enough past the ledge to
## have time to come down on it. The same for both, because you enter the first
## at the floor and the second at the lip, and each is a storey below its ledge.
static func ride_height(tier: float) -> float:
	return tier + COLUMN_OVERSHOOT


## The first shaft, standing on the floor with the first ledge's face beside it.
##
## The face matters as much as the jet. A column with a wall down one side means
## a player who holds the direction they were already running gets carried up
## that wall and stepped onto the ledge at the top of it, so the easy answer is
## also a correct one. Getting off is still yours to time: let go and you ride
## past the ledge and come back down the shaft.
static func first_column(tier: float) -> Rect2:
	var top := first_ledge(tier) - COLUMN_OVERSHOOT
	return Rect2(FIRST_VENT_X, top, COLUMN_WIDTH, FLOOR_TOP - top)


## The second, which fills the moat and comes up out of the lava in it.
##
## Its box starts at the lava and not at the lip, so a mistimed step off the lip
## falls the short distance into the moat rather than being caught by a jet that
## was not there. What you ride is the distance from the lip up, which is the
## same storey and overshoot the first one gives you.
static func second_column(tier: float) -> Rect2:
	var top := second_ledge(tier) - COLUMN_OVERSHOOT
	return Rect2(LEDGE_END, top, COLUMN_WIDTH, lava_top(tier) - top)


## The lava in the moat, which is the only thing in the room that kills.
static func moat(tier: float) -> Rect2:
	var top := lava_top(tier)
	return Rect2(LEDGE_END, top, COLUMN_WIDTH, ROOM_HEIGHT - top)


static func lava_top(tier: float) -> float:
	return first_ledge(tier) + LAVA_INSET


## How far a hero has to run from `from` before any part of them is inside the
## shaft at `column_x`. Being in the jet is an overlap and not an arrival, so the
## edge of the body is what counts and the checkpoint arithmetic says so.
static func run_to_column(from: float, column_x: float, hero_width: float) -> float:
	return maxf(column_x - hero_width * 0.5 - from, 0.0)


func _ready() -> void:
	var tier := world.tier_height
	var ledge := first_ledge(tier)
	var upper := second_ledge(tier)
	_add_solid(Rect2(0.0, FLOOR_TOP, LEDGE_START, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(LEDGE_START, ledge, LEDGE_WIDTH, ROOM_HEIGHT - ledge))
	_add_solid(Rect2(FAR_BANK_START, upper, FAR_BANK_WIDTH, ROOM_HEIGHT - upper))
	_add_lava(moat(tier))
	_add_geyser(first_column(tier))
	_add_geyser(second_column(tier))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_brazier(Vector2(MID_BRAZIER_X, ledge))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	_draw_bench(ROOM_WIDTH)
	# The far end. Gold means interactive, and reaching it is the thing you are
	# trying to do twenty times.
	var top := second_ledge(world.tier_height)
	draw_rect(Rect2(ROOM_WIDTH - 60.0, top - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
