## The rules for moving between rooms, where a headless test can reach them.
## `ActState` is the part that cannot be pure: it holds what carries and it
## changes the scene.
class_name ActRoute

## The room after `current` in `rooms`, or "" when `current` is the last one
## (the act is complete) or is not in this act at all.
static func next_room(rooms: PackedStringArray, current: String) -> String:
	var at := rooms.find(current)
	if at < 0 or at + 1 >= rooms.size():
		return ""
	return rooms[at + 1]


## Whether leaving `current` finishes the act.
static func is_last(rooms: PackedStringArray, current: String) -> bool:
	return rooms.size() > 0 and rooms[rooms.size() - 1] == current


## The act that follows act `index` of `count`. After the last, the ending
## has played and the game starts again from Act 1, as a new game.
static func act_after(index: int, count: int) -> int:
	return index + 1 if index + 1 < count else 0


## Whether finishing act `index` of `count` finishes the game.
static func is_ending(index: int, count: int) -> bool:
	return index == count - 1


## What you arrive in the next room holding. Only what is in your hand comes
## with you: a sword left embedded or lying in the last room stays there.
static func carried(held: int, max_swords: int) -> int:
	return clampi(held, 0, max_swords)


## What you hold after a chest. It fills your hand to `fill` and never takes
## any away, so a chest is never a reason not to open it. Swords of yours still
## out in the room do not count against it (Matt, 2026-10-06: counting them
## made a chest give nothing, which read as broken). Recall still caps at
## `max_swords`.
static func chest_top_up(held: int, fill: int, max_swords: int) -> int:
	return maxi(held, mini(fill, max_swords))


## What the end card says about the run: how many times Lothar died and how
## long it took, in the register the death lines keep. A string a player reads.
static func tally(deaths: int, seconds: float) -> String:
	var fell := "Lothar never fell." if deaths <= 0 else (
		"Lothar fell once" if deaths == 1 else "Lothar fell %d times" % deaths
	)
	var minutes := int(seconds / 60.0)
	var took := "in under a minute" if minutes < 1 else (
		"in a minute" if minutes == 1 else "in %d minutes" % minutes
	)
	if deaths <= 0:
		return "%s It took %s." % [fell, took.trim_prefix("in ")]
	return "%s, %s." % [fell, took]


## The line under an act's own card: how often it killed you.
static func act_tally(deaths: int) -> String:
	if deaths <= 0:
		return "Not once did it kill you."
	return "It killed you once." if deaths == 1 else "It killed you %d times." % deaths
