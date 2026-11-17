extends Node
class_name PatchGuard

const PATCH_LEVEL := 5
const REQUIRED_LEVEL := 5
const ENABLED := true
const LOG_PATH := "user://patch_guard.log"

const SCRIPTS := {
	"res://scripts/autoload/SaveManager.gd": {
		"methods": ["get_puzzle_progress", "set_puzzle_progress", "clear_puzzle_progress", "log_audit",
			"mark_life_obsolete", "get_audit_log", "reset_audit_for", "set_puzzle_summary",
			"push_audit_variables", "record_hint", "get_hints_found", "clear_hints"],
	},
	"res://scripts/resource/save_state_resource.gd": {
		"props": ["puzzle_progress", "audit_log", "puzzle_summary", "puzzle_failed", "puzzle_lives_lost",
			"intro_quiz_done", "intro_quiz_mistakes", "hints_found"],
	},
	"res://scripts/resource/puzzle_evaluator_resource.gd": {},
	"res://scripts/gdscripts/java_faux_script.gd": {
		"methods": ["normalize_code", "matches_answer", "describe_problem", "hint_for_interaction",
			"validate_final", "get_hint", "hint_count"],
	},
	"res://scripts/gdscripts/puzzles/audit_summary.gd": {
		"methods": ["compute", "totals", "variables_for"],
	},
	"res://scripts/gdscripts/puzzles/final_program.gd": {
		"methods": ["check_typed", "build_code_files", "wrong_slots", "sections_to_fix", "bank_words"],
	},
	"res://scripts/gdscripts/puzzles/puzzle_base.gd": {
		"methods": ["_build_summary", "set_word_bank_available", "show_output", "dev_solve_step"],
	},
	"res://scripts/gdscripts/puzzles/puzzle_7.gd": {
		"methods": ["dev_pass", "dev_fail"],
	},
	"res://scripts/gdscripts/puzzles/challenges/slots_challenge.gd": {},
	"res://scripts/gdscripts/puzzles/challenges/predict_challenge.gd": {},
	"res://scripts/gdscripts/puzzles/challenges/trace_challenge.gd": {},
	"res://scripts/gdscripts/puzzles/audit_log_screen.gd": {},
	"res://scripts/gdscripts/puzzles/dev_tools.gd": {},
	"res://scripts/gdscripts/puzzles/hint_toast.gd": {},
	"res://scripts/gdscripts/rooms/computerroom.gd": {},
}

const MIN_PUZZLE_SCENE_NODES := 15


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ENABLED:
		call_deferred("_run")


func _run() -> void:
	var problems := check()
	var notes := get_notes()

	for note in notes:
		push_warning("[PatchGuard] note: " + note)

	if problems.is_empty():
		print("[PatchGuard] all %d checked files are at patch level %d." % [SCRIPTS.size(), REQUIRED_LEVEL])
		return

	for problem in problems:
		push_error("[PatchGuard] " + problem)
	_write_log(problems, notes)
	_show_overlay(problems)


# Everything that is wrong (empty = all good).
static func check() -> Array:
	var problems: Array = []

	for path in SCRIPTS:
		if not ResourceLoader.exists(path):
			problems.append("MISSING FILE: %s" % path)
			continue
		var script := load(path) as Script
		if script == null:
			problems.append("CANNOT LOAD: %s" % path)
			continue

		var level := int(script.get_script_constant_map().get("PATCH_LEVEL", 0))
		if level < REQUIRED_LEVEL:
			problems.append("STALE (patch level %d, need %d): %s" % [level, REQUIRED_LEVEL, path])

		var method_names: Array = []
		for method in script.get_script_method_list():
			method_names.append(str(method["name"]))
		for needed in SCRIPTS[path].get("methods", []):
			if not method_names.has(needed):
				problems.append("%s has no function %s()" % [path.get_file(), needed])

		var property_names: Array = []
		for property in script.get_script_property_list():
			property_names.append(str(property["name"]))
		for needed in SCRIPTS[path].get("props", []):
			if not property_names.has(needed):
				problems.append("%s has no variable '%s'" % [path.get_file(), needed])

	for number in range(1, PuzzleEvaluatorResource.FINAL_PUZZLE + 1):
		var scene_path := "res://scenes/puzzles/puzzle_%d.tscn" % number
		var scene := load(scene_path) as PackedScene
		if scene == null:
			problems.append("MISSING SCENE: %s" % scene_path)
		elif scene.get_state().get_node_count() < MIN_PUZZLE_SCENE_NODES:
			problems.append("EMPTY STUB SCENE (%d nodes): %s" % [scene.get_state().get_node_count(), scene_path])

	return problems


# Things worth knowing that do not stop the game.
static func get_notes() -> Array:
	var notes: Array = []

	var style := str(ProjectSettings.get_setting("dialogic/layout/default_style", ""))
	if style == "" or not ResourceLoader.exists(style):
		notes.append("Dialogic's default style '%s' does not exist, so Dialogic uses its built-in style. "
			% style + "(The custom blackboard layout is unfinished: it has no dialogue text node.)")

	var unregistered: Array = []
	var wanted := AuditSummary.variables_for({}, 0, PuzzleEvaluatorResource.LAST_NORMAL_PUZZLE)
	for key in wanted:
		var path := "%s.%s" % [SaveManager.AUDIT_VAR_ROOT, key]
		if not Dialogic.VAR.has(path):
			unregistered.append(path)
	for n in range(2, PuzzleEvaluatorResource.FINAL_PUZZLE + 1):
		for path in ["chapter_one.ace_puzzle_ending_good.ace_and_tyrone_puzzle_good%d" % n,
				"chapter_one.ace_puzzle_ending_bad.ace_and_tyrone_puzzle_bad%d" % n]:
			if not Dialogic.VAR.has(path):
				unregistered.append(path)
	if not unregistered.is_empty():
		notes.append("%d Dialogic variables are not registered (they are silently skipped), e.g. %s. "
			% [unregistered.size(), unregistered[0]] + "Use the variables block from project_godot_variables.txt.")

	return notes


func _write_log(problems: Array, notes: Array) -> void:
	var file := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("PatchGuard  %s  (required patch level %d)" % [Time.get_datetime_string_from_system(), REQUIRED_LEVEL])
	for problem in problems:
		file.store_line("PROBLEM  " + str(problem))
	for note in notes:
		file.store_line("note     " + str(note))


func _show_overlay(problems: Array) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	var background := ColorRect.new()
	background.color = Color(0.35, 0.02, 0.04, 0.96)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var text := Label.new()
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.add_theme_font_size_override("font_size", 12)
	var lines: Array = [
		"PATCH MISMATCH: some project files are out of date",
		"",
		"The files below are not at patch level %d (or are missing something other files need)." % REQUIRED_LEVEL,
		"Re-extract the latest patch over the project, or restore these files:",
		"",
	]
	var shown := 0
	for problem in problems:
		if shown >= 14:
			lines.append("... and %d more (see user://patch_guard.log)" % (problems.size() - shown))
			break
		lines.append("  - " + str(problem))
		shown += 1
	lines.append("")
	lines.append("[ click anywhere to dismiss ]")
	text.text = "\n".join(PackedStringArray(lines))
	root.add_child(text)

	root.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			layer.queue_free()
	)
