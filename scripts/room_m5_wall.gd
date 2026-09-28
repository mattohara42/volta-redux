## M5's room: the moat and the outer wall, `ART.md`'s spike prompts as one
## assembled scene rather than five separate verification scenes.
##
## `BUILD_PLAN.md`'s M5 done-when is "that room is in the game, at final
## quality," and `ART.md` flagged what was still missing to reach it: nothing
## placed the background, the tileset as walkable platforms, the hero and the
## bat together. This is that placement. It is still a `Bench`, not one of
## `BUILD_PLAN.md` M10's authored rooms: the floor and the ledge are the same
## generated `Rect2` geometry every Phase 1 bench used, now carrying real art
## instead of a grey rectangle.
class_name RoomM5Wall
extends Bench

const ROOM_WIDTH: float = 640.0

const START_BRAZIER_X: float = 40.0

## The pixel-art tiles (`ART.md`, Four layers), drawn at 1x. The floor tile's
## top row is its walkable lip, so it is drawn with that row on the floor line.
## Each ground tile comes in variants from `tools/tile-variants.py`, scattered
## by `TileVariety` so a wall is not wallpaper.
const FLOOR_TILES: Array[Texture2D] = [
	preload("res://assets/art/act1/tiles_px/floor_top_0.png"),
	preload("res://assets/art/act1/tiles_px/floor_top_1.png"),
	preload("res://assets/art/act1/tiles_px/floor_top_2.png"),
	preload("res://assets/art/act1/tiles_px/floor_top_3.png"),
]
const WALL_TILES: Array[Texture2D] = [
	preload("res://assets/art/act1/tiles_px/wall_fill_0.png"),
	preload("res://assets/art/act1/tiles_px/wall_fill_1.png"),
	preload("res://assets/art/act1/tiles_px/wall_fill_2.png"),
	preload("res://assets/art/act1/tiles_px/wall_fill_3.png"),
	preload("res://assets/art/act1/tiles_px/wall_fill_4.png"),
	preload("res://assets/art/act1/tiles_px/wall_fill_5.png"),
]
const LADDER_TILES: Array[Texture2D] = [preload("res://assets/art/act1/tiles_px/ladder.png")]
const UNSHADED: Array[Color] = [Color.WHITE]

## The ledge above the floor, one tier up, reached by the ladder. A whole
## number of floor tiles wide, so its art ends on a tile edge.
const LEDGE_X_START: float = 360.0
const LEDGE_TILE_COUNT: int = 13
const LADDER_X: float = 340.0

## Atmosphere only, not the player's path (`ART.md`): the painted wall
## pixelated to the room's own height by `tools/pixelate.py`.
const BG_TEXTURE: Texture2D = preload("res://assets/art/act1/wall_moat_bg_px.png")

const BAT_SIZE := Vector2(20.0, 14.0)
const BAT_CENTRE := Vector2(240.0, FLOOR_TOP - 90.0)
const BAT_HALF_EXTENTS := Vector2(80.0, 50.0)

## Set once in `_ready`, from `world.tier_height` rather than a literal, so a
## retuned storey height moves the ledge and the ladder together with it.
var _ledge_top: float = 0.0
var _ledge_width: float = 0.0


func _ready() -> void:
	_ledge_top = FLOOR_TOP - world.tier_height
	_ledge_width = LEDGE_TILE_COUNT * FLOOR_TILES[0].get_width()
	_add_solid(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_add_solid(Rect2(LEDGE_X_START, _ledge_top, _ledge_width, FLOOR_TOP - _ledge_top))
	_add_ladder(LADDER_X, _ledge_top, FLOOR_TOP)
	_add_brazier(Vector2(START_BRAZIER_X, FLOOR_TOP))
	_add_bat(Rect2(BAT_CENTRE - BAT_SIZE * 0.5, BAT_SIZE), BAT_HALF_EXTENTS)
	_add_enclosure(ROOM_WIDTH)
	_frame_camera(ROOM_WIDTH)
	queue_redraw()


func _draw() -> void:
	draw_texture(BG_TEXTURE, Vector2.ZERO)
	_draw_tiled(LADDER_TILES, Rect2(
		LADDER_X, _ledge_top - LADDER_OVERSHOOT, LADDER_WIDTH, FLOOR_TOP - _ledge_top + LADDER_OVERSHOOT
	), UNSHADED)
	_draw_ground(Rect2(0.0, FLOOR_TOP, ROOM_WIDTH, ROOM_HEIGHT - FLOOR_TOP))
	_draw_ground(Rect2(LEDGE_X_START, _ledge_top, _ledge_width, FLOOR_TOP - _ledge_top))
	_draw_ruler()


## A strip of floor tiles along the top edge of `rect`, masonry below it,
## stepping darker row by row the way shadow falls under a ledge.
func _draw_ground(rect: Rect2) -> void:
	var lip := FLOOR_TILES[0].get_height()
	_draw_tiled(FLOOR_TILES, Rect2(rect.position, Vector2(rect.size.x, lip)), UNSHADED)
	_draw_tiled(
		WALL_TILES, Rect2(rect.position + Vector2(0.0, lip), rect.size - Vector2(0.0, lip)),
		Palette.GROUND_SHADE
	)


## Repeats `textures` from `rect`'s top-left corner, a variant per cell by
## `TileVariety`, cutting the last column and row short so nothing is drawn
## outside `rect`. Row `n` down is multiplied by `shades[n]`, the last
## repeating.
func _draw_tiled(textures: Array[Texture2D], rect: Rect2, shades: Array[Color]) -> void:
	var tile := textures[0].get_size()
	var row := 0
	var y := 0.0
	while y < rect.size.y:
		var shade := shades[mini(row, shades.size() - 1)]
		var x := 0.0
		while x < rect.size.x:
			var at := rect.position + Vector2(x, y)
			var cell := Vector2i(floori(at.x / tile.x), floori(at.y / tile.y))
			var part := Vector2(minf(tile.x, rect.size.x - x), minf(tile.y, rect.size.y - y))
			draw_texture_rect_region(
				textures[TileVariety.pick(cell, textures.size())],
				Rect2(at, part), Rect2(Vector2.ZERO, part), shade
			)
			x += tile.x
		y += tile.y
		row += 1
