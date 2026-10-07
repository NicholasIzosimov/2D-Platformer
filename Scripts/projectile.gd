extends Area2D

var caster: Node
var ability: AbilityData
var direction: Vector2
var max_distance: float
var traveled: float = 0.0
var hit: bool = false

func setup(new_caster: Node, new_ability: AbilityData, new_direction: Vector2, new_max_distance: float) -> void:
	caster = new_caster
	ability = new_ability
	direction = new_direction
	max_distance = new_max_distance

func _ready() -> void:
	rotation = direction.angle()
	z_index = 10
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	var key: String = caster.visual_key(ability)
	var anim: String = key + "_projectile"
	if key != "" and $AnimatedSprite2D.sprite_frames.has_animation(anim):
		$AnimatedSprite2D.play(anim)
	else:
		push_warning("Missing projectile animation: " + anim)

func _physics_process(delta: float) -> void:
	var step: float = Yards.to_px(ability.projectile_speed) * delta
	global_position += direction * step
	traveled += step
	if traveled >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if hit or not is_instance_valid(caster):
		return
	var unit: Node = area.owner
	var shooter: Node = caster.get_parent()
	if unit == shooter or unit.get_node("UnitStats").is_dead:
		return
	if unit.is_in_group("player") == shooter.is_in_group("player"):
		return
	hit = true
	caster.resolve_effects(ability, unit)
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body is TileMapLayer:
		queue_free()
