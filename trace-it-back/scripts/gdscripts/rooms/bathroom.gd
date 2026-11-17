extends RoomBase


func _ready() -> void:
	room_id = "BATHROOM"
	super()
	
func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"BATHROOM_SHOWERTUB":
			interact_bathroom_showertub()
		"BATHROOM_SINK":
			interact_bathroom_sink()
		"TOILET":
			interact_toilet()
			
func interact_bathroom_showertub()-> void:
	DialogueController.start_dialogue("BATHROOM_SHOWERTUB")

func interact_bathroom_sink()-> void:
	DialogueController.start_dialogue("BATHROOM_SINK")

func interact_toilet()-> void:
	DialogueController.start_dialogue("TOILET")


func return_to_room4()-> void:
	save_room()
	NavigationManager.change_room(
		"res://scenes/rooms/room4.tscn",
		 "FromBathroom"
		)


func _on_room_border_2_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("return_to_room4")
	
