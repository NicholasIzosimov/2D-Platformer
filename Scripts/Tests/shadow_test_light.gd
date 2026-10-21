class_name ShadowTestLight
extends Node2D

@export var follow_mouse: bool = true
@export var height: float = 24.0
@export var height_step: float = 4.0
@export var min_height: float = 0.0
@export var max_height: float = 200.0

@onready var glow: PointLight2D = $Glow

func _process(_delta: float) -> void:
	if follow_mouse:
		global_position = get_global_mouse_position().round()
	glow.position = Vector2(0.0, -height)
	glow.height = height
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not follow_mouse:
		return
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or not button.shift_pressed:
		return
	if button.button_index == MOUSE_BUTTON_WHEEL_UP:
		height = minf(height + height_step, max_height)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		height = maxf(height - height_step, min_height)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 1.5, Color.WHITE)
	draw_line(Vector2.ZERO, Vector2(0.0, -height), Color(1, 1, 1, 0.4))
	draw_circle(Vector2(0.0, -height), 2.0, Color.YELLOW)
