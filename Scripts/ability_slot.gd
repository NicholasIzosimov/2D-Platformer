extends Button
var time_remaining: float = 0.0
var total_duration: float = 1.0
var cooldown_remaining: float = 0.0
var cooldown_total: float = 1.0
const COOLDOWN_TINT: Color = Color(0, 0, 0, 0.5)
const EFFECT_TINT: Color = Color(1, 1, 1, 0.35)
var effect_left: float = 0.0
var effect_total: float = 1.0
var keybind_action: String = ""

func _ready() -> void:
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	material = material.duplicate()
	icon = ability.icon
	pivot_offset = size / 2
	focus_mode = Control.FOCUS_NONE
	$TextureProgressBar.texture_progress.gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE])
	tooltip_text = ability.name
	if keybind_action != "":
		var key_label := Label.new()
		key_label.text = keybind_text(keybind_action)
		key_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		key_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		key_label.offset_right = -4
		key_label.add_theme_font_size_override("font_size", 14)
		key_label.add_theme_constant_override("outline_size", 3)
		key_label.add_theme_color_override("font_outline_color", Color.BLACK)
		add_child(key_label)
		
func start_countdown(duration: float) -> void:
	if duration < time_remaining:
		return
	total_duration = duration
	time_remaining = duration
	
func start_cooldown(duration: float) -> void:
	cooldown_remaining = duration
	cooldown_total = duration
	start_countdown(duration)
	
func _process(delta: float) -> void:
	cooldown_remaining = max(0.0, cooldown_remaining - delta)
	time_remaining = max(0.0, time_remaining - delta)
	var bar: TextureProgressBar = $TextureProgressBar
	if effect_left > 0.0:
		bar.tint_progress = EFFECT_TINT
		bar.value = effect_left / effect_total * 100
		$Label.text = TimeFormat.short(effect_left)
	elif time_remaining > 0.0:
		bar.tint_progress = COOLDOWN_TINT
		bar.value = time_remaining / total_duration * 100
		$Label.text = TimeFormat.short(time_remaining)
	else:
		bar.value = 0
		$Label.text = ""

func set_effect_timer(left: float, total: float) -> void:
	effect_left = left
	effect_total = max(total, 0.01)

var ability: AbilityData


func set_validity(in_range: bool, has_power: bool) -> void:
	var on_cooldown_only: bool = cooldown_remaining > 0.0 and effect_left <= 0.0
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
	
func stop_countdown() -> void:
	time_remaining = cooldown_remaining
	total_duration = cooldown_total

func _make_custom_tooltip(_for_text: String) -> Object:
	return RichTooltip.make(build_tooltip())

func build_tooltip() -> String:
	var lines: Array[String] = ["[b]%s[/b]" % ability.name]
	if ability.power_cost > 0.0:
		lines.append("Cost: %d" % ability.power_cost)
	lines.append("Instant" if ability.cast_time <= 0.0 else "%.1f sec cast" % ability.cast_time)
	if ability.cooldown > 0.0:
		lines.append("Cooldown: %s" % TimeFormat.short(ability.cooldown))
	if ability.requires_target:
		lines.append("Melee Range" if ability.range <= 2.0 else "Range: %d" % ability.range)
	var handler: Node = get_tree().get_first_node_in_group("player").get_node("CombatHandler")
	var generated: String = Describe.ability(ability, handler)
	if generated != "":
		lines.append("")
		lines.append(generated)
	if ability.description != "":
		lines.append("")
		lines.append("[color=gray]%s[/color]" % ability.description)
	return "\n".join(lines)

static func keybind_text(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			return OS.get_keycode_string(code)
	return ""
