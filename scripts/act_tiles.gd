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
## The painting's windows onto the sky, in one copy of it, art px: each pane's
## box from the tip of its arch to its sill. A storm (`Storm`) flashes and
## strikes inside them, and nowhere else on the painting.
@export var windows: Array[Rect2] = []
## The face of a wall you cannot stand on (`%`): masonry in the castle, cold
## bark on the forest's trunks. Empty draws `wall_tiles`.
@export var face_tiles: Array[Texture2D] = []
## Wood a sword bites into: planks in the castle, branches in the forest.
@export var wood_tiles: Array[Texture2D] = []
## Whether a wall face ends in a lintel, the floor's lip upside down. True
## for cut stone; false where the lip is something that only grows on top.
@export var lintel := true
## What a hero climbs: a ladder in the castle, a vine in the forest.
@export var climb_tiles: Array[Texture2D] = []
## What kills you to land on: iron spikes in the castle, thorns in the forest.
@export var hazard_tiles: Array[Texture2D] = []
## A slab that gives way, cropped so its top row is the surface. Null keeps a
## grid level's falling slab drawn in code, as it was before this slot.
@export var crumble_tile: Texture2D = null
## A stump (`Stump`), whole, at its rect's size. Null keeps it drawn in code.
@export var stump_texture: Texture2D = null
## A portal door (`Portal`): its frame, the slab that shuts it, and where the
## opening is in the frame, art px. The opening's foot stands on the door's
## floor. Null keeps the door drawn in code.
@export var portal_frame: Texture2D = null
@export var portal_slab: Texture2D = null
@export var portal_hole := Rect2()

@export_group("Edges and depth (N2)")
## The line drawn along a solid's open side and under it (`TileShape`): the
## darkest outline already in the fill art, so an edge reads as the art's own.
## A coloured dark (`ART_DIRECTION.md`), and `test_level_bake.gd` holds it to that.
@export var edge_dark: Color = Color("20194f")
## What a solid interior falls into, away from the air: the set's own dark,
## violet-blue in stone, umber in earth.
@export var interior_dark: Color = Color("1c1830")

@export_group("Decoration (N2)")
## What grows on the grass and hangs under the earth (`DecorRules`, forest).
## Empty leaves the decoration out.
@export var tuft_tiles: Array[Texture2D] = []
@export var root_tiles: Array[Texture2D] = []
