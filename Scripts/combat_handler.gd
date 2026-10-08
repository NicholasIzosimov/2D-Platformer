extends Node

const CRIT_MIN: float = 1.5
const CRIT_MAX: float = 2.0
const PRIMARY_STAT_SCALING: float = 0.01
const AP_REFERENCE_TIME: float = 3.0
const DOT_REFERENCE_DURATION: float = 15.0
const LINE_OF_SIGHT_MASK: int = 1
const HURTBOX_MASK: int = 16
const MISS_LEVEL_SCALE: float = 3.0
const MISS_LEVEL_GROWTH: float = 1.4
const CRIT_PER_LEVEL_DIFFERENCE: float = 1.0
const PROJECTILE_SCENE: PackedScene = preload("res://Scenes/projectile.tscn")
const EFFECTS: SpriteFrames = preload("res://Resources/Animations/effect_animations.tres")
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
signal cast_failed(reason)
signal unit_killed(unit)

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
	if ability.out_of_combat_only and get_node("../CombatState").in_combat:
		return "Can't do that in combat"
	if ability.requires_target:
		var reach: String = reach_error(ability, target)
		if reach != "":
			return reach
	if ability.triggers_gcd and gcd_active:
		return "Global cooldown active"
	if ability_cooldowns.has(ability):
		return "Ability on cooldown"
	if ability.power_cost > own_stats.current_power:
		return "Not enough power: " + own_stats.power_data.name
	if ability.requires_target:
		aim_at(target)
	ability_used.emit(ability)

	if ability.triggers_gcd:
		var gcd: float = own_stats.hasted(gcd_duration)
		gcd_active = true
		gcd_started.emit(gcd)
		gcd_timer.start(gcd)

	if ability.cast_time > 0:
		var cast_time: float = own_stats.hasted(ability.cast_time)
		is_casting = true
		cast_started.emit(ability, cast_time)
		cast_timer = Timer.new()
		cast_timer.wait_time = cast_time
		cast_timer.one_shot = true
		add_child(cast_timer)
		var target_ref: WeakRef = weakref(target) if target else null
		cast_timer.timeout.connect(func():
			var cast_target = target_ref.get_ref() if target_ref else null
			is_casting = false
			cast_finished.emit()
			cast_timer.queue_free()
			if ability.requires_target:
				if not is_instance_valid(cast_target) or cast_target.get_node("UnitStats").is_dead:
					return
				var failed: String = reach_error(ability, cast_target)
				if failed != "":
					cast_failed.emit(failed)
					return
				aim_at(cast_target)
			own_stats.modify_power(-ability.power_cost)
			deliver(ability, cast_target)
		)
		cast_timer.start()
	else:
		own_stats.modify_power(-ability.power_cost)
		deliver(ability, target)
	return ""
	
func swing(ability, target) -> bool:
	if reach_error(ability, target) != "":
		return false
	aim_at(target)
	ability_used.emit(ability)
	deliver(ability, target)
	return true
	
func resolve_effects(ability, target) -> void:
	hit_target(ability, target)
	if ability.aoe_radius <= 0.0:
		return
	var center: Vector2 = target.get_node("Hurtbox").global_position
	play_effect(ability, "_aoe", center)
	var others: Array = hostile_units_in_radius(center, Yards.to_px(ability.aoe_radius))
	others.erase(target)
	others.sort_custom(func(a, b): return a.global_position.distance_to(center) < b.global_position.distance_to(center))
	if ability.aoe_max_targets > 0:
		others.resize(min(others.size(), ability.aoe_max_targets - 1))
	for unit in others:
		hit_target(ability, unit, ability.aoe_damage_multiplier)

func hit_target(ability, target, damage_multiplier: float = 1.0) -> void:
	var target_stats = target.get_node("UnitStats")
	if randf() * 100.0 < miss_chance_against(target_stats):
		target_stats.register_miss()
		return
	if base_damage(ability) > 0.0:
		var from_ability: bool = ability != own_stats.unit_data.auto_attack
		target_stats.take_damage(ability_damage(ability) * damage_multiplier, roll_crit(target_stats), from_ability, self)
	if ability.power_gain != 0.0:
		own_stats.modify_power(ability.power_gain)
	for effect in ability.effects:
		target.get_node("CombatHandler").apply_effect(effect, self)
	play_effect(ability, "_impact", target.get_node("Hurtbox").global_position)

func hostile_units_in_radius(center: Vector2, radius: float) -> Array:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = HURTBOX_MASK
	var units: Array = []
	for result in get_parent().get_world_2d().direct_space_state.intersect_shape(query, 64):
		var unit: Node = result.collider.owner
		if units.has(unit) or unit.get_node("UnitStats").is_dead or not is_hostile_to(unit):
			continue
		units.append(unit)
	return units

func is_hostile_to(unit: Node) -> bool:
	return unit.is_in_group("player") != get_parent().is_in_group("player")

func deliver(ability, target) -> void:
	start_cooldown(ability)
	var windup: float = ability.windup
	if ability.windup_from_animation:
		windup = get_node("../UnitAnimator").time_to_impact()
	if windup <= 0.0:
		release(ability, target)
		return
	var windup_timer := Timer.new()
	windup_timer.one_shot = true
	windup_timer.wait_time = windup
	add_child(windup_timer)
	var target_ref: WeakRef = weakref(target) if target else null
	windup_timer.timeout.connect(func():
		var windup_target = target_ref.get_ref() if target_ref else null
		windup_timer.queue_free()
		if own_stats.is_dead:
			return
		if ability.requires_target and (not is_instance_valid(windup_target) or windup_target.get_node("UnitStats").is_dead):
			return
		if ability.requires_target and not ability.is_projectile:
			var still_hits: bool = hitbox_hits(windup_target) if ability.uses_hitbox else reach_error(ability, windup_target) == ""
			if not still_hits:
				windup_target.get_node("UnitStats").register_miss()
				return
		release(ability, windup_target)
	)
	windup_timer.start()

func release(ability, target) -> void:
	if ability.spawn_scene:
		spawn_object(ability)
	if not ability.requires_target:
		for effect in ability.effects:
			apply_effect(effect, self)
		return
	if ability.is_projectile:
		fire_projectile(ability, target)
	else:
		resolve_effects(ability, target)

func spawn_object(ability) -> void:
	var spawned = ability.spawn_scene.instantiate()
	if spawned.has_method("setup"):
		spawned.setup(get_parent())
	var offset: Vector2 = ability.spawn_offset
	if get_node("../AnimatedSprite2D").flip_h:
		offset.x = -offset.x
	spawned.position = get_parent().position + offset * Yards.PIXELS
	get_parent().get_parent().add_child(spawned)
	
func fire_projectile(ability, target) -> void:
	var start: Vector2 = get_node("../AttackPivot").global_position
	var direction: Vector2 = start.direction_to(target.get_node("Hurtbox").global_position)
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.setup(self, ability, direction, Yards.to_px(ability.range))
	get_parent().get_parent().add_child(projectile)
	projectile.global_position = start

func visual_key(resource) -> String:
	var override = resource.get("animation_key")
	if override:
		return override
	var path: String = resource.resource_path
	if path == "" or path.contains("::"):
		return ""
	return path.get_file().get_basename()

func play_effect(ability, suffix: String, at: Vector2) -> void:
	var anim: String = visual_key(ability) + suffix
	if not EFFECTS.has_animation(anim):
		return
	var effect := AnimatedSprite2D.new()
	effect.sprite_frames = EFFECTS
	effect.z_index = 10
	effect.animation_finished.connect(effect.queue_free)
	get_parent().get_parent().add_child(effect)
	effect.global_position = at
	effect.play(anim)
	
func start_cooldown(ability) -> void:
	if ability.cooldown > 0:
		var timer: SceneTreeTimer = get_tree().create_timer(ability.cooldown, false)
		ability_cooldowns[ability] = timer
		cooldown_started.emit(ability, ability.cooldown)
		timer.timeout.connect(_end_cooldown.bind(ability))
		
func cooldown_left(ability) -> float:
	var timer: SceneTreeTimer = ability_cooldowns.get(ability)
	return timer.time_left if timer else 0.0
	
func in_reach(ability, target) -> bool:
	if ability.uses_hitbox:
		var pivot: Node2D = get_node("../AttackPivot")
		var direction: Vector2 = pivot.global_position.direction_to(target.get_node("Hurtbox").global_position)
		return hitbox_overlaps(target, aimed_hitbox_transform(direction))
	var distance: float = get_parent().global_position.distance_to(target.global_position)
	return distance <= Yards.to_px(ability.range) and distance >= Yards.to_px(ability.min_range)
	
func reach_error(ability, target) -> String:
	if not in_reach(ability, target):
		return "Out of range"
	if not units_have_line_of_sight(get_parent(), target):
		return "Target not in line of sight"
	return ""
	
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
	own_stats.modify_stat(effect.affect_stat, effect.stat_amount)
	var tick_timer: Timer = null
	if effect.tick_interval > 0.0:
		tick_timer = Timer.new()
		tick_timer.wait_time = effect.tick_interval
		add_child(tick_timer)
		var caster_ref: WeakRef = weakref(caster) if caster else null
		tick_timer.timeout.connect(func():
			var source = caster_ref.get_ref() if caster_ref else null
			var damage: float = effect.damage
			var crit_multiplier: float = 1.0
			if is_instance_valid(source):
				if effect.damage > 0.0:
					damage = source.scaled_damage(effect.damage, source.effect_coefficient(effect))
				if source.own_stats.dots_can_crit:
					crit_multiplier = source.roll_crit(own_stats)
				if effect.power_gain != 0.0:
					source.own_stats.modify_power(effect.power_gain)
			if damage > 0.0:
				var living_caster: bool = is_instance_valid(source) and not source.own_stats.is_dead
				own_stats.take_damage(damage, crit_multiplier, true, source if living_caster else null)
			if effect.heal_percent > 0.0:
				own_stats.heal(own_stats.max_health * effect.heal_percent / 100.0)
		)
		tick_timer.start()
	var duration_timer := Timer.new()
	duration_timer.wait_time = effect.spell_duration
	duration_timer.one_shot = true
	add_child(duration_timer)
	duration_timer.timeout.connect(func():
		if tick_timer:
			tick_timer.stop()
			tick_timer.queue_free()
		own_stats.modify_stat(effect.affect_stat, -effect.stat_amount)
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
	own_stats.modify_power(own_stats.power_generation(get_node("../CombatState").in_combat), false)
	
func miss_chance_against(target_stats: Node) -> float:
	var level_diff: int = target_stats.level - own_stats.level
	var base_miss: float = own_stats.get_stat(Stat.Type.MISS_CHANCE) - own_stats.hit_percent()
	return base_miss + MISS_LEVEL_SCALE * (pow(MISS_LEVEL_GROWTH, level_diff) - 1.0)

func crit_chance_against(target_stats: Node) -> float:
	var level_diff: int = target_stats.level - own_stats.level
	return own_stats.crit_percent() - CRIT_PER_LEVEL_DIFFERENCE * level_diff

func roll_crit(target_stats: Node) -> float:
	if randf() * 100.0 < crit_chance_against(target_stats):
		return randf_range(CRIT_MIN, CRIT_MAX) + own_stats.get_stat(Stat.Type.CRIT_DAMAGE)
	return 1.0
	
func scaled_damage(amount: float, coefficient: float) -> float:
	var primary_bonus: float = 1.0 + own_stats.get_stat(Stat.Type.PRIMARY) * PRIMARY_STAT_SCALING
	var damage_bonus: float = 1.0 + own_stats.get_stat(Stat.Type.DAMAGE_PERCENT) / 100.0
	return (amount + own_stats.ability_power() * coefficient) * primary_bonus * damage_bonus

func base_damage(ability) -> float:
	var amount: float = ability.damage
	if ability.uses_weapon_damage:
		amount += own_stats.get_stat(Stat.Type.WEAPON_DAMAGE)
	return amount

func ability_damage(ability) -> float:
	return scaled_damage(base_damage(ability), ability_coefficient(ability))


func ability_coefficient(ability) -> float:
	if ability == own_stats.unit_data.auto_attack:
		return own_stats.base_swing_time() / AP_REFERENCE_TIME * ability.ap_scaling
	var time: float = max(ability.cast_time, gcd_duration)
	return min(time / AP_REFERENCE_TIME, 1.0) * ability.ap_scaling

func effect_coefficient(effect) -> float:
	return effect.tick_interval / DOT_REFERENCE_DURATION * effect.ap_scaling
	
func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, LINE_OF_SIGHT_MASK)
	var hit: Dictionary = get_parent().get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func units_have_line_of_sight(a: Node2D, b: Node2D) -> bool:
	return has_line_of_sight(a.get_node("CollisionShape2D").global_position, 
	b.get_node("CollisionShape2D").global_position)

func effect_time_left(effect) -> float:
	if not active_effects.has(effect):
		return 0.0
	return active_effects[effect]["duration_timer"].time_left
	
func register_kill(unit: Node) -> void:
	if own_stats.power_data.power_on_kill != 0.0:
		own_stats.modify_power(own_stats.power_data.power_on_kill)
	unit_killed.emit(unit)
