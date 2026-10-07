extends Node

@export var max_shadows: int = 2
@export var ambient_light: float = 0.1
var shadows: Array = []

func _ready() -> void:
	var template: Node = get_node("../Shadow")
	shadows.append(template)
	for i in max_shadows - 1:
		var copy: Node = template.duplicate()
		template.add_sibling.call_deferred(copy)
		shadows.append(copy)

func _process(delta: float) -> void:
	var unit: Node = get_parent()
	var lights: Array[Dictionary] = Lighting.lights_at(get_tree(), unit.global_position, unit)
	var total: float = ambient_light
	for info in lights:
		total += info.strength
	for info in lights:
		info["share"] = info.strength / total
	var free_lights: Array = lights.slice(0, shadows.size())
	var slot_info: Array = []
	slot_info.resize(shadows.size())
	for i in shadows.size():
		for info in free_lights:
			if is_instance_valid(shadows[i].shown_light) and info.light == shadows[i].shown_light:
				slot_info[i] = info
				free_lights.erase(info)
				break
	for i in shadows.size():
		if slot_info[i] == null and not free_lights.is_empty():
			slot_info[i] = free_lights.pop_front()
	for i in shadows.size():
		if not shadows[i].is_inside_tree():
			continue
		shadows[i].update_shadow(slot_info[i] if slot_info[i] != null else {}, i == 0 and lights.is_empty(), delta)
