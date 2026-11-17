extends RoomBase

func _ready() -> void:
	room_id = "ROOM4"
	super()

func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"ROOM4_FRONT_DOOR":
			interact_room4_front_door()
		"ROOM4_TV":
			interact_room4_tv()
		"ROOM4_COUCH":
			interact_room4_couch()

func interact_room4_front_door() -> void:
	DialogueController.start_dialogue("ROOM4_FRONT_DOOR")

func interact_room4_tv() -> void:
	DialogueController.start_dialogue("ROOM4_TV")
	
func interact_room4_couch() -> void:
	DialogueController.start_dialogue("ROOM4_COUCH")
	
func to_bathroom() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/bathroom.tscn", "FromRoom4")

func return_to_room3() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room3.tscn", "FromRoom4")


func to_computerroom()-> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/computerroom.tscn", "FromRoom4")


func _on_exit_room_4_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("return_to_room3")


func _on_room_border_1_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("to_bathroom")


func _on_room_border_2_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("to_computerroom")
