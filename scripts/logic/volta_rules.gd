## Volta's fight, as rules. Pure, so the tests can reach them. His clock is
## `GeneratorCycle`'s; this says which casts are pulls and when the chains go.
class_name VoltaRules


## Whether cast `index` (from zero) is a pull rather than a bolt: the last of
## every `every`, so the first casts teach the bolt before the first pull.
static func is_pull(index: int, every: int) -> bool:
	return every > 0 and index % every == every - 1


## The chains' burn after a step: it climbs while current holds and starts
## again from nothing the moment it breaks.
static func burn_after(burn: float, held: bool, delta: float) -> float:
	return burn + delta if held else 0.0


## Whether the chains have burnt through.
static func chains_free(burn: float, needed: float) -> bool:
	return burn >= needed
