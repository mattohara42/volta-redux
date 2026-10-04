## A light the room's `LightField` reads: a point, or a line from this node to
## `reach`, with a radius, a colour and a strength. Invisible by itself. The
## field is what turns every one of these into the room's light and dark.
##
## A line light is how a lava pit, a live copper face or an arc lights the
## room along its whole length rather than from one bright spot in the middle.
##
## Hidden with its parent: a light under a node that is not visible gives no
## light, which is how a dead conductor goes dark without telling anyone.
class_name LightSource
extends Node2D

## The far end of a line light, in this node's own coordinates. Zero is a point.
var reach := Vector2.ZERO
## How far the light carries from the point or line, art px.
var radius := 60.0
var tint := Palette.FIRE_FALLOFF
## 0 to 1 at the source, before flicker.
var strength := 0.5
## 0 is steady. 1 dips the light to nothing at the bottom of its flicker, the
## same wobble `shaders/light.gdshader` gives a `LightGlow`.
var flicker := 0.0


static func point(light_radius: float, light_tint: Color, light_strength: float, light_flicker: float = 0.0) -> LightSource:
	var light := LightSource.new()
	light.radius = light_radius
	light.tint = light_tint
	light.strength = light_strength
	light.flicker = light_flicker
	return light


## A line light from `from` to `to`, both in the parent's coordinates.
static func line(from: Vector2, to: Vector2, light_radius: float, light_tint: Color, light_strength: float) -> LightSource:
	var light := LightSource.point(light_radius, light_tint, light_strength)
	light.position = from
	light.reach = to - from
	return light


func _ready() -> void:
	add_to_group("lights")


## Both ends in canvas coordinates, the space `LightField` shades in.
func ends() -> PackedVector2Array:
	var from := global_position
	return PackedVector2Array([from, from + global_transform.basis_xform(reach)])


## Whether it should light anything this frame.
func is_shining() -> bool:
	return strength > 0.0 and radius > 0.0 and is_visible_in_tree()
