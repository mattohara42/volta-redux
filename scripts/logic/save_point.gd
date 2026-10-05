## Where a saved game picks up (`BUILD_PLAN.md` M16: a save per act), where a
## headless test can reach it. `ActState` is the part that reads and writes
## the file and changes the scene.
##
## A save is the act you were in, the swords you carried into it, and the
## run's tally so far, so a game left mid-act starts that act again from its
## first room with what you brought, and the end card still counts the whole
## run.
class_name SavePoint

## Bumped when the shape of a save changes, so an old one is ignored rather
## than misread.
const VERSION := 1
const SECTION := "game"


## A save as the values `ActState` writes. `swords` is -1 when the act was
## begun with the room's own count rather than a carried one.
static func make(act: int, swords: int, act_deaths_before: int, deaths: int, seconds: float) -> Dictionary:
	return {
		"version": VERSION,
		"act": act,
		"swords": swords,
		"act_deaths_before": act_deaths_before,
		"deaths": deaths,
		"seconds": seconds,
	}


## A save read back, made safe to act on, or empty when there is nothing to
## resume: no save, an old shape, or an act that no longer exists. Counts out
## of range are pulled back into it rather than refused, because a tally a
## little wrong is better than a lost game.
static func resume(data: Dictionary, act_count: int, max_swords: int) -> Dictionary:
	if int(data.get("version", 0)) != VERSION or not data.has("act"):
		return {}
	var act := int(data["act"])
	if act < 0 or act >= act_count:
		return {}
	var deaths := maxi(int(data.get("deaths", 0)), 0)
	return make(
		act,
		clampi(int(data.get("swords", -1)), -1, max_swords),
		clampi(int(data.get("act_deaths_before", 0)), 0, deaths),
		deaths,
		maxf(float(data.get("seconds", 0.0)), 0.0),
	)


## Whether this run of the engine plays for real and so may read and write
## the save. A tool or the tests (`--script`) never do: a capture of the first
## room must not depend on where someone's game was left, and walking the
## route must not overwrite it.
static func enabled(cmdline_args: PackedStringArray) -> bool:
	return not cmdline_args.has("--script")
