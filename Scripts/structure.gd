class_name Structure
extends Node2D

@export var clear_radius: int = 4
var units: Array = []

func get_props() -> Array[Prop]:
	var result: Array[Prop] = []
	collect_props(self, result)
	return result

func collect_props(node: Node, result: Array[Prop]) -> void:
	for child in node.get_children():
		if child is Prop:
			result.append(child)
		collect_props(child, result)

func position_of(node: Node2D) -> Vector2:
	var result: Vector2 = node.position
	var parent: Node = node.get_parent()
	while parent != self and parent is Node2D:
		result = parent.transform * result
		parent = parent.get_parent()
	return result

func get_spawn_points() -> Array[UnitSpawnPoint]:
	var result: Array[UnitSpawnPoint] = []
	for child in get_children():
		if child is UnitSpawnPoint:
			result.append(child)
	return result
