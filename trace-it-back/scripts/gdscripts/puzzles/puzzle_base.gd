extends Control
class_name PuzzleBase


signal mistake_made(life_mistakes: int, max_mistakes: int)
signal life_lost(lives_left: int)
signal step_solved(step_label: String)
signal puzzle_finished(success: bool)

const PATCH_LEVEL := 5
const MAX_LIVES := PuzzleEvaluatorResource.MAX_LIVES
const MAX_MISTAKES := PuzzleEvaluatorResource.MAX_MISTAKES
const LIFE_LOST_DELAY := 1.6
const STEP_DELAY := 1.0
const MAX_LOGGED_PROBLEMS := 3 

const OUTPUT_BOTTOM_ANCHOR := 0.38
const DEBUG_TOP_ANCHOR := 0.39
const DEBUG_BOTTOM_ANCHOR := 0.80

const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const WORD_BANK_SCENE := preload("res://scenes/puzzles/word_bank.tscn")

var puzzle_id: int = 0 

@onready var code_panel: CodePanel = $CodePanel
@onready var timer_label: Label = $Header/Timer
@onready var feedback_label: Label = $Feedback
@onready var output_panel: Panel = $OutputPanel
@onready var output_text: Label = $OutputPanel/OutputText
@onready var reset_button: Button = $Buttons/Reset
@onready var submit_button: Button = $Buttons/Submit
@onready var word_bank_button: Button = $Buttons/WordBankButton

var word_bank
var lives_display: LivesDisplay
var debug_panel: DebugPanel
var challenge: PuzzleChallenge

var puzzle_def: Dictionary = {}
var steps: Array = []

var lives: int = MAX_LIVES
var lives_lost: int = 0
var life_mistakes: int = 0
var step_index: int = 0
var elapsed_time: float = 0.0  
var completed: bool = false
var failed: bool = false
var input_locked: bool = false

var _resumed: bool = false


func _ready() -> void:
	puzzle_def = JavaFauxSyntax.get_puzzle(puzzle_id)
	steps = JavaFauxSyntax.get_steps(puzzle_id)
	if puzzle_def.is_empty() or steps.is_empty():
		push_error("PuzzleBase: no JavaFauxSyntax steps for puzzle %d" % puzzle_id)
		set_process(false)
		return

	if OS.is_debug_build():
		for problem in JavaFauxSyntax.validate(puzzle_id):
			push_warning("JavaFauxSyntax: " + problem)

	add_to_group("active_puzzle")

	feedback_label.text = ""
	output_text.text = ""

	_apply_instructions()
	_restore_progress()
	_setup_lives_display()
	_setup_debug_panel()
	_setup_word_bank()
	_connect_buttons()

	_update_timer_display()
	_start_step(step_index)

	if _resumed:
		_say("Resumed at %s with %d %s left." % [
			JavaFauxSyntax.step_label(puzzle_id, step_index),
			lives,
			_lives_word(lives)
		], "INFO")


func _process(delta: float) -> void:
	if completed or GameManager.is_timer_paused():
		return

	elapsed_time += delta
	_update_timer_display()

func _apply_instructions() -> void:
	var instructions_label := get_node_or_null("Header/Instructions") as Label
	if instructions_label != null:
		instructions_label.text = str(
			puzzle_def.get("instructions", JavaFauxSyntax.DEFAULT_INSTRUCTIONS)
		)


func _restore_progress() -> void:
	var progress := SaveManager.get_puzzle_progress(puzzle_id)
	_resumed = not progress.is_empty()

	lives = clampi(int(progress.get("lives", MAX_LIVES)), 1, MAX_LIVES)
	lives_lost = MAX_LIVES - lives
	step_index = clampi(int(progress.get("step", 0)), 0, steps.size() - 1)
	life_mistakes = clampi(int(progress.get("mistakes", 0)), 0, MAX_MISTAKES - 1)

	if not _resumed:
		SaveManager.reset_audit_for(puzzle_id)


func _setup_lives_display() -> void:
	lives_display = get_node_or_null("Header/Lives") as LivesDisplay

	if lives_display == null:
		lives_display = LivesDisplay.new()
		lives_display.name = "Lives"

		var header := get_node_or_null("Header") as Control
		var host: Control = header if header != null else self
		host.add_child(lives_display)

		lives_display.anchor_left = 0.2
		lives_display.anchor_right = 0.5
		lives_display.anchor_top = 0.5
		lives_display.anchor_bottom = 1.0
		lives_display.offset_left = 0.0
		lives_display.offset_right = 0.0
		lives_display.offset_top = 0.0
		lives_display.offset_bottom = 0.0

	lives_display.max_lives = MAX_LIVES
	lives_display.max_mistakes = MAX_MISTAKES
	_refresh_hud()


func _setup_debug_panel() -> void:
	debug_panel = get_node_or_null("DebugPanel") as DebugPanel
	if debug_panel == null:
		debug_panel = DebugPanel.new()
		debug_panel.name = "DebugPanel"
		add_child(debug_panel)

	output_panel.anchor_bottom = OUTPUT_BOTTOM_ANCHOR
	output_panel.offset_bottom = 0.0

	debug_panel.anchor_left = output_panel.anchor_left
	debug_panel.anchor_right = 1.0
	debug_panel.anchor_top = DEBUG_TOP_ANCHOR
	debug_panel.anchor_bottom = DEBUG_BOTTOM_ANCHOR
	debug_panel.offset_left = output_panel.offset_left
	debug_panel.offset_right = 0.0
	debug_panel.offset_top = 0.0
	debug_panel.offset_bottom = 0.0
	debug_panel.apply_style_from(output_panel)

	feedback_label.visible = false 
	if not debug_panel.log_requested.is_connected(_on_log_requested):
		debug_panel.log_requested.connect(_on_log_requested)

	if _resumed:
		debug_panel.load_entries(SaveManager.get_audit_log(puzzle_id))


func _setup_word_bank() -> void:
	word_bank = get_node_or_null("WordBank")
	if word_bank == null:
		word_bank = WORD_BANK_SCENE.instantiate()
		add_child(word_bank)

	move_child(word_bank, get_child_count() - 1)


func _connect_buttons() -> void:
	if not submit_button.pressed.is_connected(_on_submit_pressed):
		submit_button.pressed.connect(_on_submit_pressed)
	if not reset_button.pressed.is_connected(_on_reset_pressed):
		reset_button.pressed.connect(_on_reset_pressed)
	if not word_bank_button.pressed.is_connected(_on_word_bank_button_pressed):
		word_bank_button.pressed.connect(_on_word_bank_button_pressed)


# Add new mechanics here.
func _create_challenge(challenge_type: String) -> PuzzleChallenge:
	match challenge_type:
		"slots":
			return SlotsChallenge.new()
		"find_line":
			return FindLineChallenge.new()
		"order":
			return OrderChallenge.new()
		"predict":
			return PredictChallenge.new()
		"classify":
			return ClassifyChallenge.new()
		"trace":
			return TraceChallenge.new()
	push_error("PuzzleBase: unknown challenge type '%s'" % challenge_type)
	return null


func _start_step(index: int) -> void:
	if challenge != null:
		challenge.cleanup()

	step_index = index
	var step: Dictionary = steps[index]

	challenge = _create_challenge(str(step.get("type", "slots")))
	if challenge == null:
		_say("%s: missing challenge type" % JavaFauxSyntax.step_label(puzzle_id, index), "WARN")
		return

	challenge.setup(self, step)
	challenge.start()
	challenge.set_input_enabled(true)

	if step.has("hint"):
		_say(str(step["hint"]), "INFO")

	_update_title()
	if debug_panel != null:
		debug_panel.set_header(JavaFauxSyntax.step_label(puzzle_id, index), index, steps.size())
	_refresh_hud()

func set_word_bank_available(available: bool) -> void:
	word_bank_button.disabled = not available
	if not available and word_bank != null and word_bank.is_open:
		word_bank.toggle()
		word_bank_button.text = "Word Bank"


func show_output(text: String) -> void:
	output_text.add_theme_font_override("font", CODE_FONT)
	output_text.add_theme_font_size_override("font_size", 12)
	output_text.text = text


func _update_title() -> void:
	var title_label := get_node_or_null("Header/PuzzleTitle") as Label
	if title_label == null:
		return

	var step: Dictionary = steps[step_index]
	var label := JavaFauxSyntax.step_label(puzzle_id, step_index)
	var title := str(step.get("title", puzzle_def.get("title", "")))
	var shown := ("%s  %s" % [label, title]).strip_edges()
	title_label.text = shown

	var title_font_size := 25
	if shown.length() > 19:
		title_font_size = 13
	elif shown.length() > 15:
		title_font_size = 16
	elif shown.length() > 11:
		title_font_size = 20
	title_label.add_theme_font_size_override("font_size", title_font_size)


func _update_timer_display() -> void:
	var total_seconds := int(elapsed_time)
	var minutes := floori(total_seconds / 60.0)
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]


func _refresh_hud() -> void:
	if lives_display != null:
		lives_display.set_state(lives, life_mistakes)


func _lives_word(count: int) -> String:
	return "life" if count == 1 else "lives"

func _say(text: String, kind: String = "INFO") -> void:
	if debug_panel != null:
		debug_panel.add_line(text, kind, 0)
	else:
		feedback_label.visible = true
		feedback_label.text = text


func _on_log_requested() -> void:
	AuditLogScreen.open(get_tree())


func _on_word_bank_button_pressed() -> void:
	word_bank.toggle()
	word_bank_button.text = "Close" if word_bank.is_open else "Word Bank"


func _on_reset_pressed() -> void:
	if completed or input_locked or challenge == null:
		return

	challenge.reset()
	output_text.text = ""


func _lock_inputs() -> void:
	input_locked = true
	submit_button.disabled = true
	if challenge != null:
		challenge.set_input_enabled(false)


func _unlock_inputs() -> void:
	input_locked = false
	submit_button.disabled = false


func _on_submit_pressed() -> void:
	if completed or input_locked or challenge == null:
		return

	var problems: Array = challenge.evaluate()
	if problems.is_empty():
		_on_step_solved()
	else:
		_register_mistake(problems)


func _register_mistake(problems: Array) -> void:
	life_mistakes += 1
	mistake_made.emit(life_mistakes, MAX_MISTAKES)
	_log_problems(problems)
	_refresh_hud()

	if life_mistakes >= MAX_MISTAKES:
		_lose_life()
	else:
		_save_progress()


func _log_problems(problems: Array) -> void:
	var step_label := JavaFauxSyntax.step_label(puzzle_id, step_index)
	var logged := 0

	for problem in problems:
		if logged >= MAX_LOGGED_PROBLEMS:
			break
		logged += 1

		var entry := {
			"puzzle": puzzle_id,
			"step": step_label,
			"life": lives_lost + 1,
			"mistake": life_mistakes,
			"type": str(problem.get("error_type", "COMPILE")),
			"file": str(problem.get("file", "")),
			"line": int(problem.get("line", 0)),
			"slot": str(problem.get("slot", "")),
			"got": str(problem.get("got", "")),
			"message": str(problem.get("message", "")),
			"obsolete": false,
		}
		SaveManager.log_audit(entry)
		if debug_panel != null:
			debug_panel.add_entry(entry)
		else:
			feedback_label.visible = true
			feedback_label.text = "Incorrect. Mistakes: %d / %d" % [life_mistakes, MAX_MISTAKES]


func _save_progress() -> void:
	SaveManager.set_puzzle_progress(puzzle_id, lives, step_index, life_mistakes)


func _lose_life() -> void:
	lives -= 1
	lives_lost += 1
	life_lost.emit(lives)

	SaveManager.mark_life_obsolete(puzzle_id, lives_lost)
	if debug_panel != null:
		debug_panel.mark_life_obsolete(lives_lost)

	if lives <= 0:
		_fail_puzzle()
		return


	SaveManager.set_puzzle_progress(puzzle_id, lives, 0, 0)

	_lock_inputs()
	_say("Life lost! %d %s left. Starting over from %s." % [
		lives,
		_lives_word(lives),
		JavaFauxSyntax.step_label(puzzle_id, 0)
	], "WARN")

	await get_tree().create_timer(LIFE_LOST_DELAY).timeout

	if not is_inside_tree() or completed:
		return
	_restart_sequence()


func _restart_sequence() -> void:
	life_mistakes = 0
	_unlock_inputs()
	_start_step(0)
	_say("New life. Mistakes reset to 0 / %d." % MAX_MISTAKES, "INFO")


func _on_step_solved() -> void:
	var label := JavaFauxSyntax.step_label(puzzle_id, step_index)
	challenge.on_solved()
	step_solved.emit(label)
	_say("%s passed." % label, "OK")

	if step_index >= steps.size() - 1:
		_complete_puzzle()
		return

	_lock_inputs()
	_save_progress_for(step_index + 1)

	await get_tree().create_timer(STEP_DELAY).timeout

	if not is_inside_tree() or completed:
		return
	_unlock_inputs()
	_start_step(step_index + 1)


func _save_progress_for(next_step: int) -> void:
	SaveManager.set_puzzle_progress(puzzle_id, lives, next_step, life_mistakes)


func _complete_puzzle() -> void:
	completed = true
	_say("All topics cleared.", "OK")
	_lock_inputs()
	_finish(true)


func _fail_puzzle() -> void:
	if completed:
		return

	completed = true
	failed = true
	_say("Out of lives...", "WARN")
	_lock_inputs()
	_finish(false)

func _build_summary() -> Dictionary:
	var titles := {}
	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		titles[JavaFauxSyntax.step_label(puzzle_id, i)] = str(step.get("title", step.get("topic", "")))

	var finishing_life := mini(lives_lost + 1, MAX_LIVES)
	return AuditSummary.compute(
		SaveManager.get_audit_log(puzzle_id),
		puzzle_id,
		finishing_life,
		titles,
		life_mistakes,
		lives_lost,
		failed
	)


func _finish(success: bool) -> void:
	SaveManager.clear_puzzle_progress(puzzle_id)
	SaveManager.set_puzzle_summary(puzzle_id, _build_summary())
	puzzle_finished.emit(success)
	# mistakes = the finishing life only; earlier lives are obsolete.
	GameManager.puzzle_completed.emit(puzzle_id, elapsed_time, life_mistakes, lives_lost, failed)

func dev_solve_step() -> void:
	if completed or input_locked or challenge == null:
		return
	_on_step_solved()


func dev_add_mistake() -> void:
	if completed or input_locked:
		return
	_register_mistake([{
		"error_type": "COMPILE",
		"message": "(dev) forced mistake",
		"line": 0,
		"file": "dev",
		"slot": "",
		"got": "",
	}])


func dev_lose_life() -> void:
	if completed or input_locked:
		return
	life_mistakes = MAX_MISTAKES - 1
	dev_add_mistake()


func dev_pass() -> void:
	if completed:
		return
	_complete_puzzle()


func dev_fail() -> void:
	if completed or input_locked:
		return
	lives = 1
	life_mistakes = MAX_MISTAKES - 1
	dev_add_mistake()
