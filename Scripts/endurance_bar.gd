extends ProgressBar

@export var track_player: bool = false
var unit: Node

func _ready() -> void:
	unit = owner
	if track_player:
		unit = get_tree().get_first_node_in_group("player")
		if not unit.is_node_ready():
			await unit.ready
	var endurance = unit.get_node("Endurance")
	endurance.endurance_changed.connect(_on_endurance_changed)
	_on_endurance_changed()

func _on_endurance_changed() -> void:
	var endurance = unit.get_node("Endurance")
	max_value = endurance.max_endurance
	value = endurance.current_endurance
