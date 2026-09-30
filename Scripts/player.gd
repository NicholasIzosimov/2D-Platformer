extends CharacterBody2D

@export var walk_speed: float = 150.0
@export var sprint_speed: float = 300.0
@export var double_tap_window: float = 0.25
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 2.0
var sprint_exhausted: bool = false
var tap_timer: float = 0.0
var last_tap_action: String = ""
var tap_sprint: bool = false
var animation_locked: bool = false
var is_channeling: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

const MOVE_ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

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
	tap_timer -= delta
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dash_timer -= delta
	dash_cooldown_timer -= delta
	if Input.is_action_just_pressed("dash") and dash_timer <= 0 and dash_cooldown_timer <= 0:
		var dash_dir: Vector2 = direction
		if dash_dir == Vector2.ZERO:
			dash_dir = Vector2.LEFT if $AnimatedSprite2D.flip_h else Vector2.RIGHT
		if $Endurance.spend($Endurance.dash_cost):
			dash_direction = dash_dir
			dash_timer = dash_duration
			dash_cooldown_timer = dash_cooldown
			tap_sprint = true
			$CombatHandler.cast_cancel()
	if dash_timer > 0:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
		
	for action in MOVE_ACTIONS:
		if Input.is_action_just_pressed(action):
			if tap_timer > 0 and action == last_tap_action:
				tap_sprint = true
			last_tap_action = action
			tap_timer = double_tap_window
	if direction == Vector2.ZERO:
		tap_sprint = false

	if not Input.is_action_pressed("sprint") and not tap_sprint:
		sprint_exhausted = false
	var speed: float = walk_speed
	var is_sprinting: bool = false
	if (Input.is_action_pressed("sprint") or tap_sprint) and direction != Vector2.ZERO and not sprint_exhausted:
		if $Endurance.spend($Endurance.sprint_cost * delta):
			is_sprinting = true
			speed = sprint_speed
		else:
			sprint_exhausted = true
	$Endurance.is_sprinting = is_sprinting
	$Endurance.is_idle = direction == Vector2.ZERO

	velocity = direction * speed
	if direction != Vector2.ZERO:
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x < 0
		if not animation_locked:
			$AnimatedSprite2D.play("monkmove")
		$CombatHandler.cast_cancel()
	elif not animation_locked:
		$AnimatedSprite2D.play("monkidle")

	move_and_slide()
