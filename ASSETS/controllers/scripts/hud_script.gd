extends Control

@onready var speed_lines = $SpeedLines

# Called when the node enters the scene tree for the first time.
func _ready():
	speed_lines.visible = false

func display_speed_lines(current_velocity, base_velocity):
	if current_velocity > base_velocity * 1.3:
		speed_lines.visible = true
		speed_lines.set_instance_shader_parameter("animation_speed", current_velocity)
	else:
		speed_lines.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
