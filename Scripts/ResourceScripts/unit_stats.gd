extends Node

const ARMOR_K: float = 400.0
const ARMOR_MAX: float = 0.75
const HEALTH_PER_VIGOR: float = 10.0
@export var unit_data: UnitData
var current_primary_stat: float
var power_data: PowerData
var current_power: float
var max_power: float
var current_power_generation: float
var current_health: float
var max_health: float
var current_vigor: float
var current_armor: float
var current_block_chance: float
var current_crit_chance: float
var current_crit_damage: float
var current_damage_reduction: float
var dots_can_crit: bool = false
var current_dodge_chance: float
var current_miss_chance: float
var current_move_speed: float
var current_parry_chance: float
var current_haste: float
var is_dead: bool = false

signal health_changed
signal died
signal power_changed(amount, show_text)
signal damage_taken(amount, crit_multiplier)
signal attack_missed

func _ready() -> void:
	current_vigor = unit_data.base_vigor
	max_health = unit_data.base_health + current_vigor * HEALTH_PER_VIGOR
	current_health = max_health
	current_primary_stat = unit_data.base_primary_stat
	current_armor = unit_data.base_armor
	current_damage_reduction = unit_data.base_damage_reduction
	current_block_chance = unit_data.base_block_chance
	current_crit_chance = unit_data.base_crit_chance
	current_crit_damage = unit_data.base_crit_damage
	current_dodge_chance = unit_data.base_dodge_chance
	current_miss_chance = unit_data.base_miss_chance
	current_move_speed = unit_data.base_move_speed
	current_parry_chance = unit_data.base_parry_chance
	current_haste = unit_data.base_haste
	set_power_data(unit_data.power)

func set_power_data(new_power: PowerData) -> void:
	power_data = new_power
	max_power = power_data.max_power
	current_power = power_data.max_power
	current_power_generation = power_data.power_generation

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

func modify_power_generation(amount: float) -> void:
	current_power_generation += amount
func modify_armor(amount: float) -> void:
	current_armor += amount
func modify_crit_chance(amount: float) -> void:
	current_crit_chance += amount
func modify_crit_damage(amount: float) -> void:
	current_crit_damage += amount
func modify_dodge_chance(amount: float) -> void:
	current_dodge_chance += amount
func modify_miss_chance(amount: float) -> void:
	current_miss_chance += amount
func modify_parry_chance(amount: float) -> void:
	current_parry_chance += amount
func modify_block_chance(amount: float) -> void:
	current_block_chance += amount
func modify_move_speed(amount: float) -> void:
	current_move_speed += amount
func modify_haste(amount: float) -> void:
	current_haste += amount
func modify_damage_reduction(amount: float) -> void:
	current_damage_reduction += amount
func modify_primary_stat(amount: float) -> void:
	current_primary_stat += amount
func modify_vigor(amount: float) -> void:
	current_vigor += amount
	modify_max_health(amount * HEALTH_PER_VIGOR)
	
func take_damage(raw_damage: float, crit_multiplier: float = 1.0) -> void:
	if is_dead:
		return
	var armor_reduction: float = get_armor_reduction()
	var damage: float = raw_damage * crit_multiplier
	damage *= 1.0 - armor_reduction
	damage *= 1.0 - clamp(current_damage_reduction, 0.0, 100.0) / 100.0
	damage_taken.emit(damage, crit_multiplier)
	modify_health(damage)

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

func get_armor_reduction() -> float:
	var armor: float = max(current_armor, 0.0)
	return ARMOR_MAX * armor / (armor + ARMOR_K)
