extends Node

@export var hud: Node
@export var error_text: Node
@export var cast_bar: Node
@export var combat_cursor: Texture2D = preload("res://Assets/UI/CombatPointer.png")
@export var combat_cursor_hotspot: Vector2 = Vector2(6, 6)
var current_target: Node
var hovered_target: Node
signal target_changed(target)

func _ready() -> void:
	var combat_handler = get_node("../player/CombatHandler")
	combat_handler.cast_cancelled.connect(_on_cast_cancelled)
	combat_handler.cast_started.connect(_on_cast_started)
	combat_handler.cast_failed.connect(func(reason): error_text.show_message(reason))
	get_node("../player/Endurance").not_enough_endurance.connect(func(): error_text.show_message("Not enough endurance"))
	get_node("../player/Interactor").interact_failed.connect(func(reason): error_text.show_message(reason))
	PlayerState.action_failed.connect(func(reason): error_text.show_message(reason))
	hud.slot_activated.connect(try_cast_slot)
	target_changed.connect(hud.show_target)
	
func _on_cast_started(ability, duration: float) -> void:
	cast_bar.start_cast(duration)

func _on_cast_cancelled() -> void:
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

	for slot in hud.current_slots:
		if slot.keybind_action != "" and event.is_action_pressed(slot.keybind_action):
			try_cast_slot(slot)
			return
			
func try_cast_slot(slot) -> void:
	var ability = slot.ability
	if ability == null:
		return
	var target = null
	if ability.requires_target:
		target = get_cast_target()
		if target == null:
			target = find_auto_target(ability)
		if target == null:
			error_text.show_message("No target")
			return
		if get_valid_target() == null:
			set_target(target)
	var result = get_node("../player/CombatHandler").cast_ability(ability, target)
	if result == "":
		slot.bop()
	else:
		error_text.show_message(result)
		
func _process(delta: float) -> void:
	update_hover()
	var player = get_node("../player")
	player.get_node("AutoAttack").target = get_valid_target()
	var target = get_cast_target()
	var combat_handler = player.get_node("CombatHandler")
	var own_stats = player.get_node("UnitStats")
	for slot in hud.current_slots:
		var ability = slot.ability
		if ability == null:
			continue
		var in_range = not ability.requires_target or target == null or combat_handler.in_reach(ability, target)
		var has_power = own_stats.current_power >= ability.power_cost
		slot.set_validity(in_range, has_power)
		var holder = target if ability.requires_target else player
		var left: float = 0.0
		var total: float = 1.0
		if is_instance_valid(holder):
			for effect in ability.effects:
				var time_left: float = holder.get_node("CombatHandler").effect_time_left(effect)
				if time_left > left:
					left = time_left
					total = effect.spell_duration
		slot.set_effect_timer(left, total)
		
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
	var selected: Node = get_valid_target()
	if selected:
		return selected
	if is_instance_valid(hovered_target) and not hovered_target.get_node("UnitStats").is_dead:
		return hovered_target
	return null

func cycle_target() -> void:
	var candidates: Array = get_tab_candidates()
	if candidates.is_empty():
		return
	var index: int = candidates.find(current_target)
	set_target(candidates[(index + 1) % candidates.size()])

func get_tab_candidates() -> Array:
	var player = get_node("../player")
	var combat_handler = player.get_node("CombatHandler")
	var view: Rect2 = player.get_viewport().get_canvas_transform().affine_inverse() * player.get_viewport().get_visible_rect()
	var result: Array = []
	for enemy in get_living_enemies():
		var aggro_range: float = Yards.to_px(enemy.get_node("EnemyCombatController").aggro_range)
		if player.global_position.distance_to(enemy.global_position) > aggro_range:
			continue
		if not view.has_point(enemy.global_position):
			continue
		if not combat_handler.units_have_line_of_sight(player, enemy):
			continue
		result.append(enemy)
	result.sort_custom(func(a, b): return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	return result

func set_target(new_target: Node) -> void:
	if is_instance_valid(current_target):
		current_target.get_node("TargetIndicator").set_selected(false)
	current_target = new_target
	if is_instance_valid(current_target):
		current_target.get_node("TargetIndicator").set_selected(true)
	target_changed.emit(current_target if is_instance_valid(current_target) else null)
	
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
	Input.set_custom_mouse_cursor(combat_cursor if is_instance_valid(hovered_target) else null, Input.CURSOR_ARROW, combat_cursor_hotspot)

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)
