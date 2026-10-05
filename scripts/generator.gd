## Act 3's boss (`SPEC.md` → *Conduct*). It cannot be hit by a sword: a sword
## thrown at it breaks on it like stone. Its current runs out along a broken
## loop of copper and comes back to a socket wired into it, and bridging every
## break at once closes the loop and shorts it out, for good.
##
## Until then it throws arcs. Each is taken at where the hero stood when it
## finished charging (`GeneratorCycle`), marked, then struck, so standing still
## to throw is the risk and moving is the answer. Live, its casing kills on
## contact like any live metal.
class_name Generator
extends Node2D

signal shorted

const SPRITE_SCENE: PackedScene = preload("res://scenes/generator_sprite.tscn")
## Where the horn tips sit in the sprite, from its base centre. The arc between
## them is code (`ArcBolt`), not paint, per `CLAUDE.md`.
const HORN_LEFT := Vector2(-19.0, -64.0)
const HORN_RIGHT := Vector2(20.0, -64.0)
## The shake when it shorts: art px, and how long it takes to settle. One of
## the two things `ART_DIRECTION.md` allows a shake at all.
const SHORT_SHAKE: float = 4.0
const SHORT_SHAKE_SECONDS: float = 0.6

var enemy_config: EnemyConfig
var is_shorted := false
## Its clock waits until the hero is past this x, so a room can be looked at
## from its door before the first arc.
var wake_x := -INF
## The casing, in the room's coordinates.
var rect := Rect2()

var _out: Conductor
var _clock := 0.0
var _awake := false
var _arc_index := -1
var _target := Vector2.ZERO
var _phase: GeneratorCycle.Phase = GeneratorCycle.Phase.REST
var _arc: ArcBolt
var _hum: ArcBolt
var _sprite: Node2D


## `out` is the copper its current leaves along, a source until it shorts.
## `back` is the socket the loop returns to.
func configure(area: Rect2, out: Conductor, back: CurrentSwitch, config: EnemyConfig) -> void:
	rect = area
	_out = out
	enemy_config = config
	back.held_changed.connect(_on_loop_closed)
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = area.size
	shape.shape = box
	body.position = area.get_center()
	body.add_child(shape)
	add_child(body)
	_sprite = SPRITE_SCENE.instantiate() as Node2D
	_sprite.position = Vector2(area.get_center().x, area.end.y)
	add_child(_sprite)
	_sprite_tree()["parameters/playback"].travel("idle")
	_hum = ArcBolt.new()
	add_child(_hum)
	_hum.setup(_sprite.position + HORN_LEFT, _sprite.position + HORN_RIGHT)
	add_to_group("mechanisms")
	add_to_group("generators")


func _physics_process(delta: float) -> void:
	if is_shorted:
		return
	var player := _player()
	if not _awake:
		if player == null or player.global_position.x < wake_x:
			return
		_awake = true
	_clock += delta
	var rest := enemy_config.generator_rest_time
	var warning := enemy_config.generator_warning_time
	var strike := enemy_config.generator_strike_time
	var phase := GeneratorCycle.phase_at(_clock, rest, warning, strike)
	var index := GeneratorCycle.arc_index(_clock, rest, warning, strike)
	if phase == GeneratorCycle.Phase.WARNING and index != _arc_index and player != null:
		_arc_index = index
		_target = player.global_position
	if phase != _phase:
		_phase = phase
		_show_arc(phase == GeneratorCycle.Phase.STRIKING)
		if phase == GeneratorCycle.Phase.STRIKING:
			Sfx.play(self, Sfx.CONFIG.zap)
		queue_redraw()
	if player == null:
		return
	var hero := _hero_rect(player)
	if hero.intersects(rect.grow(Conductor.TOUCH)):
		player.die()
	elif phase == GeneratorCycle.Phase.STRIKING and hero.intersects(strike_box()):
		player.die()


## Where the arc lands this time, as a killing box.
func strike_box() -> Rect2:
	var size := enemy_config.generator_strike_size
	return Rect2(_target - size * 0.5, size)


## Back to the start of its clock, which is rest. Called on every respawn.
func reset(_frozen_for: float) -> void:
	if is_shorted:
		return
	# Asleep again until the hero comes back past `wake_x`, which is later than
	# any respawn freeze, so the freeze needs no clock of its own here.
	_awake = false
	_clock = 0.0
	_arc_index = -1
	_phase = GeneratorCycle.Phase.REST
	_show_arc(false)
	queue_redraw()


func status() -> String:
	if is_shorted:
		return "generator SHORTED"
	return "generator live, %s" % GeneratorCycle.Phase.keys()[_phase]


func _on_loop_closed(held: bool) -> void:
	if not held or is_shorted:
		return
	is_shorted = true
	_out.is_source = false
	_show_arc(false)
	_hum.queue_free()
	Burst.emit(get_parent(), global_position, Burst.Kind.ARC_SPARKS)
	Burst.emit(get_parent(), global_position, Burst.Kind.SPARKS)
	Shake.kick(self, SHORT_SHAKE, SHORT_SHAKE_SECONDS)
	Sfx.play(self, Sfx.CONFIG.short)
	# Burnt out, through its AnimationTree like every state.
	_sprite_tree()["parameters/playback"].travel("dead")
	queue_redraw()
	shorted.emit()


func _show_arc(on: bool) -> void:
	if _arc != null:
		_arc.queue_free()
		_arc = null
	if not on:
		return
	_arc = ArcBolt.new()
	add_child(_arc)
	_arc.setup(_sprite.position + (HORN_LEFT + HORN_RIGHT) * 0.5, _target, _arc_index + 1)


## The warning: the box the arc will strike, drawn in residue blue.
func _draw() -> void:
	if is_shorted or _phase != GeneratorCycle.Phase.WARNING:
		return
	draw_rect(strike_box(), Palette.ARC_RESIDUE, false, 1.0)
	var box := strike_box()
	draw_line(Vector2(box.get_center().x, box.position.y), Vector2(box.get_center().x, box.end.y), Palette.ARC_RESIDUE, 1.0)


func _sprite_tree() -> AnimationTree:
	return _sprite.get_node("AnimationTree") as AnimationTree


func _player() -> Player:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null and not player.is_dead():
			return player
	return null


func _hero_rect(player: Player) -> Rect2:
	var world: WorldConfig = player.world
	var size := Vector2(world.hero_width, world.hero_height)
	return Rect2(player.global_position - size * 0.5, size)
