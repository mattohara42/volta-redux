## What Act 4's rooms share: the Hall of Volta. Until its own tiles are
## generated (`ART.md` → *Act 4*) it borrows Act 3's dressed underground
## stone, which is the nearest thing the game has to a hall.
class_name Act4Room
extends Bench

const TILES: ActTiles = preload("res://assets/art/act3/act3_tiles.tres")
const CEILING_HEIGHT: float = 32.0
const WORLD_CONFIG: WorldConfig = preload("res://config/world.tres")


## The height a standing throw flies at from `stand_y`.
static func throw_y(stand_y: float) -> float:
	return stand_y - WORLD_CONFIG.hero_height * 0.5
