extends ScreenSized

@export var floating_number_scene: PackedScene
@export var xp_color: Color = Color(0.75, 0.45, 1.0)
@export var font_size: int = 36
@export var line_spacing: float = 34.0
@export var text_hold: float = 1.0

var lines_shown: int = 0

func _ready() -> void:
	super._ready()
	get_node("../UnitStats").died.connect(_on_died)

func _on_died() -> void:
	grant_xp()

func grant_xp() -> void:
	var stats = get_node("../UnitStats")
	var xp: float = PlayerState.xp_curve.xp_for_enemy_level(stats.level) * stats.unit_data.xp_reward
	PlayerState.add_xp(xp)
	show_reward("+%d XP" % roundi(xp), xp_color)

func show_reward(text: String, color: Color) -> void:
	var label = floating_number_scene.instantiate()
	label.text = text
	label.set_color(color)
	label.add_theme_font_size_override("font_size", font_size)
	label.position = Vector2(0, -lines_shown * line_spacing)
	label.hold = text_hold
	label.z_index = 20
	add_child(label)
	lines_shown += 1
