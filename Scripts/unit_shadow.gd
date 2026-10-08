extends Node2D

const SHADER: Shader = preload("res://Resources/Shaders/unit_shadow.gdshader")
const SWAY_SHADER: Shader = preload("res://Resources/Shaders/sway.gdshader")
@export var squash: float = 0.25
@export var ambient_alpha: float = 0.15
@export var lit_alpha: float = 0.45
@export var min_lit_squash: float = 0.4
@export var max_lit_squash: float = 1.0
@export var length_bonus: float = 0.8
@export var near_width: float = 0.4
@export var far_width: float = 1.8
@export var tip_fade: float = 0.7
@export var min_vertical: float = 0.15
@export var smoothing: float = 2.0
@export var fade_out_speed: float = 20.0
@export var fade_in_speed: float = 3.0
@export var enter_strength: float = 0.1
@export var leave_strength: float = 0.05
@export var share_contrast: float = 2.0
var source: Node2D
var light_angle: float = PI / 2.0
var length: float = 0.0
var shown_light: Node = null
var shown_ambient: bool = false
var fade: float = 0.0
var bounds: Rect2 = Rect2()
var shown_alpha: float = 0.0
var shown_lit: float = 0.0
var unit: Node2D
var layers: ShadowLayers

func _ready() -> void:
	layers = get_tree().get_first_node_in_group(ShadowLayers.GROUP)
	length = squash
	material = ShaderMaterial.new()
	material.shader = SHADER
	apply_sway()
	
func _physics_process(_delta: float) -> void:
	if is_instance_valid(unit):
		global_position = unit.global_position

func update_shadow(info: Dictionary, allow_ambient: bool, delta: float) -> void:
	if not is_instance_valid(shown_light):
		shown_light = null
	var t: float = 1.0 - exp(-smoothing * delta)
	var light: Node = info.get("light")
	var strength: float = info.get("strength", 0.0)
	var threshold: float = leave_strength if light != null and light == shown_light else enter_strength
	var wanted_light: Node = light if light != null and strength > threshold else null
	var wanted_ambient: bool = wanted_light == null and allow_ambient
	var target_angle: float = info.get("direction", Vector2.DOWN).angle()
	var lit_length: float = lerp(min_lit_squash, max_lit_squash, info.get("distance_ratio", 0.0)) * (1.0 + length_bonus) * info.get("length_scale", 1.0)
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
		shown_lit = smoothstep(0.0, 1.0, strength) * info.get("spread", 1.0)
		shown_alpha = lit_alpha * info.get("darkness", 1.0) * pow(info.get("share", 1.0), share_contrast)
	elif shown_light == null:
		length = lerp(length, squash, t)
		shown_lit = 0.0
		shown_alpha = ambient_alpha if shown_ambient else 0.0
	var direction: Vector2 = Vector2.from_angle(light_angle) if shown_light else Vector2.DOWN
	modulate = Color(shown_alpha, shown_alpha, shown_alpha, fade * source.modulate.a)
	visible = source.visible
	if layers:
		layers.place(self, shown_light)
	update_projection(direction * length, shown_lit)

func update_projection(shift: Vector2, lit_amount: float) -> void:
	var texture: Texture2D = source.sprite_frames.get_frame_texture(source.animation, source.frame) if source is AnimatedSprite2D else source.texture
	if texture == null:
		return
	if abs(shift.y) < min_vertical:
		shift.y = min_vertical if shift.y >= 0.0 else -min_vertical
	var atlas: Texture2D = texture
	var frame_rect := Rect2(Vector2.ZERO, texture.get_size())
	if texture is AtlasTexture:
		atlas = texture.atlas
		frame_rect = texture.region
	elif source is Sprite2D and source.region_enabled:
		frame_rect = source.region_rect
	var atlas_size: Vector2 = atlas.get_size()
	var region := Vector4(frame_rect.position.x / atlas_size.x, frame_rect.position.y / atlas_size.y, frame_rect.size.x / atlas_size.x, frame_rect.size.y / atlas_size.y)
	var frame_size: Vector2 = frame_rect.size
	var body_size: Vector2 = frame_size * source.scale.abs()
	var center_offset: Vector2 = source.offset + (Vector2.ZERO if source.centered else frame_size / 2.0)
	var body_center: Vector2 = source.position + center_offset * source.scale
	var top_height: float = max(body_size.y / 2.0 - body_center.y, 1.0)
	var far: float = lerp(1.0, far_width, lit_amount)
	material.set_shader_parameter("body", atlas)
	material.set_shader_parameter("region", region)
	material.set_shader_parameter("body_center", body_center)
	material.set_shader_parameter("body_size", body_size)
	material.set_shader_parameter("flip", 1.0 if source.flip_h else 0.0)
	material.set_shader_parameter("shift", shift)
	material.set_shader_parameter("top_height", top_height)
	material.set_shader_parameter("near_width", lerp(1.0, near_width, lit_amount))
	material.set_shader_parameter("far_width", far)
	material.set_shader_parameter("tip_fade", tip_fade * lit_amount)
	var half: float = body_size.x * 0.5 * max(1.0, far) + abs(body_center.x)
	var tip: Vector2 = shift * top_height
	bounds = Rect2(Vector2(-half, 0.0), Vector2.ZERO).expand(Vector2(half, 0.0)).expand(tip + Vector2(-half, 0.0)).expand(tip + Vector2(half, 0.0)).grow(2.0)
	queue_redraw()

func _draw() -> void:
	draw_rect(bounds, Color.WHITE)

func apply_sway() -> void:
	if source == null or not source.material is ShaderMaterial:
		return
	var sway: ShaderMaterial = source.material
	if sway.shader != SWAY_SHADER:
		return
	var pos: Vector2 = source.global_position
	material.set_shader_parameter("sway_strength", sway.get_shader_parameter("strength"))
	material.set_shader_parameter("sway_speed", sway.get_shader_parameter("speed"))
	material.set_shader_parameter("sway_phase", pos.x * 0.05 + pos.y * 0.03)
	material.set_shader_parameter("sway_pivot", -source.position.y)
