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
## has played and the game starts again from Act 1: there are no saves until
## M16, so that is a new game.
static func act_after(index: int, count: int) -> int:
	return index + 1 if index + 1 < count else 0


## Whether finishing act `index` of `count` finishes the game.
static func is_ending(index: int, count: int) -> bool:
	return index == count - 1


## What you arrive in the next room holding. Only what is in your hand comes
## with you: a sword left embedded or lying in the last room stays there.
static func carried(held: int, max_swords: int) -> int:
	return clampi(held, 0, max_swords)


## What you hold after a chest, given `out` swords of yours still in the room.
## It brings the swords you own up to `fill` and never takes any away, so a
## chest is never a reason not to open it.
static func chest_top_up(held: int, out: int, fill: int, max_swords: int) -> int:
	var wanted := mini(fill, max_swords) - out
	return maxi(held, mini(wanted, max_swords))
