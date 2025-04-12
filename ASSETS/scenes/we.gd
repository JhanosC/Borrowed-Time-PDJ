extends WorldEnvironment
@export_range(0, 360, 0.1) var black_hole_rotation : float = 180
var sky_material = self.environment

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _updateRotation(delta):
	black_hole_rotation+= 0.0001
	if(black_hole_rotation >= 360):
		black_hole_rotation = 0.0
	sky_material.sky_rotation.z = -black_hole_rotation
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_updateRotation(delta)
