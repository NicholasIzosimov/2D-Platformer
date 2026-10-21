class_name Lighting
extends RefCounted

const GROUP: String = "light_sources"
const CASTER_GROUP: String = "shadow_casters"
const SHADOW_GROUP: String = "cast_shadows"

static func lights_at(tree: SceneTree, at: Vector2, ignore: Node = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for light in tree.get_nodes_in_group(GROUP):
		if not light.has_method("light_info"):
			continue
		if ignore and ignore.is_ancestor_of(light):
			continue
		var info: Dictionary = light.light_info(at)
		if not info.is_empty():
			result.append(info)
	result.sort_custom(func(a, b): return a.strength > b.strength)
	return result

static func light_at(tree: SceneTree, at: Vector2, ignore: Node = null) -> float:
	var total: float = 0.0
	for info in lights_at(tree, at, ignore):
		total += info.strength
	return min(total, 1.0)

static func wake_casters(tree: SceneTree, light: Node2D) -> void:
	tree.call_group(CASTER_GROUP, "wake", light)
