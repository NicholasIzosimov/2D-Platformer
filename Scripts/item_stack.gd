class_name ItemStack
extends RefCounted

var item: ItemData
var amount: int = 1

func _init(new_item: ItemData = null, new_amount: int = 1) -> void:
	item = new_item
	amount = new_amount

func space() -> int:
	return max(item.max_stack, 1) - amount
