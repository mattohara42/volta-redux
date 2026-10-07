## What a death leaves behind in a big level (Matt, 2026-10-07), as rules a
## headless test can reach. `Player` and `Bench` act on them.
##
## A sword stuck in a wall or a switch stays where it is, so a gate it holds
## three floors down stays open; a sword lying loose or still in the air was
## the failed attempt, and goes. Your hand refills as it always has. So that
## dying is never a way to farm extra ledges, swords in hand plus swords
## stuck in the level never pass the cap: the oldest stuck ones go first.
##
## Only the timed mechanisms near the brazier you come back at go back to the
## start of their clocks. Further away, the level keeps running.
class_name RespawnRules


## Which of the swords in play to clear, by index, given whether each is
## embedded (`embedded`, in the order they were thrown), the swords about to
## be in hand, and the cap.
static func swords_to_clear(embedded: Array[bool], in_hand: int, max_swords: int) -> Array[int]:
	var clear: Array[int] = []
	var kept := 0
	for i in embedded.size():
		if embedded[i]:
			kept += 1
		else:
			clear.append(i)
	var over := in_hand + kept - max_swords
	for i in embedded.size():
		if over <= 0:
			break
		if embedded[i]:
			clear.append(i)
			over -= 1
	clear.sort()
	return clear


## Whether a mechanism at `point` is near enough to a respawn at `at` to be
## reset: within `reach` either way on each axis, about a screen.
static func within_reach(at: Vector2, point: Vector2, reach: Vector2) -> bool:
	return absf(point.x - at.x) <= reach.x and absf(point.y - at.y) <= reach.y
