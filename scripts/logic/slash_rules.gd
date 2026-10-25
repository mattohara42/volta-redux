## The slash with the sword that never leaves his hand (`SPEC.md`, Matt,
## 2026-10-25). Pure, so the tests can reach it.
##
## It costs nothing and is always there, so what stops it making the throw
## optional is its reach and its recovery: a short box in front of the hero,
## live for a moment, then a pause before the next. Both are dials in
## `config/sword.tres`.
class_name SlashRules


## Where the strike lands, relative to the hero's centre: a box `reach` px
## out from his front, `height` tall, centred on his middle.
static func box(facing: float, hero_half_width: float, reach: float, height: float) -> Rect2:
	var near := hero_half_width
	var x := near if facing > 0.0 else -near - reach
	return Rect2(x, -height * 0.5, reach, height)


## Whether a slash started `elapsed` seconds ago can still cut.
static func is_striking(elapsed: float, active: float) -> bool:
	return elapsed >= 0.0 and elapsed < active


## Whether a new slash may start: the last one is `elapsed` seconds old, and a
## slash takes `active` to strike and `recovery` more before the hand is free.
## A somersault or a dive's recovery holds it as it holds the throw
## (`Locomotion.can_throw`).
static func can_slash(elapsed: float, active: float, recovery: float, somersaulting: bool, recovering: bool) -> bool:
	if not Locomotion.can_throw(somersaulting, recovering):
		return false
	return elapsed >= active + recovery


## The blade's angle while it strikes, radians, for a hero facing right: from
## raised behind (`-sweep / 2` above level) down through level to `sweep / 2`
## below, eased so it whips through the middle. Mirrored by the caller.
static func blade_angle(elapsed: float, active: float, sweep: float) -> float:
	var t := clampf(elapsed / maxf(active, 0.0001), 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	return lerpf(-sweep * 0.5, sweep * 0.5, eased)
