extends ProgressBar

var auto_attack: Node
var label: Label
var combat_state: Node

func _ready() -> void:
	max_value = 1.0
	step = 0.0
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(label)
	var player = get_tree().get_first_node_in_group("player")
	if not player.is_node_ready():
		await player.ready
	auto_attack = player.get_node("AutoAttack")
	combat_state = player.get_node("CombatState")
	
func _process(delta: float) -> void:
	if auto_attack == null:
		return
	if combat_state.in_combat:
		modulate.a = 1.0
	elif auto_attack.progress() >= 1.0:
		modulate.a = move_toward(modulate.a, 0.0, delta * 4.0)
	value = auto_attack.progress()
	label.text = "%.1f" % auto_attack.timer if auto_attack.timer > 0.0 else ""
