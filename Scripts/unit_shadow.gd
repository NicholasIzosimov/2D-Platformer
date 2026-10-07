extends AnimatedSprite2D

const SHADER: Shader = preload("res://Resources/Shaders/unit_shadow.gdshader")
@export var squash: float = 0.25
@export var shadow_color: Color = Color(0, 0, 0, 1)
@export var ambient_alpha: float = 0.15
@export var lit_alpha: float = 0.45
@export var min_lit_squash: float = 0.4
@export var max_lit_squash: float = 1.0
@export var length_bonus: float = 0.8
@export var near_width: float = 0.4
@export var far_width: float = 1.8
@export var smoothing: float = 2.0
@export var fade_out_speed: float = 20.0
@export var fade_in_speed: float = 3.0
@export var enter_strength: float = 0.1
@export var leave_strength: float = 0.05
var source: AnimatedSprite2D
var light_angle: float = 0.0
var length: float = 0.0
var shown_light: Node = null
var shown_ambient: bool = false
var fade: float = 0.0

func _ready() -> void:
	source = get_node("../AnimatedSprite2D")
	sprite_frames = source.sprite_frames
	z_index = -1
	centered = source.centered
	skew = 0.0
	length = squash
	material = ShaderMaterial.new()
	material.shader = SHADER

func update_shadow(info: Dictionary, allow_ambient: bool, delta: float) -> void:
	if shown_light != null and not is_instance_valid(shown_light):
		shown_light = null
	var t: float = 1.0 - exp(-smoothing * delta)
	var light: Node = info.get("light")
	var strength: float = info.get("strength", 0.0)
	var threshold: float = leave_strength if light != null and light == shown_light else enter_strength
	var wanted_light: Node = light if light != null and strength > threshold else null
	var wanted_ambient: bool = wanted_light == null and allow_ambient
	var target_angle: float = info.get("direction", Vector2.DOWN).angle() - PI / 2.0
	var lit_length: float = lerp(min_lit_squash, max_lit_squash, info.get("distance_ratio", 0.0)) * (1.0 + length_bonus)
	if wanted_light != shown_light or wanted_ambient != shown_ambient:
		fade = max(0.0, fade - fade_out_speed * delta)
		if fade <= 0.0:
			shown_light = wanted_light
			shown_ambient = wanted_ambient
			light_angle = target_angle
			length = lit_length if shown_light else squash
	else:
		fade = min(1.0, fade + fade_in_speed * delta)
	var showing_info: bool = shown_light != null and light == shown_light
	if showing_info:
		light_angle = lerp_angle(light_angle, target_angle, t)
		length = lerp(length, lit_length, t)
	elif shown_light == null:
		length = lerp(length, squash, t)
	rotation = light_angle if shown_light else 0.0
	var lit_amount: float = smoothstep(0.0, 1.0, strength) if showing_info else 0.0
	offset = source.position / source.scale + source.offset
	scale = Vector2(source.scale.x, -source.scale.y * length)
	if animation != source.animation:
		animation = source.animation
	frame = source.frame
	flip_h = source.flip_h != (cos(rotation) < 0.0)
	visible = source.visible
	var alpha: float = 0.0
	if shown_light:
		alpha = lit_alpha * lit_amount * lit_amount * info.get("share", 1.0)
	elif shown_ambient:
		alpha = ambient_alpha
	modulate = Color(shadow_color, alpha * fade * source.modulate.a)
	update_taper(lit_amount)

func update_taper(lit_amount: float) -> void:
	var texture: Texture2D = sprite_frames.get_frame_texture(animation, frame)
	if texture == null:
		return
	var frame_size: Vector2 = texture.get_size()
	var region := Vector4(0.0, 0.0, 1.0, 1.0)
	if texture is AtlasTexture:
		var atlas_size: Vector2 = texture.atlas.get_size()
		region = Vector4(texture.region.position.x / atlas_size.x, texture.region.position.y / atlas_size.y, texture.region.size.x / atlas_size.x, texture.region.size.y / atlas_size.y)
	material.set_shader_parameter("region", region)
	material.set_shader_parameter("feet_v", (frame_size.y / 2.0 - offset.y) / frame_size.y)
	material.set_shader_parameter("near_width", lerp(1.0, near_width, lit_amount))
	material.set_shader_parameter("far_width", lerp(1.0, far_width, lit_amount))
