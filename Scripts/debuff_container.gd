extends HBoxContainer

@export var debuff_icon_scene: PackedScene
var current_icons: Dictionary = {}

func _ready() -> void:
	var combat_handler = owner.get_node("CombatHandler")
	combat_handler.effect_applied.connect(_on_effect_applied)
	combat_handler.effect_expired.connect(_on_effect_expired)

func _on_effect_applied(effect) -> void:
	if effect.icon == null:
		return
	if current_icons.has(effect.name):
		current_icons[effect.name].start_countdown(effect.spell_duration)
		return
	if current_icons.size() >= 3:
		return
	var icon = debuff_icon_scene.instantiate()
	icon.start_countdown(effect.spell_duration)
	icon.set_icon(effect.icon)
	add_child(icon)
	current_icons[effect.name] = icon

func _on_effect_expired(effect) -> void:
	if current_icons.has(effect.name):
		current_icons[effect.name].queue_free()
		current_icons.erase(effect.name)
