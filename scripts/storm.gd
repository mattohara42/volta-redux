## The storm over a room: rain driven across the foreground, and lightning
## behind the room that flashes over everything with a crack of thunder after
## it. Purely how it looks and sounds: nothing here changes what anything does.
##
## Volta's storm, so the flash is his colour (`Palette.ARC_CORE`), never a
## pure white (`ART_DIRECTION.md`). Out on the wall the whole painting behind
## the room lights up and the room in front of it goes to silhouette; inside
## the hall only the painting's windows do (`ActTiles.windows`), with a bolt
## in one of them, and they throw cold light into the room.
##
## Added by `Bench` to a room whose act names a storm (`ActConfig.storm`). When
## it strikes is `StormRules`; every number is `config/storm.tres`.
class_name Storm
extends Node2D

enum Kind { NONE, RAIN, WINDOWS }

const CONFIG: StormConfig = preload("res://config/storm.tres")
const AUDIO: AudioConfig = preload("res://config/audio.tres")
## Rain falls in front of the room and its dust, under the dark, so a torch
## lights the streaks near it.
const RAIN_Z := 95
## The flash goes over everything in the room, the dark and its lights
## included. The HUD lives on its own canvas layer and stays readable.
const FLASH_Z := LightField.Z + 2
## How far past the view the storm's rectangles reach, art px, as `LightField`.
const MARGIN := 16.0

var kind := Kind.NONE
var _rng := RandomNumberGenerator.new()
var _windows: Array[Rect2] = []
var _until_strike := 0.0
## Seconds into the strike now showing, or below zero between strikes.
var _strike_t := -1.0
var _pulses := 1
var _thunder_in := -1.0
## The window the strike's bolt is seen through, and the bolt in it.
var _bolt_pane := -1
var _bolt: PackedVector2Array = []
var _fork: PackedVector2Array = []

var _sky: ColorRect
var _flash: ColorRect
var _rain: CPUParticles2D
var _panes: Node2D
var _lights: Array[LightSource] = []
var _thunder: AudioStreamPlayer


## `windows` are the painting's windows across the room, in room coordinates
## (`TileArt.painted_windows`). The storm is seeded by the room, so a room's
## strikes fall the same way every time it is entered.
func setup(storm_kind: Kind, windows: Array[Rect2], room_seed: int) -> void:
	kind = storm_kind
	_windows = windows
	_rng.seed = room_seed
	_until_strike = CONFIG.first_strike_seconds

	if kind == Kind.RAIN:
		# Over the painting, under everything the room builds on top of it:
		# `Bench` puts the storm first among the room's children.
		_sky = _cover(CanvasItemMaterial.BLEND_MODE_ADD)
		add_child(_sky)
		_rain = _make_rain()
		add_child(_rain)
	if not _windows.is_empty():
		_panes = Node2D.new()
		var glass := CanvasItemMaterial.new()
		glass.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_panes.material = glass
		_panes.draw.connect(_draw_panes)
		add_child(_panes)
		for pane in _windows:
			var light := LightSource.point(CONFIG.window_light_radius, Palette.ARC_CORE, 0.0)
			light.position = pane.get_center()
			add_child(light)
			_lights.append(light)
	_flash = _cover(CanvasItemMaterial.BLEND_MODE_MIX)
	_flash.z_index = FLASH_Z
	_flash.z_as_relative = false
	add_child(_flash)

	_thunder = AudioStreamPlayer.new()
	_thunder.stream = AUDIO.thunder
	_thunder.bus = Sfx.BUS
	_thunder.volume_db = CONFIG.thunder_volume_db
	add_child(_thunder)
	_show()


## Strikes now, whatever the clock says: for a capture that wants to see one.
func strike() -> void:
	_strike_t = 0.0
	_pulses = StormRules.pulses(_rng.randf(), CONFIG.pulses_max)
	_until_strike = StormRules.gap(_rng.randf(), CONFIG.strike_gap_min, CONFIG.strike_gap_max)
	_thunder_in = StormRules.gap(_rng.randf(), CONFIG.thunder_delay_min, CONFIG.thunder_delay_max)
	_choose_bolt()


func _process(delta: float) -> void:
	_until_strike -= delta
	if _until_strike <= 0.0:
		strike()
	elif _strike_t >= 0.0:
		_strike_t += delta
		if _strike_t > StormRules.length(_pulses, CONFIG.pulse_seconds, CONFIG.pulse_gap_seconds, CONFIG.afterglow_seconds):
			_strike_t = -1.0
	if _thunder_in >= 0.0:
		_thunder_in -= delta
		if _thunder_in < 0.0 and _thunder.stream != null:
			_thunder.pitch_scale = 1.0 + _rng.randf_range(-CONFIG.thunder_pitch_jitter, CONFIG.thunder_pitch_jitter)
			_thunder.play()
	_follow_the_view()
	_show()


## How bright the sky is this frame, 0 to 1.
func _sky_now() -> float:
	if _strike_t < 0.0:
		return 0.0
	return StormRules.sky(_strike_t, _pulses, CONFIG.pulse_seconds, CONFIG.pulse_gap_seconds, CONFIG.afterglow_seconds, CONFIG.gap_level)


func _show() -> void:
	var sky := _sky_now()
	var white := 0.0 if _strike_t < 0.0 else StormRules.whiteout(_strike_t, CONFIG.whiteout_hold_seconds, CONFIG.whiteout_fade_seconds)
	if _sky != null:
		_sky.color = Color(Palette.ARC_CORE, sky * CONFIG.sky_lift)
	_flash.color = Color(Palette.ARC_CORE, white * CONFIG.whiteout)
	_flash.visible = white > 0.0
	for light in _lights:
		light.strength = sky * CONFIG.window_light_strength
	if _panes != null:
		_panes.queue_redraw()


func _draw_panes() -> void:
	var sky := _sky_now()
	if sky <= 0.0:
		return
	var glass := Color(Palette.ARC_CORE, sky * CONFIG.pane_lift)
	for pane in _windows:
		_panes.draw_colored_polygon(StormRules.arch(pane), glass)
	# The bolt in the pulses and fading with the afterglow, but gone in the
	# gaps between pulses, which is what makes it read as a flicker. Its first
	# pulse is under the whiteout, so the afterglow is where it is seen.
	if sky > CONFIG.gap_level and _bolt.size() > 1:
		var bolt := Color(Palette.ARC_CORE, sky)
		_panes.draw_polyline(_bolt, bolt, 1.0)
		if _fork.size() > 1:
			_panes.draw_polyline(_fork, bolt, 1.0)


## One window in view takes this strike's bolt, top to bottom of its glass.
func _choose_bolt() -> void:
	_bolt = PackedVector2Array()
	_fork = PackedVector2Array()
	var view := _view()
	var seen: Array[int] = []
	for i in _windows.size():
		if _windows[i].intersects(view):
			seen.append(i)
	if seen.is_empty():
		return
	var pane := _windows[seen[_rng.randi_range(0, seen.size() - 1)]]
	var top := Vector2(pane.get_center().x + _rng.randf_range(-0.2, 0.2) * pane.size.x, pane.position.y + 2.0)
	var bottom := Vector2(pane.get_center().x + _rng.randf_range(-0.4, 0.4) * pane.size.x, pane.end.y)
	var seed_value := _rng.randi()
	var path := ArcPath.bolt(top, bottom, seed_value, CONFIG.bolt_subdivisions, CONFIG.bolt_jag)
	_bolt = StormRules.inside_arch(path, pane)
	if _rng.randf() < CONFIG.bolt_fork_chance:
		_fork = StormRules.inside_arch(ArcPath.fork(path, seed_value + 1, 0.35, CONFIG.bolt_subdivisions - 1, CONFIG.bolt_jag), pane)


func _make_rain() -> CPUParticles2D:
	var rain := CPUParticles2D.new()
	rain.z_index = RAIN_Z
	rain.z_as_relative = false
	rain.local_coords = false
	rain.texture = _streak()
	rain.particle_flag_align_y = true
	rain.amount = CONFIG.rain_amount
	var view := get_viewport_rect().size if is_inside_tree() else Vector2(640.0, 360.0)
	# Long enough to cross the whole view, so a streak is never seen to
	# appear in the middle of the air for want of time to fall from the top.
	rain.lifetime = (view.y + MARGIN * 2.0) / (CONFIG.rain_speed * (1.0 - CONFIG.rain_speed_spread))
	rain.preprocess = rain.lifetime
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var slant := deg_to_rad(CONFIG.rain_slant)
	var direction := Vector2(sin(slant), cos(slant))
	rain.direction = direction
	rain.spread = 2.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = CONFIG.rain_speed * (1.0 - CONFIG.rain_speed_spread)
	rain.initial_velocity_max = CONFIG.rain_speed * (1.0 + CONFIG.rain_speed_spread)
	var ramp := Gradient.new()
	var tint := Palette.STONE_LIT
	ramp.set_color(0, Color(tint, 0.0))
	ramp.set_color(1, Color(tint, 0.0))
	ramp.add_point(0.08, Color(tint, CONFIG.rain_alpha))
	ramp.add_point(0.92, Color(tint, CONFIG.rain_alpha))
	rain.color_ramp = ramp
	return rain


## One streak, one art px wide, fading toward its tail.
func _streak() -> ImageTexture:
	var length := maxi(int(CONFIG.rain_streak_length), 1)
	var image := Image.create(1, length, false, Image.FORMAT_RGBA8)
	for y in length:
		image.set_pixel(0, y, Color(1.0, 1.0, 1.0, float(y + 1) / length))
	return ImageTexture.create_from_image(image)


func _cover(blend: CanvasItemMaterial.BlendMode) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paint := CanvasItemMaterial.new()
	paint.blend_mode = blend
	rect.material = paint
	rect.color = Color(Palette.ARC_CORE, 0.0)
	return rect


## What the camera sees, in room coordinates, a margin wider all round.
func _view() -> Rect2:
	var view := get_viewport_rect().size
	var centre := view * 0.5
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		centre = camera.get_screen_center_position()
		view /= camera.zoom
	return Rect2(centre - view * 0.5, view).grow(MARGIN)


func _follow_the_view() -> void:
	var view := _view()
	for rect in [_sky, _flash]:
		if rect != null:
			rect.position = view.position.floor()
			rect.size = view.size.ceil()
	if _rain != null:
		# The streaks spawn across the view and up past its top, against the
		# wind, so they fall into it from where the wind brings them.
		var slant := tan(deg_to_rad(CONFIG.rain_slant))
		_rain.position = view.get_center() + Vector2(-view.size.y * slant * 0.5, -view.size.y * 0.5)
		_rain.emission_rect_extents = Vector2(view.size.x * 0.5 + absf(view.size.y * slant) * 0.5, view.size.y * 0.5)


## For the capture tool's log.
func status() -> String:
	return "storm: %s, next strike in %.1f s" % [Kind.keys()[kind].to_lower(), maxf(_until_strike, 0.0)]
