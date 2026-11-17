extends Control

@onready var hbox: HBoxContainer = $Panel/ScrollContainer/HBoxContainer

var is_open: bool = false


func _ready() -> void:
	hide()


func set_words(words: Array) -> void:
	_clear_words()

	for word in words:
		_create_word_button(str(word))


func _clear_words() -> void:
	for child in hbox.get_children():
		child.queue_free()


func _create_word_button(word: String) -> void:
	var button := Button.new()

	button.text = word
	button.custom_minimum_size = Vector2(100, 40)

	button.add_theme_font_size_override("font_size", 16)

	button.set_script(
		load("res://scripts/gdscripts/puzzles/draggable_word.gd")
	)

	hbox.add_child(button)


func toggle() -> void:
	is_open = not is_open
	visible = is_open


func open() -> void:
	is_open = true
	show()


func close() -> void:
	is_open = false
	hide()
