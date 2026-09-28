## Which of a tile's variants sits in a given grid cell.
##
## A hash of the cell, not a random draw, so a room looks the same every time
## it loads and a screenshot can be compared against the last one.
class_name TileVariety


## An index into `count` variants for `cell`. Always the same for the same
## cell, and spread evenly over the variants across a room.
static func pick(cell: Vector2i, count: int) -> int:
	if count <= 1:
		return 0
	var h := (cell.x * 73856093) ^ (cell.y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16)) % count
