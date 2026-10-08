extends Node

signal interact_failed(reason)
const INTERACT_MASK: int = 32
var hovered: Interactable
var nearest: Interactable

func _process(_delta: float) -> void:
	hovered = interactable_under_mouse()
	nearest = nearest_in_range()
	for interactable in get_tree().get_nodes_in_group("interactables"):
		interactable.set_highlight(interactable.enabled and (interactable == hovered or interactable == nearest))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and nearest:
		try_interact(nearest)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and hovered:
		try_interact(hovered)
		get_viewport().set_input_as_handled()

func try_interact(interactable: Interactable) -> void:
	var reason: String = interactable.interact_error(get_parent())
	if reason != "":
		interact_failed.emit(reason)
		return
	interactable.interact(get_parent())

func nearest_in_range() -> Interactable:
	var player: Node2D = get_parent()
	var best: Interactable = null
	var best_distance: float = INF
	for interactable in get_tree().get_nodes_in_group("interactables"):
		if not interactable.enabled or not interactable.in_range(player):
			continue
		var distance: float = player.global_position.distance_to(interactable.global_position)
		if distance < best_distance:
			best = interactable
			best_distance = distance
	return best

func interactable_under_mouse() -> Interactable:
	var player: Node2D = get_parent()
	var params := PhysicsPointQueryParameters2D.new()
	params.position = player.get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = INTERACT_MASK
	for result in player.get_world_2d().direct_space_state.intersect_point(params):
		if result.collider is Interactable and result.collider.enabled:
			return result.collider
	return null
