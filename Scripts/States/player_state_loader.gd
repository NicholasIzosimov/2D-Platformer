extends Node
	
func _ready() -> void:
	var stats = get_node("../UnitStats")
	for stat in PlayerState.bonus_stats:
		stats.modify_stat(stat, PlayerState.bonus_stats[stat])
	stats.weapon_speed = PlayerState.weapon_speed()
	PlayerState.leveled_up.connect(_on_leveled_up)
	stats.set_level(PlayerState.level)
	PlayerState.bonus_stat_changed.connect(_on_bonus_stat_changed)
	PlayerState.gear_changed.connect(_on_gear_changed)
	get_node("../CombatHandler").unit_killed.connect(_on_unit_killed)
	PlayerState.quest_completed.connect(_on_quest_completed)
	get_node("../CombatState").combat_changed.connect(func(value): PlayerState.in_combat = value)
	
func _on_gear_changed() -> void:
	get_node("../UnitStats").weapon_speed = PlayerState.weapon_speed()
	
func _on_leveled_up(_new_level: int) -> void:
	var stats = get_node("../UnitStats")
	stats.set_level(PlayerState.level)
	get_node("../CombatTextSpawner").spawn_text("Level Up!", Color(1.0, 0.85, 0.2), 40)
	stats.heal_to_full()
	
func _on_bonus_stat_changed(stat: Stat.Type, amount: float) -> void:
	get_node("../UnitStats").modify_stat(stat, amount)

func _on_unit_killed(unit: Node) -> void:
	PlayerState.register_kill(unit.get_node("UnitStats").unit_data)

func _on_quest_completed(_quest: Quest) -> void:
	get_node("../CombatTextSpawner").spawn_text("Quest Complete!", Color(1.0, 0.85, 0.2), 40)
