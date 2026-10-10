extends Resource

class_name GearRules

@export var rarities: Array[Rarity] = []
@export var slot_budget: Dictionary[GearData.Slot, float] = {}
@export var stat_costs: Dictionary[Stat.Type, float] = {}
@export var stat_pool: Dictionary[Stat.Type, float] = {}
@export var armor_slots: Array[GearData.Slot] = []
var split_variance: float = 0.5
var armor_per_budget: float = 2.0
var weapon_dps_per_budget: float = 0.5
var budget_base: float = 4.0
var budget_per_level: float = 2.0
var budget_exponent: float = 1.2
var gold_per_budget: float = 1.0
var gold_rarity_exponent: float = 2.0
var value_variance: float = 0.15

func roll_rarity(min_rarity: Rarity = null) -> Rarity:
	var options: Array[Rarity] = rarities.slice(max(rarities.find(min_rarity), 0))
	var total: float = 0.0
	for rarity in options:
		total += rarity.weight
	var r: float = randf() * total
	for rarity in options:
		r -= rarity.weight
		if r < 0.0:
			return rarity
	return options.back()

func roll_stats(item: GearData, template: GearTemplate, count: int) -> void:
	var stat_budget: float = budget(item.item_level, item.rarity, item.slot)
	var weights: Dictionary = pick_stats(template, count)
	var total_weight: float = 0.0
	for stat in weights:
		total_weight += weights[stat]
	for stat in weights:
		var amount: float = stat_budget * weights[stat] / total_weight / stat_costs.get(stat, 1.0)
		var percent: bool = Stat.PERCENT_STATS.has(stat)
		var rounded: float = snappedf(amount, 0.1) if percent else roundf(amount)
		if rounded == 0.0 and template.forced_stats.has(stat):
			rounded = 0.1 if percent else 1.0
		if rounded != 0.0:
			item.stats[stat] = rounded

func level_budget(item_level: int) -> float:
	return budget_base + budget_per_level * pow(max(item_level - 1, 0), budget_exponent)

func budget(item_level: int, rarity: Rarity, slot: GearData.Slot) -> float:
	return level_budget(item_level) * rarity.budget_multiplier * slot_budget.get(slot, 1.0)

func generate(template: GearTemplate, item_level: int, min_rarity: Rarity = null) -> GearData:
	assert(template.slot != GearData.Slot.MAIN_HAND or template.attack_speed > 0.0, "%s: Main Hand template needs an Attack Speed" % template.name)
	var item := GearData.new()
	item.name = template.name if template.name != "" else GearData.Slot.keys()[template.slot].capitalize()
	item.slot = template.slot
	item.icon = template.icon
	item.attack_speed = template.attack_speed
	item.item_level = template.fixed_item_level if template.fixed_item_level > 0 else item_level
	item.rarity = template.fixed_rarity if template.fixed_rarity else roll_rarity(min_rarity)
	var base: Dictionary = base_values(item)
	for stat in base:
		item.stats[stat] = base[stat]
	roll_stats(item, template, item.rarity.stat_count - base.size())
	for stat in template.bonus_stats:
		item.stats[stat] = item.stats.get(stat, 0.0) + template.bonus_stats[stat]
	item.value = item_value(item)
	return item
	
func base_values(item: GearData) -> Dictionary:
	var values: Dictionary = {}
	var rarity_budget: float = level_budget(item.item_level) * item.rarity.budget_multiplier
	if item.attack_speed > 0.0:
		values[Stat.Type.WEAPON_DAMAGE] = roundf(rarity_budget * weapon_dps_per_budget * item.attack_speed)
	if armor_slots.has(item.slot):
		values[Stat.Type.ARMOR] = roundf(rarity_budget * slot_budget.get(item.slot, 1.0) * armor_per_budget)
	return values
	
func pick_stats(template: GearTemplate, count: int) -> Dictionary:
	var picked: Dictionary = {}
	for stat in template.forced_stats:
		if picked.size() >= count:
			break
		if Stat.BASE_STATS.has(stat):
			continue
		picked[stat] = template.forced_stats[stat]
	var chances: Dictionary = stat_pool.duplicate()
	for stat in picked:
		chances.erase(stat)
	for stat in Stat.BASE_STATS:
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

func item_value(item: GearData) -> int:
	var points: float = 0.0
	for stat in item.stats:
		points += absf(item.stats[stat]) * stat_costs.get(stat, 1.0)
	var rarity_premium: float = pow(item.rarity.budget_multiplier, gold_rarity_exponent - 1.0)
	return max(1, roundi(points * rarity_premium * gold_per_budget * randf_range(1.0 - value_variance, 1.0 + value_variance)))
