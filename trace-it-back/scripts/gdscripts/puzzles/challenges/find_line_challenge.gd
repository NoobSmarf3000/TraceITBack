extends PuzzleChallenge
class_name FindLineChallenge

# Click the faulty line (or every ignored line when "multi" is true).

var _buttons: Array = []
var _multi := false
var _guard := false


func start() -> void:
	_multi = bool(step.get("multi", false))
	_buttons.clear()

	var box := open_stage()
	add_prompt(box, str(step.get("prompt", "")))

	var lines: Array = step.get("lines", [])
	for i in range(lines.size()):
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%2d  %s" % [i + 1, str(lines[i])]
		button.custom_minimum_size = Vector2(0, 22)
		button.add_theme_font_override("font", CODE_FONT)
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.toggled.connect(_on_line_toggled.bind(button))
		box.add_child(button)
		_buttons.append(button)

	host.show_output("")


func _on_line_toggled(pressed: bool, source: Button) -> void:
	if _multi or not pressed or _guard:
		return
	_guard = true
	for button in _buttons:
		if button != source:
			button.set_pressed_no_signal(false)
	_guard = false


func reset() -> void:
	for button in _buttons:
		button.set_pressed_no_signal(false)


func set_input_enabled(enabled: bool) -> void:
	for button in _buttons:
		button.disabled = not enabled


func _selected_lines() -> Array:
	var selected: Array = []
	for i in range(_buttons.size()):
		if _buttons[i].button_pressed:
			selected.append(i + 1)
	return selected


func evaluate() -> Array:
	var error_type := step_error_type("COMPILE")
	var faulty: Array = step.get("faulty", [])
	var selected := _selected_lines()
	var problems: Array = []

	if selected.is_empty():
		problems.append(problem(error_type, "nothing selected: pick the line first"))
		return problems

	var wrong_text := str(step.get("wrong_text", "no problem found on this line"))
	for line_number in selected:
		if not faulty.has(line_number):
			problems.append(problem(error_type, wrong_text, int(line_number)))

	var missed := 0
	for line_number in faulty:
		if not selected.has(line_number):
			missed += 1
	if missed > 0 and _multi:
		var missed_text := str(step.get("missed_text", "%d line(s) still unmarked"))
		problems.append(problem(error_type, missed_text % missed))

	return problems
