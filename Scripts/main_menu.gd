extends Control

const CLASSES_PATH: String = "res://Resources/Classes/"
const GAME_SCENE: String = "res://Scenes/combat_scene.tscn"

func _ready() -> void:
	for class_data in load_classes():
		var button := Button.new()
		button.text = class_data.name if class_data.name != "" else class_data.resource_path.get_file().get_basename().capitalize()
		button.pressed.connect(start_run.bind(class_data))
		%ClassList.add_child(button)

func load_classes() -> Array[ClassData]:
	var result: Array[ClassData] = []
	for file in ResourceLoader.list_directory(CLASSES_PATH):
		if not file.ends_with(".tres"):
			continue
		var resource = load(CLASSES_PATH + file)
		if resource is ClassData:
			result.append(resource)
	return result

func start_run(class_data: ClassData) -> void:
	PlayerState.start_run(class_data)
	get_tree().change_scene_to_file(GAME_SCENE)
