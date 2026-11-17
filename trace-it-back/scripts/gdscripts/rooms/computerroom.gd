extends RoomBase

const PATCH_LEVEL := 5

const MILD_GLITCH_AFTER_PUZZLE := {1: 5, 2: 4, 3: 3}
const HEAVY_GLITCH_AFTER_PUZZLE := {2: 6, 3: 4}
const LAST_PUZZLE := PuzzleEvaluatorResource.LAST_NORMAL_PUZZLE
const FINAL_PUZZLE := PuzzleEvaluatorResource.FINAL_PUZZLE
const PUZZLE_SCENES := {
	1: preload("res://scenes/puzzles/puzzle_1.tscn"),
	2: preload("res://scenes/puzzles/puzzle_2.tscn"),
	3: preload("res://scenes/puzzles/puzzle_3.tscn"),
	4: preload("res://scenes/puzzles/puzzle_4.tscn"),
	5: preload("res://scenes/puzzles/puzzle_5.tscn"),
	6: preload("res://scenes/puzzles/puzzle_6.tscn"),
	7: preload("res://scenes/puzzles/puzzle_7.tscn"),
}

const RESULT_DELAY := 2.0
const FAIL_DELAY := 0.8
const BAD_ENDING_CORRUPTION := 2   
const CREDITS_SCENE := "res://scenes/credits.tscn"

enum PuzzleContinuation { STOP, SHOW_INTRO, SKIP_INTRO }

@onready var ace: ACE = $ACE

var intro_queued := false
var sequence_running := false


func _ready() -> void:
	room_id = "COMPUTER_ROOM"
	super()
	DialogueController.dialogue_finished.connect(_on_dialogue_finished)
	ace.play_anim(_rest_anim() if _computer_on() else "off")


func _save() -> SaveStateResource:
	return SaveManager.get_current_save()


func _computer_on() -> bool:
	return _save().computer_on or _last_puzzle_done() >= FINAL_PUZZLE


func _last_puzzle_done() -> int:
	return _save().last_puzzle


func _rest_anim() -> String:
	if _last_puzzle_done() >= FINAL_PUZZLE:
		return "off"
	match _save().ace_glitch:
		1:
			return "glitch_1"
		2:
			return "glitch_2"
	return "idle"



func _first_registered(names: Array) -> String:
	for n in names:
		if DialogicResourceUtil.resource_exists_from_identifier(n, "dtl"):
			return n
	return ""


func handle_interaction(interaction_id: String) -> void:
	match interaction_id:
		"COMPUTERROOM_BOOKSHELF":
			DialogueController.start_dialogue("COMPUTERROOM_BOOKSHELF")
		"COMPUTERROOM_ACE":
			interact_ace()


func interact_ace() -> void:
	if _last_puzzle_done() >= FINAL_PUZZLE or not _computer_on():
		DialogueController.start_dialogue("COMPUTERROOM_ACE")
		return
	var next := _last_puzzle_done() + 1
	if next <= FINAL_PUZZLE:
		run_sequence(next, false)   




func play_ace(anim_name: String) -> void:
	ace.play_anim(anim_name)


func on_room_event(event_name: String, arg: String = "") -> void:
	print("[ComputerRoom] room_event: ", event_name, " ", arg)
	match event_name:
		"intro_accepted":
			intro_queued = true
		"glitch":
			_set_glitch(2 if arg == "glitch_2" else 1)
		"glitch_mild":
			_set_glitch(1)
		"glitch_heavy":
			_set_glitch(2)
		_:
			push_warning("Unknown room_event: " + event_name)


func _set_glitch(level: int) -> void:
	var previous := _save().ace_glitch
	_save().ace_glitch = maxi(previous, level)
	if _save().ace_glitch > previous:
		SaveManager.save_game()
	ace.play_anim(_rest_anim())


func _on_dialogue_finished() -> void:
	if intro_queued:
		intro_queued = false
		run_sequence(1, true)



func run_sequence(first_puzzle: int, play_intro: bool) -> void:
	if sequence_running:
		return
	sequence_running = true
	GameManager.lock_gameplay()

	if play_intro:
		ace.play_anim("idle")
		await _play_timeline("ACE_AND_TYRONE1")
		_save().computer_on = true
		SaveManager.save_game()

	if first_puzzle == 1 and not _save().intro_quiz_done:
		await _run_intro_quiz()

	var id := first_puzzle
	var continuation := PuzzleContinuation.SHOW_INTRO
	while id <= LAST_PUZZLE:
		if continuation == PuzzleContinuation.SHOW_INTRO:
			await _play_timeline("ACE_AND_TYRONE_PRE%d" % id)
		var ev: PuzzleEvaluatorResource = await _run_puzzle(id)
		continuation = await _post_puzzle_cutscene(ev)
		if continuation == PuzzleContinuation.STOP:
			break
		id += 1

	var chapter_finished := false
	if continuation == PuzzleContinuation.STOP:
		ace.play_anim(_rest_anim())
	else:
		chapter_finished = await _run_final()

	AudioManager.stop_music(1.5)
	GameManager.unlock_gameplay()
	sequence_running = false
	if chapter_finished:
		ace.play_anim(_rest_anim())
		_open_credits.call_deferred()


func _open_credits() -> void:
	var error := get_tree().change_scene_to_file(CREDITS_SCENE)
	if error != OK:
		push_error("[ComputerRoom] Could not open %s: %s" % [CREDITS_SCENE, error_string(error)])

func _run_intro_quiz() -> void:
	var quiz := IntroQuiz.new()
	add_child(quiz)
	var mistakes: int = await quiz.finished
	_save().intro_quiz_done = true
	_save().intro_quiz_mistakes = mistakes
	SaveManager.save_game()


func _fade_out() -> void:
	TransitionAnimation.transition()
	await TransitionAnimation.on_transition_finished


func _fade_in() -> void:
	TransitionAnimation.fade_to_normal()
	await TransitionAnimation.on_fade_in_finished


func _run_puzzle(id: int) -> PuzzleEvaluatorResource:
	print("[ComputerRoom] opening puzzle ", id)
	AudioManager.play_music("puzzle")
	await _fade_out()
	ace.play_anim(_rest_anim())

	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	layer.add_child(PUZZLE_SCENES[id].instantiate())
	await _fade_in()

	var args: Array = []
	while true:
		args = await GameManager.puzzle_completed
		if args[0] == id:
			break

	var ev := PuzzleEvaluatorResource.from_result(id, args[1], args[2], args[3], args[4])
	print("[ComputerRoom] puzzle %d done, mistakes: %d, lives lost: %d, failed: %s" % [id, ev.mistakes, ev.lives_lost, ev.failed()])

	await get_tree().create_timer(FAIL_DELAY if ev.failed() else RESULT_DELAY).timeout
	await _fade_out()
	AudioManager.stop_music(0.3)
	layer.queue_free()
	SaveManager.record_puzzle(id, ev.completion_time, ev.mistakes, ev.failed(), ev.lives_lost)
	await _fade_in()
	return ev


func _post_puzzle_cutscene(ev: PuzzleEvaluatorResource) -> PuzzleContinuation:
	var mistake_clear := not ev.failed() and ev.mistakes > 0
	if not mistake_clear:
		_apply_auto_glitch(ev.puzzle_id)
	Dialogic.VAR.set_variable("chapter_one.continue_puzzle.Later", "")

	var timeline := _first_registered(ev.outcome_timelines())
	var skipped := false
	if timeline == "":
		push_warning("[ComputerRoom] no outcome timeline found after puzzle %d" % ev.puzzle_id)
	else:
		skipped = await _play_timeline(timeline)

	if mistake_clear:
		_apply_auto_glitch(ev.puzzle_id)
	ace.play_anim(_rest_anim())

	if skipped:
		return PuzzleContinuation.SKIP_INTRO
	if ev.puzzle_id < LAST_PUZZLE and str(Dialogic.VAR.get_variable("chapter_one.continue_puzzle.Later")) == "Later":
		return PuzzleContinuation.STOP
	return PuzzleContinuation.SHOW_INTRO

func _apply_auto_glitch(puzzle_id: int) -> void:
	var s := _save()
	var tier := s.ace_corruption
	# A life lost before a clean clear still counts toward the first visual glitch.
	if tier == 0 and s.puzzle_lives_lost.values().any(func(count): return count > 0):
		tier = 1

	if tier >= 4 or puzzle_id >= int(HEAVY_GLITCH_AFTER_PUZZLE.get(tier, FINAL_PUZZLE)):
		_set_glitch(2)
	elif puzzle_id >= LAST_PUZZLE or puzzle_id >= int(MILD_GLITCH_AFTER_PUZZLE.get(tier, FINAL_PUZZLE)):
		_set_glitch(1)

func _run_final() -> bool:
	var s := _save()
	var ending := "BAD" if s.ace_corruption >= BAD_ENDING_CORRUPTION else "GOOD"
	s.ending = ending
	Dialogic.VAR.set_variable("chapter_one.chap_one_ending", ending)
	Dialogic.VAR.set_variable("chapter_one.chap_one_timeout_ending", ending)
	print("[ComputerRoom] final puzzle, ending: ", ending)
	AudioManager.play_music("final")
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var puzzle: Node = PUZZLE_SCENES[FINAL_PUZZLE].instantiate()
	puzzle.set("mode", ending)
	layer.add_child(puzzle)

	var result: Dictionary = await puzzle.closed
	if result.is_empty():
		layer.queue_free()
		return false

	SaveManager.clear_puzzle_progress(FINAL_PUZZLE)
	var success: bool = result["success"]
	s.final_timed_out = not success
	if success:
		await get_tree().create_timer(1.5).timeout
	layer.queue_free()   

	s.last_puzzle = FINAL_PUZZLE
	s.computer_on = true
	s.last_event_type = "ENDING"
	s.puzzle_times[FINAL_PUZZLE] = result["time"]
	s.puzzle_errors[FINAL_PUZZLE] = result["mistakes"]
	SaveManager.save_game()

	
	var anim_name := "crash" if success else "crash_2"
	ace.play_anim(anim_name)
	await _play_timeline("ENDING_CH1" if success else "TIMEOUT_ENDING_CH1", "")
	print("[ComputerRoom] chapter 1 finished | success: ", success)
	return true


func _play_timeline(timeline: String, music: String = "ace") -> bool:
	if not DialogicResourceUtil.resource_exists_from_identifier(timeline, "dtl"):
		push_warning("[ComputerRoom] timeline not registered in Dialogic: " + timeline)
		return false
	print("[ComputerRoom] playing timeline ", timeline)
	if music != "":
		AudioManager.play_music(music)
	await get_tree().process_frame
	if not DialogueController.start_dialogue(timeline):
		return false
	await DialogueController.dialogue_finished
	return DialogueController.last_dialogue_skipped

func return_to_room4() -> void:
	save_room()
	NavigationManager.change_room("res://scenes/rooms/room4.tscn", "FromComputerRoom")


func _on_room_border_1_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	call_deferred("return_to_room4")
