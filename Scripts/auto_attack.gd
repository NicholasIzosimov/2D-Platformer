extends Node

var target: Node2D = null
var timer: float = 0.0
var combat_handler: Node
var stats: Node

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
		timer = swing_time()

func swing_time() -> float:
	return stats.unit_data.base_swing_time / (1.0 + stats.current_haste / 100.0)
