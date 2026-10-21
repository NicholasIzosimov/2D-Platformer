class_name Shopkeeper
extends Prop

@export var shop: ShopData
@export var gear_rules: GearRules
var stock: LootContents
var buyback: Array[ItemStack] = []
signal buyback_changed

func _ready() -> void:
	super._ready()
	$Interactable.interacted.connect(_on_interacted)
	$Sprite.play("hamster_idle")

func _on_interacted(_unit: Node) -> void:
	if stock == null:
		stock = LootContents.roll_stock(shop.loot, gear_rules, PlayerState.level + shop.level_offset, shop.stock_count, shop.min_rarity)
	get_tree().get_first_node_in_group("shop_window").open(self)

func price(stack: ItemStack) -> int:
	return max(1, roundi(stack.item.gold_value() * shop.price_multiplier)) * stack.amount

func save_state() -> Variant:
	return stock

func load_state(data: Variant) -> void:
	stock = data

func buy(index: int) -> void:
	var stack: ItemStack = stock.stacks[index]
	if stack == null:
		return
	var cost: int = price(stack)
	if PlayerState.gold < cost:
		PlayerState.action_failed.emit("Not enough gold")
		return
	if PlayerState.add_to_bag(stack.item, stack.amount) > 0:
		return
	PlayerState.spend_gold(cost)
	stock.remove(index)


func sell_value(stack: ItemStack) -> int:
	return stack.item.gold_value() * stack.amount

func sell(bag_index: int) -> void:
	var stack: ItemStack = PlayerState.bag[bag_index]
	if stack == null:
		return
	PlayerState.add_gold(sell_value(stack))
	PlayerState.remove_from_bag(bag_index)
	buyback.push_front(stack)
	if buyback.size() > shop.buyback_size:
		buyback.pop_back()
	buyback_changed.emit()

func buy_back(index: int) -> void:
	var stack: ItemStack = buyback[index]
	var cost: int = sell_value(stack)
	if PlayerState.gold < cost:
		PlayerState.action_failed.emit("Not enough gold")
		return
	if PlayerState.add_to_bag(stack.item, stack.amount) > 0:
		return
	PlayerState.spend_gold(cost)
	buyback.remove_at(index)
	buyback_changed.emit()

func clear_buyback() -> void:
	buyback.clear()
	buyback_changed.emit()
