class_name ScreenSized
extends Node2D

@export var pivot: Vector2 = Vector2.ZERO
var base_position: Vector2
var extra_scale: float = 1.0
var lift: float = 0.0

func _ready() -> void:
	base_position = position

func _process(_delta: float) -> void:
	var s: float = extra_scale / world_zoom()
	scale = Vector2(s, s)
	position = base_position + pivot * (1.0 - s) + Vector2(0.0, lift)

func world_zoom() -> float:
	var camera := get_viewport().get_camera_2d()
	return camera.zoom.x if camera else 1.0
