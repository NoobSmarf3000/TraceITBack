extends RoomBase


func _ready() -> void:
	room_id = "ROOM1"
	super._ready()
	
func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"ROOM1_PARENT_DOOR":
			interact_room1_parent_door()
		
func interact_room1_parent_door() -> void:
	DialogueController.start_dialogue("ROOM1_PARENT_DOOR")

func leave_to_bedroom() -> void:
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/bedroom.tscn",
		"FromRoom1"
	)


func leave_to_rooftop() -> void:
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/rooftop.tscn",
		"FromRoom1"
	)


func leave_to_room3() -> void:
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/room3.tscn",
		"FromRoom1"
	)
	


func _on_room_border_2_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	call_deferred("leave_to_rooftop")


func _on_exit_room_1_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	call_deferred("leave_to_room3")

func _on_door_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	call_deferred("leave_to_bedroom")
