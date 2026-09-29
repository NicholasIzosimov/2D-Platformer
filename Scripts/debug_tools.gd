extends Node

@export var enemy_spawner: Node
@export var enemy_scene: PackedScene
@export var spawn_point: Marker2D

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_spawn_enemy"):
		enemy_spawner.summon_enemy(enemy_scene, spawn_point.global_position)
