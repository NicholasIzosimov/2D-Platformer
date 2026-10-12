class_name HeightSource
extends Node2D

const HEIGHT_LAYER: int = 1 << 1
const ENCODE_SHADER: Shader = preload("res://Resources/Shaders/Tests/height_encode.gdshader")
const LIT_SHADER: Shader = preload("res://Resources/Shaders/Tests/lit.gdshader")

static var next_id: int = 1
static var lit_material: ShaderMaterial

var object_id: float
var height_materials: Array[ShaderMaterial] = []
var copies: Array = []

func _ready() -> void:
	visibility_layer |= HEIGHT_LAYER
	object_id = next_id / 255.0
	next_id = next_id % 255 + 1
	for node in find_children("*", "", true, false):
		if node is Sprite2D or node is AnimatedSprite2D:
			use_lit_material(node)
			add_copy(node)

func use_lit_material(sprite: CanvasItem) -> void:
	if sprite.material != null:
		return
	if lit_material == null:
		lit_material = ShaderMaterial.new()
		lit_material.shader = LIT_SHADER
	sprite.material = lit_material

func add_copy(source: Node2D) -> void:
	var copy: Node2D = source.duplicate(0)
	copy.material = make_height_material(source.material)
	copy.visibility_layer = HEIGHT_LAYER
	if copy is AnimatedSprite2D:
		(copy as AnimatedSprite2D).speed_scale = 0.0
	add_child(copy, false, Node.INTERNAL_MODE_BACK)
	copies.append([source, copy])

func make_height_material(source_material: Material) -> ShaderMaterial:
	var height_material := ShaderMaterial.new()
	height_material.shader = ENCODE_SHADER
	if source_material is ShaderMaterial:
		for uniform in ENCODE_SHADER.get_shader_uniform_list():
			var value: Variant = (source_material as ShaderMaterial).get_shader_parameter(uniform.name)
			if value != null:
				height_material.set_shader_parameter(uniform.name, value)
	height_material.set_shader_parameter("object_id", object_id)
	height_materials.append(height_material)
	return height_material

func _process(_delta: float) -> void:
	for height_material in height_materials:
		height_material.set_shader_parameter("ground_y", global_position.y)
	for pair in copies:
		sync_copy(pair[0], pair[1])

func sync_copy(source: Node2D, copy: Node2D) -> void:
	copy.global_transform = source.global_transform
	copy.visible = source.is_visible_in_tree()
	if source is AnimatedSprite2D:
		var from := source as AnimatedSprite2D
		var to := copy as AnimatedSprite2D
		if to.animation != from.animation:
			to.animation = from.animation
		to.frame = from.frame
		to.flip_h = from.flip_h
		to.flip_v = from.flip_v
	elif source is Sprite2D:
		var from := source as Sprite2D
		var to := copy as Sprite2D
		to.frame = from.frame
		to.flip_h = from.flip_h
		to.flip_v = from.flip_v
