extends Node

@export var speed_variance: float = 0.05
@export var hp_slow_factor: float = 0.3
@export var path_bias: float = 20.0
@export var weave_angle: float = 15.0
@export var weave_speed: float = 2.0
@export var leash_time: float = 5.0
@export var wander_speed_factor: float = 0.4
@export var corpse_time: float = 3.0
@export var retreat_buffer: float = 1.0
@export var retreat_speed_factor: float = 0.9
@export var separation_radius: float = 0.96
@export var separation_strength: float = 1.6
@export var aggro_range: float = 22.0
@export var wander_radius: float = 3.0
@export var social_radius: float = 5.0
var target: Node
var flow: Node
var feet_offset: Vector2
var bias: float
var weave_phase: float
var time: float = 0.0
var aggro: bool = false
var out_of_range_timer: float = 0.0
var wander_target: Vector2
var wander_timer: float = 0.0
var dead: bool = false
var retreating: bool = false

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	get_node("../UnitStats").died.connect(_on_died)
	var stats = get_node("../UnitStats")
	stats.modify_stat(Stat.Type.MOVE_SPEED, stats.get_stat(Stat.Type.MOVE_SPEED) * randf_range(-speed_variance, speed_variance))
	flow = get_tree().get_first_node_in_group("flow_field")
	var enemy = get_parent()
	feet_offset = get_node("../CollisionShape2D").position
	enemy.global_position = flow.find_free_position(enemy.global_position + feet_offset) - feet_offset
	bias = deg_to_rad(randf_range(-path_bias, path_bias))
	weave_phase = randf() * TAU
	wander_target = enemy.global_position
	stats.damage_taken.connect(_on_damage_taken)
	
func _physics_process(delta: float) -> void:
	if dead:
		return
	time += delta
	var enemy = get_parent()
	var stats = get_node("../UnitStats")
	var combat_handler = get_node("../CombatHandler")
	var distance = enemy.global_position.distance_to(target.global_position)
	var in_range: bool = combat_handler.in_reach(stats.unit_data.auto_attack, target)
	update_retreat(stats, combat_handler, distance)
	var sees_player: bool = distance <= Yards.to_px(aggro_range) and combat_handler.units_have_line_of_sight(enemy, target)
	if sees_player:
		start_aggro()
	elif aggro:
		out_of_range_timer += delta
		if out_of_range_timer >= leash_time:
			aggro = false
			wander_target = enemy.global_position
			wander_timer = 0.0

	if not aggro:
		idle_wander(enemy, stats, delta)
	elif combat_handler.is_casting:
		enemy.velocity = Vector2.ZERO
	elif retreating:
		var away: Vector2 = target.global_position.direction_to(enemy.global_position)
		enemy.velocity = away * Yards.to_px(stats.get_stat(Stat.Type.MOVE_SPEED)) * retreat_speed_factor
	elif (in_range or has_close_attack(stats, combat_handler)) and sees_player:
		enemy.velocity = Vector2.ZERO
	else:
		var direction: Vector2 = flow.get_direction(enemy.global_position + feet_offset)
		if direction == Vector2.ZERO:
			direction = enemy.global_position.direction_to(target.global_position)
		var wander_amount: float = clamp((distance - Yards.to_px(3.0)) / Yards.to_px(6.0), 0.0, 1.0)
		if not sees_player:
			wander_amount = 0.0
		var angle: float = bias + sin(time * weave_speed + weave_phase) * deg_to_rad(weave_angle)
		direction = direction.rotated(angle * wander_amount)
		var hp_lost: float = 1.0 - stats.current_health / stats.max_health
		var speed: float = Yards.to_px(stats.get_stat(Stat.Type.MOVE_SPEED)) * (1.0 - hp_lost * hp_slow_factor)
		enemy.velocity = direction * speed

	get_node("../UnitAnimator").face_target = target if aggro else null
	get_node("../AutoAttack").target = target if aggro else null
	if aggro:
		target.get_node("CombatState").refresh()
	if aggro and sees_player and not combat_handler.is_casting:
		use_abilities(stats, combat_handler)
	enemy.velocity += get_separation(enemy)
	enemy.move_and_slide()

func _on_died() -> void:
	dead = true
	var enemy = get_parent()
	enemy.remove_from_group("enemies")
	enemy.add_to_group("corpses")
	get_node("../CombatHandler").cast_cancel()
	get_node("../CollisionShape2D").set_deferred("disabled", true)
	get_node("../Bars").visible = false
	var sprite = get_node("../AnimatedSprite2D")
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, corpse_time)
	tween.tween_callback(enemy.queue_free)
	target.get_node("CombatState").end_soon()
	
func get_separation(enemy: Node2D) -> Vector2:
	var radius: float = Yards.to_px(separation_radius)
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == enemy:
			continue
		var offset: Vector2 = enemy.global_position - other.global_position
		var dist: float = offset.length()
		if dist < radius:
			if dist < 0.01:
				offset = Vector2.RIGHT.rotated(randf() * TAU)
			push += offset.normalized() * (1.0 - dist / radius)
	return push * Yards.to_px(separation_strength)

func idle_wander(enemy: Node2D, stats: Node, delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(2.0, 4.0)
		wander_target = enemy.global_position
		var combat_handler = get_node("../CombatHandler")
		for attempt in 5:
			var candidate: Vector2 = enemy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * Yards.to_px(randf_range(0.8, wander_radius))
			if combat_handler.has_line_of_sight(enemy.global_position + feet_offset, candidate + feet_offset):
				wander_target = candidate
				break
	var to_target: Vector2 = wander_target - enemy.global_position
	if to_target.length() < Yards.to_px(0.16):
		enemy.velocity = Vector2.ZERO
	else:
		enemy.velocity = to_target.normalized() * Yards.to_px(stats.get_stat(Stat.Type.MOVE_SPEED)) * wander_speed_factor

func _on_damage_taken(_amount: float, _crit_multiplier: float, _from_ability: bool) -> void:
	start_aggro()

func start_aggro() -> void:
	out_of_range_timer = 0.0
	if aggro:
		return
	aggro = true
	get_node("../CombatState").refresh()
	alert_nearby()

func alert_nearby() -> void:
	var enemy = get_parent()
	var combat_handler = get_node("../CombatHandler")
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == enemy:
			continue
		var controller = other.get_node("EnemyCombatController")
		if controller.aggro:
			continue
		if enemy.global_position.distance_to(other.global_position) > Yards.to_px(social_radius):
			continue
		if not combat_handler.units_have_line_of_sight(enemy, other):
			continue
		get_tree().create_timer(randf_range(0.1, 0.4), false).timeout.connect(controller.start_aggro)

func use_abilities(stats: Node, combat_handler: Node) -> void:
	for ability in stats.unit_data.abilities:
		if combat_handler.cast_ability(ability, target) == "":
			return
			
func update_retreat(stats: Node, combat_handler: Node, distance: float) -> void:
	var min_range: float = Yards.to_px(stats.unit_data.auto_attack.min_range)
	if min_range <= 0.0 or has_close_attack(stats, combat_handler):
		retreating = false
		return
	if distance < min_range:
		retreating = true
	elif distance >= min_range + Yards.to_px(retreat_buffer):
		retreating = false

func has_close_attack(stats: Node, combat_handler: Node) -> bool:
	for ability in stats.unit_data.abilities:
		if ability.requires_target and combat_handler.in_reach(ability, target):
			return true
	return false
