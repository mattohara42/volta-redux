## Act 3, room 6: live rungs, and the first barrier. **A sword in live copper
## is live, and a sword left behind a barrier is a sword you recall before you
## cross.**
##
## Two tiers, each faced with copper in two pieces: the lower piece is live
## and crackles, the upper is dead. The obvious throw, from where you stand,
## lands in the live piece, and a rung there kills you when you step on it. A
## crate puts the throw into the dead piece. At the top a bridge runs over a
## barrier (`Barrier`) and drops to the way out, a wooden climb that needs two
## swords. Recall from the bridge and the swords fly up to you over the field;
## recall from the floor beyond and they cross it and are lost.
class_name Act3Rungs
extends Act3Room

const ROOM_WIDTH: float = 1100.0
## Each tier is too tall to jump, from the floor or from its crate.
const TIER: float = 90.0
const LOW_TOP: float = FLOOR_TOP - TIER
const HIGH_TOP: float = LOW_TOP - TIER

const LOW_FACE_X: float = 400.0
const HIGH_FACE_X: float = 560.0
const CRATE_LOW := Rect2(300.0, FLOOR_TOP - 32.0, 40.0, 32.0)
const CRATE_HIGH := Rect2(460.0, LOW_TOP - 32.0, 40.0, 32.0)

## The bridge over the barrier, level with the high tier.
const BRIDGE_END: float = 860.0
const BRIDGE_THICKNESS: float = 16.0
const BARRIER := Rect2(820.0, HIGH_TOP + BRIDGE_THICKNESS, 6.0, FLOOR_TOP - HIGH_TOP - BRIDGE_THICKNESS)

## The way out: two wooden steps, each one sword.
const STEP_LOW := Rect2(980.0, FLOOR_TOP - 64.0, ROOM_WIDTH - 980.0, 64.0)
const STEP_HIGH := Rect2(1040.0, FLOOR_TOP - 128.0, ROOM_WIDTH - 1040.0, 64.0)
const WOOD_FACE: float = 12.0

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const EXIT_X: float = ROOM_WIDTH - 20.0


## Where the seam splitting a tier's face sits: just below the throw from its
## crate, so the crate's throw lands in the dead piece and the floor's in the
## live one.
static func seam(tier_floor: float) -> float:
	return tier_floor - 36.0


## A tier's copper, dead above its seam and live below.
static func dead_piece(face_x: float, top: float, tier_floor: float) -> Rect2:
	return Rect2(face_x, top, COPPER_WIDTH, seam(tier_floor) - top)


static func live_piece(face_x: float, tier_floor: float) -> Rect2:
	var top := seam(tier_floor) + SEAM_HEIGHT
	return Rect2(face_x, top, COPPER_WIDTH, tier_floor - top)


static func pieces() -> Array[Rect2]:
	return [
		dead_piece(LOW_FACE_X, LOW_TOP, FLOOR_TOP),
		live_piece(LOW_FACE_X, FLOOR_TOP),
		dead_piece(HIGH_FACE_X, HIGH_TOP, LOW_TOP),
		live_piece(HIGH_FACE_X, LOW_TOP),
	]


static func woods() -> Array[Rect2]:
	return [
		Rect2(STEP_LOW.position, Vector2(WOOD_FACE, STEP_LOW.size.y)),
		Rect2(STEP_HIGH.position, Vector2(WOOD_FACE, STEP_HIGH.size.y)),
	]


static func grounds() -> Array[Rect2]:
	var low_back := LOW_FACE_X + COPPER_WIDTH
	var high_back := HIGH_FACE_X + COPPER_WIDTH
	return [
		Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP),
		CRATE_LOW,
		CRATE_HIGH,
		Rect2(low_back, LOW_TOP, 640.0 - low_back, FLOOR_TOP - LOW_TOP),
		Rect2(high_back, HIGH_TOP, 640.0 - high_back, LOW_TOP - HIGH_TOP),
		Rect2(640.0, HIGH_TOP, BRIDGE_END - 640.0, BRIDGE_THICKNESS),
		Rect2(STEP_LOW.position.x + WOOD_FACE, STEP_LOW.position.y, STEP_LOW.size.x - WOOD_FACE, STEP_LOW.size.y),
		Rect2(STEP_HIGH.position.x + WOOD_FACE, STEP_HIGH.position.y, STEP_HIGH.size.x - WOOD_FACE, STEP_HIGH.size.y),
	]


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	for wood in woods():
		_add_wood(wood, false)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	var network := _add_network()
	var all := pieces()
	for i in all.size():
		# The live pieces are the odd ones: each is fed from behind the wall.
		_add_conductor(network, all[i], i % 2 == 1, COPPER)
	_add_barrier(BARRIER)
	# Down off the bridge is a drop no jump climbs back.
	_add_way_back(BRIDGE_END, HIGH_TOP)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_exit(Rect2(EXIT_X, STEP_HIGH.position.y - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
	for wood in woods():
		TileArt.draw_wood(self, wood)
	_draw_ways_back()
	_draw_seam(LOW_FACE_X, seam(FLOOR_TOP), COPPER_WIDTH)
	_draw_seam(HIGH_FACE_X, seam(LOW_TOP), COPPER_WIDTH)
