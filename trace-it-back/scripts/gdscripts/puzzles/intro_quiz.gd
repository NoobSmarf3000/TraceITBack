extends CanvasLayer
class_name IntroQuiz

signal finished(mistakes: int)

const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const FONT_SIZE := 13

var _questions: Array = []
var _index := 0
var _mistakes := 0
var _solved := false

var _progress_label: Label
var _question_label: Label
var _feedback_label: Label
var _option_buttons: Array = []
var _next_button: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_questions = JavaFauxSyntax.INTRO_QUIZ
	_build_ui()
	_show_question(0)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_right = 280.0
	panel.offset_top = -190.0
	panel.offset_bottom = 190.0
	root.add_child(panel)

	var margin := MarginContainer.new()
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = "JAVA INTRO QUIZ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", CODE_FONT)
	title.add_theme_font_size_override("font_size", 16)
	column.add_child(title)

	_progress_label = Label.new()
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_label.add_theme_font_override("font", CODE_FONT)
	_progress_label.add_theme_font_size_override("font_size", 11)
	column.add_child(_progress_label)

	_question_label = Label.new()
	_question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question_label.custom_minimum_size = Vector2(0, 48)
	_question_label.add_theme_font_override("font", CODE_FONT)
	_question_label.add_theme_font_size_override("font_size", 15)
	column.add_child(_question_label)

	for i in range(4):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 32)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_override("font", CODE_FONT)
		button.add_theme_font_size_override("font_size", FONT_SIZE)
		button.pressed.connect(_on_option_pressed.bind(i))
		column.add_child(button)
		_option_buttons.append(button)

	_feedback_label = Label.new()
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback_label.custom_minimum_size = Vector2(0, 52)
	_feedback_label.add_theme_font_override("font", CODE_FONT)
	_feedback_label.add_theme_font_size_override("font_size", 12)
	column.add_child(_feedback_label)

	_next_button = Button.new()
	_next_button.text = "Next"
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.pressed.connect(_on_next_pressed)
	column.add_child(_next_button)


func _show_question(index: int) -> void:
	_index = index
	_solved = false

	var question: Dictionary = _questions[index]
	_progress_label.text = "Question %d of %d" % [index + 1, _questions.size()]
	_question_label.text = str(question["question"])
	_feedback_label.text = ""
	_feedback_label.remove_theme_color_override("font_color")

	var options: Array = question["options"]
	for i in range(_option_buttons.size()):
		var button: Button = _option_buttons[i]
		button.visible = i < options.size()
		button.disabled = false
		if i < options.size():
			button.text = "%s   %s" % [char(65 + i), str(options[i])]

	_next_button.disabled = true
	_next_button.text = "Finish" if index == _questions.size() - 1 else "Next"


func _on_option_pressed(option_index: int) -> void:
	if _solved:
		return

	var question: Dictionary = _questions[_index]
	var options: Array = question["options"]

	if option_index == int(question["answer"]):
		_solved = true
		_feedback_label.text = "Correct!  " + str(question.get("fact", ""))
		_feedback_label.add_theme_color_override("font_color", Color("#7dff9a"))
		for button in _option_buttons:
			button.disabled = true
		_next_button.disabled = false
		return

	_mistakes += 1
	_option_buttons[option_index].disabled = true
	_feedback_label.text = "Not quite. Try another answer."
	_feedback_label.add_theme_color_override("font_color", Color("#ffd166"))

	SaveManager.log_audit({
		"puzzle": 0,
		"step": "Q%d" % (_index + 1),
		"life": 1,
		"mistake": _mistakes,
		"type": "LOGICAL",
		"file": "quiz",
		"line": 0,
		"slot": "",
		"got": str(options[option_index]),
		"message": "quiz: '%s' is not the answer" % str(options[option_index]),
		"obsolete": false,
	})


func _on_next_pressed() -> void:
	if not _solved:
		return
	if _index >= _questions.size() - 1:
		finished.emit(_mistakes)
		queue_free()
		return
	_show_question(_index + 1)
