extends SmoothBar

func _ready() -> void:
	PlayerState.xp_changed.connect(refresh)
	refresh()

func refresh() -> void:
	set_bar(PlayerState.xp, PlayerState.xp_to_next_level())
	$Label.text = "Level %d   %d / %d" % [PlayerState.level, PlayerState.xp, max_value]
