extends Resource

class_name GearTemplate

@export var name: String
@export var slot: GearData.Slot
@export var icon: Texture2D
@export var forced_stats: Dictionary[Stat.Type, float] = {}
@export var fixed_rarity: Rarity
@export_group("Weapon")
@export var attack_speed: float = 0.0
