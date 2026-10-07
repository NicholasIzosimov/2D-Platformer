extends PanelContainer

@export var gear_slot_scene: PackedScene
@export var slot_order: Array[ItemData.Slot] = []
var slots: Dictionary = {}

func _ready() -> void:
	add_to_group("pause_panes")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot_type in slot_order:
		var gear_slot = gear_slot_scene.instantiate()
		gear_slot.slot = slot_type
		gear_slot.empty_text = ItemData.Slot.keys()[slot_type].capitalize()
		gear_slot.right_clicked.connect(func(): PlayerState.unequip_to_bag(slot_type))
		%GearSlots.add_child(gear_slot)
		slots[slot_type] = gear_slot
	PlayerState.gear_changed.connect(func(): if visible: refresh())
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_pane") or (visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = not visible
	get_tree().paused = get_tree().get_nodes_in_group("pause_panes").any(func(pane): return pane.visible)
	if visible:
		refresh()

func refresh() -> void:
	%Title.text = "Level %d" % PlayerState.level
	for slot_type in slots:
		slots[slot_type].set_item(PlayerState.equipped_gear.get(slot_type))
	for child in %Stats.get_children():
		%Stats.remove_child(child)
		child.queue_free()
	var player = get_tree().get_first_node_in_group("player")
	var stats = player.get_node("UnitStats")
	var endurance = player.get_node("Endurance")
	var player_sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	%PreviewSprite.sprite_frames = player_sprite.sprite_frames
	%PreviewSprite.play(player.get_node("UnitAnimator").key + "_idle")
	add_row("Vigor", "%d" % stats.get_stat(Stat.Type.VIGOR))
	add_row("Power", "%d" % stats.ability_power())
	add_row("Weapon Damage", "%d" % stats.get_stat(Stat.Type.WEAPON_DAMAGE))
	add_row("Attack Speed", "%.2f s" % stats.base_swing_time())
	add_row("Armor", "%d" % stats.get_stat(Stat.Type.ARMOR))
	add_row("Crit Chance", "%.1f%%" % stats.crit_percent())
	add_row("Hit Chance", "%.1f%%" % stats.hit_percent())
	add_row("Haste", "%.1f%%" % stats.get_stat(Stat.Type.HASTE))
	add_row("Miss Chance", "%.1f%%" % stats.get_stat(Stat.Type.MISS_CHANCE))
	add_row("Endurance", "(+%s/s)" % endurance.endurance_regen)
	
func add_row(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	%Stats.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	%Stats.add_child(value)
