extends Control

@onready var playtime_label: Label = %PlaytimeLabel
@onready var puzzle_count_label: Label = %PuzzleCountLabel


func _ready() -> void:
	update_stats()


func _process(_delta: float) -> void:
	if visible:
		update_stats()


func update_stats() -> void:
	var save := SaveManager.get_current_save()

	if save == null:
		return

	playtime_label.text = "PLAY TIME\n" + format_playtime(
		save.playtime_seconds
	)

	puzzle_count_label.text = "PUZZLES COMPLETED\n%d" % (
		save.puzzles_completed
	)


func format_playtime(total_seconds: float) -> String:
	var seconds := int(total_seconds)

	var hours := floori(seconds / 3600.0)
	var minutes := floori((seconds % 3600) / 60.0)
	var remaining_seconds := seconds % 60

	return "%02d:%02d:%02d" % [
		hours,
		minutes,
		remaining_seconds
	]
