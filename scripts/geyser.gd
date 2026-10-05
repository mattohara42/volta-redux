## A column of scalding water that comes up on a schedule and takes you with it.
##
## The clock and every transition in it live in `GeyserCycle`, where a headless
## test can reach them. This script is the part that cannot be pure: it senses
## who is standing in the column, it hands the hero a vertical speed, and it
## draws.
##
## It is an `Area2D` and not a body, because a jet is something you are inside
## rather than something you stand on. That makes it the one mechanism in M3 with
## no collision shape you can rest against, and the reason `Platform` is not its
## parent class despite the two sharing a respawn contract.
##
## **It never kills.** `Hazard` is the only script in the repo that does, and
## this one is not it. What a geyser does is put you somewhere, and in the bench
## the somewhere is either a ledge you could not otherwise reach or, if you
## misread the clock, the lava it rises out of.
class_name Geyser
extends Area2D

## How tall the collar around the mouth of the vent is drawn, in design px.
const VENT_HEIGHT: float = 6.0
## How many gold notches the collar carries. ART_DIRECTION.md: a mechanism has to
## read as a mechanism before it is used, and a dormant geyser is a hole in the
## floor until something says otherwise.
const VENT_NOTCHES: int = 4
const ATMOSPHERE: AtmosphereConfig = preload("res://config/atmosphere.tres")
const STEAM: Shader = preload("res://shaders/steam.gdshader")
## How thick the head of the jet is drawn at the top of the column.
const CROWN_HEIGHT: float = 5.0
## How visible the reach marks are when nothing is erupting. Enough to read from
## across a room and not enough to be mistaken for the jet itself.
const REACH_ALPHA: float = 0.34
## The dashes those marks are made of, in design px: how long each is and how
## far apart they sit. Dashed rather than solid, because a pair of solid lines
## up the sides of a shaft reads as a thing you could stand on.
const REACH_DASH: float = 5.0
const REACH_GAP: float = 12.0

## Read by the overlay and by `tools/capture.gd`. What it is doing now.
var phase: GeyserCycle.Phase = GeyserCycle.Phase.SWELL
## The numbers its clock is made of, out of `config/hazards.tres`.
var config: HazardConfig

## The column, which is the room's to decide: how high a jet reaches and how wide
## the shaft is are facts about the place it was dug, the same way a ferry's span
## is a fact about the moat. This script knows what a geyser does, not where.
var _size := Vector2.ZERO
## Seconds since the room started. A geyser has no trigger, so like a ferry this
## begins at zero and never stops.
var _elapsed: float = 0.0
## The jet itself, billowing (`shaders/steam.gdshader`), shown while it is up,
## and the cool light it gives the dark around it.
var _jet: ColorRect
var _glow: LightSource


func configure(size: Vector2, hazards: HazardConfig) -> void:
	_size = size
	config = hazards
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = size
	shape.shape = box
	add_child(shape)
	# The player is layer 3 (`collision_layer = 4` in player.tscn) and is the only
	# thing this watches. A thrown sword crossing a jet is not something to lift:
	# SPEC.md gives the sword a flight of its own and a geyser is not in it.
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	# Before the hero, so the speed it hands over is read in the same physics step
	# it was written in. The hero spends the lift and clears it inside its own
	# step, so a geyser that ran afterwards would always be a frame late and the
	# rise would be a frame of gravity short of the number in the config.
	process_physics_priority = -1
	add_to_group("geysers")
	# Everything a respawn puts back at the start of its clock. Platforms are in
	# here too: see `Player._place_at_checkpoint`.
	add_to_group("mechanisms")
	_make_jet()


## ART_DIRECTION.md puts soft edges on everything that is not a shape the
## player has to read hard, and a column of water is the softest thing in the
## game, so the jet is a shader rather than flat bars. Behind the vent's collar,
## which is drawn by `_draw` over it.
func _make_jet() -> void:
	var rect := Rect2(-_size * 0.5, _size)
	var material := ShaderMaterial.new()
	material.shader = STEAM
	material.set_shader_parameter("body", Palette.STEAM_BODY)
	material.set_shader_parameter("core", Palette.STEAM_CORE)
	material.set_shader_parameter("warm", Palette.FIRE_FALLOFF)
	material.set_shader_parameter("size", _size)
	material.set_shader_parameter("rise_speed", ATMOSPHERE.steam_rise_speed)
	material.set_shader_parameter("warm_reach", ATMOSPHERE.steam_warm_reach)
	material.set_shader_parameter("edge_alpha", ATMOSPHERE.steam_edge_alpha)
	material.set_shader_parameter("steps", ATMOSPHERE.steam_steps)
	material.set_shader_parameter("crown", CROWN_HEIGHT)
	material.set_shader_parameter("seed", fmod(absf(global_position.x) * 0.013, 1.0))
	_jet = ColorRect.new()
	_jet.position = rect.position
	_jet.size = rect.size
	_jet.material = material
	_jet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_jet.show_behind_parent = true
	add_child(_jet)
	_glow = LightSource.line(
		Vector2(0.0, rect.end.y), Vector2(0.0, rect.position.y),
		ATMOSPHERE.light_steam_radius, Palette.STEAM_CORE, ATMOSPHERE.light_steam_strength
	)
	add_child(_glow)
	_show_jet()


func _show_jet() -> void:
	var up := phase == GeyserCycle.Phase.ERUPTING
	if _jet != null:
		_jet.visible = up
		_glow.visible = up


func _physics_process(delta: float) -> void:
	if config == null:
		return
	_elapsed += delta
	var was := phase
	phase = GeyserCycle.phase_at(
		_elapsed, config.geyser_swell_time, config.geyser_erupt_time,
		config.geyser_dormant_time
	)
	if GeyserCycle.lifts(phase):
		for body in get_overlapping_bodies():
			var player := body as Player
			if player != null:
				player.lift(config.geyser_lift_speed)
	# The swell is the only phase that changes what is on screen from one frame to
	# the next, because the tell ramps up across it. The column is the same
	# picture for as long as it is up.
	if phase != was or phase == GeyserCycle.Phase.SWELL:
		queue_redraw()
		_show_jet()
	if phase != was and phase == GeyserCycle.Phase.ERUPTING:
		# Spray thrown off the head of the jet as it arrives.
		Burst.emit(get_parent(), global_position - Vector2(0.0, _size.y * 0.5), Burst.Kind.SPRAY)
		Sfx.play(self, Sfx.CONFIG.geyser, true)


## Back to the first frame of the swell, with the freeze the respawn still owes
## the player spent before the clock starts rather than out of it.
##
## The same bargain `Platform.reset` makes and for the same reason: a death costs
## you the climb you missed and nothing else. Left running, a respawn would hand
## you a vent that has just gone quiet, and the first thing you would do with
## your restored controls is stand on it and wait. That is the wait that turns
## dying twenty times from annoying into tedious, and M3's done-when is about
## exactly it.
##
## Called through the "mechanisms" group, so the signature has to match
## `Platform.reset`.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	phase = GeyserCycle.Phase.SWELL
	queue_redraw()
	_show_jet()


func status() -> String:
	return GeyserCycle.phase_name(phase)


## How big the lifting box is, kept so a running build can say it. The column is
## the one part of this that a screenshot cannot be trusted about, for the reason
## a spike bed's killing box cannot: see `tools/capture.gd`.
func column() -> Vector2:
	return _size


## Cool, pale and soft, which is ART_DIRECTION.md's steam and is chosen to say
## the one thing about a geyser that matters at a glance: it does not kill you.
## Warm and saturated is reserved for what does, and a jet painted in lava's
## register would be a lie a player reads in peripheral vision and acts on.
##
## **The drawn column and the lifting box are the same rectangle.** A tapered jet
## would look better and would put the box outside the picture at the top, which
## is the mistake spikes are careful about in the other direction. So the jet's
## shader billows inside the box and fills all of it at least faintly.
func _draw() -> void:
	var rect := Rect2(-_size * 0.5, _size)
	# While the jet is up it shows its own reach (`_jet`); the marks are for
	# reading how far it will go before it goes.
	if phase != GeyserCycle.Phase.ERUPTING:
		_draw_reach(rect)
	if phase == GeyserCycle.Phase.SWELL:
		_draw_swell(rect)
	_draw_vent(rect)


## How far the jet goes when it goes, drawn whether or not it is up.
##
## The ferry's rail is the only thing in that room that says where the slab will
## be in a second, and this is the same sentence: a player deciding whether to
## walk off a lip has to be able to read how high the thing they are stepping
## into will carry them, at a moment when there is nothing on screen to measure.
func _draw_reach(rect: Rect2) -> void:
	var faint := Color(Palette.STEAM_BODY, REACH_ALPHA)
	for x in [rect.position.x, rect.end.x - 1.0]:
		var y := rect.position.y
		while y < rect.end.y:
			draw_rect(Rect2(x, y, 1.0, minf(REACH_DASH, rect.end.y - y)), faint)
			y += REACH_GAP
	# The one solid mark, across the top. How high the jet reaches is the fact a
	# player standing at a lip is deciding on, and it is the only one of these a
	# dashed line would make them measure rather than read.
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2.0)), faint)


## The tell. A mound at the mouth that grows across the warning, so the sentence
## it says is "this is about to go" rather than "something is happening".
func _draw_swell(rect: Rect2) -> void:
	var ramp := GeyserCycle.swell_ramp(
		_elapsed, config.geyser_swell_time, config.geyser_erupt_time,
		config.geyser_dormant_time
	)
	if ramp <= 0.0:
		return
	var mound := VENT_HEIGHT * 3.0 * ramp
	draw_rect(
		Rect2(rect.position.x, rect.end.y - mound, rect.size.x, mound),
		Color(Palette.STEAM_BODY, 0.30 + 0.35 * ramp)
	)
	# Spurts ahead of the column, which is what a geyser does before it goes and
	# is the part that reads from across a room.
	var step := rect.size.x / 4.0
	for i in 3:
		var x := rect.position.x + step * (float(i) + 1.0)
		var reach := mound * (1.6 + 0.5 * float(i % 2))
		draw_line(
			Vector2(x, rect.end.y), Vector2(x, rect.end.y - reach),
			Color(Palette.STEAM_CORE, 0.45 * ramp), 1.0
		)


## The mouth. Cold stone with gold on it, which is ART_DIRECTION.md's rule that a
## mechanism says what it wants before it is used: a vent with nothing coming out
## of it has to still read as a way up rather than as a hole.
func _draw_vent(rect: Rect2) -> void:
	var collar := Rect2(rect.position.x, rect.end.y - VENT_HEIGHT, rect.size.x, VENT_HEIGHT)
	draw_rect(collar, Palette.STONE_DEEP)
	var step := collar.size.x / float(VENT_NOTCHES)
	for i in VENT_NOTCHES:
		draw_rect(
			Rect2(collar.position.x + step * float(i) + step * 0.25, collar.position.y,
				step * 0.5, 2.0),
			Palette.GOLD_FACE
		)
