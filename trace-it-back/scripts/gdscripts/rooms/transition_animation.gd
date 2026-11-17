extends CanvasLayer

signal on_transition_finished
signal on_fade_in_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var busy := false


func _ready() -> void:
	color_rect.visible = false
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_to_black":
		busy = false
		on_transition_finished.emit()
	elif anim_name == "fade_to_normal":
		color_rect.visible = false
		busy = false
		on_fade_in_finished.emit()


func transition() -> void:
	busy = true
	color_rect.visible = true
	animation_player.play("fade_to_black")


func fade_to_normal() -> void:
	busy = true
	color_rect.visible = true
	animation_player.play("fade_to_normal")
