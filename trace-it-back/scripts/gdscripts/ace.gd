extends StaticBody2D
class_name ACE

signal animation_done(anim_name: StringName)

const TALK_ANIMS := ["talk_1", "talk_2"]
const PROTECTED_ANIMS := ["glitch_1", "glitch_2", "crash", "crash_2", "off", "turning_on"]

@export var auto_talk := true        
@export var speaker_name := "ACE"    

@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	anim.animation_finished.connect(func(n): animation_done.emit(n))
	Dialogic.Text.text_started.connect(_on_text_started)
	Dialogic.Text.text_finished.connect(_on_text_finished)
	Dialogic.timeline_ended.connect(_stop_talking)


func play_anim(anim_name: StringName) -> void:
	if anim.has_animation(anim_name):
		anim.play(anim_name)
	else:
		push_error("ACE has no animation: %s" % anim_name)


# ---------- Auto talking ----------

func _is_ace(info: Dictionary) -> bool:
	var character = info.get("character", null)   # null when it's narration
	return character != null and character.get_character_name() == speaker_name


func _on_text_started(info: Dictionary) -> void:
	if not auto_talk or not _is_ace(info):
		return
	if anim.is_playing() and anim.current_animation in PROTECTED_ANIMS:
		return
	anim.play(TALK_ANIMS.pick_random())


func _on_text_finished(_info: Dictionary) -> void:
	_stop_talking()


func _stop_talking() -> void:
	if anim.current_animation in TALK_ANIMS:
		anim.play("idle")
