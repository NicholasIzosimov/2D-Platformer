extends Container

@export var debuff_icon_scene: PackedScene
@export var track_player: bool = false
@export var show_buffs: bool = true
@export var show_debuffs: bool = true
@export var max_icons: int = 3
@export var slide_time: float = 0.15
@export var fade_time: float = 0.2
@export_group("Layout Preview")
@export var preview_icon: Texture2D
@export var preview_count: int = 10
@export var preview_interval: float = 0.35
@export var newest_first: bool = true
var current_icons: Dictionary = {}
var combat_handler: Node
var known: Dictionary = {}
var previous_positions: Dictionary = {}
var tweens: Dictionary = {}
var previewing: bool = false
var preview_icons: Array = []
var preview_timer: float = 0.0

func _ready() -> void:
	pre_sort_children.connect(_on_pre_sort)
	sort_children.connect(_on_sorted)
	var unit: Node = owner
	if track_player:
		unit = get_tree().get_first_node_in_group("player")
		if not unit.is_node_ready():
			await unit.ready
	combat_handler = unit.get_node("CombatHandler")
	combat_handler.effect_applied.connect(_on_effect_applied)
	combat_handler.effect_expired.connect(_on_effect_expired)

func _process(delta: float) -> void:
	if not previewing:
		return
	preview_timer -= delta
	if preview_timer > 0.0:
		return
	preview_timer = preview_interval
	if preview_icons.size() >= preview_count:
		for icon in preview_icons:
			remove_icon(icon)
		preview_icons.clear()
		return
	var icon = debuff_icon_scene.instantiate()
	icon.set_icon(preview_icon)
	add_child(icon)
	if newest_first:
		move_child(icon, 0)
	preview_icons.append(icon)

func set_preview(value: bool) -> void:
	previewing = value
	process_mode = Node.PROCESS_MODE_ALWAYS if value else Node.PROCESS_MODE_INHERIT
	preview_timer = 0.0
	if not value:
		for icon in preview_icons:
			icon.queue_free()
		preview_icons.clear()

func shows(effect: StatusEffect) -> bool:
	return show_debuffs if effect.is_debuff else show_buffs

func _on_effect_applied(effect) -> void:
	if effect.icon == null or not shows(effect):
		return
	if current_icons.has(effect.name):
		current_icons[effect.name].start_countdown(effect.spell_duration)
		return
	if max_icons > 0 and current_icons.size() >= max_icons:
		return
	var icon = debuff_icon_scene.instantiate()
	icon.effect = effect
	icon.start_countdown(effect.spell_duration)
	icon.set_icon(effect.icon)
	add_child(icon)
	if newest_first:
		move_child(icon, 0)
	current_icons[effect.name] = icon

func _on_effect_expired(effect) -> void:
	if current_icons.has(effect.name):
		remove_icon(current_icons[effect.name])
		current_icons.erase(effect.name)

func remove_icon(icon: Control) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(icon, "modulate:a", 0.0, fade_time)
	tween.tween_callback(icon.queue_free)

func _on_pre_sort() -> void:
	previous_positions.clear()
	for child in get_children():
		if child is Control and known.has(child):
			previous_positions[child] = child.position

func _on_sorted() -> void:
	for child in get_children():
		if not child is Control or child.is_queued_for_deletion():
			continue
		if not known.has(child):
			known[child] = true
			child.tree_exited.connect(func(): known.erase(child))
			animate(child, "modulate:a", 0.0, 1.0, fade_time)
		elif previous_positions.has(child) and previous_positions[child] != child.position:
			animate(child, "position", previous_positions[child], child.position, slide_time)

func animate(node: Control, property: String, from: Variant, to: Variant, time: float) -> void:
	var key: String = str(node.get_instance_id()) + property
	if tweens.has(key) and tweens[key].is_valid():
		tweens[key].kill()
	node.set_indexed(property, from)
	var tween: Tween = create_tween()
	tween.tween_property(node, property, to, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens[key] = tween
