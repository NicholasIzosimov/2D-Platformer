extends Node

@export var max_shadows: int = 2
@export var ambient_light: float = 0.1
@export var sources: Array[NodePath] = [NodePath("../AnimatedSprite2D")]
@export var update_interval: float = 0.0
@export var moves: bool = true
@export var lazy: bool = false
@export var wake_duration: float = 0.5
@export var min_secondary_share: float = 0.25
var template: Node
var slots: Array = []
var elapsed: float = 0.0
var awake: float = 0.0

func _ready() -> void:
	add_to_group(Lighting.CASTER_GROUP)
	template = get_node("../Shadow")
	template.hide()
	template.set_physics_process(false)
	elapsed = randf() * update_interval
	if not lazy:
		create_shadows()

func create_shadows() -> void:
	if not slots.is_empty():
		return
	for i in max_shadows:
		var slot: Array = []
		for path in sources:
			var shadow: Node = template.duplicate()
			shadow.unit = get_parent()
			shadow.source = get_node(path)
			shadow.set_physics_process(moves)
			shadow.show()
			get_parent().add_child.call_deferred(shadow)
			slot.append(shadow)
		slots.append(slot)
	elapsed = update_interval

func free_shadows() -> void:
	for slot in slots:
		for shadow in slot:
			if is_instance_valid(shadow):
				shadow.queue_free()
	slots.clear()

func _exit_tree() -> void:
	free_shadows()

func _process(delta: float) -> void:
	if slots.is_empty():
		return
	elapsed += delta
	awake = max(awake - delta, 0.0)
	if awake <= 0.0 and elapsed < update_interval:
		return
	var step: float = elapsed
	elapsed = 0.0
	var unit: Node = get_parent()
	var lights: Array[Dictionary] = Lighting.lights_at(get_tree(), unit.global_position, unit)
	var total: float = ambient_light
	for info in lights:
		total += info.strength
	for info in lights:
		info["share"] = info.strength / total
	var free_lights: Array = lights.slice(0, slots.size()).filter(func(info): return info == lights[0] or info.share >= min_secondary_share)
	var slot_info: Array = []
	slot_info.resize(slots.size())
	for i in slots.size():
		for info in free_lights:
			if is_instance_valid(slots[i][0].shown_light) and info.light == slots[i][0].shown_light:
				slot_info[i] = info
				free_lights.erase(info)
				break
	for i in slots.size():
		if slot_info[i] == null and not free_lights.is_empty():
			slot_info[i] = free_lights.pop_front()
	for i in slots.size():
		for shadow in slots[i]:
			if shadow.is_inside_tree():
				shadow.update_shadow(slot_info[i] if slot_info[i] != null else {}, i == 0 and lights.is_empty(), step)

func wake(light: Node2D) -> void:
	if light is LightSource and light.ground_position().distance_to(get_parent().global_position) > light.radius():
		return
	awake = wake_duration
	elapsed = 0.0
