extends LineEdit

const CODE_FONT := preload("res://assets/texts/consolas.ttf")


func _ready() -> void:
	add_theme_font_override("font", CODE_FONT)
	add_theme_font_size_override("font_size", 12)

	alignment = HORIZONTAL_ALIGNMENT_CENTER
	clear_button_enabled = false

	mouse_filter = Control.MOUSE_FILTER_STOP


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false

	return data.get("type", "") == "puzzle_word"


func _drop_data(_at_position: Vector2, data) -> void:
	text = str(data.get("value", ""))
	caret_column = text.length()
