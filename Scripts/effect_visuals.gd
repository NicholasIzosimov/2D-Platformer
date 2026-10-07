extends Node2D

const EFFECTS: SpriteFrames = preload("res://Resources/Animations/effect_animations.tres")
const GLOW: Texture2D = preload("res://Resources/Lights/soft_glow.tres")
var active: Dictionary = {}

func _ready() -> void:
	var combat_handler = owner.get_node("CombatHandler")
	combat_handler.effect_applied.connect(_on_effect_applied)
	combat_handler.effect_expired.connect(_on_effect_expired)
	owner.get_node("UnitStats").died.connect(func(): visible = false)

func _on_effect_applied(effect) -> void:
	if active.has(effect):
		return
	var anim: String = owner.get_node("CombatHandler").visual_key(effect) + "_aura"
	var has_anim: bool = EFFECTS.has_animation(anim)
	if not has_anim and effect.glow_energy <= 0.0:
		return
	var holder := Node2D.new()
	add_child(holder)
	if has_anim:
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = EFFECTS
		if effect.aura_glows:
			var glow_material := CanvasItemMaterial.new()
			glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
			sprite.material = glow_material
		holder.add_child(sprite)
		sprite.play(anim)
	if effect.glow_energy > 0.0:
		var light := PointLight2D.new()
		light.texture = GLOW
		light.color = effect.glow_color
		light.energy = effect.glow_energy
		light.texture_scale = effect.glow_scale
		holder.add_child(light)
	active[effect] = holder
	
func _on_effect_expired(effect) -> void:
	if active.has(effect):
		active[effect].queue_free()
		active.erase(effect)
