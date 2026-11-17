extends RoomBase


func _ready() -> void:
	room_id = "ROOFTOP"
	super()
	
func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"ROOFTOP_FENCE":
			interact_fence()

func interact_fence() -> void:
	DialogueController.start_dialogue("ROOFTOP_FENCE")

func leave_to_room1() -> void:
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/room1.tscn",
		"FromRooftop"
	)
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/room1.tscn",
		"FromRooftop"
	)


func _on_room_border_1_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("leave_to_room1")
