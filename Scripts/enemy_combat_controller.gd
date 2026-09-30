extends Node

@export var abilities: Array[AbilityData]
@export var speed_variance: float = 0.05
@export var hp_slow_factor: float = 0.3
@export var separation_radius: float = 48.0
@export var separation_strength: float = 80.0
@export var path_bias: float = 20.0
@export var weave_angle: float = 15.0
@export var weave_speed: float = 2.0
@export var aggro_range: float = 1100.0
@export var leash_time: float = 5.0
@export var wander_radius: float = 150.0
@export var wander_speed_factor: float = 0.4
@export var social_radius: float = 250.0

var target: Node
var cast_timer: float = 3.0
var attacking: bool = false
var flow: Node
var feet_offset: Vector2
var bias: float
var weave_phase: float
var time: float = 0.0
var aggro: bool = false
var out_of_range_timer: float = 0.0
var wander_target: Vector2
var wander_timer: float = 0.0

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	get_node("../UnitStats").died.connect(_on_died)
	get_node("../AnimatedSprite2D").animation_finished.connect(func(): attacking = false)
	var stats = get_node("../UnitStats")
	stats.modify_move_speed(stats.current_move_speed * randf_range(-speed_variance, speed_variance))
	flow = get_tree().get_first_node_in_group("flow_field")
	var enemy = get_parent()
	feet_offset = get_node("../CollisionShape2D").position
	enemy.global_position = flow.find_free_position(enemy.global_position + feet_offset) - feet_offset
	bias = deg_to_rad(randf_range(-path_bias, path_bias))
	weave_phase = randf() * TAU
	wander_target = enemy.global_position
	stats.damage_taken.connect(_on_damage_taken)
	
func _physics_process(delta: float) -> void:
	time += delta
	var enemy = get_parent()
	var stats = get_node("../UnitStats")
	var combat_handler = get_node("../CombatHandler")
	var distance = enemy.global_position.distance_to(target.global_position)
	var in_range = distance <= abilities[0].range * combat_handler.PIXELS_PER_UNIT

	var sees_player: bool = distance <= aggro_range and combat_handler.has_line_of_sight(enemy.global_position, target.global_position)
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
	elif in_range and sees_player:
		enemy.velocity = Vector2.ZERO
	else:
		var direction: Vector2 = flow.get_direction(enemy.global_position + feet_offset)
		if direction == Vector2.ZERO:
			direction = enemy.global_position.direction_to(target.global_position)
		var wander_amount: float = clamp((distance - 150.0) / 300.0, 0.0, 1.0)
		if not sees_player:
			wander_amount = 0.0
		var angle: float = bias + sin(time * weave_speed + weave_phase) * deg_to_rad(weave_angle)
		direction = direction.rotated(angle * wander_amount)
		var hp_lost: float = 1.0 - stats.current_health / stats.max_health
		var speed: float = stats.current_move_speed * (1.0 - hp_lost * hp_slow_factor)
		enemy.velocity = direction * speed

	var sprite = get_node("../AnimatedSprite2D")
	if aggro:
		sprite.flip_h = target.global_position.x < enemy.global_position.x
	elif enemy.velocity.x != 0:
		sprite.flip_h = enemy.velocity.x < 0
	if not attacking:
		if enemy.velocity != Vector2.ZERO:
			sprite.play("warrior_run")
			sprite.speed_scale = enemy.velocity.length() / stats.unit_data.base_move_speed
		else:
			sprite.play("warrior_idle")
			sprite.speed_scale = 1.0
	enemy.velocity += get_separation(enemy)
	enemy.move_and_slide()
	cast_timer -= delta

	if cast_timer <= 0 and in_range and sees_player:
		cast_timer = 3.0
		if combat_handler.cast_ability(abilities[0], target) == "":
			attacking = true
			get_node("../AnimatedSprite2D").play("warrior_attack1")

func _on_died() -> void:
	PlayerState.add_xp(get_node("../UnitStats").unit_data.xp_reward)
	get_parent().queue_free()
	
func get_separation(enemy: Node2D) -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == enemy:
			continue
		var offset: Vector2 = enemy.global_position - other.global_position
		var dist: float = offset.length()
		if dist < separation_radius:
			if dist < 0.01:
				offset = Vector2.RIGHT.rotated(randf() * TAU)
			push += offset.normalized() * (1.0 - dist / separation_radius)
	return push * separation_strength

func idle_wander(enemy: Node2D, stats: Node, delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(2.0, 4.0)
		wander_target = enemy.global_position
		var combat_handler = get_node("../CombatHandler")
		for attempt in 5:
			var candidate: Vector2 = enemy.global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(40.0, wander_radius)
			if combat_handler.has_line_of_sight(enemy.global_position + feet_offset, candidate + feet_offset):
				wander_target = candidate
				break
	var to_target: Vector2 = wander_target - enemy.global_position
	if to_target.length() < 8.0:
		enemy.velocity = Vector2.ZERO
	else:
		enemy.velocity = to_target.normalized() * stats.current_move_speed * wander_speed_factor

func _on_damage_taken(_amount: float, _crit_multiplier: float) -> void:
	start_aggro()

func start_aggro() -> void:
	out_of_range_timer = 0.0
	if aggro:
		return
	aggro = true
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
		if enemy.global_position.distance_to(other.global_position) > social_radius:
			continue
		if not combat_handler.has_line_of_sight(enemy.global_position, other.global_position):
			continue
		get_tree().create_timer(randf_range(0.1, 0.4), false).timeout.connect(controller.start_aggro)
