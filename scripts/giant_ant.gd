## SPEC.md's giant ant: walks walls and ceilings, ignores gravity. The mistake
## it punishes is assuming the floor is where the danger is, and `AntCrawl`
## carries the whole loop: a rectangle it walks the inside face of forever.
##
## `track` is in the room's coordinates directly, the way `Bat`'s box is
## relative to a centre: this node's own `position` is fully determined by
## where on the loop it currently is, so nothing else sets it.
class_name GiantAnt
extends Enemy

## The pixel-art ant (`ANIMATION.md`): a crawl loop, drawn at 1x. Its feet are
## on the local bottom edge of the killing box, so the rotation below is the
## whole trick of walking a wall.
const SPRITE_SCENE: PackedScene = preload("res://scenes/ant_sprite.tscn")

var _track := Rect2()
var _elapsed: float = 0.0


## See `Bat.place` for why this is not called `configure`.
func place(size: Vector2, track: Rect2, enemy_config: EnemyConfig) -> void:
	configure(size)
	_track = track
	_config = enemy_config
	add_to_group("mechanisms")


func _ready() -> void:
	_attach_sprite(SPRITE_SCENE, "crawl")
	_update()


func _physics_process(delta: float) -> void:
	if _step_dormancy(delta):
		return
	_elapsed += delta
	_update()


func _update() -> void:
	var distance := _elapsed * _config.ant_speed
	position = AntCrawl.position_at(distance, _track)
	var normal := AntCrawl.surface_normal_at(distance, _track)
	rotation = normal.angle() + PI * 0.5


func reset(frozen_for: float) -> void:
	_elapsed = -maxf(frozen_for, 0.0)
	_update()


func status() -> String:
	return "ant" + _status_suffix()
