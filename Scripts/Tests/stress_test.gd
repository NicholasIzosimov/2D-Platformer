extends Node

@export var world: Node2D
@export var camera: Camera2D
@export var light_template: ShadowTestLight
@export var prop_templates: Array[Node2D] = []
@export var camera_speed: float = 200.0
@export var spread: float = 300.0
@onready var stats_label: Label = %StatsLabel

var base_size: Vector2i
var base_zoom: Vector2
var light_count: int = 0
var prop_count: int = 0

func _ready() -> void:
	base_size = get_window().content_scale_size
	base_zoom = camera.zoom

func _process(delta: float) -> void:
	var move := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	camera.position += move * camera_speed * delta
	stats_label.text = "FPS %d   process %.1f ms   lights %d   props %d" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		light_count,
		prop_count,
	]

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode == KEY_L:
		spawn_lights(5)
	elif key.keycode == KEY_P:
		spawn_props(10)
	elif key.keycode == KEY_V:
		toggle_pixel_mode()

func random_point() -> Vector2:
	var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread) * 0.6)
	return (camera.get_screen_center_position() + offset).round()

func spawn_lights(count: int) -> void:
	for i in count:
		var light := light_template.duplicate() as ShadowTestLight
		light.follow_mouse = false
		light.height = randf_range(10.0, 60.0)
		light.position = random_point()
		world.add_child(light)
		light.glow.color = Color.from_hsv(randf(), 0.5, 1.0)
		light_count += 1

func spawn_props(count: int) -> void:
	for i in count:
		var prop := prop_templates.pick_random().duplicate() as Node2D
		prop.position = random_point()
		world.add_child(prop)
		prop_count += 1

func toggle_pixel_mode() -> void:
	var window := get_window()
	if window.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		window.content_scale_size = base_size
		camera.zoom = base_zoom
	else:
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
		window.content_scale_size = Vector2i(Vector2(base_size) / base_zoom)
		camera.zoom = Vector2.ONE
