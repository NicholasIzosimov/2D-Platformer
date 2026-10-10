extends ItemData

class_name GearData

enum Slot {HEAD, NECK, SHOULDERS, CHEST, CLOAK, HANDS, LEGS, FEET, RING, MAIN_HAND, CHARM}

@export var slot: Slot
@export var item_level: int = 1
@export var stats: Dictionary[Stat.Type, float] = {}
@export_group("Weapon")
@export var attack_speed: float = 0.0
