extends CanvasLayer


func _on_velocity_update(velocity):
	$Velocity.text = str(velocity).pad_decimals(2)
