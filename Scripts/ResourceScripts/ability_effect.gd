extends Resource

class_name AbilityEffect

@export var name: String
enum Stat {NONE, MOVE_SPEED, ARMOR}
@export var damage: float
@export var power_gain: float
@export var is_debuff: bool
@export var spell_duration: float
@export var tick_interval: float
@export var affect_stat: Stat
@export var stat_amount: float
@export var icon: Texture2D
