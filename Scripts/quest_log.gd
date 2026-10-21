extends PanelContainer

var shown: bool = true

func _ready() -> void:
	add_to_group("layout_preview")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = shown
	PlayerState.quests_changed.connect(refresh)
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest_log"):
		shown = not shown
		visible = shown
		get_viewport().set_input_as_handled()

func set_preview(value: bool) -> void:
	visible = value or shown

func refresh() -> void:
	for child in %QuestList.get_children():
		%QuestList.remove_child(child)
		child.queue_free()
	if PlayerState.quests.is_empty():
		add_line("No active quests", Color.GRAY)
	for quest in PlayerState.quests:
		add_line(quest.describe(), Color.WHITE)
		add_line("Reward: %d XP" % roundi(quest.xp_reward), Color.GRAY)

func add_line(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	%QuestList.add_child(label)
