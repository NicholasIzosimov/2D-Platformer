extends CanvasLayer

const MAIN_MENU_SCENE: String = "res://Scenes/main_menu.tscn"
const PAUSE_GROUP: StringName = &"pause_panes"

@onready var main_panel: Control = %MainPanel
@onready var options_menu: Control = %OptionsMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(PAUSE_GROUP)
	%ResumeButton.pressed.connect(close)
	%OptionsButton.pressed.connect(show_options)
	%MainMenuButton.pressed.connect(go_to_main_menu)
	%QuitButton.pressed.connect(get_tree().quit)
	close()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if options_menu.visible:
		show_main_panel()
	elif visible:
		close()
	else:
		open()
	get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	show_main_panel()
	update_pause()

func close() -> void:
	visible = false
	update_pause()

func show_main_panel() -> void:
	main_panel.show()
	options_menu.hide()

func show_options() -> void:
	main_panel.hide()
	options_menu.show()

func go_to_main_menu() -> void:
	close()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func update_pause() -> void:
	get_tree().paused = get_tree().get_nodes_in_group(PAUSE_GROUP).any(func(pane): return pane.visible)
