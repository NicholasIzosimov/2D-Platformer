class_name LightSource
extends PointLight2D

@export var ground_height: float = 0.0
var base_energy: float = 1.0

func _ready() -> void:
	base_energy = max(energy, 0.001)
	add_to_group(Lighting.GROUP)

func ground_position() -> Vector2:
	return global_position + Vector2(0.0, ground_height)

func brightness() -> float:
	return clamp(energy / base_energy, 0.0, 1.0)

func light_info(at: Vector2) -> Dictionary:
	if not enabled or brightness() <= 0.0 or texture == null:
		return {}
	var radius: float = texture.get_width() * 0.5 * texture_scale * global_scale.x
	var offset: Vector2 = at - ground_position()
	var distance: float = offset.length()
	if distance >= radius or distance < 0.01:
		return {}
	var reach: float = 1.0 - distance / radius
	return {"light": self, "strength": reach * brightness(), "spread": 1.0, "direction": offset / distance, "distance_ratio": distance / radius}
