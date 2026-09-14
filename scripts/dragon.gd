## SPEC.md's fire-breathing dragon: an Act 2 mini-boss, telegraphed cone,
## immobile. The two bosses are both anti-sword on purpose, and this one's
## answer is already sitting in `SwordFlight`: a recalling sword steers
## through geometry and "cannot fail", so a hit that arrives while a sword is
## RECALLING is immune to whatever stopped it getting there. `is_vulnerable_to`
## just says so. Nothing in the sword's own machine changes, the same way
## nothing changed there for the eyeball.
##
## That makes the whole fight a positioning puzzle rather than a new system:
## a FLYING or RETURNING sword bounces off the body like hitting stone (fresh
## ammunition, SPEC.md's mistake), and the only sword that gets through is one
## already embedded in wood past the dragon and called home, which the room
## has to make possible without ever asking the player to throw through the
## body to get there.
##
## The breath is the second half: a ranged reason to keep your distance, on
## its own clock (`DragonBreath`), so panicking and closing in to throw is
## also the wrong answer.
class_name Dragon
extends Enemy

var _config: EnemyConfig
var _elapsed: float = 0.0
var _breath_offset := Vector2.ZERO
var _breath_size := Vector2.ZERO
var phase: DragonBreath.Phase = DragonBreath.Phase.CHARGE

## Built in `place`, not with `@onready`: this node is often configured
## before it is ever added to the tree (see `Bench._add_dragon`), and
## `@onready` would not run until then. `Hazard.configure` and `Geyser.configure`
## make the same choice for the same reason.
var _breath: Area2D


## `breath_offset` is where the cone sits relative to the dragon's own centre,
## and its sign is the only place this file says which way the dragon faces:
## the room places it, the way a ferry's span decides which way a slab goes.
func place(size: Vector2, breath_offset: Vector2, breath_size: Vector2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_config = enemy_config
	_breath_offset = breath_offset
	_breath_size = breath_size
	_breath = _make_breath_area()
	_breath.position = breath_offset
	var shape := _breath.get_child(0) as CollisionShape2D
	(shape.shape as RectangleShape2D).size = breath_size
	add_to_group("mechanisms")


func _make_breath_area() -> Area2D:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	area.add_child(shape)
	# The player's own layer, per `Hazard.configure`. Not monitorable: nothing
	# needs to find the breath itself, only to be found by it.
	area.collision_layer = 0
	area.collision_mask = 4
	add_child(area)
	return area


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_update()


func _update() -> void:
	var was := phase
	phase = DragonBreath.phase_at(
		_elapsed, _config.dragon_charge_time, _config.dragon_breathe_time, _config.dragon_rest_time
	)
	if DragonBreath.is_lethal(phase):
		for body in _breath.get_overlapping_bodies():
			var player := body as Player
			if player != null:
				player.die()
	if phase != was or phase == DragonBreath.Phase.CHARGE:
		queue_redraw()


## Back to the first frame of the tell, the same bargain `Geyser.reset` makes
## and for the same reason: a respawn that landed mid-breath would be a death
## nobody could have seen coming, which is the punishment M3 exists to remove.
func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "dragon %s" % DragonBreath.phase_name(phase)


## The one override that makes this a boss rather than a fifth animal: a
## FLYING or RETURNING sword is fresh ammunition and bounces, per SPEC.md. Only
## a sword already RECALLING gets through, because a recall cannot fail.
func is_vulnerable_to(sword: Node2D) -> bool:
	var blade := sword as Sword
	return blade != null and blade.state == SwordFlight.State.RECALLING


## A big, low silhouette with a snout pointed the way the breath goes, so the
## body reads as something that faces a direction before the cone ever proves
## it. The cone itself is drawn as the same rectangle that kills, the way a
## geyser's column is: brightening through the charge and full at the breath,
## in `FIRE_*` rather than lava's palette, because this is flame and not rock.
func _draw() -> void:
	var half := killing_box * 0.5
	draw_rect(Rect2(-half, killing_box), Palette.ENEMY_CHITIN)
	var facing := signf(_breath_offset.x) if not is_zero_approx(_breath_offset.x) else 1.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(facing * half.x, -half.y * 0.4),
		Vector2(facing * (half.x + 20.0), 0.0),
		Vector2(facing * half.x, half.y * 0.4),
	]), Palette.ENEMY_CHITIN)
	_draw_breath()


func _draw_breath() -> void:
	var rect := Rect2(_breath_offset - _breath_size * 0.5, _breath_size)
	match phase:
		DragonBreath.Phase.BREATHING:
			draw_rect(rect, Palette.FIRE_CORE)
			draw_rect(
				Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.35)), Palette.FIRE_HOT
			)
		DragonBreath.Phase.CHARGE:
			var ramp := DragonBreath.charge_ramp(
				_elapsed, _config.dragon_charge_time, _config.dragon_breathe_time,
				_config.dragon_rest_time
			)
			draw_rect(rect, Color(Palette.FIRE_FALLOFF, 0.15 + 0.5 * ramp))
		_:
			pass
