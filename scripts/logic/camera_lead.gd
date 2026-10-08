## Where the hero's camera sits ahead of them (`HeroCamera`), as a rule a test
## can reach.
class_name CameraLead


## The lead after `delta`: toward `distance` on the side the hero is running,
## at `speed` px/s. Slower than `min_speed` it holds, so a stand-still turn to
## throw leaves the view where it was.
static func step(
	lead: float, speed_x: float, distance: float, speed: float, min_speed: float, delta: float
) -> float:
	if absf(speed_x) < min_speed:
		return lead
	return move_toward(lead, signf(speed_x) * distance, speed * delta)
