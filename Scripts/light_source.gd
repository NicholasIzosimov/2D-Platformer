class_name LightSource
extends PointLight2D

@export var preset: LightPreset
@export var ground_height: float = 0.0
var base_energy: float = 1.0
var last_energy: float = 0.0

func _ready() -> void:
	apply_preset()
	add_to_group(Lighting.GROUP)
	last_energy = energy
	Lighting.wake_casters(get_tree(), self)

func set_preset(new_preset: LightPreset) -> void:
	preset = new_preset
	apply_preset()

func apply_preset() -> void:
	if preset:
		texture = preset.texture
		texture_scale = preset.texture_scale
		energy = preset.energy
		color = preset.color
		ground_height = preset.ground_height
	base_energy = max(energy, 0.001)

func _process(_delta: float) -> void:
	if energy != last_energy:
		last_energy = energy
		Lighting.wake_casters(get_tree(), self)

func _exit_tree() -> void:
	Lighting.wake_casters(get_tree(), self)

func ground_position() -> Vector2:
	return global_position + Vector2(0.0, ground_height)

func brightness() -> float:
	return clamp(energy / base_energy, 0.0, 1.0)

func radius() -> float:
	return texture.get_width() * 0.5 * texture_scale * global_scale.x if texture else 0.0

func light_info(at: Vector2) -> Dictionary:
	if not enabled or brightness() <= 0.0 or texture == null:
		return {}
	var offset: Vector2 = at - ground_position()
	var distance: float = offset.length()
	if distance >= radius() or distance < 0.01:
		return {}
	var reach: float = 1.0 - distance / radius()
	return {"light": self, "strength": reach * brightness(), "spread": 1.0, "direction": offset / distance, "distance_ratio": distance / radius()}
