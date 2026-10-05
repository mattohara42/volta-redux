## A gem holder (`SPEC.md` → *Act 4*): a pedestal standing in for a break in a
## circuit. Walk into it holding a gem and the gem is set in it, which joins
## the two pieces of metal it was wired between, the way a sword joins the two
## sides of a seam. It keeps the gem: nothing takes one back out.
class_name GemHolder
extends Area2D

signal filled

const SOCKET := Vector2(12.0, 14.0)
## How far above the pedestal a hero still counts as at it, px.
const REACH_ABOVE: float = 48.0

var is_filled := false
var rect := Rect2()

var _network: CircuitNetwork
var _a: Conductor
var _b: Conductor


## `area` is the pedestal, in the room's coordinates; `a` and `b` are the two
## pieces a set gem joins.
func configure(area: Rect2, network: CircuitNetwork, a: Conductor, b: Conductor) -> void:
	rect = area
	_network = network
	_a = a
	_b = b
	position = area.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	# A little wider than the pedestal, so walking up to it is enough, and
	# reaching well above it, so jumping over it sets the gem too.
	box.size = area.size + Vector2(4.0, REACH_ABOVE)
	shape.shape = box
	shape.position = Vector2(0.0, -REACH_ABOVE * 0.5)
	add_child(shape)
	collision_layer = 0
	collision_mask = 4
	monitorable = false
	body_entered.connect(_on_body_entered)
	add_to_group("gem_holders")


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null or is_filled or player.gems_held <= 0:
		return
	player.gems_held -= 1
	is_filled = true
	_network.wire(_a, _b)
	Burst.emit(get_parent(), global_position, Burst.Kind.ARC_SPARKS)
	queue_redraw()
	filled.emit()


func status() -> String:
	return "holder %s" % ("FILLED" if is_filled else "empty")


## A gold socket on the pedestal's top (gold: it is used), dark while empty and
## holding the gem once set.
func _draw() -> void:
	var top := Vector2(0.0, -rect.size.y * 0.5)
	var socket := Rect2(top - Vector2(SOCKET.x * 0.5, SOCKET.y), SOCKET)
	draw_rect(socket, Palette.GOLD_SHADE)
	draw_rect(socket.grow(-2.0), Palette.BACKDROP)
	if is_filled:
		Gem.draw_gem(self, socket.get_center(), Gem.SIZE)
	draw_rect(socket, Palette.GOLD_FACE, false, 1.0)
