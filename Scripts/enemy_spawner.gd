extends Node

@export var level_rule: SpawnLevelRule

func summon_enemy(scene: PackedScene, position: Vector2, unit_data: UnitData = null) -> Node:
	var enemy = scene.instantiate()
	enemy.position = position
	var stats = enemy.get_node("UnitStats")
	if unit_data:
		stats.unit_data = unit_data
	stats.set_level(level_rule.roll(PlayerState.level))
	get_parent().add_child(enemy)
	return enemy
