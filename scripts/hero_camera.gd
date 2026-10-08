## The camera that rides on the hero, leading the way they run
## (`CameraLead`). The room sets its limits (`Bench._frame_camera`).
class_name HeroCamera
extends Camera2D

@export var config: CameraConfig

var _lead := 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = config.smoothing_speed


func _physics_process(delta: float) -> void:
	# Pulled off the hero (the capture tool's overviews): nothing to lead.
	if top_level:
		return
	var hero := get_parent() as CharacterBody2D
	if hero == null:
		return
	_lead = CameraLead.step(
		_lead, hero.velocity.x, config.look_ahead, config.look_ahead_speed,
		config.look_ahead_min_speed, delta
	)
	position.x = _lead
