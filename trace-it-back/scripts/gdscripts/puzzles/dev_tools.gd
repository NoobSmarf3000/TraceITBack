extends Node
class_name DevTools

const PATCH_LEVEL := 5
const ENABLED := true
const COMPUTER_ROOM := "res://scenes/rooms/computerroom.tscn"
const COMPUTER_ROOM_SPAWN := "FromRoom4"

const JUMPABLE_PUZZLES := [1, 2, 3, 4, 5, 6, 7]

var _layer: CanvasLayer
var _puzzle_picker: OptionButton
var _corruption_picker: SpinBox
var _status: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	if key.keycode == KEY_F2:
		AuditLogScreen.toggle(get_tree())
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F10 and ENABLED:
		_toggle_overlay()
		get_viewport().set_input_as_handled()


func _toggle_overlay() -> void:
	if _layer == null:
		_build_overlay()
	_layer.visible = not _layer.visible
	if _layer.visible:
		_say("")

func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 101
	add_child(_layer)

	var panel := PanelContainer.new()
	panel.position = Vector2(8, 8)
	_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(230, 0)
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)

	var title := Label.new()
	title.text = "DEV TOOLS  (F10 closes)"
	column.add_child(title)

	var start_row := HBoxContainer.new()
	column.add_child(start_row)
	_puzzle_picker = OptionButton.new()
	for number in JUMPABLE_PUZZLES:
		_puzzle_picker.add_item("Puzzle %d" % number, number)
	_puzzle_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_row.add_child(_puzzle_picker)
	start_row.add_child(_make_button("Start", _on_start_pressed))

	column.add_child(_make_button("Go to computer room", _on_go_to_room_pressed))
	column.add_child(_make_button("Intro quiz only", _on_quiz_pressed))
	column.add_child(_make_label("Running puzzle:"))
	var grid := GridContainer.new()
	grid.columns = 2
	column.add_child(grid)
	grid.add_child(_make_button("Solve step", _on_solve_step_pressed))
	grid.add_child(_make_button("+1 mistake", _on_mistake_pressed))
	grid.add_child(_make_button("Lose life", _on_lose_life_pressed))
	grid.add_child(_make_button("Pass puzzle", _on_pass_pressed))
	grid.add_child(_make_button("Fail puzzle", _on_fail_pressed))

	# --- save state ---
	column.add_child(_make_label("Save state:"))
	var corruption_row := HBoxContainer.new()
	column.add_child(corruption_row)
	corruption_row.add_child(_make_label("corruption"))
	_corruption_picker = SpinBox.new()
	_corruption_picker.min_value = 0
	_corruption_picker.max_value = 4
	_corruption_picker.step = 1
	corruption_row.add_child(_corruption_picker)
	corruption_row.add_child(_make_button("Set", _on_corruption_pressed))

	var fragment_row := HBoxContainer.new()
	column.add_child(fragment_row)
	fragment_row.add_child(_make_button("All fragments", _on_all_fragments_pressed))
	fragment_row.add_child(_make_button("No fragments", _on_no_fragments_pressed))

	column.add_child(_make_button("Seed mistakes for puzzles 1-6", _on_seed_pressed))
	column.add_child(_make_button("Audit log (F2)", func(): AuditLogScreen.open(get_tree())))
	column.add_child(_make_button("Dump save to console", _on_dump_pressed))

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(230, 0)
	column.add_child(_status)


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _say(text: String) -> void:
	if _status != null:
		_status.text = text


func _active_puzzle() -> PuzzleBase:
	return get_tree().get_first_node_in_group("active_puzzle") as PuzzleBase


func _on_start_pressed() -> void:
	var number := _puzzle_picker.get_selected_id()
	var room := get_tree().current_scene

	if room == null or not room.has_method("run_sequence"):
		_say("Not in the computer room. Use 'Go to computer room' first.")
		return
	if bool(room.get("sequence_running")):
		_say("A sequence is already running. Pass or fail the current puzzle first.")
		return

	var state := SaveManager.get_current_save()
	state.computer_on = true
	state.intro_quiz_done = true
	state.last_puzzle = number - 1
	state.puzzle_progress.erase(number)
	SaveManager.reset_audit_for(number)

	_layer.visible = false
	room.call("run_sequence", number, false)


func _on_go_to_room_pressed() -> void:
	_layer.visible = false
	NavigationManager.change_room(COMPUTER_ROOM, COMPUTER_ROOM_SPAWN)


func _on_quiz_pressed() -> void:
	_layer.visible = false
	get_tree().root.add_child(IntroQuiz.new())


func _with_puzzle(action: Callable) -> void:
	var puzzle := _active_puzzle()
	if puzzle == null:
		_say("No sub-puzzle puzzle is running (puzzle 7 is not built yet).")
		return
	action.call(puzzle)
	_say("Done.")


func _on_solve_step_pressed() -> void:
	_with_puzzle(func(p): p.dev_solve_step())


func _on_mistake_pressed() -> void:
	_with_puzzle(func(p): p.dev_add_mistake())


func _on_lose_life_pressed() -> void:
	_with_puzzle(func(p): p.dev_lose_life())


func _active_final() -> Node:
	return get_tree().get_first_node_in_group("active_final_puzzle")


func _on_pass_pressed() -> void:
	var final_puzzle := _active_final()
	if final_puzzle != null:
		final_puzzle.dev_pass()
		_say("Done.")
		return
	_with_puzzle(func(p): p.dev_pass())


func _on_fail_pressed() -> void:
	var final_puzzle := _active_final()
	if final_puzzle != null:
		final_puzzle.dev_fail()
		_say("Done.")
		return
	_with_puzzle(func(p): p.dev_fail())


func _on_all_fragments_pressed() -> void:
	for hint in JavaFauxSyntax.FINAL_HINTS:
		SaveManager.record_hint(str(hint["id"]))
	_say("All %d fragments recovered." % JavaFauxSyntax.hint_count())


func _on_no_fragments_pressed() -> void:
	SaveManager.clear_hints()
	_say("Fragments cleared.")


func _on_corruption_pressed() -> void:
	SaveManager.get_current_save().ace_corruption = int(_corruption_picker.value)
	_say("ace_corruption = %d  (final puzzle is %s)" % [
		int(_corruption_picker.value),
		"BAD" if int(_corruption_picker.value) >= 2 else "GOOD"
	])


# Fake results so puzzle 7's repair logic has something to read.
func _on_seed_pressed() -> void:
	var state := SaveManager.get_current_save()
	var worst := 0
	for number in range(1, PuzzleEvaluatorResource.LAST_NORMAL_PUZZLE + 1):
		var mistakes := number % 4
		state.puzzle_errors[number] = mistakes
		state.puzzle_lives_lost[number] = 0
		state.puzzle_failed[number] = false
		worst = maxi(worst, PuzzleEvaluatorResource.version_for(mistakes))
	state.ace_corruption = worst
	_say("Seeded mistakes 1,2,3,0,1,2 for puzzles 1-6. ace_corruption = %d" % worst)


func _on_dump_pressed() -> void:
	var state := SaveManager.get_current_save()
	print("[DevTools] ---- save ----")
	print("  last_puzzle=%d  computer_on=%s  route=%s  ace_corruption=%d" % [
		state.last_puzzle, state.computer_on, state.route, state.ace_corruption
	])
	print("  intro_quiz_done=%s  intro_quiz_mistakes=%d" % [state.intro_quiz_done, state.intro_quiz_mistakes])
	print("  puzzle_errors=", state.puzzle_errors)
	print("  puzzle_lives_lost=", state.puzzle_lives_lost)
	print("  puzzle_failed=", state.puzzle_failed)
	print("  puzzle_progress=", state.puzzle_progress)
	print("  hints_found=", state.hints_found)
	print("  audit_log entries=%d" % state.audit_log.size())
	_say("Printed to the console.")
