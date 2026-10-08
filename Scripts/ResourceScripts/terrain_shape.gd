extends Resource

class_name TerrainShape

const EMPTY := Vector2i(-1, -1)
var world_seed: int = 0

func setup(new_seed: int) -> void:
	world_seed = new_seed

func get_ground_tile(_x: int, _y: int) -> Vector2i:
	return EMPTY

func get_obstacle_tile(_x: int, _y: int) -> Vector2i:
	return EMPTY

func get_prop(_x: int, _y: int) -> PackedScene:
	return null

func cell_random(x: int, y: int, salt: int = 0) -> float:
	return float(hash(Vector3i(x, y, world_seed + salt)) & 0xFFFFFF) / 16777216.0
