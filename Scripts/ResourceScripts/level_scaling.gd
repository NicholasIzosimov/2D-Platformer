extends Resource

class_name LevelScaling

@export var vigor_per_level: float = 0.0
@export var primary_stat_per_level: float = 0.0
@export var armor_per_level: float = 0.0

func vigor_at(level: int) -> float:
	return vigor_per_level * (level - 1)

func primary_stat_at(level: int) -> float:
	return primary_stat_per_level * (level - 1)

func armor_at(level: int) -> float:
	return armor_per_level * (level - 1)
