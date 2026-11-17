extends Control

signal closed(result: Dictionary)

const PATCH_LEVEL := 5

const TIME_LIMIT_GOOD := 30.0 * 60.0
const TIME_LIMIT_BAD := 30.0 * 60.0

const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const WORD_BANK_SCENE := preload("res://scenes/puzzles/word_bank.tscn")
const CODE_PANEL_SCENE := preload("res://scenes/puzzles/code_panel.tscn")

const WRONG_SLOT_COLOR := Color(1, 0.4, 0.4)
const WRONG_LINE_COLOR := Color(1, 0.2, 0.2, 0.35)
const MAX_LOGGED_PROBLEMS := 3

const OUTPUT_BOTTOM_ANCHOR := 0.60
const DEBUG_TOP_ANCHOR := 0.61
const DEBUG_BOTTOM_ANCHOR := 0.80

const GLITCH_WORDS := ["HELLO WORLD", "ACE", "TRACEBACK", "CONGRATULATIONS", "TRACE IT BACK"]
const GLITCH_END_WORD := "TRACE IT BACK"
const GLITCH_HOLD_FIRST := 1.5
const GLITCH_TIME := 4.0
const GLITCH_HOLD_LAST := 1.5
const GLITCH_CHARS := "#@%&*?/\\|<>+=~"
const GLITCH_TINTS := [Color.WHITE, Color(0.4, 1.0, 1.0), Color(1.0, 0.3, 0.8), Color(1.0, 0.35, 0.35)]

@onready var title_label: Label = $Header/PuzzleTitle
@onready var timer_label: Label = $Header/Timer
@onready var instructions_label: Label = $Header/Instructions
@onready var feedback_label: Label = $Feedback
@onready var output_panel: Panel = $OutputPanel
@onready var output_text: Label = $OutputPanel/OutputText
@onready var reset_button: Button = $Buttons/Reset
@onready var submit_button: Button = $Buttons/Submit
@onready var word_bank_button: Button = $Buttons/WordBankButton
@onready var exit_button: Button = $Header/Exit

var mode: String = "GOOD"
var time_left: float = 0.0
var elapsed_time: float = 0.0
var mistakes: int = 0
var completed: bool = false

var sections_to_repair: Array = []

var tabs: TabContainer
var editor: CodeEdit
var code_panel: CodePanel
var word_bank
var debug_panel: DebugPanel


class DropCodeEdit extends CodeEdit:
	func _can_drop_data(_at_position: Vector2, data) -> bool:
		return typeof(data) == TYPE_DICTIONARY and data.get("type", "") == "puzzle_word"

	func _drop_data(at_position: Vector2, data) -> void:
		var spot := get_line_column_at_pos(Vector2i(at_position))
		set_caret_line(spot.y)
		set_caret_column(spot.x)
		insert_text_at_caret(str(data.get("value", "")))
		grab_focus()


func _ready() -> void:
	add_to_group("active_final_puzzle")

	if OS.is_debug_build():
		for problem in JavaFauxSyntax.validate_final():
			push_warning("JavaFauxSyntax (final puzzle): " + problem)

	var save := SaveManager.get_current_save()
	sections_to_repair = FinalProgram.sections_to_fix(save.puzzle_errors, save.puzzle_failed)

	_setup_layout()
	_setup_debug_panel()

	submit_button.pressed.connect(_on_submit_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	exit_button.visible = save.hints_found.size() < JavaFauxSyntax.hint_count()

	time_left = TIME_LIMIT_BAD if mode == "BAD" else TIME_LIMIT_GOOD

	if mode == "BAD":
		_setup_slot_mode()
	else:
		_setup_editor_mode()

	_restore_attempt()
	_announce_fragments()
	_update_timer_display()


func _process(delta: float) -> void:
	if completed or GameManager.is_timer_paused():
		return

	elapsed_time += delta
	time_left -= delta
	_update_timer_display()

	if time_left <= 0.0:
		time_left = 0.0
		_say("TIME IS UP...", "WARN")
		_finish(false)


func _update_timer_display() -> void:
	var total := int(ceil(time_left))
	timer_label.text = "%02d:%02d" % [floori(total / 60.0), total % 60]
	timer_label.modulate = Color(1, 0.35, 0.35) if time_left < 60.0 else Color.WHITE


func _setup_layout() -> void:
	for label in [instructions_label, feedback_label, output_text]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.add_theme_font_override("font", CODE_FONT)
	instructions_label.add_theme_font_size_override("font_size", 11)
	output_text.add_theme_font_size_override("font_size", 10)
	title_label.text = "Tr4c3(¡+)84ck" if mode == "BAD" else "From Scratch"

	output_text.offset_left += 8.0
	output_text.offset_right -= 8.0
	output_text.offset_top += 4.0


func _setup_debug_panel() -> void:
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
	debug_panel.set_header("7", 0, 1)
	debug_panel.log_requested.connect(func(): AuditLogScreen.open(get_tree()))

	feedback_label.visible = false 


func _say(text: String, kind: String = "INFO") -> void:
	if debug_panel != null:
		debug_panel.add_line(text, kind, 0)
	else:
		feedback_label.visible = true
		feedback_label.text = text

func _announce_fragments() -> void:
	var found := SaveManager.get_hints_found()
	_say("Log fragments recovered: %d / %d  (F2 > Fragments)" % [found.size(), JavaFauxSyntax.hint_count()], "INFO")
	for hint in JavaFauxSyntax.FINAL_HINTS:
		if found.has(str(hint["id"])):
			_say("[F%d] %s" % [int(hint["section"]), str(hint["text"]).replace("\n", " ")], "OK")


func _setup_slot_mode() -> void:
	instructions_label.text = (
		"1. Drag words into the spots\n"
		+ "2. Red spot = your last mistake\n"
		+ "3. You have %d minutes. No lives." % int(TIME_LIMIT_BAD / 60.0)
	)
	output_text.text = "Repair the code.\nPlain text is already correct;\nfix the empty spots."

	code_panel = get_node_or_null("CodePanel") as CodePanel
	if code_panel == null:
		code_panel = CODE_PANEL_SCENE.instantiate() as CodePanel
		add_child(code_panel)
	code_panel.tab_container.add_theme_font_size_override("font_size", 11)
	code_panel.setup_files(FinalProgram.build_code_files(sections_to_repair))

	_setup_word_bank()
	_say("Sections to repair: %s" % ", ".join(PackedStringArray(sections_to_repair.map(func(n): return str(n)))), "INFO")


func _file_name() -> String:
	return str(FinalProgram.program().get("file", JavaFauxSyntax.DEFAULT_FILE))


func _check_slots() -> bool:
	var file_name := _file_name()
	_clear_slot_marks()

	var given: Dictionary = code_panel.get_answers().get(file_name, {})
	var problems := FinalProgram.wrong_slots(given, sections_to_repair)
	if problems.is_empty():
		return true

	mistakes += 1
	_log_problems(problems)

	var marked := 0
	for problem in problems:
		if marked >= MAX_LOGGED_PROBLEMS:
			break
		marked += 1
		var slot = code_panel.slot_controls.get(file_name, {}).get(str(problem["slot"]), null)
		if slot != null:
			slot.modulate = WRONG_SLOT_COLOR
			slot.text = ""
	return false


func _clear_slot_marks() -> void:
	var slots: Dictionary = code_panel.slot_controls.get(_file_name(), {})
	for slot_id in slots:
		slots[slot_id].modulate = Color.WHITE


func _setup_editor_mode() -> void:
	var panel := get_node_or_null("CodePanel")
	if panel != null:
		panel.queue_free()

	instructions_label.text = (
		"1. Write the whole program\n"
		+ "2. Wrong lines turn red\n"
		+ "3. You have %d minutes.\n" % int(TIME_LIMIT_GOOD / 60.0)
		+ "No lives: only ACE's are at stake"
	)
	output_text.text = FinalProgram.spec_text()

	tabs = TabContainer.new()
	add_child(tabs)
	tabs.anchor_right = 0.5
	tabs.anchor_bottom = 0.7
	tabs.anchor_left = 0.0
	tabs.anchor_top = 0.15
	tabs.offset_left = 6.0
	tabs.offset_top = 0.0
	tabs.offset_right = 0.0
	tabs.offset_bottom = 0.0
	tabs.add_theme_font_override("font", CODE_FONT)
	tabs.add_theme_font_size_override("font_size", 11)

	editor = DropCodeEdit.new()
	editor.gutters_draw_line_numbers = true
	editor.indent_use_spaces = true
	editor.indent_size = 4
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.placeholder_text = "Write %s here..." % _file_name()
	editor.add_theme_font_override("font", CODE_FONT)
	editor.add_theme_font_size_override("font_size", 12)
	tabs.add_child(editor)
	tabs.set_tab_title(tabs.get_tab_idx_from_control(editor), _file_name())

	_setup_word_bank()


func _check_editor() -> bool:
	_clear_line_marks()

	var result := FinalProgram.check_typed(editor.text)
	if bool(result["ok"]):
		return true

	mistakes += 1

	var shown_line := int(result["line"])
	var text := str(result["message"])
	if int(result["section"]) > 0:
		text += " (puzzle %d)" % int(result["section"])
	var problem := {
		"error_type": str(result["type"]),
		"message": JavaFauxSyntax.format_message(_file_name(), shown_line, str(result["type"]), text),
		"line": shown_line,
		"file": _file_name(),
		"slot": "",
		"got": "",
	}
	_log_problems([problem])

	var row := clampi(shown_line - 1, 0, editor.get_line_count() - 1)
	editor.set_line_background_color(row, WRONG_LINE_COLOR)
	editor.set_caret_line(row)
	return false


func _clear_line_marks() -> void:
	if editor == null:
		return
	for i in range(editor.get_line_count()):
		editor.set_line_background_color(i, Color(0, 0, 0, 0))


func _setup_word_bank() -> void:
	word_bank = get_node_or_null("WordBank")
	if word_bank == null:
		word_bank = WORD_BANK_SCENE.instantiate()
		add_child(word_bank)

	var words := FinalProgram.bank_words(sections_to_repair)
	words.shuffle()
	word_bank.set_words(words)
	move_child(word_bank, get_child_count() - 1)

	if not word_bank_button.pressed.is_connected(_on_word_bank_button_pressed):
		word_bank_button.pressed.connect(_on_word_bank_button_pressed)


func _on_word_bank_button_pressed() -> void:
	if word_bank == null:
		return
	word_bank.toggle()
	word_bank_button.text = "Close" if word_bank.is_open else "Word Bank"


func _log_problems(problems: Array) -> void:
	var logged := 0
	for problem in problems:
		if logged >= MAX_LOGGED_PROBLEMS:
			break
		logged += 1

		var entry := {
			"puzzle": PuzzleEvaluatorResource.FINAL_PUZZLE,
			"step": "7",
			"life": 1,
			"mistake": mistakes,
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


func _on_submit_pressed() -> void:
	if completed:
		return
	var ok := _check_slots() if mode == "BAD" else _check_editor()
	if ok:
		_say("Main.java compiles and runs. All sections match.", "OK")
		_finish(true)


func _on_reset_pressed() -> void:
	if completed:
		return
	if mode == "BAD":
		code_panel.reset()
		_clear_slot_marks()
	else:
		editor.text = ""
		_clear_line_marks()

func _restore_attempt() -> void:
	var progress := SaveManager.get_puzzle_progress(PuzzleEvaluatorResource.FINAL_PUZZLE)
	if progress.get("mode", "") != mode:
		return

	time_left = float(progress.get("time_left", time_left))
	elapsed_time = float(progress.get("elapsed_time", 0.0))
	mistakes = int(progress.get("mistakes", 0))
	if editor != null:
		editor.text = str(progress.get("draft", ""))
	else:
		var answers: Dictionary = progress.get("draft", {})
		var slots: Dictionary = code_panel.slot_controls.get(_file_name(), {})
		for slot_id in slots:
			slots[slot_id].text = str(answers.get(slot_id, ""))


func _on_exit_pressed() -> void:
	if completed:
		return

	completed = true
	var draft: Variant = editor.text if editor != null else code_panel.get_answers().get(_file_name(), {})
	var save := SaveManager.get_current_save()
	save.puzzle_progress[PuzzleEvaluatorResource.FINAL_PUZZLE] = {
		"mode": mode,
		"time_left": time_left,
		"elapsed_time": elapsed_time,
		"mistakes": mistakes,
		"draft": draft,
	}
	SaveManager.save_game()
	closed.emit({})


func _finish(success: bool) -> void:
	if completed:
		return
	completed = true
	AudioManager.stop_music(0.0)
	exit_button.disabled = true
	submit_button.disabled = true
	reset_button.disabled = true
	if editor != null:
		editor.editable = false
	if code_panel != null:
		code_panel.set_editing_enabled(false)

	if success:
		await _play_success_sequence()

	GameManager.final_puzzle_finished.emit(success, elapsed_time, mistakes)
	closed.emit({"success": success, "time": elapsed_time, "mistakes": mistakes})

func dev_pass() -> void:
	_finish(true)


func dev_fail() -> void:
	_say("(dev) time is up", "WARN")
	_finish(false)

func _hide_puzzle_ui() -> void:
	for node_name in ["Header", "OutputPanel", "Feedback", "Buttons", "CodePanel", "WordBank", "DebugPanel"]:
		var node := get_node_or_null(node_name) as CanvasItem
		if node != null:
			node.visible = false
	if tabs != null:
		tabs.visible = false


func _scramble(word: String) -> String:
	var out := ""
	for ch in word:
		if ch != " " and randf() < 0.25:
			out += GLITCH_CHARS[randi() % GLITCH_CHARS.length()]
		else:
			out += ch
	return out


func _play_success_sequence() -> void:
	_hide_puzzle_ui()

	var label := Label.new()
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", CODE_FONT)
	label.add_theme_font_size_override("font_size", 28)
	label.text = "HELLO WORLD"

	await get_tree().create_timer(GLITCH_HOLD_FIRST).timeout

	var elapsed := 0.0
	var last := "HELLO WORLD"
	while elapsed < GLITCH_TIME:
		var word: String = GLITCH_WORDS.pick_random()
		while word == last:
			word = GLITCH_WORDS.pick_random()
		last = word

		label.text = _scramble(word) if randf() < 0.35 else word
		label.modulate = GLITCH_TINTS.pick_random()
		var jx := randf_range(-5.0, 5.0)
		var jy := randf_range(-3.0, 3.0)
		label.offset_left = jx
		label.offset_right = jx
		label.offset_top = jy
		label.offset_bottom = jy

		var wait := lerpf(0.3, 0.05, elapsed / GLITCH_TIME)
		await get_tree().create_timer(wait).timeout
		elapsed += wait

	label.text = GLITCH_END_WORD
	label.modulate = Color.WHITE
	label.offset_left = 0.0
	label.offset_right = 0.0
	label.offset_top = 0.0
	label.offset_bottom = 0.0
	await get_tree().create_timer(GLITCH_HOLD_LAST).timeout
