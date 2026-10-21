class_name UnitSpawnPoint
extends Marker2D

@export var unit_data: UnitData
@export var spawn_table: SpawnTable
@export var wander_radius: float = 1.0
@export var wander_interval: Vector2 = Vector2(5.0, 9.0)

func pick_unit() -> UnitData:
	if unit_data:
		return unit_data
	if spawn_table:
		return spawn_table.pick(PlayerState.level)
	return null
