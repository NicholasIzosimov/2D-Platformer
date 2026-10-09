extends PanelContainer

@export var slot_scene: PackedScene
@export var cursor_offset: Vector2 = Vector2(32, 64)
var contents: LootContents
var source: Interactable
var slots: Array = []

func _ready() -> void:
	add_to_group("loot_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%Header.close_pressed.connect(close)

func open(new_contents: LootContents, new_source: Interactable, title: String) -> void:
	close()
	contents = new_contents
	source = new_source
	%Header.title = title
	for i in contents.stacks.size():
		var slot = slot_scene.instantiate()
		slot.left_clicked.connect(func(): contents.take(i))
		%LootSlots.add_child(slot)
		slots.append(slot)
	contents.changed.connect(refresh)
	refresh()
	if contents:
		place_at_mouse()
		visible = true

func place_at_mouse() -> void:
	size = get_combined_minimum_size()
	var screen: Vector2 = get_viewport_rect().size
	var target: Vector2 = get_viewport().get_mouse_position() - cursor_offset
	position = target.clamp(Vector2.ZERO, screen - size)

func close() -> void:
	if contents and contents.changed.is_connected(refresh):
		contents.changed.disconnect(refresh)
	contents = null
	source = null
	for slot in slots:
		slot.queue_free()
	slots.clear()
	visible = false

func refresh() -> void:
	for i in slots.size():
		slots[i].set_stack(contents.stacks[i])
	if contents.is_empty():
		close()

func _process(_delta: float) -> void:
	if contents == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(source) or not source.in_range(player):
		close()

func _unhandled_input(event: InputEvent) -> void:
	if contents and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
