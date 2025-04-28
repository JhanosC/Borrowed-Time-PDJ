extends CanvasLayer


func _on_velocity_update(velocity):
	$Velocity.text = "speed: " + str(velocity).pad_decimals(2)

func _on_fov_update(fov):
	$FOV.text = "fov: " + str(fov).pad_decimals(2)

func _on_camera_distortion_update(distortion):
	$Camera_Distortion.text = "distortion: " + str(distortion).pad_decimals(2)

func _on_states_update(can_crouch,slaming,sliding,wall_running,on_floor,on_wall,wish_dir):
	$States.text = (
		"Can crouch: "+str(can_crouch) 
		+"\nSlaming: "+str(slaming)
		+"\nSliding: "+str(sliding)
		+"\nWall running: "+str(wall_running)
		+"\nOn floor: "+str(on_floor)
		+"\nOn wall: "+str(on_wall)
		+"\nWish_dir: "+str(wish_dir)
		)


func _on_position_update(x, y, z):
	$Position.text = "x: "+str(x)+"\ny: "+str(y)+"\nz: "+str(z)
