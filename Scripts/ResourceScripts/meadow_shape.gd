extends TerrainShape

class_name MeadowShape

const PROP_INSET: int = 1

@export var ground_tile: Vector2i = Vector2i(1, 1)
@export var spawn_clear_radius: float = 8.0
@export_group("Props")
@export var props: Dictionary[PackedScene, float] = {}
@export var prop_chance: float = 0.5
@export var prop_spacing: int = 5
@export_group("Structures")
@export var structures: Dictionary[PackedScene, float] = {}
@export var structure_chance: float = 0.15
@export var structure_edge_margin: int = 6

func get_ground_tile(_x: int, _y: int) -> Vector2i:
	return ground_tile

func get_prop(x: int, y: int) -> PackedScene:
	if props.is_empty() or Vector2(x, y).length() < spawn_clear_radius:
		return null
	var block := Vector2i(floori(float(x) / prop_spacing), floori(float(y) / prop_spacing))
	if cell_random(block.x, block.y, 200) >= prop_chance:
		return null
	var span: int = prop_spacing - PROP_INSET * 2
	var chosen: Vector2i = block * prop_spacing + Vector2i(PROP_INSET + int(cell_random(block.x, block.y, 201) * span), PROP_INSET + int(cell_random(block.x, block.y, 202) * span))
	if Vector2i(x, y) != chosen:
		return null
	return weighted_pick(props, cell_random(x, y, 1))

func get_structure(c: Vector2i, chunk_size: Vector2i) -> Array:
	if structures.is_empty() or cell_random(c.x, c.y, 100) >= structure_chance:
		return []
	var span: Vector2i = chunk_size - Vector2i(structure_edge_margin, structure_edge_margin) * 2
	var cell := Vector2i(
		c.x * chunk_size.x + structure_edge_margin + int(cell_random(c.x, c.y, 101) * span.x),
		c.y * chunk_size.y + structure_edge_margin + int(cell_random(c.x, c.y, 102) * span.y))
	if Vector2(cell).length() < spawn_clear_radius + structure_edge_margin:
		return []
	var scene = weighted_pick(structures, cell_random(c.x, c.y, 103))
	return [scene, cell] if scene else []
