extends CanvasLayer
class_name HintToast

const PATCH_LEVEL := 5
const SHOW_SECONDS := 3.5
const FADE_SECONDS := 0.6
const CODE_FONT := preload("res://assets/texts/consolas.ttf")

var _panel: PanelContainer
var _label: Label
var _tween: Tween


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	call_deferred("_connect_signal")


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_panel.offset_top = 10.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	_panel.add_child(margin)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", CODE_FONT)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color("#7dff9a"))
	margin.add_child(_label)


func _connect_signal() -> void:
	if not SaveManager.hint_found.is_connected(_on_hint_found):
		SaveManager.hint_found.connect(_on_hint_found)


func _on_hint_found(hint_id: String, found: int, total: int) -> void:
	var hint := JavaFauxSyntax.get_hint(hint_id)
	_label.text = "LOG FRAGMENT RECOVERED  %d/%d\n%s   (F2 to read)" % [found, total, str(hint.get("title", ""))]

	if _tween != null:
		_tween.kill()
	_panel.visible = true
	_panel.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(SHOW_SECONDS)
	_tween.tween_property(_panel, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(func(): _panel.visible = false)
