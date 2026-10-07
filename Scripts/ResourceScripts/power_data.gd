extends Resource

class_name PowerData

@export var max_power: float = 100
@export var power_generation: float
@export var name: String
@export var color: Color = Color(0.21, 0.66, 0.78)
@export var out_of_combat_generation: float = 0.0
@export_range(0.0, 100.0) var starting_power_percent: float = 100.0
@export var power_on_kill: float = 0.0
