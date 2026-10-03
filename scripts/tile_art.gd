## Act 1's pixel-art ground and background (`ART.md`, Four layers), drawn at 1x
## by whichever room needs a floor. Static and stateless: a room passes its own
## canvas in, and the calls only work inside that canvas's `_draw`.
##
## Each ground tile comes in variants from `tools/tile-variants.py`, scattered by
## `TileVariety` so a wall is not wallpaper, and the masonry steps darker below a
## walkable lip (`Palette.GROUND_SHADE`).
class_name TileArt

## The castle, which every room draws unless it passes another act's set.
const ACT1: ActTiles = preload("res://assets/art/act1/act1_tiles.tres")
const LADDER_TILES: Array[Texture2D] = [preload("res://assets/art/act1/tiles_px/ladder.png")]
## The outer wall's crenellations: a merlon and a gap per tile, standing behind
## a wall walk. Scenery, not geometry: nothing stands on it.
const BATTLEMENT_TILES: Array[Texture2D] = [
	preload("res://assets/art/act1/tiles_px/battlement.png")
]
## Two teeth per tile. Warm and saturated, because it kills (`ART_DIRECTION.md`).
const SPIKE_TILES: Array[Texture2D] = [preload("res://assets/art/act1/tiles_px/spikes.png")]
## Planks a sword bites into. Warm umber, so wood reads as wood from across the
## room (`ART_DIRECTION.md`).
const WOOD_TILES: Array[Texture2D] = [preload("res://assets/art/act1/tiles_px/wood.png")]
## The portcullis a `Gate` draws, repeating top to bottom.
const PORTCULLIS_TILE: Texture2D = preload("res://assets/art/act1/tiles_px/portcullis.png")
## Heavy chain, repeating top to bottom, and the ring it hangs from.
const CHAIN_TILES: Array[Texture2D] = [preload("res://assets/art/act1/tiles_px/chain.png")]
const SHACKLE: Texture2D = preload("res://assets/art/act1/props/shackle.png")
## A cracked slab, cropped to the stone so its top row is the surface you land on.
const CRUMBLE_TILE: Texture2D = preload("res://assets/art/act1/tiles_px/crumble.png")
const UNSHADED: Array[Color] = [Color.WHITE]

## One floor tile's width, the unit a ledge's length is counted in so its art
## ends on a tile edge.
static func tile_width() -> float:
	return ACT1.floor_tiles[0].get_width()


static func draw_background(canvas: CanvasItem) -> void:
	canvas.draw_texture(ACT1.background, Vector2.ZERO)


## The painted wall repeated across a room wider than one screen. Every other
## copy is mirrored, so the seam between two copies is the same edge meeting
## itself rather than one edge meeting the other.
static func draw_background_across(canvas: CanvasItem, width: float, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	if set.background == null:
		# Not painted yet: the plain backdrop, which the light layer still falls on.
		canvas.draw_rect(Rect2(0.0, 0.0, width, Bench.ROOM_HEIGHT), Palette.BACKDROP)
		return
	var bg := set.background
	var step := float(bg.get_width())
	var x := 0.0
	var mirrored := false
	while x < width:
		if mirrored:
			canvas.draw_set_transform(Vector2(x + step, 0.0), 0.0, Vector2(-1.0, 1.0))
		else:
			canvas.draw_set_transform(Vector2(x, 0.0))
		canvas.draw_texture(bg, Vector2.ZERO)
		x += step
		mirrored = not mirrored
	canvas.draw_set_transform(Vector2.ZERO)


## A strip of floor tiles along the top edge of `rect`, masonry below it,
## stepping darker row by row the way shadow falls under a ledge.
static func draw_ground(canvas: CanvasItem, rect: Rect2, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	var lip := set.floor_tiles[0].get_height()
	draw_tiled(canvas, set.floor_tiles, Rect2(rect.position, Vector2(rect.size.x, lip)), UNSHADED)
	draw_tiled(
		canvas, set.wall_tiles, Rect2(rect.position + Vector2(0.0, lip), rect.size - Vector2(0.0, lip)),
		Palette.GROUND_SHADE
	)


## Masonry with no walkable lip, for the face of a wall that comes down from
## above: stone you cannot stand on should not show the top that says you can.
## It is lit from below, where the braziers and the hero are, and falls into
## the dark going up, so a wall a screen tall does not outshine the floor.
static func draw_wall(canvas: CanvasItem, rect: Rect2, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	var rows := ceili(rect.size.y / set.wall_tiles[0].get_height())
	var lit := Palette.GROUND_SHADE[Palette.GROUND_SHADE.size() - 1]
	var shades: Array[Color] = []
	for row in rows:
		var t := float(row) / float(maxi(rows - 1, 1))
		shades.append(Palette.WALL_DARK.lerp(lit, t * t * t))
	draw_tiled(canvas, set.wall_tiles, rect, shades)
	# A lintel along the bottom: the floor's own lip, upside down, so the edge
	# you walk under is finished the way the edge you walk on is.
	var lip := set.floor_tiles[0].get_height()
	canvas.draw_set_transform(Vector2(0.0, rect.end.y * 2.0 - lip), 0.0, Vector2(1.0, -1.0))
	draw_tiled(
		canvas, set.floor_tiles, Rect2(rect.position.x, rect.end.y - lip, rect.size.x, lip),
		[Palette.GROUND_SHADE[1]]
	)
	canvas.draw_set_transform(Vector2.ZERO)


static func draw_ladder(canvas: CanvasItem, rect: Rect2) -> void:
	draw_tiled(canvas, LADDER_TILES, rect, UNSHADED)


static func draw_wood(canvas: CanvasItem, rect: Rect2) -> void:
	draw_tiled(canvas, WOOD_TILES, rect, UNSHADED)


## A chain hanging from a shackle at `top`, down to `bottom`, centred on `x`.
## `shade` dims it for a chain seen in the dark, behind the room.
static func draw_chain(canvas: CanvasItem, x: float, top: float, bottom: float, shade: Color) -> void:
	var width := CHAIN_TILES[0].get_width()
	var ring := SHACKLE.get_height()
	canvas.draw_texture(SHACKLE, Vector2(x - SHACKLE.get_width() * 0.5, top), shade)
	draw_tiled(canvas, CHAIN_TILES, Rect2(x - width * 0.5, top + ring, width, bottom - top - ring), [shade])


## A row of battlements standing on a wall walk whose surface is `walk_y`, from
## `x` for `width`. Shaded like the masonry under a lip, so it sits behind the
## hero and reads as wall rather than as something to stand on.
static func draw_battlements(canvas: CanvasItem, x: float, walk_y: float, width: float) -> void:
	var height := BATTLEMENT_TILES[0].get_height()
	draw_tiled(
		canvas, BATTLEMENT_TILES, Rect2(x, walk_y - height, width, height),
		[Palette.GROUND_SHADE[1]]
	)


## A spike bed's teeth over `bed`, the drawn rectangle `Bench._add_spikes` keeps.
## The tile is drawn standing on the bed's floor, so it may stand a little proud
## of the lethal box, never short of it.
static func draw_spikes(canvas: CanvasItem, bed: Rect2) -> void:
	var height := SPIKE_TILES[0].get_height()
	draw_tiled(
		canvas, SPIKE_TILES, Rect2(bed.position.x, bed.end.y - height, bed.size.x, height), UNSHADED
	)


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


static func _or_act1(tiles: ActTiles) -> ActTiles:
	return tiles if tiles != null else ACT1
