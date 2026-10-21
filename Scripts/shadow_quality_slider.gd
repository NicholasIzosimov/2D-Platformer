extends HBoxContainer

@onready var slider: HSlider = %Slider
@onready var value_label: Label = %ValueLabel

func _ready() -> void:
	slider.min_value = 0
	slider.max_value = GraphicsSettings.SHADOW_SAMPLES.size() - 1
	slider.step = 1
	slider.value = GraphicsSettings.shadow_quality
	slider.value_changed.connect(_on_value_changed)
	update_label()

func _on_value_changed(value: float) -> void:
	GraphicsSettings.set_shadow_quality(int(value))
	update_label()

func update_label() -> void:
	value_label.text = GraphicsSettings.shadow_label()
