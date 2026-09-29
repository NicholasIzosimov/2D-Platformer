extends Node

@export var abilities: Array[AbilityData]
@export var speed_variance: float = 0.1
@export var hp_slow_factor: float = 0.3
@export var small_jump_velocity: float = -400.0
@export var big_jump_velocity: float = -550.0
var target: Node
var cast_timer: float = 3.0
var attacking: bool = false

func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	get_node("../UnitStats").died.connect(_on_died)
	get_node("../AnimatedSprite2D").animation_finished.connect(func(): attacking = false)
	var stats = get_node("../UnitStats")
	stats.modify_move_speed(stats.current_move_speed * randf_range(-speed_variance, speed_variance))
	
func _physics_process(delta: float) -> void:
	var enemy = get_parent()
	var stats = get_node("../UnitStats")
	if not enemy.is_on_floor():
		enemy.velocity += enemy.get_gravity() * delta

	var combat_handler = get_node("../CombatHandler")
	var distance = enemy.global_position.distance_to(target.global_position)
	var in_range = distance <= abilities[0].range * combat_handler.PIXELS_PER_UNIT

	if in_range:
		enemy.velocity.x = 0
	else:
		var direction = sign(target.global_position.x - enemy.global_position.x)
		var hp_lost: float = 1.0 - stats.current_health / stats.max_health
		var speed: float = stats.current_move_speed * (1.0 - hp_lost * hp_slow_factor)
		enemy.velocity.x = direction * speed
		var check1 = get_node("../HeightCheck1")
		var check2 = get_node("../HeightCheck2")
		check1.target_position.x = direction * 40
		check2.target_position.x = direction * 40
		if enemy.is_on_floor() and enemy.is_on_wall():
			check1.force_raycast_update()
			check2.force_raycast_update()
			if not check1.is_colliding():
				enemy.velocity.y = small_jump_velocity
			elif not check2.is_colliding():
				enemy.velocity.y = big_jump_velocity
				
	var sprite = get_node("../AnimatedSprite2D")
	sprite.flip_h = target.global_position.x < enemy.global_position.x
	if not attacking:
		if enemy.velocity.x != 0:
			sprite.play("warrior_run")
			sprite.speed_scale = abs(enemy.velocity.x) / stats.unit_data.base_move_speed
		else:
			sprite.play("warrior_idle")
			sprite.speed_scale = 1.0
	enemy.move_and_slide()
	cast_timer -= delta

	if cast_timer <= 0 and in_range:
		cast_timer = 3.0
		if combat_handler.cast_ability(abilities[0], target) == "":
			attacking = true
			get_node("../AnimatedSprite2D").play("warrior_attack1")

func _on_died() -> void:
	PlayerState.add_xp(get_node("../UnitStats").unit_data.xp_reward)
	get_parent().queue_free()
