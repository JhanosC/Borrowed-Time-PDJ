extends RigidBody3D
var freezeBody = false
var player_holding = false
var was_thrown = false

func _physics_process(delta):
	if self.was_thrown and !self.freeze:
		var contacts = get_colliding_bodies()
		if contacts != null:
			for body in contacts:
				if body.is_in_group("walls"):
					print('i was trown')
					self.freeze = true
					self.was_thrown = false
					player_released()
	
func player_picked():
	player_holding = true
	
func player_released():
	player_holding = false

func player_threw():
	was_thrown = true
