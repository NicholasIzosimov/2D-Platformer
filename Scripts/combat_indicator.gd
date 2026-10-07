extends Label

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player.is_node_ready():
		await player.ready
	var combat_state = player.get_node("CombatState")
	combat_state.combat_changed.connect(_on_combat_changed)
	_on_combat_changed(combat_state.in_combat)

func _on_combat_changed(in_combat: bool) -> void:
	modulate.a = 1.0 if in_combat else 0.0
