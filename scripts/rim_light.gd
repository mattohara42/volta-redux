## Keeps a sprite's rim lit from the strongest light reaching it
## (`shaders/rim.gdshader`): which `LightSource` that is, from which side, and
## how strongly, worked out the way `LightField` falls a light off, so the rim
## and the room's light agree.
##
## Purely how it looks. Attached to the hero and to every enemy's sprite.
class_name RimLight
extends Node

const SHADER: Shader = preload("res://shaders/rim.gdshader")
const CONFIG: AtmosphereConfig = preload("res://config/atmosphere.tres")

var _sprite: CanvasItem
## A light to leave out: the hero's own, which is always on top of the hero.
var _ignore: Node
var _material: ShaderMaterial


## Puts a rim on `sprite`, ignoring any light under `ignore`.
static func attach(sprite: CanvasItem, ignore: Node = null) -> RimLight:
	if sprite == null:
		return null
	var rim := RimLight.new()
	rim._sprite = sprite
	rim._ignore = ignore
	rim._material = ShaderMaterial.new()
	rim._material.shader = SHADER
	sprite.material = rim._material
	sprite.add_child(rim)
	return rim


func _process(_delta: float) -> void:
	var at := (_sprite as Node2D).global_position if _sprite is Node2D else Vector2.ZERO
	var best := 0.0
	var toward := Vector2.ZERO
	var tint := Palette.FIRE_HOT
	for node in get_tree().get_nodes_in_group("lights"):
		var light := node as LightSource
		if light == null or not light.is_shining() or (_ignore != null and _ignore.is_ancestor_of(light)):
			continue
		var ends := light.ends()
		var nearest := Geometry2D.get_closest_point_to_segment(at, ends[0], ends[1])
		var reach := 1.0 - at.distance_to(nearest) / maxf(light.radius, 1.0)
		var lit := light.strength * reach * reach if reach > 0.0 else 0.0
		if lit > best:
			best = lit
			toward = (nearest - at).normalized()
			tint = light.tint
	var mirrored := signf((_sprite as Node2D).global_transform.x.x) if _sprite is Node2D else 1.0
	_material.set_shader_parameter("rim_dir", Vector2(toward.x * mirrored, toward.y))
	_material.set_shader_parameter("rim_strength", clampf(best * CONFIG.rim_gain, 0.0, CONFIG.rim_max))
	_material.set_shader_parameter("rim_colour", hot(tint))


## A light's colour as a rim catches it: fire goes to its hot end, current to
## its core, so a rim always reads brighter than the light's own falloff.
static func hot(tint: Color) -> Color:
	return tint.lerp(Palette.FIRE_HOT if tint.r >= tint.b else Palette.ARC_CORE, 0.6)
