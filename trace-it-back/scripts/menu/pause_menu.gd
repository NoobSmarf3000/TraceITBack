extends Control

@onready var dim: ColorRect = %Dim
@onready var top_bar: Control = %TopBar

@onready var resume_button: Button = %Resume
@onready var stats_button: Button = %Stats
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit

@onready var stat_bar: Control = %StatBar
@onready var stat_back_button: Button = %StatBack
@onready var settings_panel: Control = %SettingsPanel
@onready var quit_panel: Control = %QuitPanel

@onready var main_menu_quit: Button = %MainMenuQuit
@onready var game_quit: Button = %GameQuit
@onready var back_button: Button = %QuitBack


var is_open: bool = false
var is_quit_menu_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide_pause_menu()

	if not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)

	if not stats_button.pressed.is_connected(_on_stats_pressed):
		stats_button.pressed.connect(_on_stats_pressed)

	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)

	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

	if not stat_back_button.pressed.is_connected(_on_stat_back_pressed):
		stat_back_button.pressed.connect(_on_stat_back_pressed)

	if not main_menu_quit.pressed.is_connected(_on_main_menu_quit_pressed):
		main_menu_quit.pressed.connect(_on_main_menu_quit_pressed)

	if not game_quit.pressed.is_connected(_on_game_quit_pressed):
		game_quit.pressed.connect(_on_game_quit_pressed)

	if not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)

	if not settings_panel.back_pressed.is_connected(_on_settings_back_pressed):
		settings_panel.back_pressed.connect(_on_settings_back_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	if not current_scene is RoomBase:
		return

	if is_open:
		close_pause_menu()
	else:
		open_pause_menu()


func open_pause_menu() -> void:
	is_open = true
	is_quit_menu_open = false

	dim.show()
	top_bar.show()
	stat_bar.hide()
	settings_panel.hide()
	quit_panel.hide()

	get_tree().paused = true

	resume_button.grab_focus()


func close_pause_menu() -> void:
	hide_pause_menu()
	get_tree().paused = false


func hide_pause_menu() -> void:
	dim.hide()
	top_bar.hide()
	stat_bar.hide()
	settings_panel.hide()
	quit_panel.hide()

	is_open = false
	is_quit_menu_open = false


func _on_resume_pressed() -> void:
	close_pause_menu()


func _on_stats_pressed() -> void:
	top_bar.hide()
	settings_panel.hide()
	quit_panel.hide()

	stat_bar.show()
	stat_back_button.grab_focus()


func _on_stat_back_pressed() -> void:
	stat_bar.hide()
	top_bar.show()
	stats_button.grab_focus()


func _on_settings_pressed() -> void:
	top_bar.hide()
	stat_bar.hide()
	quit_panel.hide()

	settings_panel.show()
	settings_panel.focus_first_control()


func _on_settings_back_pressed() -> void:
	settings_panel.hide()
	top_bar.show()
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	top_bar.hide()
	stat_bar.hide()
	settings_panel.hide()

	quit_panel.show()
	is_quit_menu_open = true

	main_menu_quit.grab_focus()


func _on_back_pressed() -> void:
	quit_panel.hide()
	is_quit_menu_open = false

	top_bar.show()
	quit_button.grab_focus()


func _on_main_menu_quit_pressed() -> void:
	SaveManager.save_game()
	AudioManager.stop_music(0.4)

	get_tree().paused = false
	hide_pause_menu()

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_game_quit_pressed() -> void:
	SaveManager.save_game()

	get_tree().paused = false
	get_tree().quit()
