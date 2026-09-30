extends Node

var current_target: Node
var hovered_target: Node
@export var action_bar: Node
@export var error_text: Node
@export var cast_bar: Node

func _ready() -> void:
	set_target(get_tree().get_first_node_in_group("enemies"))
	var combat_handler = get_node("../player/CombatHandler")
	combat_handler.gcd_started.connect(_on_gcd_started)
	combat_handler.cast_cancelled.connect(_on_cast_cancelled)
	combat_handler.cooldown_started.connect(_on_cooldown_started)
	combat_handler.cast_started.connect(_on_cast_started)
	combat_handler.cast_finished.connect(func(): get_node("../player").stop_channel_animation())
	get_node("../player/Endurance").not_enough_endurance.connect(func(): error_text.show_message("Not enough endurance"))
	
func _on_cast_started(ability, duration: float) -> void:
	cast_bar.start_cast(duration)

func _on_cooldown_started(ability, duration: float) -> void:
	for slot in action_bar.current_slots:
		if slot.ability == ability:
			slot.start_countdown(duration)

func _on_gcd_started(duration: float) -> void:
	for slot in action_bar.current_slots:
		slot.start_countdown(duration)

func _on_cast_cancelled() -> void:
	for slot in action_bar.current_slots:
		slot.stop_countdown()
	cast_bar.cancel_cast()
	error_text.show_message("Can't cast while moving")
	get_node("../player").stop_channel_animation()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("tab_target"):
		cycle_target()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked = get_enemy_under_mouse()
		if clicked:
			set_target(clicked)
		return

	var i = 1
	for slot in action_bar.current_slots:
		if Input.is_action_just_pressed("cast_" + str(i)):
			var target = get_valid_target()
			if target == null:
				error_text.show_message("No target")
				return
			var ability = slot.ability
			var result = get_node("../player/CombatHandler").cast_ability(ability, target)
			if result == "":
				slot.bop()
				var player_node = get_node("../player")
				if ability.cast_time > 0:
					player_node.start_channel_animation()
				else:
					player_node.play_attack_animation()
			else:
				error_text.show_message(result)
		i += 1

func _process(delta: float) -> void:
	update_hover()
	var target = get_valid_target()
	if target == null:
		return
	var combat_handler = get_node("../player/CombatHandler")
	var own_stats = get_node("../player/UnitStats")
	var caster_position = get_node("../player").global_position
	for slot in action_bar.current_slots:
		var ability = slot.ability
		var in_range = caster_position.distance_to(target.global_position) <= ability.range * combat_handler.PIXELS_PER_UNIT
		var has_power = own_stats.current_power >= ability.power_cost
		slot.set_validity(in_range, has_power)

func get_living_enemies() -> Array:
	var result = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.get_node("UnitStats").is_dead:
			result.append(enemy)
	return result

func get_valid_target() -> Node:
	if not is_instance_valid(current_target) or current_target.get_node("UnitStats").is_dead:
		var enemies = get_living_enemies()
		set_target(enemies[0] if enemies.size() > 0 else null)
	return current_target

func cycle_target() -> void:
	var enemies = get_living_enemies()
	if enemies.is_empty():
		set_target(null)
		return
	var index = enemies.find(current_target)
	set_target(enemies[(index + 1) % enemies.size()])

func set_target(new_target: Node) -> void:
	if is_instance_valid(current_target):
		current_target.get_node("TargetIndicator").set_selected(false)
	current_target = new_target
	if is_instance_valid(current_target):
		current_target.get_node("TargetIndicator").set_selected(true)

func get_enemy_under_mouse() -> Node:
	var player = get_node("../player")
	var params = PhysicsPointQueryParameters2D.new()
	params.position = player.get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 8
	var candidates: Array = []
	for result in player.get_world_2d().direct_space_state.intersect_point(params):
		var unit = result.collider.owner
		if unit.is_in_group("enemies") and not unit.get_node("UnitStats").is_dead and not candidates.has(unit):
			candidates.append(unit)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
	if candidates.size() > 1 and candidates[0] == current_target:
		return candidates[1]
	return candidates[0]

func update_hover() -> void:
	var hovered = get_enemy_under_mouse()
	if hovered == hovered_target:
		return
	if is_instance_valid(hovered_target):
		hovered_target.get_node("TargetIndicator").set_hovered(false)
	hovered_target = hovered
	if is_instance_valid(hovered_target):
		hovered_target.get_node("TargetIndicator").set_hovered(true)
