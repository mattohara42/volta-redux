## Act 1, room 2: the outer wall. **It teaches the scorpion's from-above trick**
## (`HANDOFF.md`, `LEVELS.md` → *The outer castle*), the one room 1 is held to
## not teaching.
##
## Three beats, left to right:
##
##   1. **The climb.** A storey of wall too tall to jump (`world.tier_height`),
##      a ladder up its face and a bat working the air around it. A bat dies to
##      a throw, and the ladder is where you cannot throw, so the order is yours.
##   2. **The gatehouse.** The wall walk steps down into a passage with a
##      scorpion patrolling it, roofed too low to jump it, like room 1's tunnels.
##      The step is the lesson: standing on its edge, a throw lands in the top
##      of the scorpion's body, which kills it whichever way it faces. A level
##      throw from the passage floor still has to find its back.
##   3. **The breach.** Past a checkpoint the walk is broken over a spike pit,
##      bridged by slabs that give way under you. Keep moving.
##
## Built like `Act1Bank`: `Bench` geometry drawn with `TileArt`.
class_name Act1Wall
extends Bench

const ROOM_WIDTH: float = 1600.0

const START_BRAZIER_X: float = 48.0

## The outer wall's first storey. Its top is one tier above the ground, so it
## is climbed and never jumped; the test holds this to `world.tier_height`.
const WALL_X: float = 256.0
const WALK_TOP: float = 224.0
const LADDER_X: float = WALL_X - Bench.LADDER_WIDTH

const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(176.0, 220.0)
const BAT_HALF_EXTENTS := Vector2(72.0, 44.0)

## The step down from the wall walk. Between 5 and 16 px is the band where a
## standing throw meets the top of a scorpion rather than its face.
const STEP_X: float = 576.0
const STEP_DROP: float = 12.0
const LOWER_TOP: float = WALK_TOP + STEP_DROP

## The gatehouse passage, roofed like room 1's tunnels.
const TUNNEL_CLEARANCE: float = 56.0
const PASSAGE := Rect2(608.0, 0.0, 272.0, LOWER_TOP - TUNNEL_CLEARANCE)

const SCORPION_SIZE := Vector2(30.0, 34.0)
const GUARD_HOME_X: float = 648.0
const GUARD_RANGE: float = 180.0

const CHECKPOINT_X: float = 920.0

## The breach: the walk is gone from here to `BREACH_END`, with spikes on the
## ground below and slabs that fall bridging it.
const BREACH_X: float = 1024.0
const BREACH_END: float = 1360.0
const SLAB_WIDTH: float = 48.0
const SLABS: Array[float] = [1064.0, 1152.0, 1240.0]

const TORCHES: Array[float] = [336.0, 496.0, 960.0, 1440.0]
const TORCH_HEIGHT: float = 26.0

const EXIT_X: float = ROOM_WIDTH - 56.0

const CRUMBLE_ART: Texture2D = preload("res://assets/art/act1/tiles_px/crumble.png")


## Every solid in the room, left to right, each as the ground `TileArt` draws.
static func grounds() -> Array[Rect2]:
	return [
		Rect2(0.0, FLOOR_TOP, WALL_X, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(WALL_X, WALK_TOP, STEP_X - WALL_X, ROOM_HEIGHT - WALK_TOP),
		Rect2(STEP_X, LOWER_TOP, BREACH_X - STEP_X, ROOM_HEIGHT - LOWER_TOP),
		Rect2(BREACH_X, FLOOR_TOP, BREACH_END - BREACH_X, ROOM_HEIGHT - FLOOR_TOP),
		Rect2(BREACH_END, LOWER_TOP, ROOM_WIDTH - BREACH_END, ROOM_HEIGHT - LOWER_TOP),
	]


## The slab a falling platform starts as, its top level with the walk.
static func slab(x: float) -> Rect2:
	return Rect2(x, LOWER_TOP, SLAB_WIDTH, CRUMBLE_ART.get_height())


func _ready() -> void:
	for ground in grounds():
		_add_solid(ground)
	_add_solid(PASSAGE)
	_add_ladder(LADDER_X, WALK_TOP, FLOOR_TOP)

	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_brazier(Vector2(CHECKPOINT_X, LOWER_TOP))
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_scorpion(
		Rect2(GUARD_HOME_X - SCORPION_SIZE.x * 0.5, LOWER_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y),
		GUARD_RANGE
	)

	_add_spikes(FLOOR_TOP, BREACH_X, int((BREACH_END - BREACH_X) / hazards.spike_tooth_pitch))
	for x in SLABS:
		var platform := _add_falling_platform(slab(x))
		if platform != null:
			platform.art = CRUMBLE_ART

	for x in TORCHES:
		var torch := WallTorch.new()
		# Bracketed to the wall at about head height, above the battlements.
		torch.position = Vector2(x, _surface_at(x) - TORCH_HEIGHT)
		add_child(torch)
		move_child(torch, 0)

	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


## The walking surface at `x`, for placing scenery on it.
static func _surface_at(x: float) -> float:
	for ground in grounds():
		if x >= ground.position.x and x < ground.end.x:
			return ground.position.y
	return FLOOR_TOP


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH)
	# Battlements stand behind every stretch of wall walk open to the sky.
	TileArt.draw_battlements(self, WALL_X, WALK_TOP, STEP_X - WALL_X)
	TileArt.draw_battlements(self, STEP_X, LOWER_TOP, PASSAGE.position.x - STEP_X)
	TileArt.draw_battlements(self, PASSAGE.end.x, LOWER_TOP, BREACH_X - PASSAGE.end.x)
	TileArt.draw_battlements(self, BREACH_END, LOWER_TOP, ROOM_WIDTH - BREACH_END)
	TileArt.draw_wall(self, PASSAGE)
	for ground in grounds():
		TileArt.draw_ground(self, ground)
	for bed in _spike_beds:
		TileArt.draw_spikes(self, bed)
	TileArt.draw_ladder(self, _ladders[0])
	# The way on, until rooms are sequenced by act state. Gold means interactive.
	draw_rect(Rect2(EXIT_X, LOWER_TOP - 48.0, 8.0, 48.0), Palette.GOLD_FACE)
