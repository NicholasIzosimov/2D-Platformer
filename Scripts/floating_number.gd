extends Label


@export var crit_min_size: float = 40.0
@export var crit_max_size: float = 56.0
@export var crit_hold: float = 0.6
@export var crit_fade: float = 1.6
@export var crit_shake: float = 6.0
@export var crit_shake_time: float = 0.35
var drift_x: float = 0.0
var rise: float = 40.0
var duration: float = 1.0
var hold: float = 0.0
var is_crit: bool = false
var float_position: Vector2
var shake: float = 0.0

func _ready() -> void:
	float_position = position - get_combined_minimum_size() / 2
	position = float_position
	var stay: float = hold
	var fade: float = duration
	if is_crit:
		stay = crit_hold
		fade = crit_fade
		shake = crit_shake
		create_tween().tween_property(self, "shake", 0.0, crit_shake_time)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "float_position:y", float_position.y - rise, stay + fade)
	tween.tween_property(self, "float_position:x", float_position.x + drift_x, stay + fade)
	tween.tween_property(self, "modulate:a", 0.0, fade).set_delay(stay)
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	position = float_position + Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	
func set_value(amount: float) -> void:
	text = str(roundi(amount))

func set_crit(multiplier: float) -> void:
	is_crit = true
	var t: float = clamp((multiplier - 1.5) / 0.5, 0.0, 1.0)
	add_theme_font_size_override("font_size", int(lerp(crit_min_size, crit_max_size, t)))
	add_theme_color_override("font_color", Color.YELLOW)

func set_miss() -> void:
	text = "Miss"
	add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func set_color(color: Color) -> void:
	add_theme_color_override("font_color", color)
