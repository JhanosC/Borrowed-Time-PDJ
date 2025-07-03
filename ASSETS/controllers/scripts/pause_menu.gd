extends Control

@onready var main = $".."
@onready var options_menu = $OptionsMenu

func _ready() -> void:
	hide()

func _on_resume_pressed() -> void:
	main.pause_game()

func _on_quit_pressed() -> void:
	main.pause_game()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/main_menu.tscn")

func _on_restart_pressed() -> void:
	main.pause_game()
	Global.game_controller.reload_scene()


func _on_options_pressed():
	options_menu.show()
