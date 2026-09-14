## What the two kinds of platform have in common.
##
## A platform is a solid that moves under a clock of its own and carries whatever
## is standing on it while it goes. The two in M3 differ only in what that clock
## says: one waits to be stood on and then leaves for good, the other never stops
## and was never asking. `AnimatableBody2D` rather than `StaticBody2D` for both,
## because the engine only carries a rider on a body that is moved by code.
##
## The shared part is deliberately small. It is here because three things outside
## the platforms want to talk to one without knowing which kind it is: the hero
## on a respawn, the debug overlay, and `tools/capture.gd`. The alternative was
## the same cast to a concrete class in all three, growing an `or` every time a
## kind of platform is added.
class_name Platform
extends AnimatableBody2D

## The numbers its clock is made of. Both kinds read `config/hazards.tres`.
var config: HazardConfig

var _size := Vector2.ZERO
## Where the room put it. Every offset either kind of platform applies is
## relative to this, so "home" is a fact about the room and not about the clock.
var _home := Vector2.ZERO
var _shape: CollisionShape2D


## The body every platform is: a box of the size the room asked for, moved by
## code rather than by physics. Subclasses call this and then add whatever their
## own clock needs.
func _build(size: Vector2, hazards: HazardConfig) -> void:
	_size = size
	config = hazards
	sync_to_physics = true
	_shape = CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	_shape.shape = box
	add_child(_shape)
	add_to_group("platforms")
	# Everything a respawn puts back at the start of its clock, geysers included.
	# See `Player._place_at_checkpoint`.
	add_to_group("mechanisms")


func _ready() -> void:
	_home = position


## Back to the start of its clock, now, with no part of the cycle left to run.
##
## Called by the player on a respawn. M3's bargain is that a death costs you the
## jump you missed and nothing else, and a route still missing a step, or a ferry
## still out in the middle of the moat, is a second cost. That is the wait that
## turns dying twenty times from annoying into tedious.
##
## `frozen_for` is how long the player still cannot move, which is
## `DeathConfig.respawn_freeze`: a respawn puts the body down before it hands the
## controls back. A platform whose clock is free running has to sit out that gap
## as well, or a third of the window it offers has already gone by the time
## anybody can run at it. Measured on this bench before it was fixed, the second
## ferry left 2 frames before a respawn could reach the lip, every time. A
## platform that is parked until something touches it has nothing to sit out and
## ignores this.
func reset(frozen_for: float) -> void:
	pass


## One word for the debug overlay and for `tools/capture.gd`. A platform's whole
## content is a clock, and a clock is the one thing a screenshot cannot show: a
## slab at home and a slab one frame from letting go are the same picture.
func status() -> String:
	return "platform"
