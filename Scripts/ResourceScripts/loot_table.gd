extends Resource

class_name LootTable

@export_range(0.0, 1.0) var item_chance: float = 0.1
@export var templates: Dictionary[ItemTemplate, float] = {}
@export var gold_base: float = 1.0
@export var gold_per_level: float = 1.0
@export var gold_variance: float = 0.3

func roll_gold(level: int) -> int:
	var amount: float = (gold_base + gold_per_level * (level - 1)) * randf_range(1.0 - gold_variance, 1.0 + gold_variance)
	return max(roundi(amount), 0)

func roll_item(rules: ItemRules, level: int) -> ItemData:
	if templates.is_empty() or randf() >= item_chance:
		return null
	var total: float = 0.0
	for template in templates:
		total += templates[template]
	var r: float = randf() * total
	for template in templates:
		r -= templates[template]
		if r < 0.0:
			return rules.generate(template, level)
	return null
