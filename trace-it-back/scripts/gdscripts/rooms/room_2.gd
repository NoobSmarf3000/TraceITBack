extends RoomBase


func _ready() -> void:
	room_id = "ROOM2"
	super()

func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"ROOM2_DINING_TABLE":
			interact_room2_dining_table()

func interact_room2_dining_table() -> void:
	DialogueController.start_dialogue("ROOM2_DINING_TABLE")
	
func return_to_room3() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room3.tscn", "FromRoom2")
	


func _on_room_border_1_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	call_deferred("return_to_room3")
