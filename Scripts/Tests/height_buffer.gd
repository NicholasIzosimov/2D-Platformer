extends SubViewport
## Shadow test: renders only the height copies (visibility layer 2) of the main world,
## one texel per art pixel, following the main camera.

const HEIGHT_LAYER_BIT: int = 1 # bit 1 = layer 2

@export var main_camera: Camera2D
@onready var buffer_camera: Camera2D = $BufferCamera

func _ready() -> void:
	var main_view: Viewport = main_camera.get_viewport()
	world_2d = main_view.world_2d
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	canvas_cull_mask = 1 << HEIGHT_LAYER_BIT
	main_view.set_canvas_cull_mask_bit(HEIGHT_LAYER_BIT, false)

func _process(_delta: float) -> void:
	var view_size := Vector2i((main_camera.get_viewport().get_visible_rect().size / main_camera.zoom).ceil())
	if size != view_size:
		size = view_size
	buffer_camera.global_position = main_camera.get_screen_center_position()
