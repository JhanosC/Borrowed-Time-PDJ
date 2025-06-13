extends Control

@onready var main = $"../../"


func _ready() -> void:
	$".".hide()


func _on_next_level_pressed() -> void:
	var tmp:String =get_tree().current_scene.to_string()
	print(tmp)
	#Global.game_controller.load_new_scene()


func _on_continue_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	pass # Replace with function body.
