class_name Interactable
extends Area2D

signal interacted(unit)
@export var visual: Node2D
@export var interact_range: float = 2.0
@export var out_of_combat_only: bool = true
@export var highlight_color: Color = Color(1.4, 1.4, 1.4)
@export var highlight_scale: float = 1.1
@export var highlight_time: float = 0.1
@export var action_text: String = "open"
var enabled: bool = true
var highlighted: bool = false
var tween: Tween

func _ready() -> void:
	add_to_group("interactables")
	if visual == null:
		visual = get_parent()
	$Prompt.visible = false
	$Prompt/Label.text = "Press %s to %s" % [Keybinds.text("interact"), action_text]

func set_highlight(value: bool) -> void:
	if value == highlighted:
		return
	highlighted = value
	visual.modulate = highlight_color if value else Color.WHITE
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(visual, "scale", Vector2.ONE * (highlight_scale if value else 1.0), highlight_time)

func set_prompt(value: bool) -> void:
	$Prompt.visible = value

func in_range(unit: Node2D) -> bool:
	return unit.global_position.distance_to(global_position) <= Yards.to_px(interact_range)

func interact_error(unit: Node2D) -> String:
	if not in_range(unit):
		return "Too far away"
	if out_of_combat_only and unit.get_node("CombatState").in_combat:
		return "Can't do that in combat"
	return ""

func interact(unit: Node2D) -> void:
	interacted.emit(unit)
