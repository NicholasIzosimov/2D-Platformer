extends Resource

class_name LevelColors

@export var red_at: int = 5
@export var orange_at: int = 3
@export var yellow_at: int = -2
@export var green_at: int = -9
@export var red: Color = Color(1.0, 0.1, 0.1)
@export var orange: Color = Color(1.0, 0.5, 0.25)
@export var yellow: Color = Color(1.0, 1.0, 0.0)
@export var green: Color = Color(0.25, 0.75, 0.25)
@export var grey: Color = Color(0.5, 0.5, 0.5)
@export var own: Color = Color.WHITE

func color_for(level_diff: int) -> Color:
	if level_diff >= red_at:
		return red
	if level_diff >= orange_at:
		return orange
	if level_diff >= yellow_at:
		return yellow
	if level_diff >= green_at:
		return green
	return grey
