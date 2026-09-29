extends ProgressBar

func _ready() -> void:
	PlayerState.xp_changed.connect(refresh)
	refresh()

func refresh() -> void:
	max_value = PlayerState.xp_to_next_level()
	value = PlayerState.xp
	$Label.text = "Level %d   %d / %d" % [PlayerState.level, PlayerState.xp, max_value]
