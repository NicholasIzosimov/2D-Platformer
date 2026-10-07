extends Resource

class_name LevelScaling

@export_group("Vigor")
@export var vigor_per_level: float = 0.0
@export var vigor_exponent: float = 1.0

@export_group("Primary Stat")
@export var primary_stat_per_level: float = 0.0
@export var primary_stat_exponent: float = 1.0

@export_group("Armor")
@export var armor_per_level: float = 0.0
@export var armor_exponent: float = 1.0

func vigor_at(level: int) -> float:
	return scaled(vigor_per_level, vigor_exponent, level)

func primary_stat_at(level: int) -> float:
	return scaled(primary_stat_per_level, primary_stat_exponent, level)

func armor_at(level: int) -> float:
	return scaled(armor_per_level, armor_exponent, level)

func scaled(per_level: float, exponent: float, level: int) -> float:
	return per_level * pow(max(level - 1, 0), exponent)
