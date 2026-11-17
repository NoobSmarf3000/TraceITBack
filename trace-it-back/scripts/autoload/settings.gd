extends Control

@onready var settings_panel: Control = $SettingsPanel

func _ready() -> void:
	settings_panel.back_pressed.connect(_on_settings_panel_back_pressed)

func _on_settings_panel_back_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/main_menu/main_menu.tscn"
	)
