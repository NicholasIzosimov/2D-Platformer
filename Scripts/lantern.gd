extends Prop

@export var hook_height: float = 21.0

func _ready() -> void:
	super._ready()
	$Sprite.position.y -= hook_height
	$Light.position.y -= hook_height
	$Light.ground_height = -$Light.position.y
