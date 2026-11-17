extends RoomBase


func _ready() -> void:
	room_id = "ROOM3"
	super()
	
func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"ROOM3_KITCHEN1":
			interact_room3_kitchen1()
		"ROOM3_COOKINGRANGE":
			interact_room3_cookingrange()
		"ROOM3_FRIDGE":
			interact_room3_fridge()


func interact_room3_kitchen1() -> void:
	DialogueController.start_dialogue("ROOM3_KITCHEN1")

func interact_room3_cookingrange() -> void:
	DialogueController.start_dialogue("ROOM3_COOKINGRANGE")

func interact_room3_fridge() -> void:
	DialogueController.start_dialogue("ROOM3_FRIDGE")

func to_room2() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room2.tscn", "FromRoom3")

func to_room4() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room4.tscn", "FromRoom3")

func return_to_room1() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room1.tscn", "FromRoom3")


func _on_room_border_2_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("to_room2")


func _on_door_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("to_room4")

func _on_exit_room_3_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("return_to_room1")
