## What Act 4's rooms share: the Hall of Volta, in dark violet marble with a
## bronze line under every floor's lip (`ART.md` → *Act 4*).
class_name Act4Room
extends Bench

const TILES: ActTiles = preload("res://assets/art/act4/act4_tiles.tres")
const CEILING_HEIGHT: float = 32.0
const WORLD_CONFIG: WorldConfig = preload("res://config/world.tres")


## The height a standing throw flies at from `stand_y`.
static func throw_y(stand_y: float) -> float:
	return stand_y - WORLD_CONFIG.hero_height * 0.5
