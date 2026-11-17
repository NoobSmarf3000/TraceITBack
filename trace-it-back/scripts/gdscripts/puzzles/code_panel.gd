extends Control
class_name CodePanel

const CODE_FONT := preload("res://assets/texts/consolas.ttf")

@onready var tab_container: TabContainer = $TabContainer

var slot_controls: Dictionary = {}
var file_data: Dictionary = {}

class CodeDropSlot extends LineEdit:
	func _can_drop_data(_at_position: Vector2, data) -> bool:
		if typeof(data) != TYPE_DICTIONARY:
			return false

		return data.get("type", "") == "puzzle_word"

	func _drop_data(_at_position: Vector2, data) -> void:
		text = str(data.get("value", ""))
		caret_column = text.length()

func _ready() -> void:
	tab_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func setup_files(files: Array) -> void:
	_clear_files()

	for file in files:
		_create_file(file)


func _clear_files() -> void:
	slot_controls.clear()
	file_data.clear()

	for child in tab_container.get_children():
		child.queue_free()


func _create_file(file: Dictionary) -> void:
	var file_name: String = str(file.get("name", "Untitled.java"))
	var lines: Array = file.get("lines", [])

	file_data[file_name] = file

	var file_tab := Control.new()
	file_tab.name = file_name
	file_tab.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var code_area := VBoxContainer.new()
	code_area.name = "CodeArea"
	code_area.add_theme_constant_override("separation", 2)
	code_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	scroll.add_child(code_area)
	file_tab.add_child(scroll)
	tab_container.add_child(file_tab)

	slot_controls[file_name] = {}

	for line_data in lines:
		_create_code_line(
			code_area,
			file_name,
			line_data
		)


func _create_code_line(
	code_area: VBoxContainer,
	file_name: String,
	line_data: Dictionary
) -> void:

	var line := HBoxContainer.new()
	line.name = "CodeLine"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_number := Label.new()
	line_number.text = str(code_area.get_child_count() + 1)
	line_number.custom_minimum_size.x = 35
	line_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line_number.add_theme_font_override("font", CODE_FONT)
	line_number.add_theme_font_size_override("font_size", 14)

	line.add_child(line_number)

	var code_content := HBoxContainer.new()
	code_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_content.add_theme_constant_override("separation", 0)

	line.add_child(code_content)

	var parts: Array = line_data.get("parts", [])

	for part in parts:
		if part.has("text"):
			_create_text_part(
				code_content,
				str(part["text"])
			)

		elif part.has("slot"):
			_create_slot(
				code_content,
				file_name,
				part
			)

	code_area.add_child(line)


func _create_text_part(
	parent: HBoxContainer,
	text_value: String
) -> void:

	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", CODE_FONT)
	label.add_theme_font_size_override("font_size", 14)

	parent.add_child(label)


func _create_slot(
	parent: HBoxContainer,
	file_name: String,
	slot_data: Dictionary
) -> void:

	var slot_name: String = str(slot_data["slot"])

	var slot := CodeDropSlot.new()

	slot.name = slot_name
	slot.custom_minimum_size.x = float(
		slot_data.get("width", 100)
	)

	slot.add_theme_font_override("font", CODE_FONT)
	slot.add_theme_font_size_override("font_size", 14)

	slot.alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot.clear_button_enabled = false
	slot.placeholder_text = str(
		slot_data.get("placeholder", "")
	)

	# Allow the existing draggable_word system to drop
	# directly into this LineEdit.
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	slot.set_meta("code_panel_slot", true)
	slot.set_meta("slot_name", slot_name)

	if not slot_controls.has(file_name):
		slot_controls[file_name] = {}

	slot_controls[file_name][slot_name] = slot

	parent.add_child(slot)


func get_answers() -> Dictionary:
	var answers := {}

	for file_name in slot_controls:
		answers[file_name] = {}

		for slot_name in slot_controls[file_name]:
			var slot: LineEdit = slot_controls[file_name][slot_name]
			answers[file_name][slot_name] = slot.text

	return answers


func get_file_answers(file_name: String) -> Dictionary:
	if not slot_controls.has(file_name):
		return {}

	var answers := {}

	for slot_name in slot_controls[file_name]:
		var slot: LineEdit = slot_controls[file_name][slot_name]
		answers[slot_name] = slot.text

	return answers


func reset() -> void:
	for file_name in slot_controls:
		for slot_name in slot_controls[file_name]:
			var slot: LineEdit = slot_controls[file_name][slot_name]
			slot.clear()


func set_editing_enabled(enabled: bool) -> void:
	for file_name in slot_controls:
		for slot_name in slot_controls[file_name]:
			var slot: LineEdit = slot_controls[file_name][slot_name]
			slot.editable = enabled


func get_current_file() -> String:
	var current_tab := tab_container.get_current_tab_control()

	if current_tab == null:
		return ""

	return current_tab.name
