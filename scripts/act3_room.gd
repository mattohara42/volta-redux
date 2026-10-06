## What Act 3's rooms share: the underground tiles, copper plate, and the one
## rule every copper face is built on, that a seam sits exactly where a standing
## throw flies (`SPEC.md` → *Conduct*), so a sword thrown at it lands across it.
class_name Act3Room
extends Bench

const TILES: ActTiles = preload("res://assets/art/act3/act3_tiles.tres")
const COPPER: Texture2D = preload("res://assets/art/act3/tiles_px/copper.png")
const WORLD_CONFIG: WorldConfig = preload("res://config/world.tres")
const SEAM_HEIGHT: float = 2.0
## How far a live copper face sits back under the ledge above it, so a hero
## dropping past it never brushes it. It is also how far a hero would have to
## walk into the recess to die, which they can see crackling.
const RECESS: float = 16.0
const COPPER_WIDTH: float = 24.0
const CEILING_HEIGHT: float = 32.0


## The top of the seam a hero standing on `stand_y` throws down.
static func seam_at(stand_y: float) -> float:
	return stand_y - WORLD_CONFIG.hero_height * 0.5 - SEAM_HEIGHT * 0.5


## The way back up out of a yard (`SPEC.md`: you can always walk back to the
## start). Every Act 3 yard is a drop deeper than the jump, and before the
## family playtest none had a way out. At the foot of the drop, so it serves
## the ledge you came off, and clear of the recessed copper.
func _add_way_back(yard_x: float, upper_top: float) -> void:
	_add_ladder(yard_x, upper_top, FLOOR_TOP)


func _draw_ways_back() -> void:
	for ladder in _ladders:
		TileArt.draw_ladder(self, ladder)


func _draw_seam(x: float, y: float, width: float) -> void:
	# Insulation: the dark of a gap, so it reads as a break in the copper.
	draw_rect(Rect2(x, y, width, SEAM_HEIGHT), Palette.BACKDROP)


## A wire along the wall from `from` across and then up or down to `to`, the
## residue blue of a spent arc: it says these two are joined.
func _draw_wire(from: Vector2, to: Vector2) -> void:
	var corner := Vector2(to.x, from.y)
	draw_line(from, corner, Palette.ARC_RESIDUE, 1.0)
	draw_line(corner, to, Palette.ARC_RESIDUE, 1.0)


## The same, but up to the ceiling and along it first, for a room whose floor
## has things on it a wire at chest height would read as a tripwire across.
func _draw_wire_overhead(from: Vector2, to: Vector2) -> void:
	var run_y := CEILING_HEIGHT + 4.0
	draw_line(from, Vector2(from.x + 4.0, from.y), Palette.ARC_RESIDUE, 1.0)
	draw_line(Vector2(from.x + 4.0, from.y), Vector2(from.x + 4.0, run_y), Palette.ARC_RESIDUE, 1.0)
	draw_line(Vector2(from.x + 4.0, run_y), Vector2(to.x, run_y), Palette.ARC_RESIDUE, 1.0)
	draw_line(Vector2(to.x, run_y), to, Palette.ARC_RESIDUE, 1.0)
