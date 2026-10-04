## Act 4, room 1: the gallery. **The first gem is cut down, not climbed to.**
##
## The gem sits on a little wooden shelf hung by a chain from the ceiling, too
## high to reach from the floor. A crate and one sword in the gallery's wooden
## face take you up a storey, and from the gallery a throw flies at the
## shelf's height: it knocks the shelf away, flies on, and comes home. The gem
## drops to the floor.
class_name Act4Gallery
extends Act4Room

const ROOM_WIDTH: float = 1000.0
const CRATE := Rect2(330.0, FLOOR_TOP - 40.0, 40.0, 40.0)
## The gallery, a storey up, faced with wood toward the crate.
const GALLERY := Rect2(400.0, FLOOR_TOP - 100.0, 160.0, 100.0)
const WOOD_FACE: float = 12.0
## The shelf, at the height a throw from the gallery flies.
const SHELF := Rect2(700.0, FLOOR_TOP - 100.0 - 18.0 - 6.0, 14.0, 12.0)

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const EXIT_X: float = ROOM_WIDTH - 40.0


static func wood() -> Rect2:
	return Rect2(GALLERY.position, Vector2(WOOD_FACE, GALLERY.size.y))


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP),
		CRATE,
		Rect2(GALLERY.position.x + WOOD_FACE, GALLERY.position.y, GALLERY.size.x - WOOD_FACE, GALLERY.size.y),
	]


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_wood(wood(), false)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	var shelf := GemShelf.new()
	add_child(shelf)
	shelf.configure(SHELF, FLOOR_TOP, CEILING_HEIGHT)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
	TileArt.draw_wood(self, wood())
