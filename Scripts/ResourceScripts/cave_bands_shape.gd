extends TerrainShape

class_name CaveBandsShape

@export var solid_tile: Vector2i = Vector2i(1, 1)
@export var band_height: int = 16
@export var corridor_ceiling: int = 3
@export var corridor_floor: int = 13
@export var wobble: float = 2.0
@export var wobble_frequency: float = 0.02
@export var shaft_spacing: int = 40
@export var shaft_width: int = 4
@export var shaft_chance: float = 0.5

var noise := FastNoiseLite.new()

func setup(new_seed: int) -> void:
	super.setup(new_seed)
	noise.seed = new_seed
	noise.frequency = wobble_frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

func get_tile(x: int, y: int) -> Vector2i:
	if is_open(x, y):
		return EMPTY
	return solid_tile

func spawn_height(x: int) -> int:
	return corridor_floor + roundi(noise.get_noise_2d(x, 0.0) * wobble) - 2

func is_open(x: int, y: int) -> bool:
	var b: int = floori(y / float(band_height))
	var ly: int = y - b * band_height
	var ceiling: int = corridor_ceiling + roundi(noise.get_noise_2d(x, b * 1000.0 + 500.0) * wobble)
	var floor_y: int = corridor_floor + roundi(noise.get_noise_2d(x, b * 1000.0) * wobble)
	if ly >= ceiling and ly < floor_y:
		return true
	var shaft_start: int = int((shaft_spacing - shaft_width) / 2.0)
	var i: int = floori(x / float(shaft_spacing))
	var lx: int = x - i * shaft_spacing
	if lx >= shaft_start and lx < shaft_start + shaft_width:
		if ly >= floor_y and shaft_open(i, b):
			return true
		if ly < ceiling and shaft_open(i, b - 1):
			return true
	return false

func shaft_open(i: int, b: int) -> bool:
	return posmod(hash(Vector3i(world_seed, i, b)), 1000) < int(shaft_chance * 1000.0)
