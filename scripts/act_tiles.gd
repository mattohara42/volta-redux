## One act's ground: the floor lip, the masonry or rock under it, and the far
## background. `TileArt` draws from one of these; a room passes its act's set,
## and Act 1's is the default, so a room that passes none draws the castle. A
## level can name a set of its own (`GridRoom.tiles`), as the forest does.
##
## The slots after the background are optional. Left empty, each draws the
## castle's art (`TileArt`), so a set only names what it changes.
class_name ActTiles
extends Resource

## The walkable lip, in variants scattered by `TileVariety`.
@export var floor_tiles: Array[Texture2D] = []
## What fills below a lip and makes walls, in variants.
@export var wall_tiles: Array[Texture2D] = []
## The painted far layer, or null for a plain backdrop until one is painted.
@export var background: Texture2D = null
## Where the painting is itself lit (a window, a fire), in one copy of it, art
## px. Each becomes a light in the room's `LightField`, so the dark draws back
## around what the painter lit and the painting and the room agree.
@export var lights: PackedVector2Array = PackedVector2Array()
## The face of a wall you cannot stand on (`%`): masonry in the castle, cold
## bark on the forest's trunks. Empty draws `wall_tiles`.
@export var face_tiles: Array[Texture2D] = []
## Wood a sword bites into: planks in the castle, branches in the forest.
@export var wood_tiles: Array[Texture2D] = []
## What a hero climbs: a ladder in the castle, a vine in the forest.
@export var climb_tiles: Array[Texture2D] = []
## What kills you to land on: iron spikes in the castle, thorns in the forest.
@export var hazard_tiles: Array[Texture2D] = []
## A slab that gives way, cropped so its top row is the surface. Null keeps a
## grid level's falling slab drawn in code, as it was before this slot.
@export var crumble_tile: Texture2D = null
## A stump (`Stump`), whole, at its rect's size. Null keeps it drawn in code.
@export var stump_texture: Texture2D = null
