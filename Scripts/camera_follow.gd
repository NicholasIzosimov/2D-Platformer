extends Camera2D

@export var follow_smoothing: float = 12.0
@export var lead_time: float = 0.10
@export var max_lead: float = 0.2
@export var lead_smoothing: float = 9
@export var target_view_height: float = 540.0
@export var min_view_height: float = 360.0
@export var max_view_height: float = 720.0
@export var zoom_stiffness: float = 180.0
@export var zoom_damping: float = 12.0
var zoom_steps: int = 0
var target_zoom: float = 1.0
var zoom_velocity: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing
	get_window().size_changed.connect(update_zoom)
	update_zoom()

func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var target_offset: Vector2 = (body.velocity * lead_time).limit_length(Yards.to_px(max_lead))
	offset = offset.lerp(target_offset, 1.0 - exp(-lead_smoothing * delta))
	spring_zoom(min(delta, 1.0 / 30.0))

func spring_zoom(delta: float) -> void:
	var current: float = zoom.x
	if current == target_zoom and zoom_velocity == 0.0:
		return
	zoom_velocity += (zoom_stiffness * (target_zoom - current) - zoom_damping * zoom_velocity) * delta
	current += zoom_velocity * delta
	if abs(target_zoom - current) < 0.001 and abs(zoom_velocity) < 0.01:
		current = target_zoom
		zoom_velocity = 0.0
	zoom = Vector2(current, current)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		zoom_steps += 1
		update_zoom(true)
	elif event.is_action_pressed("zoom_out"):
		zoom_steps -= 1
		update_zoom(true)

func update_zoom(animate: bool = false) -> void:
	var window := Vector2(get_window().size)
	var base := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	var stretch: float = min(window.x / base.x, window.y / base.y)
	var default_scale: int = max(1, roundi(window.y / target_view_height))
	var min_scale: int = max(1, ceili(window.y / max_view_height))
	var max_scale: int = max(min_scale, floori(window.y / min_view_height))
	var pixel_scale: int = clampi(default_scale + zoom_steps, min_scale, max_scale)
	zoom_steps = pixel_scale - default_scale
	target_zoom = pixel_scale / stretch
	if not animate:
		zoom = Vector2(target_zoom, target_zoom)
		zoom_velocity = 0.0
