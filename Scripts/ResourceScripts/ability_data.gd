extends Resource

class_name AbilityData

@export var icon: Texture2D
@export var name: String
@export_group("Core")
@export var triggers_gcd: bool
@export var uses_hitbox: bool = false
@export var damage: float = 0.0
@export var cooldown: float
@export var power_gain: float = 0.0
@export var power_cost: float
@export var cast_time: float
@export var range: float
@export var min_range: float = 0.0
@export var effects: Array[StatusEffect]
@export var custom_ability: CustomAbility

@export_group("AoE")
@export var aoe_radius: float = 0.0
@export var aoe_max_targets: int = 0
@export var aoe_damage_multiplier: float = 1.0

@export_group("Projectile & Misc")
@export var is_projectile: bool = false
@export var windup_from_animation: bool = false
@export var projectile_speed: float = 600.0
@export var windup: float = 0.0
