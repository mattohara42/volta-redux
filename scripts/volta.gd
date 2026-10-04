## Volta (`SPEC.md` → *Act 4*). He cannot be beaten by throwing: he stands out
## of reach on his dais and the dragon finishes him. Until then he casts on
## `GeneratorCycle`'s clock. Most casts are bolts at wherever the hero stood
## when the warning began, like the generator's arcs; every
## `volta_pull_every`th is a pull (`VoltaRules`), which tears every embedded
## sword in the room out of its wall and throws it toward him, breaking
## whatever circuit it was part of. Touching him kills.
##
## His sprite (`scenes/volta_sprite.tscn`) faces left, toward the hero, and
## its AnimationTree is told which of idle, cast and fall to show.
class_name Volta
extends Node2D

signal fallen

const SPRITE_SCENE: PackedScene = preload("res://scenes/volta_sprite.tscn")
## His body, robe hem to crown, for touching him. The staff is not part of it.
const SIZE := Vector2(28.0, 52.0)
## The orb on his staff, from his feet: where every bolt leaves from.
const HAND := Vector2(-16.0, -48.0)
## How long the fall into the fire takes, seconds. Presentation, not tuning.
const FALL_TIME: float = 0.8

var enemy_config: EnemyConfig
var is_defeated := false
## Stopped casting: the chains are off and the dragon is turning on him.
var is_stopped := false
## His feet, in the room's coordinates.
var base := Vector2.ZERO
## His clock waits until the hero is past this x.
var wake_x := -INF

var _clock := 0.0
var _awake := false
var _cast_index := -1
var _target := Vector2.ZERO
var _phase: GeneratorCycle.Phase = GeneratorCycle.Phase.REST
var _bolt: ArcBolt
var _sprite: Node2D


func configure(feet: Vector2, config: EnemyConfig) -> void:
	base = feet
	enemy_config = config
	_sprite = SPRITE_SCENE.instantiate() as Node2D
	_sprite.position = feet
	add_child(_sprite)
	add_to_group("mechanisms")
	add_to_group("volta")
	queue_redraw()


func rect() -> Rect2:
	return Rect2(base - Vector2(SIZE.x * 0.5, SIZE.y), SIZE)


func _physics_process(delta: float) -> void:
	if is_defeated or is_stopped:
		return
	var player := _player()
	if not _awake:
		if player == null or player.global_position.x < wake_x:
			return
		_awake = true
	_clock += delta
	var rest := enemy_config.volta_rest_time
	var warning := enemy_config.volta_warning_time
	var strike := enemy_config.volta_strike_time
	var phase := GeneratorCycle.phase_at(_clock, rest, warning, strike)
	var index := GeneratorCycle.arc_index(_clock, rest, warning, strike)
	if phase == GeneratorCycle.Phase.WARNING and index != _cast_index and player != null:
		_cast_index = index
		_target = player.global_position
	if phase != _phase:
		_phase = phase
		_travel("idle" if phase == GeneratorCycle.Phase.REST else "cast")
		if phase == GeneratorCycle.Phase.STRIKING and _pulling():
			_pull()
		_show_bolt(phase == GeneratorCycle.Phase.STRIKING and not _pulling())
		queue_redraw()
	if player == null:
		return
	var hero := _hero_rect(player)
	if hero.intersects(rect().grow(1.0)):
		player.die()
	elif phase == GeneratorCycle.Phase.STRIKING and not _pulling() and hero.intersects(strike_box()):
		player.die()


func strike_box() -> Rect2:
	var size := enemy_config.volta_strike_size
	return Rect2(_target - size * 0.5, size)


## The moment the chains let go: no more casts, and no bolt left in the air.
func stop() -> void:
	is_stopped = true
	_phase = GeneratorCycle.Phase.REST
	_travel("idle")
	_show_bolt(false)
	queue_redraw()


## Into the fire below him: he drops to `pit_floor` and is gone.
func fall_into(pit_floor: float) -> void:
	if is_defeated:
		return
	is_defeated = true
	_show_bolt(false)
	_travel("fall")
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "position:y", pit_floor - base.y + SIZE.y, FALL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		visible = false
		fallen.emit()
	)


func reset(_frozen_for: float) -> void:
	if is_defeated or is_stopped:
		return
	_awake = false
	_clock = 0.0
	_cast_index = -1
	_phase = GeneratorCycle.Phase.REST
	_travel("idle")
	_show_bolt(false)
	queue_redraw()


func status() -> String:
	if is_defeated:
		return "volta DEFEATED"
	return "volta casting #%d, %s%s" % [_cast_index, GeneratorCycle.Phase.keys()[_phase], " (pull)" if _pulling() else ""]


func _pulling() -> bool:
	return _cast_index >= 0 and VoltaRules.is_pull(_cast_index, enemy_config.volta_pull_every)


func _pull() -> void:
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword != null and sword.state == SwordFlight.State.EMBEDDED:
			sword.yank(base.x, enemy_config.volta_pull_speed)


func _hand() -> Vector2:
	return base + HAND


func _travel(state: String) -> void:
	(_sprite.get_node("AnimationTree") as AnimationTree)["parameters/playback"].travel(state)


func _show_bolt(on: bool) -> void:
	if _bolt != null:
		_bolt.queue_free()
		_bolt = null
	if not on:
		return
	_bolt = ArcBolt.new()
	add_child(_bolt)
	_bolt.setup(_hand(), _target, _cast_index + 1)


## During a bolt's warning the box it will strike is marked; during a pull's
## warning his staff's orb swells.
func _draw() -> void:
	if is_defeated or is_stopped or _phase != GeneratorCycle.Phase.WARNING:
		return
	if _pulling():
		draw_circle(_hand(), 5.0, Palette.ARC_CORE)
		return
	var box := strike_box()
	draw_rect(box, Palette.ARC_RESIDUE, false, 1.0)
	draw_line(Vector2(box.get_center().x, box.position.y), Vector2(box.get_center().x, box.end.y), Palette.ARC_RESIDUE, 1.0)


func _player() -> Player:
	for node in get_tree().get_nodes_in_group("player"):
		var player := node as Player
		if player != null and not player.is_dead():
			return player
	return null


func _hero_rect(player: Player) -> Rect2:
	var size := Vector2(player.world.hero_width, player.world.hero_height)
	return Rect2(player.global_position - size * 0.5, size)
