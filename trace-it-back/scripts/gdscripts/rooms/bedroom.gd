extends RoomBase


func _ready() -> void:
	room_id = "BEDROOM"
	super._ready()

func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"BEDROOM_BED":
			interact_bed()

		"BEDROOM_DRAWER":
			interact_drawer()

		"BEDROOM_SHELF":
			interact_shelf()


func interact_bed() -> void:
	DialogueController.start_dialogue("BEDROOM_BED")


func interact_drawer() -> void:
	DialogueController.start_dialogue("BEDROOM_DRAWER")


func interact_shelf() -> void:
	DialogueController.start_dialogue("BEDROOM_SHELF")


func leave_to_room1() -> void:
	save_room()

	NavigationManager.change_room(
		"res://scenes/rooms/room1.tscn",
		"FromBedroom"
	)


func _on_doormat_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("leave_to_room1")
