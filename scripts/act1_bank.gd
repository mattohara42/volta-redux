## Act 1, room 1: the moat bank. **It teaches throw and catch without a word of
## text** (`BUILD_PLAN.md` M10), using only mechanisms Phase 1 already built.
##
## Three beats, left to right:
##
##   1. **The bank.** A brazier, open ground and a plinth. Nothing here can hurt
##      you, so pressing buttons is free: a throw flies out, turns, and comes
##      back to where you are now, and standing still catches it.
##   2. **The culvert.** A tunnel under the outer wall, too low to jump inside,
##      with a scorpion asleep in it facing away. The only way through is a
##      sword in its back. Walk up and it wakes and walks off, back still turned,
##      so the throw is still there to find; wait too long and it comes back
##      armour first, which is `SPEC.md`'s scorpion lesson arriving on its own.
##      The mouth is outside its patrol, so there is always somewhere to stand.
##   3. **The sally port.** A second tunnel after a checkpoint, with a scorpion
##      awake and patrolling. The same lesson, now with timing: throw when its
##      back is turned. A throw that misses comes home, which is the catch.
##
## Every floor in a scorpion's line is flat on purpose. A throw from a step 5 to
## 16 px higher lands in the top of its body, which counts as "from above" and
## kills it head on (`ScorpionPatrol.is_vulnerable_to`). That is a later room's
## trick, and `tests/test_act1_bank.gd` holds this room to not teaching it yet.
##
## Built on `Bench`'s geometry and `TileArt`'s Act 1 tiles rather than a Godot
## TileMap: see `Bench`'s class comment.
class_name Act1Bank
extends Bench

const ROOM_WIDTH: float = 1280.0

const START_BRAZIER_X: float = 48.0
## A plinth on the bank: jump furniture (`SPEC.md`, "the jump owns a scale"),
## lower than a jump and far enough back that a throw from its top turns for
## home before it reaches the culvert's face.
const PLINTH := Rect2(160.0, FLOOR_TOP - 32.0, 48.0, 32.0)

## The culvert. Its ceiling leaves `TUNNEL_CLEARANCE` px of headroom: room to
## stand, and too little to jump a scorpion.
const TUNNEL_CLEARANCE: float = 56.0
const CULVERT := Rect2(440.0, 0.0, 280.0, FLOOR_TOP - TUNNEL_CLEARANCE)

const SCORPION_SIZE := Vector2(30.0, 34.0)
## Its patrol runs right from here, so while it sleeps it faces away from the
## hero walking in from the left.
const SLEEPER_HOME_X: float = 480.0
const SLEEPER_RANGE: float = 180.0

const CHECKPOINT_X: float = 760.0

## A drainage channel between the tunnels. Jump furniture, and a retry rather
## than a trap: shallower than a jump.
const DITCH := Rect2(816.0, FLOOR_TOP, 48.0, 24.0)

const SALLY_PORT := Rect2(912.0, 0.0, 256.0, FLOOR_TOP - TUNNEL_CLEARANCE)
const GUARD_HOME_X: float = 952.0
const GUARD_RANGE: float = 176.0

const EXIT_X: float = ROOM_WIDTH - 56.0
## A chest of swords by the way in, so whatever the last room cost you is
## made up before this one asks for anything.
const CHEST_X: float = 96.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, DITCH.position.x, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(DITCH.position.x, DITCH.end.y, DITCH.size.x, ROOM_HEIGHT - DITCH.end.y))
	_add_solid(Rect2(DITCH.end.x, FLOOR_TOP, ROOM_WIDTH - DITCH.end.x, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(PLINTH)
	_add_solid(CULVERT)
	_add_solid(SALLY_PORT)

	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_brazier(Vector2(CHECKPOINT_X, FLOOR_TOP))

	var sleeper := _add_scorpion(_scorpion_box(SLEEPER_HOME_X), SLEEPER_RANGE)
	sleeper.start_dormant()
	_add_scorpion(_scorpion_box(GUARD_HOME_X), GUARD_RANGE)

	_add_exit(Rect2(EXIT_X, FLOOR_TOP - 48.0, 8.0, 48.0))
	_add_chest(Vector2(CHEST_X, FLOOR_TOP))
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


static func _scorpion_box(home_x: float) -> Rect2:
	return Rect2(
		home_x - SCORPION_SIZE.x * 0.5, FLOOR_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y
	)


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH)
	TileArt.draw_wall(self, CULVERT)
	TileArt.draw_wall(self, SALLY_PORT)
	TileArt.draw_ground(self, Rect2(0.0, FLOOR_TOP, DITCH.position.x, ROOM_HEIGHT - FLOOR_TOP))
	TileArt.draw_ground(self, Rect2(DITCH.position.x, DITCH.end.y, DITCH.size.x, ROOM_HEIGHT - DITCH.end.y))
	TileArt.draw_ground(self, Rect2(DITCH.end.x, FLOOR_TOP, ROOM_WIDTH - DITCH.end.x, ROOM_HEIGHT - FLOOR_TOP))
	TileArt.draw_ground(self, PLINTH)
