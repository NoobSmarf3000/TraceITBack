extends Control

signal back_pressed

@onready var master_slider: HSlider = %Master
@onready var music_slider: HSlider = %Music
@onready var sfx_slider: HSlider = %SFX
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var back_button: Button = %Back


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for slider in [master_slider, music_slider, sfx_slider]:
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01

	_refresh()

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	back_button.pressed.connect(_on_back_pressed)
	visibility_changed.connect(_on_visibility_changed)


func focus_first_control() -> void:
	master_slider.grab_focus()

func _refresh() -> void:
	master_slider.set_value_no_signal(SettingsManager.get_master_volume())
	music_slider.set_value_no_signal(SettingsManager.get_music_volume())
	sfx_slider.set_value_no_signal(SettingsManager.get_sfx_volume())
	_update_labels()


func _update_labels() -> void:
	master_value.text = "%d%%" % roundi(master_slider.value * 100.0)
	music_value.text = "%d%%" % roundi(music_slider.value * 100.0)
	sfx_value.text = "%d%%" % roundi(sfx_slider.value * 100.0)


func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_update_labels()


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	_update_labels()


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	_update_labels()


func _on_sfx_drag_ended(changed: bool) -> void:
	if changed:
		AudioManager.play_sfx("click")
		SettingsManager.save_settings()


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
	else:
		SettingsManager.save_settings()


func _on_back_pressed() -> void:
	SettingsManager.save_settings()
	back_pressed.emit()
