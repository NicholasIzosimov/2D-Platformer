extends PanelContainer

@export var slot_scene: PackedScene
var shopkeeper: Shopkeeper
var slots: Array = []

func _ready() -> void:
	add_to_group("shop_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%Header.close_pressed.connect(close)

func open(new_shopkeeper: Shopkeeper) -> void:
	close()
	shopkeeper = new_shopkeeper
	%Header.title = shopkeeper.shop.title
	for i in shopkeeper.stock.stacks.size():
		var slot = slot_scene.instantiate()
		%StockSlots.add_child(slot)
		slots.append(slot)
	shopkeeper.stock.changed.connect(refresh)
	refresh()
	visible = true
	get_tree().call_group("bag_pane", "show_bag")

func close() -> void:
	if is_instance_valid(shopkeeper) and shopkeeper.stock.changed.is_connected(refresh):
		shopkeeper.stock.changed.disconnect(refresh)
	shopkeeper = null
	for slot in slots:
		slot.queue_free()
	slots.clear()
	visible = false

func refresh() -> void:
	for i in slots.size():
		var stack: ItemStack = shopkeeper.stock.stacks[i]
		slots[i].set_stack(stack, shopkeeper.price(stack) if stack else 0)

func _process(_delta: float) -> void:
	if shopkeeper == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(shopkeeper) or not shopkeeper.get_node("Interactable").in_range(player):
		close()

func _unhandled_input(event: InputEvent) -> void:
	if shopkeeper and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
