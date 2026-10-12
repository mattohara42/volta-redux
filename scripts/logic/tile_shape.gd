## What a solid cell's neighbours say about how it is drawn (N2): which of its
## sides are open, so an edge goes there, and how deep it is in the stone, so
## its interior can fall into the dark. Pure, over a level's padded map rows
## (`LevelGrid.Level.rows`), so a test can read it the way the bake does.
##
## Outside the map counts as solid: a level's floor runs on down out of sight
## rather than showing an edge along the bottom of the screen.
class_name TileShape
extends RefCounted

## What counts as stone for edges and depth: ground, wall face, castle.
const SOLID := "#%&"

const UP := 1
const RIGHT := 2
const DOWN := 4
const LEFT := 8

## Deeper than this is all one depth, so a cell sealed in on every side does
## not need a number of its own.
const DEEPEST := 64


static func is_solid(rows: Array[String], x: int, y: int, solid: String = SOLID) -> bool:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return true
	return solid.contains(rows[y][x])


## The open sides of cell (x, y), as `UP | RIGHT | DOWN | LEFT` bits. Zero for
## a cell that is not solid, which has no sides to draw.
static func open_sides(rows: Array[String], x: int, y: int, solid: String = SOLID) -> int:
	if not is_solid(rows, x, y, solid):
		return 0
	var sides := 0
	if not is_solid(rows, x, y - 1, solid):
		sides |= UP
	if not is_solid(rows, x + 1, y, solid):
		sides |= RIGHT
	if not is_solid(rows, x, y + 1, solid):
		sides |= DOWN
	if not is_solid(rows, x - 1, y, solid):
		sides |= LEFT
	return sides


## Every cell's depth into the stone, row by row: 0 for open cells, 1 for
## solid touching the open on any side or corner, 2 for the ring inside that,
## and so on up to `DEEPEST`.
static func depths(rows: Array[String], solid: String = SOLID) -> PackedInt32Array:
	var height := rows.size()
	var width := rows[0].length() if height > 0 else 0
	var out := PackedInt32Array()
	out.resize(width * height)
	out.fill(DEEPEST)
	var frontier: Array[Vector2i] = []
	for y in height:
		for x in width:
			if not is_solid(rows, x, y, solid):
				out[y * width + x] = 0
				frontier.append(Vector2i(x, y))
	# A breadth-first walk out from every open cell at once, eight ways, so
	# depth is the ring a cell is in.
	var depth := 0
	while not frontier.is_empty() and depth < DEEPEST - 1:
		depth += 1
		var next: Array[Vector2i] = []
		for at in frontier:
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var x: int = at.x + dx
					var y: int = at.y + dy
					if x < 0 or y < 0 or x >= width or y >= height:
						continue
					if out[y * width + x] > depth:
						out[y * width + x] = depth
						next.append(Vector2i(x, y))
		frontier = next
	return out


## How many solid cells stand above (x, y) in its own column before the open:
## 0 for a cell whose top is open. The row under a lip is 1. Draws the shadow
## that falls under a ledge.
static func below_top(rows: Array[String], x: int, y: int, solid: String = SOLID) -> int:
	var n := 0
	while is_solid(rows, x, y - n - 1, solid) and y - n - 1 >= 0:
		n += 1
	return n
