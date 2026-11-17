extends Control

var slot_buttons: Array[Button] = []

@onready var save_1: Button = $VBoxContainer/Slot1/Save1
@onready var save_2: Button = $VBoxContainer/Slot2/Save2
@onready var save_3: Button = $VBoxContainer/Slot3/Save3
@onready var delete_1: Button = $VBoxContainer/Slot1/Delete1
@onready var delete_2: Button = $VBoxContainer/Slot2/Delete2
@onready var delete_3: Button = $VBoxContainer/Slot3/Delete3


func _ready() -> void:
	slot_buttons.assign([save_1, save_2, save_3])
	update_slot_display()

	if not delete_1.pressed.is_connected(_on_delete_1_pressed):
		delete_1.pressed.connect(_on_delete_1_pressed)

	if not delete_2.pressed.is_connected(_on_delete_2_pressed):
		delete_2.pressed.connect(_on_delete_2_pressed)

	if not delete_3.pressed.is_connected(_on_delete_3_pressed):
		delete_3.pressed.connect(_on_delete_3_pressed)


func update_slot_display() -> void:
	for i in range(SaveManager.MAX_SLOTS):
		var slot_num := i + 1

		if i >= slot_buttons.size():
			push_warning(
				"LoadMenu: Not enough slot buttons assigned."
			)
			continue

		var button := slot_buttons[i]

		var save := SaveManager.get_save_preview(slot_num)

		if save == null:
			button.text = "SLOT %d\nEMPTY" % slot_num
		else:
			button.text = get_slot_text(slot_num, save)

	delete_1.disabled = not SaveManager.slot_has_data(1)
	delete_2.disabled = not SaveManager.slot_has_data(2)
	delete_3.disabled = not SaveManager.slot_has_data(3)


func get_slot_text(slot_num: int, save: SaveStateResource) -> String:
	var room_name := save.checkpoint
	if room_name.is_empty():
		room_name = "Unknown"

	return "SLOT %d\n%s\nPUZZLE %d/6  |  %s" % [
		slot_num, room_name, mini(save.last_puzzle, 6), format_playtime(save.playtime_seconds)
	]



func format_playtime(total_seconds: float) -> String:
	var seconds := int(total_seconds)
	var hours := floori(seconds / 3600.0)
	var minutes := floori((seconds % 3600) / 60.0)
	return "%02d:%02d:%02d" % [hours, minutes, seconds % 60]


func handle_slot_selection(slot: int) -> void:
	if not SaveManager.slot_has_data(slot):
		SaveManager.set_slot(slot)
		SaveManager.new_game()

		print("Starting new game in slot ", slot)

		get_tree().change_scene_to_file(
			"res://scenes/main_menu/new_game.tscn"
		)

		return

	SaveManager.set_slot(slot)
	SaveManager.load_game()


func _on_save_1_pressed() -> void:
	handle_slot_selection(1)

func _on_save_2_pressed() -> void:
	handle_slot_selection(2)


func _on_save_3_pressed() -> void:
	handle_slot_selection(3)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_delete_1_pressed() -> void:
	delete_slot(1)


func _on_delete_2_pressed() -> void:
	delete_slot(2)


func _on_delete_3_pressed() -> void:
	delete_slot(3)
	
func delete_slot(slot: int) -> void:
	if not SaveManager.slot_has_data(slot):
		return

	SaveManager.delete_save(slot)
	update_slot_display()
