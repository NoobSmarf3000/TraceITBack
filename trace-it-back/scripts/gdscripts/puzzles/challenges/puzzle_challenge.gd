extends RefCounted
class_name PuzzleChallenge


const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const FONT_SIZE := 11

var host            
var step: Dictionary = {}
var stage: Panel


func setup(p_host, p_step: Dictionary) -> void:
	host = p_host
	step = p_step

func start() -> void:
	pass

func reset() -> void:
	pass

func set_input_enabled(_enabled: bool) -> void:
	pass

func evaluate() -> Array:
	return []

func on_solved() -> void:
	host.show_output(str(step.get("output", "")))

func cleanup() -> void:
	close_stage()


func problem(error_type: String, text: String, line: int = 0, slot: String = "", got: String = "") -> Dictionary:
	var file_name: String = step.get("file", JavaFauxSyntax.DEFAULT_FILE)
	return {
		"error_type": error_type,
		"message": JavaFauxSyntax.format_message(file_name, line, error_type, text),
		"line": line,
		"file": file_name,
		"slot": slot,
		"got": got,
	}


func step_error_type(fallback: String = "LOGICAL") -> String:
	var error_type := str(step.get("error_type", fallback))
	return error_type if JavaFauxSyntax.ERROR_TYPES.has(error_type) else fallback

func open_stage() -> VBoxContainer:
	var code_panel: Control = host.code_panel
	code_panel.visible = false
	host.set_word_bank_available(false)

	stage = Panel.new()
	stage.name = "ChallengeStage"
	stage.anchor_left = code_panel.anchor_left
	stage.anchor_top = code_panel.anchor_top
	stage.anchor_right = code_panel.anchor_right
	stage.anchor_bottom = code_panel.anchor_bottom
	stage.offset_left = code_panel.offset_left
	stage.offset_top = code_panel.offset_top
	stage.offset_right = code_panel.offset_right
	stage.offset_bottom = code_panel.offset_bottom

	var box = host.output_panel.get_theme_stylebox("panel")
	if box != null:
		stage.add_theme_stylebox_override("panel", box)

	host.add_child(stage)
	host.move_child(stage, code_panel.get_index() + 1)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	scroll.add_child(content)
	return content


func close_stage() -> void:
	if stage != null:
		stage.queue_free()
		stage = null
	host.code_panel.visible = true


func add_prompt(box: Control, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size = Vector2(200, 0)
	label.add_theme_font_override("font", CODE_FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	box.add_child(label)
	return label

func add_listing(box: Control, lines: Array) -> Label:
	var numbered: Array = []
	for i in range(lines.size()):
		numbered.append("%2d  %s" % [i + 1, str(lines[i])])

	var label := Label.new()
	label.text = "\n".join(numbered)
	label.add_theme_font_override("font", CODE_FONT)
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	box.add_child(label)
	return label
