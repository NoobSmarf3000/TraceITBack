extends CharacterBody2D

class_name Tyrone

const SPEED = 300.0
const ROOM_WIDTH = 640
const ROOM_HEIGHT = 480

@onready var animated_sprite = $TyroneAnimations
@onready var interaction_box: Area2D = $InteractionBox

var last_direction = Vector2.DOWN

@onready var camera: Camera2D = $Camera2D
var room_bounds := Rect2()

func _ready() -> void:
	add_to_group("player")

	interaction_box.monitoring = true
	interaction_box.monitorable = true
	interaction_box.collision_layer = 0
	interaction_box.collision_mask = 2
	
	_setup_camera()


func _physics_process(_delta):
	if GameManager.is_gameplay_locked:
		velocity = Vector2.ZERO
		_play_idle()
		AudioManager.stop_loop("walk")
		_update_camera()
		return

	if Input.is_action_just_pressed("interact"):
		interact_with_object()

	var input_direction = Input.get_vector(
		"walk_left",
		"walk_right",
		"walk_up",
		"walk_down"
	).normalized()

	velocity = input_direction * SPEED

	if input_direction != Vector2.ZERO:
		last_direction = input_direction

		if abs(last_direction.x) > abs(last_direction.y):
			animated_sprite.play("walk_right")
			animated_sprite.flip_h = last_direction.x < 0
		else:
			animated_sprite.flip_h = false

			if last_direction.y < 0:
				animated_sprite.play("walk_up")
			else:
				animated_sprite.play("walk_down")

	else:
		if abs(last_direction.x) > abs(last_direction.y):
			animated_sprite.play("idle_right")
			animated_sprite.flip_h = last_direction.x < 0
		else:
			animated_sprite.flip_h = false

			if last_direction.y < 0:
				animated_sprite.play("idle_up")
			else:
				animated_sprite.play("idle")

	move_and_slide()

	if get_real_velocity().length() > 20.0:
		AudioManager.start_loop("walk")
	else:
		AudioManager.stop_loop("walk")

	_update_camera()

func _play_idle() -> void:
	if abs(last_direction.x) > abs(last_direction.y):
		animated_sprite.play("idle_right")
		animated_sprite.flip_h = last_direction.x < 0
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("idle_up" if last_direction.y < 0 else "idle")

func interact_with_object() -> void:
	var objects := interaction_box.get_overlapping_areas()

	for object in objects:
		if object is InteractionObject:
			object.interact()
		return

func _exit_tree() -> void:
	AudioManager.stop_loop("walk")


func _setup_camera() -> void:
	var room := get_parent() as RoomBase
	if room:
		room_bounds = room.get_room_bounds()

	camera.top_level = true
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_update_camera()


func _update_camera() -> void:
	if room_bounds.size == Vector2.ZERO:
		camera.global_position = global_position
		return

	var view := get_viewport_rect().size / camera.zoom
	camera.global_position = Vector2(
		_camera_axis(global_position.x, room_bounds.position.x, room_bounds.end.x, view.x),
		_camera_axis(global_position.y, room_bounds.position.y, room_bounds.end.y, view.y)
	)

func _enter_tree() -> void:
	var player := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player == null:
		return
	for anim_name in player.get_animation_list():
		var anim := player.get_animation(anim_name)
		for i in anim.get_track_count():
			if anim.track_get_type(i) == Animation.TYPE_VALUE \
					and str(anim.track_get_path(i)).ends_with(":animation"):
				anim.value_track_set_update_mode(i, Animation.UPDATE_DISCRETE)

func _camera_axis(target: float, room_min: float, room_max: float, view: float) -> float:
	if room_max - room_min <= view:
		return (room_min + room_max) * 0.5    
	return clampf(target, room_min + view * 0.5, room_max - view * 0.5)
