extends PanelContainer

@export var item_slot_scene: PackedScene
var slots: Array = []

func _ready() -> void:
	add_to_group("pause_panes")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in PlayerState.bag_size:
		var item_slot = item_slot_scene.instantiate()
		item_slot.right_clicked.connect(func(): PlayerState.equip_from_bag(i))
		%BagSlots.add_child(item_slot)
		slots.append(item_slot)
	PlayerState.bag_changed.connect(refresh)
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bags") or (visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = not visible
	get_tree().paused = get_tree().get_nodes_in_group("pause_panes").any(func(pane): return pane.visible)

func refresh() -> void:
	for i in slots.size():
		slots[i].set_item(PlayerState.bag[i])
