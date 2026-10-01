extends Node

const PIXELS_PER_UNIT = 50.0
const CRIT_MIN: float = 1.5
const CRIT_MAX: float = 2.0
const PRIMARY_STAT_SCALING: float = 0.01
const LINE_OF_SIGHT_MASK: int = 1
const HURTBOX_MASK: int = 16
const MISS_LEVEL_SCALE: float = 3.0
const MISS_LEVEL_GROWTH: float = 1.4
var active_effects: Dictionary = {}
var ability_cooldowns: Dictionary = {}
var own_stats: Node
var gcd_duration = 1.5
var gcd_active: bool = false
var is_casting: bool = false
var cast_timer: Timer
var gcd_timer: Timer
signal effect_applied(effect)
signal effect_expired(effect)
signal gcd_started(duration)
signal cast_started(ability, duration)
signal cast_cancelled()
signal cooldown_started(ability, duration)
signal cast_finished()
signal ability_used(ability)

func _ready() -> void:
	own_stats = get_node("../UnitStats")
	gcd_timer = Timer.new()
	gcd_timer.one_shot = true
	add_child(gcd_timer)
	gcd_timer.timeout.connect(_end_gcd)
	var regen_timer = Timer.new()
	regen_timer.wait_time = 1.0
	add_child(regen_timer)
	regen_timer.timeout.connect(_regen_tick)
	regen_timer.start()
	
func cast_ability(ability, target) -> String:
	if is_casting:
		return "Already casting"
	if not in_reach(ability, target):
		return "Out of range"
	if not units_have_line_of_sight(get_parent(), target):
		return "Target not in line of sight"
	if ability.triggers_gcd and gcd_active:
		return "Global cooldown active"
	if ability_cooldowns.has(ability):
		return "Ability on cooldown"
	if ability.power_cost > own_stats.current_power:
		return "Not enough power: " + own_stats.power_data.name
	aim_at(target)
	ability_used.emit(ability)
	
	if ability.triggers_gcd:
		gcd_active = true
		gcd_started.emit(gcd_duration)
		gcd_timer.start(gcd_duration)

	if ability.cast_time > 0:
		is_casting = true
		cast_started.emit(ability, ability.cast_time)
		cast_timer = Timer.new()
		cast_timer.wait_time = ability.cast_time
		cast_timer.one_shot = true
		add_child(cast_timer)
		cast_timer.timeout.connect(func():
			is_casting = false
			cast_finished.emit()
			cast_timer.queue_free()
			if not is_instance_valid(target) or target.get_node("UnitStats").is_dead:
				return
			own_stats.modify_power(-ability.power_cost)
			deliver(ability, target)
		)
		cast_timer.start()
	else:
		own_stats.modify_power(-ability.power_cost)
		deliver(ability, target)
	return ""
	
func swing(ability, target) -> bool:
	if not in_reach(ability, target):
		return false
	if not units_have_line_of_sight(get_parent(), target):
		return false
	aim_at(target)
	ability_used.emit(ability)
	deliver(ability, target)
	return true
	
func resolve_effects(ability, target) -> void:
	var target_stats = target.get_node("UnitStats")
	if randf() * 100.0 < miss_chance_against(target_stats):
		target_stats.register_miss()
	else:
		var crit_multiplier: float = roll_crit()
		for effect in ability.effects:
			if effect.tick_interval == 0:
				target_stats.take_damage(effect_damage(effect), crit_multiplier)
				own_stats.modify_power(effect.power_gain)
			elif effect.tick_interval > 0:
				target.get_node("CombatHandler").apply_effect(effect, self)

func deliver(ability, target) -> void:
	start_cooldown(ability)
	if ability.windup <= 0.0:
		resolve_effects(ability, target)
		return
	var windup_timer := Timer.new()
	windup_timer.one_shot = true
	windup_timer.wait_time = ability.windup
	add_child(windup_timer)
	windup_timer.timeout.connect(func():
		windup_timer.queue_free()
		if own_stats.is_dead or not is_instance_valid(target) or target.get_node("UnitStats").is_dead:
			return
		if ability.uses_hitbox and not hitbox_hits(target):
			target.get_node("UnitStats").register_miss()
			return
		resolve_effects(ability, target)
	)
	windup_timer.start()

func start_cooldown(ability) -> void:
	if ability.cooldown > 0:
		ability_cooldowns[ability] = true
		cooldown_started.emit(ability, ability.cooldown)
		get_tree().create_timer(ability.cooldown, false).timeout.connect(_end_cooldown.bind(ability))

func in_reach(ability, target) -> bool:
	if ability.uses_hitbox:
		var pivot: Node2D = get_node("../AttackPivot")
		var direction: Vector2 = pivot.global_position.direction_to(target.get_node("Hurtbox").global_position)
		return hitbox_overlaps(target, aimed_hitbox_transform(direction))
	return get_parent().global_position.distance_to(target.global_position) <= ability.range * PIXELS_PER_UNIT


func aim_at(target: Node2D) -> void:
	var pivot: Node2D = get_node("../AttackPivot")
	pivot.rotation = pivot.global_position.direction_to(target.get_node("Hurtbox").global_position).angle()

func hitbox_hits(target: Node2D) -> bool:
	var shape_node: CollisionShape2D = get_node("../AttackPivot/AttackHitbox/CollisionShape2D")
	return hitbox_overlaps(target, shape_node.global_transform)

func aimed_hitbox_transform(direction: Vector2) -> Transform2D:
	var pivot: Node2D = get_node("../AttackPivot")
	var shape_node: CollisionShape2D = get_node("../AttackPivot/AttackHitbox/CollisionShape2D")
	var relative: Transform2D = pivot.global_transform.affine_inverse() * shape_node.global_transform
	return Transform2D(direction.angle(), pivot.global_position) * relative
	
func hitbox_overlaps(target: Node2D, shape_transform: Transform2D) -> bool:
	var shape_node: CollisionShape2D = get_node("../AttackPivot/AttackHitbox/CollisionShape2D")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = shape_transform
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = HURTBOX_MASK
	for result in get_parent().get_world_2d().direct_space_state.intersect_shape(query):
		if result.collider == target.get_node("Hurtbox"):
			return true
	return false
	
func cast_cancel() -> void:
	if is_casting and cast_timer:
		cast_timer.stop()
		cast_timer.queue_free()
		is_casting = false
		gcd_active = false
		gcd_timer.stop()
		cast_cancelled.emit()

func apply_effect(effect, caster: Node) -> void:
	if active_effects.has(effect):
		active_effects[effect]["duration_timer"].start()
		effect_applied.emit(effect)
		return

	var target_stats = own_stats

	var tick_timer = Timer.new()
	tick_timer.wait_time = effect.tick_interval
	add_child(tick_timer)
	tick_timer.timeout.connect(func():
		var crit_multiplier: float = 1.0
		if is_instance_valid(caster) and caster.own_stats.dots_can_crit:
			crit_multiplier = caster.roll_crit()
		var damage: float = effect.damage
		if is_instance_valid(caster):
			damage = caster.effect_damage(effect)
		target_stats.take_damage(damage, crit_multiplier)
		if is_instance_valid(caster):
			caster.own_stats.modify_power(effect.power_gain)
	)
	tick_timer.start()
	
	var duration_timer = Timer.new()
	duration_timer.wait_time = effect.spell_duration
	duration_timer.one_shot = true
	add_child(duration_timer)
	duration_timer.timeout.connect(func():
		tick_timer.queue_free()
		duration_timer.queue_free()
		active_effects.erase(effect)
		effect_expired.emit(effect)
	)
	duration_timer.start()

	active_effects[effect] = {"tick_timer": tick_timer, "duration_timer": duration_timer}
	effect_applied.emit(effect)

	
func _end_gcd() -> void:
	gcd_active = false

func _end_cooldown(ability) -> void:
	ability_cooldowns.erase(ability)
	
func _regen_tick() -> void:
	own_stats.modify_power(own_stats.current_power_generation, false)
	
func roll_crit() -> float:
	if randf() * 100.0 < own_stats.current_crit_chance:
		return randf_range(CRIT_MIN, CRIT_MAX) + own_stats.current_crit_damage
	return 1.0
	
func miss_chance_against(target_stats: Node) -> float:
	var level_diff: int = target_stats.level - own_stats.level
	return own_stats.current_miss_chance + MISS_LEVEL_SCALE * (pow(MISS_LEVEL_GROWTH, level_diff) - 1.0)
	
func effect_damage(effect) -> float:
	return effect.damage * (1.0 + own_stats.current_primary_stat * PRIMARY_STAT_SCALING)

func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, LINE_OF_SIGHT_MASK)
	var hit: Dictionary = get_parent().get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func units_have_line_of_sight(a: Node2D, b: Node2D) -> bool:
	return has_line_of_sight(a.get_node("CollisionShape2D").global_position, 
	b.get_node("CollisionShape2D").global_position)
