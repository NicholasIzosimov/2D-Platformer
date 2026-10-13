extends PanelContainer

func _ready() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		visible = not visible
		get_viewport().set_input_as_handled()
