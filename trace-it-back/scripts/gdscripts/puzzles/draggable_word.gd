extends Button


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _get_drag_data(_at_position: Vector2):
	var preview := duplicate()

	preview.modulate.a = 0.7
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_drag_preview(preview)

	return {
		"type": "puzzle_word",
		"value": text
	}
