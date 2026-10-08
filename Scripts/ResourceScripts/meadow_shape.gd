extends TerrainShape

class_name MeadowShape

@export var ground_tile: Vector2i = Vector2i(1, 1)
@export var obstacle_tile: Vector2i = Vector2i(6, 4)
@export var prop_chance: float = 0.02
@export var obstacle_frequency: float = 0.05
@export var obstacle_threshold: float = 0.45
@export var spawn_clear_radius: float = 8.0
@export var props: Dictionary[PackedScene, float] = {}

var noise := FastNoiseLite.new()

func setup(new_seed: int) -> void:
	super.setup(new_seed)
	noise.seed = new_seed
	noise.frequency = obstacle_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

func get_ground_tile(_x: int, _y: int) -> Vector2i:
	return ground_tile

func get_obstacle_tile(x: int, y: int) -> Vector2i:
	if Vector2(x, y).length() < spawn_clear_radius:
		return EMPTY
	if noise.get_noise_2d(x, y) > obstacle_threshold:
		return obstacle_tile
	return EMPTY

func get_prop(x: int, y: int) -> PackedScene:
	if props.is_empty() or Vector2(x, y).length() < spawn_clear_radius:
		return null
	if cell_random(x, y) >= prop_chance:
		return null
	var total: float = 0.0
	for data in props:
		total += props[data]
	var r: float = cell_random(x, y, 1) * total
	for data in props:
		r -= props[data]
		if r < 0.0:
			return data
	return null
