extends Prop

@export var warmth: StatusEffect
@export var pulse_interval: float = 0.5

var summoner: Node
var timer: float = 0.0
var snuffed: bool = false

func setup(new_summoner: Node) -> void:
	summoner = new_summoner

func _ready() -> void:
	super._ready()
	$AnimatedSprite2D.play("burn")
	if summoner == null:
		return
	set_active(true)
	var combat_state = summoner.get_node("CombatState")
	combat_state.combat_changed.connect(_on_combat_changed)
	if combat_state.in_combat:
		snuff()

func _process(delta: float) -> void:
	if snuffed or not is_instance_valid(summoner):
		return
	timer -= delta
	if timer > 0.0:
		return
	timer = pulse_interval
	for area in $WarmthArea.get_overlapping_areas():
		if area.owner == summoner:
			summoner.get_node("CombatHandler").apply_effect(warmth, null)

func _on_combat_changed(in_combat: bool) -> void:
	if in_combat and not snuffed:
		snuff()

func snuff() -> void:
	snuffed = true
	create_tween().tween_property($PointLight2D, "energy", 0.0, 0.5)
	$AnimatedSprite2D.play("snuff")
	await $AnimatedSprite2D.animation_finished
	if not $VisibleOnScreenNotifier2D.is_on_screen():
		queue_free()
		return
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)
