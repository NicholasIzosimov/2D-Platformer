extends Node

@export var floating_number_scene: PackedScene
@export var spread: float = 15.0
@export var drift: float = 25.0
@export var player_damage_color: Color = Color(1.0, 0.3, 0.3)
@export var ability_damage_color: Color = Color(1.0, 0.85, 0.2)
@export var damage_font: Font
@export var text_height: float = -85.0
@export var incoming_window: float = 1.0
var incoming_total: float = 0.0
var incoming_crit: float = 1.0
var incoming_ready: bool = true
var unit_stats: Node
var side: float = 1.0
var anchor: Node2D

func _ready() -> void:
	anchor = owner.get_node("CombatText")
	unit_stats = get_node("../UnitStats")
	unit_stats.damage_taken.connect(_on_damage_taken)
	unit_stats.attack_missed.connect(_on_attack_missed)

func _on_damage_taken(amount: float, crit_multiplier: float, from_ability: bool) -> void:
	if amount <= 0:
		return
	if owner.is_in_group("player"):
		gather_incoming(amount, crit_multiplier)
		return
	var number = create_number()
	number.set_value(-amount)
	if damage_font:
		number.add_theme_font_override("font", damage_font)
	if crit_multiplier > 1.0:
		number.set_crit(crit_multiplier)
	elif from_ability:
		number.set_color(ability_damage_color)
	anchor.add_child(number)

func gather_incoming(amount: float, crit_multiplier: float) -> void:
	incoming_total += amount
	incoming_crit = max(incoming_crit, crit_multiplier)
	if incoming_ready:
		show_incoming()

func show_incoming() -> void:
	if incoming_total <= 0.0:
		incoming_ready = true
		return
	var number = create_number()
	number.set_value(-incoming_total)
	if damage_font:
		number.add_theme_font_override("font", damage_font)
	if incoming_crit > 1.0:
		number.set_crit(incoming_crit)
	number.set_color(player_damage_color)
	anchor.add_child(number)
	incoming_total = 0.0
	incoming_crit = 1.0
	incoming_ready = false
	get_tree().create_timer(incoming_window, false).timeout.connect(show_incoming)
	
func _on_attack_missed() -> void:
	var number = create_number()
	number.set_miss()
	anchor.add_child(number)

func _on_power_changed(amount: float, show_text: bool) -> void:
	if not show_text:
		return
	var number = create_number()
	number.set_value(amount)
	anchor.add_child(number)

func create_number() -> Node:
	side = -side
	var number = floating_number_scene.instantiate()
	number.position = Vector2(side * randf_range(5.0, spread), text_height + randf_range(-8.0, 8.0))
	number.drift_x = side * drift
	number.z_index = 20
	return number

func spawn_text(text: String, color: Color, font_size: int) -> void:
	var number = create_number()
	number.text = text
	number.set_color(color)
	number.add_theme_font_size_override("font_size", font_size)
	anchor.add_child(number)
