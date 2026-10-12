extends Node

@export var main_camera: Camera2D
@export var height_buffer: SubViewport
@export var thickness: float = 2.0
@export_range(0.01, 1.0) var facing_softness: float = 0.3
@export_range(0.0, 1.0) var back_strength: float = 0.7
@export var step_px: float = 1.0

func _ready() -> void:
	RenderingServer.global_shader_parameter_set("shadow_buffer", height_buffer.get_texture())

func _process(_delta: float) -> void:
	var size := Vector2(height_buffer.size)
	var corner: Vector2 = main_camera.get_screen_center_position() - size * 0.5
	RenderingServer.global_shader_parameter_set("shadow_buffer_rect", Vector4(corner.x, corner.y, size.x, size.y))
	RenderingServer.global_shader_parameter_set("shadow_params", Vector4(thickness, facing_softness, back_strength, step_px))
