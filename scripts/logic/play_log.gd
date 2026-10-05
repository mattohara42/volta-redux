## One line per room played, for judging difficulty and length from a real
## playthrough rather than by reasoning (`CLAUDE.md`: feel is verified by
## playing). `ActState` times the room and writes the file; this is the shape
## of a line, where a headless test can reach it.
##
## The file is `user://play_log.csv`, appended to and never rewritten, so
## every session adds to it. `tools/play_log.py` sums it up per room.
class_name PlayLog

const PATH := "user://play_log.csv"
const HEADER := "when,act,room,seconds,deaths,causes,swords_in,swords_out,restarts,ended"


## A room as one CSV line. `causes` counts deaths by `DeathMessages.Cause`.
## `ended` is how the room was left: "exit", "quit" or "new game", and
## `swords_out` is -1 for any but an exit. Only a plain launch writes it, as
## only a plain launch touches the save.
static func row(when: String, act: int, room_path: String, seconds: float, deaths: int,
		causes: Dictionary, swords_in: int, swords_out: int, restarts: int, ended: String) -> String:
	return "%s,%d,%s,%.1f,%d,%s,%d,%d,%d,%s" % [
		when, act + 1, room_path.get_file().get_basename(), seconds, deaths,
		cause_counts(causes), swords_in, swords_out, restarts, ended,
	]


## Deaths by cause as one CSV-safe field: "lava 3 beast 1", most first, or
## "none".
static func cause_counts(causes: Dictionary) -> String:
	var keys := causes.keys()
	keys.sort_custom(func(a: int, b: int) -> bool:
		return causes[a] > causes[b] or (causes[a] == causes[b] and a < b))
	var parts := PackedStringArray()
	for cause: int in keys:
		parts.append("%s %d" % [String(DeathMessages.Cause.keys()[cause]).to_lower(), causes[cause]])
	return "none" if parts.is_empty() else " ".join(parts)
