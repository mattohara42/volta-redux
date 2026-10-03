## Act 2, room 3: the causeway. **A throw you have to catch before the
## platform you are standing on drops** (`SPEC.md`, Act 2's lesson).
##
## Two lines of basalt slabs over lava, each giving way a moment after you land,
## as on `RoomM3Falling`, whose crossing this inherits along with its tests. Over
## the second line a bat works the air at body height. Time the crossing round
## it, or throw at it from the island. A hit kills it and spends the sword
## (`SPEC.md`: both die). A miss is the lesson: the sword flies out, turns, and
## comes back to wherever you are now, which is somewhere on slabs that are
## already going, and a catch you are not there for lands behind you.
class_name Act2Causeway
extends RoomM3Falling

const TILES: ActTiles = preload("res://assets/art/act2/act2_tiles.tres")
const SLAB_ART: Texture2D = preload("res://assets/art/act2/tiles_px/slab.png")

const CHEST_X: float = 120.0
const EXIT_X: float = ROOM_WIDTH - 40.0
const CEILING := Rect2(0.0, 0.0, ROOM_WIDTH, 32.0)

## The bat over the second crossing: roaming its middle at body height, never
## reaching back over the island, so the island stays somewhere to stand.
const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(812.0, FLOOR_TOP - 24.0)
const BAT_HALF_EXTENTS := Vector2(56.0, 20.0)


static func banks() -> Array[Rect2]:
	return [
		Rect2(0.0, FLOOR_TOP, FIRST_BANK_END, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(ISLAND_START, FLOOR_TOP, ISLAND_END - ISLAND_START, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(LAST_BANK_START, FLOOR_TOP, ROOM_WIDTH - LAST_BANK_START, ROOM_HEIGHT - FLOOR_TOP),
	]


func _ready() -> void:
	super._ready()
	for child in get_children():
		var slab := child as FallingPlatform
		if slab != null:
			slab.art = SLAB_ART
	_add_solid(CEILING)
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, CEILING, TILES)
	for bank in banks():
		TileArt.draw_ground(self, bank, TILES)
