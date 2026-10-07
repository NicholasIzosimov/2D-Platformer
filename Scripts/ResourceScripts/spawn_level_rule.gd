extends Resource

class_name SpawnLevelRule

@export var levels_below: int = 20
@export var falloff: float = 0.8
@export var levels_above: int = 3
@export var above_chance: float = 0.05
@export var above_falloff: float = 0.5

func weight(offset: int) -> float:
	if offset <= 0:
		return pow(falloff, -offset)
	return above_chance * pow(above_falloff, offset - 1)

func roll(player_level: int) -> int:
	var lowest: int = max(1, player_level - levels_below)
	var highest: int = player_level + levels_above
	var total: float = 0.0
	for lvl in range(lowest, highest + 1):
		total += weight(lvl - player_level)
	var r: float = randf() * total
	for lvl in range(lowest, highest + 1):
		r -= weight(lvl - player_level)
		if r < 0.0:
			return lvl
	return player_level
