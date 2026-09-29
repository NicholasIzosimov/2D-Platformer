extends ProgressBar
class_name CastBar

var current_tween: Tween

func _ready() -> void:
	visible = false

func start_cast(duration: float) -> void:
	if current_tween:
		current_tween.kill()
	visible = true
	max_value = duration
	value = 0
	current_tween = create_tween()
	current_tween.tween_property(self, "value", duration, duration)
	current_tween.tween_callback(func(): visible = false)

func cancel_cast() -> void:
	if current_tween:
		current_tween.kill()
	visible = false
