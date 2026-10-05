## Dust hanging in a room's air, drifting, catching whatever light there is.
## Under the room's dark (`LightField`), so a mote is only seen where a
## brazier, the lava or the copper lights it: the air near a light looks like
## air, and a corner nothing lights stays still.
##
## Follows the camera, leaving its motes where they are in the room, so they
## drift past as the view moves rather than travelling with it.
class_name Motes
extends CPUParticles2D

const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")
## Above everything in the room, below the dark.
const Z := 90


static func make(tint: Color) -> Motes:
	var motes := Motes.new()
	motes.z_index = Z
	motes.z_as_relative = false
	motes.local_coords = false
	motes.amount = CONFIG.motes_amount
	motes.lifetime = CONFIG.motes_lifetime
	motes.preprocess = CONFIG.motes_lifetime
	motes.emission_shape = EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(340.0, Bench.ROOM_HEIGHT * 0.5)
	motes.direction = Vector2(1.0, -0.3)
	motes.spread = 180.0
	motes.initial_velocity_min = CONFIG.motes_drift * 0.25
	motes.initial_velocity_max = CONFIG.motes_drift
	motes.gravity = Vector2.ZERO
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(tint, 0.0))
	ramp.set_color(1, Color(tint, 0.0))
	ramp.add_point(0.3, Color(tint, 0.7))
	ramp.add_point(0.7, Color(tint, 0.7))
	motes.color_ramp = ramp
	return motes


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var centre := get_viewport_rect().size * 0.5
	if camera != null:
		centre = camera.get_screen_center_position()
	position = Vector2(centre.x, Bench.ROOM_HEIGHT * 0.5)
