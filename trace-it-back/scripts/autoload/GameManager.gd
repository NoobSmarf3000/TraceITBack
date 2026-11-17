extends Node

signal gameplay_locked
signal gameplay_unlocked
signal chapter_changed(chapter: int)
signal story_progress_changed(progress: int)
signal puzzle_completed(id: int, time: float, mistakes: int, lives_lost: int, failed: bool)
@warning_ignore("unused_signal")
signal final_puzzle_finished(success: bool, time: float, mistakes: int)

var current_chapter := 1
var story_progress := 0
var _lock_count := 0
var is_gameplay_locked: bool:
	get: return _lock_count > 0

func is_timer_paused() -> bool:
	return DialogueController.active or TransitionAnimation.busy


func _ready() -> void:
	# BAD route = all three lives lost on a single puzzle.
	puzzle_completed.connect(func(_id, _time, _mistakes, _lives_lost, failed):
		if SaveManager.current_save and failed:
			SaveManager.current_save.route = "Bad"
	)

	# F2 = audit log screen, F10 = developer overlay (see dev_tools.gd)
	add_child(DevTools.new())

	# Log fragments for the final puzzle pop up here; PatchGuard shouts if files are stale
	add_child(HintToast.new())
	add_child(PatchGuard.new())

func lock_gameplay() -> void:
	_lock_count += 1
	if _lock_count == 1:
		gameplay_locked.emit()

func unlock_gameplay() -> void:
	_lock_count = maxi(0, _lock_count - 1)
	if _lock_count == 0:
		gameplay_unlocked.emit()


# Called when the main menu opens. A sequence abandoned mid-way (e.g. quitting from a
# puzzle) never reaches its unlock_gameplay(), which would leave the next game locked.
func reset_runtime_state() -> void:
	var was_locked := _lock_count > 0
	_lock_count = 0
	if was_locked:
		gameplay_unlocked.emit()


func set_story_progress(value: int) -> void:
	story_progress = value
	story_progress_changed.emit(value)


func set_chapter(value: int) -> void:
	current_chapter = value
	chapter_changed.emit(value)
