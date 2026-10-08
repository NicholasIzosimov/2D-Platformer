class_name UnitSpawnPoint
extends Marker2D

@export var unit_data: UnitData
@export var spawn_table: SpawnTable

func pick_unit() -> UnitData:
	if unit_data:
		return unit_data
	if spawn_table:
		return spawn_table.pick(PlayerState.level)
	return null
