extends Label

var current_tween: Tween

func _ready() -> void:
	modulate.a = 0

func show_message(message: String) -> void:
	if current_tween:
		current_tween.kill()
	text = message
	modulate.a = 1
	current_tween = create_tween()
	current_tween.tween_interval(0.5)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.5)
