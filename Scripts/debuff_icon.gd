extends Panel

var time_remaining: float = 0.0
var total_duration: float = 1.0

func _ready() -> void:
	size_flags_horizontal = 0
	size_flags_vertical = 0
	
func set_color(color: Color) -> void:
	get_theme_stylebox("panel").border_color = color

func start_countdown(duration: float) -> void:
	total_duration = duration
	time_remaining = duration

func _process(delta: float) -> void:
	if time_remaining <= 0:
		return
	time_remaining = max(0.0, time_remaining - delta)
	$Label.text = str(int(ceil(time_remaining)))
	$TextureProgressBar.value = (time_remaining / total_duration) * 100
	
func set_icon(texture: Texture2D) -> void:
	$TextureRect.texture = texture
