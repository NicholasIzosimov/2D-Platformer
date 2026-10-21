extends SubViewport

const HEIGHT_LAYER_BIT: int = 1

@export var main_camera: Camera2D

func _ready() -> void:
	var main_view: Viewport = main_camera.get_viewport()
	world_2d = main_view.world_2d
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas_cull_mask = 1 << HEIGHT_LAYER_BIT
	main_view.set_canvas_cull_mask_bit(HEIGHT_LAYER_BIT, false)
	RenderingServer.global_shader_parameter_set("shadow_buffer", get_texture())
	connect_sync.call_deferred()

func sync_to_main_view() -> void:
	var main_view: Viewport = main_camera.get_viewport()
	var view_size := Vector2i((main_view.get_visible_rect().size / main_camera.zoom).ceil())
	if size != view_size:
		size = view_size
	canvas_transform = Transform2D().scaled(Vector2.ONE / main_camera.zoom) * main_view.canvas_transform
	var corner: Vector2 = canvas_transform.affine_inverse() * Vector2.ZERO
	RenderingServer.global_shader_parameter_set("shadow_buffer_rect", Vector4(corner.x, corner.y, size.x, size.y))

func connect_sync() -> void:
	RenderingServer.frame_pre_draw.connect(sync_to_main_view)
