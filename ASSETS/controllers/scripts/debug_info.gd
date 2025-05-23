extends CanvasLayer
	

func _on_velocity_update(velocity, desired_velocity, current_dash_storage):
	$Velocity.text = (
		"Speed: " + str(velocity).pad_decimals(2)
		+"\nDesired Velocity: "+str(desired_velocity).pad_decimals(2)
		+"\nCurrent Dash Storage: "+str(current_dash_storage).pad_decimals(2)
		)
#
#func _on_fov_update(fov):
	#$FOV.text = "fov: " + str(fov).pad_decimals(2)
#
#func _on_camera_distortion_update(distortion):
	#$Camera_Distortion.text = "distortion: " + str(distortion).pad_decimals(2)

func _on_character_body_3d_states_update(can_crouch: bool, slaming: bool, sliding: bool, wall_running: bool, on_floor: bool, on_wall: bool, direction: Vector3,is_slow: bool,can_slow: bool) -> void:
	$States.text = (
		"Can crouch: "+str(can_crouch) 
		+"\nSlaming: "+str(slaming)
		+"\nSliding: "+str(sliding)
		+"\nWall running: "+str(wall_running)
		+"\nOn floor: "+str(on_floor)
		+"\nOn wall: "+str(on_wall)
		+"\ndirection: "+str(direction)
		+"\nSlow: "+str(is_slow)
		+"\nCan Slow: "+str(can_slow)
		)
#
#func _on_position_update(x, y, z):
	#$Position.text = "x: "+str(x)+"\ny: "+str(y)+"\nz: "+str(z)
