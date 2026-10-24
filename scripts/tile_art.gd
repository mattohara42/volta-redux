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
## The foreground kit (`ART.md`): features set into a back wall, each by its
## `[decor]` kind, and ivy hanging from a ceiling. A kind with two pieces
## takes one a cell (`TileVariety`).
const KIT := {
	"slit": [preload("res://assets/art/act1/kit/slit.png")],
	"niche": [preload("res://assets/art/act1/kit/niche.png")],
	"pier": [preload("res://assets/art/act1/kit/pier.png")],
	"drain": [preload("res://assets/art/act1/kit/drain.png")],
	"breach": [preload("res://assets/art/act1/kit/breach_0.png"), preload("res://assets/art/act1/kit/breach_1.png")],
	"ring": [preload("res://assets/art/act1/kit/ring.png")],
	"footing": [preload("res://assets/art/act1/kit/footing.png")],
	"banner": [preload("res://assets/art/act1/kit/banner.png")],
}
const IVY: Array[Texture2D] = [preload("res://assets/art/act1/kit/ivy.png")]
const UNSHADED: Array[Color] = [Color.WHITE]
## How far down its tile the forest lip's grass starts: a tuft roots there,
## in the grass, rather than standing on the tile's empty top rows.
const TUFT_SINK: float = 3.0

## One floor tile's width, the unit a ledge's length is counted in so its art
## ends on a tile edge.
static func tile_width() -> float:
	return ACT1.floor_tiles[0].get_width()


static func draw_background(canvas: CanvasItem) -> void:
	canvas.draw_texture(ACT1.background, Vector2.ZERO)


## The painted wall repeated across a room wider than one screen, and down one
## taller than a screen. Every other copy is mirrored, so the seam between two
## copies is the same edge meeting itself rather than one edge meeting the
## other. Down a tall room that is a stopgap: a level five floors tall wants a
## painting of its own (`BACKLOG.md`).
static func draw_background_across(canvas: CanvasItem, width: float, tiles: ActTiles = null, height: float = 0.0) -> void:
	var set := _or_act1(tiles)
	if set.background == null:
		# Not painted yet: nothing here, so the act's `Backdrop` shows through
		# from under the room, or the project's clear colour (`Palette.BACKDROP`)
		# where there is none.
		return
	var bg := set.background
	var step := float(bg.get_width())
	var rise := float(bg.get_height())
	var y := 0.0
	var flipped := false
	while y < maxf(height, 1.0):
		var x := 0.0
		var mirrored := false
		while x < width:
			var at := Vector2(x + (step if mirrored else 0.0), y + (rise if flipped else 0.0))
			canvas.draw_set_transform(at, 0.0, Vector2(-1.0 if mirrored else 1.0, -1.0 if flipped else 1.0))
			canvas.draw_texture(bg, Vector2.ZERO)
			x += step
			mirrored = not mirrored
		y += rise
		flipped = not flipped
	canvas.draw_set_transform(Vector2.ZERO)


## Every lit point of `tiles`' painting across a room `width` wide, copy by
## copy, mirrored the way `draw_background_across` mirrors every other copy.
static func painted_lights(width: float, tiles: ActTiles = null, height: float = 0.0) -> PackedVector2Array:
	var set := _or_act1(tiles)
	var out := PackedVector2Array()
	if set.background == null:
		return out
	var step := float(set.background.get_width())
	var rise := float(set.background.get_height())
	var y := 0.0
	var flipped := false
	while y < maxf(height, 1.0):
		var x := 0.0
		var mirrored := false
		while x < width:
			for point in set.lights:
				out.append(Vector2(
					x + (step - point.x if mirrored else point.x),
					y + (rise - point.y if flipped else point.y)
				))
			x += step
			mirrored = not mirrored
		y += rise
		flipped = not flipped
	return out


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
	var faces := set.face_tiles if not set.face_tiles.is_empty() else set.wall_tiles
	var rows := ceili(rect.size.y / faces[0].get_height())
	var lit := Palette.GROUND_SHADE[Palette.GROUND_SHADE.size() - 1]
	var shades: Array[Color] = []
	for row in rows:
		var t := float(row) / float(maxi(rows - 1, 1))
		shades.append(Palette.WALL_DARK.lerp(lit, t * t * t))
	draw_tiled(canvas, faces, rect, shades)
	draw_lintel(canvas, Rect2(rect.position.x, rect.end.y, rect.size.x, 0.0), tiles)


## A lintel along the bottom of `rect` (its height is ignored): the floor's own
## lip, upside down, so the edge you walk under is finished the way the edge
## you walk on is. Only where the lip is masonry: the forest's is moss, and
## moss does not hang under a trunk.
static func draw_lintel(canvas: CanvasItem, rect: Rect2, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	if not set.lintel:
		return
	var lip := set.floor_tiles[0].get_height()
	canvas.draw_set_transform(Vector2(0.0, rect.end.y * 2.0 - lip), 0.0, Vector2(1.0, -1.0))
	draw_tiled(
		canvas, set.floor_tiles, Rect2(rect.position.x, rect.end.y - lip, rect.size.x, lip),
		[Palette.GROUND_SHADE[1]]
	)
	canvas.draw_set_transform(Vector2.ZERO)


static func draw_ladder(canvas: CanvasItem, rect: Rect2, tiles: ActTiles = null) -> void:
	draw_tiled(canvas, _slot(tiles, "climb_tiles", LADDER_TILES), rect, UNSHADED)


## Wood's grain runs along it, so a post or a trunk taller than it is wide is
## drawn turned a quarter, rather than as a stack of short planks.
static func draw_wood(canvas: CanvasItem, rect: Rect2, tiles: ActTiles = null) -> void:
	var textures := _slot(tiles, "wood_tiles", WOOD_TILES)
	if rect.size.y <= rect.size.x:
		draw_tiled(canvas, textures, rect, UNSHADED)
		return
	# Turned a quarter clockwise, (u, v) lands at (-v, u): this rect, in the
	# turned frame, covers `rect` exactly.
	canvas.draw_set_transform(Vector2.ZERO, PI * 0.5)
	draw_tiled(
		canvas, textures, Rect2(rect.position.y, -rect.end.x, rect.size.y, rect.size.x), UNSHADED
	)
	canvas.draw_set_transform(Vector2.ZERO)


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
static func draw_spikes(canvas: CanvasItem, bed: Rect2, tiles: ActTiles = null) -> void:
	var textures := _slot(tiles, "hazard_tiles", SPIKE_TILES)
	var height := textures[0].get_height()
	draw_tiled(
		canvas, textures, Rect2(bed.position.x, bed.end.y - height, bed.size.x, height), UNSHADED
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


## A level's back wall (`[back]`): the set's own fill, face and wood, shaded
## to stand behind everything that can be touched.
static func draw_back(canvas: CanvasItem, level: LevelGrid.Level, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	var faces := set.face_tiles if not set.face_tiles.is_empty() else set.wall_tiles
	var shade: Array[Color] = [Palette.BACK_SHADE]
	for rect in level.back_rects("#"):
		draw_tiled(canvas, set.wall_tiles, rect, shade)
	for rect in level.back_rects("%"):
		draw_tiled(canvas, faces, rect, shade)
	for rect in level.back_rects("w"):
		draw_tiled(canvas, _slot(tiles, "wood_tiles", WOOD_TILES), rect, shade)
	# Its sides in the set's edge, so a trunk or a wall behind ends in a line
	# as the stone in front does.
	for c in LevelGrid.BACK:
		for rect in level.back_rects(c):
			canvas.draw_rect(Rect2(rect.position, Vector2(1.0, rect.size.y)), set.edge_dark)
			canvas.draw_rect(Rect2(rect.end.x - 1.0, rect.position.y, 1.0, rect.size.y), set.edge_dark)


## A line of the set's edge dark along every open side of the level's stone
## (`TileShape`), so a block ends in an outline rather than in a cut through
## its masonry. A ground cell's top is its lip and keeps it. Castle stone
## (`&`) takes the castle's edge, whatever the level's set.
static func draw_edges(canvas: CanvasItem, level: LevelGrid.Level, tiles: ActTiles = null) -> void:
	var set := _or_act1(tiles)
	var cell := level.cell
	# Ground you walk under ends in a lintel, as a wall face does.
	for y in level.rows.size():
		var x := 0
		var row := level.rows[y]
		while x < row.length():
			if row[x] != "#" or not TileShape.open_sides(level.rows, x, y) & TileShape.DOWN:
				x += 1
				continue
			var start := x
			while x < row.length() and row[x] == "#" and TileShape.open_sides(level.rows, x, y) & TileShape.DOWN:
				x += 1
			draw_lintel(canvas, Rect2(start * cell, y * cell, (x - start) * cell, cell), tiles)
	for y in level.rows.size():
		var row := level.rows[y]
		for x in row.length():
			var sides := TileShape.open_sides(level.rows, x, y)
			if sides == 0:
				continue
			var edge := ACT1.edge_dark if row[x] == "&" else set.edge_dark
			var at := Vector2(x, y) * cell
			if sides & TileShape.LEFT:
				canvas.draw_rect(Rect2(at, Vector2(1.0, cell)), edge)
			if sides & TileShape.RIGHT:
				canvas.draw_rect(Rect2(at + Vector2(cell - 1.0, 0.0), Vector2(1.0, cell)), edge)
			if sides & TileShape.DOWN:
				canvas.draw_rect(Rect2(at + Vector2(0.0, cell - 1.0), Vector2(cell, 1.0)), edge)
			if sides & TileShape.UP and row[x] != "#":
				canvas.draw_rect(Rect2(at, Vector2(cell, 1.0)), edge)


## The level's `[decor]` that holds still (`DecorRules`): battlements on a
## wall walk, chains from a ceiling, tufts on grass, roots under earth, the
## foreground kit's wall features and ivy. A
## torch flickers, so it is a `WallTorch` the room adds, not drawn here. A
## decoration whose art the set does not have is left out rather than drawn
## as something else.
static func draw_decor(canvas: CanvasItem, level: LevelGrid.Level, tiles: ActTiles = null) -> void:
	var cell := level.cell
	for at in level.decor_cells("battlement"):
		draw_battlements(canvas, at.x * cell, (at.y + 1) * cell, cell)
	var chains := level.decor_cells("chain")
	for at in chains:
		if chains.has(at - Vector2i(0, 1)):
			continue
		var length := 1
		while chains.has(at + Vector2i(0, length)):
			length += 1
		draw_chain(canvas, (at.x + 0.5) * cell, at.y * cell, (at.y + length) * cell, Palette.GROUND_SHADE[1])
	var set := _or_act1(tiles)
	for at in level.decor_cells("tuft"):
		_draw_prop(canvas, set.tuft_tiles, at, Vector2((at.x + 0.5) * cell, (at.y + 1) * cell + TUFT_SINK), true)
	for at in level.decor_cells("root"):
		_draw_prop(canvas, set.root_tiles, at, Vector2((at.x + 0.5) * cell, at.y * cell), false)
	# Set into the back wall, so shaded with it: the art's own big stones are
	# what stand out from the brick, not a brightness the wall does not have.
	for kind: String in KIT:
		var pieces: Array[Texture2D] = []
		pieces.assign(KIT[kind])
		for at in level.decor_cells(kind):
			_draw_prop(canvas, pieces, at, Vector2((at.x + 0.5) * cell, (at.y + 1) * cell), true, Palette.KIT_SHADE)
	for at in level.decor_cells("ivy"):
		_draw_prop(canvas, IVY, at, Vector2((at.x + 0.5) * cell, at.y * cell), false, Palette.GROUND_SHADE[1])


## One of `textures`, picked for the cell, centred on `anchor`: standing on it,
## or hanging from it, multiplied by `shade`.
static func _draw_prop(canvas: CanvasItem, textures: Array[Texture2D], cell: Vector2i, anchor: Vector2, stands: bool, shade := Color.WHITE) -> void:
	if textures.is_empty():
		return
	var texture := textures[TileVariety.pick(cell, textures.size())]
	var size := texture.get_size()
	var top := anchor.y - size.y if stands else anchor.y
	canvas.draw_texture(texture, Vector2(roundf(anchor.x - size.x * 0.5), top), shade)


## How dark each cell of the level's stone goes, one texel a cell: its colour
## the dark it falls into (the castle's for castle stone, the set's for the
## rest), its alpha how far (`shaders/ground_shade.gdshader` steps it).
static func shade_field(level: LevelGrid.Level, config: AtmosphereConfig, tiles: ActTiles = null) -> ImageTexture:
	var own := _or_act1(tiles).interior_dark
	var width := level.rows[0].length()
	var height := level.rows.size()
	var depths := TileShape.depths(level.rows)
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var t := clampf((depths[y * width + x] - config.ground_shade_from) / config.ground_shade_span, 0.0, 1.0)
			var dark := ACT1.interior_dark if level.rows[y][x] == "&" else own
			image.set_pixel(x, y, Color(dark, t * config.ground_shade_most))
	return ImageTexture.create_from_image(image)


static func _or_act1(tiles: ActTiles) -> ActTiles:
	return tiles if tiles != null else ACT1


## One of a set's optional slots (`ActTiles`), or the castle's art when the set
## leaves it empty or there is no set.
static func _slot(tiles: ActTiles, slot: StringName, castle: Array[Texture2D]) -> Array[Texture2D]:
	if tiles == null:
		return castle
	var own: Array[Texture2D] = tiles.get(slot)
	return own if not own.is_empty() else castle
