extends Control

@export var slot_scene: PackedScene
@export var current_class: ClassData
var current_slots = []

func _ready() -> void:
	for ability in current_class.abilities:
		var slot = slot_scene.instantiate()
		slot.ability = ability
		$HUD/AbilitySlots.add_child(slot)
		current_slots.append(slot)
