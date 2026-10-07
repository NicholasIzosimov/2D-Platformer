extends Panel

signal right_clicked

@export var slot: ItemData.Slot
@export var empty_icon: Texture2D = preload("res://Assets/ItemIcons/icon_template.png")
@export var filled_background: Texture2D = preload("res://Assets/ItemIcons/icon_equipped_background.png")
var item: ItemData
var empty_text: String = ""

func _ready() -> void:
	refresh()

func set_item(new_item: ItemData) -> void:
	item = new_item
	refresh()

func refresh() -> void:
	$Background.texture = filled_background if item else empty_icon
	$Icon.texture = item.icon if item else null
	tooltip_text = Describe.item(item) if item else empty_text

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		right_clicked.emit()

func _make_custom_tooltip(for_text: String) -> Object:
	return RichTooltip.make(for_text)
