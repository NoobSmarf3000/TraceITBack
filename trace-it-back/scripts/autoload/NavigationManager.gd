extends Node

const TYRONE_SCENE := preload("res://scenes/player/tyrone.tscn")

var current_spawn_point: String = "Start"
var current_room: RoomBase = null
var player: Tyrone = null
var is_changing_room: bool = false


func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

	call_deferred("_setup_room")


func change_room(scene_path: String, spawn_point: String) -> void:
	if is_changing_room:
		return

	print(
		"NavigationManager: Requested room change -> ",
		scene_path,
		" | Spawn: ",
		spawn_point
	)

	current_spawn_point = spawn_point
	is_changing_room = true

	# Fade to black first.
	TransitionAnimation.transition()

	await TransitionAnimation.on_transition_finished

	call_deferred("_change_room_deferred", scene_path)


func _change_room_deferred(scene_path: String) -> void:
	var result := get_tree().change_scene_to_file(scene_path)

	if result != OK:
		push_error(
			"NavigationManager: Failed to change scene. Error: "
			+ str(result)
		)

		is_changing_room = false


func _on_scene_changed() -> void:
	call_deferred("_setup_room")

func _abort_setup() -> void:
	var was_changing := is_changing_room
	is_changing_room = false
	if was_changing:
		TransitionAnimation.fade_to_normal()

func _setup_room() -> void:
	var scene := get_tree().current_scene

	if scene == null:
		push_error("NavigationManager: Current scene is null.")
		_abort_setup()
		return

	if not scene is RoomBase:
		print("NavigationManager: Scene '", scene.name, "' is not a room. Tyrone will not be spawned.")
		current_room = null
		player = null
		_abort_setup()
		return

	current_room = scene as RoomBase
	print("NavigationManager: New room loaded -> ", current_room.name)

	player = get_tree().get_first_node_in_group("player") as Tyrone

	if player == null:
		print("NavigationManager: Tyrone does not exist. Instantiating.")
		player = TYRONE_SCENE.instantiate() as Tyrone

		if player == null:
			push_error("NavigationManager: Could not instantiate Tyrone.")
			_abort_setup()
			return

		current_room.add_child(player)

	var spawn_points := current_room.get_node_or_null("SpawnPoints")

	if spawn_points == null:
		push_error("NavigationManager: Room '%s' has no SpawnPoints node." % current_room.name)
		_abort_setup()
		return

	print("NavigationManager: Looking for spawn point -> ", current_spawn_point)
	var spawn := spawn_points.get_node_or_null(current_spawn_point) as Node2D

	if spawn == null:
		push_warning("NavigationManager: Spawn '%s' not found in '%s'. Using a fallback." % [current_spawn_point, current_room.name])
		spawn = spawn_points.get_node_or_null("Default") as Node2D
		if spawn == null and spawn_points.get_child_count() > 0:
			spawn = spawn_points.get_child(0) as Node2D

	if spawn == null:
		push_error("NavigationManager: Room '%s' has no usable spawn point." % current_room.name)
		_abort_setup()
		return

	player.global_position = spawn.global_position
	print("NavigationManager: Tyrone spawned at ", player.global_position)

	is_changing_room = false
	TransitionAnimation.fade_to_normal()
