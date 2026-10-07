extends Node

@export var world: Node
@export var player: Node2D
@export var field_radius: int = 25
@export var update_interval: float = 0.25

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]

var distances: Dictionary = {}
var timer: float = 0.0

func _ready() -> void:
	add_to_group("flow_field")

func _physics_process(delta: float) -> void:
	timer -= delta
	if timer <= 0.0:
		timer = update_interval
		rebuild()

func world_to_cell(pos: Vector2) -> Vector2i:
	return world.ground.local_to_map(world.ground.to_local(pos))

func cell_to_world(cell: Vector2i) -> Vector2:
	return world.ground.to_global(world.ground.map_to_local(cell))

func rebuild() -> void:
	distances.clear()
	var start: Vector2i = world_to_cell(player.global_position)
	distances[start] = 0
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		var d: int = distances[cell]
		if d >= field_radius:
			continue
		for dir in DIRS:
			var next: Vector2i = cell + dir
			if distances.has(next) or world.blocked.has(next):
				continue
			if dir.x != 0 and dir.y != 0:
				if world.blocked.has(cell + Vector2i(dir.x, 0)) or world.blocked.has(cell + Vector2i(0, dir.y)):
					continue
			distances[next] = d + 1
			queue.append(next)

func get_direction(pos: Vector2) -> Vector2:
	var cell: Vector2i = world_to_cell(pos)
	if not distances.has(cell):
		return Vector2.ZERO
	var best: Vector2i = cell
	var best_d: int = distances[cell]
	for dir in DIRS:
		var next: Vector2i = cell + dir
		if distances.has(next) and distances[next] < best_d:
			best_d = distances[next]
			best = next
	if best == cell:
		return Vector2.ZERO
	return pos.direction_to(cell_to_world(best))

func find_free_position(pos: Vector2) -> Vector2:
	var cell: Vector2i = world_to_cell(pos)
	if not world.blocked.has(cell):
		return pos
	for r in range(1, 20):
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				if max(abs(x), abs(y)) != r:
					continue
				var c: Vector2i = cell + Vector2i(x, y)
				if not world.blocked.has(c):
					return cell_to_world(c)
	return pos
