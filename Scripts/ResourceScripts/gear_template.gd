extends Resource

class_name GearTemplate

@export var name: String
@export var slot: GearData.Slot
@export var icon: Texture2D
@export_group("Weapon")
@export var attack_speed: float = 0.0
@export_group("Overrides")
@export var fixed_rarity: Rarity
@export var fixed_item_level: int = 0
@export var forced_stats: Dictionary[Stat.Type, float] = {}
@export var bonus_stats: Dictionary[Stat.Type, float] = {}
