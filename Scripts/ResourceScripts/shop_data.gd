extends Resource

class_name ShopData

@export var title: String = "Shop"
@export var loot: LootTable
@export var min_rarity: Rarity
@export var stock_count: int = 6
@export var price_multiplier: float = 5.0
@export var buyback_size: int = 6
@export var level_offset: int = 3
