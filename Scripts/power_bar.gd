extends ProgressBar

@export var track_player: bool = false
var unit: Node

func _ready() -> void:
	unit = owner
	if track_player:
		unit = get_tree().get_first_node_in_group("player")
		if not unit.is_node_ready():
			await unit.ready
	var power = unit.get_node("UnitStats")
	power.power_changed.connect(_on_power_changed)
	_on_power_changed(0.0, false)

func _on_power_changed(_amount: float, _show_text: bool) -> void:
	var power = unit.get_node("UnitStats")
	max_value = power.max_power
	value = power.current_power
