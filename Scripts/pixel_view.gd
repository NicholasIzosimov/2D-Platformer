extends SubViewportContainer

@export var camera: Camera2D
@export var target_view_height: float = 480.0
@export var min_view_height: float = 320.0
@export var max_view_height: float = 720.0
@export var zoom_stiffness: float = 180.0
@export var zoom_damping: float = 18.0

@onready var world_viewport: SubViewport = $WorldViewport

var zoom_steps: int = 0
var pixel_scale: int = 1
var size_scale: int = 1
var visual_scale: float = 1.0
var zoom_velocity: float = 0.0

func _ready() -> void:
	stretch = false
	get_window().size_changed.connect(reset_scale)
	reset_scale()
	RenderingServer.frame_pre_draw.connect(sync_view)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in", false, true):
		zoom_steps += 1
		update_scale()
	elif event.is_action_pressed("zoom_out", false, true):
		zoom_steps -= 1
		update_scale()

func reset_scale() -> void:
	update_scale()
	size_scale = pixel_scale
	visual_scale = pixel_scale
	zoom_velocity = 0.0

func update_scale() -> void:
	var window_height := float(get_window().size.y)
	var default_scale: int = maxi(1, roundi(window_height / target_view_height))
	var min_scale: int = maxi(1, ceili(window_height / max_view_height))
	var max_scale: int = maxi(min_scale, floori(window_height / min_view_height))
	pixel_scale = clampi(default_scale + zoom_steps, min_scale, max_scale)
	zoom_steps = pixel_scale - default_scale
	size_scale = mini(size_scale, pixel_scale)

func _process(delta: float) -> void:
	if visual_scale == pixel_scale and zoom_velocity == 0.0:
		return
	var step: float = minf(delta, 1.0 / 30.0)
	zoom_velocity += (zoom_stiffness * (pixel_scale - visual_scale) - zoom_damping * zoom_velocity) * step
	visual_scale = maxf(visual_scale + zoom_velocity * step, size_scale)
	if absf(pixel_scale - visual_scale) < 0.001 and absf(zoom_velocity) < 0.01:
		visual_scale = pixel_scale
		zoom_velocity = 0.0
		size_scale = pixel_scale

func sync_view() -> void:
	var window_size := Vector2(get_window().size)
	var view_size := Vector2i((window_size / size_scale).ceil()) + Vector2i(2, 2)
	if world_viewport.size != view_size:
		world_viewport.size = view_size
		size = Vector2(view_size)
	var center: Vector2 = camera.get_screen_center_position()
	var snapped_center: Vector2 = center.round()
	var half := Vector2(view_size / 2)
	world_viewport.canvas_transform = Transform2D(0.0, half - snapped_center)
	var units_per_pixel: float = get_viewport_rect().size.y / window_size.y
	var units_scale: float = units_per_pixel * visual_scale
	scale = Vector2(units_scale, units_scale)
	position = get_viewport_rect().size * 0.5 - (half + center - snapped_center) * units_scale
