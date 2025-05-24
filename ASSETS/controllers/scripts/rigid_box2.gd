extends RigidBody3D

var thrown := false
var targeted := false
var held := false
@onready var outline: MeshInstance3D = $MeshInstance3D/Outline

# Called when the node enters the scene tree for the first time.
func _ready():
	outline.hide()
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	for i in get_colliding_bodies():
		if i is not RigidBody3D and i is not Player and thrown:
			freeze = true
	if linear_velocity.length() <= 0.0:
		thrown = false
	if targeted and not held:
		enable_outline()
	elif outline.visible == true:
		disable_outline()

func throw(push_dir, push_force):
	thrown = true
	lock_rotation = false
	apply_impulse(push_dir * push_force)

func enable_outline():
	outline.visible = true
func disable_outline():
	outline.hide()
