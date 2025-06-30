extends Control

@onready var hover_button: AudioStreamPlayer = $hover_button
@onready var click_button: AudioStreamPlayer = $click_button


func _on_start_button_pressed() -> void:
	#get_tree().change_scene_to_file('res://ASSETS/scenes/levels/test_level_1.tscn')
	Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/test_level_1.tscn")
	click_button.play()
	print('game has started')
	pass # Replace with function body.


func _on_start_button_mouse_entered() -> void:
	hover_button.play()
	pass # Replace with function body.



func _on_exit_button_2_mouse_entered() -> void:
	hover_button.play()
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	click_button.play()
	get_tree().quit()
	print('game has started')
	pass # with function body.
