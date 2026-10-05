extends Node

@export var selected_scale: float = 1.1
@export var glide_speed: float = 10.0
@export var plate_size: Vector2 = Vector2(80, 28)
@export var plate_offset_y: float = -80.0

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	enemies.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	var placed: Array[Rect2] = []
	var t: float = min(1.0, glide_speed * delta)
	for enemy in enemies:
		var natural := Rect2(enemy.global_position + Vector2(-plate_size.x / 2.0, plate_offset_y), plate_size)
		var rect: Rect2 = natural
		var moved: bool = true
		while moved:
			moved = false
			for other in placed:
				var above: float = other.position.y - plate_size.y
				if rect.intersects(other) and above < rect.position.y - 0.01:
					rect.position.y = above
					moved = true
		placed.append(rect)
		var bars = enemy.get_node("Bars")
		bars.position = bars.position.lerp(Vector2(0, rect.position.y - natural.position.y), t)
		var s: float = selected_scale if enemy.get_node("TargetIndicator").is_selected else 1.0
		bars.scale = bars.scale.lerp(Vector2(s, s), t)
