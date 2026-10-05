## The screen dissolving from the backdrop's dark to the room, or back: how a
## room arrives, and how an act's card comes up. In the ordered dither every
## light is shaded with (`shaders/dissolve.gdshader`), two art pixels a step.
##
## Purely how it looks. A room is live under it from its first frame, so a
## reveal never costs a player a moment of control.
class_name Dissolve
extends CanvasLayer

const SHADER: Shader = preload("res://shaders/dissolve.gdshader")
## Under the opening card and an act's card, over the room and its HUD.
const LAYER := 80

var _rect: ColorRect
var _material: ShaderMaterial
var _from := 1.0
var _to := 0.0
var _seconds := 0.3
var _clock := 0.0


## Clears from the dark to whatever is under it over `seconds`, then goes.
static func reveal(parent: Node, seconds: float, layer: int = LAYER) -> Dissolve:
	return _make(parent, 1.0, 0.0, seconds, layer)


## Fills from clear to the dark over `seconds`, and stays.
static func cover(parent: Node, seconds: float, layer: int = LAYER) -> Dissolve:
	return _make(parent, 0.0, 1.0, seconds, layer)


static func _make(parent: Node, from: float, to: float, seconds: float, layer: int) -> Dissolve:
	var dissolve := Dissolve.new()
	dissolve.layer = layer
	dissolve.process_mode = Node.PROCESS_MODE_ALWAYS
	dissolve._from = from
	dissolve._to = to
	dissolve._seconds = maxf(seconds, 0.01)
	dissolve._rect = ColorRect.new()
	dissolve._rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dissolve._rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dissolve._material = ShaderMaterial.new()
	dissolve._material.shader = SHADER
	dissolve._material.set_shader_parameter("colour", Palette.BACKDROP)
	dissolve._material.set_shader_parameter("cover", from)
	dissolve._rect.material = dissolve._material
	dissolve.add_child(dissolve._rect)
	parent.add_child(dissolve)
	return dissolve


func _process(delta: float) -> void:
	_clock += delta
	var t := clampf(_clock / _seconds, 0.0, 1.0)
	_material.set_shader_parameter("cover", lerpf(_from, _to, t))
	if t >= 1.0 and _to <= 0.0:
		queue_free()
