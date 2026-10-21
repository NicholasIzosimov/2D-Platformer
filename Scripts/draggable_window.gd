class_name DraggableWindow
extends PanelContainer

signal moved(delta)
var dragging: bool = false
var drag_offset: Vector2
var drag_start: Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		if dragging:
			drag_offset = get_global_mouse_position() - position
			drag_start = position
		elif position != drag_start:
			moved.emit(position - drag_start)
	elif event is InputEventMouseMotion and dragging:
		var screen: Vector2 = get_viewport_rect().size
		position = (get_global_mouse_position() - drag_offset).clamp(Vector2.ZERO, screen - size)
