extends CastBar

func _ready() -> void:
	super._ready()
	var combat_handler = get_node("../CombatHandler")
	combat_handler.cast_started.connect(func(ability, duration): start_cast(duration))
	combat_handler.cast_cancelled.connect(cancel_cast)
