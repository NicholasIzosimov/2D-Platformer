extends Node

@export var enemy_spawner: Node
@export var world: Node
@export var enemy_scene: PackedScene
@export var spawn_table: SpawnTable
@export var max_enemies: int = 8
@export var spawn_interval: float = 1.5
@export var edge_margin: float = 2.0
@export var spawn_attempts: int = 10

var timer: float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = spawn_interval
	despawn_unloaded_enemies()
	if get_tree().get_nodes_in_group("enemies").size() < max_enemies:
		try_spawn()

func try_spawn() -> void:
	var view: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	var center: Vector2 = view.get_center()
	var half: Vector2 = view.size / 2
	for attempt in spawn_attempts:
		var dir: Vector2 = Vector2.RIGHT.rotated(randf() * TAU)
		var to_edge: float = min(half.x / max(abs(dir.x), 0.001), half.y / max(abs(dir.y), 0.001))
		var pos: Vector2 = center + dir * (to_edge + Yards.to_px(edge_margin))
		if world.is_open(pos):
			enemy_spawner.summon_enemy(enemy_scene, pos, spawn_table.pick(PlayerState.level))
			return

func despawn_unloaded_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get_node("EnemyCombatController").aggro:
			continue
		if not world.is_loaded(enemy.global_position):
			enemy.queue_free()
