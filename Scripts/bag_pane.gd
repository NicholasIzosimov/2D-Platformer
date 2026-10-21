extends DraggableWindow

@export var item_slot_scene: PackedScene
var slots: Array = []
var open: bool = false

func _ready() -> void:
	visible = open
	add_to_group("layout_preview")
	add_to_group("bag_pane")
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in PlayerState.bag_size:
		var item_slot = item_slot_scene.instantiate()
		item_slot.compare = true
		item_slot.right_clicked.connect(on_right_click.bind(i))
		%BagSlots.add_child(item_slot)
		slots.append(item_slot)
	PlayerState.bag_changed.connect(refresh)
	PlayerState.gold_changed.connect(func(_amount): refresh())
	refresh()
	%Header.close_pressed.connect(close)
func show_bag() -> void:
	open = true
	visible = true
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bags") or (visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	open = not open
	visible = open

func set_preview(value: bool) -> void:
	visible = value or open

func refresh() -> void:
	for i in slots.size():
		slots[i].set_stack(PlayerState.bag[i])
	%GoldLabel.text = str(PlayerState.gold)

func close() -> void:
	open = false
	visible = false

func on_right_click(index: int) -> void:
	var shop_window = get_tree().get_first_node_in_group("shop_window")
	if shop_window and shop_window.shopkeeper:
		shop_window.shopkeeper.sell(index)
	else:
		PlayerState.equip_from_bag(index)
