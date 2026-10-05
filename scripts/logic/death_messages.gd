## What the game says when it kills you.
##
## The 1984 original put a bordered box on the level carrying one of fifteen
## short, mock-heroic lines. `assets/reference/c64/` holds four of them and
## CLAUDE.md forbids shipping anything out of that directory, so these are
## originals written to the same register: brief, archaic, and absurdly formal
## about a stupid death.
##
## **The box does not come with them.** SPEC.md's central modernisation is that
## dying costs under a second, and a box you have to read costs two. The line
## therefore lingers while you are already running again, which keeps the
## tradition and the done-when at the same time.
##
## **A line knows what it is about** (`BACKLOG.md`, raised during M12). A line
## that names lava is only said by lava, so an arc in Act 3 never answers with
## a geyser. Lines about nothing in particular can be said by anything.
class_name DeathMessages

## What killed you, as far as the lines care.
enum Cause { ANY, LAVA, SPIKES, BEAST, CURRENT, FIRE }

## Every line, and beside it the one cause it may be said for. ANY is said
## for every cause. Fifteen were written first, to match the original's
## count; the rest arrived when lines learned their causes, so every cause
## has a handful of its own.
const LINES: Array[Array] = [
	["GRAVITY, UNDEFEATED", Cause.ANY],
	["THE FLOOR OBJECTED", Cause.ANY],
	["YOU SUCCUMB TO MOMENTUM", Cause.ANY],
	["A BRIEF AND BRILLIANT CAREER", Cause.ANY],
	["LOTHARS BANE", Cause.ANY],
	["AN IGNOBLE PAUSE", Cause.ANY],
	["THE HILL PEOPLE MUST NOT HEAR", Cause.ANY],
	["A LESSON IN HUMILITY", Cause.ANY],
	["A MOLTEN WELCOME", Cause.LAVA],
	["THE MOUNTAIN DRINKS DEEP", Cause.LAVA],
	["THE MOAT KEEPS ITS OWN", Cause.LAVA],
	["THE GEYSER HAD OTHER PLANS", Cause.LAVA],
	["RENDERED, AS TALLOW IS", Cause.LAVA],
	["WARMER THAN ADVERTISED", Cause.LAVA],
	["THE DEEP FIRES ARE NOT BATHS", Cause.LAVA],
	["SMELTED, TO NO PURPOSE", Cause.LAVA],
	["SPITTED LIKE A HOG", Cause.SPIKES],
	["THE IRON WAS PATIENT", Cause.SPIKES],
	["A POINTED REBUKE", Cause.SPIKES],
	["ALL POINTS CONSIDERED", Cause.SPIKES],
	["IMPALED UPON YOUR PRIDE", Cause.SPIKES],
	["THE TEETH WERE SET FOR YOU", Cause.SPIKES],
	["BESTED BY VERMIN", Cause.BEAST],
	["SUPPER, ARRIVED ON FOOT", Cause.BEAST],
	["OUTWITTED BY A CARAPACE", Cause.BEAST],
	["A FEAST FOR LESSER THINGS", Cause.BEAST],
	["THE BEAST BOWS TO NO ONE", Cause.BEAST],
	["DEVOURED WITHOUT CEREMONY", Cause.BEAST],
	["VOLTA SENDS HIS REGARDS", Cause.CURRENT],
	["THE COPPER WAS NOT ASLEEP", Cause.CURRENT],
	["CONDUCTED, BUT NOT TO GLORY", Cause.CURRENT],
	["YOUR HAIR WILL NOT RECOVER", Cause.CURRENT],
	["GROUNDED, AT LAST", Cause.CURRENT],
	["A CIRCUIT, COMPLETED", Cause.CURRENT],
	["THE WYRM EXHALES", Cause.FIRE],
	["ROASTED IN GOOD FAITH", Cause.FIRE],
	["A WARM AND FINAL AUDIENCE", Cause.FIRE],
	["THE DRAGON WAS NOT AMUSED", Cause.FIRE],
	["COOKED THROUGH, THEN SOME", Cause.FIRE],
]

## The widest line the HUD will take, in characters.
const MAX_LENGTH := 32


static func count() -> int:
	return LINES.size()


static func message_at(index: int) -> String:
	if index < 0 or index >= LINES.size():
		return ""
	return LINES[index][0]


static func cause_of(index: int) -> Cause:
	if index < 0 or index >= LINES.size():
		return Cause.ANY
	return LINES[index][1]


## Every line `cause` may say: its own, and the ones about nothing.
static func pool_for(cause: Cause) -> PackedInt32Array:
	var pool: PackedInt32Array = []
	for i in LINES.size():
		var line_cause: Cause = LINES[i][1]
		if line_cause == Cause.ANY or line_cause == cause:
			pool.append(i)
	return pool


## A bag of every unused line, refilled from `pool` once it empties. This is
## what makes the rotation **unique** rather than merely random: every line a
## cause can say is seen before any of them twice, which matters in a game
## built to be died in often. One bag per cause, kept by whoever is dying.
static func refill_if_empty(bag: PackedInt32Array, pool: PackedInt32Array) -> PackedInt32Array:
	if not bag.is_empty():
		return bag
	return pool.duplicate()


## Which slot of the bag to take, for a roll in [0, 1). Its own function because
## clamping the top of the range is the bug that would otherwise show up once
## every few thousand deaths and never in a test.
static func slot_for(roll: float, bag_size: int) -> int:
	if bag_size <= 0:
		return -1
	return clampi(int(roll * float(bag_size)), 0, bag_size - 1)
