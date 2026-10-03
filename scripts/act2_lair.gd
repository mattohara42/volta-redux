## Act 2, room 6: the dragon's lair. **Beaten with recall, never with a fresh
## throw, and not killed**: overpowered and chained (`LEVELS.md`), the dragon
## you will free in Act 4.
##
## The fight is `RoomM4Dragon`'s, the same ledge, dragon and breath: a throw from
## the ledge only just clears its low body and bites wood past it, and standing
## in front of it to hold J brings the sword home through it. One change, so the
## act can go on: the wood is a timber hanging from the roof rather than a post
## from the floor. A throw from the ledge still meets it at the same height, and
## once the dragon is chained there is room to walk under it to the way on.
##
## One sword, as on the bench and for the bench's reason: with three, holding J
## throws a fresh sword first, which bounces off the body for nothing, so the
## only honest proof of "beatable without spending a sword" is to hand out one.
## A chest past the dragon makes the act's next room whole again.
class_name Act2Lair
extends Bench

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")
const BEAM: Texture2D = preload("res://assets/art/act2/tiles_px/beam.png")

const ROOM_WIDTH: float = 760.0
const SWORDS_HANDED_OUT: int = 1

## The bench's arena, unchanged.
const START_BRAZIER_X: float = RoomM4Dragon.START_BRAZIER_X
const LEDGE := RoomM4Dragon.LEDGE
const DRAGON_SIZE := RoomM4Dragon.DRAGON_SIZE
const DRAGON_X: float = RoomM4Dragon.DRAGON_X
const BREATH_OFFSET := RoomM4Dragon.BREATH_OFFSET
const BREATH_SIZE := RoomM4Dragon.BREATH_SIZE

## The bench's post, hung from the roof with walking room under it.
const HEADROOM: float = 40.0
const TIMBER := Rect2(
	RoomM4Dragon.WOOD.position.x, 32.0, RoomM4Dragon.WOOD.size.x, FLOOR_TOP - HEADROOM - 32.0
)

const CHEST_X: float = 520.0
const EXIT_X: float = ROOM_WIDTH - 40.0
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)


func _ready() -> void:
	_hand_out_swords(SWORDS_HANDED_OUT)
	texture_repeat = TEXTURE_REPEAT_ENABLED
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(CEILING)
	_add_solid(LEDGE)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_dragon(
		Rect2(DRAGON_X - DRAGON_SIZE.x * 0.5, FLOOR_TOP - DRAGON_SIZE.y, DRAGON_SIZE.x, DRAGON_SIZE.y),
		BREATH_OFFSET, BREATH_SIZE
	)
	_add_wood(TIMBER, false)
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
	TileArt.draw_ground(self, Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP), TILES)
	TileArt.draw_ground(self, LEDGE, TILES)
	draw_texture_rect(BEAM, TIMBER, true)
