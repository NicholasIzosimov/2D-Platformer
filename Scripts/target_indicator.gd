extends Node2D

var is_selected: bool = false

func set_selected(value: bool) -> void:
	is_selected = value
	$Selected.visible = value
	owner.get_node("Bars/TargetArrows").visible = value
	
func set_hovered(value: bool) -> void:
	$Hovered.visible = value
	owner.get_node("Bars").modulate = Color(1.4, 1.4, 1.4) if value else Color.WHITE
