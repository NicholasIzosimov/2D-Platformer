extends Resource

class_name AbilityData

@export var icon: Texture2D
@export var name: String
@export var power_cost: float
@export var cooldown: float
@export var cast_time: float
@export var triggers_gcd: bool
@export var range: float
@export var uses_hitbox: bool = false
@export var windup: float = 0.0
@export var effects: Array[AbilityEffect]
@export var custom_ability: CustomAbility
