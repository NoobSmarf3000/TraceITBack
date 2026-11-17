extends Panel
class_name DebugPanel

signal log_requested

const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const MAX_LINES := 80
const LOG_FONT_SIZE := 11

const KIND_COLORS := {
	"COMPILE": "#ff7a7a",
	"RUNTIME": "#ff7ad9",
	"LOGICAL": "#ffd166",
	"WARN": "#ffd166",
	"OK": "#7dff9a",
	"INFO": "#9fd8ff",
}
const COLOR_OBSOLETE := "#6b6b6b"

var title_label: Label
var log_label: RichTextLabel
var log_button: Button

var _built := false
var _lines: Array = []
var _header := "DEBUG"


func _ready() -> void:
	_ensure_built()


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	clip_contents = true

	title_label = Label.new()
	title_label.name = "DebugTitle"
	title_label.anchor_right = 1.0
	title_label.anchor_bottom = 0.14
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.text = _header
	add_child(title_label)

	log_button = Button.new()
	log_button.name = "LogButton"
	log_button.text = "LOG"
	log_button.flat = true
	log_button.focus_mode = Control.FOCUS_NONE
	log_button.tooltip_text = "Open the full audit log (F2)"
	log_button.anchor_left = 0.8
	log_button.anchor_right = 1.0
	log_button.anchor_top = 0.0
	log_button.anchor_bottom = 0.14
	log_button.offset_left = 0.0
	log_button.offset_right = 0.0
	log_button.offset_top = 0.0
	log_button.offset_bottom = 0.0
	log_button.add_theme_font_size_override("font_size", 10)
	log_button.pressed.connect(func(): log_requested.emit())
	add_child(log_button)

	log_label = RichTextLabel.new()
	log_label.name = "DebugLog"
	log_label.bbcode_enabled = true
	log_label.scroll_active = true
	log_label.scroll_following = true
	log_label.selection_enabled = false
	log_label.mouse_filter = Control.MOUSE_FILTER_PASS
	log_label.anchor_left = 0.0
	log_label.anchor_top = 0.15
	log_label.anchor_right = 1.0
	log_label.anchor_bottom = 1.0
	log_label.offset_left = 6.0
	log_label.offset_top = 0.0
	log_label.offset_right = -6.0
	log_label.offset_bottom = -4.0
	log_label.add_theme_font_override("normal_font", CODE_FONT)
	log_label.add_theme_font_size_override("normal_font_size", LOG_FONT_SIZE)
	add_child(log_label)


# Copies the look of the OUTPUT panel so the two panels match.
func apply_style_from(source: Panel) -> void:
	_ensure_built()

	var box := source.get_theme_stylebox("panel")
	if box != null:
		add_theme_stylebox_override("panel", box)

	var source_title := source.get_node_or_null("OutputTitle") as Label
	if source_title != null:
		var font := source_title.get_theme_font("font")
		if font != null:
			title_label.add_theme_font_override("font", font)
		var title_font_size := source_title.get_theme_font_size("font_size")
		if title_font_size > 0:
			title_label.add_theme_font_size_override("font_size", title_font_size)


func set_header(step_label: String, index: int, total: int) -> void:
	_ensure_built()
	_header = "DEBUG  %s  [%d/%d]" % [step_label, index + 1, total]
	title_label.text = _header


func clear() -> void:
	_lines.clear()
	_rebuild()


func add_line(text: String, kind: String = "INFO", life: int = 0) -> void:
	_lines.append({"text": text, "kind": kind, "life": life, "obsolete": false})
	_trim()
	_rebuild()


# One audit-log entry (see SaveManager.log_audit).
func add_entry(entry: Dictionary) -> void:
	_lines.append(_line_from_entry(entry))
	_trim()
	_rebuild()


func load_entries(entries: Array) -> void:
	_lines.clear()
	for entry in entries:
		_lines.append(_line_from_entry(entry))
	_trim()
	_rebuild()


func mark_life_obsolete(life: int) -> void:
	for line in _lines:
		if int(line["life"]) == life:
			line["obsolete"] = true
	_rebuild()


func _line_from_entry(entry: Dictionary) -> Dictionary:
	var life := int(entry.get("life", 0))
	return {
		"text": "[L%d #%d] %s" % [life, int(entry.get("mistake", 0)), str(entry.get("message", ""))],
		"kind": str(entry.get("type", "COMPILE")),
		"life": life,
		"obsolete": bool(entry.get("obsolete", false)),
	}


func _trim() -> void:
	while _lines.size() > MAX_LINES:
		_lines.pop_front()


func _rebuild() -> void:
	_ensure_built()
	log_label.clear()

	for line in _lines:
		var text := _escape(str(line["text"]))
		if bool(line["obsolete"]):
			log_label.append_text("[color=%s][s]%s[/s][/color]\n" % [COLOR_OBSOLETE, text])
		else:
			var color: String = KIND_COLORS.get(str(line["kind"]), KIND_COLORS["INFO"])
			log_label.append_text("[color=%s]%s[/color]\n" % [color, text])

func _escape(text: String) -> String:
	return text.replace("[", "[lb]")
