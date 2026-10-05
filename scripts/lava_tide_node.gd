## Lava that rises and falls over a passage on a clock (`LavaTide`, in
## `scripts/logic/`, holds the rule). It kills on contact like any lava, and it
## is a mechanism: a respawn puts its clock back to the start of a low tide.
##
## Its lava runs from the current level down past `low_y`, so it fills the
## passage when high and sits under the floor when low. The room draws the rock
## in front of it on a later layer, which is what hides it under the floor.
class_name LavaTideNode
extends Node2D

var phase: LavaTide.Phase = LavaTide.Phase.LOW
var config: HazardConfig

var _x := 0.0
var _width := 0.0
var _low_y := 0.0
var _high_y := 0.0
var _elapsed := 0.0
var _hazard: Hazard
var _surface: LavaSurface


## `span` is the x range it floods; it moves between `low_y` and `high_y`.
func configure(span: Vector2, low_y: float, high_y: float, hazards: HazardConfig) -> void:
	config = hazards
	_x = span.x
	_width = span.y - span.x
	_low_y = low_y
	_high_y = high_y
	var depth := Bench.ROOM_HEIGHT - high_y
	_hazard = Hazard.new()
	_hazard.configure(Vector2(_width, depth))
	_hazard.cause = DeathMessages.Cause.LAVA
	add_child(_hazard)
	_surface = LavaSurface.new()
	_surface.setup(Rect2(Vector2(_x, high_y), Vector2(_width, depth)))
	add_child(_surface)
	add_to_group("mechanisms")
	_place(_low_y)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	var t := maxf(_elapsed, 0.0)
	phase = LavaTide.phase_at(
		t, config.tide_low_time, config.tide_rise_time, config.tide_high_time, config.tide_fall_time
	)
	_place(LavaTide.level_at(
		t, config.tide_low_time, config.tide_rise_time, config.tide_high_time,
		config.tide_fall_time, _low_y, _high_y
	))


## Back to the start of a low tide. Called through the "mechanisms" group, so
## the signature matches `Platform.reset` and `Geyser.reset`.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	phase = LavaTide.Phase.LOW
	_place(_low_y)


func status() -> String:
	return LavaTide.Phase.keys()[phase]


func _place(level: float) -> void:
	var depth := Bench.ROOM_HEIGHT - _high_y
	_hazard.position = Vector2(_x + _width * 0.5, level + depth * 0.5)
	_surface.position = Vector2(_x, level)
