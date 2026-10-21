class_name WindowHeader
extends HBoxContainer

signal close_pressed
@export var title: String = "":
	set(value):
		title = value
		if is_node_ready():
			$Title.text = value

func _ready() -> void:
	$Title.text = title
	$CloseButton.pressed.connect(close_pressed.emit)
