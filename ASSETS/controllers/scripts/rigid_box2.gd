extends RigidBody3D

var thrown := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for i in get_colliding_bodies():
		if i is not RigidBody3D and thrown and i.is_in_group("walls"):
			freeze = true
	if linear_velocity.length() <= 0.0:
		thrown = false

func throw(push_dir, push_force):
	thrown = true
	lock_rotation = false
	apply_impulse(push_dir * push_force)
