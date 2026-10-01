extends ProgressBar
class_name SmoothBar

@export var smooth_speed: float = 10.0
var target_value: float = 0.0
var initialized: bool = false

func set_bar(new_value: float, new_max: float) -> void:
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
