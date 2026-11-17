@tool
extends DialogicLayoutBase

@export var canvas_layer: int = 1
@export var follow_viewport: bool = false

@export_subgroup("Global")
@export var global_bg_color: Color = Color(0, 0, 0, 0.9)
@export var global_font_color: Color = Color("white")
@export_file('*.ttf', '*.tres') var global_font: String = ""
@export var global_font_size: int = 18


func _apply_export_overrides() -> void:
	var layer_node = find_child("CanvasLayer", true, false) as CanvasLayer
	if layer_node:
		layer_node.layer = canvas_layer
		layer_node.follow_viewport_enabled = follow_viewport


	var text_node = find_child("DialogText", true, false)
	if text_node:
		text_node.add_theme_color_override("default_color", global_font_color)
		text_node.add_theme_font_size_override("normal_font_size", global_font_size)
