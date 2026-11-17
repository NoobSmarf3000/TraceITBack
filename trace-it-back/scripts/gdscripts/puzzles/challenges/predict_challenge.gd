extends PuzzleChallenge
class_name PredictChallenge

const PATCH_LEVEL := 5   # PatchGuard checks this

# Read a program and say what it prints.
#   choice mode: "options" + "answer" (index)
#   text mode:   "answer" is the accepted text (or a list of accepted texts)

var _group: ButtonGroup
var _buttons: Array = []
var _input: LineEdit


func start() -> void:
	_buttons.clear()
	_input = null

	var box := open_stage()
	if str(step.get("prompt", "")) != "":
		add_prompt(box, str(step["prompt"]))
	add_listing(box, step.get("lines", []))
	add_prompt(box, str(step.get("question", "")))

	if step.has("options"):
		_group = ButtonGroup.new()
		_group.allow_unpress = true
		for option in step["options"]:
			var button := Button.new()
			button.toggle_mode = true
			button.button_group = _group
			button.focus_mode = Control.FOCUS_NONE
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text = str(option)
			button.custom_minimum_size = Vector2(0, 26)
			button.add_theme_font_override("font", CODE_FONT)
			button.add_theme_font_size_override("font_size", FONT_SIZE)
			box.add_child(button)
			_buttons.append(button)
	else:
		_input = LineEdit.new()
		_input.placeholder_text = "type the output"
		_input.add_theme_font_override("font", CODE_FONT)
		_input.add_theme_font_size_override("font_size", FONT_SIZE)
		box.add_child(_input)

	host.show_output("")


func reset() -> void:
	for button in _buttons:
		button.set_pressed_no_signal(false)
	if _input != null:
		_input.text = ""


func set_input_enabled(enabled: bool) -> void:
	for button in _buttons:
		button.disabled = not enabled
	if _input != null:
		_input.editable = enabled


func evaluate() -> Array:
	var error_type := step_error_type("LOGICAL")
	var focus_line := int(step.get("focus_line", 0))
	var problems: Array = []

	if _input != null:
		var typed := _input.text.strip_edges()
		if typed == "":
			problems.append(problem(error_type, "nothing entered: type what the program prints", focus_line))
		elif not _accepted_texts().has(typed):
			problems.append(problem(error_type, "the output is not \"%s\"" % typed, focus_line, "", typed))
		return problems

	var chosen := -1
	for i in range(_buttons.size()):
		if _buttons[i].button_pressed:
			chosen = i
	if chosen == -1:
		problems.append(problem(error_type, "no answer selected", focus_line))
	elif chosen != int(step.get("answer", -1)):
		var text := str(step["options"][chosen])
		problems.append(problem(error_type, "the output is not \"%s\"" % text, focus_line, "", text))
	return problems


func _accepted_texts() -> Array:
	var answer = step.get("answer", "")
	var accepted: Array = []
	if answer is Array:
		for item in answer:
			accepted.append(str(item).strip_edges())
	else:
		accepted.append(str(answer).strip_edges())
	return accepted
