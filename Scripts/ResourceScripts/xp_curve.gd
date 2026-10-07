extends Resource

class_name XpCurve

@export var kills_base: float = 10.0
@export var kills_per_level: float = 15.0
@export var kills_exponent: float = 1.0
@export var reward_base: float = 10.0
@export var reward_per_level: float = 10.0
@export var reward_exponent: float = 1.0

func kills_for_level(level: int) -> float:
	return kills_base + kills_per_level * pow(level - 1, kills_exponent)

func xp_for_enemy_level(level: int) -> float:
	return reward_base + reward_per_level * pow(level - 1, reward_exponent)

func xp_to_next_level(level: int) -> float:
	return kills_for_level(level) * xp_for_enemy_level(level)
