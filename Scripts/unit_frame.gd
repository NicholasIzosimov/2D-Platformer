extends HBoxContainer

const HEAD_FRACTION: float = 0.45
@export var track_player: bool = false
@export var portrait_on_right: bool = false
var combat_state: Node
var combat_handler: Node
var badge_effect: StatusEffect
var unit: Node
var crop_cache: Dictionary = {}
@export var level_colors: LevelColors

func _ready() -> void:
	if portrait_on_right:
		move_child(%PortraitColumn, -1)
		%Portrait.flip_h = true
		%CombatIcon.flip_h = true
		%CombatIcon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE)
		%EffectBadge.flip_h = true
		%EffectBadge.position.x = %Portrait.custom_minimum_size.x - %EffectBadge.position.x
	PlayerState.leveled_up.connect(func(_new_level): update_labels())
	if track_player:
		var player = get_tree().get_first_node_in_group("player")
		if not player.is_node_ready():
			await player.ready
		set_unit(player)
	else:
		set_unit(null)

func set_unit(new_unit: Node) -> void:
	disconnect_unit()
	unit = new_unit
	visible = is_instance_valid(unit)
	if not visible:
		return
	%HealthBar.bind(unit)
	%PowerBar.bind(unit)
	%Portrait.texture = make_portrait(unit)
	unit.get_node("UnitStats").level_changed.connect(update_labels)
	update_labels()
	combat_state = unit.get_node("CombatState")
	combat_handler = unit.get_node("CombatHandler")
	combat_state.combat_changed.connect(_on_combat_changed)
	combat_handler.effect_applied.connect(_on_effect_applied)
	combat_handler.effect_expired.connect(_on_effect_expired)
	badge_effect = null
	for effect in combat_handler.active_effects:
		if effect.frame_badge:
			badge_effect = effect
	update_badges()

func disconnect_unit() -> void:
	if is_instance_valid(unit):
		var old_stats = unit.get_node("UnitStats")
		if old_stats.level_changed.is_connected(update_labels):
			old_stats.level_changed.disconnect(update_labels)
	if is_instance_valid(combat_state) and combat_state.combat_changed.is_connected(_on_combat_changed):
		combat_state.combat_changed.disconnect(_on_combat_changed)
	if is_instance_valid(combat_handler) and combat_handler.effect_applied.is_connected(_on_effect_applied):
		combat_handler.effect_applied.disconnect(_on_effect_applied)
		combat_handler.effect_expired.disconnect(_on_effect_expired)
	combat_state = null
	combat_handler = null

func _on_combat_changed(_in_combat: bool) -> void:
	update_badges()

func _on_effect_applied(effect) -> void:
	if effect.frame_badge and badge_effect != effect:
		badge_effect = effect
		update_badges()

func _on_effect_expired(effect) -> void:
	if effect == badge_effect:
		badge_effect = null
		update_badges()

func update_badges() -> void:
	var in_combat: bool = combat_state.in_combat
	%CombatIcon.visible = in_combat
	var show_badge: bool = badge_effect != null and not in_combat
	%EffectBadge.visible = show_badge
	if show_badge and %EffectBadge.sprite_frames != badge_effect.frame_badge:
		%EffectBadge.sprite_frames = badge_effect.frame_badge
		%EffectBadge.play(badge_effect.frame_badge_animation)

func make_portrait(target_unit: Node) -> Texture2D:
	var data: UnitData = target_unit.get_node("UnitStats").unit_data
	if data.portrait:
		return data.portrait
	var sprite: AnimatedSprite2D = target_unit.get_node("AnimatedSprite2D")
	var anim: String = target_unit.get_node("UnitAnimator").key + "_idle"
	if not sprite.sprite_frames.has_animation(anim):
		return null
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
	var local: Rect2 = auto_crop(frame, data)
	var portrait_texture := AtlasTexture.new()
	if frame is AtlasTexture:
		portrait_texture.atlas = frame.atlas
		portrait_texture.region = Rect2(frame.region.position + local.position, local.size)
	else:
		portrait_texture.atlas = frame
		portrait_texture.region = local
	return portrait_texture

func auto_crop(frame: Texture2D, data: UnitData) -> Rect2:
	var frame_size: Vector2 = frame.get_size()
	if not crop_cache.has(frame):
		var image: Image = frame.get_image()
		crop_cache[frame] = Rect2(image.get_used_rect()) if image else Rect2(Vector2.ZERO, frame_size)
	var used: Rect2 = crop_cache[frame]
	if used.size == Vector2.ZERO:
		used = Rect2(Vector2.ZERO, frame_size)
	var side: float = min(used.size.y * HEAD_FRACTION / data.portrait_zoom, frame_size.x, frame_size.y)
	var center := Vector2(used.get_center().x, used.position.y + side / 2.0)
	center += data.portrait_offset * side
	var top_left: Vector2 = (center - Vector2(side, side) / 2.0).clamp(Vector2.ZERO, frame_size - Vector2(side, side))
	return Rect2(top_left, Vector2(side, side))

func update_labels() -> void:
	if not is_instance_valid(unit):
		return
	var stats = unit.get_node("UnitStats")
	%NameLabel.text = stats.unit_data.name
	%LevelLabel.text = "Lv.%d" % stats.level
	var color: Color = level_colors.own if unit.is_in_group("player") else level_colors.color_for(stats.level - PlayerState.level)
	%LevelLabel.add_theme_color_override("font_color", color)
