extends Node

@export var selected_scale: float = 1.1
@export var glide_speed: float = 10.0

func _process(delta: float) -> void:
	var t: float = min(1.0, glide_speed * delta)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var s: float = 1.0
		if enemy.get_node("TargetIndicator").is_selected:
			s = selected_scale
		var bars = enemy.get_node("Bars")
		bars.position = bars.position.lerp(Vector2.ZERO, t)
		bars.scale = bars.scale.lerp(Vector2(s, s), t)
