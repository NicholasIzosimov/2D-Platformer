class_name MoonLight
extends DirectionalLight2D

@export var shadow_direction: Vector2 = Vector2(1, 1)
@export var illumination: float = 0.15
@export var shadow_darkness: float = 1.0
@export var shadow_length: float = 0.5
@export var length_scale: float = 0.6

func _ready() -> void:
	add_to_group(Lighting.GROUP)

func light_info(_at: Vector2) -> Dictionary:
	if not enabled:
		return {}
	return {"light": self, "strength": illumination, "darkness": shadow_darkness, "spread": 0.0, "direction": 
		shadow_direction.normalized(), "distance_ratio": shadow_length, "length_scale": length_scale}
