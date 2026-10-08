extends Node

@export var interval: float = 0.1
@export var shade_color: Color = Color(0.5, 0.5, 0.62)
@export var shade_strength: float = 1.5
@export var smoothing: float = 8.0
var shade: float = 0.0
var target: float = 0.0
var timer: float = 0.0
var unit: Node2D
var sprite: CanvasItem

func _ready() -> void:
	unit = get_parent()
	sprite = unit.get_node("AnimatedSprite2D")
	timer = randf() * interval

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = interval
		target = sample_shade()
	shade = lerp(shade, target, 1.0 - exp(-smoothing * delta))
	sprite.self_modulate = Color.WHITE.lerp(shade_color, clamp(shade * shade_strength, 0.0, 1.0))

func sample_shade() -> float:
	var feet: Vector2 = unit.global_position
	var result: float = 0.0
	for shadow in get_tree().get_nodes_in_group(Lighting.SHADOW_GROUP):
		if shadow.unit == unit:
			continue
		result = max(result, shadow.shade_at(feet))
	return result
