extends Node

@export var floating_number_scene: PackedScene
@export var spread: float = 15.0
@export var drift: float = 25.0
@export var player_damage_color: Color = Color(1.0, 0.3, 0.3)

var unit_stats: Node
var side: float = 1.0
func _ready() -> void:
	unit_stats = get_node("../UnitStats")
	unit_stats.damage_taken.connect(_on_damage_taken)
	unit_stats.attack_missed.connect(_on_attack_missed)
	#unit_stats.power_changed.connect(_on_power_changed)

func _on_damage_taken(amount: float, crit_multiplier: float) -> void:
	if amount <= 0:
		return
	var number = create_number()
	number.set_value(-amount)
	if crit_multiplier > 1.0:
		number.set_crit(crit_multiplier)
	if owner.is_in_group("player"):
		number.set_color(player_damage_color)
	owner.get_node("Bars").add_child(number)

func _on_attack_missed() -> void:
	var number = create_number()
	number.set_miss()
	owner.get_node("Bars").add_child(number)

func _on_power_changed(amount: float, show_text: bool) -> void:
	if not show_text:
		return
	var number = create_number()
	number.set_value(amount)
	owner.get_node("Bars").add_child(number)

func create_number() -> Node:
	side = -side
	var number = floating_number_scene.instantiate()
	number.position = Vector2(side * randf_range(5.0, spread), -85.0 + randf_range(-8.0, 8.0))
	number.drift_x = side * drift
	number.z_index = 20
	return number

func spawn_text(text: String, color: Color, font_size: int) -> void:
	var number = create_number()
	number.text = text
	number.set_color(color)
	number.add_theme_font_size_override("font_size", font_size)
	owner.get_node("Bars").add_child(number)
