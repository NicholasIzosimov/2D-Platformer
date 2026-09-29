extends CharacterBody2D
#The player should:
#read input (keyboard/mouse presses)
#physics / move the body
#animations
@export var wall_stick_time: float = 0.5
@export var wall_slide_speed: float = 60.0
@export var wall_jump_push: float = 100.0
@export var wall_jump_lock_time: float = 0.2
@export var wall_jump_air_accel: float = 1200.0
@export var wall_jump_air_drag: float = 400.0
@export var walk_speed: float = 150.0
@export var sprint_speed: float = 300.0
@export var double_tap_window: float = 0.25
var wall_jump_lock_timer: float = 0.0
var wall_stick_timer: float = 0.0
var wall_normal: Vector2 = Vector2.ZERO
var last_wall_normal: Vector2 = Vector2.ZERO
var has_jumped: bool = false
var sprint_exhausted: bool = false
var tap_timer: float = 0.0
var last_tap_dir: float = 0.0
var tap_sprint: bool = false
const JUMP_VELOCITY = -400.0
var animation_locked: bool = false
var is_channeling: bool = false


func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	
func play_attack_animation() -> void:
	animation_locked = true
	$AnimatedSprite2D.play("monkspell")
	
func _on_animation_finished() -> void:
	if is_channeling:
		$AnimatedSprite2D.play("monkspell")
	else:
		animation_locked = false

func start_channel_animation() -> void:
	is_channeling = true
	animation_locked = true
	$AnimatedSprite2D.play("monkspell")

func stop_channel_animation() -> void:
	is_channeling = false
	animation_locked = false
	
func _physics_process(delta: float) -> void:
	wall_stick_timer -= delta
	wall_jump_lock_timer -= delta
	tap_timer -= delta
	
	if is_on_floor():
		has_jumped = false
		wall_stick_timer = 0
		last_wall_normal = Vector2.ZERO
		wall_jump_lock_timer = 0
		
	if not is_on_floor() and has_jumped and is_on_wall() and wall_stick_timer <= 0 and get_wall_normal() != last_wall_normal:
		wall_stick_timer = wall_stick_time
		wall_normal = get_wall_normal()
		last_wall_normal = wall_normal
		print("stuck ", wall_normal)
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if wall_stick_timer > 0 and velocity.y > wall_slide_speed:
		velocity.y = wall_slide_speed
		
	if Input.is_action_just_pressed("jump") and is_on_floor() and $Endurance.spend($Endurance.jump_cost):
		velocity.y = JUMP_VELOCITY
		has_jumped = true
		if not animation_locked:
			$AnimatedSprite2D.play("monkmove")
		$CombatHandler.cast_cancel()
		
	elif Input.is_action_just_pressed("jump") and wall_stick_timer > 0 and $Endurance.spend($Endurance.wall_jump_cost):
		velocity.y = JUMP_VELOCITY
		velocity.x = wall_normal.x * wall_jump_push
		wall_stick_timer = 0
		wall_jump_lock_timer = wall_jump_lock_time
		
		
	var direction := Input.get_axis("move_left", "move_right")
	var speed: float = walk_speed
	
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		var tap_dir: float = -1.0
		if Input.is_action_just_pressed("move_right"):
			tap_dir = 1.0
		if tap_timer > 0 and tap_dir == last_tap_dir:
			tap_sprint = true
		last_tap_dir = tap_dir
		tap_timer = double_tap_window

	if direction * last_tap_dir <= 0:
		tap_sprint = false
			
	if not Input.is_action_pressed("sprint") and not tap_sprint:
		sprint_exhausted = false
	var is_sprinting: bool = false
	if (Input.is_action_pressed("sprint") or tap_sprint) and direction != 0 and not sprint_exhausted:
		if $Endurance.spend($Endurance.sprint_cost * delta):
			is_sprinting = true
			speed = sprint_speed
		else:
			sprint_exhausted = true
	$Endurance.is_sprinting = is_sprinting
	$Endurance.is_idle = is_on_floor() and direction == 0 and velocity.x == 0
		
	if wall_stick_timer > 0 and direction * wall_normal.x > 0:
		wall_stick_timer = 0
		
	if wall_jump_lock_timer <= 0:
		if direction:
			$AnimatedSprite2D.flip_h = direction < 0
			if not is_on_floor():
				velocity.x = move_toward(velocity.x, direction * speed, wall_jump_air_accel * delta)
			else:
				velocity.x = direction * speed
			if not animation_locked:
				$AnimatedSprite2D.play("monkmove")
			$CombatHandler.cast_cancel()
		else:
			if not is_on_floor():
				velocity.x = move_toward(velocity.x, 0, wall_jump_air_drag * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
			if not animation_locked:
				$AnimatedSprite2D.play("monkidle")

	move_and_slide()
