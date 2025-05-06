extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body is Player:
		_change_level()
	queue_free()

func _change_level():
	Global.game_controller.change_3d_scene("res://ASSETS/scenes/test_level.tscn")
	queue_free()
