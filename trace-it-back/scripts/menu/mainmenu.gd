extends Control

@onready var new_game_button: Button = $VBoxContainer/NewGame
@onready var load_game_button: Button = $VBoxContainer/LoadGame
@onready var settings_button: Button = $VBoxContainer/Settings
@onready var exit_game_button: Button = $VBoxContainer/ExitGame

func _ready() -> void:
	AudioManager.stop_music(0.4)
	GameManager.reset_runtime_state()

	new_game_button.focus_neighbor_bottom = load_game_button.get_path()
	load_game_button.focus_neighbor_top = new_game_button.get_path()
	load_game_button.focus_neighbor_bottom = settings_button.get_path()
	settings_button.focus_neighbor_top = load_game_button.get_path()
	settings_button.focus_neighbor_bottom = exit_game_button.get_path()
	exit_game_button.focus_neighbor_top = settings_button.get_path()
	
	if has_node("/root/PauseMenuLayer"):
		var pause_layer = get_node("/root/PauseMenuLayer")

		if pause_layer.has_method("hide_pause_menu"):
			pause_layer.hide_pause_menu()


func _on_new_game_pressed() -> void:
	for slot in range(1, SaveManager.MAX_SLOTS + 1):
		if not SaveManager.slot_has_data(slot):
			SaveManager.set_slot(slot)
			get_tree().change_scene_to_file("res://scenes/main_menu/new_game.tscn")
			return
	get_tree().change_scene_to_file("res://scenes/main_menu/load_game.tscn")
	
func _on_load_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/load_game.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/settings.tscn")

func _on_exit_game_pressed() -> void:
	get_tree().quit()
