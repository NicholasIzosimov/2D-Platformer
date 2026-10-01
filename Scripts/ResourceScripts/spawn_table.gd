extends Resource

class_name SpawnTable

@export var entries: Array[SpawnEntry] = []

func pick(player_level: int) -> UnitData:
	var total: float = 0.0
	for entry in entries:
		if player_level >= entry.min_player_level:
			total += entry.weight
	if total <= 0.0:
		return null
	var r: float = randf() * total
	for entry in entries:
		if player_level < entry.min_player_level:
			continue
		r -= entry.weight
		if r < 0.0:
			return entry.unit_data
	return null
