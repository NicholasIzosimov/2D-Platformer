extends Button

const COOLDOWN_TINT: Color = Color(0, 0, 0, 0.5)
const EFFECT_TINT: Color = Color(1, 1, 1, 0.35)
const EMPTY_TINT: Color = Color(1, 1, 1, 0.4)
var ability: AbilityData
var slot_index: int = 0
var keybind_action: String = ""
var combat_handler: Node
var effect_left: float = 0.0
var effect_total: float = 1.0
var dragging: bool = false

func _ready() -> void:
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	material = material.duplicate()
	pivot_offset = size / 2
	focus_mode = Control.FOCUS_NONE
	$TextureProgressBar.texture_progress.gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	combat_handler = get_tree().get_first_node_in_group("player").get_node("CombatHandler")
	if keybind_action != "":
		var key_label := Label.new()
		key_label.text = Keybinds.text(keybind_action)
		key_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		key_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		key_label.offset_right = -4
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.add_theme_constant_override("outline_size", 3)
		key_label.add_theme_color_override("font_outline_color", Color.BLACK)
		add_child(key_label)
	set_ability(ability)

func set_ability(new_ability: AbilityData) -> void:
	ability = new_ability
	effect_left = 0.0
	refresh_look()

func refresh_look() -> void:
	var shown: AbilityData = null if dragging else ability
	icon = shown.icon if shown else null
	if shown == null:
		self_modulate = EMPTY_TINT
		material.set_shader_parameter("saturation", 1.0)

func _process(_delta: float) -> void:
	var bar: TextureProgressBar = $TextureProgressBar
	if dragging:
		bar.value = 0
		$Label.text = ""
		return
	var waiting: float = 0.0
	var total: float = 1.0
	if ability:
		waiting = combat_handler.cooldown_left(ability)
		total = ability.cooldown
		var gcd_left: float = combat_handler.gcd_timer.time_left if ability.triggers_gcd else 0.0
		if gcd_left > waiting:
			waiting = gcd_left
			total = combat_handler.gcd_timer.wait_time
	if effect_left > 0.0:
		bar.tint_progress = EFFECT_TINT
		bar.value = effect_left / effect_total * 100
		$Label.text = TimeFormat.short(effect_left)
	elif waiting > 0.0:
		bar.tint_progress = COOLDOWN_TINT
		bar.value = waiting / max(total, 0.01) * 100
		$Label.text = TimeFormat.short(waiting)
	else:
		bar.value = 0
		$Label.text = ""

func set_effect_timer(left: float, total: float) -> void:
	effect_left = left
	effect_total = max(total, 0.01)

func set_validity(in_range: bool, has_power: bool) -> void:
	if dragging:
		return
	var on_cooldown_only: bool = combat_handler.cooldown_left(ability) > 0.0 and effect_left <= 0.0
	material.set_shader_parameter("saturation", 0.0 if on_cooldown_only else 1.0)
	if not has_power:
		self_modulate = Color(0.4, 0.6, 1)
	elif not in_range:
		self_modulate = Color(1, 0.4, 0.4)
	else:
		self_modulate = Color(1, 1, 1)

func bop() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.10, 1.10), 0.05)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if ability == null or not Input.is_key_pressed(KEY_SHIFT):
		return null
	var preview_root := Control.new()
	var preview := TextureRect.new()
	preview.texture = ability.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = size
	preview.position = -size / 2
	preview_root.add_child(preview)
	set_drag_preview(preview_root)
	dragging = true
	refresh_look()
	return {"slot_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	PlayerState.swap_slots(data["slot_index"], slot_index)

func tooltip_sections() -> Array:
	if ability == null or dragging:
		return []
	return [build_tooltip()]

func build_tooltip() -> String:
	var lines: Array[String] = ["[b]%s[/b]" % ability.name]
	if ability.power_cost > 0.0:
		lines.append("Cost: %d" % ability.power_cost)
	lines.append("Instant" if ability.cast_time <= 0.0 else "%.1f sec cast" % combat_handler.own_stats.hasted(ability.cast_time))
	if ability.cooldown > 0.0:
		lines.append("Cooldown: %s" % TimeFormat.short(ability.cooldown))
	if ability.requires_target:
		lines.append("Melee Range" if ability.range <= 2.0 else "Range: %d" % ability.range)
	var generated: String = Describe.ability(ability, combat_handler)
	if generated != "":
		lines.append("")
		lines.append(generated)
	if ability.description != "":
		lines.append("")
		lines.append("[color=gray]%s[/color]" % ability.description)
	return "\n".join(lines)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and dragging:
		dragging = false
		refresh_look()
