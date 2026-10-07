extends Camera2D

@export var follow_smoothing: float = 12.0
@export var lead_time: float = 0.10
@export var max_lead: float = 0.2
@export var lead_smoothing: float = 9
@export var target_view_height: float = 540.0
@export var min_view_height: float = 360.0
@export var max_view_height: float = 720.0
@export var zoom_duration: float = 0.12
var zoom_steps: int = 0
var zoom_tween: Tween

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing
	get_window().size_changed.connect(update_zoom)
	update_zoom()

func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var target_offset: Vector2 = (body.velocity * lead_time).limit_length(Yards.to_px(max_lead))
	offset = offset.lerp(target_offset, 1.0 - exp(-lead_smoothing * delta))

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
	var target: Vector2 = Vector2.ONE * pixel_scale / stretch
	if zoom_tween:
		zoom_tween.kill()
	if animate:
		zoom_tween = create_tween()
		zoom_tween.tween_property(self, "zoom", target, zoom_duration)
	else:
		zoom = target
