extends PuzzleChallenge
class_name ClassifyChallenge

# Put every item in the right group (valid/invalid, value -> data type, ...).

const UNSET := "-"

var _selectors: Array = []   # one OptionButton per item


func start() -> void:
	_selectors.clear()

	var box := open_stage()
	add_prompt(box, str(step.get("prompt", "")))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 5)
	box.add_child(grid)

	var choices: Array = step.get("choices", [])
	for item in step.get("items", []):
		var label := Label.new()
		label.text = str(item["text"])
		label.custom_minimum_size = Vector2(110, 0)
		label.add_theme_font_override("font", CODE_FONT)
		label.add_theme_font_size_override("font_size", 13)
		grid.add_child(label)

		var selector := OptionButton.new()
		selector.focus_mode = Control.FOCUS_NONE
		selector.custom_minimum_size = Vector2(120, 24)
		selector.add_item(UNSET)
		for choice in choices:
			selector.add_item(str(choice))
		selector.select(0)
		grid.add_child(selector)
		_selectors.append(selector)

	host.show_output("")


func reset() -> void:
	for selector in _selectors:
		selector.select(0)


func set_input_enabled(enabled: bool) -> void:
	for selector in _selectors:
		selector.disabled = not enabled


func evaluate() -> Array:
	var error_type := step_error_type("LOGICAL")
	var error_text := str(step.get("error_text", "'%s' does not belong under '%s'"))
	var items: Array = step.get("items", [])
	var problems: Array = []

	for i in range(items.size()):
		var item_text := str(items[i]["text"])
		var chosen: String = _selectors[i].get_item_text(_selectors[i].selected)

		if chosen == UNSET:
			problems.append(problem(error_type, "no choice made for %s" % item_text, 0, "", chosen))
		elif chosen != str(items[i]["answer"]):
			problems.append(problem(error_type, error_text % [item_text, chosen], 0, "", chosen))
	return problems
