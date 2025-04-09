extends CanvasLayer


func _on_velocity_update(velocity):
	$Velocity.text = "speed: " + str(velocity).pad_decimals(2)

func _on_fov_update(fov):
	$FOV.text = "fov: " + str(fov).pad_decimals(2)


func _on_camera_distortion_update(distortion):
	$Camera_Distortion.text = "distortion: " + str(distortion).pad_decimals(2)
