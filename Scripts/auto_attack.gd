extends Node

var target: Node2D = null
var timer: float = 0.0
var combat_handler: Node
var stats: Node
var swing_duration: float = 1.0

func _ready() -> void:
	combat_handler = get_node("../CombatHandler")
	stats = get_node("../UnitStats")

func _physics_process(delta: float) -> void:
	if stats.is_dead:
		return
	timer = max(0.0, timer - delta)
	if timer > 0.0:
		return
	if not is_instance_valid(target) or target.get_node("UnitStats").is_dead:
		return
	if combat_handler.is_casting:
		return
	if combat_handler.swing(stats.unit_data.auto_attack, target):
		swing_duration = swing_time()
		timer = swing_duration

func swing_time() -> float:
	return stats.unit_data.base_swing_time / (1.0 + stats.get_stat(Stat.Type.HASTE) / 100.0)
	
func progress() -> float:
	return 1.0 - timer / swing_duration

func is_engaged() -> bool:
	return is_instance_valid(target) and not target.get_node("UnitStats").is_dead
