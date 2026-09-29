extends Node

var bonus_health: float = 0.0
var bonus_primary_stat: float = 0.0
var bonus_armor: float = 0.0
var bonus_damage_reduction: float = 0.0
var bonus_crit_chance: float = 0.0
var bonus_crit_damage: float = 0.0
var bonus_dodge_chance: float = 0.0
var bonus_miss_chance: float = 0.0
var bonus_parry_chance: float = 0.0
var bonus_block_chance: float = 0.0
var bonus_move_speed: float = 0.0
var bonus_haste: float = 0.0
var bonus_max_power: float = 0.0
var gold: int = 0
var class_data: ClassData
var learned_abilities: Array[AbilityData] = []
var max_abilities: int = 5
var equipped_abilities: Array[AbilityData] = []
var bonus_power_generation: float = 0.0
var level: int = 1
var xp: float = 0.0
var talent_points: int = 0
var bonus_vigor: float = 0.0

const XP_BASE: float = 100.0
const XP_GROWTH: float = 1.5

signal loadout_changed
signal gold_changed(new_amount)
signal xp_changed
signal leveled_up(new_level)

func _ready() -> void:
	equipped_abilities.resize(max_abilities)
	class_data = load("res://Resources/Classes/malefactor.tres")
	for ability in class_data.abilities:
		learn_ability(ability)
	equip_ability(class_data.abilities[0], 0)
	equip_ability(class_data.abilities[1], 1)
	
func learn_ability(ability: AbilityData) -> bool:
	if not class_data.abilities.has(ability):
		return false
	if learned_abilities.has(ability):
		return false
	learned_abilities.append(ability)
	return true

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
	
func unequip_slot(slot: int) -> void:
	equipped_abilities[slot] = null
	loadout_changed.emit()

func swap_slots(a: int, b: int) -> void:
	var temp = equipped_abilities[a]
	equipped_abilities[a] = equipped_abilities[b]
	equipped_abilities[b] = temp
	loadout_changed.emit()
	
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
	return XP_BASE * pow(level, XP_GROWTH)

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		talent_points += 1
		print("Level up! Now level ", level)
		leveled_up.emit(level)
	xp_changed.emit()
