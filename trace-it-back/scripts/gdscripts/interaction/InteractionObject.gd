extends Area2D
class_name InteractionObject

@export var interaction_name: String = ""


func _ready() -> void:
	add_to_group("interactable")

	monitoring = false
	monitorable = true
	collision_layer = 2
	collision_mask = 0


func interact() -> void:
	var room := get_tree().current_scene

	if room == null:
		return

	SaveManager.record_interaction(interaction_name)

	if room.has_method("handle_interaction"):
		room.handle_interaction(interaction_name)
