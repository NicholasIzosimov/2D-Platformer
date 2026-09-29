extends TerrainShape

class_name PlainsShape

@export var surface_tile: Vector2i = Vector2i(1, 0)
@export var ground_tile: Vector2i = Vector2i(1, 1)
@export var base_height: int = 0
@export var hill_height: float = 3.0
@export var hill_frequency: float = 0.03

var noise := FastNoiseLite.new()

func setup(new_seed: int) -> void:
	super.setup(new_seed)
	noise.seed = new_seed
	noise.frequency = hill_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

func surface_y(x: int) -> int:
	return base_height - roundi(noise.get_noise_1d(x) * hill_height)

func get_tile(x: int, y: int) -> Vector2i:
	var surface: int = surface_y(x)
	if y < surface:
		return EMPTY
	if y == surface:
		return surface_tile
	return ground_tile

func spawn_height(x: int) -> int:
	return surface_y(x) - 2
