extends Button
var time_remaining: float = 0.0
var total_duration: float = 1.0

func _ready() -> void:
	#text = ability.name
	icon = ability.icon
	pivot_offset = size / 2
	focus_mode = Control.FOCUS_NONE
	
func start_countdown(duration: float) -> void:
	if duration < time_remaining:
		return
	total_duration = duration
	time_remaining = duration

func _process(delta: float) -> void:
	if time_remaining <= 0:
		return
	time_remaining = max(0.0, time_remaining - delta)
	if time_remaining == 0:
		$Label.text = ""
	else:
		$Label.text = str(int(ceil(time_remaining)))
	$TextureProgressBar.value = (time_remaining / total_duration) * 100

var ability: AbilityData
	
func set_validity(in_range: bool, has_power: bool) -> void:
	if not has_power:
		modulate = Color(0.4, 0.6, 1)
	elif not in_range:
		modulate = Color(1, 0.4, 0.4)
	else:
		modulate = Color(1, 1, 1)
		
func bop() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.10, 1.10), 0.05)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.05)
	
func stop_countdown() -> void:
	time_remaining = 0
	$Label.text = ""
	$TextureProgressBar.value = 0
