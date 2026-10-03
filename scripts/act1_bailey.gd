## Act 1, room 3: the bailey. **It teaches what wood does to a sword**, and it is
## where the caged creature is first glimpsed (`LEVELS.md`, *Left to work out
## at M10*: chains and a shape in the dark, never the whole dragon).
##
## Three beats, left to right:
##
##   1. **Two hurdles.** A wooden block and a stone one, both low enough to jump.
##      Throw at the wood and the sword sticks, and holding J brings it home.
##      Throw at the stone and the sword is gone. The chest by the way in makes
##      that a lesson rather than a loss.
##   2. **The grate.** Behind the hurdles, a barred window in the back wall with
##      chains running down into the dark, and something in there that blinks.
##      Scenery: it changes nothing about play.
##   3. **The yard.** A drop into a yard closed by a portcullis. The gold switch
##      is set into the wall you just dropped from, at throw height: turn round,
##      throw, and the gate rises while the sword holds it. A ladder goes back up.
##
## Built like the other Act 1 rooms: `Bench` geometry drawn with `TileArt`.
class_name Act1Bailey
extends Bench

const ROOM_WIDTH: float = 1280.0

## The upper level you arrive on, and the drop into the yard. The face is tall
## enough to set a switch into its foot.
const UPPER_TOP: float = FLOOR_TOP - 64.0
const YARD_X: float = 760.0

const START_BRAZIER_X: float = 48.0
const CHEST_X: float = 96.0

## Both low enough to jump (`movement.jump_height`), both tall enough to catch a
## standing throw. The tests hold both.
const WOOD_BLOCK := Rect2(280.0, UPPER_TOP - 32.0, 24.0, 32.0)
const STONE_BLOCK := Rect2(440.0, UPPER_TOP - 48.0, 24.0, 48.0)

## The barred window behind the hurdles: the dragon's first appearance.
const GRATE := Rect2(520.0, 120.0, 176.0, 104.0)
const GRATE_CHAINS: Array[float] = [560.0, 652.0]
## Where its eyes are in the dark, and how they blink. Purely how it looks.
const EYES_AT := Vector2(612.0, 196.0)
const EYE_GAP: float = 10.0
const BLINK_PERIOD: float = 3.4
const BLINK_OPEN: float = 2.6
## The bars and chains, dimmed well under the playfield: this is background,
## and backgrounds lose (`ART_DIRECTION.md`). The eyes alone are not dimmed.
const GRATE_SHADE := Color(0.42, 0.40, 0.52)

## The switch, set into the foot of the drop's face at throw height, facing the
## yard. The face above it is stone.
const SWITCH := Rect2(YARD_X - 24.0, FLOOR_TOP - 40.0, 24.0, 40.0)
const LADDER_X: float = YARD_X
const YARD_CHEST_X: float = 840.0

## The portcullis, too tall to jump, with stone over it to the ceiling.
const GATE := Rect2(920.0, FLOOR_TOP - 120.0, 32.0, 120.0)

const EXIT_X: float = ROOM_WIDTH - 56.0

var _clock := 0.0


## The solids, as the ground `TileArt` draws.
static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, UPPER_TOP, YARD_X, SWITCH.position.y - UPPER_TOP),
		Rect2(0.0, SWITCH.position.y, SWITCH.position.x, ROOM_HEIGHT - SWITCH.position.y),
		Rect2(YARD_X, FLOOR_TOP, ROOM_WIDTH - YARD_X, ROOM_HEIGHT - FLOOR_TOP),
	]


static func gate_wall() -> Rect2:
	return Rect2(GATE.position.x, 0.0, GATE.size.x, GATE.position.y)


func _ready() -> void:
	# The grate's bars repeat down the window.
	texture_repeat = TEXTURE_REPEAT_ENABLED
	for ground in grounds():
		_add_solid(ground)
	_add_solid(gate_wall())
	_add_wood(WOOD_BLOCK, false)
	_add_solid(STONE_BLOCK)
	_add_ladder(LADDER_X, UPPER_TOP, FLOOR_TOP)

	_add_brazier(Vector2(START_BRAZIER_X, UPPER_TOP))
	_add_chest(Vector2(CHEST_X, UPPER_TOP))
	_add_chest(Vector2(YARD_CHEST_X, FLOOR_TOP))

	# The room wires its own switch to its own gate, as M2's switch room does.
	var switch := _add_switch(SWITCH)
	var gate := _add_gate(GATE)
	gate.art = TileArt.PORTCULLIS_TILE
	switch.held_changed.connect(gate.set_open)

	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _process(delta: float) -> void:
	_clock = fmod(_clock + delta, BLINK_PERIOD)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH)
	_draw_grate()
	# Drawn as the two levels they are, not the collision pieces: the upper
	# level's face runs unbroken down to the yard, with the switch set into it.
	TileArt.draw_ground(self, Rect2(0.0, UPPER_TOP, YARD_X, ROOM_HEIGHT - UPPER_TOP))
	TileArt.draw_ground(self, grounds()[2])
	TileArt.draw_wall(self, gate_wall())
	TileArt.draw_wood(self, WOOD_BLOCK)
	TileArt.draw_ground(self, STONE_BLOCK)
	TileArt.draw_ladder(self, _ladders[0])


## The window into the dark: a recess darker than the wall, chains hanging into
## it, a pair of eyes that open and close, and the portcullis bars in front.
## Backgrounds lose (`ART_DIRECTION.md`), so all of it sits under the playfield.
func _draw_grate() -> void:
	draw_rect(GRATE, Palette.BACKDROP)
	var dim := GRATE_SHADE
	for x in GRATE_CHAINS:
		TileArt.draw_chain(self, x, GRATE.position.y, GRATE.end.y, dim)
	if _clock < BLINK_OPEN:
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(EYES_AT + Vector2(side * EYE_GAP * 0.5 - 2.0, -1.0), Vector2(4.0, 2.0)), Palette.FIRE_CORE)
	draw_texture_rect(TileArt.PORTCULLIS_TILE, GRATE, true, dim)
