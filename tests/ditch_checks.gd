## The checks every sword-step ditch has to pass, shared by the rooms built on
## one: `Act1Wall`'s ditch, `RoomM2Gap` and `RoomM2Switch`. Not a test file itself (no
## `test_` prefix); each room's test calls `run` with its own numbers.
##
## The claim is that the ditch **cannot be crossed without standing on your own
## sword**: the far side is out of a jump's reach, and a sword thrown into the
## wooden face under it is a step you can reach from the lip and climb off with
## nothing overhead. The first version of this crossing checked horizontal reach
## only, and a post in the gap blocked the way on from the ledge for weeks
## (`BACKLOG.md`). Every number here comes from `config/`.
class_name DitchChecks
extends RefCounted

const MOVE := "res://config/movement.tres"
const WORLD := "res://config/world.tres"
const SWORD := "res://config/sword.tres"


static func run(
	case: TestCase, name: String, near_edge: float, near_top: float,
	far_top: float, hoarding: Rect2, pit_top: float
) -> void:
	var move: MovementConfig = load(MOVE)
	var world: WorldConfig = load(WORLD)
	var sword: SwordConfig = load(SWORD)
	var lip := near_edge - world.hero_width * 0.5
	var throw_y := near_top - world.hero_height * 0.5
	var ledge := SwordFlight.embed_position(hoarding.position.x, 1.0, world.sword_length)
	var ledge_top := throw_y - Sword.LEDGE_THICKNESS * 0.5
	var reach := Motion.jump_reach(
		move.jump_height, move.time_to_apex, move.fall_gravity_multiplier,
		move.max_run_speed, near_top - ledge_top
	)

	case.check(near_top - far_top > move.jump_height, "%s: the far side is out of a jump's reach" % name)
	case.check(throw_y > hoarding.position.y and throw_y < hoarding.end.y, "%s: a throw from the lip meets the wood" % name)
	case.check(hoarding.position.x - lip < sword.max_range, "%s: and the wood is in range" % name)
	case.check(
		ledge - lip <= reach,
		"%s: lip to ledge is %.0f px against a %.0f px jump" % [name, ledge - lip, reach]
	)
	case.check(
		ledge_top - far_top < move.jump_height,
		"%s: the ledge is %.0f px under the far side, inside a jump" % [name, ledge_top - far_top]
	)
	case.check_eq(hoarding.position.y, far_top, "%s: the wood runs up to the far side's top, nothing overhangs the ledge" % name)
	case.check(pit_top - near_top < move.jump_height, "%s: falling in is a retry" % name)
	case.check(pit_top - far_top > move.jump_height, "%s: and not a way round" % name)
