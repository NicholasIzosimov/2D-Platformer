extends SmoothBar

@export var track_player: bool = false
var unit: Node
var shown_power: PowerData

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
	shown_power = null
	if not is_instance_valid(unit):
		return
	unit.get_node("UnitStats").power_changed.connect(_on_power_changed)
	_on_power_changed(0.0, false)

func _on_power_changed(_amount: float, _show_text: bool) -> void:
	var power = unit.get_node("UnitStats")
	if power.power_data != shown_power:
		apply_color(power.power_data)
	set_bar(power.current_power, power.max_power)

func apply_color(power_data: PowerData) -> void:
	shown_power = power_data
	var fill := get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	fill.bg_color = power_data.color
	add_theme_stylebox_override("fill", fill)
	var background := get_theme_stylebox("background").duplicate() as StyleBoxFlat
	background.bg_color = Color(power_data.color.darkened(0.5), background.bg_color.a)
	add_theme_stylebox_override("background", background)
