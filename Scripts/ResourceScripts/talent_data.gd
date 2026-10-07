extends Resource

class_name TalentData

@export var name: String
@export var icon: Texture2D
@export_multiline var description: String
@export var max_ranks: int = 1
@export var points_required: int = 0

@export_group("Per Rank")
@export var stat_bonuses: Dictionary[Stat.Type, float] = {}
@export var ability_mods: Array[AbilityMod] = []

@export_group("Unlock")
@export var grants_ability: AbilityData
