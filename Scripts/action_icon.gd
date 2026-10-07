extends AnimatedSprite2D

enum Action {NONE, QUEST_TARGET}

var stats: Node

func _ready() -> void:
	stats = owner.get_node("UnitStats")
	PlayerState.quests_changed.connect(refresh)
	stats.died.connect(refresh)
	refresh()

func refresh() -> void:
	var key: String = Action.keys()[current_action()].to_lower()
	visible = key != "none" and sprite_frames.has_animation(key)
	if visible:
		play(key)

func current_action() -> Action:
	if stats.is_dead:
		return Action.NONE
	if PlayerState.is_quest_target(stats.unit_data):
		return Action.QUEST_TARGET
	return Action.NONE
