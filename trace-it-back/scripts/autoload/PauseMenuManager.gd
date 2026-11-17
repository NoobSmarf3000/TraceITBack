extends Node

const PAUSE_MENU_SCENE := preload("res://scenes/main_menu/pause_menu.tscn")

var pause_menu: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().scene_changed.connect(_on_scene_changed)

	# Do not create the pause menu until we are actually in a room.
	call_deferred("_check_current_scene")


func _check_current_scene() -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	if current_scene is RoomBase:
		show_pause_menu()
	else:
		hide_pause_menu()


func _on_scene_changed() -> void:
	call_deferred("_check_current_scene")


func show_pause_menu() -> void:
	if pause_menu == null:
		pause_menu = PAUSE_MENU_SCENE.instantiate() as CanvasLayer

		if pause_menu == null:
			push_error("PauseMenuManager: Could not instantiate pause_menu.tscn.")
			return

		add_child(pause_menu)

	pause_menu.show()


func hide_pause_menu() -> void:
	if pause_menu != null:
		pause_menu.hide()
