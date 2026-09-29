extends Node

@export var terrain: TileMapLayer
@export var player: Node2D
@export var shape: TerrainShape
@export var chunk_size: Vector2i = Vector2i(32, 32)
@export var load_radius: Vector2i = Vector2i(3, 2)
@export var max_chunks_per_frame: int = 2
@export var source_id: int = 0

var loaded: Dictionary = {}

func _ready() -> void:
	start_world()
func change_shape(new_shape: TerrainShape) -> void:
	shape = new_shape
	loaded.clear()
	start_world()
func start_world() -> void:
	shape.setup(randi())
	terrain.clear()
	var spawn_cell := Vector2i(0, shape.spawn_height(0))
	player.global_position = terrain.to_global(terrain.map_to_local(spawn_cell))
	var center: Vector2i = player_chunk()
	for cy in range(center.y - load_radius.y, center.y + load_radius.y + 1):
		for cx in range(center.x - load_radius.x, center.x + load_radius.x + 1):
			generate_chunk(Vector2i(cx, cy))
	player.get_node("Camera2D").reset_smoothing()

func _process(_delta: float) -> void:
	var center: Vector2i = player_chunk()
	var loads_left: int = max_chunks_per_frame
	for cy in range(center.y - load_radius.y, center.y + load_radius.y + 1):
		for cx in range(center.x - load_radius.x, center.x + load_radius.x + 1):
			var c := Vector2i(cx, cy)
			if loads_left > 0 and not loaded.has(c):
				generate_chunk(c)
				loads_left -= 1
	for c in loaded.keys():
		if abs(c.x - center.x) > load_radius.x + 1 or abs(c.y - center.y) > load_radius.y + 1:
			unload_chunk(c)

func player_chunk() -> Vector2i:
	var cell: Vector2i = terrain.local_to_map(terrain.to_local(player.global_position))
	return Vector2i(floori(cell.x / float(chunk_size.x)), floori(cell.y / float(chunk_size.y)))

func generate_chunk(c: Vector2i) -> void:
	for x in range(c.x * chunk_size.x, (c.x + 1) * chunk_size.x):
		for y in range(c.y * chunk_size.y, (c.y + 1) * chunk_size.y):
			var tile: Vector2i = shape.get_tile(x, y)
			if tile != TerrainShape.EMPTY:
				terrain.set_cell(Vector2i(x, y), source_id, tile)
	loaded[c] = true

func unload_chunk(c: Vector2i) -> void:
	for x in range(c.x * chunk_size.x, (c.x + 1) * chunk_size.x):
		for y in range(c.y * chunk_size.y, (c.y + 1) * chunk_size.y):
			terrain.erase_cell(Vector2i(x, y))
	loaded.erase(c)
