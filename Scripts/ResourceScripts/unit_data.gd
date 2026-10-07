extends Resource

class_name UnitData

@export var base_stats: Dictionary[Stat.Type, float] = {
	Stat.Type.VIGOR: 1.0,
	Stat.Type.MOVE_SPEED: 3.0,
	Stat.Type.CRIT_CHANCE: 5.0,
	Stat.Type.MISS_CHANCE: 10.0,
}
@export var name: String
@export var power: PowerData = preload("res://Resources/Powers/bot_power.tres")
@export var abilities: Array[AbilityData] = []
@export var starting_gear: Array[ItemData] = []
@export var loot_table: LootTable
@export var base_health: float = 10.0
@export var xp_reward: float = 1.0
@export var level_scaling: LevelScaling = preload("res://Resources/Progression/level_scaling.tres")
@export var auto_attack: AbilityData = preload("res://Resources/Abilities/auto_attack.tres")
@export var base_swing_time: float = 2.0
@export var out_of_combat_regen: float = 1.0
@export_group("Portrait")
@export var portrait: Texture2D
@export var portrait_offset: Vector2 = Vector2.ZERO
@export var portrait_zoom: float = 1.0
