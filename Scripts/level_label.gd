extends Label

@export var level_colors: LevelColors

func _ready() -> void:
	owner.get_node("UnitStats").level_changed.connect(refresh)
	PlayerState.leveled_up.connect(_on_player_leveled_up)
	refresh()

func _on_player_leveled_up(_new_level: int) -> void:
	refresh()

func refresh() -> void:
	var level: int = owner.get_node("UnitStats").level
	text = str(level)
	var color: Color = level_colors.color_for(level - PlayerState.level)
	if owner.is_in_group("player"):
		color = level_colors.own
	add_theme_color_override("font_color", color)
