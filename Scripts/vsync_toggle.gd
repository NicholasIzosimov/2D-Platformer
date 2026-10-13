extends CheckButton

func _ready() -> void:
	text = "V-Sync"
	button_pressed = GraphicsSettings.vsync
	toggled.connect(GraphicsSettings.set_vsync)
