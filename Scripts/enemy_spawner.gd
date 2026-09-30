extends Node

@export var level_rule: SpawnLevelRule

func summon_enemy(scene: PackedScene, position: Vector2) -> Node:
	var enemy = scene.instantiate()
	enemy.position = position
	enemy.get_node("UnitStats").set_level(level_rule.roll(PlayerState.level))
	get_parent().add_child(enemy)
	return enemy
