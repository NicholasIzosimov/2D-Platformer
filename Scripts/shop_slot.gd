extends VBoxContainer

signal clicked

func _ready() -> void:
	$Slot.compare = true
	$Slot.left_clicked.connect(clicked.emit)

func set_stack(stack: ItemStack, price: int) -> void:
	$Slot.set_stack(stack)
	$Price.visible = stack != null
	$Price/Label.text = str(price)
