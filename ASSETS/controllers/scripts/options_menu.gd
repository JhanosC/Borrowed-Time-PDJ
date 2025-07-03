extends Control

@onready var main = $".."

func _ready() -> void:
	hide()

func _on_quit_pressed():
	main.show()
	hide()


func _on_check_box_toggled(toggled_on):
	if toggled_on:
		Global.game_controller.mute()
	else:
		Global.game_controller.play()
