extends PanelContainer

@export var slot_scene: PackedScene
var shopkeeper: Shopkeeper
var slots: Array = []
var pending_index: int = -1
var pending_buyback: bool = false
var buyback_slots: Array = []

func _ready() -> void:
	add_to_group("shop_window")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	%Header.close_pressed.connect(close)
	%Confirm.confirmed.connect(_on_confirmed)

func open(new_shopkeeper: Shopkeeper) -> void:
	close()
	shopkeeper = new_shopkeeper
	%Header.title = shopkeeper.shop.title
	for i in shopkeeper.stock.stacks.size():
		var slot = slot_scene.instantiate()
		slot.clicked.connect(ask_buy.bind(i))
		%StockSlots.add_child(slot)
		slots.append(slot)
	shopkeeper.stock.changed.connect(refresh)
	shopkeeper.buyback_changed.connect(refresh_buyback)
	refresh_buyback()
	refresh()
	visible = true
	get_tree().call_group("bag_pane", "show_bag")

func close() -> void:
	if is_instance_valid(shopkeeper):
		if shopkeeper.stock.changed.is_connected(refresh):
			shopkeeper.stock.changed.disconnect(refresh)
		if shopkeeper.buyback_changed.is_connected(refresh_buyback):
			shopkeeper.buyback_changed.disconnect(refresh_buyback)
		shopkeeper.clear_buyback()
	shopkeeper = null
	for slot in slots + buyback_slots:
		slot.queue_free()
	slots.clear()
	buyback_slots.clear()
	visible = false
	%Confirm.hide()

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

func refresh_buyback() -> void:
	for slot in buyback_slots:
		slot.queue_free()
	buyback_slots.clear()
	if shopkeeper == null:
		return
	for i in shopkeeper.buyback.size():
		var stack: ItemStack = shopkeeper.buyback[i]
		var slot = slot_scene.instantiate()
		slot.clicked.connect(ask_buy_back.bind(i))
		%BuybackSlots.add_child(slot)
		slot.set_stack(stack, shopkeeper.sell_value(stack))
		buyback_slots.append(slot)
	%BuybackLabel.visible = not buyback_slots.is_empty()
	#reset_size()
	
func ask_buy(index: int) -> void:
	var stack: ItemStack = shopkeeper.stock.stacks[index]
	if stack == null:
		return
	pending_index = index
	pending_buyback = false
	%Confirm.dialog_text = "Buy %s for %d gold?" % [stack.item.name, shopkeeper.price(stack)]
	%Confirm.popup_centered()

func _on_confirmed() -> void:
	if shopkeeper == null:
		return
	if pending_buyback:
		shopkeeper.buy_back(pending_index)
	else:
		shopkeeper.buy(pending_index)

func ask_buy_back(index: int) -> void:
	var stack: ItemStack = shopkeeper.buyback[index]
	pending_index = index
	pending_buyback = true
	%Confirm.dialog_text = "Buy back %s for %d gold?" % [stack.item.name, shopkeeper.sell_value(stack)]
	%Confirm.popup_centered()
