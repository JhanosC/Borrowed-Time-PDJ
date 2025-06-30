extends Control

@onready var pause_menu: Control = $PauseMenu
@onready var end_level_menu: Control =$EndLevelMenu

var has_ended = false
var is_paused = false
var next_scene_path: String= ""



func _ready() -> void:
	pause_menu.hide()
	end_level_menu.hide()
	self.hide()

func end_level():
	if !has_ended:
		end_level_menu.get_stats()
		self.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		has_ended=true
		Engine.time_scale = 0
		end_level_menu.show()
		
	else:
		self.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		has_ended=false
		Engine.time_scale = 1
		end_level_menu.hide() 
	

func pause_game():
	if !is_paused:
		self.show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_paused = true
		Engine.time_scale = 0
		pause_menu.show()
		
	else:
		self.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_paused = false
		Engine.time_scale = 1
		pause_menu.hide()	
