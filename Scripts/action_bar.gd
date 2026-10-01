extends Control

@export var slot_scene: PackedScene
var current_slots = []

func _ready() -> void:
	for ability in PlayerState.equipped_abilities:
		if ability == null:
			continue
		var slot = slot_scene.instantiate()
		slot.ability = ability
		$HUD/AbilitySlots.add_child(slot)
		current_slots.append(slot)
