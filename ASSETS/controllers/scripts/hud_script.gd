extends Control

@onready var speed_lines = $SpeedLines
@onready var time: Label = $Time
@onready var dash_storage: ProgressBar = $DashStorage
@onready var debug_info: Label = $DebugInfo
var time_passed = 0.0
var fps

# Called when the node enters the scene tree for the first time.
func _ready():
	speed_lines.visible = false

func display_speed_lines(current_velocity, base_velocity):
	if current_velocity > base_velocity * 1.3:
		speed_lines.visible = true
	else:
		speed_lines.visible = false

func display_fall_lines(current_velocity, base_velocity):
	if current_velocity > base_velocity * 1.3:
		speed_lines.visible = true
	else:
		speed_lines.visible = false

func display_time(delta):
	time_passed += delta
	time.text = str(time_passed).pad_decimals(2)
	
func get_time():
	return time_passed

func update_dash_storage(dash_amount, max_dash_amount):
	dash_storage.max_value = max_dash_amount
	dash_storage.value = dash_amount

func display_debug_info(can_crouch: bool,
slaming: bool,
sliding: bool,
wall_running: bool,
on_floor: bool,
on_wall: bool,
hook_out: bool,
direction: Vector3,
velocity,
desired_velocity) -> void:
	debug_info.text = (
		"FPS: " + str(fps)
		+"\nCan crouch: "+str(can_crouch) 
		+"\nSlaming: "+str(slaming)
		+"\nSliding: "+str(sliding)
		+"\nWall running: "+str(wall_running)
		+"\nOn floor: "+str(on_floor)
		+"\nOn wall: "+str(on_wall)
		+"\nHook out: "+str(hook_out)
		+"\nDirection: "+str(direction)
		+"\nVelocity: "+str(velocity).pad_decimals(2)
		+"\nDesired Velocity: "+str(desired_velocity).pad_decimals(2)
		)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	display_time(delta)
	fps = Engine.get_frames_per_second()
