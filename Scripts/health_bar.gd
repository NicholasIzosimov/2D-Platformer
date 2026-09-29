extends ProgressBar

@export var track_player: bool = false
var unit: Node

func _ready() -> void:
	unit = owner
	if track_player:
		unit = get_tree().get_first_node_in_group("player")
		if not unit.is_node_ready():
			await unit.ready
	var health = unit.get_node("UnitStats")
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(0.0)

func _on_health_changed(_damage: float) -> void:
	var health = unit.get_node("UnitStats")
	max_value = health.max_health
	value = health.current_health
