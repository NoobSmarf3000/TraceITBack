extends Resource
class_name SaveStateResource

const PATCH_LEVEL := 5   # PatchGuard checks this, so a stale copy of this file is caught at startup

# Progress
@export var current_scene : String = ""
@export var checkpoint : String = ""
@export var spawn_point: String = "Start"
@export var interaction_counts: Dictionary = {}
@export var last_interaction_stage: int = 0 
@export var final_timed_out: bool = false

# Choices
@export var dialogue_choices : Dictionary = {}

# Puzzle data
@export var puzzle_times : Dictionary = {}
@export var puzzle_errors : Dictionary = {}       # id -> mistakes in the finishing life
@export var puzzle_progress : Dictionary = {}     # id -> {lives, step, mistakes} while a puzzle is unfinished
@export var audit_log : Array = []               # every mistake ever made (see SaveManager.log_audit)
@export var puzzle_summary : Dictionary = {}     # id -> AuditSummary.compute() result, stored when the puzzle ends
@export var hints_found : Array = []                # ids of the final-puzzle log fragments found (JavaFauxSyntax.FINAL_HINTS)
@export var puzzle_lives_lost : Dictionary = {}   # id -> lives lost (final result)
@export var puzzle_failed : Dictionary = {}       # id -> true if all lives were lost

# Story
@export var ace_glitch: int = 0
@export var route : String = "Neutral"
@export var ending: String = ""
@export var ace_corruption: int = 0

# Player
@export var inventory : Array[String] = []

# Statistics
@export var playtime_seconds: float = 0.0
@export var total_errors : int = 0
@export var puzzles_completed : int = 0

# Dialogic
@export var dialogic_variables : Dictionary = {}

# Narrative intro
@export var last_event_type: String = "NONE"
@export var last_puzzle: int = 0
@export var narrative_event_consumed: bool = false

# ACE . Resume
@export var last_scene : String = ""
@export var last_action : String = ""
@export var last_interaction : String = ""

@export var computer_on: bool = false
@export var intro_quiz_done: bool = false
@export var intro_quiz_mistakes: int = 0
