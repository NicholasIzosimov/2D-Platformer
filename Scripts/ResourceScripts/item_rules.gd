extends Resource

class_name ItemRules

@export var rarities: Array[Rarity] = []
@export var budget_base: float = 4.0
@export var budget_per_level: float = 2.0
@export var budget_exponent: float = 1.2
@export var slot_budget: Dictionary[ItemData.Slot, float] = {}
@export var stat_costs: Dictionary[Stat.Type, float] = {}
@export var weapon_dps_per_budget: float = 0.5
@export var stat_pool: Dictionary[Stat.Type, float] = {}
@export var split_variance: float = 0.5
@export var armor_per_budget: float = 2.0
@export var armor_slots: Array[ItemData.Slot] = []

func roll_rarity() -> Rarity:
	var total: float = 0.0
	for rarity in rarities:
		total += rarity.weight
	var r: float = randf() * total
	for rarity in rarities:
		r -= rarity.weight
		if r < 0.0:
			return rarity
	return rarities.back()

func budget(item_level: int, rarity: Rarity, slot: ItemData.Slot) -> float:
	var level_budget: float = budget_base + budget_per_level * pow(max(item_level - 1, 0), budget_exponent)
	return level_budget * rarity.budget_multiplier * slot_budget.get(slot, 1.0)

func generate(template: ItemTemplate, item_level: int) -> ItemData:
	var item := ItemData.new()
	item.name = template.name if template.name != "" else ItemData.Slot.keys()[template.slot].capitalize()
	item.slot = template.slot
	item.icon = template.icon
	item.attack_speed = template.attack_speed
	item.item_level = item_level
	item.rarity = template.fixed_rarity if template.fixed_rarity else roll_rarity()
	var total_budget: float = budget(item_level, item.rarity, template.slot)
	var has_armor: bool = armor_slots.has(item.slot)
	var weights: Dictionary = pick_stats(template, item.rarity.stat_count - (1 if has_armor else 0))
	var total_weight: float = 0.0
	for stat in weights:
		total_weight += weights[stat]
	for stat in weights:
		var amount: float = total_budget * weights[stat] / total_weight / stat_costs.get(stat, 1.0)
		var percent: bool = Stat.PERCENT_STATS.has(stat)
		var rounded: float = snappedf(amount, 0.1) if percent else roundf(amount)
		if rounded == 0.0 and template.forced_stats.has(stat):
			rounded = 0.1 if percent else 1.0
		if rounded != 0.0:
			item.stats[stat] = rounded
	if item.attack_speed > 0.0:
		item.stats[Stat.Type.WEAPON_DAMAGE] = roundf(total_budget * weapon_dps_per_budget * item.attack_speed)
	if has_armor:
		item.stats[Stat.Type.ARMOR] = item.stats.get(Stat.Type.ARMOR, 0.0) + roundf(total_budget * armor_per_budget)
	return item

func pick_stats(template: ItemTemplate, count: int) -> Dictionary:
	var picked: Dictionary = {}
	for stat in template.forced_stats:
		if picked.size() >= count:
			break
		picked[stat] = template.forced_stats[stat]
	var chances: Dictionary = stat_pool.duplicate()
	for stat in picked:
		chances.erase(stat)
	for i in min(count - picked.size(), chances.size()):
		var stat = weighted_pick(chances)
		picked[stat] = 1.0
		chances.erase(stat)
	for stat in picked:
		picked[stat] *= randf_range(1.0 - split_variance, 1.0 + split_variance)
	return picked

func weighted_pick(chances: Dictionary):
	var total: float = 0.0
	for key in chances:
		total += chances[key]
	var r: float = randf() * total
	for key in chances:
		r -= chances[key]
		if r < 0.0:
			return key
	return chances.keys().back()
