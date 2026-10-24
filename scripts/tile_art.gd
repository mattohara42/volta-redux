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
## The castle yard: siege gear and stores standing on the floor, behind
## everything you touch, by `[decor]` kind.
const YARD := {
	"trebuchet": [preload("res://assets/art/act1/yard/trebuchet.png")],
	"ballista": [preload("res://assets/art/act1/yard/ballista.png")],
	"cart": [preload("res://assets/art/act1/yard/cart.png")],
	"barrels": [preload("res://assets/art/act1/yard/barrels.png")],
	"crates": [preload("res://assets/art/act1/yard/crates.png")],
	"rack": [preload("res://assets/art/act1/yard/rack.png")],
	"shot": [preload("res://assets/art/act1/yard/shot.png")],
	"rubble": [preload("res://assets/art/act1/yard/rubble.png")],
	"sacks": [preload("res://assets/art/act1/yard/sacks.png")],
}
## The forest kit: what is set into a bank of earth, and what stands on the
## grass, by `[decor]` kind.
const FOREST_KIT := {
	"boulder": [preload("res://assets/art/forest/kit/boulder.png")],
	"stones": [preload("res://assets/art/forest/kit/stones.png")],
	"skull": [preload("res://assets/art/forest/kit/skull.png")],
	"strata": [preload("res://assets/art/forest/kit/strata.png")],
	"standing_stone": [preload("res://assets/art/forest/kit/standing_stone.png")],
	"fern": [preload("res://assets/art/forest/kit/fern.png")],
	"toadstools": [preload("res://assets/art/forest/kit/toadstools.png")],
	"log": [preload("res://assets/art/forest/trees/pale_log.png")],
}
## The forest's trees (Matt, 2026-10-24): a trunk stood on its foot, sections
## stacked up to its crown, leaves round the crown; and the greenery the
## rules place, all behind everything you touch. Fronds are the one thing
## drawn in front of the hero (`draw_fronds`).
const TRUNK: Texture2D = preload("res://assets/art/forest/trees/trunk.png")
const TRUNK_BASE: Texture2D = preload("res://assets/art/forest/trees/trunk_base.png")
const TRUNK_CROWN: Texture2D = preload("res://assets/art/forest/trees/trunk_crown.png")
const LEAVES: Array[Texture2D] = [preload("res://assets/art/forest/trees/leaves_big.png")]
const LEAVES_SMALL: Array[Texture2D] = [preload("res://assets/art/forest/trees/leaves_small.png")]
const BUSH: Array[Texture2D] = [preload("res://assets/art/forest/trees/bush.png")]
const MOSS: Array[Texture2D] = [
	preload("res://assets/art/forest/trees/moss.png"), preload("res://assets/art/forest/trees/ivy_curtain.png")
]
const FRONDS: Array[Texture2D] = [
	preload("res://assets/art/forest/trees/fern_spray.png"), preload("res://assets/art/forest/trees/bush.png")
]
## A bough, by its length in cells (`tools/bough.py`): solid bark drawn as a
## branch, its thick end at the trunk, its twigs past the solid end. The
## band you stand on starts one cell down the texture.
const BOUGHS := {
	6: preload("res://assets/art/forest/trees/bough_6.png"),
	7: preload("res://assets/art/forest/trees/bough_7.png"),
	8: preload("res://assets/art/forest/trees/bough_8.png"),
	9: preload("res://assets/art/forest/trees/bough_9.png"),
	10: preload("res://assets/art/forest/trees/bough_10.png"),
}
## How many rows a bough is, the band each texture is warped to.
const BOUGH_ROWS := 2
## Where a crown's clumps of leaves sit, from the middle of its top, art px,
## and whether each is a big clump (1) or a small one (0). Wide, so a crown
## reads as a great oak's canopy and not a tuft on a pole (Matt, 2026-10-24).
const CANOPY: Array[Vector3] = [
	Vector3(-120, 34, 0), Vector3(122, 30, 0), Vector3(-92, 18, 1), Vector3(94, 14, 1),
	Vector3(-46, 2, 1), Vector3(46, -2, 1), Vector3(-20, -22, 1), Vector3(24, -24, 1),
	Vector3(0, -38, 0), Vector3(-70, -10, 0), Vector3(72, -14, 0),
]
## One clump in this many of a crown is left out, picked per tree.
const CANOPY_GAPS := 5
## The pale tree (the second trees sheet): taller and twisted, ash-pale bark,
## a willow's drooping leaves hanging round two limbs.
const PALE_CANOPY: Array[Vector3] = [
	Vector3(-96, 40, 0), Vector3(98, 36, 0), Vector3(-70, 24, 1), Vector3(72, 20, 1),
	Vector3(-36, 10, 1), Vector3(38, 6, 1), Vector3(0, -6, 1), Vector3(-16, 30, 0),
	Vector3(20, 34, 0), Vector3(-50, -2, 0), Vector3(54, -6, 0),
]
## Each kind of tree, by its `[decor]` foot and crown: the oak (`y`, `k`) and
## the pale tree (`Y`, `K`). Placed by hand, never by rule.
static var TREE_KINDS: Array[Dictionary] = [
	{
		"foot": "tree", "crown": "crown", "base": TRUNK_BASE, "sections": [TRUNK],
		"crown_texture": TRUNK_CROWN, "crown_sink": 0, "canopy": CANOPY,
		"leaves": LEAVES[0], "leaves_small": LEAVES_SMALL[0],
	},
	{
		"foot": "pale_tree", "crown": "pale_crown", "base": preload("res://assets/art/forest/trees/pale_base.png"),
		"sections": [preload("res://assets/art/forest/trees/pale_trunk.png"), preload("res://assets/art/forest/trees/pale_trunk_hole.png")],
		"crown_texture": preload("res://assets/art/forest/trees/pale_crown.png"), "crown_sink": 2, "canopy": PALE_CANOPY,
		"leaves": preload("res://assets/art/forest/trees/willow_big.png"),
		"leaves_small": preload("res://assets/art/forest/trees/willow_small.png"),
	},
]
## Where a bough's leaves sit: from the tip of its texture, art px, along the
## bough and up, big then small.
const BOUGH_LEAVES: Array[Vector2] = [Vector2(-14, -2), Vector2(-40, -14)]
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
	var drawn_as_boughs := bough_cells(level)
	for y in level.rows.size():
		var row := level.rows[y]
		for x in row.length():
			var sides := TileShape.open_sides(level.rows, x, y)
			if sides == 0 or drawn_as_boughs.has(Vector2i(x, y)):
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
	_draw_kit(canvas, level, KIT, false, Palette.KIT_SHADE)
	_draw_kit(canvas, level, YARD, false, Color.WHITE)
	# Standing on the grass, unshaded as the tufts are: the forest's art is
	# darker than the castle's, and shaded it went to grey shapes.
	_draw_kit(canvas, level, FOREST_KIT, false, Color.WHITE)
	for at in level.decor_cells("ivy"):
		_draw_prop(canvas, IVY, at, Vector2((at.x + 0.5) * cell, at.y * cell), false, Palette.GROUND_SHADE[1])


## The level's trees and the greenery round them, behind everything else: a
## tree's foot (`[decor]` `y`) stands on the ground, and its trunk rises to
## the crown (`k`) above it in the same column.
static func draw_trees(canvas: CanvasItem, level: LevelGrid.Level) -> void:
	var cell := level.cell
	for kind: Dictionary in TREE_KINDS:
		var crowns := level.decor_cells(kind["crown"])
		for foot in level.decor_cells(kind["foot"]):
			var crown := Vector2i(-1, -1)
			for c in crowns:
				if c.x == foot.x and c.y < foot.y and c.y > crown.y:
					crown = c
			if crown.y >= 0:
				_draw_tree(canvas, kind, foot, crown, cell)
	for at in level.decor_cells("leaves"):
		_draw_centred(canvas, LEAVES, at, cell)
	for at in level.decor_cells("leaves_small"):
		_draw_centred(canvas, LEAVES_SMALL, at, cell)
	for at in level.decor_cells("bush"):
		_draw_prop(canvas, BUSH, at, Vector2((at.x + 0.5) * cell, (at.y + 1) * cell + TUFT_SINK), true)
	for at in level.decor_cells("moss"):
		_draw_prop(canvas, MOSS, at, Vector2((at.x + 0.5) * cell, at.y * cell), false)


## Each bough in the level: the solid it covers, by its `[decor]` anchor (`<`
## grows left from its trunk, `>` right) along the run of bark in that
## direction, `BOUGH_ROWS` rows deep. A bough is drawn as a branch rather
## than as a bar of bark (Matt, 2026-10-24).
static func boughs(level: LevelGrid.Level) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for kind in ["bough_left", "bough_right"]:
		var step := -1 if kind == "bough_left" else 1
		for at in level.decor_cells(kind):
			var length := 0
			var x := at.x
			while x >= 0 and x < level.rows[at.y].length() and level.rows[at.y][x] == "%":
				length += 1
				x += step
			found.append({"anchor": at, "step": step, "length": length})
	return found


## Every cell a bough covers, so the bark and its edges are left out there.
static func bough_cells(level: LevelGrid.Level) -> Dictionary:
	var cells := {}
	for b in boughs(level):
		var at: Vector2i = b["anchor"]
		for i in int(b["length"]):
			for r in BOUGH_ROWS:
				cells[Vector2i(at.x + i * int(b["step"]), at.y + r)] = true
	return cells


## The level's boughs, drawn with its stone. A bough with no art of its
## length is left as bark (`test_level_bake.gd` holds every one to having it).
static func draw_boughs(canvas: CanvasItem, level: LevelGrid.Level) -> void:
	var cell := level.cell
	for b in boughs(level):
		var texture: Texture2D = BOUGHS.get(int(b["length"]))
		if texture == null:
			continue
		var at: Vector2i = b["anchor"]
		var top := (at.y - 1) * cell
		var step := int(b["step"])
		if step > 0:
			canvas.draw_texture(texture, Vector2(at.x * cell, top))
		else:
			canvas.draw_set_transform(Vector2((at.x + 1) * cell, top), 0.0, Vector2(-1.0, 1.0))
			canvas.draw_texture(texture, Vector2.ZERO)
			canvas.draw_set_transform(Vector2.ZERO)
		# Leaves at its tip, so the whole tree is in leaf and not only its crown.
		var root := at.x * cell if step > 0 else (at.x + 1) * cell
		var tip := Vector2(root + step * texture.get_width(), top + cell)
		for i in BOUGH_LEAVES.size():
			var leaves: Texture2D = LEAVES[0] if i == 0 else LEAVES_SMALL[0]
			var offset := Vector2(BOUGH_LEAVES[i].x * step, BOUGH_LEAVES[i].y)
			canvas.draw_texture(leaves, (tip + offset - leaves.get_size() * 0.5).round())


## One tree of `kind` (`TREE_KINDS`): its foot on the ground, its trunk up to
## the crown cell, its crown and leaves above. About half are drawn mirrored
## and each crown leaves out a clump or two of its own, so a stand of them is
## not one tree cloned; trunk sections alternate upside down so a join is an
## edge meeting itself, and a kind with more than one section picks per tree.
static func _draw_tree(canvas: CanvasItem, kind: Dictionary, foot: Vector2i, crown: Vector2i, cell: float) -> void:
	var base: Texture2D = kind["base"]
	var crown_texture: Texture2D = kind["crown_texture"]
	var sections: Array = kind["sections"]
	var middle := (foot.x + 0.5) * cell
	var ground := (foot.y + 1) * cell
	var top := (crown.y + 1) * cell
	var facing := -1.0 if TileVariety.pick(foot, 2) == 1 else 1.0
	canvas.draw_set_transform(Vector2(middle, 0.0), 0.0, Vector2(facing, 1.0))
	var y := ground - base.get_height()
	canvas.draw_texture(base, Vector2(roundf(-base.get_width() * 0.5), y))
	var flipped := false
	var n := 0
	while y > top:
		var section: Texture2D = sections[TileVariety.pick(foot + Vector2i(0, n), sections.size())] if n % 3 == 1 else sections[0]
		var size := section.get_size()
		var part := minf(size.y, y - top)
		var region := Rect2(0.0, 0.0 if flipped else size.y - part, size.x, part)
		var at := Rect2(roundf(-size.x * 0.5), y - part, size.x, part)
		if flipped:
			canvas.draw_set_transform(Vector2(middle, at.position.y * 2.0 + part), 0.0, Vector2(facing, -1.0))
		canvas.draw_texture_rect_region(section, at, region)
		canvas.draw_set_transform(Vector2(middle, 0.0), 0.0, Vector2(facing, 1.0))
		y -= part
		flipped = not flipped
		n += 1
	var crown_top := top - crown_texture.get_height() + int(kind["crown_sink"])
	canvas.draw_texture(crown_texture, Vector2(roundf(-crown_texture.get_width() * 0.5), crown_top))
	var canopy: Array = kind["canopy"]
	var big: Texture2D = kind["leaves"]
	var small: Texture2D = kind["leaves_small"]
	for i in canopy.size():
		var clump: Vector3 = canopy[i]
		if TileVariety.pick(foot + Vector2i(i, 0), CANOPY_GAPS) == 0:
			continue
		var texture := big if clump.z > 0 else small
		canvas.draw_texture(texture, (Vector2(clump.x, crown_top + clump.y) - texture.get_size() * 0.5).round())
	canvas.draw_set_transform(Vector2.ZERO)


## The fronds in front of the hero, sunk into the lip they grow from.
static func draw_fronds(canvas: CanvasItem, level: LevelGrid.Level) -> void:
	for at in level.decor_cells("frond"):
		_draw_prop(canvas, FRONDS, at, Vector2((at.x + 0.5) * level.cell, (at.y + 1) * level.cell + TUFT_SINK), true)


static func _draw_centred(canvas: CanvasItem, textures: Array[Texture2D], at: Vector2i, cell: float) -> void:
	var texture := textures[TileVariety.pick(at, textures.size())]
	canvas.draw_texture(texture, ((Vector2(at) + Vector2(0.5, 0.5)) * cell - texture.get_size() * 0.5).round())


## The kit's features set into the face of the level's stone, drawn with the
## stone (before its interiors fall into the dark), so they take the same
## shade, weather and dark as the masonry around them.
static func draw_kit_in_stone(canvas: CanvasItem, level: LevelGrid.Level) -> void:
	_draw_kit(canvas, level, KIT, true, Palette.GROUND_SHADE[Palette.GROUND_SHADE.size() - 1])
	# Earth is darker than masonry, so what is buried in it is left as drawn.
	_draw_kit(canvas, level, FOREST_KIT, true, Color.WHITE)


## Each of `kit`'s features anchored in stone (`in_stone`) or in air,
## standing on its anchor cell.
static func _draw_kit(canvas: CanvasItem, level: LevelGrid.Level, kit: Dictionary, in_stone: bool, shade: Color) -> void:
	var cell := level.cell
	for kind: String in kit:
		var pieces: Array[Texture2D] = []
		pieces.assign(kit[kind])
		for at in level.decor_cells(kind):
			if TileShape.is_solid(level.rows, at.x, at.y) != in_stone:
				continue
			_draw_prop(canvas, pieces, at, Vector2((at.x + 0.5) * cell, (at.y + 1) * cell), true, shade)


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
