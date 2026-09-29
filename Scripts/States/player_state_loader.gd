extends Node

func _ready() -> void:
	var levels_gained: int = PlayerState.level - 1
	var stats = get_node("../UnitStats")
	stats.set_power_data(PlayerState.class_data.power)
	stats.max_health += PlayerState.bonus_health
	stats.current_health += PlayerState.bonus_health
	stats.modify_armor(PlayerState.bonus_armor)
	stats.modify_primary_stat(PlayerState.bonus_primary_stat)
	stats.modify_damage_reduction(PlayerState.bonus_damage_reduction)
	stats.modify_crit_chance(PlayerState.bonus_crit_chance)
	stats.modify_crit_damage(PlayerState.bonus_crit_damage)
	stats.modify_dodge_chance(PlayerState.bonus_dodge_chance)
	stats.modify_miss_chance(PlayerState.bonus_miss_chance)
	stats.modify_parry_chance(PlayerState.bonus_parry_chance)
	stats.modify_block_chance(PlayerState.bonus_block_chance)
	stats.modify_move_speed(PlayerState.bonus_move_speed)
	stats.modify_haste(PlayerState.bonus_haste)
	stats.max_power += PlayerState.bonus_max_power
	stats.current_power += PlayerState.bonus_max_power
	stats.modify_power_generation(PlayerState.bonus_power_generation)
	stats.max_health += PlayerState.class_data.health_per_level * levels_gained
	stats.current_health += PlayerState.class_data.health_per_level * levels_gained
	stats.modify_primary_stat(PlayerState.class_data.primary_stat_per_level * levels_gained)
	PlayerState.leveled_up.connect(_on_leveled_up)

func _on_leveled_up(_new_level: int) -> void:
	var stats = get_node("../UnitStats")
	stats.modify_max_health(PlayerState.class_data.health_per_level)
	stats.modify_primary_stat(PlayerState.class_data.primary_stat_per_level)
	get_node("../CombatTextSpawner").spawn_text("Level Up!", Color(1.0, 0.85, 0.2), 40)
	stats.heal_to_full()
