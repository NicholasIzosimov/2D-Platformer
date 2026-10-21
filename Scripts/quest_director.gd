extends Node

@export var spawn_table: SpawnTable
@export var kill_count: int = 10
@export var xp_fraction: float = 0.1

func _ready() -> void:
	PlayerState.quests_changed.connect(ensure_quest)
	ensure_quest()

func ensure_quest() -> void:
	if not PlayerState.quests.is_empty():
		return
	var target: UnitData = spawn_table.pick(PlayerState.level)
	if target == null:
		return
	var quest := Quest.new()
	quest.target = target
	quest.required = kill_count
	quest.xp_reward = PlayerState.xp_to_next_level() * xp_fraction
	PlayerState.add_quest(quest)
