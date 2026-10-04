## Act 4, room 2: the guard. **The second gem is carried by a scorpion.**
##
## A low passage, roofed too low to jump, with a scorpion patrolling it and a
## gem riding on its back. Its armour still faces the way it walks, so a
## throw has to find its back, or come from the step at the passage mouth,
## which is high enough that a standing throw lands in the top of its body
## and kills it whichever way it faces (`Act1Wall`'s lesson). Killed, it
## drops the gem where it fell.
class_name Act4Guard
extends Act4Room

const ROOM_WIDTH: float = 1100.0
## The step at the passage mouth: 5 to 16 px is the band where a standing
## throw meets the top of a scorpion (`Act1Wall.STEP_DROP`).
const STEP_DROP: float = 12.0
const STEP_END: float = 400.0
const UPPER_TOP: float = FLOOR_TOP - STEP_DROP
const TUNNEL_CLEARANCE: float = 56.0
const PASSAGE := Rect2(440.0, 0.0, 480.0, FLOOR_TOP - TUNNEL_CLEARANCE)

const SCORPION_SIZE := Vector2(30.0, 34.0)
## The near end of its walk (`Scorpion`: a room places it at one end and it
## walks `GUARD_RANGE` toward the other), inside throwing range of the step.
const GUARD_HOME_X: float = 500.0
const GUARD_RANGE: float = 340.0

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 120.0
const EXIT_X: float = ROOM_WIDTH - 40.0


static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, STEP_END, ROOM_HEIGHT - UPPER_TOP),
		Rect2(STEP_END, FLOOR_TOP, ROOM_WIDTH - STEP_END, ROOM_HEIGHT - FLOOR_TOP),
	]


func _ready() -> void:
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT))
	_add_solid(PASSAGE)
	var guard := _add_scorpion(
		Rect2(GUARD_HOME_X - SCORPION_SIZE.x * 0.5, FLOOR_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y),
		GUARD_RANGE
	)
	var mark := CarriedGem.new()
	mark.position = Vector2(0.0, -SCORPION_SIZE.y * 0.5 - Gem.SIZE.y * 0.5)
	guard.add_child(mark)
	guard.defeated.connect(_drop_gem)
	_add_brazier(Vector2(START_BRAZIER_X, UPPER_TOP))
	_add_chest(Vector2(CHEST_X, UPPER_TOP))
	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _drop_gem(at: Vector2) -> void:
	_add_gem.call_deferred(Vector2(at.x, FLOOR_TOP))


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH, TILES)
	TileArt.draw_wall(self, Rect2(0.0, 0.0, ROOM_WIDTH, CEILING_HEIGHT), TILES)
	TileArt.draw_wall(self, PASSAGE, TILES)
	for ground in grounds():
		TileArt.draw_ground(self, ground, TILES)
