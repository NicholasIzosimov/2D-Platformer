extends Node

const ARMOR_K: float = 400.0
const ARMOR_MAX: float = 0.75
const DAMAGE_VARIANCE: float = 0.1
const HEALTH_PER_VIGOR: float = 10.0
const RATING_PER_PERCENT_BASE: float = 10.0
const RATING_PER_PERCENT_GROWTH: float = 0.1
@export var unit_data: UnitData
var values: Dictionary[Stat.Type, float] = {}
var power_data: PowerData
var current_power: float
var max_power: float
var current_health: float
var max_health: float
var dots_can_crit: bool = false
var is_dead: bool = false
var level: int = 1

signal damage_taken(amount, crit_multiplier, from_ability)
signal health_changed
signal died
signal power_changed(amount, show_text)
signal attack_missed
signal level_changed
signal stat_changed(stat)

func _ready() -> void:
	values = unit_data.base_stats.duplicate()
	max_health = unit_data.base_health + get_stat(Stat.Type.VIGOR) * HEALTH_PER_VIGOR
	current_health = max_health
	set_power_data(unit_data.power)
	apply_level_scaling(1, level)
	assert(max_health > 0.0, "%s has no health: set base_health or vigor" % unit_data.name)

func get_stat(stat: Stat.Type) -> float:
	return values.get(stat, 0.0)

func modify_stat(stat: Stat.Type, amount: float) -> void:
	if amount == 0.0:
		return
	values[stat] = get_stat(stat) + amount
	match stat:
		Stat.Type.VIGOR:
			modify_max_health(amount * HEALTH_PER_VIGOR)
		Stat.Type.MAX_POWER:
			max_power += amount
			current_power += amount
			power_changed.emit(0.0, false)
	stat_changed.emit(stat)

func set_level(new_level: int) -> void:
	if is_node_ready():
		apply_level_scaling(level, new_level)
	level = new_level
	level_changed.emit()

func apply_level_scaling(from_level: int, to_level: int) -> void:
	var scaling: LevelScaling = unit_data.level_scaling
	if scaling == null:
		return
	modify_stat(Stat.Type.VIGOR, scaling.vigor_at(to_level) - scaling.vigor_at(from_level))
	modify_stat(Stat.Type.PRIMARY, scaling.primary_stat_at(to_level) - scaling.primary_stat_at(from_level))
	modify_stat(Stat.Type.ARMOR, scaling.armor_at(to_level) - scaling.armor_at(from_level))

func set_power_data(new_power: PowerData) -> void:
	power_data = new_power
	max_power = power_data.max_power + get_stat(Stat.Type.MAX_POWER)
	current_power = max_power * power_data.starting_power_percent / 100.0

func power_generation(in_combat: bool) -> float:
	if in_combat:
		return power_data.power_generation + get_stat(Stat.Type.POWER_GENERATION)
	return power_data.out_of_combat_generation

func modify_health(damage: float) -> void:
	if is_dead:
		return
	current_health = max(0.0, current_health - damage)
	health_changed.emit(damage)
	if current_health == 0.0:
		is_dead = true
		died.emit()

func modify_power(amount: float, show_text: bool = true) -> void:
	if is_dead:
		return
	current_power = clamp(current_power + amount, 0.0, max_power)
	power_changed.emit(amount, show_text)

func take_damage(raw_damage: float, crit_multiplier: float = 1.0, from_ability: bool = false, source: Node = null) -> void:
	if is_dead:
		return
	var damage: float = raw_damage * crit_multiplier
	damage *= 1.0 - get_armor_reduction()
	damage *= 1.0 - clamp(get_stat(Stat.Type.DAMAGE_REDUCTION), 0.0, 100.0) / 100.0
	damage *= randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	damage_taken.emit(damage, crit_multiplier, from_ability)
	modify_health(damage)
	if is_dead and source != null:
		source.register_kill(get_parent())

func register_miss() -> void:
	attack_missed.emit()

func modify_max_health(amount: float) -> void:
	max_health += amount
	current_health += amount
	health_changed.emit(0.0)

func heal_to_full() -> void:
	if is_dead:
		return
	current_health = max_health
	health_changed.emit(0.0)

func heal(amount: float) -> void:
	if is_dead or current_health >= max_health:
		return
	current_health = min(current_health + amount, max_health)
	health_changed.emit(0.0)

func get_armor_reduction() -> float:
	var armor: float = max(get_stat(Stat.Type.ARMOR), 0.0)
	return ARMOR_MAX * armor / (armor + ARMOR_K)

func rating_to_percent(rating: float) -> float:
	return rating / (RATING_PER_PERCENT_BASE * (1.0 + RATING_PER_PERCENT_GROWTH * (level - 1)))

func hit_percent() -> float:
	return get_stat(Stat.Type.HIT_CHANCE) + rating_to_percent(get_stat(Stat.Type.HIT_RATING))

func crit_percent() -> float:
	return get_stat(Stat.Type.CRIT_CHANCE) + rating_to_percent(get_stat(Stat.Type.CRIT_RATING))
