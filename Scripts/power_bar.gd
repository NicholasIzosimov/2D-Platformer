extends SmoothBar

@export var track_player: bool = false
var unit: Node

func _ready() -> void:
	if track_player:
		var player = get_tree().get_first_node_in_group("player")
		if not player.is_node_ready():
			await player.ready
		bind(player)
	elif owner and owner.has_node("UnitStats"):
		bind(owner)

func bind(new_unit: Node) -> void:
	if is_instance_valid(unit):
		var old_stats = unit.get_node("UnitStats")
		if old_stats.power_changed.is_connected(_on_power_changed):
			old_stats.power_changed.disconnect(_on_power_changed)
	unit = new_unit
	initialized = false
	if not is_instance_valid(unit):
		return
	unit.get_node("UnitStats").power_changed.connect(_on_power_changed)
	_on_power_changed(0.0, false)

func _on_power_changed(_amount: float, _show_text: bool) -> void:
	var power = unit.get_node("UnitStats")
	set_bar(power.current_power, power.max_power)
