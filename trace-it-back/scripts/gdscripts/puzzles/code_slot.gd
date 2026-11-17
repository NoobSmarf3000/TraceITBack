extends Control

var value: String = ""

const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const SLOT_FONT_SIZE := 12


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	if not data.has("type"):
		return false

	return data["type"] == "puzzle_word"


func _drop_data(_at_position: Vector2, data) -> void:
	value = str(data["value"])
	_update_display()


func _update_display() -> void:
	var label := get_node_or_null("Label")

	if label == null:
		label = Label.new()
		label.name = "Label"

		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		label.add_theme_font_override("font", CODE_FONT)
		label.add_theme_font_size_override("font_size", SLOT_FONT_SIZE)

		add_child(label)

	label.text = value


func clear_slot() -> void:
	value = ""

	var label := get_node_or_null("Label")

	if label != null:
		label.queue_free()
