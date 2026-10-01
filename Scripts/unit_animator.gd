extends Node

const FALLBACKS: Dictionary = {"run": "idle", "cast": "attack"}

var key: String = ""
var face_target: Node2D = null
var current_action: String = ""
var locked: bool = false
var casting: bool = false
var dead: bool = false
var warned: Dictionary = {}
var body: CharacterBody2D
var sprite: AnimatedSprite2D
var stats: Node

func _ready() -> void:
	body = get_parent()
	sprite = get_node("../AnimatedSprite2D")
	stats = get_node("../UnitStats")
	if key == "":
		key = stats.unit_data.resource_path.get_file().get_basename()
	sprite.animation_finished.connect(_on_animation_finished)
	stats.died.connect(_on_died)
	var combat_handler = get_node("../CombatHandler")
	combat_handler.ability_used.connect(_on_ability_used)
	combat_handler.cast_started.connect(_on_cast_started)
	combat_handler.cast_finished.connect(_on_cast_ended)
	combat_handler.cast_cancelled.connect(_on_cast_ended)

func _physics_process(_delta: float) -> void:
	if dead:
		return
	update_facing()
	if locked:
		return
	var speed: float = body.velocity.length()
	if speed > stats.unit_data.base_move_speed * 0.25:
		play_loop("run")
		sprite.speed_scale = speed / stats.unit_data.base_move_speed
	else:
		play_loop("idle")
		sprite.speed_scale = 1.0

func update_facing() -> void:
	var x: float = body.velocity.x
	if is_instance_valid(face_target):
		x = face_target.global_position.x - body.global_position.x
	if abs(x) > 0.5:
		sprite.flip_h = x < 0

func play_loop(action: String) -> void:
	if action == current_action:
		return
	current_action = action
	var anim: String = find_animation(action)
	if anim != "":
		sprite.play(anim)

func play_once(action: String) -> void:
	current_action = action
	var anim: String = find_animation(action)
	if anim == "":
		locked = false
		return
	locked = true
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.play(anim)

func find_animation(action: String) -> String:
	var base_name: String = key + "_" + action
	var options: Array[String] = []
	if sprite.sprite_frames.has_animation(base_name):
		options.append(base_name)
	var variant: int = 2
	while sprite.sprite_frames.has_animation(base_name + "_" + str(variant)):
		options.append(base_name + "_" + str(variant))
		variant += 1
	if not options.is_empty():
		return options.pick_random()
	if FALLBACKS.has(action):
		return find_animation(FALLBACKS[action])
	if not warned.has(base_name):
		warned[base_name] = true
		push_warning("Missing animation: " + base_name)
	return ""

func _on_animation_finished() -> void:
	if dead:
		return
	if casting:
		sprite.stop()
		sprite.play(sprite.animation)
		return
	locked = false
	current_action = ""

func _on_ability_used(ability) -> void:
	if ability.cast_time == 0:
		play_once("attack")

func _on_cast_started(_ability, _duration: float) -> void:
	casting = true
	play_once("cast")

func _on_cast_ended() -> void:
	casting = false
	locked = false
	current_action = ""

func _on_died() -> void:
	dead = true
	var anim: String = find_animation("die")
	if anim != "":
		sprite.speed_scale = 1.0
		sprite.stop()
		sprite.play(anim)
