extends Node

@export var max_endurance: float = 100.0
@export var endurance_regen: float = 5.0
@export var wall_jump_cost: float = 15.0
@export var sprint_cost: float = 10.0
@export var sprint_regen_multiplier: float = 0.5
@export var idle_regen_multiplier: float = 2.0
@export var jump_cost: float = 0.0
var current_endurance: float = 0.0
var is_sprinting: bool = false
var is_idle: bool = false
signal endurance_changed
signal not_enough_endurance

func _ready() -> void:
	current_endurance = max_endurance

func _process(delta: float) -> void:
	if current_endurance < max_endurance:
		var regen: float = endurance_regen
		if is_sprinting:
			regen *= sprint_regen_multiplier
		if is_idle:
			regen *= idle_regen_multiplier
		current_endurance = min(current_endurance + regen * delta, max_endurance)
		endurance_changed.emit()

func spend(amount: float) -> bool:
	if current_endurance < amount:
		not_enough_endurance.emit()
		return false
	current_endurance -= amount
	endurance_changed.emit()
	return true
