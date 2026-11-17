extends Node

const SAVE_PATH := "user://settings.tres"

const VOLUME_CURVE := 2.0

var settings := SettingsResource.new()


func _ready() -> void:
	_load_settings()
	apply_all()


func apply_all() -> void:
	_apply_bus("Master", settings.master_volume)
	_apply_bus("Music", settings.music_volume)
	_apply_bus("SFX", settings.sfx_volume)


func set_master_volume(value: float) -> void:
	settings.master_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Master", settings.master_volume)


func get_master_volume() -> float:
	return settings.master_volume


func set_music_volume(value: float) -> void:
	settings.music_volume = clampf(value, 0.0, 1.0)
	_apply_bus("Music", settings.music_volume)


func get_music_volume() -> float:
	return settings.music_volume


func set_sfx_volume(value: float) -> void:
	settings.sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus("SFX", settings.sfx_volume)


func get_sfx_volume() -> float:
	return settings.sfx_volume


func save_settings() -> void:
	var error := ResourceSaver.save(settings, SAVE_PATH)
	if error != OK:
		push_warning("SettingsManager: could not save settings (error %d)" % error)


func _load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var loaded := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SettingsResource
	if loaded != null:
		settings = loaded


func _apply_bus(bus_name: String, value: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	AudioServer.set_bus_mute(bus, value <= 0.001)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(pow(value, VOLUME_CURVE), 0.0001)))
