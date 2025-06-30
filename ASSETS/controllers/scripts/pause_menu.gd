extends Control

@onready var main = $".."

func _ready() -> void:
	hide()

func _on_resume_pressed() -> void:
	print(StatsMan.reset_count)
	print(StatsMan.level_time)
	main.pause_game()

func _on_quit_pressed() -> void:
	#botar para ir no menu principal
	#Global.game_controller.load_new_scene("")
	pass

func _on_restart_pressed() -> void:
	main.pause_game()
	Global.game_controller.reload_scene()
