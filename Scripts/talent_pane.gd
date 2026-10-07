extends PanelContainer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_panes")
	PlayerState.talents_changed.connect(refresh_points)
	refresh_points()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("talent_tree") or (visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = not visible
	get_tree().paused = get_tree().get_nodes_in_group("pause_panes").any(func(pane): return pane.visible)

func refresh_points() -> void:
	%Points.text = "Talent Points: %d" % PlayerState.talent_points
