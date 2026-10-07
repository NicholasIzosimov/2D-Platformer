extends TextureRect

var combat_state: Node
var indicator: Node

func _ready() -> void:
	combat_state = owner.get_node("CombatState")
	indicator = owner.get_node("TargetIndicator")
	combat_state.combat_changed.connect(func(_in_combat): refresh())
	indicator.selected_changed.connect(func(_selected): refresh())
	refresh()

func refresh() -> void:
	visible = combat_state.in_combat and not indicator.is_selected
