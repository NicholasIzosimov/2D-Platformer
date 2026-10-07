extends ProgressBar
class_name SmoothBar

@export var smooth_speed: float = 10.0
var target_value: float = 0.0
var initialized: bool = false
@export var show_numbers: bool = false
@export var number_font_size: int = 16
var label: Label

func set_bar(new_value: float, new_max: float) -> void:
	update_label(new_value, new_max)
	if not initialized or new_max != max_value:
		step = 0.0
		max_value = new_max
		value = new_value
		target_value = new_value
		initialized = true
		return
	target_value = new_value

func _process(delta: float) -> void:
	if abs(value - target_value) > 0.01:
		value = lerp(value, target_value, 1.0 - exp(-smooth_speed * delta))

func update_label(current: float, maximum: float) -> void:
	if not show_numbers:
		return
	if label == null:
		label = Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", number_font_size)
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		add_child(label)
	label.text = "%d / %d" % [roundi(current), roundi(maximum)]
