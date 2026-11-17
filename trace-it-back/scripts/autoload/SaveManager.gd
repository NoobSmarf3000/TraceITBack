extends Node

const PATCH_LEVEL := 5   # PatchGuard checks this, so a stale copy of this file is caught at startup

# A final-puzzle log fragment was just found (see record_hint).
signal hint_found(hint_id: String, found: int, total: int)

const MAX_SLOTS := 3
const SAVE_PATH := "user://save_slot_%d.tres"
const INTERACTION_VARS := {
	"BEDROOM_BED": "bed",
	"COMPUTERROOM_BOOKSHELF": "bookshelf",
	"ROOM3_COOKINGRANGE": "cookingrange",
	"ROOM4_COUCH": "couch",
	"ROOM2_DINING_TABLE": "diningtable",
	"BEDROOM_DRAWER": "drawer",
	"ROOFTOP_FENCE": "fence",
	"ROOM3_FRIDGE": "fridge",
	"ROOM4_FRONT_DOOR": "front_door",
	"ROOM3_KITCHEN1": "kitchen1",
	"ROOM1_PARENT_DOOR": "parent_door",
	"BEDROOM_SHELF": "shelf",
	"BATHROOM_SINK": "sink",
	"TOILET": "toilet",
	"ROOM4_TV": "tv",
}

var current_slot: int = 1
var current_save: SaveStateResource
var pending_scene := ""

func get_current_save() -> SaveStateResource:
	if current_save == null:
		new_game()

	return current_save

func record_puzzle(id: int, time: float, mistakes: int, failed: bool, lives_lost: int = 0) -> void:
	var s := get_current_save()
	s.puzzle_times[id] = time
	s.puzzle_errors[id] = mistakes
	s.puzzle_lives_lost[id] = lives_lost
	s.puzzle_failed[id] = failed
	s.puzzle_progress.erase(id)
	s.total_errors += mistakes
	if not failed:
		s.puzzles_completed += 1
	s.last_event_type = "PUZZLE"
	s.last_puzzle = id
	s.narrative_event_consumed = false
	s.ace_corruption = maxi(s.ace_corruption, PuzzleEvaluatorResource.version_for(mistakes, failed))
	push_audit_variables(s)
	save_game()


# ---- Puzzle progress (persisted so quitting mid-puzzle can't refill lives or reset mistakes) ----
func get_puzzle_progress(id: int) -> Dictionary:
	var progress = get_current_save().puzzle_progress.get(id, {})
	return progress if progress is Dictionary else {}


func set_puzzle_progress(id: int, lives: int, step: int, mistakes: int) -> void:
	get_current_save().puzzle_progress[id] = {
		"lives": lives,
		"step": step,
		"mistakes": mistakes,
	}
	save_game()


func clear_puzzle_progress(id: int) -> void:
	get_current_save().puzzle_progress.erase(id)


# ---- Audit log ----
# One entry per logged mistake:
#   puzzle, step ("1.2"), life (1-3), mistake (1-7 within that life),
#   type (COMPILE / RUNTIME / LOGICAL), file, line, slot, got, message, obsolete
const AUDIT_LOG_CAP := 400


func log_audit(entry: Dictionary) -> void:
	var s := get_current_save()
	s.audit_log.append(entry)
	if s.audit_log.size() > AUDIT_LOG_CAP:
		s.audit_log = s.audit_log.slice(s.audit_log.size() - AUDIT_LOG_CAP)


# A life that ended with 7 mistakes is obsolete: it stays in the log (dimmed) but never scores.
func mark_life_obsolete(puzzle_id: int, life: int) -> void:
	for entry in get_current_save().audit_log:
		if int(entry.get("puzzle", -1)) == puzzle_id and int(entry.get("life", 0)) == life:
			entry["obsolete"] = true


# puzzle_id < 0 returns the whole log.
func get_audit_log(puzzle_id: int = -1) -> Array:
	var result: Array = []
	for entry in get_current_save().audit_log:
		if puzzle_id < 0 or int(entry.get("puzzle", -1)) == puzzle_id:
			result.append(entry)
	return result


# Used when a puzzle is started from scratch (e.g. replayed from the debug menu).
func reset_audit_for(puzzle_id: int) -> void:
	var kept: Array = []
	for entry in get_current_save().audit_log:
		if int(entry.get("puzzle", -1)) != puzzle_id:
			kept.append(entry)
	get_current_save().audit_log = kept


# ---- What ACE reads: one summary per puzzle (see audit_summary.gd) ----
# Dialogic variables live under this group; every variable must also be
# registered in Dialogic (see the variables snippet shipped with Patch 4).
const AUDIT_VAR_ROOT := "chapter_one.audit_logs"


# Stored when a puzzle ends; record_puzzle() saves it to disk right after.
func set_puzzle_summary(id: int, summary: Dictionary) -> void:
	get_current_save().puzzle_summary[id] = summary


# Pushes every audit variable. Safe with null (a brand-new player): everything resets to defaults.
func push_audit_variables(s: SaveStateResource) -> void:
	var summaries: Dictionary = {}
	var quiz_mistakes := 0
	if s != null:
		summaries = s.puzzle_summary
		quiz_mistakes = s.intro_quiz_mistakes

	var values := AuditSummary.variables_for(summaries, quiz_mistakes, PuzzleEvaluatorResource.LAST_NORMAL_PUZZLE)
	for key in values:
		_set_var("%s.%s" % [AUDIT_VAR_ROOT, key], values[key])


func record_interaction(interaction_name: String) -> void:
	var s := get_current_save()
	var count := int(s.interaction_counts.get(interaction_name, 0)) + 1
	s.interaction_counts[interaction_name] = count

	s.last_event_type = "INTERACTION"
	s.last_interaction = interaction_name
	s.last_interaction_stage = mini(count, 2)    # the second interaction sticks from then on
	s.last_scene = get_tree().current_scene.scene_file_path
	s.narrative_event_consumed = false

	push_interaction_variables(s)

	# Touching certain objects recovers a log fragment for the final puzzle.
	var hint_id := JavaFauxSyntax.hint_for_interaction(interaction_name)
	if hint_id != "":
		record_hint(hint_id)


# ---- Final puzzle: log fragments (hints) ----
# Found by touching an object (automatic, see JavaFauxSyntax.FINAL_HINTS) or from a
# timeline:   do SaveManager.record_hint("bedroom")
func get_hints_found() -> Array:
	return get_current_save().hints_found.duplicate()


func has_hint(hint_id: String) -> bool:
	return get_current_save().hints_found.has(hint_id)


# Returns true only the first time a fragment is found.
func record_hint(hint_id: String) -> bool:
	if not JavaFauxSyntax.is_hint(hint_id):
		push_warning("SaveManager.record_hint: '%s' is not a known fragment (see JavaFauxSyntax.FINAL_HINTS)" % hint_id)
		return false

	var s := get_current_save()
	if s.hints_found.has(hint_id):
		return false

	s.hints_found.append(hint_id)
	hint_found.emit(hint_id, s.hints_found.size(), JavaFauxSyntax.hint_count())
	if get_tree().current_scene != null:
		save_game()
	return true


# Development: forget every fragment, or find them all.
func clear_hints() -> void:
	get_current_save().hints_found = []


func get_latest_save() -> SaveStateResource:
	var best_slot := 0
	var best_time := 0
	for slot in range(1, MAX_SLOTS + 1):
		if not slot_has_data(slot):
			continue
		var t := FileAccess.get_modified_time(get_save_path(slot))
		if t > best_time:
			best_time = t
			best_slot = slot
	if best_slot == 0:
		return null    # brand-new player
	return get_save_preview(best_slot)

func _set_var(path: String, value) -> void:
	if Dialogic.VAR.has(path):
		Dialogic.VAR.set_variable(path, value)


func push_interaction_variables(s: SaveStateResource) -> void:
	for suffix in INTERACTION_VARS.values():
		_set_var("interactions.last_interacted_" + suffix, "")

	var last := ""
	var stage := ""
	if s != null:
		match s.last_event_type:
			"INTERACTION":
				last = s.last_interaction
				stage = str(s.last_interaction_stage)
			"PUZZLE":
				last = "PUZZLE_%d" % s.last_puzzle
			"ENDING":
				last = "PUZZLE_%d" % PuzzleEvaluatorResource.FINAL_PUZZLE

	_set_var("interactions.last_interacted", last)
	_set_var("interactions._2nd_interaction_onwards", "1" if stage == "2" else "")
	if INTERACTION_VARS.has(last):
		_set_var("interactions.last_interacted_" + INTERACTION_VARS[last], stage)


func push_puzzle_variables(s: SaveStateResource) -> void:
	for n in range(1, PuzzleEvaluatorResource.LAST_NORMAL_PUZZLE + 1):
		for v in range(1, 4):
			_set_var("chapter_one.ace_and_tyrone_puzzle_ending_mistake_%d.ace_and_tyrone_puzzle_ending_mistakev%d_%d" % [n, v, n], "")
	for n in range(2, PuzzleEvaluatorResource.FINAL_PUZZLE + 1):
		_set_var("chapter_one.ace_puzzle_ending_good.ace_and_tyrone_puzzle_good%d" % n, "")
		_set_var("chapter_one.ace_puzzle_ending_bad.ace_and_tyrone_puzzle_bad%d" % n, "")
	_set_var("chapter_one.chap_one_ending", "")
	_set_var("chapter_one.chap_one_timeout_ending", "")

	if s == null:
		return

	if s.last_event_type == "ENDING":
		_set_var("chapter_one.chap_one_ending", s.ending)
		_set_var("chapter_one.chap_one_timeout_ending", "1" if s.final_timed_out else "")
		return

	if s.last_event_type != "PUZZLE":
		return

	var n := s.last_puzzle
	var v := PuzzleEvaluatorResource.version_for(
		int(s.puzzle_errors.get(n, 0)),
		bool(s.puzzle_failed.get(n, false))
	)
	if v == 0:
		_set_var("chapter_one.ace_puzzle_ending_good.ace_and_tyrone_puzzle_good%d" % (n + 1), "1")
	elif v == 4:
		_set_var("chapter_one.ace_puzzle_ending_bad.ace_and_tyrone_puzzle_bad%d" % (n + 1), "1")
	else:
		_set_var("chapter_one.ace_and_tyrone_puzzle_ending_mistake_%d.ace_and_tyrone_puzzle_ending_mistakev%d_%d" % [n, v, n], "1")


func push_story_variables(s: SaveStateResource) -> void:
	push_interaction_variables(s)
	push_puzzle_variables(s)
	push_audit_variables(s)


func should_play_narrative() -> bool:
	return current_save != null \
		and not current_save.narrative_event_consumed \
		and current_save.last_event_type != "NONE"


func _ready() -> void:
	current_save = null


func get_save_path(slot: int) -> String:
	return SAVE_PATH % slot


func slot_has_data(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


func set_slot(slot: int) -> void:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("SaveManager: Invalid save slot: %d" % slot)
		return

	current_slot = slot

func _process(delta: float) -> void:
	if current_save == null:
		return

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	if current_scene is RoomBase:
		current_save.playtime_seconds += delta

func new_game() -> void:
	current_save = SaveStateResource.new()

	current_save.current_scene = ""
	current_save.checkpoint = ""
	current_save.route = "Neutral"
	current_save.dialogue_choices = {}
	current_save.puzzle_times = {}
	current_save.puzzle_errors = {}
	current_save.puzzle_progress = {}
	current_save.audit_log = []
	current_save.puzzle_summary = {}
	current_save.hints_found = []
	current_save.puzzle_lives_lost = {}
	current_save.puzzle_failed = {}
	current_save.inventory = []
	current_save.total_errors = 0
	current_save.puzzles_completed = 0
	current_save.dialogic_variables = {}
	current_save.playtime_seconds = 0.0


func save_game() -> void:
	if current_save == null:
		new_game()

	var room := get_tree().current_scene as RoomBase
	if room != null:
		current_save.current_scene = room.scene_file_path
		current_save.spawn_point = NavigationManager.current_spawn_point
		if not room.room_id.is_empty():
			current_save.checkpoint = room.room_id

	var path := get_save_path(current_slot)

	current_save.current_scene = get_tree().current_scene.scene_file_path
	current_save.spawn_point = NavigationManager.current_spawn_point

	var error := ResourceSaver.save(current_save, path)

	if error != OK:
		push_error("SaveManager: Failed to save game to slot %d. Error: %s" % [current_slot, error])
		return

	print("Game saved to slot %d | scene: %s | spawn: %s | last puzzle: %d | puzzles done: %d" % [
		current_slot, current_save.current_scene, current_save.spawn_point,
		current_save.last_puzzle, current_save.puzzles_completed
	])


func load_game() -> void:
	var path := get_save_path(current_slot)

	if not FileAccess.file_exists(path):
		print("SaveManager: Slot %d is empty." % current_slot)
		return

	# CACHE_MODE_IGNORE: always read the file from disk, never an old cached copy
	var loaded_save := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)

	if loaded_save == null:
		push_error("SaveManager: Could not load save file.")
		return

	if not loaded_save is SaveStateResource:
		push_error("SaveManager: Save file in slot %d is not a SaveStateResource." % current_slot)
		return

	current_save = loaded_save as SaveStateResource

	if current_save.current_scene.is_empty():
		push_warning("SaveManager: Save slot %d has no current scene." % current_slot)
		return

	var spawn := current_save.spawn_point
	if spawn.is_empty():
		spawn = "Default"
	NavigationManager.current_spawn_point = spawn

	print("Loaded slot %d | scene: %s | spawn: %s | last puzzle: %d" % [
		current_slot, current_save.current_scene, spawn, current_save.last_puzzle
	])

	NavigationManager.change_room(current_save.current_scene, spawn)



func delete_save(slot: int) -> void:
	if slot < 1 or slot > MAX_SLOTS:
		push_warning("SaveManager: Invalid save slot: %d" % slot)
		return

	var path := get_save_path(slot)

	if not FileAccess.file_exists(path):
		return

	var error := DirAccess.remove_absolute(path)

	if error != OK:
		push_error(
			"SaveManager: Could not delete save slot %d."
			% slot
		)
		return

	print("Deleted save slot %d." % slot)
	
func get_save_preview(slot: int) -> SaveStateResource:
	var path := get_save_path(slot)

	if not FileAccess.file_exists(path):
		return null

	var loaded_save := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)

	if loaded_save == null or not loaded_save is SaveStateResource:
		return null

	return loaded_save as SaveStateResource
