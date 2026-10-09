extends ItemData

class_name GearData

const GOLD_PER_LEVEL: float = 2.0
const GOLD_RARITY_EXPONENT: float = 2.0
enum Slot {HEAD, NECK, SHOULDERS, CHEST, CLOAK, HANDS, LEGS, FEET, RING, MAIN_HAND, CHARM}

@export var slot: Slot
@export var item_level: int = 1
@export var stats: Dictionary[Stat.Type, float] = {}
@export_group("Weapon")
@export var attack_speed: float = 0.0

func gold_value() -> int:
	if value > 0:
		return value
	var multiplier: float = rarity.budget_multiplier if rarity else 1.0
	return max(1, roundi(GOLD_PER_LEVEL * item_level * pow(multiplier, GOLD_RARITY_EXPONENT)))
