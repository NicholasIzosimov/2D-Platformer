extends Node

const FALLBACKS: Dictionary = {"run": "idle", "cast": "attack"}
@export var impact_frames: Dictionary = {}

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
var pivot: Node2D

func _ready() -> void:
	body = get_parent()
	sprite = get_node("../AnimatedSprite2D")
	stats = get_node("../UnitStats")
	pivot = get_node("../AttackPivot")
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
	if speed > stats.get_stat(Stat.Type.MOVE_SPEED) * 0.25:
		play_loop("run")
		sprite.speed_scale = speed / stats.get_stat(Stat.Type.MOVE_SPEED)
	else:
		play_loop("idle")
		sprite.speed_scale = 1.0

func update_facing() -> void:
	if locked or casting:
		var aim_x: float = Vector2.from_angle(pivot.rotation).x
		if abs(aim_x) > 0.01:
			sprite.flip_h = aim_x < 0
		return
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

func play_once(action: String, windup: float = 0.0) -> void:
	current_action = action
	var anim: String = find_animation(action)
	if anim == "":
		locked = false
		return
	locked = true
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.play(anim)
	if windup > 0.0:
		var to_impact: float = impact_time(anim)
		if to_impact > 0.0:
			sprite.speed_scale = to_impact / windup

func impact_time(anim: String) -> float:
	var frames: SpriteFrames = sprite.sprite_frames
	var impact: int = impact_frames.get(anim, frames.get_frame_count(anim) / 2)
	var time: float = 0.0
	for i in impact:
		time += frames.get_frame_duration(anim, i)
	return time / frames.get_animation_speed(anim)
	
func time_to_impact() -> float:
	if not locked or sprite.animation == &"":
		return 0.0
	return impact_time(String(sprite.animation)) / max(sprite.speed_scale, 0.01)
	
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
	if ability == stats.unit_data.auto_attack or ability.windup_from_animation:
		play_once("attack")
	elif ability.cast_time == 0:
		play_once("attack", ability.windup)

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
	if anim == "":
		sprite.pause()
		return
	sprite.speed_scale = 1.0
	sprite.stop()
	sprite.play(anim)
