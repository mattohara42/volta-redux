## What an enemy leaves for a moment when a sword kills it: its last frame, as
## a silhouette, flashing firelight, then cooling to chitin and fading as it
## lifts a few pixels. The enemy itself is gone the instant it dies, so the
## room is safe at once; this is only the picture catching up.
##
## Purely how it looks, so its numbers sit here (`Burst` says why).
class_name EnemyGhost
extends Sprite2D

const SHADER: Shader = preload("res://shaders/silhouette.gdshader")
## How long the flash holds, how long the fade takes, and how far it lifts,
## seconds and art px.
const FLASH_SECONDS: float = 0.07
const FADE_SECONDS: float = 0.28
const LIFT: float = 6.0

var _clock := 0.0
var _home := Vector2.ZERO
var _material: ShaderMaterial


## A ghost of `sprite`'s current frame, where it is, added to `parent`.
## Nothing happens if the sprite has no frame to copy.
static func of(sprite: AnimatedSprite2D, parent: Node) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame == null:
		return
	var ghost := EnemyGhost.new()
	ghost.texture = frame
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost._material = ShaderMaterial.new()
	ghost._material.shader = SHADER
	ghost._material.set_shader_parameter("tint", Palette.FIRE_HOT)
	ghost.material = ghost._material
	LightField.emissive(ghost)
	parent.add_child(ghost)
	ghost.global_transform = sprite.global_transform
	ghost._home = ghost.position


func _process(delta: float) -> void:
	_clock += delta
	if _clock < FLASH_SECONDS:
		return
	var t := clampf((_clock - FLASH_SECONDS) / FADE_SECONDS, 0.0, 1.0)
	_material.set_shader_parameter("tint", Palette.FIRE_HOT.lerp(Palette.ENEMY_CHITIN, t))
	_material.set_shader_parameter("alpha", 1.0 - t)
	position = _home + Vector2(0.0, -roundf(LIFT * t))
	if t >= 1.0:
		queue_free()
