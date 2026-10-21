extends CanvasLayer

const OFFSET: Vector2 = Vector2(16, 16)
var box: VBoxContainer
var shown_sections: Array = []

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	box = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	box.hide()
	add_child(box)

func _process(_delta: float) -> void:
	var source: Control = find_source(get_viewport().gui_get_hovered_control())
	var sections: Array = source.tooltip_sections() if source else []
	if sections != shown_sections:
		rebuild(sections)
	if box.visible:
		place()

func find_source(control: Control) -> Control:
	while control:
		if control.has_method("tooltip_sections"):
			return control
		control = control.get_parent() as Control
	return null

func rebuild(sections: Array) -> void:
	shown_sections = sections
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	for text in sections:
		var label: Control = RichTooltip.make(text)
		if label == null:
			continue
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var panel := PanelContainer.new()
		panel.theme_type_variation = &"TooltipPanel"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		box.add_child(panel)
	box.visible = box.get_child_count() > 0
	box.reset_size()

func place() -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var pos: Vector2 = mouse + OFFSET
	if pos.x + box.size.x > screen.x:
		pos.x = mouse.x - OFFSET.x - box.size.x
	pos.y = min(pos.y, screen.y - box.size.y)
	box.position = pos
