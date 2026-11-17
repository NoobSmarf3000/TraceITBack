extends Control

const NEXT_SCENE := "res://scenes/main_menu/main_menu.tscn"

const MUSIC_KEY := "credits"

const START_DELAY := 0.8   
const FADE_IN := 1.0
const HOLD := 3.0
const FADE_OUT := 1.0
const GAP := 0.4            
const ALLOW_SKIP := true    

const PARTS := [
	{"main": "TraceITback", "extra": "Chapter 1", "size": 60},
	{"heading": "Created by", "main": "Christian John Aquino"},
	{"heading": "Story and Writing", "main": "Christian John Aquino"},
	{"heading": "Programming", "main": "Christian John Aquino"},
	{"heading": "Pixel Art and Animation", "main": "Christian John Aquino",
		"extra": "Drawn and animated with Aseprite"},
	{"heading": "Music", "main": "Christian John Aquino",
		"extra": "Composed with BandLab"},
	{"heading": "Built with", "main": "Godot Engine"},
	{"heading": "Dialogue system", "main": "Dialogic"},
	{"heading": "Language of the puzzles", "main": "Java",
		"extra": "From Oracle. Java is a trademark of Oracle and/or its affiliates."},
	{"heading": "Educational reference and puzzle themes from W3Schools."},
	{
		"main": "To those of you who have come this far,",
		"extra": "Thank you for playing.\nMy dream starts today.\nChristian John Aquino",
		"size": 35,
	}
]

@onready var page: Control = %Page
@onready var heading_label: Label = %Heading
@onready var main_label: Label = %Main
@onready var extra_label: Label = %Extra
@onready var skip_hint: Label = %SkipHint

var _tween: Tween
var _leaving := false


func _ready() -> void:
	page.modulate.a = 0.0
	skip_hint.visible = ALLOW_SKIP

	AudioManager.play_music(MUSIC_KEY, 1.5)

	_run_credits()


func _unhandled_input(event: InputEvent) -> void:
	if ALLOW_SKIP and event.is_action_pressed("ui_cancel"):
		if _tween:
			_tween.kill()
		_go_to_next_scene()


func _run_credits() -> void:
	await get_tree().create_timer(START_DELAY).timeout

	for part in PARTS:
		if _leaving:
			return

		_show_part(part)

		_tween = create_tween()
		_tween.tween_property(page, "modulate:a", 1.0, FADE_IN)
		_tween.tween_interval(HOLD)
		_tween.tween_property(page, "modulate:a", 0.0, FADE_OUT)
		_tween.tween_interval(GAP)
		await _tween.finished

	_go_to_next_scene()


func _show_part(part: Dictionary) -> void:
	var heading: String = part.get("heading", "")
	heading_label.text = heading
	heading_label.visible = heading != ""

	main_label.text = part.get("main", "")
	main_label.add_theme_font_size_override("font_size", int(part.get("size", 40)))

	var extra: String = part.get("extra", "")
	extra_label.text = extra
	extra_label.visible = extra != ""


func _go_to_next_scene() -> void:
	if _leaving:
		return
	_leaving = true

	AudioManager.stop_music(1.0)
	get_tree().change_scene_to_file(NEXT_SCENE)
	TransitionAnimation.fade_to_normal()  
