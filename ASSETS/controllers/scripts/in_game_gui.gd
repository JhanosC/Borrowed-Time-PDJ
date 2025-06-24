extends Control

@onready var pause_menu: Control = $PauseMenu
@onready var end_level_menu: Control =$EndLevelMenu

var has_ended = false
var is_paused = false

func _ready() -> void:
	pause_menu.hide()
	end_level_menu.hide()

func end_level():
	if !has_ended:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		has_ended=true
		Engine.time_scale = 0
		end_level_menu.show()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		has_ended=false
		Engine.time_scale = 1
		end_level_menu.hide() 

func pause_game():
	if !is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		is_paused = true
		Engine.time_scale = 0
		pause_menu.show()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_paused = false
		Engine.time_scale = 1
		pause_menu.hide()	
