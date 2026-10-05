extends Control

@export var slot_scene: PackedScene
var current_slots = []
signal slot_activated(slot)

func _ready() -> void:
	build_slots()
	PlayerState.loadout_changed.connect(refresh_slots)
	refresh_slots()

func build_slots() -> void:
	var index: int = 0
	while InputMap.has_action("cast_%d" % (index + 1)):
		var slot = slot_scene.instantiate()
		slot.slot_index = index
		slot.keybind_action = "cast_%d" % (index + 1)
		slot.pressed.connect(func():
			if not Input.is_key_pressed(KEY_SHIFT):
				slot_activated.emit(slot)
		)
		$AbilitySlots.add_child(slot)
		current_slots.append(slot)
		index += 1

func refresh_slots() -> void:
	var equipped: Array[AbilityData] = PlayerState.equipped_abilities
	for slot in current_slots:
		slot.set_ability(equipped[slot.slot_index] if slot.slot_index < equipped.size() else null)
		
func show_target(target: Node) -> void:
	$TargetUnitFrame.set_unit(target)
