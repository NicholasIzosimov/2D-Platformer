extends Node
	
func _ready() -> void:
	var stats = get_node("../UnitStats")
	stats.set_power_data(PlayerState.class_data.power)
	stats.modify_vigor(PlayerState.bonus_vigor)
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
	PlayerState.leveled_up.connect(_on_leveled_up)
	stats.set_level(PlayerState.level)
	
func _on_leveled_up(_new_level: int) -> void:
	var stats = get_node("../UnitStats")
	stats.set_level(PlayerState.level)
	get_node("../CombatTextSpawner").spawn_text("Level Up!", Color(1.0, 0.85, 0.2), 40)
	stats.heal_to_full()
