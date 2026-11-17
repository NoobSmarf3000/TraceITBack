extends Control

func _on_start_pressed() -> void:
	SaveManager.new_game()

	SaveManager.current_save.checkpoint = "BEDROOM"

	SaveManager.current_save.current_scene = \
		"res://scenes/rooms/bedroom.tscn"

	NavigationManager.current_spawn_point = "Start"

	SaveManager.save_game()

	NavigationManager.change_room(
		"res://scenes/rooms/bedroom.tscn",
		"Start"
	)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
