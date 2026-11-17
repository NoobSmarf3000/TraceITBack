extends RefCounted
class_name AuditSummary

const PATCH_LEVEL := 5  

const ERROR_ORDER := ["COMPILE", "LOGICAL", "RUNTIME"]

static func compute(
	entries: Array,
	puzzle_id: int,
	finishing_life: int,
	titles: Dictionary,
	mistakes: int,
	lives_lost: int,
	failed: bool
) -> Dictionary:
	var mistakes_per_step := {}
	var type_counts := {"COMPILE": 0, "RUNTIME": 0, "LOGICAL": 0}

	for entry in entries:
		if int(entry.get("puzzle", -1)) != puzzle_id:
			continue
		if int(entry.get("life", 0)) != finishing_life:
			continue

		var label := str(entry.get("step", ""))
		if not mistakes_per_step.has(label):
			mistakes_per_step[label] = {}
		mistakes_per_step[label][int(entry.get("mistake", 0))] = true

		var error_type := str(entry.get("type", "COMPILE"))
		type_counts[error_type] = int(type_counts.get(error_type, 0)) + 1

	var labels: Array = mistakes_per_step.keys()
	labels.sort_custom(func(a, b): return _label_order(str(a)) < _label_order(str(b)))
	var worst_step := ""
	var worst_count := 0
	for label in labels:
		var count: int = mistakes_per_step[label].size()
		if count > worst_count:
			worst_count = count
			worst_step = str(label)

	return {
		"mistakes": mistakes,
		"lives_lost": lives_lost,
		"failed": failed,
		"worst_step": worst_step,
		"worst_topic": str(titles.get(worst_step, "")),
		"main_error": _top_type(type_counts),
		"compile": int(type_counts["COMPILE"]),
		"runtime": int(type_counts["RUNTIME"]),
		"logical": int(type_counts["LOGICAL"]),
	}

static func totals(summaries: Dictionary, quiz_mistakes: int) -> Dictionary:
	var total_mistakes := 0
	var total_lives_lost := 0
	var type_counts := {"COMPILE": 0, "RUNTIME": 0, "LOGICAL": 0}
	var worst_puzzle := 0
	var worst_mistakes := 0

	var ids: Array = summaries.keys()
	ids.sort()
	for id in ids:
		var summary: Dictionary = summaries[id]
		var mistakes := int(summary.get("mistakes", 0))
		total_mistakes += mistakes
		total_lives_lost += int(summary.get("lives_lost", 0))
		type_counts["COMPILE"] += int(summary.get("compile", 0))
		type_counts["RUNTIME"] += int(summary.get("runtime", 0))
		type_counts["LOGICAL"] += int(summary.get("logical", 0))
		if mistakes > worst_mistakes:
			worst_mistakes = mistakes
			worst_puzzle = int(id)

	return {
		"total_mistakes": total_mistakes,
		"total_lives_lost": total_lives_lost,
		"favorite_error": _top_type(type_counts),
		"worst_puzzle": worst_puzzle,
		"quiz_mistakes": quiz_mistakes,
	}

static func variables_for(summaries: Dictionary, quiz_mistakes: int, last_puzzle: int) -> Dictionary:
	var values := {}
	for n in range(1, last_puzzle + 1):
		var summary: Dictionary = summaries.get(n, {})
		var prefix := "puzzle%d." % n
		values[prefix + "mistakes"] = int(summary.get("mistakes", 0))
		values[prefix + "lives_lost"] = int(summary.get("lives_lost", 0))
		values[prefix + "failed"] = "1" if bool(summary.get("failed", false)) else ""
		values[prefix + "worst_step"] = str(summary.get("worst_step", ""))
		values[prefix + "worst_topic"] = str(summary.get("worst_topic", ""))
		values[prefix + "main_error"] = str(summary.get("main_error", ""))

	var totals_values := totals(summaries, quiz_mistakes)
	for key in totals_values:
		values["summary." + str(key)] = totals_values[key]
	return values

static func _top_type(type_counts: Dictionary) -> String:
	var best := ""
	var best_count := 0
	for error_type in ERROR_ORDER:
		var count := int(type_counts.get(error_type, 0))
		if count > best_count:
			best_count = count
			best = error_type
	return best

static func _label_order(label: String) -> int:
	var parts := label.split(".")
	if parts.size() < 2:
		return 0
	return int(parts[0]) * 100 + int(parts[1])
