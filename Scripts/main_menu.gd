extends Control

const GAME_SCENE: String = "res://Scenes/combat_scene.tscn"

func _ready() -> void:
	%StartButton.pressed.connect(start_run)

func start_run() -> void:
	PlayerState.start_run()
	get_tree().change_scene_to_file(GAME_SCENE)
