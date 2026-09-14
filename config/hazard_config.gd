## Every number a hazard's shape is made of.
##
## CLAUDE.md puts hazard tuning in `config/`, and a spike bed has one number
## that decides how the game feels: `spike_grace`, the depth you can sink into
## the points and live. Getting that wrong is the difference between a hazard
## that is hard and one that is unfair, and it is not something a script gets
## to hold.
##
## Lava is not here. Lava is a rectangle a room hands to `Hazard` and it has no
## shape of its own to tune.
##
## Geysers are here, and unlike spikes they are not a shape at all: every number
## one has is a duration or a speed, because a geyser is a clock that takes the
## hero's vertical speed off him and hands it back. How tall and how wide the
## column is belongs to the room that dug the shaft, for the same reason a
## ferry's span does.
##
## Platforms are not hazards either, in the sense that neither kind has a
## killing box and neither ever touches `Hazard`: they are the things that put
## you in one, or fail to keep you out of one. Their numbers are here because
## they are what a room full of hazards is tuned against, and splitting them
## into a file of their own would put two halves of the same decision in two
## places.
class_name HazardConfig
extends Resource

@export_group("Spikes")
## How far a tooth stands off the surface it is bolted to, in design px. Read
## against WorldConfig.tile_size: three quarters of a tile, so a bed reads as
## spikes rather than as a rough floor.
@export var spike_tooth_height: float = 12.0
## Base width of one tooth, and therefore the spacing of the points. Half a
## tile, which puts two points under a standing hero.
@export var spike_tooth_pitch: float = 8.0
## How far below the points the killing box starts, in design px. Brushing the
## tips lives, sinking past this dies.
##
## It only ever applies to a jump arc crossing a bed near its apex, where the
## vertical speed is close to zero, because nothing else approaches a bed
## downwards slowly. Measured in a running build at this value it does not
## change the takeoff window on the M3 spike bench at all, so whether it is
## worth having is a feel question and M14 owns it. A quarter of a tooth.
@export var spike_grace: float = 3.0

@export_group("Falling platforms")
## Seconds from something standing on a platform to the platform letting go.
## The number the whole hazard is made of: it is how long you are allowed to
## stand still, and the room around it is built against it.
##
## Long enough to land, read the shake and jump, and short enough that crossing
## a moat is one continuous decision rather than a queue. Against a 200 px/s run
## and a 48 px slab, it is a little under twice what crossing one slab costs.
@export var platform_warn_time: float = 0.45
## How hard a let-go platform falls, px/s^2. Deliberately gentler than the
## hero's own falling gravity, so a slab that drops out from under you sinks
## rather than snapping away, and you can watch it go while you jump.
@export var platform_fall_gravity: float = 1400.0
## Seconds a platform stays out of the room before it is back at home. A death
## puts every platform back at once, so this is only ever felt by somebody still
## alive: it is what turning round and going back costs.
@export var platform_return_time: float = 0.8
## How far the warning shake throws the slab sideways, in design px. Small: it
## is a tremor and not a wobble, and it has to read at 40 px without the slab
## appearing to leave its own socket.
@export var platform_shake: float = 1.5
## How fast that shake oscillates, in Hz. Fast enough to read as unstable rather
## than as something being moved on purpose.
@export var platform_shake_hz: float = 16.0

@export_group("Moving platforms")
## How fast a ferry crosses, px/s. The number the hazard is made of: it decides
## how long a moat is shut for, and therefore what missing the boat costs.
##
## Deliberately a little over half a run, so a ferry is plainly slower than you
## are and catching one is never a chase. How long a crossing takes is derived
## from this and the span the room gave it, because a travel time in here would
## go stale the moment a room made a moat wider.
@export var platform_travel_speed: float = 110.0
## Seconds a ferry waits at each end before setting off again.
##
## This is the window you board in, and it is why a ferry docks rather than
## turning round on the spot. It is set by the harder of the two boardings on the
## M3 bench: a respawn has to be able to run at the ferry and jump onto it before
## it leaves, and at half a second it could not. What a player who misses that
## window waits is one trip out and one back, which is the number to keep an eye
## on if this grows.
@export var platform_wait_time: float = 0.7

@export_group("Geysers")
## Seconds of warning before a geyser lifts anything, and the one number in the
## group that is purely about fairness. A column that arrived with no tell would
## be a thing you learn by dying, which is the 1984 complaint SPEC.md exists to
## throw away.
##
## Read against the falling platform's warning, which is the other tell in M3 and
## sits at 0.45. This one is a little longer because what it is warning you about
## is worth crossing a room for rather than worth stepping off, and because a
## respawn lands in the first frame of it: see `GeyserCycle`.
@export var geyser_swell_time: float = 0.5
## Seconds the column stays up. The window, and therefore the whole hazard: it
## has to outlast a ride by enough that arriving part of the way through one is
## still worth doing, or the only boarding anybody makes is from a standing start
## at the vent.
@export var geyser_erupt_time: float = 1.4
## Seconds of quiet between eruptions. What missing one costs, along with the
## swell that follows it, and therefore the number to watch if this grows: M3's
## second done-when is that dying twenty times is annoying rather than tedious,
## and a wait you did not choose is how that goes wrong.
@export var geyser_dormant_time: float = 1.1
## How fast the column carries you, px/s.
##
## Deliberately well under the hero's own takeoff speed, so a ride reads as being
## carried rather than as a jump somebody else is doing for you. It is the number
## that decides how much of an eruption a storey costs, and the room's ledges are
## laid out against what it buys.
@export var geyser_lift_speed: float = 170.0
