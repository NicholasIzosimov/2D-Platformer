extends Resource

class_name TalentData

@export var name: String
@export var icon: Texture2D
@export_multiline var description: String
@export var max_ranks: int = 1
@export var row: int = 0
@export var column: float = 0.0
@export var parents: Array[TalentData] = []

@export_group("Per Rank")
@export var stat_bonuses: Dictionary[Stat.Type, float] = {}
@export var ability_mods: Array[AbilityMod] = []

@export_group("Unlock")
@export var grants_ability: AbilityData
