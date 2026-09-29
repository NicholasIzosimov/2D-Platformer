extends Node

@export var bars_half_width: float = 35.0
@export var bars_top: float = -71.0
@export var debuff_top: float = -94.0
@export var bars_bottom: float = -50.0
@export var gap: float = 3.0
@export var selected_scale: float = 1.1
@export var glide_speed: float = 10.0

func _process(delta: float) -> void:
	var placed: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var base: Vector2 = enemy.global_position
		var s: float = 1.0
		if enemy.get_node("TargetIndicator").is_selected:
			s = selected_scale
		var top: float = bars_top
		if enemy.get_node("Bars/HealthBar/DebuffContainer").get_child_count() > 0:
			top = debuff_top
		var offset: float = 0.0
		var bumped: bool = true
		while bumped:
			bumped = false
			var my_top: float = base.y + offset + s * top
			var my_bottom: float = base.y + offset + s * bars_bottom
			for other in placed:
				var close_x: bool = abs(other["x"] - base.x) < (s + other["s"]) * bars_half_width
				var close_y: bool = my_top < other["bottom"] + gap and my_bottom > other["top"] - gap + 0.01
				if close_x and close_y:
					offset = other["top"] - gap - (base.y + s * bars_bottom)
					bumped = true
					break
		placed.append({
			"x": base.x,
			"s": s,
			"top": base.y + offset + s * top,
			"bottom": base.y + offset + s * bars_bottom,
		})
		var bars = enemy.get_node("Bars")
		var t: float = min(1.0, glide_speed * delta)
		bars.position.y = lerp(bars.position.y, offset, t)
		bars.scale = bars.scale.lerp(Vector2(s, s), t)
