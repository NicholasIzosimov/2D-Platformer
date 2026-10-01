extends Node

var current_target: Node
var hovered_target: Node
@export var hud: Node
@export var error_text: Node
@export var cast_bar: Node

func _ready() -> void:
	var combat_handler = get_node("../player/CombatHandler")
	combat_handler.gcd_started.connect(_on_gcd_started)
	combat_handler.cast_cancelled.connect(_on_cast_cancelled)
	combat_handler.cooldown_started.connect(_on_cooldown_started)
	combat_handler.cast_started.connect(_on_cast_started)
	combat_handler.cast_failed.connect(func(reason): error_text.show_message(reason))
	get_node("../player/Endurance").not_enough_endurance.connect(func(): error_text.show_message("Not enough endurance"))
	
func _on_cast_started(ability, duration: float) -> void:
	cast_bar.start_cast(duration)

func _on_cooldown_started(ability, duration: float) -> void:
	for slot in hud.current_slots:
		if slot.ability == ability:
			slot.start_countdown(duration)

func _on_gcd_started(duration: float) -> void:
	for slot in hud.current_slots:
		slot.start_countdown(duration)

func _on_cast_cancelled() -> void:
	for slot in hud.current_slots:
		slot.stop_countdown()
	cast_bar.cancel_cast()
	error_text.show_message("Can't cast while moving")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_target(null)
		return
	if Input.is_action_just_pressed("tab_target"):
		cycle_target()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked = get_enemy_under_mouse()
		if clicked:
			set_target(clicked)
		return

	var i = 1
	for slot in hud.current_slots:
		if Input.is_action_just_pressed("cast_" + str(i)):
			var target = get_cast_target()
			if target == null:
				target = find_auto_target(slot.ability)
				if target == null:
					error_text.show_message("No target")
					return
				set_target(target)
			var ability = slot.ability
			var result = get_node("../player/CombatHandler").cast_ability(ability, target)
			if result == "":
				slot.bop()
			else:
				error_text.show_message(result)
		i += 1

func _process(delta: float) -> void:
	update_hover()
	var target = get_cast_target()
	get_node("../player/AutoAttack").target = target
	var combat_handler = get_node("../player/CombatHandler")
	var own_stats = get_node("../player/UnitStats")
	for slot in hud.current_slots:
		var ability = slot.ability
		var in_range = target == null or combat_handler.in_reach(ability, target)
		var has_power = own_stats.current_power >= ability.power_cost
		slot.set_validity(in_range, has_power)
		
func find_auto_target(ability) -> Node:
	var player = get_node("../player")
	var combat_handler = player.get_node("CombatHandler")
	var best: Node = null
	var best_distance: float = INF
	for enemy in get_living_enemies():
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance >= best_distance or not combat_handler.in_reach(ability, enemy):
			continue
		if not combat_handler.units_have_line_of_sight(player, enemy):
			continue
		best = enemy
		best_distance = distance
	return best
	
func get_living_enemies() -> Array:
	var result = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.get_node("UnitStats").is_dead:
			result.append(enemy)
	return result

func get_valid_target() -> Node:
	if not is_instance_valid(current_target) or current_target.get_node("UnitStats").is_dead:
		set_target(null)
	return current_target
	
func get_cast_target() -> Node:
	if is_instance_valid(hovered_target) and not hovered_target.get_node("UnitStats").is_dead:
		return hovered_target
	return get_valid_target()

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
