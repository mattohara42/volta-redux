## Act 2, room 5: the mine. **A climb you build out of your own swords**, with
## something in the way that eats them.
##
## Two storeys, each a ditch faced with timber cribbing: the far side is out of
## a jump's reach, and a sword thrown into the timber is a step you stand on and
## climb off. It is the outer wall's ditch crossing twice, one above the other, and
## `DitchChecks` holds both. Between them, on the middle level, an eyeball
## drifts toward you at your height (`SPEC.md`'s anti-catch enemy). Kill it with
## a throw and that sword is spent; get past it some other way and it is still
## there when you hold J to bring your steps home, waiting in the return line.
## A chest on the middle level means the climb can always be finished.
class_name Act2Mine
extends Bench

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")
const BEAM: Texture2D = preload("res://assets/art/act2/tiles_px/beam.png")

const ROOM_WIDTH: float = 1200.0
const HOARDING_WIDTH: float = 16.0
const RISE: float = 64.0

## The first ditch, from the entry floor up to the middle level.
const NEAR_1: float = 400.0
const TOP_0: float = FLOOR_TOP
const TOP_1: float = TOP_0 - RISE
const HOARDING_1 := Rect2(472.0, TOP_1, HOARDING_WIDTH, ROOM_HEIGHT - TOP_1)
const PIT_1: float = TOP_0 + 36.0

## The second, from the middle level up to the top.
const NEAR_2: float = 800.0
const TOP_2: float = TOP_1 - RISE
const HOARDING_2 := Rect2(872.0, TOP_2, HOARDING_WIDTH, ROOM_HEIGHT - TOP_2)
const PIT_2: float = TOP_1 + 36.0

## The eyeball: drifting between the first landing and the second lip, at the
## height of a hero on the middle level, and never onto either.
const EYEBALL_SIZE := Vector2(24.0, 24.0)
const EYEBALL_START := Vector2(680.0, TOP_1 - 60.0)
const EYEBALL_ROAM := Rect2(600.0, TOP_1 - 100.0, 150.0, 100.0)

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const MID_BRAZIER_X: float = 510.0
const MID_CHEST_X: float = 550.0
const EXIT_X: float = ROOM_WIDTH - 40.0
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)


## Every solid, as the ground `TileArt` draws: the three levels and the two
## ditch floors. The hoardings are wood and drawn as timber.
static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, TOP_0, NEAR_1, ROOM_HEIGHT - TOP_0),
		Rect2(NEAR_1, PIT_1, HOARDING_1.position.x - NEAR_1, ROOM_HEIGHT - PIT_1),
		Rect2(HOARDING_1.end.x, TOP_1, NEAR_2 - HOARDING_1.end.x, ROOM_HEIGHT - TOP_1),
		Rect2(NEAR_2, PIT_2, HOARDING_2.position.x - NEAR_2, ROOM_HEIGHT - PIT_2),
		Rect2(HOARDING_2.end.x, TOP_2, ROOM_WIDTH - HOARDING_2.end.x, ROOM_HEIGHT - TOP_2),
	]


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(CEILING)
	_add_wood(HOARDING_1, false)
	_add_wood(HOARDING_2, false)
	_add_ladder(NEAR_1 + 4.0, TOP_0, PIT_1)
	_add_ladder(NEAR_2 + 4.0, TOP_1, PIT_2)

	_add_brazier(Vector2(START_BRAZIER_X, TOP_0))
	_add_brazier(Vector2(MID_BRAZIER_X, TOP_1))
	_add_chest(Vector2(CHEST_X, TOP_0))
	_add_chest(Vector2(MID_CHEST_X, TOP_1))
	_add_eyeball(Rect2(EYEBALL_START - EYEBALL_SIZE * 0.5, EYEBALL_SIZE), EYEBALL_ROAM)

	_add_exit(Rect2(EXIT_X, TOP_2 - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
	for hoarding in [HOARDING_1, HOARDING_2]:
		draw_texture_rect(BEAM, hoarding, true)
	for ladder in _ladders:
		TileArt.draw_ladder(self, ladder)
