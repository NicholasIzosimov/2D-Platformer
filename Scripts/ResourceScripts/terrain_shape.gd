extends Resource

class_name TerrainShape

const EMPTY := Vector2i(-1, -1)
var world_seed: int = 0

func setup(new_seed: int) -> void:
	world_seed = new_seed

func get_tile(_x: int, _y: int) -> Vector2i:
	return EMPTY

func spawn_height(_x: int) -> int:
	return 0
