## One act's ground: the floor lip, the masonry or rock under it, and the far
## background. `TileArt` draws from one of these; a room passes its act's set,
## and Act 1's is the default, so a room that passes none draws the castle.
class_name ActTiles
extends Resource

## The walkable lip, in variants scattered by `TileVariety`.
@export var floor_tiles: Array[Texture2D] = []
## What fills below a lip and makes walls, in variants.
@export var wall_tiles: Array[Texture2D] = []
## The painted far layer, or null for a plain backdrop until one is painted.
@export var background: Texture2D = null
