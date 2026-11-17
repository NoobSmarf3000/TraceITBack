extends Area2D
class_name RoomBase

@export var room_id: String = ""


func _ready() -> void:
	enter_room()


func enter_room() -> void:
	print("Entered room: ", room_id)


func exit_room() -> void:
	print("Exited room: ", room_id)


func save_room() -> void:
	if SaveManager.current_save == null:
		SaveManager.new_game()

	SaveManager.current_save.checkpoint = room_id
	SaveManager.save_game()

func get_room_bounds() -> Rect2:
	var best := Rect2()
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var rect: Rect2 = sprite.get_global_transform() * sprite.get_rect()
		if rect.get_area() > best.get_area():
			best = rect
	return best
