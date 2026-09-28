## Act 1's pixel-art ground and background (`ART.md`, Four layers), drawn at 1x
## by whichever room needs a floor. Static and stateless: a room passes its own
## canvas in, and the calls only work inside that canvas's `_draw`.
##
## Each ground tile comes in variants from `tools/tile-variants.py`, scattered by
## `TileVariety` so a wall is not wallpaper, and the masonry steps darker below a
## walkable lip (`Palette.GROUND_SHADE`).
class_name TileArt

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

## Atmosphere only, not the player's path: the painted wall pixelated to a 640x360
## room by `tools/pixelate.py`.
const BACKGROUND: Texture2D = preload("res://assets/art/act1/wall_moat_bg_px.png")


## One floor tile's width, the unit a ledge's length is counted in so its art
## ends on a tile edge.
static func tile_width() -> float:
	return FLOOR_TILES[0].get_width()


static func draw_background(canvas: CanvasItem) -> void:
	canvas.draw_texture(BACKGROUND, Vector2.ZERO)


## A strip of floor tiles along the top edge of `rect`, masonry below it,
## stepping darker row by row the way shadow falls under a ledge.
static func draw_ground(canvas: CanvasItem, rect: Rect2) -> void:
	var lip := FLOOR_TILES[0].get_height()
	draw_tiled(canvas, FLOOR_TILES, Rect2(rect.position, Vector2(rect.size.x, lip)), UNSHADED)
	draw_tiled(
		canvas, WALL_TILES, Rect2(rect.position + Vector2(0.0, lip), rect.size - Vector2(0.0, lip)),
		Palette.GROUND_SHADE
	)


static func draw_ladder(canvas: CanvasItem, rect: Rect2) -> void:
	draw_tiled(canvas, LADDER_TILES, rect, UNSHADED)


## Repeats `textures` from `rect`'s top-left corner, a variant per cell by
## `TileVariety`, cutting the last column and row short so nothing is drawn
## outside `rect`. Row `n` down is multiplied by `shades[n]`, the last
## repeating.
static func draw_tiled(
	canvas: CanvasItem, textures: Array[Texture2D], rect: Rect2, shades: Array[Color]
) -> void:
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
			canvas.draw_texture_rect_region(
				textures[TileVariety.pick(cell, textures.size())],
				Rect2(at, part), Rect2(Vector2.ZERO, part), shade
			)
			x += tile.x
		y += tile.y
		row += 1
