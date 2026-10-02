extends Resource

class_name StatusEffect

@export var name: String
@export var icon: Texture2D
@export var is_debuff: bool
@export var damage: float
@export var affect_stat: Stat.Type
@export var stat_amount: float
@export var spell_duration: float
@export var tick_interval: float
@export var power_gain: float
@export var heal_percent: float = 0.0
@export_group("Glow")
@export var glow_color: Color = Color(1.0, 0.7, 0.4)
@export var glow_energy: float = 0.0
@export var glow_scale: float = 0.5
@export var aura_glows: bool = false
@export_group("Unit Frame Badge")
@export var frame_badge: SpriteFrames
@export var frame_badge_animation: StringName = &"default"
