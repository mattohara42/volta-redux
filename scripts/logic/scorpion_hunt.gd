## The hunting scorpion's mind (`SPEC.md`, *The scorpion hunts*, Matt,
## 2026-10-25). Pure, so the tests can reach it; the scorpion asks the world
## what it sees and where its floor stops, and hands the answers in here.
##
## It never stands still while it walks: it goes to and fro over the range the
## room gave it, as `ScorpionPatrol` drew it, turning early at a ledge or a
## wall. When it sees the hero in front of it, on its own floor, it hunts:
## turns to face him wherever he goes and comes after him, faster than it
## walks, until its floor stops it at a ledge or a wall, where it waits facing
## him. When it has not seen him for a while it goes back to walking, from
## wherever the hunt left it, back toward its range.
##
## Facing is the whole fight. A hunting scorpion's armour is always toward the
## hero, so a level throw bounces; what kills it is a sword coming home through
## its back, or a hit from above (`ScorpionPatrol.is_vulnerable_to`).
class_name ScorpionHunt


## Everything the scorpion carries from one frame to the next. Positions are
## along its own floor, in the same units as the room.
class State:
	var x := 0.0
	var facing := 1.0
	var hunting := false
	## Seconds of hunting since it last saw the hero.
	var unseen := 0.0


## Whether the hero is where this scorpion can see him: `offset` is the hero's
## feet minus its own feet. On its own floor means within `sight.y` of its feet
## either way, which a hero standing on that floor always is and a hero a storey
## up or down never is. A walking scorpion looks only the way it faces; a
## hunting one already knows where he is, so it sees him either side, and
## turning round is how a hunt follows a hero who jumped over it.
static func sees(offset: Vector2, facing: float, hunting: bool, sight: Vector2) -> bool:
	if absf(offset.y) > sight.y or absf(offset.x) > sight.x:
		return false
	return hunting or offset.x == 0.0 or signf(offset.x) == facing


## One frame. `seen` is `sees` with the line of sight already checked;
## `hero_dx` is the hero's x minus the scorpion's, read only while hunting.
## `blocked_left` and `blocked_right` say whether its floor stops (a ledge or a
## wall) within a step either way. `lo` and `hi` are the range it walks.
static func step(
	s: State, seen: bool, hero_dx: float, blocked_left: bool, blocked_right: bool,
	lo: float, hi: float, walk_speed: float, hunt_speed: float, lose_after: float, delta: float
) -> void:
	if seen:
		s.hunting = true
		s.unseen = 0.0
	elif s.hunting:
		s.unseen += delta
		if s.unseen >= lose_after:
			s.hunting = false
			s.unseen = 0.0
	if s.hunting:
		_hunt(s, hero_dx, blocked_left, blocked_right, hunt_speed, delta)
	else:
		_walk(s, blocked_left, blocked_right, lo, hi, walk_speed, delta)


static func _blocked(facing: float, blocked_left: bool, blocked_right: bool) -> bool:
	return blocked_right if facing > 0.0 else blocked_left


## Toward the hero, never past him, and not over the edge of its floor. At the
## edge it stops, facing him, which is the wait `levels/act2_caverns.beats`
## (beat 9) is written around.
static func _hunt(
	s: State, hero_dx: float, blocked_left: bool, blocked_right: bool, speed: float, delta: float
) -> void:
	if hero_dx != 0.0:
		s.facing = signf(hero_dx)
	if _blocked(s.facing, blocked_left, blocked_right):
		return
	s.x += s.facing * minf(maxf(speed, 0.0) * delta, absf(hero_dx))


## To and fro over `lo..hi`, turning at either end or wherever its floor stops
## first. Outside its range (a hunt took it there) it walks back toward it.
## It holds still only where there is nowhere to walk: blocked both ways, or
## blocked on the way back to its range, where turning would take it further
## off.
static func _walk(
	s: State, blocked_left: bool, blocked_right: bool, lo: float, hi: float, speed: float, delta: float
) -> void:
	if s.x <= lo:
		s.facing = 1.0
	elif s.x >= hi:
		s.facing = -1.0
	if _blocked(s.facing, blocked_left, blocked_right):
		var away := (s.x <= lo and s.facing > 0.0) or (s.x >= hi and s.facing < 0.0)
		if away or _blocked(-s.facing, blocked_left, blocked_right):
			return
		s.facing = -s.facing
	var was_inside := s.x >= lo and s.x <= hi
	s.x += s.facing * maxf(speed, 0.0) * delta
	if was_inside:
		s.x = clampf(s.x, lo, hi)
