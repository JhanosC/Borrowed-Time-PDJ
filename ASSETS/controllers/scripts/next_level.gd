extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body is Player:
		Global.game_controller.change_3d_scene("res://ASSETS/scenes/test_level_2.tscn")
		print("O bah!")
	queue_free()
