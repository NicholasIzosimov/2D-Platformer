class_name Structure
extends Node2D

@export var clear_radius: int = 4
var units: Array = []

func get_props() -> Array[Prop]:
	var result: Array[Prop] = []
	for child in get_children():
		if child is Prop:
			result.append(child)
	return result

func get_spawn_points() -> Array[UnitSpawnPoint]:
	var result: Array[UnitSpawnPoint] = []
	for child in get_children():
		if child is UnitSpawnPoint:
			result.append(child)
	return result
