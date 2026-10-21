extends Panel

var time_remaining: float = 0.0
var total_duration: float = 1.0
var effect: StatusEffect

func _ready() -> void:
	size_flags_horizontal = 0
	size_flags_vertical = 0
	mouse_filter = Control.MOUSE_FILTER_PASS
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			
func set_color(color: Color) -> void:
	get_theme_stylebox("panel").border_color = color

func start_countdown(duration: float) -> void:
	total_duration = duration
	time_remaining = duration

func _process(delta: float) -> void:
	if time_remaining <= 0:
		return
	time_remaining = max(0.0, time_remaining - delta)
	$Label.text = TimeFormat.short(time_remaining)
	$TextureProgressBar.value = (1.0 - time_remaining / total_duration) * 100
	
func set_icon(texture: Texture2D) -> void:
	$TextureRect.texture = texture
	
func tooltip_sections() -> Array:
	if effect == null:
		return []
	var text: String = "[b]%s[/b]" % effect.name
	var details: String = Describe.status_effect(effect)
	if details != "":
		text += "\n" + details
	text += "\n[color=gray]%s remaining[/color]" % TimeFormat.short(time_remaining)
	return [text]
