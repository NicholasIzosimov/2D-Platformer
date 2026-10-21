extends Panel


@export var slot: GearData.Slot
@export var empty_icon: Texture2D = preload("res://Assets/ItemIcons/icon_template.png")
@export var filled_background: Texture2D = preload("res://Assets/ItemIcons/icon_equipped_background.png")
var item: ItemData
var empty_text: String = ""
var compare: bool = false
var stack: ItemStack
signal right_clicked
signal left_clicked

func _ready() -> void:
	mouse_entered.connect(func(): $Highlight.visible = true)
	mouse_exited.connect(func(): $Highlight.visible = false)
	refresh()

func set_item(new_item: ItemData) -> void:
	set_stack(ItemStack.new(new_item) if new_item else null)
	
func refresh() -> void:
	$Background.texture = filled_background if item else empty_icon
	$Icon.texture = item.icon if item else null
	$Amount.visible = stack != null and (stack.amount > 1 or item is CurrencyData)
	$Amount.text = str(stack.amount) if stack else ""
	var rarity: Rarity = item.rarity if item else null
	$RarityBorder.visible = rarity != null
	if rarity:
		$RarityBorder.self_modulate = rarity.color

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit()

func tooltip_sections() -> Array:
	if item == null:
		return [empty_text] if empty_text != "" else []
	if item is CurrencyData:
		return ["%d %s" % [stack.amount, item.name]]
	if not compare or not (item is GearData):
		return [Describe.item(item)]
	if not Input.is_action_pressed("compare_item"):
		return [Describe.item(item) + "\n[color=gray]Hold Shift to compare[/color]"]
	var equipped: ItemData = PlayerState.equipped_gear.get(item.slot)
	var sections: Array = [Describe.item(item)]
	if equipped:
		sections.append("[color=gray]Currently equipped[/color]\n" + Describe.item(equipped))
	sections.append(Describe.item_comparison(item, equipped))
	return sections

func set_stack(new_stack: ItemStack) -> void:
	stack = new_stack
	item = stack.item if stack else null
	refresh()
