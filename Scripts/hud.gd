extends Control

@export var slot_scene: PackedScene
var current_slots = []
signal slot_activated(slot)

func _ready() -> void:
	PlayerState.loadout_changed.connect(rebuild)
	rebuild()

func rebuild() -> void:
	for slot in current_slots:
		slot.queue_free()
	current_slots.clear()
	for ability in PlayerState.equipped_abilities:
		if ability == null:
			continue
		var slot = slot_scene.instantiate()
		slot.ability = ability
		var action: String = "cast_%d" % (current_slots.size() + 1)
		slot.keybind_action = action if InputMap.has_action(action) else ""
		slot.pressed.connect(func(): slot_activated.emit(slot))
		$AbilitySlots.add_child(slot)
		current_slots.append(slot)
