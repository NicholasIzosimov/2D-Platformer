extends Node

@export var ground: TileMapLayer
@export var obstacles: TileMapLayer
@export var player: Node2D
@export var shape: TerrainShape
@export var props_parent: Node2D
@export var max_props_per_frame: int = 20
@export var active_margin: float = 160.0
@export var activation_interval: float = 0.25
@export var chunk_size: Vector2i = Vector2i(32, 32)
@export var load_radius: Vector2i = Vector2i(3, 2)
@export var max_chunks_per_frame: int = 2
@export var source_id: int = 0
var loaded: Dictionary = {}
var blocked: Dictionary = {}
var props: Dictionary = {}
var prop_queue: Array = []
var activation_timer: float = 0.0

func _ready() -> void:
	start_world()

func start_world() -> void:
	shape.setup(randi())
	ground.clear()
	obstacles.clear()
	loaded.clear()
	blocked.clear()
	for chunk_props in props.values():
		for prop in chunk_props:
			prop.queue_free()
	props.clear()
	prop_queue.clear()
	player.global_position = ground.to_global(ground.map_to_local(Vector2i.ZERO))
	var center: Vector2i = player_chunk()
	for cy in range(center.y - load_radius.y, center.y + load_radius.y + 1):
		for cx in range(center.x - load_radius.x, center.x + load_radius.x + 1):
			generate_chunk(Vector2i(cx, cy))
	spawn_queued_props(prop_queue.size())
	player.get_node("Camera2D").reset_smoothing()

func change_shape(new_shape: TerrainShape) -> void:
	shape = new_shape
	start_world()

func _process(delta: float) -> void:
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
	spawn_queued_props(max_props_per_frame)
	activation_timer -= delta
	if activation_timer <= 0.0:
		activation_timer = activation_interval
		update_active_props()
		
func player_chunk() -> Vector2i:
	return pos_to_chunk(player.global_position)

func pos_to_chunk(pos: Vector2) -> Vector2i:
	var cell: Vector2i = ground.local_to_map(ground.to_local(pos))
	return Vector2i(floori(cell.x / float(chunk_size.x)), floori(cell.y / float(chunk_size.y)))

func is_loaded(pos: Vector2) -> bool:
	return loaded.has(pos_to_chunk(pos))

func is_open(pos: Vector2) -> bool:
	return is_loaded(pos) and not blocked.has(ground.local_to_map(ground.to_local(pos)))

func generate_chunk(c: Vector2i) -> void:
	for x in range(c.x * chunk_size.x, (c.x + 1) * chunk_size.x):
		for y in range(c.y * chunk_size.y, (c.y + 1) * chunk_size.y):
			var cell := Vector2i(x, y)
			var ground_tile: Vector2i = shape.get_ground_tile(x, y)
			if ground_tile != TerrainShape.EMPTY:
				ground.set_cell(cell, source_id, ground_tile)
			var obstacle_tile: Vector2i = shape.get_obstacle_tile(x, y)
			if obstacle_tile != TerrainShape.EMPTY:
				obstacles.set_cell(cell, source_id, obstacle_tile)
				blocked[cell] = true
				continue
			var prop_scene: PackedScene = shape.get_prop(x, y)
			if prop_scene:
				prop_queue.append([prop_scene, cell, c])
	props[c] = []
	loaded[c] = true

func spawn_prop(scene: PackedScene, cell: Vector2i) -> Prop:
	var prop: Prop = scene.instantiate()
	prop.position = props_parent.to_local(ground.to_global(ground.map_to_local(cell)))
	props_parent.add_child(prop)
	return prop

func spawn_queued_props(count: int) -> void:
	var spawned: int = 0
	while spawned < count and not prop_queue.is_empty():
		var entry: Array = prop_queue.pop_front()
		var c: Vector2i = entry[2]
		if not loaded.has(c):
			continue
		var prop: Prop = spawn_prop(entry[0], entry[1])
		props[c].append(prop)
		if prop.blocks_cell:
			blocked[entry[1]] = true
		spawned += 1

func unload_chunk(c: Vector2i) -> void:
	for x in range(c.x * chunk_size.x, (c.x + 1) * chunk_size.x):
		for y in range(c.y * chunk_size.y, (c.y + 1) * chunk_size.y):
			var cell := Vector2i(x, y)
			ground.erase_cell(cell)
			obstacles.erase_cell(cell)
			blocked.erase(cell)
	for prop in props.get(c, []):
		prop.queue_free()
	prop_queue = prop_queue.filter(func(entry): return entry[2] != c)
	props.erase(c)
	loaded.erase(c)


func update_active_props() -> void:
	var camera: Camera2D = player.get_node("Camera2D")
	var half: Vector2 = camera.max_view_size() / 2.0 + Vector2(active_margin, active_margin)
	var area := Rect2(camera.get_screen_center_position() - half, half * 2.0)
	for chunk_props in props.values():
		for prop in chunk_props:
			prop.set_active(area.has_point(prop.global_position))
