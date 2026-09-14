## The hex side of ART_DIRECTION.md, for everything the code colours: shaders,
## particles, UI, and the placeholder geometry of the grey-box milestones.
##
## The prose in ART_DIRECTION.md is the source of truth. These are transcriptions
## of it, and `test_palette.gd` holds every one of them to the coloured-dark rule.
class_name Palette

# Cold stone. Everything not on fire.
const STONE_DEEP := Color("3a3550")
const STONE_MID := Color("565073")
const STONE_LIT := Color("7d7a99")

# Firelight. Braziers, torches, the hero's rim light.
const FIRE_CORE := Color("f0a63c")
const FIRE_HOT := Color("ffd98a")
const FIRE_FALLOFF := Color("a35a22")

# Lava. The one saturated thing in the game.
const LAVA_CRUST := Color("6b1f14")
const LAVA_FLOW := Color("d94f1e")
const LAVA_FISSURE := Color("ffb64a")
const LAVA_CORE := Color("fff0c2")

# Spikes. Warm and saturated because it kills you, but a good deal less
# saturated than lava at the bright end: ART_DIRECTION.md calls lava the one
# saturated thing in the game and iron catching firelight is not molten rock.
# The silhouette does the rest of the work, since a row of points reads as a row
# of points long before its hue does.
const SPIKE_IRON := Color("7a2434")
const SPIKE_TIP := Color("e0956f")

# Steam. A geyser's column. Cool and desaturated on purpose: ART_DIRECTION.md
# reserves warm and saturated for what kills you, and a geyser is the one hazard
# in the game that does not. Kept well under ARC's saturation and off its hue, so
# a jet is not read as an arc by a player who has been to Act 3.
const STEAM_BODY := Color("7e9bb0")
const STEAM_CORE := Color("cfe4ea")

# Electricity. Act 3 and Volta, and the only cool bright.
const ARC := Color("5fe0e8")
const ARC_CORE := Color("eafcff")
const ARC_RESIDUE := Color("2a6f8a")

# Wood. ART_DIRECTION.md calls wood warm umber, and also says anything you can
# stand on is cold and matte. Wood is both: it is the surface a sword bites and
# then a ledge you stand on. Resolved as warm in hue and matte in saturation,
# so it reads as "not stone" without ever reading as "on fire". Its saturation
# sits at about half of lava's on purpose.
const WOOD_DEEP := Color("4a3626")
const WOOD_FACE := Color("7a5c3e")

# Gold means interactive and nothing else gets to use it.
const GOLD_FACE := Color("e8c25a")
const GOLD_SHADE := Color("a37c26")

# Enemies. SPEC.md puts animals on the same kill list as lava and spikes, so
# the body is warm like a hazard, but well off lava's saturation the way
# spikes are: this is chitin catching firelight, not molten rock.
const ENEMY_CHITIN := Color("5c2a3a")

# The backdrop a room sits against before there is a painted background.
const BACKDROP := Color("211c33")


## Every named colour, so the rule check has something to iterate.
static func all() -> Dictionary:
	return {
		"STONE_DEEP": STONE_DEEP,
		"STONE_MID": STONE_MID,
		"STONE_LIT": STONE_LIT,
		"FIRE_CORE": FIRE_CORE,
		"FIRE_HOT": FIRE_HOT,
		"FIRE_FALLOFF": FIRE_FALLOFF,
		"LAVA_CRUST": LAVA_CRUST,
		"LAVA_FLOW": LAVA_FLOW,
		"LAVA_FISSURE": LAVA_FISSURE,
		"LAVA_CORE": LAVA_CORE,
		"SPIKE_IRON": SPIKE_IRON,
		"SPIKE_TIP": SPIKE_TIP,
		"STEAM_BODY": STEAM_BODY,
		"STEAM_CORE": STEAM_CORE,
		"ARC": ARC,
		"ARC_CORE": ARC_CORE,
		"ARC_RESIDUE": ARC_RESIDUE,
		"WOOD_DEEP": WOOD_DEEP,
		"WOOD_FACE": WOOD_FACE,
		"GOLD_FACE": GOLD_FACE,
		"GOLD_SHADE": GOLD_SHADE,
		"ENEMY_CHITIN": ENEMY_CHITIN,
		"BACKDROP": BACKDROP,
	}
