extends PanelContainer

@export var gear_slot_scene: PackedScene
@export var slot_order: Array[ItemData.Slot] = []

var slots: Dictionary = {}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot_type in slot_order:
		var gear_slot = gear_slot_scene.instantiate()
		gear_slot.slot = slot_type
		%GearSlots.add_child(gear_slot)
		slots[slot_type] = gear_slot

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("character_pane") or (visible and event.is_action_pressed("ui_cancel")):
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		refresh()

func refresh() -> void:
	%Title.text = "%s - Level %d" % [PlayerState.class_data.name, PlayerState.level]
	for child in %Stats.get_children():
		%Stats.remove_child(child)
		child.queue_free()
	var player = get_tree().get_first_node_in_group("player")
	var stats = player.get_node("UnitStats")
	var combat = player.get_node("CombatHandler")
	var endurance = player.get_node("Endurance")
	var class_data: ClassData = PlayerState.class_data

	add_row("Vigor", "%d" % stats.get_stat(Stat.Type.VIGOR))
	add_row(class_data.primary_stat_name, "%d" % stats.get_stat(Stat.Type.PRIMARY))
	add_row("Armor", "%d" % stats.get_stat(Stat.Type.ARMOR))
	add_row("Crit Chance", "%.1f%%" % stats.get_stat(Stat.Type.CRIT_CHANCE))
	add_row("Hit", "%.1f%%" % stats.get_stat(Stat.Type.HIT))
	add_row("Damage", "+%.0f%%" % stats.get_stat(Stat.Type.DAMAGE_PERCENT))
	add_row("Miss Chance", "%.1f%%" % stats.get_stat(Stat.Type.MISS_CHANCE))
	add_row("Endurance", "(+%s/s)" % endurance.endurance_regen)
	add_row("Speed", "%d" % stats.get_stat(Stat.Type.MOVE_SPEED))

func add_row(label_text: String, value_text: String) -> void:
	var label := Label.new()
	label.text = label_text
	%Stats.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	%Stats.add_child(value)
