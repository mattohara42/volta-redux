## Ground drawn on its own layer, for a room that needs rock in front of
## something it owns: a lava tide has to sink out of sight under the floor, so
## the floor is drawn after it. Draws `rects` with an act's tiles, nothing else.
class_name GroundLayer
extends Node2D

var rects: Array[Rect2] = []
var tiles: ActTiles = null


func _draw() -> void:
	for rect in rects:
		TileArt.draw_ground(self, rect, tiles)
