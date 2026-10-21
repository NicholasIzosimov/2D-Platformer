extends Label

func _ready() -> void:
	if owner.is_in_group("player"):
		hide()
		return
	text = owner.get_node("UnitStats").unit_data.name
