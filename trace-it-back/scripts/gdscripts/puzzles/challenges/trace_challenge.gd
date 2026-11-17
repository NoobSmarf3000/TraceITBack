extends PuzzleChallenge
class_name TraceChallenge

const PATCH_LEVEL := 5   # PatchGuard checks this

# Trace table: what is each variable after every statement?
# This is the "tracing variable values step by step" debugging habit.

var _inputs: Array = []   # per row: {variable name: LineEdit}


func start() -> void:
	_inputs.clear()

	var box := open_stage()
	add_prompt(box, str(step.get("prompt", "")))

	var trace_vars: Array = step.get("vars", [])
	var grid := GridContainer.new()
	grid.columns = 1 + trace_vars.size()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)

	grid.add_child(_make_label("statement"))
	for variable in trace_vars:
		grid.add_child(_make_label(str(variable)))

	for row in step.get("rows", []):
		var code_label := _make_label(str(row["code"]))
		code_label.custom_minimum_size = Vector2(170, 0)
		grid.add_child(code_label)

		var fields := {}
		for variable in trace_vars:
			var field := LineEdit.new()
			field.placeholder_text = "?"
			field.custom_minimum_size = Vector2(56, 22)
			field.add_theme_font_override("font", CODE_FONT)
			field.add_theme_font_size_override("font_size", FONT_SIZE)
			grid.add_child(field)
			fields[variable] = field
		_inputs.append(fields)

	host.show_output("")


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", CODE_FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func reset() -> void:
	for fields in _inputs:
		for variable in fields:
			fields[variable].text = ""


func set_input_enabled(enabled: bool) -> void:
	for fields in _inputs:
		for variable in fields:
			fields[variable].editable = enabled


func evaluate() -> Array:
	var rows: Array = step.get("rows", [])
	var first_line := int(step.get("first_line", 0))
	var problems: Array = []

	for i in range(rows.size()):
		var expected: Dictionary = rows[i]["values"]
		var code := str(rows[i]["code"])
		var line := first_line + i if first_line > 0 else 0
		for variable in expected:
			var typed: String = _inputs[i][variable].text.strip_edges()
			if typed == "":
				problems.append(problem("LOGICAL", "no value entered for %s after '%s'" % [variable, code], line, "", typed))
				break
			if typed != str(expected[variable]):
				problems.append(problem("LOGICAL", "after '%s' %s is not '%s'" % [code, variable, typed], line, "", typed))
				break
	return problems
