## Act 2, room 2: the geyser shaft. **Two storeys, and the only way up either
## is a jet that is not there most of the time.** The first rises out of the
## floor and can only cost you a wait; the second rises out of lava.
##
## The climb is `RoomM3Geysers`'s, inherited rather than copied: that bench's
## twelve tests and its two capture scenarios already hold every ride, lip and
## respawn timing, and they hold this room too. What this room adds is Act 2:
## cavern rock in place of bench shapes, a rock ceiling, a chest by the way in,
## and an exit to the next room in `config/act2.tres`.
class_name Act2Geysers
extends RoomM3Geysers

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")

const CHEST_X: float = 110.0
const EXIT_X: float = ROOM_WIDTH - 40.0
## Rock overhead, as in the cavern mouth. A jet's top stands well below it.
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)


## The floor, the first ledge and the far bank, as the ground `TileArt` draws.
static func grounds(tier: float) -> Array[Rect2]:
	var ledge := first_ledge(tier)
	var upper := second_ledge(tier)
	return [
		Rect2(0.0, FLOOR_TOP, LEDGE_START, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(LEDGE_START, ledge, LEDGE_WIDTH, ROOM_HEIGHT - ledge),
		Rect2(FAR_BANK_START, upper, FAR_BANK_WIDTH, ROOM_HEIGHT - upper),
	]


func _ready() -> void:
	super._ready()
	_add_solid(CEILING)
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	var upper := second_ledge(world.tier_height)
	_add_exit(Rect2(EXIT_X, upper - 48.0, 8.0, 48.0))


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
	for ground in grounds(world.tier_height):
		TileArt.draw_ground(self, ground, TILES)
