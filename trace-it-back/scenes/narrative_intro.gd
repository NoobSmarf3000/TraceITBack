extends CanvasLayer

const FIRST_TIMELINE := "GAME_INTRO"   
const NEXT_SCENE := "res://scenes/main_menu/main_menu.tscn"

var _skip_count := 0
var _switching_intro := false


func _ready() -> void:
	layer = 0   

	SaveManager.push_story_variables(SaveManager.get_latest_save())

	_set_intro_var("intro.intro_skipped", "")
	_set_intro_var("intro.intro_skip_count", 0)

	Dialogic.Inputs.dialogic_action_priority.connect(_on_player_input)
	Dialogic.Inputs.auto_skip.toggled.connect(_on_autoskip_toggled)

	await get_tree().process_frame
	if DialogueController.start_dialogue(FIRST_TIMELINE):
		await DialogueController.dialogue_finished

	get_tree().change_scene_to_file(NEXT_SCENE)


func _exit_tree() -> void:
	if Dialogic.Inputs.dialogic_action_priority.is_connected(_on_player_input):
		Dialogic.Inputs.dialogic_action_priority.disconnect(_on_player_input)
	if Dialogic.Inputs.auto_skip.toggled.is_connected(_on_autoskip_toggled):
		Dialogic.Inputs.auto_skip.toggled.disconnect(_on_autoskip_toggled)


func _on_player_input() -> void:
	if not _can_count_skip() or Dialogic.Inputs.action_was_consumed \
			or not Dialogic.Text.is_text_reveal_skippable():
		return
	for text_node in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		if text_node is DialogicNode_DialogText and text_node.revealing:
			if _count_skip():
				Dialogic.Inputs.action_was_consumed = true
			return


func _on_autoskip_toggled(enabled: bool) -> void:
	if enabled and _can_count_skip():
		_count_skip()


func _can_count_skip() -> bool:
	if _switching_intro or Dialogic.current_timeline == null:
		return false
	return Dialogic.current_timeline.get_identifier() in ["INTRO_1", "INTRO_SKIPPED"]


func _count_skip() -> bool:
	_skip_count += 1
	_set_intro_var("intro.intro_skipped", "1")
	_set_intro_var("intro.intro_skip_count", _skip_count)

	match _skip_count:
		1:
			_switching_intro = true
			_switch_intro.call_deferred("INTRO_SKIPPED")
		3:
			_switching_intro = true
			_switch_intro.call_deferred("INTRO_FORCESKIP")
		_:
			return false
	return true


func _switch_intro(timeline: String) -> void:
	Dialogic.Inputs.auto_skip.enabled = false
	DialogueController.stop_dialogue_playback()
	await Dialogic.clear(Dialogic.ClearFlags.TIMELINE_INFO_ONLY)
	Dialogic.start_timeline(timeline)
	_switching_intro = false


func _set_intro_var(path: String, value) -> void:
	if Dialogic.VAR.has(path):
		Dialogic.VAR.set_variable(path, value)
