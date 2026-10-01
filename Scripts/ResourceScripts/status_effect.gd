extends Resource

class_name StatusEffect

@export var name: String
@export var icon: Texture2D
@export var is_debuff: bool
@export var damage: float
@export var affect_stat: Stat
enum Stat {NONE, MOVE_SPEED, ARMOR}
@export var stat_amount: float
@export var spell_duration: float
@export var tick_interval: float
@export var power_gain: float
