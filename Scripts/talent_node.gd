@tool
class_name TalentNode
extends Button

const NODE_SIZE: Vector2 = Vector2(48, 48)
@export var talent: TalentData:
	set(value):
		talent = value
		icon = talent.icon if talent else null
@export var parents: Array[TalentNode] = []
var rank_label: Label
var tooltip: String = ""

func _ready() -> void:
	size = NODE_SIZE
	expand_icon = true
	focus_mode = Control.FOCUS_NONE
	icon = talent.icon if talent else null
	if Engine.is_editor_hint():
		return
	rank_label = Label.new()
	rank_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	rank_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	rank_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	rank_label.add_theme_font_size_override("font_size", 12)
	rank_label.add_theme_constant_override("outline_size", 3)
	rank_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(rank_label)
	pressed.connect(func(): PlayerState.spend_talent_point(talent, parent_talents()))

func requirement_nodes() -> Array[TalentNode]:
	var result: Array[TalentNode] = []
	var holder: Node = get_parent()
	if holder is TalentNode:
		result.append(holder)
	for node in parents:
		if node and not result.has(node):
			result.append(node)
	return result

func parent_talents() -> Array[TalentData]:
	var result: Array[TalentData] = []
	for node in requirement_nodes():
		if node.talent:
			result.append(node.talent)
	return result

func is_maxed() -> bool:
	return talent != null and PlayerState.talent_rank(talent) >= talent.max_ranks

func refresh() -> void:
	var rank: int = PlayerState.talent_rank(talent)
	rank_label.text = "%d/%d" % [rank, talent.max_ranks]
	var body: String = talent.description if talent.description != "" else Describe.talent(talent, rank)
	var requirement: String = ""
	if PlayerState.points_spent() < talent.points_required:
		requirement = "\n[color=red]Requires %d points spent in the tree[/color]" % talent.points_required
	tooltip = "[b]%s[/b]\n[color=gray]Rank %d/%d[/color]%s\n\n%s" % [talent.name, rank, talent.max_ranks, requirement, body]
	var tint: Color = Color.WHITE
	if rank >= talent.max_ranks:
		rank_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	elif PlayerState.is_talent_unlocked(talent, parent_talents()):
		var can_add: bool = PlayerState.talent_points > 0
		rank_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4) if can_add else Color.WHITE)
	else:
		tint = Color(0.35, 0.35, 0.35)
		rank_label.add_theme_color_override("font_color", Color.WHITE)
	self_modulate = tint
	rank_label.modulate = tint

func tooltip_sections() -> Array:
	return [tooltip] if tooltip != "" else []
