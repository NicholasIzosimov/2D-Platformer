extends Node
	
func _ready() -> void:
	var stats = get_node("../UnitStats")
	for stat in PlayerState.bonus_stats:
		stats.modify_stat(stat, PlayerState.bonus_stats[stat])
	PlayerState.leveled_up.connect(_on_leveled_up)
	stats.set_level(PlayerState.level)
	PlayerState.bonus_stat_changed.connect(_on_bonus_stat_changed)
	
func _on_leveled_up(_new_level: int) -> void:
	var stats = get_node("../UnitStats")
	stats.set_level(PlayerState.level)
	get_node("../CombatTextSpawner").spawn_text("Level Up!", Color(1.0, 0.85, 0.2), 40)
	stats.heal_to_full()
	
func _on_bonus_stat_changed(stat: Stat.Type, amount: float) -> void:
	get_node("../UnitStats").modify_stat(stat, amount)
