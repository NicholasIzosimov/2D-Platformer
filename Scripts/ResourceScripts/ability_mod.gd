extends Resource

class_name AbilityMod

@export var ability: AbilityData
@export_enum("range", "min_range", "cooldown", "cast_time", "power_cost", "damage", "windup", "aoe_radius", "aoe_max_targets", "aoe_damage_multiplier") var property: String = "range"
@export var amount_per_rank: float = 0.0
