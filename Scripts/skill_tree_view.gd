@tool
class_name SkillTreeView
extends Control

@export var line_color: Color = Color(0.4, 0.4, 0.4)
@export var line_color_maxed: Color = Color(1.0, 0.85, 0.3)
@export var line_width: float = 3.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Engine.is_editor_hint():
		return
	PlayerState.talents_changed.connect(refresh)
	refresh()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func talent_nodes() -> Array[TalentNode]:
	var result: Array[TalentNode] = []
	collect_nodes(self, result)
	return result

func collect_nodes(holder: Node, result: Array[TalentNode]) -> void:
	for child in holder.get_children():
		if child is TalentNode:
			result.append(child)
		collect_nodes(child, result)

func refresh() -> void:
	for node in talent_nodes():
		if node.talent:
			node.refresh()
	queue_redraw()

func center_of(node: TalentNode) -> Vector2:
	return (get_global_transform().affine_inverse() * node.get_global_transform()) * (node.size / 2.0)

func _draw() -> void:
	for node in talent_nodes():
		for parent in node.requirement_nodes():
			var maxed: bool = not Engine.is_editor_hint() and parent.is_maxed()
			draw_line(center_of(parent), center_of(node), line_color_maxed if maxed else line_color, line_width)

func start_node() -> TalentNode:
	for node in talent_nodes():
		if node.requirement_nodes().is_empty():
			return node
	return null
