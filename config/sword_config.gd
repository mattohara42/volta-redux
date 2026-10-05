## Every number that decides how the sword behaves.
##
## SPEC.md: the sword is the game. These are the numbers that decide whether a
## throw is a decision or a formality, so they get their own file and no script
## sets one.
class_name SwordConfig
extends Resource

@export_group("Flight")
## Outbound and return speed, px/s. One number: a sword that came back slower
## than it left would let you outrun your own throw.
@export var speed: float = 420.0
## How far it flies before it turns, px.
@export var max_range: float = 200.0
## How far it will travel on the way back before giving up and dropping, px.
## Above max_range, so standing still is always a catch and running away is not.
@export var max_return_distance: float = 300.0
## Visual only. A spinning sword makes its state readable at 40 px.
@export var spin_speed: float = 14.0

@export_group("Catching")
## The catch window. Distance from the sword to the player's centre at which a
## returning sword is back in your hand, px.
@export var catch_radius: float = 14.0
## How close you have to walk to a sword lying on the floor to pick it up, px.
@export var pickup_radius: float = 16.0
## Seconds between throws, so a held button is not an automatic weapon.
@export var throw_cooldown: float = 0.18

@export_group("Embed and recall")
## Recall speed, px/s. Its own number rather than `speed`, because a recall is a
## decision you make under pressure and how long it takes you to get the sword
## back is the cost of that decision.
@export var recall_speed: float = 380.0
## How long the throw button has to be held before every embedded sword comes
## home, seconds. Long enough that no throw tap reaches it.
@export var recall_hold_time: float = 0.35

@export_group("Dropping")
## A spent sword falls. It does not use the player's gravity: it is a thrown
## object, not a body, and it should not float like one.
@export var fall_gravity: float = 900.0
## Horizontal decay while falling, px/s^2. A missed sword should land near where
## it passed you, not sail to the end of the room.
@export var fall_drag: float = 600.0
@export var max_fall_speed: float = 500.0

@export_group("Ammunition")
## SPEC.md: three swords, cap five. Ten was the original's number and it is why
## no single throw mattered there.
@export var starting_swords: int = 3
@export var max_swords: int = 5
## What a sword chest tops you up to: the swords you own (in hand and out in the
## room) are brought up to this, never past it. Matt, 2026-10-03: early rooms
## resupply from a chest of three, later rooms from hidden swords or a mechanism.
@export var chest_fill: int = 3
## How far past its blade an embedded sword reaches for metal, px. This is what
## lets a sword thrown into an insulating seam touch the conductors either side.
@export var conduct_reach: float = 3.0

@export_group("Sound")
## BUILD_PLAN.md M15: "The throw, the catch, the embed and the recall need
## four distinguishable sounds, because the sword's state is information the
## player needs without looking." Rendered from code by `tools/synth/`, each
## built to differ from the other three in every way an ear sorts sounds;
## `assets/audio/README.md` says how.
@export var throw_sound: AudioStream
@export var catch_sound: AudioStream
@export var embed_sound: AudioStream
@export var recall_sound: AudioStream
## The rest of what a sword says, rendered with the four above
## (`tools/synth/`). `fly_sound` loops for as long as the sword is in the
## air and the engine pans it with the sword, which is how M15's done-when
## (play with the screen dimmed and still know where your sword is) is met.
@export var fly_sound: AudioStream
@export var break_sound: AudioStream
@export var clatter_sound: AudioStream
@export var fry_sound: AudioStream
