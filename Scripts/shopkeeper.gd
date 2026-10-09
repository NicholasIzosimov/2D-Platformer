class_name Shopkeeper
extends Prop

@export var shop: ShopData
@export var gear_rules: GearRules
var stock: LootContents

func _ready() -> void:
	super._ready()
	$Interactable.interacted.connect(_on_interacted)
	$Sprite.play("hamster_idle")

func _on_interacted(_unit: Node) -> void:
	if stock == null:
		stock = LootContents.roll_stock(shop.loot, gear_rules, PlayerState.level, shop.stock_count, shop.min_rarity)
	for stack in stock.stacks:
		print(stack.item.name if stack else "(sold)")

func save_state() -> Variant:
	return stock

func load_state(data: Variant) -> void:
	stock = data
