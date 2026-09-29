extends Panel

@export var slot: ItemData.Slot
var item: ItemData

func _ready() -> void:
	refresh()

func set_item(new_item: ItemData) -> void:
	item = new_item
	refresh()

func refresh() -> void:
	if item:
		$Icon.texture = item.icon
		tooltip_text = item.name
	else:
		$Icon.texture = null
		tooltip_text = ItemData.Slot.keys()[slot].capitalize()
