extends CanvasLayer


func _on_velocity_update(velocity):
	$Velocity.text = "speed: " + str(velocity).pad_decimals(2)
#
#func _on_fov_update(fov):
	#$FOV.text = "fov: " + str(fov).pad_decimals(2)
#
#func _on_camera_distortion_update(distortion):
	#$Camera_Distortion.text = "distortion: " + str(distortion).pad_decimals(2)

func _on_character_body_3d_states_update(can_crouch: bool, slaming: bool, sliding: bool, wall_running: bool, on_floor: bool, on_wall: bool, direction: Vector3) -> void:
	$States.text = (
		"Can crouch: "+str(can_crouch) 
		+"\nSlaming: "+str(slaming)
		+"\nSliding: "+str(sliding)
		+"\nWall running: "+str(wall_running)
		+"\nOn floor: "+str(on_floor)
		+"\nOn wall: "+str(on_wall)
		+"\ndirection: "+str(direction)
		)
#
#func _on_position_update(x, y, z):
	#$Position.text = "x: "+str(x)+"\ny: "+str(y)+"\nz: "+str(z)
