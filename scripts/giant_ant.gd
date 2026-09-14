## SPEC.md's giant ant: walks walls and ceilings, ignores gravity. The mistake
## it punishes is assuming the floor is where the danger is, and `AntCrawl`
## carries the whole loop: a rectangle it walks the inside face of forever.
##
## `track` is in the room's coordinates directly, the way `Bat`'s box is
## relative to a centre: this node's own `position` is fully determined by
## where on the loop it currently is, so nothing else sets it.
class_name GiantAnt
extends Enemy

var _config: EnemyConfig
var _track := Rect2()
var _elapsed: float = 0.0


## See `Bat.place` for why this is not called `configure`.
func place(size: Vector2, track: Rect2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_track = track
	_config = enemy_config
	add_to_group("mechanisms")


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_update()


func _update() -> void:
	var distance := _elapsed * _config.ant_speed
	position = AntCrawl.position_at(distance, _track)
	var normal := AntCrawl.surface_normal_at(distance, _track)
	rotation = normal.angle() + PI * 0.5
	queue_redraw()


func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "ant"


## Drawn in the node's own frame, where "down" is always toward whatever
## surface it is walking, so the rotation set in `_update` is the whole trick:
## the same six-legged shape reads as upside down on the ceiling without this
## file knowing what a ceiling is.
func _draw() -> void:
	var half := killing_box * 0.5
	draw_rect(Rect2(-half, killing_box), Palette.ENEMY_CHITIN)
	var leg_span := half.x * 1.4
	for i in 3:
		var x := -half.x * 0.6 + half.x * 0.6 * float(i)
		draw_line(Vector2(x, half.y), Vector2(x - leg_span * 0.15, half.y + 4.0), Palette.STONE_LIT, 1.5)
		draw_line(Vector2(x, half.y), Vector2(x + leg_span * 0.15, half.y + 4.0), Palette.STONE_LIT, 1.5)
