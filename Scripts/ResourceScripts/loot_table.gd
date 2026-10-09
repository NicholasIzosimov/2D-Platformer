extends Resource

class_name LootTable

@export_range(0.0, 1.0) var item_chance: float = 0.1
@export var templates: Dictionary[GearTemplate, float] = {}
@export var gold_base: float = 1.0
@export var gold_per_level: float = 1.0
@export var gold_variance: float = 0.3
@export var currency: CurrencyData
@export var additional_loot_tables: Array[LootTable] = []

func roll_gold(level: int) -> int:
	var amount: float = (gold_base + gold_per_level * (level - 1)) * randf_range(1.0 - gold_variance, 1.0 + gold_variance)
	return max(roundi(amount), 0)

func all_templates() -> Dictionary:
	var result: Dictionary = templates.duplicate()
	for table in additional_loot_tables:
		var included: Dictionary = table.all_templates()
		for template in included:
			result[template] = result.get(template, 0.0) + included[template]
	return result

func roll_item(rules: GearRules, level: int, min_rarity: Rarity = null) -> GearData:
	var pool: Dictionary = all_templates()
	if pool.is_empty() or randf() >= item_chance:
		return null
	var total: float = 0.0
	for template in pool:
		total += pool[template]
	var r: float = randf() * total
	for template in pool:
		r -= pool[template]
		if r < 0.0:
			return rules.generate(template, level, min_rarity)
	return null
