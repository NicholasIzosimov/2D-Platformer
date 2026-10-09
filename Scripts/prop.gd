class_name Prop
extends Node2D

@export var blocks_cell: bool = true
var active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func set_active(value: bool) -> void:
	if value == active:
		return
	active = value
	process_mode = Node.PROCESS_MODE_INHERIT if value else Node.PROCESS_MODE_DISABLED
	var caster: Node = get_node_or_null("ShadowCaster")
	if caster:
		if value:
			caster.create_shadows()
		else:
			caster.free_shadows()

func save_state() -> Variant:
	return null

func load_state(_data: Variant) -> void:
	pass
