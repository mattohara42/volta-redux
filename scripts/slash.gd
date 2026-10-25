## The slash: the sword that never leaves the hero's hand (`SPEC.md`, Matt,
## 2026-10-25). The hero owns it, a child that strikes when told.
##
## Not part of `Sword`. `CLAUDE.md` keeps every behaviour of the thrown sword
## in one machine, and this one is never thrown: it has no flight, no catch,
## no embed and no count, so putting it in that machine would be the special
## case the rule exists to stop.
##
## It watches the enemies layer and nothing else, and sits on no layer, so
## nothing that answers to a thrown sword (a switch's slot, wood, a chest, a
## barrier) ever sees it. What a cut does is the enemy's call
## (`Enemy.slashed`), the way a thrown sword's hit is.
##
## The look is a placeholder until the hero has a slash animation: he holds
## his throw pose while the blade sprite sweeps through the strike by
## transform (`ANIMATION.md`: objects move by transform).
class_name Slash
extends Area2D

const BLADE: Texture2D = preload("res://assets/art/hero/sword_px.png")
## Layer 6, the enemies (`Enemy.ENEMY_LAYER`).
const ENEMY_MASK: int = 1 << 5

var _config: SwordConfig
var _facing := 1.0
## Seconds since the last slash began. Starts past any recovery, so the first
## press always cuts.
var _elapsed := INF
var _hit: Array[Node] = []
var _box := CollisionShape2D.new()
var _blade := Sprite2D.new()


func setup(sword_config: SwordConfig) -> void:
	_config = sword_config
	collision_layer = 0
	collision_mask = ENEMY_MASK
	monitorable = false
	_box.shape = RectangleShape2D.new()
	add_child(_box)
	_blade.texture = BLADE
	# The hilt is the texture's left end: pivot there, so the blade swings
	# from the hand.
	_blade.centered = false
	_blade.offset = Vector2(0.0, -BLADE.get_height() * 0.5)
	_blade.visible = false
	add_child(_blade)


## Whether a slash may start now. The hero passes his own holds.
func ready_to_slash(somersaulting: bool, recovering: bool) -> bool:
	return SlashRules.can_slash(
		_elapsed, _config.slash_active, _config.slash_recovery, somersaulting, recovering
	)


## Strikes toward `facing` from a hero `hero_half_width` px wide each side.
func strike(facing: float, hero_half_width: float) -> void:
	_facing = facing
	_elapsed = 0.0
	_hit.clear()
	var rect := SlashRules.box(facing, hero_half_width, _config.slash_reach, _config.slash_height)
	(_box.shape as RectangleShape2D).size = rect.size
	_box.position = rect.get_center()
	_blade.position = Vector2(facing * hero_half_width, 0.0)
	_blade.visible = true
	_cut()


## A dead hero does not finish a cut.
func cancel() -> void:
	_elapsed = INF
	_blade.visible = false


func is_striking() -> bool:
	return SlashRules.is_striking(_elapsed, _config.slash_active)


func _physics_process(delta: float) -> void:
	if _config == null or _elapsed == INF:
		return
	_elapsed += delta
	if is_striking():
		_cut()
	else:
		_blade.visible = false


## Every enemy in the box is cut once a slash. Asked every striking frame,
## not on entry, so one already standing in the box when it opens is cut too.
func _cut() -> void:
	var angle := SlashRules.blade_angle(_elapsed, _config.slash_active, deg_to_rad(_config.slash_sweep_degrees))
	_blade.scale = Vector2(_facing, 1.0)
	_blade.rotation = angle * _facing
	for area in get_overlapping_areas():
		var enemy := area as Enemy
		if enemy == null or _hit.has(enemy):
			continue
		_hit.append(enemy)
		# From the hand, not the far end of the box: a scorpion faced from in
		# front is cut from in front however far the reach goes.
		enemy.slashed(_blade)

