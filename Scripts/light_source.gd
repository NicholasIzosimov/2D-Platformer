class_name LightSource
extends PointLight2D

@export var ground_height: float = 0.0

func _ready() -> void:
	add_to_group(Lighting.GROUP)

func ground_position() -> Vector2:
	return global_position + Vector2(0.0, ground_height)
