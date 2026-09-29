extends Node

func summon_enemy(scene: PackedScene, position: Vector2) -> Node:
	var enemy = scene.instantiate()
	enemy.position = position
	get_parent().add_child(enemy)
	return enemy
