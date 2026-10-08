extends Node

@export var enemy_spawner: Node
@export var world: Node
@export var enemy_scene: PackedScene
@export var spawn_table: SpawnTable
@export var max_enemies: int = 8
@export var spawn_interval: float = 1.5
@export var spawn_margin: float = 3.0
@export var population_margin: float = 13.0
@export var spawn_attempts: int = 10

var timer: float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = spawn_interval
	var camera: Camera2D = world.player.get_node("Camera2D")
	var view_size: Vector2 = camera.max_view_size()
	var view := Rect2(camera.get_screen_center_position() - view_size / 2.0, view_size)
	var population: Rect2 = view.grow(Yards.to_px(population_margin))
	var nearby: int = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if population.has_point(enemy.global_position):
			nearby += 1
		elif not enemy.get_node("EnemyCombatController").aggro:
			enemy.queue_free()
	if nearby < max_enemies:
		try_spawn(view)

func try_spawn(view: Rect2) -> void:
	var center: Vector2 = view.get_center()
	var half: Vector2 = view.size / 2.0
	for attempt in spawn_attempts:
		var dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
		var to_edge: float = min(half.x / max(abs(dir.x), 0.001), half.y / max(abs(dir.y), 0.001))
		var distance: float = to_edge + Yards.to_px(randf_range(spawn_margin, population_margin))
		var pos: Vector2 = center + dir * distance
		if world.is_open(pos):
			enemy_spawner.summon_enemy(enemy_scene, pos, spawn_table.pick(PlayerState.level))
			return
