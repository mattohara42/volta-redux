## A level's art set (`ActTiles`) names only what it changes: every optional
## slot left empty draws the castle's art, so the castle levels do not move
## when the forest gets its own.
extends TestCase

const VINE: Texture2D = preload("res://assets/art/act1/tiles_px/chain.png")


func test_an_empty_slot_draws_the_castle() -> void:
	check_eq(TileArt._slot(null, "wood_tiles", TileArt.WOOD_TILES), TileArt.WOOD_TILES, "no set: the castle's planks")
	var own := ActTiles.new()
	check_eq(TileArt._slot(own, "climb_tiles", TileArt.LADDER_TILES), TileArt.LADDER_TILES, "an empty slot: the castle's ladder")
	check_eq(TileArt._slot(TileArt.ACT1, "hazard_tiles", TileArt.SPIKE_TILES), TileArt.SPIKE_TILES, "Act 1's set leaves them all empty")
	check(TileArt.ACT1.crumble_tile == null, "and keeps a grid level's slabs drawn as they were")


func test_a_filled_slot_is_used() -> void:
	var own := ActTiles.new()
	own.climb_tiles = [VINE] as Array[Texture2D]
	check_eq(TileArt._slot(own, "climb_tiles", TileArt.LADDER_TILES), [VINE] as Array[Texture2D], "the set's own climb")


## The forest's trunks are stone in the map, so their bark has to read as
## something a sword breaks on: drawn from its own slot, not the earth's.
func test_the_forest_faces_its_walls_with_bark() -> void:
	var forest: ActTiles = load("res://assets/art/forest/forest_tiles.tres")
	check(not forest.face_tiles.is_empty(), "the forest has its own wall faces")
	check(forest.face_tiles[0] != forest.wall_tiles[0], "and they are not the earth under its floor")
	check(TileArt.ACT1.face_tiles.is_empty(), "the castle's walls stay its masonry")
