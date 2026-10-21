class_name ShadowLayers
extends Node2D

const GROUP: String = "shadow_layers"
const MERGE_SHADER: Shader = preload("res://Resources/Shaders/shadow_merge.gdshader")
var layers: Dictionary = {}

func _enter_tree() -> void:
	add_to_group(GROUP)

func place(shadow: Node2D, light: Node) -> void:
	var key: int = light.get_instance_id() if light else 0
	var layer: CanvasGroup = layers.get(key)
	if layer == null:
		layer = CanvasGroup.new()
		layer.material = ShaderMaterial.new()
		layer.material.shader = MERGE_SHADER
		add_child(layer)
		layers[key] = layer
	if shadow.get_parent() != layer:
		shadow.reparent(layer)
		shadow.reset_physics_interpolation()

func _process(_delta: float) -> void:
	for key in layers.keys():
		if layers[key].get_child_count() == 0:
			layers[key].queue_free()
			layers.erase(key)
