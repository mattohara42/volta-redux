## The generator's arc, as a rule. Pure, so the tests can reach it.
##
##   REST       charging, harmless
##   WARNING    a marker where you stood when it finished charging
##   STRIKING   the arc is in the ground there and kills
##
## **It starts at rest**, for the reason `LavaTide` starts low: a respawn puts
## the clock back to zero, and coming back to life under an arc would be a
## second death you did nothing to earn.
class_name GeneratorCycle

enum Phase { REST, WARNING, STRIKING }


static func period(rest: float, warning: float, strike: float) -> float:
	return rest + warning + strike


static func phase_at(t: float, rest: float, warning: float, strike: float) -> Phase:
	var at := fposmod(maxf(t, 0.0), period(rest, warning, strike))
	if at < rest:
		return Phase.REST
	if at < rest + warning:
		return Phase.WARNING
	return Phase.STRIKING


## Which arc this is, counting from zero: a new target is taken each time this
## changes on entering WARNING.
static func arc_index(t: float, rest: float, warning: float, strike: float) -> int:
	return floori(maxf(t, 0.0) / period(rest, warning, strike))
