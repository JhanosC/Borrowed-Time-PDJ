extends Control

@onready var pause_menu: Control = $PauseMenu
@onready var end_level_menu: Control = $EndLevelMenu

var has_ended = false
var is_paused = false
var next_scene_path: String = ""

func _ready() -> void:
	pause_menu.hide()
	end_level_menu.hide()
	self.hide()

func end_level(path_to_new_scene):
	if !has_ended:
		end_level_menu.get_stats()
		end_level_menu.set_next_path(path_to_new_scene)
		self.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		has_ended = true
		end_level_menu.show()
		get_tree().paused = true
		
func resume_level():
	self.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	has_ended = false
	end_level_menu.hide()
	get_tree().paused = false

func pause_game():
	if !is_paused:
		self.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_paused = true
		get_tree().paused = true
		pause_menu.show()
		
	else:
		self.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_paused = false
		get_tree().paused = false
		pause_menu.hide()
