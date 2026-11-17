extends PuzzleChallenge
class_name SlotsChallenge

const PATCH_LEVEL := 5   # PatchGuard checks this

# Drag or type words into the empty slots of a Java program.
# Data format: see JavaFauxSyntax ("lines", "answers", "accept", "decoys", ...).


func start() -> void:
	host.set_word_bank_available(true)
	host.code_panel.visible = true
	host.code_panel.setup_files(JavaFauxSyntax.build_code_files(step))
	host.word_bank.set_words(JavaFauxSyntax.get_bank_words(step))
	host.show_output("")


func reset() -> void:
	host.code_panel.reset()


func set_input_enabled(enabled: bool) -> void:
	host.code_panel.set_editing_enabled(enabled)


func evaluate() -> Array:
	var file_name: String = step.get("file", JavaFauxSyntax.DEFAULT_FILE)
	var given: Dictionary = host.code_panel.get_answers().get(file_name, {})
	var expected := JavaFauxSyntax.get_answers(step)

	var problems: Array = []
	for slot_id in expected:
		var got := str(given.get(slot_id, "")).strip_edges()
		if JavaFauxSyntax.matches_answer(step, str(slot_id), got):
			continue

		var wrong := JavaFauxSyntax.describe_problem(step, str(slot_id), got)
		wrong["slot"] = str(slot_id)
		wrong["got"] = got
		problems.append(wrong)

	# Report the problems top-to-bottom, like a compiler would.
	problems.sort_custom(func(a, b): return int(a["line"]) < int(b["line"]))
	return problems


func cleanup() -> void:
	pass   # the code panel stays; the next step rebuilds it
