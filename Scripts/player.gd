extends CharacterBody2D

@export var sprint_multiplier: float = 2.0
@export var double_tap_window: float = 0.25
@export var dash_speed: float = 10.0
@export var dash_duration: float = 0.3
@export var dash_cooldown: float = 2.0
var sprint_exhausted: bool = false
var tap_timer: float = 0.0
var last_tap_action: String = ""
var tap_sprint: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

const MOVE_ACTIONS: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

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
			$CombatHandler.cast_cancel()
			$UnitAnimator.play_for("dash", dash_duration)
	if dash_timer > 0:
		velocity = dash_direction * Yards.to_px(dash_speed)
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
	var speed: float = Yards.to_px($UnitStats.get_stat(Stat.Type.MOVE_SPEED))
	var is_sprinting: bool = false
	if (Input.is_action_pressed("sprint") or tap_sprint) and direction != Vector2.ZERO and not sprint_exhausted:
		if $Endurance.spend($Endurance.sprint_cost * delta):
			is_sprinting = true
			speed *= sprint_multiplier
		else:
			sprint_exhausted = true
	$Endurance.is_sprinting = is_sprinting
	$Endurance.is_idle = direction == Vector2.ZERO

	velocity = direction * speed
	if direction != Vector2.ZERO:
		$CombatHandler.cast_cancel()
		
	move_and_slide()
	if is_sprinting and ran_into_obstacle(direction):
		tap_sprint = false
		sprint_exhausted = true
		
func ran_into_obstacle(direction: Vector2) -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_collider() is TileMapLayer and direction.dot(collision.get_normal()) < -0.7:
			return true
	return false
