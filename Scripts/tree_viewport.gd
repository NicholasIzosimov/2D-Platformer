extends Control

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_step: float = 0.1
var tree: SkillTreeView
var dragging: bool = false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	for child in get_children():
		if child is SkillTreeView:
			tree = child
	center_on_start.call_deferred()

func center_on_start() -> void:
	var start: TalentNode = tree.start_node()
	var target: Vector2 = tree.center_of(start) if start else Vector2.ZERO
	tree.position = size / 2.0 - target * tree.scale.x

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_at(event.position, 1.0 + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_at(event.position, 1.0 / (1.0 + zoom_step))
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		tree.position += event.relative

func zoom_at(point: Vector2, factor: float) -> void:
	var new_zoom: float = clamp(tree.scale.x * factor, min_zoom, max_zoom)
	var point_in_tree: Vector2 = (point - tree.position) / tree.scale.x
	tree.scale = Vector2(new_zoom, new_zoom)
	tree.position = point - point_in_tree * new_zoom
