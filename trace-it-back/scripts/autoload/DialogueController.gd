extends Node

signal dialogue_started
signal dialogue_finished

const SKIP_HOLD_SECONDS := 2.0
const NARRATIVE_INTROS := [
	"INTRO_FORCESKIP", "INTRO_1", "INTRO_SKIPPED", "GAME_INTRO", "INTRO_RETURN"
]

var active: bool = false
var last_dialogue_skipped := false
var _skip_held := false
var _skip_elapsed := 0.0
var _started_timeline := ""

func ace_play(anim_name: String) -> void:
	var room := get_tree().current_scene
	if room and room.has_method("play_ace"):
		room.play_ace(anim_name)


func start_dialogue(timeline: String) -> bool:
	if active:
		push_warning("DialogueController: '%s' ignored, a dialogue is already active" % timeline)
		return false
	if not DialogicResourceUtil.resource_exists_from_identifier(timeline, "dtl"):
		push_warning("DialogueController: timeline '%s' is not registered in Dialogic" % timeline)
		return false

	print("DialogueController: Starting timeline -> ", timeline)
	last_dialogue_skipped = false
	_started_timeline = timeline
	active = true
	GameManager.lock_gameplay()
	dialogue_started.emit()
	Dialogic.start(timeline)
	return true


func finish_dialogue() -> void:
	if not active:
		return

	active = false
	_started_timeline = ""
	_reset_skip_hold()

	GameManager.unlock_gameplay()

	dialogue_finished.emit()
	
func room_event(event_name: String, arg: String = "") -> void:
	var room := get_tree().current_scene
	if room and room.has_method("on_room_event"):
		room.on_room_event(event_name, arg)
	else:
		push_warning("room_event '%s': %s has no on_room_event()" % [event_name, room])
	
func queue_puzzles() -> void:
	var room := get_tree().current_scene
	if room and room.has_method("queue_puzzles"):
		room.queue_puzzles()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogic.timeline_started.connect(_reset_skip_hold)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	if not Dialogic.signal_event.is_connected(_on_signal):
		Dialogic.signal_event.connect(_on_signal)


func _input(event: InputEvent) -> void:
	if event.is_action_released("skip_dialogue"):
		_reset_skip_hold()
	elif event.is_action_pressed("skip_dialogue") and _can_skip_dialogue():
		_skip_held = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_skip_hold()


func _process(delta: float) -> void:
	if not _skip_held:
		return
	if not _can_skip_dialogue():
		_reset_skip_hold()
		return

	_skip_elapsed += delta
	if _skip_elapsed >= SKIP_HOLD_SECONDS:
		_reset_skip_hold()
		_skip_dialogue()


func _can_skip_dialogue() -> bool:
	if not active or last_dialogue_skipped or get_tree().paused or Dialogic.paused:
		return false
	if Dialogic.current_timeline == null or _started_timeline in NARRATIVE_INTROS:
		return false
	if Dialogic.current_timeline.get_identifier() in NARRATIVE_INTROS:
		return false
	var save := SaveManager.current_save
	return save != null and save.intro_quiz_done


func _reset_skip_hold() -> void:
	_skip_held = false
	_skip_elapsed = 0.0


func _skip_dialogue() -> void:
	last_dialogue_skipped = true
	stop_dialogue_playback()
	Dialogic.end_timeline(true)


func stop_dialogue_playback() -> void:
	if Dialogic.current_timeline == null:
		return
	if Dialogic.current_event_idx >= 0:
		var event = Dialogic.current_timeline.get_event(Dialogic.current_event_idx)
		if event is DialogicWaitEvent and is_instance_valid(event._tween):
			event._tween.kill()
	for text_node in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		if text_node is DialogicNode_DialogText:
			text_node.revealing = false
			text_node.visible_characters = -1
	Dialogic.Inputs.stop_timers()
	Dialogic.Choices.hide_all_choices()


func _on_timeline_ended() -> void:
	finish_dialogue()


func _on_signal(argument) -> void:
	var room := get_tree().current_scene
	if room and room.has_method("handle_dialogue_signal"):
		room.handle_dialogue_signal(argument)
