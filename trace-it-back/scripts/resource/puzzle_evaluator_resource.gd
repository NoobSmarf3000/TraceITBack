extends Resource
class_name PuzzleEvaluatorResource

const PATCH_LEVEL := 5   
const LAST_NORMAL_PUZZLE := 6   
const FINAL_PUZZLE := 7         


const MAX_LIVES := 3
const MAX_MISTAKES := 7        


const V1_BELOW := 2   
const V2_BELOW := 4   


@export var puzzle_id: int = 0
@export var completion_time: float = 0.0
@export var mistakes: int = 0         
@export var lives_lost: int = 0        
@export var lost_all_lives: bool = false
@export var completed: bool = false


static func from_result(
	id: int,
	time: float,
	mistake_count: int,
	lives_lost_count: int = 0,
	all_lives_lost: bool = false
) -> PuzzleEvaluatorResource:
	var ev := PuzzleEvaluatorResource.new()
	ev.puzzle_id = id
	ev.completion_time = time
	ev.mistakes = mistake_count
	ev.lives_lost = lives_lost_count
	ev.lost_all_lives = all_lives_lost
	ev.completed = true
	return ev


static func version_for(mistake_count: int, all_lives_lost: bool = false) -> int:
	if all_lives_lost:
		return 4
	if mistake_count <= 0:
		return 0
	if mistake_count < V1_BELOW:
		return 1
	if mistake_count < V2_BELOW:
		return 2
	return 3


func failed() -> bool:
	return lost_all_lives


func mistake_version() -> int:
	return version_for(mistakes, lost_all_lives)


func outcome_timelines() -> Array:
	var next := puzzle_id + 1
	if failed():
		return ["ACE_AND_TYRONE_BAD%d" % next]
	if mistakes == 0:
		return ["ACE_AND_TYRONE_GOOD%d" % next]
	var v := mistake_version()
	return [
		"ACE_AND_TYRONE_PUZZLE_MISTAKEV%d_%d" % [v, puzzle_id],
	]
