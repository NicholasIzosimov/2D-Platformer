extends Camera2D

@export var follow_smoothing: float = 12.0
@export var lead_time: float = 0.10
@export var max_lead: float = 10.0
@export var lead_smoothing: float = 9

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing

func _process(delta: float) -> void:
	var body := get_parent() as CharacterBody2D
	var target_offset: Vector2 = (body.velocity * lead_time).limit_length(max_lead)
	offset = offset.lerp(target_offset, 1.0 - exp(-lead_smoothing * delta))
