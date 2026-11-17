extends Node

signal cutscene_started(cutscene_name: String)
signal cutscene_finished(cutscene_name: String)

var active: bool = false
var current_cutscene_id:= ""


func start_cutscene(cutscene_id: String, timeline: String) -> void:
	if active:
		return
		
		active = true
		current_cutscene_id = cutscene_id
		cutscene_started.emit(cutscene_id)
		
		DialogueController.start_dialogue(timeline)
		
		if not DialogueController.dialogue_finished.is_connected(_on_dialogue_finished):
			DialogueController.dialogue_finished.is_connected(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
	if not active:
		return
		
	var finished_id := current_cutscene_id
	
	active = false
	current_cutscene_id = ""
		
	cutscene_finished.emit(finished_id)
