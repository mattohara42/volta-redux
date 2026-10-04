## The ending's flight (`SPEC.md` → *Act 4*): the freed dragon carries you
## out, and you steer it up and down between the pillars.
class_name FlightConfig
extends Resource

## How fast the dragon carries you forward, px/s. Not yours to change: the
## flight is a ride, and the only decision is height.
@export var forward_speed: float = 150.0
## How fast you climb or dive, px/s. Fast enough to make every gap from the
## one before it at this forward speed.
@export var vertical_speed: float = 170.0
