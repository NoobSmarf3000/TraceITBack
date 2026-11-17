extends CanvasLayer
class_name AuditLogScreen

const PATCH_LEVEL := 5
const GROUP := "audit_log_screen"
const CODE_FONT := preload("res://assets/texts/consolas.ttf")
const FONT_SIZE := 12

const TYPE_COLORS := {
	"COMPILE": "#ff7a7a",
	"RUNTIME": "#ff7ad9",
	"LOGICAL": "#ffd166",
}
const OBSOLETE_COLOR := "#6b6b6b"


static func open(tree: SceneTree) -> void:
	if tree.get_first_node_in_group(GROUP) != null:
		return
	tree.root.add_child(AuditLogScreen.new())


static func toggle(tree: SceneTree) -> void:
	var existing := tree.get_first_node_in_group(GROUP)
	if existing != null:
		existing.queue_free()
	else:
		open(tree)


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var panel := Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -310.0
	panel.offset_right = 310.0
	panel.offset_top = -215.0
	panel.offset_bottom = 215.0
	root.add_child(panel)

	var margin := MarginContainer.new()
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)

	var title := Label.new()
	title.text = "TRACEBACK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)

	var save := SaveManager.get_current_save()
	var entries := SaveManager.get_audit_log()

	var traceback := _make_text_view("Traceback")
	traceback.text = build_traceback_text(entries, save.puzzle_lives_lost, save.puzzle_failed)
	tabs.add_child(traceback)

	var log_view := _make_text_view("Log")
	log_view.text = build_log_text(entries)
	tabs.add_child(log_view)

	var fragments_view := _make_text_view("Fragments")
	fragments_view.text = build_fragments_text(SaveManager.get_hints_found())
	tabs.add_child(fragments_view)

	var close_button := Button.new()
	close_button.text = "Close  (F2 / Esc)"
	close_button.pressed.connect(queue_free)
	column.add_child(close_button)


func _make_text_view(view_name: String) -> RichTextLabel:
	var view := RichTextLabel.new()
	view.name = view_name
	view.bbcode_enabled = true
	view.scroll_active = true
	view.selection_enabled = true
	view.add_theme_font_override("normal_font", CODE_FONT)
	view.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	view.add_theme_font_override("bold_font", CODE_FONT)
	view.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	return view


static func escape(text: String) -> String:
	return text.replace("[", "[lb]")


static func _puzzle_heading(id: int) -> String:
	if id <= 0:
		return JavaFauxSyntax.puzzle_title(id)
	return "Puzzle %d: %s" % [id, JavaFauxSyntax.puzzle_title(id)]


static func _entry_text(entry: Dictionary) -> String:
	return "[L%d #%d] %s  %s" % [
		int(entry.get("life", 0)),
		int(entry.get("mistake", 0)),
		str(entry.get("step", "")),
		str(entry.get("message", "")),
	]


static func build_log_text(entries: Array) -> String:
	if entries.is_empty():
		return "A clean run so far."

	var by_puzzle := {}
	for entry in entries:
		var id := int(entry.get("puzzle", -1))
		if not by_puzzle.has(id):
			by_puzzle[id] = []
		by_puzzle[id].append(entry)

	var ids := by_puzzle.keys()
	ids.sort()

	var counts := {"COMPILE": 0, "RUNTIME": 0, "LOGICAL": 0}
	var out := ""
	for id in ids:
		out += "[b]== %s ==[/b]\n" % escape(_puzzle_heading(int(id)))
		for entry in by_puzzle[id]:
			var text := escape(_entry_text(entry))
			if bool(entry.get("obsolete", false)):
				out += "[color=%s][s]%s[/s][/color]\n" % [OBSOLETE_COLOR, text]
			else:
				var error_type := str(entry.get("type", "COMPILE"))
				if int(id) > 0:   # the intro quiz is listed but never counted
					counts[error_type] = int(counts.get(error_type, 0)) + 1
				out += "[color=%s]%s[/color]\n" % [TYPE_COLORS.get(error_type, "#ffffff"), text]
		out += "\n"

	out += "Counted (puzzles only, lost lives are obsolete):\nCOMPILE %d  |  RUNTIME %d  |  LOGICAL %d" % [
		int(counts["COMPILE"]), int(counts["RUNTIME"]), int(counts["LOGICAL"])
	]
	return out


static func build_traceback_text(entries: Array, lives_lost: Dictionary, failed: Dictionary) -> String:
	var current_by_puzzle := {}
	var first_cause := {}
	for entry in entries:
		var id := int(entry.get("puzzle", 0))
		if id <= 0 or bool(entry.get("obsolete", false)):
			continue
		if first_cause.is_empty():
			first_cause = entry
		if not current_by_puzzle.has(id):
			current_by_puzzle[id] = []
		current_by_puzzle[id].append(entry)

	var frame_ids: Array = current_by_puzzle.keys()
	for id in failed:
		if bool(failed[id]) and not frame_ids.has(id):
			frame_ids.append(id)
	frame_ids.sort()
	frame_ids.reverse()

	var out := "[b]ACE.trace()[/b]   (most recent call first)\n\n"

	if frame_ids.is_empty():
		out += "  nothing to trace back:\n  no mistakes in your finishing lives."
		return out

	for id in frame_ids:
		var detail := ""
		if bool(failed.get(id, false)):
			detail = "FAILED: all 3 lives lost"
		else:
			var mistake_keys := {}
			var type_counts := {}
			for entry in current_by_puzzle.get(id, []):
				mistake_keys["%d:%d" % [int(entry.get("life", 0)), int(entry.get("mistake", 0))]] = true
				var error_type := str(entry.get("type", "COMPILE"))
				type_counts[error_type] = int(type_counts.get(error_type, 0)) + 1

			var parts: Array = []
			for error_type in ["COMPILE", "RUNTIME", "LOGICAL"]:
				if type_counts.has(error_type):
					parts.append("%s x%d" % [error_type, int(type_counts[error_type])])
			var count := mistake_keys.size()
			detail = "%d mistake%s: %s" % [count, "" if count == 1 else "s", ", ".join(parts)]
			if int(lives_lost.get(id, 0)) > 0:
				detail += "  | lives lost: %d" % int(lives_lost[id])

		out += "  at Puzzle_%d  %s\n      (%s)\n" % [int(id), escape(JavaFauxSyntax.puzzle_title(int(id))), detail]

	if not first_cause.is_empty():
		out += "\n[b]Caused by:[/b]\n  Puzzle_%d  %s\n  %s" % [
			int(first_cause.get("puzzle", 0)),
			escape(str(first_cause.get("step", ""))),
			escape(str(first_cause.get("message", ""))),
		]
	return out



static func build_fragments_text(found: Array) -> String:
	var out := "[b]LOG FRAGMENTS  %d / %d[/b]\n" % [found.size(), JavaFauxSyntax.hint_count()]
	out += "Pieces of ACE's boot log are hidden around the house.\n\n"

	for hint in JavaFauxSyntax.FINAL_HINTS:
		var tag := escape("[F%d]" % int(hint["section"]))
		if found.has(str(hint["id"])):
			var code := "    " + str(hint["text"]).replace("\n", "\n    ")
			out += "[color=#7dff9a][b]%s %s[/b]  (%s)[/color]\n%s\n\n" % [
				tag, escape(str(hint["title"])), escape(str(hint["room"])), escape(code)
			]
		else:
			out += "[color=%s]%s %s[/color]\n\n" % [OBSOLETE_COLOR, tag, escape("[ CORRUPTED ]")]
	return out
