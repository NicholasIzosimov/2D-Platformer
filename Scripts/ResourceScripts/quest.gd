extends Resource

class_name Quest

@export var target: UnitData
@export var required: int = 10
@export var progress: int = 0
@export var xp_reward: float = 0.0

func is_complete() -> bool:
	return progress >= required

func describe() -> String:
	return "%s slain: %d/%d" % [target.name, progress, required]
