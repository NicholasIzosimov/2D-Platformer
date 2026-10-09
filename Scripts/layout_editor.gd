extends Control

const SAVE_PATH: String = "user://ui_layout.cfg"
const SECTION: String = "hud"
const FIT_GROUP: String = "layout_fit_content"
const MIN_HANDLE_SIZE: Vector2 = Vector2(48, 24)
const PREVIEW_GROUP: String = "layout_preview"
@export var unlock_button: Button
@export var grid: float = 8.0
@export var handle_color: Color = Color(0.3, 0.6, 1.0, 0.35)
var elements: Array[Control] = []
var moves: Dictionary = {}
var handles: Dictionary = {}
var toolbar: HBoxContainer
var dragging: Control = null
var drag_start_mouse: Vector2
var drag_start_move: Vector2

func _ready() -> void:
	add_to_group("pause_panes")
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	for child in get_parent().get_children():
		if child is Control and child != self:
			elements.append(child)
			if child is DraggableWindow:
				child.moved.connect(_on_window_moved.bind(child))
	build_toolbar()
	load_layout()
	if unlock_button:
		unlock_button.pressed.connect(set_unlocked.bind(true))
	get_parent().move_child.call_deferred(self, -1)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		set_unlocked(false)
		get_viewport().set_input_as_handled()

func set_unlocked(value: bool) -> void:
	visible = value
	get_tree().call_group(PREVIEW_GROUP, "set_preview", value)
	get_tree().paused = get_tree().get_nodes_in_group("pause_panes").any(func(pane): return pane.visible)
	if value:
		build_handles()
	else:
		dragging = null
		save_layout()

func build_toolbar() -> void:
	toolbar = HBoxContainer.new()
	add_child(toolbar)
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toolbar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toolbar.offset_top = 40.0
	add_toolbar_button("Lock", set_unlocked.bind(false))
	add_toolbar_button("Reset", reset_layout)

func add_toolbar_button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	toolbar.add_child(button)

func build_handles() -> void:
	for handle in handles.values():
		handle.queue_free()
	handles.clear()
	for element in elements:
		var handle := Panel.new()
		var style := StyleBoxFlat.new()
		style.bg_color = handle_color
		style.set_border_width_all(1)
		style.border_color = Color.WHITE
		handle.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = element.name
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		handle.add_child(label)
		handle.gui_input.connect(_on_handle_input.bind(element))
		add_child(handle)
		handles[element] = handle
	move_child(toolbar, -1)
	update_handles()

func update_handles() -> void:
	for element in handles:
		var rect: Rect2 = content_rect(element) if element.is_in_group(FIT_GROUP) else element.get_global_rect()
		handles[element].global_position = rect.position
		handles[element].size = rect.size.max(MIN_HANDLE_SIZE)

func content_rect(element: Control) -> Rect2:
	var own: Rect2 = element.get_global_rect()
	if not element is Container:
		return own
	var reserved := Rect2(own.position, element.custom_minimum_size * element.get_global_transform().get_scale())
	var content := Rect2()
	var found: bool = false
	if reserved.has_area():
		content = reserved
		found = true
	for child in element.get_children():
		if child is Control and child.visible:
			var child_rect: Rect2 = content_rect(child)
			content = child_rect if not found else content.merge(child_rect)
			found = true
	return content if found else own

func _on_handle_input(event: InputEvent, element: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = element
			drag_start_mouse = get_global_mouse_position()
			drag_start_move = moves.get(element, Vector2.ZERO)
		else:
			dragging = null
	elif event is InputEventMouseMotion and dragging == element:
		var wanted: Vector2 = drag_start_move + get_global_mouse_position() - drag_start_mouse
		var default_position: Vector2 = element.global_position - moves.get(element, Vector2.ZERO)
		var snapped_position: Vector2 = (default_position + wanted).snapped(Vector2(grid, grid))
		apply_move(element, snapped_position - default_position)
		update_handles()

func apply_move(element: Control, move: Vector2) -> void:
	var change: Vector2 = move - moves.get(element, Vector2.ZERO)
	if element.is_layout_rtl():
		change.x = -change.x
	element.offset_left += change.x
	element.offset_right += change.x
	element.offset_top += change.y
	element.offset_bottom += change.y
	moves[element] = move

func reset_layout() -> void:
	for element in elements:
		apply_move(element, Vector2.ZERO)
	update_handles()

func load_layout() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for element in elements:
		apply_move(element, config.get_value(SECTION, element.name, Vector2.ZERO))

func save_layout() -> void:
	var config := ConfigFile.new()
	for element in elements:
		config.set_value(SECTION, element.name, moves.get(element, Vector2.ZERO))
	config.save(SAVE_PATH)
	
func _process(_delta: float) -> void:
	if visible:
		update_handles()


func _on_window_moved(delta: Vector2, element: Control) -> void:
	moves[element] = moves.get(element, Vector2.ZERO) + delta
	save_layout()
