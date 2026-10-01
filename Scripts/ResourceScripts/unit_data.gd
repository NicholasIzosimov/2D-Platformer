extends Resource

class_name UnitData

@export var name: String
@export var power: PowerData = preload("res://Resources/Powers/bot_power.tres")
@export var base_health: float = 10.0
@export var base_vigor: float = 1.0
@export var base_primary_stat: float = 0.0
@export var base_armor: float
@export var xp_reward: float = 1.0
@export var base_move_speed: float = 150.0
@export var base_crit_chance: float
@export var base_crit_damage: float
@export var base_miss_chance: float
@export var base_damage_reduction: float = 0.0
@export var base_dodge_chance: float
@export var base_parry_chance: float
@export var base_block_chance: float
@export var base_haste: float
@export var level_scaling: LevelScaling = preload("res://Resources/Progression/level_scaling.tres")
@export var auto_attack: AbilityData = preload("res://Resources/Abilities/auto_attack.tres")
@export var base_swing_time: float = 2.0
@export var out_of_combat_regen: float = 1.0
