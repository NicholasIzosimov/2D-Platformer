class_name Lighting
extends RefCounted

const GROUP: String = "light_sources"

static func lights_at(tree: SceneTree, at: Vector2, ignore: Node = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for light in tree.get_nodes_in_group(GROUP):
		if not (light is LightSource) or not light.enabled or light.energy < 0.05 or light.texture == null:
			continue
		if ignore and ignore.is_ancestor_of(light):
			continue
		var radius: float = light.texture.get_width() * 0.5 * light.texture_scale * light.global_scale.x
		var offset: Vector2 = at - light.ground_position()
		var distance: float = offset.length()
		if distance >= radius or distance < 0.01:
			continue
		result.append({"light": light, "strength": 1.0 - distance / radius, "direction": offset / distance, "distance_ratio": distance / radius})
	result.sort_custom(func(a, b): return a.strength > b.strength)
	return result

static func light_at(tree: SceneTree, at: Vector2, ignore: Node = null) -> float:
	var total: float = 0.0
	for info in lights_at(tree, at, ignore):
		total += info.strength
	return min(total, 1.0)
