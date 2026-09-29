@tool
extends Node2D

@export var color: Color = Color.RED:
	set(value):
		color = value
		queue_redraw()
@export var size: Vector2 = Vector2(30, 8):
	set(value):
		size = value
		queue_redraw()
@export var width: float = 2.0:
	set(value):
		width = value
		queue_redraw()

func _draw() -> void:
	var points = PackedVector2Array()
	for i in 49:
		var angle = TAU * i / 48
		points.append(Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_polyline(points, color, width, true)
