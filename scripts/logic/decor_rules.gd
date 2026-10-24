## Where decoration goes, by rule (N2; Matt, 2026-10-07: "decoration placed by
## rules is allowed, written into the level file so it can be reviewed").
## Reads a level and returns its `[decor]` grid, which `tools/dev.sh
## decorate` writes into the file. An authoring tool, run once and then
## edited by hand like any other part of the file; the game only ever reads
## what the file says. Pure, and the same level always gives the same grid.
##
## Two styles, one per set of art:
##
##   castle   battlements along a wall walk that stands over a drop, out in
##            the open rather than before a back wall; torches
##            on a back wall at head height, spaced along the floor; chains
##            hanging from a high ceiling; a wall feature (an arrow slit, a
##            niche, a pier, a breach) in the bays of a back wall between
##            the torches; ivy hanging from a ceiling
##   forest   tufts on the grass; roots hanging under earth
##
## Decoration only ever goes in air the map leaves empty, so it never covers
## a ladder, a marker or a mechanism, and changes nothing that plays. A
## creature's box is air it moves through, so it counts as air: a parapet does
## not stop where a bat flies.
class_name DecorRules
extends RefCounted

const STYLES: PackedStringArray = ["castle", "forest"]

## A drop is a wall when it falls at least this many cells.
const WALL_DROP := 3
## Torches are this many cells apart along a floor, at most.
const TORCH_PITCH := 10
## And keep this far from a brazier or a ladder, which light and fill the
## space already.
const TORCH_CLEAR := 3
## A chain hangs only where the ceiling is at least this high, and is this
## long, and one hangs in this many cells along a ceiling.
const CHAIN_HEADROOM := 6
const CHAIN_LENGTH := 2
const CHAIN_ONE_IN := 9
## One tuft in this many grass cells; one root in this many cells of earth
## underside.
const TUFT_ONE_IN := 3
const ROOT_ONE_IN := 2
## Wall features (the foreground kit, `ART.md`): at most one in this many
## cells along a floor, and none within this many cells of a torch, a
## ladder or a brazier, which fill the wall already.
const FEATURE_PITCH := 6
const FEATURE_CLEAR := 2
## The kinds, in the order a bay tries them from wherever its hash starts.
const FEATURES: PackedStringArray = ["niche", "slit", "pier", "breach", "ring", "drain", "banner", "footing"]
## Each one's footprint in cells: how far it reaches either side of its
## anchor, how many rows tall it is, and how far above the floor its bottom
## row, the anchor, sits. Its art fits inside (`test_decor_rules.gd`).
const FOOTPRINTS := {
	"niche": Vector3i(1, 3, 0), "pier": Vector3i(0, 3, 0), "footing": Vector3i(1, 2, 0),
	"slit": Vector3i(1, 3, 1), "breach": Vector3i(1, 3, 1), "ring": Vector3i(1, 3, 1),
	"drain": Vector3i(1, 3, 1), "banner": Vector3i(1, 3, 1), "ivy": Vector3i(1, 3, 0),
}
## Ivy hangs from one ceiling cell in this many, where there is at least
## this much air below, and never within this many cells of other ivy.
const IVY_ONE_IN := 6
const IVY_HEADROOM := 5
const IVY_PITCH := 8

const AIR := "."
const SOLID := "#%&"
## The kinds whose anchor is only the air a creature moves in.
const CREATURES: PackedStringArray = ["bat", "scorpion", "ant", "eyeball"]


## The `[decor]` grid for `level` in `style`, one string per map row.
static func place(level: LevelGrid.Level, style: String) -> Array[String]:
	var rows := _creatures_as_air(level)
	var grid: Array[String] = []
	for row in rows:
		grid.append(AIR.repeat(row.length()))
	var back := _back_cells(level)
	if style == "castle":
		_battlements(rows, grid, back)
		_torches(rows, grid, back)
		_chains(rows, grid)
		_features(rows, grid, back)
		_ivy(rows, grid)
	elif style == "forest":
		_tufts(rows, grid)
		_roots(rows, grid)
	return grid


## The section as text, ready to append to a level file.
static func section(grid: Array[String]) -> String:
	var lines := PackedStringArray(["[decor]"])
	for row in grid:
		lines.append(row)
	return "\n".join(lines) + "\n"


## A parapet is the edge of a wall walk against the sky, so none stands in
## front of a back wall: that is a building, and you are beside it.
static func _battlements(rows: Array[String], grid: Array[String], back: Dictionary) -> void:
	for run in _top_runs(rows):
		var y: int = run.x
		var from: int = run.y
		var to: int = run.z
		if to - from < 2 or not (_drops(rows, from - 1, y + 1) or _drops(rows, to + 1, y + 1)):
			continue
		for x in range(from, to + 1):
			if _sky_above(rows, x, y) and not back.has(Vector2i(x, y)):
				_put(rows, grid, x, y, "n")


static func _torches(rows: Array[String], grid: Array[String], back: Dictionary) -> void:
	for run in _top_runs(rows):
		var y: int = run.x - 1
		if y < 0:
			continue
		var candidates: Array[int] = []
		for x in range(run.y, run.z + 1):
			if back.has(Vector2i(x, y)) and _free(rows, x, y) and _free(rows, x, y + 1) and _clear_of_lights(rows, x, y + 1):
				candidates.append(x)
		var last := -TORCH_PITCH
		for x in candidates:
			if x - last >= TORCH_PITCH:
				_put(rows, grid, x, y, "t")
				last = x


static func _chains(rows: Array[String], grid: Array[String]) -> void:
	for y in range(1, rows.size()):
		for x in rows[y].length():
			if not SOLID.contains(rows[y - 1][x]) or not _free(rows, x, y):
				continue
			if _hash(x, y) % CHAIN_ONE_IN != 0 or _headroom(rows, x, y) < CHAIN_HEADROOM:
				continue
			for i in CHAIN_LENGTH:
				_put(rows, grid, x, y + i, "c")


## One feature a bay, standing on the floor in front of a back wall, its
## whole footprint wall and air no other decoration has taken.
static func _features(rows: Array[String], grid: Array[String], back: Dictionary) -> void:
	for run in _top_runs(rows):
		var floor_air: int = run.x
		var last := -FEATURE_PITCH
		for x in range(run.y, run.z + 1):
			if x - last < FEATURE_PITCH or not _clear_of_fill(rows, grid, x, floor_air):
				continue
			var start := _hash(x, floor_air) % FEATURES.size()
			for i in FEATURES.size():
				var kind := FEATURES[(start + i) % FEATURES.size()]
				var foot: Vector3i = FOOTPRINTS[kind]
				var anchor := floor_air - foot.z
				if _fits(rows, grid, back, x, anchor - foot.y + 1, anchor, foot.x, true):
					_put(rows, grid, x, anchor, _char(kind))
					last = x
					break


## Ivy hangs from a lip three cells wide, so it does not hang off an edge.
static func _ivy(rows: Array[String], grid: Array[String]) -> void:
	var foot: Vector3i = FOOTPRINTS["ivy"]
	for y in range(1, rows.size()):
		var last := -IVY_PITCH
		for x in range(1, rows[y].length() - 1):
			if x - last < IVY_PITCH or _hash(x, y) % IVY_ONE_IN != 0 or _headroom(rows, x, y) < IVY_HEADROOM:
				continue
			var hung := true
			for dx in range(-foot.x, foot.x + 1):
				hung = hung and SOLID.contains(rows[y - 1][x + dx])
			if hung and _fits(rows, grid, {}, x, y, y + foot.y - 1, foot.x, false):
				_put(rows, grid, x, y, _char("ivy"))
				last = x


## Whether every cell from `top` to `bottom`, `reach` either side of `x`, is
## air the map and the decoration leave empty, and wall behind if `walled`.
static func _fits(rows: Array[String], grid: Array[String], back: Dictionary, x: int, top: int, bottom: int, reach: int, walled: bool) -> bool:
	for y in range(top, bottom + 1):
		for dx in range(-reach, reach + 1):
			var at := Vector2i(x + dx, y)
			if not _free(rows, at.x, at.y) or grid[at.y][at.x] != AIR:
				return false
			if walled and not back.has(at):
				return false
	return true


## Whether nothing that lights or fills a wall (a torch, a ladder, a
## brazier) stands within `FEATURE_CLEAR` of `x`, on the floor's row or the
## few above it.
static func _clear_of_fill(rows: Array[String], grid: Array[String], x: int, floor_air: int) -> bool:
	for y in range(maxi(floor_air - 4, 0), floor_air + 1):
		for dx in range(-FEATURE_CLEAR, FEATURE_CLEAR + 1):
			var cx := x + dx
			if cx < 0 or cx >= rows[y].length():
				continue
			if rows[y][cx] in ["B", "H"] or grid[y][cx] == "t":
				return false
	return true


## The `[decor]` character for a kind (`LevelGrid.DECOR`).
static func _char(kind: String) -> String:
	for c: String in LevelGrid.DECOR:
		if LevelGrid.DECOR[c] == kind:
			return c
	return AIR


static func _tufts(rows: Array[String], grid: Array[String]) -> void:
	for y in range(0, rows.size() - 1):
		for x in rows[y].length():
			if rows[y + 1][x] == "#" and _free(rows, x, y) and _hash(x, y) % TUFT_ONE_IN == 0:
				_put(rows, grid, x, y, ",")


static func _roots(rows: Array[String], grid: Array[String]) -> void:
	for y in range(1, rows.size()):
		for x in rows[y].length():
			if rows[y - 1][x] == "#" and _free(rows, x, y) and _hash(x, y) % ROOT_ONE_IN == 0:
				_put(rows, grid, x, y, "'")


## Every run of open-topped solid along a row, as (row of the air above it,
## first x, last x). A run breaks where the top does.
static func _top_runs(rows: Array[String]) -> Array[Vector3i]:
	var runs: Array[Vector3i] = []
	for y in range(1, rows.size()):
		var x := 0
		var row := rows[y]
		while x < row.length():
			if not (SOLID.contains(row[x]) and _open(rows, x, y - 1)):
				x += 1
				continue
			var start := x
			while x < row.length() and SOLID.contains(row[x]) and _open(rows, x, y - 1):
				x += 1
			runs.append(Vector3i(y - 1, start, x - 1))
	return runs


## Whether the column at `x` falls at least `WALL_DROP` cells from row `y`.
static func _drops(rows: Array[String], x: int, y: int) -> bool:
	if x < 0 or x >= rows[0].length():
		return false
	for i in WALL_DROP:
		if y + i >= rows.size() or not _open(rows, x, y + i):
			return false
	return true


static func _sky_above(rows: Array[String], x: int, y: int) -> bool:
	for above in range(0, y + 1):
		if SOLID.contains(rows[above][x]) or rows[above][x] == "w":
			return false
	return true


static func _headroom(rows: Array[String], x: int, y: int) -> int:
	var n := 0
	while y + n < rows.size() and _open(rows, x, y + n):
		n += 1
	return n


static func _clear_of_lights(rows: Array[String], x: int, y: int) -> bool:
	for dx in range(-TORCH_CLEAR, TORCH_CLEAR + 1):
		var cx := x + dx
		if cx < 0 or cx >= rows[y].length():
			continue
		if rows[y][cx] in ["B", "H"]:
			return false
	return true


## Air, or a ladder's air: open for what a wall walk or a ceiling is.
static func _open(rows: Array[String], x: int, y: int) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return false
	return not SOLID.contains(rows[y][x]) and rows[y][x] != "w"


## Air the map leaves empty: no marker, no anchor, no ladder, no hazard.
static func _free(rows: Array[String], x: int, y: int) -> bool:
	return y >= 0 and y < rows.size() and x >= 0 and x < rows[y].length() and rows[y][x] == AIR


static func _put(rows: Array[String], grid: Array[String], x: int, y: int, c: String) -> void:
	if _free(rows, x, y):
		var row := grid[y]
		row[x] = c
		grid[y] = row


static func _creatures_as_air(level: LevelGrid.Level) -> Array[String]:
	var creatures := ""
	for t in level.things:
		if CREATURES.has(t.kind):
			creatures += t.anchor
	var rows: Array[String] = []
	for row in level.rows:
		var open := row
		for c in creatures:
			open = open.replace(c, AIR)
		rows.append(open)
	return rows


static func _back_cells(level: LevelGrid.Level) -> Dictionary:
	var cells := {}
	for c in LevelGrid.BACK:
		for rect in level.back_rects(c):
			var from := Vector2i(rect.position / level.cell)
			var to := Vector2i(rect.end / level.cell)
			for y in range(from.y, to.y):
				for x in range(from.x, to.x):
					cells[Vector2i(x, y)] = true
	return cells


static func _hash(x: int, y: int) -> int:
	return TileVariety.pick(Vector2i(x, y), 1 << 20)
