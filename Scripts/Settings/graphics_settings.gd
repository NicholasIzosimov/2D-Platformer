extends Node

signal changed

const PATH: String = "user://settings.cfg"
const SECTION: String = "graphics"
const SHADOW_SAMPLES: Array[int] = [0, 1, 2, 4, 8]
const SHADOW_LABELS: Array[String] = ["Off", "Hard", "Soft (low)", "Soft", "Soft (high)"]

var shadow_quality: int = 3
var vsync: bool = true

func _ready() -> void:
	load_settings()
	apply_vsync()

func set_shadow_quality(value: int) -> void:
	shadow_quality = clampi(value, 0, SHADOW_SAMPLES.size() - 1)
	save_settings()
	changed.emit()

func set_vsync(value: bool) -> void:
	vsync = value
	apply_vsync()
	save_settings()
	changed.emit()

func apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)

func shadow_samples() -> int:
	return SHADOW_SAMPLES[shadow_quality]

func shadow_label() -> String:
	return SHADOW_LABELS[shadow_quality]

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	shadow_quality = clampi(config.get_value(SECTION, "shadow_quality", shadow_quality), 0, SHADOW_SAMPLES.size() - 1)
	vsync = config.get_value(SECTION, "vsync", vsync)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	config.set_value(SECTION, "shadow_quality", shadow_quality)
	config.set_value(SECTION, "vsync", vsync)
	config.save(PATH)
