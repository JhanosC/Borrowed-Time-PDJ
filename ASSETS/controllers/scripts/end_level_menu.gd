extends Control

@onready var main = $"../../"



func _on_next_level_pressed() -> void:
	Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/test_level_2.tscn")
	main.end_level()
	#Global.game_controller.load_new_scene()


func _on_continue_pressed() -> void:
	main.end_level()



func _on_quit_pressed() -> void:
	get_tree().quit()
