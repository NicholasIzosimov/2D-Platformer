extends Node

@export var thickness: float = 2.0
@export_range(0.01, 1.0) var facing_softness: float = 0.3
@export_range(0.0, 1.0) var back_strength: float = 0.7
@export var step_px: float = 1.0
@export var light_size: float = 6.0

func _process(_delta: float) -> void:
	RenderingServer.global_shader_parameter_set("shadow_params", Vector4(thickness, facing_softness, back_strength, step_px))
	RenderingServer.global_shader_parameter_set("shadow_soft", Vector4(GraphicsSettings.shadow_samples(), light_size, 0.0, 0.0))
