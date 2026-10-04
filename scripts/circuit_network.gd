## Works out, every physics frame, which conductors are live: the room's
## sources, its conductors, and whatever embedded swords join them
## (`Circuit`, in `scripts/logic/`, is the rule). A room adds one of these and
## registers its pieces; nothing else needs to know a circuit exists.
##
## A sword joins every conductor its blade touches, reaching `conduct_reach` px
## past the blade. That reach is how a sword thrown into an insulating seam
## touches the metal on both sides of it.
class_name CircuitNetwork
extends Node

const SWORD: SwordConfig = preload("res://config/sword.tres")
const WORLD: WorldConfig = preload("res://config/world.tres")

var _pieces: Array[Conductor] = []
## Permanent links the room lays: a switch wired to a stretch of wall.
var _wires: Array = []


func add(piece: Conductor) -> void:
	_pieces.append(piece)


## A fixed wire between two registered pieces.
func wire(a: Conductor, b: Conductor) -> void:
	_wires.append([_pieces.find(a), _pieces.find(b)])


## Indices into the registered pieces that are live this frame. For the tests
## and the capture tool as much as for the pieces themselves.
func live_indices() -> Dictionary:
	var sources: Array = []
	for i in _pieces.size():
		if _pieces[i].is_source:
			sources.append(i)
	return Circuit.live(sources, _links())


func _physics_process(_delta: float) -> void:
	var live := live_indices()
	for i in _pieces.size():
		_pieces[i].is_live = live.has(i)
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword != null:
			sword.conducting = _touching(sword).any(func(i: int) -> bool: return live.has(i))


func _links() -> Array:
	var links: Array = _wires.duplicate()
	for node in get_tree().get_nodes_in_group("swords"):
		var sword := node as Sword
		if sword != null:
			links.append_array(Circuit.links_through(_touching(sword)))
	return links


## The pieces an embedded sword's blade touches. Only an embedded sword
## conducts: one in flight is passing through, not wired in.
func _touching(sword: Sword) -> Array:
	var out: Array = []
	if sword.state != SwordFlight.State.EMBEDDED:
		return out
	var blade := Rect2(
		sword.global_position - Vector2(WORLD.sword_length, Sword.LEDGE_THICKNESS) * 0.5,
		Vector2(WORLD.sword_length, Sword.LEDGE_THICKNESS)
	).grow(SWORD.conduct_reach)
	for i in _pieces.size():
		if _pieces[i].rect.intersects(blade):
			out.append(i)
	return out
