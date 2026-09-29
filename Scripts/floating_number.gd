extends Label

var drift_x: float = 0.0
@export var crit_min_size: float = 40.0
@export var crit_max_size: float = 56.0

func _ready() -> void:
	position -= get_combined_minimum_size() / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 40, 1.0)
	tween.tween_property(self, "position:x", position.x + drift_x, 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(queue_free)

func set_value(amount: float) -> void:
	text = str(roundi(amount))

func set_crit(multiplier: float) -> void:
	var t: float = clamp((multiplier - 1.5) / 0.5, 0.0, 1.0)
	add_theme_font_size_override("font_size", int(lerp(crit_min_size, crit_max_size, t)))
	add_theme_color_override("font_color", Color.YELLOW)

func set_miss() -> void:
	text = "Miss"
	add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func set_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
