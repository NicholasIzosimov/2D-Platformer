extends Node


const PLAYER_DATA_PATH: String = "res://Resources/Units/player.tres"

var bonus_stats: Dictionary[Stat.Type, float] = {}
var gold: int = 0
var player_data: UnitData
var ability_copies: Dictionary = {}
var learned_abilities: Array[AbilityData] = []
var max_abilities: int = 20
var equipped_abilities: Array[AbilityData] = []
var level: int = 1
var xp: float = 0.0
var talent_points: int = 0
var talent_ranks: Dictionary = {}
var equipped_gear: Dictionary[GearData.Slot, GearData] = {}
var xp_curve: XpCurve
var bag_size: int = 16
var quests: Array[Quest] = []
var in_combat: bool = false
var gear_rules: GearRules
var bag: Array[ItemStack] = []

signal loadout_changed
signal gold_changed(new_amount)
signal xp_changed
signal leveled_up(new_level)
signal bonus_stat_changed(stat, amount)
signal talents_changed
signal gear_changed
signal bag_changed
signal quests_changed
signal quest_completed(quest)
signal action_failed(reason)

func _init() -> void:
	xp_curve = load("res://Resources/Progression/xp_curve.tres")
	gear_rules = load("uid://muk03tvj2dbx")
	player_data = load(PLAYER_DATA_PATH)
	start_run()

func start_run() -> void:
	bonus_stats.clear()
	gold = 0
	ability_copies.clear()
	learned_abilities.clear()
	equipped_abilities.clear()
	equipped_abilities.resize(max_abilities)
	level = 1
	xp = 0.0
	talent_points = 0
	talent_ranks.clear()
	equipped_gear.clear()
	quests.clear()
	for i in player_data.abilities.size():
		equip_ability(learn_ability(player_data.abilities[i]), i)
	bag.clear()
	bag.resize(bag_size)
	for template in player_data.starting_gear:
		equip_item(gear_rules.generate(template, level))

func get_ability(original: AbilityData) -> AbilityData:
	if not ability_copies.has(original):
		var copy: AbilityData = original.duplicate()
		var path: String = original.resource_path
		if copy.animation_key == "" and path != "" and not path.contains("::"):
			copy.animation_key = path.get_file().get_basename()
		ability_copies[original] = copy
	return ability_copies[original]

func learn_ability(original: AbilityData) -> AbilityData:
	var copy: AbilityData = get_ability(original)
	if not learned_abilities.has(copy):
		learned_abilities.append(copy)
	return copy

func equip_ability(ability: AbilityData, slot: int) -> bool:
	if not learned_abilities.has(ability):
		return false
	if slot < 0 or slot >= max_abilities:
		return false
	var existing_slot = equipped_abilities.find(ability)
	if existing_slot != -1:
		equipped_abilities[existing_slot] = null
	equipped_abilities[slot] = ability
	loadout_changed.emit()
	return true

func equip_in_free_slot(ability: AbilityData) -> void:
	var slot: int = equipped_abilities.find(null)
	if slot != -1:
		equip_ability(ability, slot)

func unequip_slot(slot: int) -> void:
	equipped_abilities[slot] = null
	loadout_changed.emit()

func swap_slots(a: int, b: int) -> void:
	var temp = equipped_abilities[a]
	equipped_abilities[a] = equipped_abilities[b]
	equipped_abilities[b] = temp
	loadout_changed.emit()

func add_bonus_stat(stat: Stat.Type, amount: float) -> void:
	bonus_stats[stat] = bonus_stats.get(stat, 0.0) + amount
	bonus_stat_changed.emit(stat, amount)

func talent_rank(talent: TalentData) -> int:
	return talent_ranks.get(talent, 0)

func points_spent() -> int:
	var total: int = 0
	for talent in talent_ranks:
		total += talent_ranks[talent]
	return total

func is_talent_unlocked(talent: TalentData, parents: Array[TalentData]) -> bool:
	if points_spent() < talent.points_required:
		return false
	if parents.is_empty():
		return true
	for parent in parents:
		if talent_rank(parent) >= parent.max_ranks:
			return true
	return false

func can_spend(talent: TalentData, parents: Array[TalentData]) -> bool:
	return talent_points > 0 and talent_rank(talent) < talent.max_ranks and is_talent_unlocked(talent, parents)

func spend_talent_point(talent: TalentData, parents: Array[TalentData]) -> bool:
	if not can_spend(talent, parents):
		return false
	talent_points -= 1
	talent_ranks[talent] = talent_rank(talent) + 1
	apply_talent_rank(talent)
	talents_changed.emit()
	return true

func apply_talent_rank(talent: TalentData) -> void:
	for stat in talent.stat_bonuses:
		add_bonus_stat(stat, talent.stat_bonuses[stat])
	for mod in talent.ability_mods:
		var ability: AbilityData = get_ability(mod.ability)
		ability.set(mod.property, ability.get(mod.property) + mod.amount_per_rank)
	if talent.grants_ability and talent_rank(talent) == 1:
		equip_in_free_slot(learn_ability(talent.grants_ability))

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount > gold:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func xp_to_next_level() -> float:
	return xp_curve.xp_to_next_level(level)

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		talent_points += 1
		leveled_up.emit(level)
		talents_changed.emit()
	xp_changed.emit()

func equip_item(item: GearData) -> GearData:
	var replaced: GearData = unequip_item(item.slot)
	equipped_gear[item.slot] = item
	for stat in item.stats:
		add_bonus_stat(stat, item.stats[stat])
	gear_changed.emit()
	return replaced

func unequip_item(slot: GearData.Slot) -> GearData:
	var item: GearData = equipped_gear.get(slot)
	if item == null:
		return null
	equipped_gear.erase(slot)
	for stat in item.stats:
		add_bonus_stat(stat, -item.stats[stat])
	gear_changed.emit()
	return item

func weapon_speed() -> float:
	var weapon: GearData = equipped_gear.get(GearData.Slot.MAIN_HAND)
	return weapon.attack_speed if weapon else 0.0

func add_to_bag(item: ItemData, amount: int = 1) -> int:
	var left: int = amount
	for stack in bag:
		if left == 0:
			break
		if stack and stack.item == item:
			var moved: int = min(left, stack.space())
			stack.amount += moved
			left -= moved
	while left > 0:
		var index: int = bag.find(null)
		if index == -1:
			break
		var placed: int = min(left, max(item.max_stack, 1))
		bag[index] = ItemStack.new(item, placed)
		left -= placed
	if left < amount:
		bag_changed.emit()
	if left > 0:
		action_failed.emit("Inventory is full")
	return left

func equip_from_bag(index: int) -> void:
	var stack: ItemStack = bag[index]
	if stack == null or not (stack.item is GearData):
		return
	if in_combat:
		action_failed.emit("Can't do that in combat")
		return
	var replaced: GearData = equip_item(stack.item)
	bag[index] = ItemStack.new(replaced) if replaced else null
	bag_changed.emit()

func unequip_to_bag(slot: GearData.Slot) -> bool:
	if not equipped_gear.has(slot):
		return false
	if in_combat:
		action_failed.emit("Can't do that in combat")
		return false
	if bag.find(null) == -1:
		action_failed.emit("Inventory is full")
		return false
	add_to_bag(unequip_item(slot))
	return true

func add_quest(quest: Quest) -> void:
	quests.append(quest)
	quests_changed.emit()

func register_kill(unit_data: UnitData) -> void:
	for quest in quests.duplicate():
		if quest.target != unit_data:
			continue
		quest.progress += 1
		if quest.is_complete():
			complete_quest(quest)
	quests_changed.emit()

func complete_quest(quest: Quest) -> void:
	quests.erase(quest)
	add_xp(quest.xp_reward)
	quest_completed.emit(quest)
	
func is_quest_target(unit_data: UnitData) -> bool:
	return quests.any(func(quest): return quest.target == unit_data)

func remove_from_bag(index: int) -> void:
	bag[index] = null
	bag_changed.emit()
