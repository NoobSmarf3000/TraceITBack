extends RefCounted
class_name FinalProgram

const PATCH_LEVEL := 5
const SECTION_COUNT := 6


static func program() -> Dictionary:
	return JavaFauxSyntax.FINAL_PROGRAM

static func section_of_slot(slot_id: String) -> int:
	return int(slot_id.substr(1, 1))


static func section_of_line(line_index: int) -> int:
	var sections: Array = program()["sections"]
	if line_index < 0 or line_index >= sections.size():
		return 0
	return int(sections[line_index])


static func expected_lines() -> Array:
	var result: Array = []
	var answers: Dictionary = program()["answers"]
	for raw in program()["lines"]:
		var text := ""
		for part in JavaFauxSyntax.parse_line(str(raw)):
			if part.has("slot"):
				text += str(answers.get(part["slot"], ""))
			else:
				text += str(part["text"])
		result.append(text)
	return result

static func line_variants(line_index: int) -> Array:
	var raw := str(program()["lines"][line_index])
	var variants: Array = [""]
	for part in JavaFauxSyntax.parse_line(raw):
		var options: Array = []
		if part.has("slot"):
			options = JavaFauxSyntax.accepted_answers(program(), str(part["slot"]))
		else:
			options = [str(part["text"])]

		var next: Array = []
		for prefix in variants:
			for option in options:
				next.append(str(prefix) + str(option))
		variants = next

	var normalized: Array = []
	for variant in variants:
		var clean := JavaFauxSyntax.normalize_code(str(variant))
		if not normalized.has(clean):
			normalized.append(clean)
	return normalized


static func _is_comment_line(line_index: int) -> bool:
	return str(program()["lines"][line_index]).strip_edges().begins_with("//")


static func _line_matches(line_index: int, typed_normalized: String) -> bool:
	if _is_comment_line(line_index):
		return typed_normalized.begins_with("//")   
	return line_variants(line_index).has(typed_normalized)



static func check_typed(text: String) -> Dictionary:
	var expected := expected_lines()

	var typed: Array = []          
	var typed_numbers: Array = []   
	var raw_lines := text.replace("\r", "").split("\n")
	for i in range(raw_lines.size()):
		var cleaned := str(raw_lines[i]).strip_edges()
		if cleaned != "":
			typed.append(JavaFauxSyntax.normalize_code(cleaned))
			typed_numbers.append(i + 1)

	for i in range(expected.size()):
		if i >= typed.size():
			var last := 1
			if not typed_numbers.is_empty():
				last = int(typed_numbers[typed_numbers.size() - 1])
			return _result(false, last, "COMPILE", "reached end of file while parsing", 0)
		if not _line_matches(i, str(typed[i])):
			return _result(false, int(typed_numbers[i]), "LOGICAL",
				"this line is not what the program needs", section_of_line(i))

	if typed.size() > expected.size():
		return _result(false, int(typed_numbers[expected.size()]), "LOGICAL", "this line does not belong", 0)

	return _result(true, 0, "", "", 0)


static func _result(ok: bool, line: int, error_type: String, message: String, section: int) -> Dictionary:
	return {"ok": ok, "line": line, "type": error_type, "message": message, "section": section}


static func sections_to_fix(errors: Dictionary, failed: Dictionary) -> Array:
	var sections: Array = []
	for n in range(1, SECTION_COUNT + 1):
		if int(errors.get(n, 0)) > 0 or bool(failed.get(n, false)):
			sections.append(n)
	if sections.is_empty():
		for n in range(1, SECTION_COUNT + 1):
			sections.append(n)
	return sections

static func bank_words(sections: Array) -> Array:
	var words: Array = []
	var answers: Dictionary = program()["answers"]
	for raw in program()["lines"]:
		for part in JavaFauxSyntax.parse_line(str(raw)):
			if not part.has("slot"):
				continue
			var slot_id := str(part["slot"])
			if sections.has(section_of_slot(slot_id)):
				var word := str(answers[slot_id])
				if not words.has(word):
					words.append(word)

	var decoys: Dictionary = program().get("decoys_by_section", {})
	for section in sections:
		for decoy in decoys.get(section, []):
			var word := str(decoy)
			if not words.has(word):
				words.append(word)
	return words


static func build_code_files(sections_to_repair: Array) -> Array:
	var answers: Dictionary = program()["answers"]
	var lines: Array = []
	for raw in program()["lines"]:
		var parts: Array = []
		for part in JavaFauxSyntax.parse_line(str(raw)):
			if part.has("slot") and not sections_to_repair.has(section_of_slot(str(part["slot"]))):
				parts.append({"text": str(answers[part["slot"]])})
			else:
				parts.append(part)
		lines.append({"parts": parts})
	return [{"name": program().get("file", JavaFauxSyntax.DEFAULT_FILE), "lines": lines}]

static func wrong_slots(given: Dictionary, sections_to_repair: Array) -> Array:
	var problems: Array = []
	var answers: Dictionary = program()["answers"]
	for slot_id in answers:
		if not sections_to_repair.has(section_of_slot(str(slot_id))):
			continue
		var got := str(given.get(slot_id, "")).strip_edges()
		if JavaFauxSyntax.matches_answer(program(), str(slot_id), got):
			continue
		var problem := JavaFauxSyntax.describe_problem(program(), str(slot_id), got)
		problem["slot"] = str(slot_id)
		problem["got"] = got
		problem["section"] = section_of_slot(str(slot_id))
		problems.append(problem)
	problems.sort_custom(func(a, b): return int(a["line"]) < int(b["line"]))
	return problems

static func spec_text() -> String:
	return "\n".join(program()["spec"])
