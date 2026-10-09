extends Resource

class_name ItemData

@export var name: String
@export var icon: Texture2D
@export var rarity: Rarity
@export var max_stack: int = 1
@export var value: int = 0

func gold_value() -> int:
	return value
