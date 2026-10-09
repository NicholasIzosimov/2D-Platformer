extends Panel


@export var slot: GearData.Slot
@export var empty_icon: Texture2D = preload("res://Assets/ItemIcons/icon_template.png")
@export var filled_background: Texture2D = preload("res://Assets/ItemIcons/icon_equipped_background.png")
@export var gold_icon: Texture2D = preload("res://Assets/UI/gold_coin.png")
var gold: int = 0
var item: ItemData
var empty_text: String = ""
var compare: bool = false
signal right_clicked
signal left_clicked

func _ready() -> void:
	mouse_entered.connect(func(): $Highlight.visible = true)
	mouse_exited.connect(func(): $Highlight.visible = false)
	refresh()

func set_item(new_item: ItemData) -> void:
	item = new_item
	gold = 0
	refresh()
	
func set_gold(amount: int) -> void:
	item = null
	gold = amount
	refresh()
	
func refresh() -> void:
	var filled: bool = item != null or gold > 0
	$Background.texture = filled_background if filled else empty_icon
	$Icon.texture = item.icon if item else (gold_icon if gold > 0 else null)
	$Amount.visible = gold > 0
	$Amount.text = str(gold)
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
	if gold > 0:
		return ["%d Gold" % gold]
	if item == null:
		return [empty_text] if empty_text != "" else []
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
