extends Node

@export var selected_scale: float = 1.1
@export var glide_speed: float = 10.0
@export var plate_size: Vector2 = Vector2(80, 28)

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var camera := get_viewport().get_camera_2d()
	if player == null or camera == null:
		return
	var size: Vector2 = plate_size / camera.zoom.x
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	enemies.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	var placed: Array[Rect2] = []
	var t: float = min(1.0, glide_speed * delta)
	for enemy in enemies:
		var bars = enemy.get_node("Bars")
		var center: Vector2 = enemy.global_position + bars.base_position + bars.pivot
		var natural := Rect2(center - size / 2.0, size)
		var rect: Rect2 = natural
		var moved: bool = true
		while moved:
			moved = false
			for other in placed:
				var above: float = other.position.y - size.y
				if rect.intersects(other) and above < rect.position.y - 0.01:
					rect.position.y = above
					moved = true
		placed.append(rect)
		bars.lift = lerp(bars.lift, rect.position.y - natural.position.y, t)
		var s: float = selected_scale if enemy.get_node("TargetIndicator").is_selected else 1.0
		bars.extra_scale = lerp(bars.extra_scale, s, t)
