extends Button

class_name TalentButton

var talent: TalentData
var rank_label: Label

func setup(new_talent: TalentData) -> void:
	talent = new_talent

func _ready() -> void:
	icon = talent.icon
	expand_icon = true
	focus_mode = Control.FOCUS_NONE
	rank_label = Label.new()
	rank_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	rank_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rank_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rank_label.add_theme_font_size_override("font_size", 12)
	rank_label.add_theme_constant_override("outline_size", 3)
	rank_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(rank_label)
	pressed.connect(func(): PlayerState.spend_talent_point(talent))
	refresh()

func refresh() -> void:
	var rank: int = PlayerState.talent_rank(talent)
	rank_label.text = "%d/%d" % [rank, talent.max_ranks]
	var body: String = talent.description if talent.description != "" else Describe.talent(talent, rank)
	tooltip_text = "[b]%s[/b]\n[color=gray]Rank %d/%d[/color]\n\n%s" % [talent.name, rank, talent.max_ranks, body]
	if rank >= talent.max_ranks:
		modulate = Color.WHITE
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	elif PlayerState.is_talent_unlocked(talent):
		modulate = Color.WHITE
		var can_add: bool = PlayerState.talent_points > 0
		rank_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if can_add else Color.WHITE)
	else:
		modulate = Color(0.35, 0.35, 0.35)
		rank_label.add_theme_color_override("font_color", Color.WHITE)
		
func _make_custom_tooltip(for_text: String) -> Object:
	return RichTooltip.make(for_text)
