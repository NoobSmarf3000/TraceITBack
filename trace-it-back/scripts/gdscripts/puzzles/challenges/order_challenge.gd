extends PuzzleChallenge
class_name OrderChallenge

# Put the statements in the right order with the ^ and v buttons.
# "lines" is stored in the CORRECT order; "start_order" says how they start.

var _order: Array = []    # _order[position] = index into "lines"
var _list: VBoxContainer
var _enabled := true


func start() -> void:
	var lines: Array = step.get("lines", [])
	var start_order: Array = step.get("start_order", [])

	_order.clear()
	if start_order.size() == lines.size():
		_order = start_order.duplicate()
	else:
		for i in range(lines.size() - 1, -1, -1):
			_order.append(i)

	var box := open_stage()
	add_prompt(box, str(step.get("prompt", "")))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	box.add_child(_list)

	_rebuild()
	host.show_output("")


func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()

	var lines: Array = step.get("lines", [])
	for position in range(_order.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		row.add_child(_make_move_button("^", position, -1))
		row.add_child(_make_move_button("v", position, 1))

		var label := Label.new()
		label.text = str(lines[_order[position]])
		label.add_theme_font_override("font", CODE_FONT)
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		row.add_child(label)

		_list.add_child(row)


func _make_move_button(symbol: String, position: int, delta: int) -> Button:
	var button := Button.new()
	button.text = symbol
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(26, 22)
	button.disabled = not _enabled
	button.pressed.connect(_move.bind(position, delta))
	return button


func _move(position: int, delta: int) -> void:
	var target := position + delta
	if target < 0 or target >= _order.size():
		return
	var held = _order[position]
	_order[position] = _order[target]
	_order[target] = held
	_rebuild()


func reset() -> void:
	var start_order: Array = step.get("start_order", [])
	var lines: Array = step.get("lines", [])
	_order.clear()
	if start_order.size() == lines.size():
		_order = start_order.duplicate()
	else:
		for i in range(lines.size() - 1, -1, -1):
			_order.append(i)
	_rebuild()


func set_input_enabled(enabled: bool) -> void:
	_enabled = enabled
	if _list != null:
		_rebuild()


func evaluate() -> Array:
	var error_type := step_error_type("LOGICAL")
	var wrong_text := str(step.get("wrong_text", "this statement runs at the wrong time"))

	var problems: Array = []
	for position in range(_order.size()):
		if int(_order[position]) != position:
			problems.append(problem(error_type, wrong_text, position + 1))
	return problems
