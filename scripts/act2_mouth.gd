## Act 2, room 1: the cavern mouth. **Lava, and floors that are already going
## somewhere.** Two moats too wide to jump, each crossed only on a basalt slab
## riding back and forth over it.
##
## The crossing is `RoomM3Moving`'s, inherited rather than copied: that bench's
## ten tests (`tests/test_room_m3_moving.gd`) already hold every jump, dock and
## respawn timing in it, and they hold this room too. What this room adds is
## Act 2 itself: cavern rock and basalt in place of bench shapes, a chest by the
## way in, and an exit to the next room in `config/act2.tres`.
class_name Act2Mouth
extends RoomM3Moving

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")
const SLAB_ART: Texture2D = preload("res://assets/art/act2/tiles_px/slab.png")

const CHEST_X: float = 120.0
## Rock overhead, so the cave reads as a cave before its background is painted.
## Solid, so what is drawn is what you hit; far above any jump.
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)
const EXIT_X: float = ROOM_WIDTH - 40.0


## The three banks, as the ground `TileArt` draws.
static func banks() -> Array[Rect2]:
	return [
		Rect2(0.0, FLOOR_TOP, FIRST_BANK_END, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(ISLAND_START, FLOOR_TOP, ISLAND_END - ISLAND_START, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(LAST_BANK_START, FLOOR_TOP, ROOM_WIDTH - LAST_BANK_START, ROOM_HEIGHT - FLOOR_TOP),
	]


func _ready() -> void:
	super._ready()
	for child in get_children():
		var ferry := child as MovingPlatform
		if ferry != null:
			ferry.art = SLAB_ART
	_add_solid(CEILING)
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
	for bank in banks():
		TileArt.draw_ground(self, bank, TILES)
