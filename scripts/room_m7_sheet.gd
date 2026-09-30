## M7's enemy sheet: every enemy that has art, on one screen at game size beside
## the hero, each running its M4 behaviour.
##
## `BUILD_PLAN.md`'s M7 done-when is that they are on screen, distinguishable at
## game size and consistent in treatment. This is the instrument for judging
## that, so the layout is a lineup and not a fight: a bench, like the M4 rooms,
## not one of M10's authored rooms. The generator, the sixth, is M12's boss and
## has no behaviour to run yet, so it stands here as its sprite alone.
class_name RoomM7Sheet
extends Bench

const ROOM_WIDTH: float = 760.0

const START_BRAZIER_X: float = 40.0

const SCORPION_SIZE := Vector2(30.0, 34.0)
const SCORPION_HOME_X: float = 110.0
const SCORPION_RANGE: float = 80.0

## Its floor leg is the real floor, as in M4, so the loop is where it walks.
const ANT_SIZE := Vector2(22.0, 16.0)
const ANT_TRACK := Rect2(250.0, FLOOR_TOP - 130.0, 70.0, 130.0)

const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(390.0, FLOOR_TOP - 110.0)
const BAT_HALF_EXTENTS := Vector2(40.0, 40.0)

const EYEBALL_SIZE := Vector2(24.0, 24.0)
const EYEBALL_START := Vector2(470.0, FLOOR_TOP - 70.0)
const EYEBALL_ROAM := Rect2(430.0, FLOOR_TOP - 150.0, 60.0, 150.0)

const DRAGON_SIZE := Vector2(56.0, 48.0)
const DRAGON_X: float = 590.0
const BREATH_OFFSET := Vector2(-90.0, 10.0)
const BREATH_SIZE := Vector2(60.0, 30.0)

const GENERATOR_SCENE: PackedScene = preload("res://scenes/generator_sprite.tscn")
const GENERATOR_X: float = 700.0


func _ready() -> void:
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_scorpion(
		Rect2(SCORPION_HOME_X - SCORPION_SIZE.x * 0.5, FLOOR_TOP - SCORPION_SIZE.y, SCORPION_SIZE.x, SCORPION_SIZE.y),
		SCORPION_RANGE
	)
	_add_ant(ANT_SIZE, ANT_TRACK)
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_eyeball(Rect2(EYEBALL_START - EYEBALL_SIZE * 0.5, EYEBALL_SIZE), EYEBALL_ROAM)
	_add_dragon(
		Rect2(DRAGON_X - DRAGON_SIZE.x * 0.5, FLOOR_TOP - DRAGON_SIZE.y, DRAGON_SIZE.x, DRAGON_SIZE.y),
		BREATH_OFFSET, BREATH_SIZE
	)
	var generator := GENERATOR_SCENE.instantiate() as Node2D
	generator.position = Vector2(GENERATOR_X, FLOOR_TOP)
	add_child(generator)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	TileArt.draw_background_across(self, ROOM_WIDTH)
	TileArt.draw_ground(self, Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
