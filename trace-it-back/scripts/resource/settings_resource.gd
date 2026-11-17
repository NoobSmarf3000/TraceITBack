extends Resource
class_name SettingsResource

@export_range(0.0, 1.0)
var master_volume: float = 1.0

@export_range(0.0, 1.0)
var music_volume: float = 1.0

@export_range(0.0, 1.0)
var sfx_volume: float = 1.0

@export var walk_down := "ui_down"
@export var walk_up := "ui_up"
@export var walk_left := "ui_left"
@export var walk_right := "ui_right"

@export var fullscreen := false
