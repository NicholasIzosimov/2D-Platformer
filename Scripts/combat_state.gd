extends Node

signal combat_changed(in_combat)

@export var combat_timeout: float = 5.0
var in_combat: bool = false
var timer: float = 0.0
var stats: Node

func _ready() -> void:
	stats = get_node("../UnitStats")
	stats.damage_taken.connect(func(_amount, _crit): refresh())
	stats.attack_missed.connect(refresh)
	get_node("../CombatHandler").ability_used.connect(func(_ability): refresh())

func refresh() -> void:
	timer = combat_timeout
	if not in_combat:
		in_combat = true
		combat_changed.emit(true)

func _process(delta: float) -> void:
	if in_combat:
		timer -= delta
		if timer <= 0.0:
			in_combat = false
			combat_changed.emit(false)
	elif not stats.is_dead:
		stats.heal(stats.max_health * stats.unit_data.out_of_combat_regen / 100.0 * delta)
