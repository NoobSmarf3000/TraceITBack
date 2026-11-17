extends Control
class_name LivesDisplay

const FONT := preload("res://assets/texts/consolas.ttf")
const HEART_STEPS := 28
const HEART_SCALE := 0.62
const HEART_SPACING := 24.0
const FONT_SIZE := 14

const COLOR_FULL := Color(0.95, 0.25, 0.3, 1.0)
const COLOR_LOST := Color(0.95, 0.25, 0.3, 0.35)
const COLOR_TEXT := Color(1, 1, 1, 1)
const COLOR_TEXT_WARN := Color(1.0, 0.45, 0.4, 1.0)

var max_lives: int = 3
var max_mistakes: int = 7
var lives: int = 3
var mistakes: int = 0


func _init() -> void:
	custom_minimum_size = Vector2(110, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(new_lives: int, new_mistakes: int) -> void:
	lives = new_lives
	mistakes = new_mistakes
	queue_redraw()


func _draw() -> void:
	var center_y := size.y * 0.5

	for i in range(max_lives):
		var points := _heart_points(Vector2(14.0 + i * HEART_SPACING, center_y))
		if i < lives:
			draw_colored_polygon(points, COLOR_FULL)
		else:
			var outline := PackedVector2Array(points)
			outline.append(points[0])
			draw_polyline(outline, COLOR_LOST, 1.5)

	var text := "ERR %d/%d" % [mistakes, max_mistakes]
	var color := COLOR_TEXT_WARN if mistakes >= max_mistakes - 2 else COLOR_TEXT
	var text_pos := Vector2(14.0 + max_lives * HEART_SPACING + 6.0, center_y + 5.0)
	draw_string(FONT, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _heart_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(HEART_STEPS):
		var t := TAU * float(i) / float(HEART_STEPS)
		var s := sin(t)
		var x := 16.0 * s * s * s
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y) * HEART_SCALE)
	return points
